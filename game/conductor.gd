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
	body = preload("res://assets/models/conductor.glb").instantiate()
	add_child(body)
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
	lantern.light_color = Color("ff553a") if alert else Color("e48667")
	return clampf(1.0 - distance / 20.0, 0, 1) if target.z < -9 else 0.0
