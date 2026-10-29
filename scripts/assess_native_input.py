#!/usr/bin/env python3
"""Exercise an exported Linux game through X11 keyboard/mouse events.

Requires libX11, libXtst, xwininfo and xprop, plus a dedicated X11 display.
The opt-in observer only reports state: all actions use the OS input path.
This short banking loop does not assess full-run balance or hardware FPS.
"""
import argparse
import ctypes
import json
import math
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time


class NativeInputCheck:
    def __init__(self, args):
        self.binary = args.binary.resolve(strict=True)
        self.base = (args.output.resolve() if args.output else
                     Path(tempfile.mkdtemp(prefix="midnight-input-")))
        if args.output:
            self.base.mkdir(parents=True, exist_ok=False)
        self.log = self.base / "run.log"
        self.env = os.environ.copy()
        self.env.update(DISPLAY=args.display,
                        MIDNIGHT_INPUT_CAPTURE_DIR=str(self.base / "captures"))
        for variable, folder in [("XDG_DATA_HOME", "data"),
                                 ("XDG_CONFIG_HOME", "config"),
                                 ("XDG_CACHE_HOME", "cache")]:
            path = self.base / folder
            path.mkdir()
            self.env[variable] = str(path)
        self.checkpoint_rendering = args.checkpoint_rendering
        self.process = None
        self.held = set()
        self.x = ctypes.CDLL("libX11.so.6")
        self.xtest = ctypes.CDLL("libXtst.so.6")
        pointer, integer, ulong = ctypes.c_void_p, ctypes.c_int, ctypes.c_ulong
        self.x.XOpenDisplay.argtypes = [ctypes.c_char_p]
        self.x.XOpenDisplay.restype = pointer
        self.x.XCloseDisplay.argtypes = [pointer]
        self.x.XStringToKeysym.argtypes = [ctypes.c_char_p]
        self.x.XStringToKeysym.restype = ulong
        self.x.XKeysymToKeycode.argtypes = [pointer, ulong]
        self.x.XKeysymToKeycode.restype = ctypes.c_uint
        self.x.XFlush.argtypes = [pointer]
        self.x.XSetInputFocus.argtypes = [pointer, ulong, integer, ulong]
        self.x.XDefaultRootWindow.argtypes = [pointer]
        self.x.XDefaultRootWindow.restype = ulong
        self.xtest.XTestFakeKeyEvent.argtypes = [pointer, ctypes.c_uint, integer, ulong]
        self.xtest.XTestFakeButtonEvent.argtypes = [pointer, ctypes.c_uint, integer, ulong]
        self.xtest.XTestFakeMotionEvent.argtypes = [pointer, integer, integer, integer, ulong]
        self.xtest.XTestFakeRelativeMotionEvent.argtypes = [pointer, integer, integer, ulong]
        self.display = self.x.XOpenDisplay(args.display.encode())
        if not self.display:
            raise RuntimeError("Could not open X11 display " + args.display)

    def latest(self):
        try:
            return json.loads((self.base / "captures/state.json").read_text())
        except (FileNotFoundError, json.JSONDecodeError):
            return {}

    def wait(self, check, label, seconds=30):
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            state = self.latest()
            if check(state):
                return state
            if self.process.poll() is not None:
                raise RuntimeError("Game exited during " + label + "\n" + self.log.read_text())
            time.sleep(0.025)
        raise RuntimeError(label + " timed out: " + json.dumps(self.latest()))

    def key(self, name, down):
        code = self.x.XKeysymToKeycode(self.display, self.x.XStringToKeysym(name.encode()))
        self.xtest.XTestFakeKeyEvent(self.display, code, int(down), 0)
        self.x.XFlush(self.display)
        (self.held.add if down else self.held.discard)(name)

    def tap(self, name):
        self.key(name, True)
        time.sleep(0.07)
        self.key(name, False)

    def move(self, key, check, label):
        self.key(key, True)
        try:
            self.wait(check, label)
        finally:
            self.key(key, False)
        time.sleep(0.3)

    def turn(self, target):
        for _ in range(50):
            state = self.latest()
            angle = (target - state["yaw"] + math.pi) % math.tau - math.pi
            if abs(angle) < 0.025:
                return
            dx = max(-160, min(160, round(-angle / (0.0022 * state["sensitivity"]))))
            before = state["yaw"]
            self.xtest.XTestFakeRelativeMotionEvent(self.display, dx, 0, 0)
            self.x.XFlush(self.display)
            self.wait(lambda s: abs(s.get("yaw", before) - before) > 0.002, "mouse motion", 5)
        raise RuntimeError("Mouse look did not reach target: " + json.dumps(self.latest()))

    def focus_window(self):
        tree = subprocess.check_output(["xwininfo", "-root", "-tree"], env=self.env, text=True)
        window = None
        for candidate in re.findall(r'(0x[0-9a-f]+) "The Midnight Exchange"', tree):
            prop = subprocess.check_output(["xprop", "-id", candidate, "_NET_WM_PID"],
                                           env=self.env, text=True)
            match = re.search(r"=\s*(\d+)", prop)
            if match and int(match.group(1)) == self.process.pid:
                window = int(candidate, 16)
                break
        if window is None:
            raise RuntimeError("No game window matches launched process " + str(self.process.pid))
        info = subprocess.check_output(["xwininfo", "-id", hex(window)], env=self.env, text=True)

        def metric(name):
            return int(re.search(re.escape(name) + r":\s*(-?\d+)", info).group(1))

        self.left = metric("Absolute upper-left X")
        self.top = metric("Absolute upper-left Y")
        self.width = metric("Width")
        self.height = metric("Height")
        self.x.XSetInputFocus(self.display, window, 2, 0)
        self.x.XFlush(self.display)
        time.sleep(0.1)

    def click(self, px, py):
        gx = self.left + round(px * self.width / 1280)
        gy = self.top + round(py * self.height / 720)
        self.xtest.XTestFakeMotionEvent(self.display, -1, gx, gy, 0)
        self.x.XFlush(self.display)
        time.sleep(0.06)
        self.xtest.XTestFakeButtonEvent(self.display, 1, 1, 0)
        self.x.XFlush(self.display)
        time.sleep(0.06)
        self.xtest.XTestFakeButtonEvent(self.display, 1, 0, 0)
        self.x.XFlush(self.display)

    def exercise(self):
        self.wait(lambda s: s.get("mode") == "title", "title")
        self.focus_window()
        self.click(985, 648)
        self.wait(lambda s: s.get("mode") == "ticket", "open ticket counter")
        for digit in "90210":
            self.tap(digit)
        self.tap("Return")
        self.wait(lambda s: s.get("playing") and s.get("mouse") == 2 and s.get("seed") == 90210,
                  "board a typed ticket number")
        # Losing OS focus must protect the clock; fullscreen shortcuts must
        # still work on a pause page with ordinary keyboard/mouse focus.
        root = self.x.XDefaultRootWindow(self.display)
        self.x.XSetInputFocus(self.display, root, 2, 0)
        self.x.XFlush(self.display)
        unfocused = self.wait(lambda s: s.get("paused") and s.get("mode") == "pause",
                              "automatic focus pause")
        time.sleep(0.5)
        if self.latest()["remaining"] != unfocused["remaining"]:
            raise RuntimeError("Clock advanced after OS focus loss")
        self.focus_window()
        self.tap("F11")
        self.wait(lambda s: s.get("window") == 3, "enter fullscreen")
        self.tap("F11")
        self.wait(lambda s: s.get("window") == 0, "return to windowed")
        self.focus_window()
        self.tap("Escape")
        self.wait(lambda s: not s.get("paused") and s.get("mouse") == 2, "resume after focus loss")
        # Every shuffled first carriage has a display at x=2.1, z=-11.
        self.move("w", lambda s: s.get("z", 10) <= -10.3, "walk to first display")
        self.move("d", lambda s: s.get("x", 0) >= 0.3, "approach display")
        self.turn(-math.pi / 2)
        self.tap("e")
        self.wait(lambda s: s.get("inventory") == 1, "collect with E")
        print("PICKUP", json.dumps(self.latest()), flush=True)
        self.move("s", lambda s: s.get("x", 10) <= 0.3, "return to aisle")
        self.turn(-math.pi)
        self.move("w", lambda s: s.get("z", -100) >= 3.1, "return to counter")
        self.tap("e")
        bank = self.wait(lambda s: s.get("bank", 0) > 0 and s.get("inventory") == 0,
                         "bank with E")
        print("BANK", json.dumps(bank), flush=True)
        self.tap("1")
        self.wait(lambda s: s.get("capacity") == 4, "choose capacity upgrade")
        self.tap("Tab")
        planned = self.wait(lambda s: s.get("paused") and s.get("mode") == "route",
                            "open switchboard")
        self.click(664, 375)
        swapped = self.wait(lambda s: s.get("pressure") == planned["pressure"] - 1,
                            "click shunt arrow")
        if abs(swapped["remaining"] - (planned["remaining"] - 6)) >= 0.05:
            raise RuntimeError("Shunt time cost differs: " + json.dumps([planned, swapped]))
        self.click(985, 648)
        self.wait(lambda s: s.get("ledger") is True, "open passenger ledger")
        self.tap("Tab")
        self.wait(lambda s: s.get("playing") and not s.get("paused"), "close focused route")
        self.tap("Escape")
        self.wait(lambda s: s.get("mode") == "pause" and s.get("paused"), "pause")
        self.click(314, 595)
        self.wait(lambda s: not s.get("playing") and s.get("mode") == "title", "return to title")
        self.click(314, 667)
        code = self.process.wait(timeout=10)
        text = self.log.read_text()
        if code != 0 or "ERROR:" in text or bank["catches"] != 0:
            raise RuntimeError("Native input check failed: " + str(code) + "\n" + text)
        result = {"passed": True, "bank": bank, "switchboard": swapped,
                  "focus_pause": True, "fullscreen_round_trip": True,
                  "continuous_rendering": not self.checkpoint_rendering}
        (self.base / "summary.json").write_text(json.dumps(result, indent=2) + "\n")
        print("NATIVE INPUT PASS: OS typed ticket, boarding, focus pause, F11, pickup, bank, upgrade, paid shunt, ledger, "
              "Tab, pause/title and quit", flush=True)

    def run(self):
        print("Native input artifacts:", self.base, flush=True)
        options = ["--disable-render-loop"] if self.checkpoint_rendering else []
        try:
            with self.log.open("w") as output:
                self.process = subprocess.Popen(
                    [str(self.binary), "--audio-driver", "Dummy", "--resolution", "1280x720",
                     *options, "--", "--input-observer"], cwd=self.base, env=self.env,
                    stdout=output, stderr=subprocess.STDOUT)
            self.exercise()
        finally:
            for name in list(self.held):
                self.key(name, False)
            if self.process is not None and self.process.poll() is None:
                self.process.terminate()
                try:
                    self.process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    self.process.kill()
                    self.process.wait()
            self.x.XCloseDisplay(self.display)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path, help="Exported Linux executable")
    parser.add_argument("--display", default=os.environ.get("DISPLAY"), help="Dedicated X11 display")
    parser.add_argument("--output", type=Path, help="New directory for profile, log and screenshots")
    parser.add_argument("--checkpoint-rendering", action="store_true",
                        help="Draw only checkpoints on slow software displays")
    args = parser.parse_args()
    if not args.display:
        parser.error("Set DISPLAY or provide --display")
    NativeInputCheck(args).run()


if __name__ == "__main__":
    main()
