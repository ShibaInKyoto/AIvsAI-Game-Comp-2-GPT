class_name MidnightConductor
extends Node3D
## A readable aisle-bound threat: take the side passages and sneak to let him pass.

var body: Node3D
var lantern: OmniLight3D
var phase := 0.0
var patrol_direction := 1.0
var alert := false
var active := true
var speed := 2.15

func _ready() -> void:
	position = Vector3(0, 0, -78)
	body = Node3D.new()
	add_child(body)
	var coat := StandardMaterial3D.new()
	coat.albedo_color = Color("171e2a")
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("caa16b")
	gold.metallic = 0.6
	var face := StandardMaterial3D.new()
	face.albedo_color = Color("dddac8")
	face.emission_enabled = true
	face.emission = Color("a9bdb9")
	face.emission_energy_multiplier = 0.3
	shape(Vector3(0, 1.15, 0), Vector3(0.65, 1.5, 0.4), coat)
	shape(Vector3(0, 2.08, 0), Vector3(0.32, 0.38, 0.3), face)
	shape(Vector3(0, 2.32, 0), Vector3(0.7, 0.07, 0.6), coat)
	shape(Vector3(0, 2.47, 0), Vector3(0.42, 0.27, 0.38), coat)
	for side in [-1, 1]:
		shape(Vector3(side * 0.4, 1.25, 0), Vector3(0.15, 0.95, 0.2), coat)
		shape(Vector3(side * 0.15, 0.28, 0), Vector3(0.16, 0.45, 0.2), coat)
		shape(Vector3(side * 0.085, 2.12, 0.16), Vector3(0.05, 0.04, 0.02), coat)
	for y in [0.85, 1.1, 1.35, 1.6]:
		shape(Vector3(0, y, 0.21), Vector3(0.055, 0.055, 0.025), gold)
	shape(Vector3(0.47, 0.78, 0.16), Vector3(0.25, 0.35, 0.25), gold)
	lantern = OmniLight3D.new()
	lantern.position = Vector3(0.47, 1.05, 0.2)
	lantern.light_color = Color("e48667")
	lantern.light_energy = 3
	lantern.omni_range = 7
	add_child(lantern)
	var warning := Label3D.new()
	warning.text = "THE CONDUCTOR"
	warning.font_size = 24
	warning.pixel_size = 0.004
	warning.position.y = 2.9
	warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	warning.modulate = Color("dda78a")
	add_child(warning)

func shape(pos: Vector3, size: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.material_override = material
	part.position = pos
	body.add_child(part)

func advance(delta: float, target: Vector3, noise: float, grace: float) -> float:
	phase += delta
	body.position.y = sin(phase * 2) * 0.065
	var distance := position.distance_to(target)
	alert = target.z < -12 and distance < noise and grace <= 0
	if alert:
		var direction := signf(target.z - position.z)
		position.z += direction * delta * (speed + 1.0)
		body.rotation.y = 0 if direction > 0 else PI
	else:
		position.z += patrol_direction * delta * speed
		if position.z > -17:
			patrol_direction = -1
		elif position.z < -108:
			patrol_direction = 1
		body.rotation.y = 0 if patrol_direction > 0 else PI
	position.z = clampf(position.z, -110, -13)
	lantern.light_energy = 3 + sin(phase * 6) * 0.3
	return clampf(1.0 - distance / 20.0, 0, 1) if target.z < -9 else 0.0
