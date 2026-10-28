# The Midnight Exchange

A native Windows Godot 4 game. You are the night porter on a train carrying impossible freight. Salvage cargo from unstable carriages and return it to the exchange before the train reaches dawn.

## Pillars
- A coherent world: amber lamps, midnight blue landscape, brass and red velvet.
- Physical route choices: cargo is both reward and a burden; choose when to turn back.
- Runs that tell stories through room arrangements, freight and escalating instability.
- Responsive controls, clear interactions and explicit danger; no unexplained failures.

## Development sequence
1. Playable foundation: movement, carriage generation, freight, extraction, results.
2. Distinctive cargo effects and procedural routes; risk and reward choices.
3. Art direction, sound, feedback, accessibility and tutorial.
4. Automated simulation, Windows export, release workflow and playtesting.

## Continuity
Use the existing checkout; cloud tasks are isolated already. Do not create worktrees.
Run `godot --headless --path . --editor --import` to validate resources.
Run `godot --headless --path . -- --smoke-test` for the gameplay smoke test.
Maintain progress here and commit meaningful milestones. Never declare the project finished until a native Windows export and the full loop have been validated. Publish using GitHub Actions when the competition ends or development is explicitly concluded.

## Current milestone
Foundation in progress. No final release declared.
