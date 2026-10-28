# The Midnight Exchange

A native Windows 10/11 game built in Godot 4.6.3. First-person magical freight salvage aboard an art-deco night train. Four-and-a-half-minute standard runs; optional escalating endless services.

## Player decisions

A satchel holds only three relics initially. A stolen hour extends the deadline when banked. Bells multiply the entire cargo delivery but draw the conductor. A folded doorway sacrifices its value to bring the rest home. Aurora muffles the porter and restores composure when banked.

The timetable lever moves the last carriage to the front for ten seconds. All geometry, freight, passengers and the conductor travel consistently with the carriage. Adjacent carriages can also be swapped on the switchboard for six seconds. The exchange remains fixed. Specific adjacencies awaken resonances: observatory/garden adds time when banking aurora, archive/choir muffles bells inside those rooms, and dining/last carriage increases passenger fares. Swaps move complete geometry, freight, people and the conductor. The route is a spatial planning puzzle as well as a shortcut.

Four optional passenger commissions consume particular relics in return for sealed fares. Those fares survive capture but still need to reach the counter. This trades immediate utility for story and a reliable payout. People helped appear on the dawn platform.

Bank £600 to buy freedom. Leave early or pursue a larger score. Capture returns freight to its displays and costs time, preserving both savings and the possibility of recovery. The first two deliveries earn free upgrades. Endless services reset the train and increase pressure, recording an aggregate voyage best.

## Art and audio

Procedural 3D architecture and furnishings for an observatory, winter garden, dining room, archive, choir and final carriage. Brass, teal fan wallpaper, warm lamps, velvet and an original woven runner. A procedural aurora and passing forest establish the moving train. Original generated ambient composition, rail rhythm and effects require no external audio service. Original Blender-modeled settees, telescopes, ferns, dining settings, bookcases, luggage and masked characters replace the initial block placeholders. A player lantern casts local shadows and can be toggled with L. Fonts are DejaVu, with their license retained.

Static carriage meshes are merged by material. A representative dining-room capture dropped from 905 to 254 draw calls (72% reduction), while preserving movable carriage roots and collision transforms. This is a draw-call comparison, not a claim about hardware frame rate. Cloud rendering uses Mesa llvmpipe, not the judges' GPUs.

## Architecture

Simulation/economy (`run_state.gd`) is independent of the scene tree. Main composes physics, input, persistence and interactions. Train owns architecture and route changes. Freight, passengers, conductor, UI, sound and the dawn station have separate modules. There are no network services or runtime package dependencies.

## Validation

- State suite: 103,035 checks, including 25,000 randomized actions across 100 seeds, plus 1,000 deterministic initial train orders.
- Scene smoke: pickup/drop/recover/bank, upgrades, actual switchboard button and exact time charge, all three resonance effects, passenger trade, actual floor and window collision, folding, conductor collision/recovery, result/route/settings UI.
- Walking route: 228m aisle round trip, twelve physical pickups, two rotations, separately timed £655 extraction, dawn scene and restart into a harder service.
- Release exports use explicit checks, never stripped `assert()` calls.
- Native Windows CI is required before a tagged release. Milestones 9fdd01e and f4eb370 passed Windows CI; current revisions must pass their own run.
- Linux and Windows standalone exports are also tested locally (Windows through Wine). Wine supplements actual Windows CI.
- A cache-free import also passed the entire suite with the modeled assets. Graphical captures inspect gameplay, menus and dawn results. No human playtest has been claimed.

## Continuity and release

Use the existing checkout; cloud tasks are isolated already. Do not create worktrees. Use `scripts/validate.sh`, which checks process status and engine/script errors in addition to explicit outcomes. Godot is available on PATH; writable XDG locations in this environment are `/workspace/.runtime/{data,config,cache}`. `scripts/bootstrap_godot.py` can provision checksum-verified official binaries and export templates if needed.

Push verified milestones to main. Pushes create ZIP artifacts and run actual Windows tests. A `v*` tag triggers the release job only after Linux and Windows validation succeed. When competition work is explicitly concluded, publish through that GitHub Actions path. No final release has been declared yet.

## Remaining release work

Inspect latest route/title/results layouts, run the full validator and current native exports, push the completed revision, and verify that revision's Windows CI. Confirm release documentation and ZIP contents. Do not substitute a prior successful CI run for the current revision.


## Latest checkpoint after environment restart

Initial carriage order is now deterministically shuffled per ticket. Freight prices are assigned by starting depth and remain fixed after moves. Boiler pressure starts at 3, caps at 6, and earns one per cumulative £150 banked. Rotation costs 2 pressure/10s; adjacent swaps cost 1/6s. This prevents repeated cheap rotations from replacing exploration. The smoke test uses extra pressure only for isolated geometry/resonance stress; the winning route uses normal pressure and a fresh 270-second budget after the independent navigation stress phase.

The moving forest now uses four MultiMesh layers instead of individual tree nodes. Full validation passed after that change: 103,035 state checks, three smoke seeds (90210, 37, 20261028), and the physical winning-route test. A graphical capture of the new forest and updated switchboard, current Windows exports/CI, and release packaging remain outstanding. Do not declare development finished or tag a final release yet. Continue independently; the user has not stopped the competition.
