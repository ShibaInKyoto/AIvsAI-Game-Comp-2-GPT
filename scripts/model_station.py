"""Original dawn-platform furnishings. Run with Blender 4.3 in background mode."""
from functools import partial
from pathlib import Path
import math
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from modeling import (BLACK, GOLD, IVORY, box as base_box, clear,
                      cylinder as base_cylinder, export, material,
                      tube_between as base_tube)

box = partial(base_box, bevel_segments=1)
cylinder = partial(base_cylinder, bevel_segments=1)
tube = partial(base_tube, bevel_segments=1)
IRON = material('Station green cast iron', (.055, .14, .13), .45, .55)
SLATS = material('Station honey oak', (.29, .17, .08), 0, .6)


def bench():
    clear()
    for x in [-.91, .91]:
        for y in [-.25, .25]:
            foot = (x, y, .045)
            knee = (x, y * .65, .45)
            cylinder(foot, .08, .07, IRON, 12)
            tube(foot, knee, .035, IRON)
        tube((x, -.24, .45), (x, .30, .45), .04, IRON)
        tube((x, .29, .42), (x, .38, 1.25), .04, IRON)
    tube((-.91, .10, .21), (.91, .10, .21), .025, IRON)
    for y in [-.30, -.15, 0, .15, .30]:
        box((0, y, .50), (2.2, .125, .055), SLATS, .012)
    for z in [.78, .95, 1.12]:
        box((0, .35, z), (2.2, .06, .13), SLATS, .012)
        for x in [-.91, .91]:
            bolt = cylinder((x, .314, z), .018, .012, GOLD, 12)
            bolt.rotation_euler.x = math.pi / 2
    for side in [-1, 1]:
        points = [(side * 1.01, .35, 1.10), (side * 1.01, .29, .86),
                  (side * 1.01, -.24, .82), (side * 1.01, -.32, .73),
                  (side * 1.01, -.24, .51)]
        for start, end in zip(points, points[1:]):
            tube(start, end, .035, IRON)
        box((side * 1.01, .015, .865), (.13, .50, .05), SLATS, .025)
    export('station_bench')


def canopy_frame():
    clear()
    for side in [-1, 1]:
        x = side * 5.4
        box((x, 0, .06), (.50, .46, .12), IRON, .025)
        cylinder((x, 0, .30), .16, .48, IRON, 16, radius_top=.11)
        cylinder((x, 0, 2.25), .075, 3.45, IRON, 16)
        cylinder((x, 0, 4.08), .15, .18, GOLD, 16)
        box((x, 0, 4.24), (.42, .38, .14), IRON, .025)
        # Cast-iron curved spandrels, open to the morning light.
        points = []
        for step in range(9):
            angle = step * math.pi / 16
            points.append((x - side * (1.55 - 1.55 * math.cos(angle)),
                           0, 2.75 + 1.55 * math.sin(angle)))
        for start, end in zip(points, points[1:]):
            tube(start, end, .033, IRON)
        for step in [2, 4, 6]:
            px, py, pz = points[step]
            tube((px, py, pz), (px, py, 4.32), .018, IRON)
    box((0, 0, 4.34), (11.25, .20, .15), IRON, .02)
    # Shallow roof ribs rise toward the ridge. The scene supplies roof panels.
    for side in [-1, 1]:
        tube((side * 5.65, 0, 4.50), (0, 0, 5.45), .055, IRON)
        tube((side * 4.0, 0, 4.45), (side * 2.8, 0, 4.98), .022, GOLD)
    export('station_frame')


def clock():
    clear()
    cylinder((0, 0, .07), .35, .14, IRON, 20)
    cylinder((0, 0, .28), .18, .35, IRON, 16)
    cylinder((0, 0, 1.95), .065, 3.25, IRON, 16)
    for z in [.52, 3.40]:
        cylinder((0, 0, z), .13, .07, GOLD, 16)
    cylinder((0, 0, 3.65), .18, .26, IRON, 16, radius_top=.08)
    for y, radius, depth, surface in [(0, .59, .22, IRON),
                                      (-.13, .56, .035, GOLD),
                                      (-.155, .50, .02, IVORY)]:
        disk = cylinder((0, y, 4.12), radius, depth, surface, 48)
        disk.rotation_euler.x = math.pi / 2
    for hour in range(12):
        angle = hour * math.tau / 12
        mark = box((math.sin(angle) * .415, -.173, 4.12 + math.cos(angle) * .415),
                   (.028 if hour % 3 else .045, .008, .085), BLACK, 0)
        mark.rotation_euler.y = angle
    # Six o'clock: the first ordinary morning after the train.
    box((0, -.19, 4.29), (.023, .018, .34), BLACK, .003)
    box((0, -.205, 4.00), (.04, .018, .24), BLACK, .005)
    pin = cylinder((0, -.22, 4.12), .045, .025, GOLD, 16)
    pin.rotation_euler.x = math.pi / 2
    cylinder((0, 0, 4.82), .055, .14, GOLD, 16, radius_top=.005)
    export('station_clock')


if __name__ == '__main__':
    bench()
    canopy_frame()
    clock()
