# Development log

Historical checkpoint notes follow in implementation order. Statements about pending checks apply to the checkpoint being described. See [the design](DESIGN.md) for current behavior and validation boundaries.

## Earlier overview

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
- Sound suite: 50 checks of imported compressed-loop lengths, room crossfades, dawn/restart and stream cleanup.
- Conductor suite: 10 checks of the single-use choir organ, moving source, noise priority, arrival, expiry and source cleanup.
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

Before a final declaration, verify current native exports, ZIP contents, release documentation and that revision's Windows CI. Continue balance assessment with genuine threat-aware play; the navigation/economy harness intentionally isolates the conductor. No human playtest has been claimed. Do not substitute a prior successful CI run for the current revision.


## Earlier route and pressure checkpoint

Initial carriage order is now deterministically shuffled per ticket. Freight prices are assigned by starting depth and remain fixed after moves. Boiler pressure starts at 3, caps at 6, and earns one per cumulative £150 banked. Rotation costs 2 pressure/10s; adjacent swaps cost 1/6s. This prevents repeated cheap rotations from replacing exploration. The smoke test uses extra pressure only for isolated geometry/resonance stress; the winning route uses normal pressure and a fresh 270-second budget after the independent navigation stress phase.

The moving forest now uses four MultiMesh layers instead of individual tree nodes. Full validation passed after that change: 103,035 state checks, three smoke seeds (90210, 37, 20261028), and the physical winning-route test. Subsequent checkpoints below cover the forest/switchboard captures, native exports and Windows CI. No final release has been declared. Continue independently; the user has not stopped the competition.

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


## Approaching dawn

The sky and ambient light gradually warm during the final ninety seconds. A single final-minute reminder waits for the current notification to finish, then tells the porter to bank freight or use a doorway. The normal timer remains authoritative; hours can delay the visual dawn again. The late-run garden capture rendered correctly, and scene smoke passed after the change. Route-marker revision 0b7441c is awaiting native Windows CI (run 40842493053).


## Native input and event feedback

Native Windows CI passed both route-marker revision 0b7441c and approaching-dawn revision f57902e (runs 40842493053 and 40842861117). The current Linux standalone was exercised through X11 keyboard/mouse events: title interaction, movement, mouse look, pause/resume, conductor capture/recovery, and resizing to the minimum 960×540 window. The interface scales correctly after the resize frame settles. Synthetic input timing under llvmpipe was unreliable, so no complete manual collection/banking or human playtest is claimed; those interactions remain covered by scene integration tests. The native run produced no script/runtime errors.

Folding, banking and capture now give a brief, muted color transition beneath the HUD. This makes instant relocation and delivery changes easier to read without obscuring text. Scene smoke passed with all three event effects executing. The README now links to development build artifacts so visiting judges can find the current Windows ZIP before the final release. No final release has been declared.


## Winter-garden geometry

Folded, ridged leaf meshes and simple curved stems replace the fern's dense beveled pieces. The urn and palette remain consistent. Per-model triangles fell from 48,504 to 2,920 (94.0%); GLB size fell from 1,879,816 to 167,376 bytes. This is an asset geometry/size measurement, not a hardware FPS claim. The new silhouette was inspected in the carriage; import, scene smoke and mixed-geometry batching checks passed. scripts/model_fern.py regenerates the fern independently and is reused by model_props.py. The gameplay screenshot shows the updated foliage. Event-feedback checkpoint 1ca898f passed native Windows CI (run 40844402023).


## Passing villages and live-run assessment

Ten original procedural houses pass outside the train among the trees. Their warm windows, gabled roofs and chimneys are combined into four material batches; only the group transform moves. They use the same travel speed as the forest and add no physics or player interactions. A garden-window capture was inspected. The full state/profile/geometry suites, three scene seeds and physical winning route passed with the new scenery. docs/.gdignore keeps documentation screenshots out of Godot's asset import scan.

The exploratory live porter completed ticket 90210 with £655 and about 76 seconds remaining, surviving one capture under normal clock, pressure and upgrade rules. Other layouts exposed policy failures (poor return paths from cover, repeated evasions, and waiting for the conductor beyond his patrol boundary). A port of that controller into the game did not repeat the success reliably, so it was removed and is not a release gate. Temporary diagnostic source/logs remain at /tmp/midnight-journey.gd and /tmp/midnight-journey*.log in this cloud workspace. This is evidence that a live win is possible, not a claim of universal balance or human playtesting. Further controller work should return to the aisle before long travel, recover cleanly after capture, and account for patrol bounds and folded doorways.

Foliage revision eaa8648 passed native Windows CI (run 40845682627). No final release has been declared.

## Forest scrolling cost

The forest keeps static instance transforms and passes each tree's original center through instance custom data. A world-space vertex shader wraps each complete tree along the same 230m route. The CPU now updates four scroll uniforms instead of rebuilding 400 layer transforms and updating 100 tree positions per frame. Tree basis/scale construction happens once. The fixed custom bounds include the full wrapped range.

The frozen window view matches the previous forest presentation. A fresh Windows export rendered the moving/wrapping forest through Wine without errors; a fresh Linux export passed smoke. This is a reduction in CPU-side update work, not a measured claim about gaming-PC frame rate. Village revision bd0f709 passed native Windows CI (run 40851573858). The shader revision still needs its own pushed CI result. No final release has been declared.

The conductor's light now attaches to the modeled body at the lantern's actual local position, so turning and bobbing carry the light with the hand. The positional chime uses that same world position. A conductor portrait was inspected and the encounter smoke passed after the change. The unused active flag was removed; threat behavior remains governed by patrol, hearing and grace.

## Credits and menu consistency

Settings now contains a credits/notices page with engine and font acknowledgments and the packaged license filenames. It preserves the originating title/pause mode, so returning and resuming work consistently. Settings navigation uses the same styled button helper as the main menu. Credits and settings layouts were rendered and inspected; scene smoke passed after the helper change.

## Counter interaction clarity

A full satchel can now be banked even when dropped freight is under the gaze cone at the counter. Partial/empty satchels can still collect nearby dropped freight first. The focus marker and E prompt follow that same action choice. A scene regression drops a real relic at the counter, fills the satchel, banks successfully, and verifies the floor relic remains available.

Carriage 00 prompts now direct the porter to its brass counter rather than telling them to return to the carriage they already occupy. Upgrade choices remain visible in the manifest while floor loot is targeted. Brief conductor grace is labeled as distraction, and teleport/capture clear stale proximity threat. Full validation passed, including all three scene seeds and the walking route. The return-counter view was inspected.

Cloud graphical checks hit an X11 MIT-SHM access error after the execution transport changed. Restarting the task's dummy Xorg :99 with -extension MIT-SHM resolved it; the repeated capture is free of runtime errors. This is test-display configuration, not a game setting. The current server PID is 55178. Native Windows CI passed forest revision 5102c9f (40853527407), lantern alignment 099a808 (40854488305), and credits 81e2322 (40856990301). The counter revision still needs its own CI result. No final release has been declared.

## The porter's satchel

An original modeled leather satchel, gloved hand and uniform sleeve now frame the selected relic in first person. Selecting, dropping or banking cargo updates the presentation; the view meshes have no collision or freight identity. They remain inside the player's world clearance and cast no shadows. A separate render layer excludes the very close player flashlight, with a gentle view-only fill preserving the leather and glove detail. Camera motion settings control the small walking sway and relic drift.

All four selected relics were inspected in the carriage renderer. The representative garden view adds nine draw calls (130 versus 121 before the satchel); this is not a hardware frame-rate measurement. The full state, profile, geometry, three-seed scene and walking-route suites passed. Fresh Linux standalone smoke passed, and the fresh Windows export rendered the satchel and aurora through Wine without errors. Native Windows CI remains required for this revision. scripts/model_satchel.py regenerates the new asset using the shared Blender helpers.

Counter-interaction revision c37bb26 passed native Windows CI (run 40861278968). No final release has been declared.

## Switchboard readability

The route ledger now gives each carriage a separate row, highlights the porter's current room and uses 48×34 arrow targets in place of 36×20 controls. Disabled, focused and pressed states use the game's palette. The ledger explicitly explains that planning pauses the clock while swapping still spends six seconds. Counter and read-only views were inspected, including the minimum 960×540 window. Scene smoke passed, including focused Tab input and an actual button-triggered swap with its exact time/pressure charge. The capture helper now refreshes the ledger after its requested camera position, so the screenshot's YOU marker corresponds to that room.

## Reproducible live-conductor assessment

scripts/assess_live.gd preserves the revised diagnostic porter outside the shipped game and deterministic build gate. It follows a receding patrol quietly, brakes before movement waypoints, stays crouched when leaving cover, and handles captures without abandoning a viable run. The input/save override does not alter time, pressure, starting grace, freight, movement speed or conductor rules. It knows the entire freight layout and prioritizes valuable carriages, so its results show possible routes rather than novice difficulty.

The policy completed tickets 90210 (£717, 202.6s left), 37 (£632, 247.5s), 20261028 (£630, 226.4s), and 20261029 (£699, 235.4s). Each used normal banked-hour bonuses and finished with no captures; no bells were abandoned. The first three used the temporary controller before source cleanup; the daily ticket used the checked-in script path. This replaces the earlier unreliable center-aisle policy as the current assessment tool. It remains optional because heuristic failures do not establish that a ticket is impossible. No human playtest has been claimed.

Native Windows CI passed the satchel revision 64a455a (run 40866572885) and switchboard revision a8f8218 (40867143462). No final release has been declared.

## Rooms heard and a morning earned

Seven original, quiet twelve-second carriage textures add clock ticks, glass harmonics, wind/leaves, porcelain, pages, organ breath and a distant melody. They follow room identity when the timetable changes. Room changes crossfade over 0.9 seconds, and silent loops pause playback. At a successful dawn, the train wheels and night score fade out over 1.5 seconds into an original twenty-four-second D-major theme. Returning to title or boarding another service restores the night audio. Shutdown stops transition processing before releasing streams.

Audio integration exposed an existing loop-length defect: imported WAVs use QOA compression, so raw byte count was truncating the music and rail loops. Loop boundaries now use decoded duration × sample rate. The fifty-check sound suite loads the actual imported resources and exercises the complete dawn/restart lifecycle. Eight new WAV files regenerate byte-for-byte, remain below clipping, and have zero-valued endpoints. The generator uses only Python's standard library; no external recordings are used.

The full state/profile/geometry/sound suites, three scene seeds and walking route passed. Fresh Linux standalone smoke and Windows-through-Wine smoke also passed. Native Windows CI still needs to verify this revision. No human listening test or hardware frame-rate claim has been made. No final release has been declared.

## Passenger ledger and fare wording

The paused route ledger now has a passenger page showing all four requests, current carriage locations, current offers, completed thanks and the total sealed fares still to bank. Switching pages preserves the same route and switchboard controls. Locations follow actual passenger positions after shunting, and unaccepted offers reflect the current dining/last-carriage resonance. Completed entries do not imply an already banked fare remains pending.

The page was rendered normally and with a completed-passenger/£75 presentation fixture at 960×540. That fixture used the real page button and an actual timetable rotation, verifying the astronomer's carriage changed from 01 to 02. Scene smoke passed after the new page and signal connection. The existing bell math is unchanged: bonuses apply to carried freight, while sealed fares retain their quoted value. HUD, relic prompt and guide wording now say this consistently.

Native Windows CI passed the live-assessment checkpoint 5a46bf2 (40868649503) and audio checkpoint c41f87d (40870264952). This ledger revision still needs its own native check. No final release has been declared.

## The choir's one voice

A brass stop on the choir's existing organ can now be played with E once per run. Its original three-second chord calls the conductor toward that organ for eighteen seconds. Nearby noise takes priority, so the call does not grant immunity. When he arrives he waits until the call expires, then resumes patrol. The destination reads the organ's current transform and respects the sanctuary boundary. The organ is a child of the choir carriage and remains spent after shunting or capture; a new service restores its voice.

The conductor's caption and warm lantern identify when he is following the music. The choir's arrival text and contextual prompt explain the action. The organ source and conductor chime share a positional sound helper. The new organ component has one small mesh and a caption, with no per-frame processing or collision.

Ten conductor checks cover source movement/removal, noise priority, arrival, expiry, normal patrol, the sanctuary boundary and one-use activation. Scene smoke now uses the actual gaze/E path, verifies that activation grants no grace, shunts the sounding organ through the real counter, and verifies ordinary footsteps still interrupt the call. The service-restart test also checks that the new organ is unused. The full state/profile/geometry/sound/conductor suites, three scene seeds and walking route passed. Fresh Linux smoke and Windows-through-Wine smoke/rendering passed. The organ and conductor captions now use the body font with thinner outlines. Native Windows CI still needs to verify this revision.

Passenger-ledger revision c282a7b passed native Windows CI (run 40871192372). No final release has been declared.

## A modeled choir instrument

An original Blender organ replaces the primitive cabinets: nine hollow speaking pipes, an arched walnut case, velvet backing, enamel fan panels, a full keyboard and a pedalboard. Its four placements retain the existing rectangular collision footprint and carriage-relative stop position. Geometry remains merged into the choir's material batches.

Single-step bevels keep the small trim and key highlights while reducing the modeled draft from 34,884 to 13,364 triangles (61.7%) and its GLB from 1,775,976 to 676,444 bytes (61.9%). This compares two drafts of the new model, not the earlier primitives, and is not a hardware FPS measurement. The shared modeling helpers retain their three-segment defaults for existing generators; the organ explicitly chooses one segment.

The modeled draft passed the full validator. After bevel reduction, geometry, scene smoke and the walking route passed again. Fresh Linux standalone smoke and Windows-through-Wine smoke/rendering passed with the final model. Close and carriage-wide views were inspected. scripts/model_organ.py reproduces the asset. Current design documentation now lives in DESIGN.md, with historical checkpoint details retained here.

Organ-interaction revision fc62989 passed native Windows CI (run 40932350113). This model revision still needs its own CI result. No final release has been declared.

## The people remembered

Winning after helping a traveler now records that person's first morning in the porter's notebook. Four original epilogues give separate tickets a persistent story goal without changing freight, difficulty or rewards. The notebook opens from the title's guide page, previews unmet requests, selects an already remembered traveler by default, and shows progress on the title. Escape closes title pages and returns results to a rebuilt title scene; the scene test checks this with a focused notebook button.

Profile version two adds a four-bit record of remembered travelers. Older scores/settings remain intact, losses keep old memories without granting new ones, and repeated wins merge the record. Fractional, nonfinite and out-of-range memory data is rejected. Thirty-six profile checks cover migration, outcomes, corrupt fields, serialization and replacement. The exported scene smoke also replaces an isolated profile containing these records.

The full validator passed. A presentation fixture used the real winning-run hook to unlock all four, navigated through the actual notebook buttons and returned to a title showing 4/4; it did not write the user's save. Locked and all four unlocked pages were inspected. Fresh Linux standalone and Windows-through-Wine smoke passed, including the focused Escape checks. The Windows export rendered the notebook, four-traveler result and fresh title without errors. The public notebook screenshot shows the locked page to preserve the epilogues' discovery.

Modeled-organ revision 9ab557b passed native Windows CI (run 40935138870). This notebook revision still needs its own CI result. No human playtest or final release has been declared.

## A native keyboard and mouse banking loop

The exported Linux executable now has an optional observer for OS-input checks. It reports ordinary scene state and captures transition screenshots, without supplying actions, changing rules or instantiating during normal play. The external Python driver uses X11 keyboard/mouse events, fresh isolated local data and the launched process's window. Release stdout is buffered, so complete state snapshots use replace-on-success files; event logs retain just transitions.

Continuous-rendering checks boarded from the title, walked to a first-carriage display, turned the camera, collected with E, returned and banked, chose capacity, clicked a paid shunt, opened passenger commissions, closed the focused route with Tab, paused, returned to title and quit cleanly. The checked-in driver banked £24 on ticket 313266, with zero captures, then verified exactly one pressure and six seconds spent on the shunt. Screenshots were inspected. An earlier checkpoint-rendering variant also passed, but continuous rendering is the reproducible driver's default. These are short automated input loops on Linux software rendering, not human playtests, whole-run balance checks or hardware FPS measurements.

The full validator passed, including all three scene seeds and the walking soak. Fresh Linux standalone smoke and Windows-through-Wine standalone smoke passed. Native Windows CI passed the remembered-travelers revision b676789 (run 40939851025); this observer revision still needs its own CI result. No final release has been declared.

## Four travelers, four silhouettes

The shared passenger model has been replaced by four original figures: the astronomer's blue wool, broad brim, brass constellation and collapsed telescope; the archivist's plum coat, spectacles and ribbon-marked book; the soloist's green shoulder wrap, beret and modeled musical staff; and the last passenger's gray cap, striped scarf and travel case. They now face the aisle aboard the train and face the platform camera at dawn. Interaction positions and fares are unchanged. Captions use the same readable body font as the conductor.

Single-step bevels keep the four figures to 15,376 triangles combined, versus 27,808 for four instances of the earlier shared figure (44.7% fewer). Unique asset files total 657,728 bytes versus the old shared asset's 319,608 bytes. This trades a small download increase for individual identities while reducing instance geometry; no hardware FPS claim is implied. model_passengers.py reproduces them, and the complete props generator calls it too. The unused shared asset and tint-duplication code were removed.

All four carriage views and the four-traveler dawn fixture were rendered and inspected. The full validator, fresh Linux standalone smoke and Windows-through-Wine smoke passed. The Windows executable also rendered the soloist and choir. Native Windows CI passed input-observer revision d709dec (run 40943261211); this art revision still needs its own CI result. No final release has been declared.

## Interact with what you can see

A focused review reproduced a real targeting defect: a passenger within 2.4m could be selected through a solid carriage partition. The physics ray hit the wall while the old gaze/distance check still selected the traveler. Freight, passengers and the organ now require an unobstructed world-space view. The ray excludes the porter's own capsule. Distant or out-of-cone objects do not issue ray queries, and the existing generous gaze cones remain.

With walls now respected, dropping against furniture also needed a safe destination. If the intended drop spot is blocked, the relic falls at the porter's feet. Scene smoke verifies that a partition blocks a traveler and nearby freight, a clear aisle view permits interaction, and a relic dropped toward its pedestal can be recovered. Existing quiet bell-drop/recovery and organ gaze checks remain in the suite.

The full validator, all three scene seeds and walking soak passed. Fresh Linux and Windows-through-Wine standalone smoke passed. The continuous-rendering OS-input driver banked £21 on ticket 574523 with no captures, then completed upgrades, switchboard clicks, ledger and menu transitions. Native Windows CI passed traveler-art revision 9372554 (run 40944559130); this targeting revision still needs its own CI result. No final release has been declared.
