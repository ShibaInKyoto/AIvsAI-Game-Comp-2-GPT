class_name MidnightFreight
extends Node3D
## Freights have a persistent identity; visual animation never changes interaction position.

const TYPES := ["Stolen hour", "Choir bell", "Folded doorway", "Bottled aurora"]
const COLORS := [Color("84d4d0"), Color("edb568"), Color("c4a3ed"), Color("a3d7a0")]
var kind := 0
var value := 0
var serial := 0
var visual: Node3D
var phase := 0.0
var taken := false

func configure(type: int, price: int, identity: int) -> void:
	kind = type
	value = price
	serial = identity
	phase = float(identity) * 1.73

func _ready() -> void:
	visual = Node3D.new()
	add_child(visual)
	var frame := StandardMaterial3D.new()
	frame.albedo_color = Color("b99b65")
	frame.metallic = 0.75
	var glow := StandardMaterial3D.new()
	glow.albedo_color = COLORS[kind]
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.emission_enabled = true
	glow.emission = COLORS[kind]
	glow.emission_energy_multiplier = 0.65
	var core := MeshInstance3D.new()
	if kind == 0:
		var sphere := SphereMesh.new()
		sphere.radius = 0.22
		sphere.height = 0.44
		core.mesh = sphere
	elif kind == 1:
		var bell := CylinderMesh.new()
		bell.top_radius = 0.1
		bell.bottom_radius = 0.3
		bell.height = 0.42
		core.mesh = bell
	elif kind == 2:
		var prism := PrismMesh.new()
		prism.size = Vector3(0.42, 0.55, 0.16)
		core.mesh = prism
	else:
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.15
		capsule.height = 0.5
		core.mesh = capsule
	core.material_override = glow
	visual.add_child(core)
	for height in [-0.34, 0.34]:
		var rim := MeshInstance3D.new()
		var ring := CylinderMesh.new()
		ring.top_radius = 0.34
		ring.bottom_radius = 0.34
		ring.height = 0.06
		rim.mesh = ring
		rim.position.y = height
		rim.material_override = frame
		visual.add_child(rim)
	for x in [-0.29, 0.29]:
		for z in [-0.29, 0.29]:
			var post := MeshInstance3D.new()
			var rod := BoxMesh.new()
			rod.size = Vector3(0.035, 0.7, 0.035)
			post.mesh = rod
			post.position = Vector3(x, 0, z)
			post.material_override = frame
			visual.add_child(post)

func _process(delta: float) -> void:
	phase += delta
	visual.position.y = sin(phase * 1.5) * 0.07
	visual.rotation.y += delta * 0.25

func title() -> String:
	return TYPES[kind]

func effect() -> String:
	return ["Bank: +18 seconds", "Loud: attracts the conductor • +25% trip bonus", "F: consume to fold home, keeping other freight", "Bank: restores composure"][kind]
