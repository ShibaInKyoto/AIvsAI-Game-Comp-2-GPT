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

## Stealth and input review

The quiet-side-passage mechanic now has a 1.5m base crouched hearing radius, with bells adding 3.5m each and aurora/lining reducing it. This lets the conductor pass a quiet porter, while noisy cargo remains a deliberate risk. The scene test physically enters a side refuge, verifies initial pursuit, injects Ctrl, waits for the live patrol to pass, then verifies that a carried bell attracts him again. It also injects Tab with a focused switchboard button. All three smoke seeds and the full state/navigation suite passed. Passenger completion prompts no longer suggest a fare remains unbanked after delivery. Native Windows CI passed the preceding f0cac58 checkpoint; this change still needs its own CI run.

## Original relic art

Four original Blender antiques replace the shared cage primitives: a pocket watch, hollow choir bell, folding miniature doorway and glass aurora bottle. The doorway and bottle use animated material effects; their identities and interaction positions remain unchanged. All four were inspected in the actual renderer. Geometry helpers now live in scripts/modeling.py and are shared by the prop/relic generators. Rebuilding props preserved dimensions, counts and material layout but Blender produced small triangulation/normal differences, so the existing prop binaries were retained. The full validator and fresh Linux export passed. Engine/font notices are included in native ZIP packaging. The stealth milestone baef534 passed native Windows CI.

## Title scene, profile handling and directional sound

The title menu now presents an original modeled locomotive crossing a moonlit viaduct, with animated steam, valley mist and camera drift. The field guide has its own button; settings and quitting are accessible from the title. Camera motion settings also govern the title camera. The composed title view measured 40 draw calls under llvmpipe; the scene alone measured 22. Four-sample 3D anti-aliasing smooths geometry edges. Long notification text now wraps above the HUD. The full four-passenger dawn epilogue was visually checked and fits its panel.

Conductor chimes now use a real 3D sound source. The profile module validates each field independently, recovers from corrupt JSON, and replaces the saved file only after a complete write. Sixteen profile checks cover invalid fields, limits, replacement and interrupted writes. Exported scene smoke tests also replace an isolated QA profile, including on native Windows CI.

Title work exposed an indexed/non-indexed mesh batching defect. The shared batcher now normalizes non-indexed custom surfaces before appending them; a regression checks that custom triangles remain referenced when merged with a cube. The state, profile, geometry, three-seed scene and walking-route suites passed. Fresh Linux standalone smoke passed, and title/results captures rendered cleanly. The preceding relic-art commit 320e02f passed native Windows CI. This checkpoint needs its own pushed CI result before it is treated as Windows-verified.

Continue independent development after this checkpoint; no final release has been declared. Preserve the existing checkout and pending work across model/usage changes. User switched reasoning effort from Ultra to High to conserve budget and may switch model; this does not change the game requirements or authorize a final declaration.

## Cargo recovery checkpoint

Native Windows CI passed title/profile checkpoint 8873f35 (run 40840321227). The Windows export also rendered the title scene under Wine and passed exported smoke, including profile replacement.

A later recovery audit found that dropped-and-recollected freight returned to the drop location on capture despite the display-return rule. Each relic now tracks its display independently of its current physical location. Both positions follow their respective carriage during shunting; capture restores the relic to the moving display. The scene regression drops/recollects a real relic at the exchange, moves its original carriage away and back, then checks actual conductor capture restores it and releases its collection identity. All three ticket seeds and the physical winning route passed. This recovery change needs its own native Windows CI result.

## Targeting and stealth clarity

The relic under the player's gaze now shows a brass focus ring and a world-space name/value prompt. A full satchel changes that prompt to SATCHEL FULL. Passenger interactions suppress relic highlighting so the displayed target matches E's action. The gameplay screenshot now shows the modeled aurora bottle and current HUD. Loss text explicitly says that each new ticket starts fresh, avoiding a suggestion that banked cash carries between independent runs.

The quiet encounter regression now uses a real bell: it attracts pursuit, is dropped in a refuge, lets the live conductor pass, and is collected again with E. Full validation passed before the final text-only clarification: state, profile, geometry, three smoke seeds, and the physical route. Cargo-recovery commit 9ba8837 passed native Windows CI (run 40840647014).

A diagnostic attempt to run the center-aisle collection bot with the conductor enabled failed (£356), because that bot walks straight through him and repeatedly gets caught. The experimental flag was removed. This does not establish human balance; no live-threat winning route or human playtest has been claimed. Future balance work should use a threat-aware route policy, retaining the separate deterministic navigation/economy checks and genuine encounter tests. No final release declaration has been made.

The route ledger now marks the player's current carriage with [YOU], using the same slot calculation as the live room HUD. The switchboard capture confirms the marker fits before the arrow controls, and scene smoke passed after the navigation change. Targeting/stealth checkpoint 7b642ee passed native Windows CI (run 40841908954).
