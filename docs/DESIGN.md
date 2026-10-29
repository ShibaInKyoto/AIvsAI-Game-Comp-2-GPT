# The Midnight Exchange

A native Windows 10/11 game built in Godot 4.6.3: first-person magical freight salvage aboard an art-deco night train. Standard services begin with four and a half minutes; an optional endless voyage offers successively harder services.

## The porter’s decisions

Explore seven carriages, pack three relics and bank £600 to buy freedom. The first two deliveries grant a free choice of more capacity, quicker movement or quieter lining. A stolen hour adds eighteen seconds when banked. Each bell increases all carried freight by 25% but makes the porter easier to hear. A folded doorway sacrifices its own value to return the remaining cargo home. Aurora muffles the porter and restores composure when banked.

Four passenger commissions consume particular relics for sealed fares. These occupy no satchel slots and survive capture, but must still be banked. Bell bonuses apply to carried freight; sealed fares retain their quoted value. Helped travelers appear at the dawn platform. Winning after helping them unlocks four original first-morning epilogues, kept in the porter's notebook across tickets. This adds a story goal without changing run difficulty. The paused route ledger shows requests, current carriage locations, completed thanks and pending fares.

The conductor patrols the central aisle and responds to noise. Quiet side refuges let him pass. Capture restores carried freight to its moving displays and costs fifteen seconds, preserving savings, upgrades and sealed fares. The choir’s brass organ stop can call him toward its carriage for eighteen seconds, once per service. Nearby noise overrides that diversion; its destination follows the moving organ and respects the sanctuary boundary.

## The moving timetable

The exchange stays fixed while the other six carriages begin in a ticket-dependent order. Freight prices depend on starting depth and remain fixed after moves. T moves the last carriage to the front for two pressure and ten seconds. The counter’s switchboard swaps neighbors for one pressure and six seconds. Carriage geometry, collision, freight, passengers, organ and conductor move consistently.

Pressure starts at three, caps at six, and earns one per cumulative £150 banked. Three adjacencies awaken bonuses: observatory/garden adds time for banked aurora; archive/choir muffles bells inside those rooms; dining/last carriage increases unaccepted passenger offers by 25%. Planning pauses the clock, while the explicit switching costs still apply.

Random and daily UTC tickets share these rules. Endless services reset the train, freight and upgrades while reducing starting time to a minimum of 150 seconds and increasing conductor speed. Voyage score accumulates across services and has its own saved best.

## Art, sound and rendering

Original procedural architecture and modeled furnishings distinguish the observatory, winter garden, dining room, archive, choir and last carriage. Four modeled antiques have separate silhouettes and animated effects. The porter’s gloved hand, leather satchel and selected cargo appear in first person. An original locomotive, viaduct, mist and steam frame the title; helped passengers populate a real-time dawn station.

Static scenery is merged by material while retaining carriage roots and collision. The forest uses four MultiMeshes with shader-based scrolling; the CPU updates four uniforms. A passing village moves as one batched group. The fern has 2,920 triangles, and the modeled pipe organ has 13,364. These are geometry/work counts, not claims about hardware frame rate; cloud rendering uses llvmpipe.

Original generated music, effects and seven carriage textures use no external audio service or recordings. Room changes crossfade; silent loops pause playback. A successful dawn fades out the wheels and night music into a resolved morning theme. Compressed WAV loops use decoded sample-frame counts. The conductor’s chime and organ call use world-space sound. DejaVu fonts retain their notice, and both native ZIPs include engine and third-party notices.

## Code boundaries

- `run_state.gd` isolates economy and run state from rendering and physics.
- `main.gd` composes the world, input, interactions, persistence and exported integration checks.
- `train.gd` owns architecture, collision, scenery, batching and carriage transforms.
- `freight.gd`, `passenger.gd`, `organ.gd` and `conductor.gd` own their respective world behavior.
- `interface.gd`, `sound.gd`, `satchel.gd`, `title_scene.gd` and `dawn.gd` own presentation.
- `profile.gd` validates individual fields, recovers corrupt saves and replaces files only after a complete write.
- `scripts/` regenerates original assets and provisions checksum-verified tools; Blender is optional for rebuilding models.

There are no runtime network services or package dependencies. Asset-generation scripts and their generated assets are committed.

## Validation and its limits

`scripts/validate.sh` checks process exit status and engine/script errors, then runs:

- 103,035 state checks, including 25,000 randomized actions and 1,000 deterministic train orders.
- Profile recovery/replacement, legacy-profile migration and remembered-traveler rules, mixed indexed geometry, fifty sound checks and ten conductor checks.
- Three scene seeds exercising actual interactions, focused Tab input, floor/window collision, quiet evasion, bell dropping, the moving organ diversion, capture and UI transitions.
- A 228m walking/economy soak with twelve physical pickups, two rotations, £655 extraction, dawn and a harder service restart. This harness isolates the conductor; the scene encounter tests exercise live threat.

`scripts/assess_live.gd` is an optional, map-aware porter diagnostic using normal threat/economy rules. It demonstrates possible routes, not novice difficulty or universal balance. It is separate from the deterministic build gate. No human playtest has been claimed.

`scripts/assess_native_input.py` runs an exported Linux executable on a dedicated X11 display through OS mouse/keyboard events. An opt-in observer in `game/debug/` reports state and captures screenshots; it supplies no input or rule changes. The driver uses isolated local data and selects the launched process's window. It checks boarding, a physical pickup and deposit, an upgrade, a paid switchboard click, the passenger page, focused Tab, pause, title and quit. Continuous rendering is the default; checkpoint rendering is an explicit software-display option. This short loop is separate from full-run balance and Windows CI.

GitHub Actions exports Linux and Windows ZIPs and runs the packaged game on native Windows before allowing a tagged release. Local standalone tests and Windows-through-Wine tests supplement CI. Each revision needs its own successful run; earlier results do not certify a later build. See [the development log](DEVELOPMENT_LOG.md) for implementation checkpoints and measurements.

## Competition continuity

Continue in the existing checkout; do not create worktrees. This cloud environment has Godot on PATH and writable XDG locations under `/workspace/.runtime/{data,config,cache}`. The bootstrap script can install verified official binaries/templates elsewhere.

No final release has been declared. Before concluding competition work, verify current exports, ZIP contents, release documentation and that revision’s Windows CI. When work is explicitly concluded, immediately use the existing `v*` tag/GitHub Actions publication path.
