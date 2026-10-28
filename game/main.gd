extends Node3D
## Procedural train foundation. All geometry is local and requires no external assets.

const CAR_LENGTH := 18.0
const CAR_COUNT := 7
const SPEED := 5.0
var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var prompt: Label
var freight: Array[Node3D] = []
var carried := 0
var banked := 0
var remaining := 180.0
var ended := false
var yaw := 0.0
var pitch := 0.0
var rng := RandomNumberGenerator.new()
var smoke := false

func material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = 0.65
	return result

func box(pos: Vector3, size: Vector3, mat: Material, solid := true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var volume := BoxShape3D.new()
		volume.size = size
		collision.shape = volume
		body.add_child(collision)
		mesh.add_child(body)
	return mesh

func _ready() -> void:
	smoke = "--smoke-test" in OS.get_cmdline_user_args()
	rng.seed = 90210 if smoke else Time.get_ticks_usec()
	var world := WorldEnvironment.new()
	var atmosphere := Environment.new()
	atmosphere.background_mode = Environment.BG_COLOR
	atmosphere.background_color = Color("101a30")
	atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.ambient_light_color = Color("98aec7")
	atmosphere.ambient_light_energy = 0.65
	world.environment = atmosphere
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-35, -25, 0)
	moon.light_color = Color("8daed9")
	moon.light_energy = 0.7
	add_child(moon)
	build_train()
	build_player()
	build_hud()
	if "--capture" in OS.get_cmdline_user_args():
		call_deferred("capture_frame")
	if smoke:
		call_deferred("smoke_test")
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func capture_frame() -> void:
	for frame in range(30):
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/midnight-foundation.png")
	get_tree().quit()

func build_train() -> void:
	var wood := material(Color("302a33"))
	var brass := material(Color("b18b4d"), 0.65)
	var velvet := material(Color("542c3b"))
	var dark := material(Color("111b2b"))
	for car in range(CAR_COUNT):
		var z := -car * CAR_LENGTH
		box(Vector3(0, -0.2, z), Vector3(7, 0.4, CAR_LENGTH), wood)
		box(Vector3(0, 3.5, z), Vector3(7, 0.3, CAR_LENGTH), dark)
		for side in [-1, 1]:
			box(Vector3(side * 3.5, 0.55, z), Vector3(0.2, 1.1, CAR_LENGTH), velvet)
			box(Vector3(side * 3.5, 2.95, z), Vector3(0.2, 1.0, CAR_LENGTH), wood)
			for section in range(6):
				box(Vector3(side * 3.5, 1.8, z - 7.5 + section * 3), Vector3(0.2, 1.7, 0.16), brass)
			# Invisible glazing keeps the porter safely aboard.
			var glass := material(Color(0.1, 0.2, 0.3, 0.12))
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			box(Vector3(side * 3.5, 1.8, z), Vector3(0.1, 1.5, CAR_LENGTH), glass)
		for edge in [-1, 1]:
			box(Vector3(edge * 2.4, 1.7, z - 9), Vector3(2.2, 3.4, 0.2), wood)
		box(Vector3(0, 0.015, z), Vector3(1.8, 0.03, 17.5), velvet, false)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 2.9, z)
		lamp.light_color = Color("ffd08b")
		lamp.light_energy = 2.0
		lamp.omni_range = 11
		add_child(lamp)
		box(Vector3(0, 3.1, z), Vector3(0.7, 0.12, 0.7), brass, false)
		if car > 0:
			for item in range(3):
				var cargo := box(Vector3(rng.randf_range(-2.5, 2.5), 0.5, z + rng.randf_range(-6, 6)), Vector3(0.7, 1, 0.7), brass, false)
				cargo.set_meta("value", rng.randi_range(2, 5) * car)
				freight.append(cargo)
			for side in [-1, 1]:
				box(Vector3(side * 2.5, 0.4, z + 3), Vector3(1.2, 0.8, 2.5), velvet)
	box(Vector3(0, 1.7, 9), Vector3(7, 3.4, 0.2), wood)
	box(Vector3(0, 1.7, -CAR_COUNT * CAR_LENGTH + 9), Vector3(7, 3.4, 0.2), wood)
	box(Vector3(0, 0.4, 5), Vector3(2.0, 0.8, 1), brass)
	for i in range(80):
		var distance := rng.randf_range(18, 90)
		var side := -1 if i % 2 == 0 else 1
		box(Vector3(distance * side, -3, rng.randf_range(-150, 50)), Vector3(rng.randf_range(2, 7), rng.randf_range(5, 18), 4), dark, false)

func build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 0.1, 2)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	collider.shape = capsule
	collider.position.y = 0.85
	player.add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.6
	camera.fov = 80
	player.add_child(camera)
	add_child(player)

func build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := ColorRect.new()
	panel.color = Color(0.025, 0.035, 0.06, 0.85)
	panel.position = Vector2(24, 24)
	panel.size = Vector2(650, 116)
	canvas.add_child(panel)
	hud = Label.new()
	hud.position = Vector2(42, 35)
	hud.add_theme_font_size_override("font_size", 22)
	canvas.add_child(hud)
	prompt = Label.new()
	prompt.position = Vector2(42, 610)
	prompt.add_theme_font_size_override("font_size", 22)
	canvas.add_child(prompt)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(634, 347)
	canvas.add_child(crosshair)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.3, 1.3)
		player.rotation.y = yaw
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		if event.keycode == KEY_E and not ended:
			interact()
		if event.keycode == KEY_R and ended:
			get_tree().reload_current_scene()

func nearest_freight() -> Node3D:
	var nearest: Node3D = null
	var distance := 2.3
	for cargo in freight:
		var candidate := player.position.distance_to(cargo.position)
		if candidate < distance:
			distance = candidate
			nearest = cargo
	return nearest

func interact() -> void:
	if player.position.distance_to(Vector3(0, 0, 5)) < 3:
		banked += carried
		carried = 0
		return
	var cargo := nearest_freight()
	if cargo != null:
		carried += int(cargo.get_meta("value"))
		freight.erase(cargo)
		cargo.queue_free()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if not ended and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var direction := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		direction = player.transform.basis * direction.normalized()
		var speed := SPEED / (1.0 + carried * 0.009)
		player.velocity.x = direction.x * speed
		player.velocity.z = direction.z * speed
		player.velocity.y -= 20 * delta
		player.move_and_slide()
	if not ended:
		remaining = maxf(0, remaining - delta)
		if remaining <= 0:
			ended = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.text = "THE MIDNIGHT EXCHANGE\nDawn in %d:%02d   |   Banked £%d   |   Carrying £%d\nWASD move · Mouse look · E collect / bank · Esc pause" % [int(remaining) / 60, int(remaining) % 60, banked, carried]
	if ended:
		prompt.text = "DAWN ARRIVES  —  £%d safely exchanged.\nUnbanked freight is lost. Press R for another journey." % banked
	elif player.position.distance_to(Vector3(0, 0, 5)) < 3:
		prompt.text = "E  •  Exchange your freight here. Venture deeper for more valuable cargo."
	elif nearest_freight() != null:
		prompt.text = "E  •  Take freight worth £%d" % int(nearest_freight().get_meta("value"))
	else:
		prompt.text = "Deeper carriages hold richer freight. Return to the brass counter to bank it."

func smoke_test() -> void:
	assert(freight.size() == 18, "Freight generation failed")
	var cargo := freight[0]
	var value := int(cargo.get_meta("value"))
	player.position = cargo.position
	interact()
	assert(carried == value and freight.size() == 17, "Collection failed")
	player.position = Vector3(0, 0.1, 4)
	interact()
	assert(banked == value and carried == 0, "Banking failed")
	remaining = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(ended, "Run completion failed")
	print("SMOKE PASS: generation, collection, banking, run completion")
	get_tree().quit()
