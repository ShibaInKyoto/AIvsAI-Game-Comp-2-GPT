class_name MidnightPassenger
extends Node3D
## Optional passenger commissions trade a relic for a sealed fare, banked at the exchange.

const NAMES := ["THE ASTRONOMER", "THE ARCHIVIST", "THE SOLOIST", "THE LAST PASSENGER"]
const NEEDS := [3, 0, 1, 2]
const FARES := [75, 90, 95, 110]
const REQUESTS := [
	"I have forgotten the color of the sky. Bring me a bottled aurora.",
	"One hour. That is all I need to write her name before it disappears.",
	"I know the song, but not its sound. A choir bell might remind me.",
	"This train does not stop at my home. Perhaps a folded doorway could."
]
const THANKS := [
	"There. Green, like the sea. I remember the sea.",
	"Her name was June. Please, let it be June wherever you are going.",
	"I shall sing softly. He will not hear me over the wheels.",
	"I can see the kitchen light. She has left it on. Thank you."
]
const MEMORIES := [
	"At dawn the astronomer fills the bottle with seawater. It no longer glows. She spends a long time holding it against the sky, pleased that the two blues are different.\n\nThere is a house above the harbor where she once drew constellations on the ceiling for a child who could not sleep. She buys a brush before she buys breakfast.\n\nThat evening she paints over the stars, one at a time. Then she opens the curtains. The child, grown now, stands in the doorway and tells her which ones she missed.",
	"The archivist uses the hour before the station clock strikes six. He writes June's name on the envelope and again at the top of the page.\n\nThe letter contains no explanation of the train. It asks whether the plum tree survived the winter. It says he remembers the green cup with the broken handle. It says he is sorry he took so long.\n\nAt the address, someone has painted the door blue. He raises his hand to knock. From inside, a woman calls his name before his knuckles reach the wood.",
	"The soloist discovers that the bell makes no sound on the platform. She puts it in her pocket anyway.\n\nIn a small cafe, a radio is playing the tune she spent the journey trying to remember. This time she hears the mistake in its third bar. She laughs, borrows a pencil and writes the missing note on a napkin.\n\nBy evening there are six people around the cafe piano. None of them knows the song. She teaches it to them slowly, leaving room for their mistakes. Under her coat, the little bell rings once.",
	"The last passenger checks the kitchen light twice. It is still on.\n\nHe finds a child asleep at the table beside two cold plates. On one, someone has made a little train out of peas. He sits down very carefully, so the chair will not wake her.\n\nIn the morning she asks where he went. He says he got on the wrong service. She accepts this, then tells him the peas were meant to be a bridge.\n\nHe keeps the folded doorway in a drawer. When he opens it later, there is only a small mirror inside."
]
var identity := 0
var completed := false
var figure: Node3D
var caption: Label3D
var elapsed := 0.0

func _ready() -> void:
	figure = preload("res://assets/models/passenger.glb").instantiate()
	add_child(figure)
	tint_figure(figure)
	caption = Label3D.new()
	caption.text = NAMES[identity]
	caption.position.y = 2.62
	caption.font_size = 22
	caption.pixel_size = 0.004
	caption.modulate = Color("aed1c9")
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(caption)

func tint_figure(node: Node) -> void:
	if node is MeshInstance3D:
		for index in range(node.mesh.get_surface_count()):
			var surface := node.mesh.surface_get_material(index) as StandardMaterial3D
			if surface != null and "enamel" in surface.resource_name.to_lower():
				var tinted := surface.duplicate() as StandardMaterial3D
				tinted.albedo_color = [Color("35515e"), Color("554359"), Color("355c55"), Color("5b505d")][identity]
				node.set_surface_override_material(index, tinted)
	for child in node.get_children():
		tint_figure(child)

func _process(delta: float) -> void:
	elapsed += delta
	figure.position.y = sin(elapsed * 1.3 + identity) * 0.035
	if completed:
		figure.scale = figure.scale.lerp(Vector3(0.85, 0.85, 0.85), delta)
		caption.text = "A TRAVELER HELPED  /  THANK YOU"
