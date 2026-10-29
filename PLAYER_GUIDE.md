# The Midnight Exchange — Porter’s guide

## Starting

Windows 10/11, 64-bit. Extract the ZIP before opening TheMidnightExchange.exe. An OpenGL 3.3-capable graphics driver is required. The executable includes the game data. No installation, network connection or account is required.

Choose **Board a new night** for a random ticket, or **Daily ticket** for the day's shared layout (UTC). A run lasts four and a half minutes, plus any time earned by banking stolen hours. Bank at least £600 to buy your freedom. Continue for a higher score or leave with Q at the exchange. The horizon begins to pale during the final ninety seconds. At dawn, banked freight counts and anything still carried is lost. Each new ticket starts a fresh run.

## Controls

| Action | Control |
| --- | --- |
| Walk / look | WASD / mouse |
| Run / sneak | Hold Shift / hold Ctrl |
| Collect / bank | E |
| Use a folded doorway | F |
| Select a satchel slot | 1–5 |
| Drop the selected relic | X |
| Choose a free upgrade at the counter | 1, 2 or 3 |
| Turn the timetable at the counter | T (2 pressure + 10 seconds) |
| Route ledger / switchboard | Tab |
| Leave with your debt paid | Q at the counter |
| Pause / resume | Escape |
| Lantern on / off | L |
| Fullscreen / window | F11 |

Pause automatically stops the clock when the window loses focus. Sensitivity, sound level, camera motion and your best score are saved locally. Settings are accessible from the title and pause screens.

## Freight

- **Stolen hour:** banking it adds 18 seconds. Deep-carriage hours can be valuable lifelines.
- **Choir bell:** each adds 25% to all carried freight. Sealed passenger fares keep their quoted value. Bells also make you easier to hear.
- **Folded doorway:** press F to consume one and return to the exchange with the rest of your freight. Its own cash value is sacrificed.
- **Bottled aurora:** muffles your presence while carried; banking one restores your composure.

The first two deliveries each grant a free upgrade. Choose a larger satchel, a quicker stride, or quiet lining. The capacity upgrade can be chosen twice, for five slots.

The conductor walks the central aisle. Give him space. Hold Ctrl and step into a gap beside the furniture to let him pass. The HUD confirms when you are quiet enough. A carried bell can betray your hiding place: drop it, carry aurora to muffle it, or keep moving. Running attracts him from farther away. Staying very close drains composure. If he catches you, he returns your current freight to its displays and costs you 15 seconds; your savings and upgrades are safe.

The exchange is a sanctuary. The conductor cannot enter it. T moves the last carriage to the front, shortening some routes—but the conductor travels with his carriage. Listen for his chime and watch for the red lantern.

The chime comes from his position in the train. Turn your head or use headphones to hear his direction; the HUD also warns when he is near and when he hears you.

Stay crouched as you leave cover, until the lantern is farther away. Standing up beside him can restart pursuit. If he is already walking away, quietly follow at a distance rather than waiting for him to complete another patrol.

The choir carriage has a brass organ stop. Face it and press E to call the conductor toward that organ for eighteen seconds. Each night gives it one voice. Nearby footsteps and bells still draw his attention, so move quietly after playing. The organ and his destination follow the choir carriage when you shunt it; the call never brings him into the exchange sanctuary.

## Tips

Bank an early delivery for a free upgrade. A bell is worth more when the rest of your satchel is valuable. Save doorways for long journeys. The timetable changes the route without creating new freight; turning it repeatedly costs precious time. Sneaking is slower but helps you pass safely. You can finish a run even after a bad encounter.

## Local data

Windows: `%APPDATA%/Godot/app_userdata/The Midnight Exchange/porter.json`.
Only settings and the personal best are stored. Deleting this file resets them. There is no telemetry.

The game uses Godot Engine and DejaVu fonts. Their license notices are included beside the executable. Game models, textures, icons and audio were created for The Midnight Exchange; generation scripts are included in the source repository.

## The Long Way Home

For a longer challenge, choose **The Long Way Home** from the title screen. Each successful service lets you board another night. Each service gives you less starting time (down to 150 seconds) and a quicker conductor; your voyage score adds up across services. Satchel, upgrades and freight start fresh on each train. Your best voyage total is saved separately.

Press Tab to open the route ledger. It shows the current order of the carriages and how much freight remains in each. The clock is paused while you read it.

## The passengers

Four travelers have unfinished business. Speak with E when facing one nearby. Each needs a particular kind of relic and offers a sealed fare in exchange. Accepting a commission consumes that relic; the fare does not occupy a satchel slot and survives a conductor encounter. Return to the exchange to bank it. Each passenger can be helped once per run. They travel with their carriage when you turn the timetable.

Press Tab and choose **Passenger commissions** to review requests, current carriage numbers, offers and the travelers you have helped. The ledger also shows the sealed fares still waiting to be banked. Its **Resonance couplings** button returns to the pairing bonuses.

## The switchboard and resonances

At the exchange, press Tab and use the arrows to swap neighboring carriages. Each swap costs 1 pressure and six seconds. The clock and pressure displays update after each swap; ordinary planning time is paused. The exchange cannot move. The T lever rotates the last carriage to the front for 2 pressure and ten seconds. Passengers, freight and the conductor all travel with their carriage.

Three pairings awaken bonuses when the rooms are neighbors:

- **Observatory + winter garden:** each bottled aurora banked grants another 12 seconds.
- **Archive + choir:** bells do not increase your noise while you are inside either room.
- **Dining room + last carriage:** passenger commissions offer 25% larger sealed fares.

The switchboard shows awake and dormant pairings. Room lighting changes with the resonance. All three pairings can be awake at once, but arranging them consumes time and moves the conductor too.


## Boiler pressure

Each ticket starts with 3 pressure; the boiler holds at most 6. Every cumulative £150 banked generates one pressure, so splitting a delivery into small deposits does not create extra fuel. A full rotation costs 2 pressure and 10 seconds; an adjacent swap costs 1 pressure and 6 seconds. The switchboard displays the remaining pressure and clock. If pressure runs low, explore on foot and bring freight back. Initial carriage order varies by ticket, and freight keeps its starting value after shunting.
