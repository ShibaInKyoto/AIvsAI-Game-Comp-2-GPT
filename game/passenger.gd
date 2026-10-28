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
		caption.text = "FARE SEALED  /  THANK YOU"
