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
	figure = Node3D.new()
	add_child(figure)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = [Color("35515e"), Color("554359"), Color("355c55"), Color("5b505d")][identity]
	cloth.metallic = 0.15
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("c5ac79")
	gold.metallic = 0.7
	var ivory := StandardMaterial3D.new()
	ivory.albedo_color = Color("c7d9cc")
	ivory.emission_enabled = true
	ivory.emission = Color("6eaaa7")
	ivory.emission_energy_multiplier = 0.3
	var coat := CylinderMesh.new()
	coat.top_radius = 0.2
	coat.bottom_radius = 0.4
	coat.height = 1.4
	coat.radial_segments = 8
	part(coat, Vector3(0, 0.95, 0), cloth)
	var head := SphereMesh.new()
	head.radius = 0.17
	head.height = 0.38
	part(head, Vector3(0, 1.88, 0), ivory)
	var brim := CylinderMesh.new()
	brim.top_radius = 0.3
	brim.bottom_radius = 0.3
	brim.height = 0.045
	part(brim, Vector3(0, 2.07, 0), gold)
	var crown := CylinderMesh.new()
	crown.top_radius = 0.18
	crown.bottom_radius = 0.21
	crown.height = 0.23
	part(crown, Vector3(0, 2.2, 0), cloth)
	for side in [-1, 1]:
		var sleeve := CapsuleMesh.new()
		sleeve.radius = 0.09
		sleeve.height = 0.75
		var arm := part(sleeve, Vector3(side * 0.28, 1.18, 0.05), cloth)
		arm.rotation.z = side * 0.15
	var ticket := BoxMesh.new()
	ticket.size = Vector3(0.3, 0.18, 0.025)
	part(ticket, Vector3(0, 1.1, 0.25), gold)
	caption = Label3D.new()
	caption.text = NAMES[identity]
	caption.position.y = 2.62
	caption.font_size = 22
	caption.pixel_size = 0.004
	caption.modulate = Color("aed1c9")
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(caption)

func part(mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.mesh = mesh
	result.position = pos
	result.material_override = material
	figure.add_child(result)
	return result

func _process(delta: float) -> void:
	elapsed += delta
	figure.position.y = sin(elapsed * 1.3 + identity) * 0.035
	if completed:
		figure.scale = figure.scale.lerp(Vector3(0.85, 0.85, 0.85), delta)
		caption.text = "FARE SEALED  /  THANK YOU"
