class_name MidnightConductor
extends Node3D
## A readable aisle-bound threat: take the side passages and sneak to let him pass.

var body: Node3D
var lantern: OmniLight3D
var caption: Label3D
const CALL_DURATION := 18.0
var music_source: Node3D
var call_remaining := 0.0
var following_music := false
var phase := 0.0
var patrol_direction := 1.0
var alert := false
var speed := 2.15

func _ready() -> void:
	position = Vector3(0, 0, -78)
	body = preload("res://assets/models/conductor.glb").instantiate()
	add_child(body)
	lantern = OmniLight3D.new()
	lantern.position = Vector3(0.48, 0.78, 0.24)
	lantern.light_color = Color("e48667")
	lantern.light_energy = 3
	lantern.omni_range = 7
	body.add_child(lantern)
	caption = Label3D.new()
	caption.text = "THE CONDUCTOR"
	caption.font = preload("res://assets/fonts/body.ttf")
	caption.font_size = 24
	caption.outline_size = 3
	caption.pixel_size = 0.004
	caption.position.y = 2.9
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.modulate = Color("dda78a")
	add_child(caption)

func answer_choir(source: Node3D) -> void:
	music_source = source
	call_remaining = CALL_DURATION

func face(direction: float) -> void:
	if direction != 0:
		body.rotation.y = 0 if direction > 0 else PI

func advance(delta: float, target: Vector3, noise: float, grace: float) -> float:
	phase += delta
	body.position.y = sin(phase * 2) * 0.065
	var distance := position.distance_to(target)
	call_remaining = maxf(0, call_remaining - delta) if is_instance_valid(music_source) else 0.0
	if call_remaining <= 0:
		music_source = null
	alert = target.z < -12 and distance < noise and grace <= 0
	following_music = call_remaining > 0 and not alert
	if alert:
		var direction := signf(target.z - position.z)
		position.z += direction * delta * (speed + 1.0)
		face(direction)
	elif following_music:
		# Read the source transform each step: shunting carries the sounding organ.
		var destination := clampf(music_source.global_position.z, -108, -17)
		var direction := signf(destination - position.z)
		position.z = move_toward(position.z, destination, speed * delta)
		if direction != 0:
			patrol_direction = direction
		face(direction)
	else:
		position.z += patrol_direction * delta * speed
		if position.z > -17:
			patrol_direction = -1
		elif position.z < -108:
			patrol_direction = 1
		face(patrol_direction)
	position.z = clampf(position.z, -110, -13)
	lantern.light_energy = 3 + sin(phase * 6) * 0.3
	lantern.light_color = Color("ff553a") if alert else (Color("e7c87d") if following_music else Color("e48667"))
	caption.text = "FOLLOWING THE CHOIR" if following_music else "THE CONDUCTOR"
	return clampf(1.0 - distance / 20.0, 0, 1) if target.z < -9 else 0.0
