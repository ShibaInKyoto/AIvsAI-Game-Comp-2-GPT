#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
run_checked() {
  local log
  log="$(mktemp)"
  if ! "$@" > "$log" 2>&1; then
    cat "$log"
    rm -f "$log"
    return 1
  fi
  cat "$log"
  if rg -q 'SCRIPT ERROR:|ERROR:|Assertion failed' "$log"; then
    rm -f "$log"
    return 1
  fi
  rm -f "$log"
}
run_checked "$GODOT_BIN" --headless --path . --editor --import
run_checked timeout 45 "$GODOT_BIN" --headless --path . --script tests/run_state_test.gd
run_checked timeout 45 "$GODOT_BIN" --headless --path . -- --smoke-test

run_checked timeout 60 "$GODOT_BIN" --headless --fixed-fps 120 --path . -- --soak-test
