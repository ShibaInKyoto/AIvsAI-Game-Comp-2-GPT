extends Node3D
## Composition root: input, physics and presentation coordinate the isolated run simulation.

const SAVE_PATH := "user://porter.json"
var run: MidnightRun
var train: MidnightTrain
var conductor: MidnightConductor
var player: CharacterBody3D
var camera: Camera3D
var interface: MidnightInterface
var sound: MidnightSound
var freight: Array[MidnightFreight] = []
var passengers: Array[MidnightPassenger] = []
var world_root: Node3D
var atmosphere: Environment
var sky_material: ShaderMaterial
var moon: DirectionalLight3D
var playing := false
var paused := false
var yaw := 0.0
var pitch := 0.0
var energy := 100.0
var sprint_exhausted := false
var grace := 10.0
var threat := 0.0
var notice_time := 0.0
var step_time := 0.0
var elapsed := 0.0
var movement_time := 0.0
var sensitivity := 1.0
var motion := 0.35
var volume := 0.65
var best := 0
var best_voyage := 0
var last_ticket := 0
var smoke := false
var test_failed := false
var capture := false
var sneaking := false
var test_direction := Vector3.ZERO
var service := 0
var voyage_total := 0
var visited: Dictionary = {}

func _ready() -> void:
	get_tree().auto_accept_quit = false
	smoke = "--smoke-test" in OS.get_cmdline_user_args() or "--soak-test" in OS.get_cmdline_user_args()
	capture = "--capture" in OS.get_cmdline_user_args()
	load_settings()
	setup_environment()
	sound = MidnightSound.new()
	add_child(sound)
	interface = MidnightInterface.new()
	add_child(interface)
	interface.play_requested.connect(func(daily: bool):
		var replay := daily and interface.mode == "result"
		if not replay:
			service = 0
			voyage_total = 0
		elif service > 0:
			voyage_total = maxi(0, voyage_total - run.banked)
		start_ticket(daily))
	interface.endless_requested.connect(func():
		service = 1
		voyage_total = 0
		start_ticket(false))
	interface.next_service_requested.connect(func():
		service += 1
		start_ticket(false))
	interface.resume_requested.connect(resume)
	interface.quit_requested.connect(to_title)
	interface.setting_changed.connect(change_setting)
	interface.set_meta("sensitivity", sensitivity)
	interface.set_meta("volume", volume)
	interface.set_meta("motion", motion)
	interface.show_title(best)
	build_world(90210)
	camera.rotation_degrees = Vector3(-5, -16, 0)
	if "--soak-test" in OS.get_cmdline_user_args():
		call_deferred("soak_test")
	elif smoke:
		call_deferred("smoke_test")
	elif capture:
		start_ticket(false, 90210)
		call_deferred("capture_frame")

func setup_environment() -> void:
	var world := WorldEnvironment.new()
	atmosphere = Environment.new()
	atmosphere.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_material = ShaderMaterial.new()
	sky_material.shader = preload("res://game/night_sky.gdshader")
	sky.sky_material = sky_material
	atmosphere.sky = sky
	atmosphere.background_color = Color("101c2c")
	atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.ambient_light_color = Color("9bb3c4")
	atmosphere.ambient_light_energy = 0.48
	atmosphere.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = atmosphere
	add_child(world)
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-32, -25, 0)
	moon.light_color = Color("90b8dc")
	moon.light_energy = 0.55
	add_child(moon)

func build_world(ticket: int) -> void:
	if is_instance_valid(world_root):
		remove_child(world_root)
		world_root.queue_free()
	freight.clear()
	passengers.clear()
	world_root = Node3D.new()
	add_child(world_root)
	train = MidnightTrain.new()
	world_root.add_child(train)
	train.generate(ticket)
	var rng := RandomNumberGenerator.new()
	rng.seed = ticket
	for index in range(train.spawn_points.size()):
		var cargo := MidnightFreight.new()
		var kind := rng.randi_range(0, 3)
		# Every journey has all tools available, with a doorway in the middle car.
		if index < 4:
			kind = index
		if index == 8:
			kind = 2
		cargo.configure(kind, 12 + (index / 3 + 1) * 8 + rng.randi_range(0, 8), index)
		cargo.position = train.spawn_points[index]
		world_root.add_child(cargo)
		freight.append(cargo)
	for index in range(4):
		var passenger := MidnightPassenger.new()
		passenger.identity = index
		passenger.position = Vector3(-2.5, 0, -[1, 4, 5, 6][index] * MidnightTrain.LENGTH + 7)
		world_root.add_child(passenger)
		passengers.append(passenger)
	conductor = MidnightConductor.new()
	world_root.add_child(conductor)
	build_player()

func build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 0.05, 2.5)
	player.floor_snap_length = 0.3
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.7
	collider.shape = capsule
	collider.position.y = 0.85
	player.add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.6
	camera.fov = 78
	camera.far = 400
	player.add_child(camera)
	world_root.add_child(player)

func start_ticket(daily: bool, forced_seed := 0) -> void:
	var ticket := forced_seed
	if ticket == 0:
		if daily:
			ticket = last_ticket if interface.mode == "result" else int(Time.get_date_string_from_system(true).replace("-", ""))
		else:
			ticket = int(Time.get_ticks_usec() % 999999)
	sky_material.set_shader_parameter("dawn", 0.0)
	atmosphere.ambient_light_color = Color("9bb3c4")
	atmosphere.ambient_light_energy = 0.48
	moon.light_color = Color("90b8dc")
	last_ticket = ticket
	run = MidnightRun.new()
	run.begin(ticket)
	build_world(ticket)
	run.remaining = maxf(150, MidnightRun.DURATION - maxi(0, service - 1) * 15)
	conductor.speed = 2.15 + minf(2.0, maxi(0, service - 1) * 0.3)
	visited = {0: true}
	playing = true
	paused = false
	yaw = 0
	pitch = 0
	energy = 100
	sprint_exhausted = false
	grace = 10
	threat = 0
	elapsed = 0
	interface.enter_game()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not smoke and not capture else Input.MOUSE_MODE_VISIBLE
	notify("Bank £600 before dawn. The brass counter behind you is your sanctuary.", 7)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and playing and not paused and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0022 * sensitivity
		pitch = clampf(pitch - event.relative.y * 0.0022 * sensitivity, -1.35, 1.35)
		player.rotation.y = yaw
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB and playing:
			if paused:
				resume()
			else:
				paused = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				interface.show_route(train, freight, run)
		if event.keycode == KEY_F11:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		if event.keycode == KEY_ESCAPE and playing:
			if paused:
				resume()
			else:
				pause()
		if not playing or paused:
			return
		match event.keycode:
			KEY_E: interact()
			KEY_F: fold_home()
			KEY_T: rotate_timetable()
			KEY_X: drop_selected()
			KEY_Q:
				if at_counter() and run.banked >= MidnightRun.TARGET:
					finish_run()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var index := int(event.keycode - KEY_1)
				if at_counter() and run.upgrade_tokens > 0 and index < 3:
					if run.upgrade(index):
						sound.play("bank", 1.2)
						notify(["Larger satchel: one extra slot.", "Quicker stride: walk and run 20% faster.", "Quiet lining: the conductor hears less."][index])
				elif index < run.inventory.size():
					run.selected = index

func pause() -> void:
	paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	interface.show_pause()

func resume() -> void:
	paused = false
	interface.enter_game()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func to_title() -> void:
	playing = false
	paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	interface.show_title(best)

func shutdown() -> void:
	playing = false
	if is_instance_valid(sound):
		sound.silence()
	if smoke or capture:
		OS.delay_msec(150)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(1 if test_failed else 0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		shutdown()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and playing and not paused and not smoke and not capture:
		pause()

func at_counter() -> bool:
	return player.position.distance_to(Vector3(0, 0, 4.3)) < 3.2

func nearest_freight() -> MidnightFreight:
	var nearest: MidnightFreight = null
	var distance := 2.15
	for cargo in freight:
		if cargo.taken:
			continue
		var offset := cargo.position - camera.global_position
		var candidate := offset.length()
		# A generous gaze cone avoids pixel hunting while respecting facing direction.
		if candidate < distance and -camera.global_transform.basis.z.dot(offset.normalized()) > 0.35:
			distance = candidate
			nearest = cargo
	return nearest

func nearest_passenger() -> MidnightPassenger:
	for passenger in passengers:
		var offset := passenger.position + Vector3(0, 1.4, 0) - camera.global_position
		if offset.length() < 2.4 and -camera.global_transform.basis.z.dot(offset.normalized()) > 0.4:
			return passenger
	return null

func interact() -> void:
	if at_counter():
		var earned := run.bank()
		if earned > 0:
			sound.play("bank")
			notify("£%d exchanged. %s" % [earned, "Your debt is paid! Q at the counter to leave, or keep going." if run.banked >= MidnightRun.TARGET else "Your savings are safe."], 5)
		else:
			notify("The counter banks your freight. Find relics in the carriages ahead.")
		return
	var passenger := nearest_passenger()
	if passenger != null:
		if passenger.completed:
			notify(MidnightPassenger.THANKS[passenger.identity], 6)
		elif run.trade(MidnightPassenger.NEEDS[passenger.identity], MidnightPassenger.FARES[passenger.identity], passenger.identity):
			passenger.completed = true
			sound.play("bank", 0.8)
			notify("%s  /  £%d fare sealed. Bank it at the exchange." % [MidnightPassenger.THANKS[passenger.identity], MidnightPassenger.FARES[passenger.identity]], 7)
		else:
			notify(MidnightPassenger.REQUESTS[passenger.identity], 7)
		return
	var cargo := nearest_freight()
	if cargo == null:
		return
	if run.take(cargo.kind, cargo.value, cargo.serial):
		cargo.taken = true
		cargo.hide()
		sound.play("take", 0.9 + cargo.kind * 0.1)
		notify("%s  /  %s" % [cargo.title(), cargo.effect()], 3)
	else:
		notify("Satchel full. X drops selected freight; F uses a folded doorway.")

func drop_selected() -> void:
	if run.inventory.is_empty():
		return
	var item: Dictionary = run.inventory[run.selected]
	for cargo in freight:
		if cargo.serial == item.serial:
			cargo.taken = false
			cargo.position = player.position - player.transform.basis.z * 0.8 + Vector3(0, 0.6, 0)
			cargo.position.x = clampf(cargo.position.x, -3.0, 3.0)
			cargo.position.z = clampf(cargo.position.z, -115.5, 7.5)
			cargo.show()
			break
	run.collected_ids.erase(item.serial)
	run.inventory.remove_at(run.selected)
	run.selected = mini(run.selected, maxi(0, run.inventory.size() - 1))
	sound.play("click")

func rotate_timetable() -> void:
	if not at_counter():
		notify("The timetable lever is at the exchange. Return to carriage 00.")
		return
	if run.remaining <= 15:
		notify("Too close to dawn to switch the train safely.")
		return
	var changes := train.rotate_timetable()
	for cargo in freight:
		var old_slot := clampi(roundi(-cargo.position.z / MidnightTrain.LENGTH), 0, 6)
		if changes.has(old_slot):
			cargo.position.z += float(changes[old_slot])
	run.remaining -= 10
	grace = maxf(grace, 5)
	for passenger in passengers:
		var old_slot := clampi(roundi(-passenger.position.z / MidnightTrain.LENGTH), 1, 6)
		passenger.position.z += float(changes.get(old_slot, 0))
	var conductor_slot := clampi(roundi(-conductor.position.z / MidnightTrain.LENGTH), 1, 6)
	conductor.position.z = clampf(conductor.position.z + float(changes.get(conductor_slot, 0)), -110, -13)
	sound.play("fold", 0.7)
	notify("The timetable turns. %s is now carriage 01. −10 seconds." % train.car_name(1).to_lower(), 5)

func fold_home() -> void:
	if at_counter():
		notify("You are already home. Save the doorway for the far carriages.")
		return
	if run.fold():
		player.position = Vector3(0, 0.05, 3.6)
		player.velocity = Vector3.ZERO
		grace = 8
		sound.play("fold")
		notify("Space folds like a ticket. The counter welcomes you back.")
	else:
		notify("Carry a Folded doorway to fold home with F.")

func caught() -> void:
	# Confiscated freight returns to its display; mistakes cost time, never make the goal impossible.
	for item in run.inventory:
		run.collected_ids.erase(item.serial)
		for cargo in freight:
			if cargo.serial == item.serial:
				cargo.taken = false
				cargo.show()
				break
	run.caught()
	player.position = Vector3(0, 0.05, 2.5)
	player.velocity = Vector3.ZERO
	grace = 12
	conductor.position.z = -78
	sound.play("caught")
	notify("The conductor returns your freight to its displays. −15 seconds. Savings are safe.", 6)

func finish_run() -> void:
	if not playing:
		return
	run.finish()
	playing = false
	paused = false
	best = maxi(best, run.banked)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if service > 0:
		voyage_total += run.banked
		best_voyage = maxi(best_voyage, voyage_total)
	save_settings()
	if run.won and not smoke:
		build_dawn()
	interface.show_result(run, best, service, voyage_total)
	sound.play("bank" if run.won else "caught", 0.85)

func build_dawn() -> void:
	remove_child(world_root)
	world_root.queue_free()
	var station := MidnightDawn.new()
	world_root = station
	add_child(station)
	camera = station.build(run.commissions)
	sky_material.set_shader_parameter("dawn", 1.0)
	atmosphere.ambient_light_color = Color("f4d6ad")
	atmosphere.ambient_light_energy = 0.8
	moon.light_color = Color("ffca8c")

func notify(text: String, duration := 4.0) -> void:
	interface.notice_label.text = text
	notice_time = duration

func _physics_process(delta: float) -> void:
	if not playing or paused:
		return
	elapsed += delta
	grace = maxf(0, grace - delta)
	notice_time = maxf(0, notice_time - delta)
	interface.notice_label.modulate.a = minf(1, notice_time)
	var direction := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if smoke or capture:
		direction = test_direction
	sneaking = Input.is_physical_key_pressed(KEY_CTRL)
	if energy < 2:
		sprint_exhausted = true
	elif energy > 25:
		sprint_exhausted = false
	var sprinting := Input.is_physical_key_pressed(KEY_SHIFT) and not sprint_exhausted and energy > 2 and direction.length_squared() > 0 and not sneaking
	var speed := 5.4 * run.stride
	if sprinting:
		speed *= 1.65
		energy = maxf(0, energy - delta * 23)
	else:
		energy = minf(100, energy + delta * 17)
	if sneaking:
		speed *= 0.5
	var moving := direction.length_squared() > 0
	direction = direction.normalized() if smoke else player.transform.basis * direction.normalized()
	player.velocity.x = move_toward(player.velocity.x, direction.x * speed, delta * 30)
	player.velocity.z = move_toward(player.velocity.z, direction.z * speed, delta * 30)
	player.velocity.y -= 22 * delta
	player.move_and_slide()
	if moving:
		movement_time += delta * (1.5 if sprinting else 1.0)
		step_time -= delta
		if step_time <= 0:
			sound.play("step", randf_range(0.85, 1.1), -8 if sneaking else 0)
			step_time = 0.32 if sprinting else 0.48
	var bob := sin(movement_time * 11) * 0.035 * motion if moving else 0.0
	camera.position.y = lerpf(camera.position.y, (1.35 if sneaking else 1.6) + bob, delta * 12)
	camera.rotation.z = sin(elapsed * 0.75) * 0.007 * motion
	camera.fov = lerpf(camera.fov, (78.0 + 5.0 * motion) if sprinting else 78.0, delta * 5)
	var noise := 9.0 + run.count_kind(1) * 9.0 + (7.0 if sprinting else 0.0)
	noise -= run.ward * 4 + run.count_kind(3) * 3
	if sneaking:
		noise *= 0.45
	threat = conductor.advance(delta, player.position, maxf(3, noise), grace)
	sound.threat(delta, threat)
	var distance := conductor.position.distance_to(player.position)
	if distance < 9 and player.position.z < -12 and grace <= 0:
		run.composure -= delta * (7 if conductor.alert else 3)
	else:
		run.composure = minf(100, run.composure + delta * 5)
	var catch_radius := 1.1 if sneaking else 1.65
	if grace <= 0 and (distance < catch_radius or run.composure <= 0):
		caught()
	if player.position.y < -4:
		# Defensive recovery should never be needed with the continuous floor.
		player.position = Vector3(0, 0.1, 2.5)
		player.velocity = Vector3.ZERO
	run.tick(delta)
	var car := clampi(roundi(-player.position.z / MidnightTrain.LENGTH), 0, MidnightTrain.COUNT - 1)
	var identity: int = train.car_order[car]
	if not visited.has(identity):
		visited[identity] = true
		if notice_time < 1:
			notify(["", "The stars here shine inward. Someone has wound them too tightly.", "In the winter garden, everything grows toward yesterday.", "Every place is set. None of the chairs are warm.", "The ledger has your handwriting. The dates are all tomorrow.", "The bells have no clappers. They ring when you remember them.", "The last carriage smells like the home you have not found yet."][identity], 5)
	var message := "Explore the train. The brass counter is in carriage 00."
	if at_counter():
		if run.upgrade_tokens > 0:
			message = "FREE UPGRADE  /  1 larger satchel  ·  2 quicker stride  ·  3 quiet lining     |     E bank freight"
		elif run.banked >= MidnightRun.TARGET:
			message = "YOUR DEBT IS PAID  /  Q leave the train  ·  E bank more freight  ·  T shift timetable (−10s)"
		else:
			message = "E  BANK FREIGHT  /  T shift timetable (−10s)  /  First two deliveries earn upgrades."
	else:
		var cargo := nearest_freight()
		if cargo != null:
			message = "E  %s  /  £%d  /  %s" % [cargo.title().to_upper(), cargo.value, cargo.effect()]
		elif run.inventory.size() == run.capacity:
			message = "SATCHEL FULL  /  Return to carriage 00. F folds home if you carry a doorway."
	var passenger := nearest_passenger()
	if passenger != null and not at_counter():
		message = "E  %s  /  %s for a £%d sealed fare" % [MidnightPassenger.NAMES[passenger.identity], MidnightFreight.TYPES[MidnightPassenger.NEEDS[passenger.identity]], MidnightPassenger.FARES[passenger.identity]]
		if passenger.completed:
			message = "E  %s  /  Fare sealed. Bank it at the exchange." % MidnightPassenger.NAMES[passenger.identity]
	interface.update(run, car, energy, threat, message, sneaking)
	if run.pending_fares > 0:
		interface.manifest_label.text = "MANIFEST %d/%d   /   £%d SEALED FARES TO BANK   /   %d OF 4 PASSENGERS HELPED" % [run.inventory.size(), run.capacity, run.pending_fares, run.commissions.size()]
	interface.room_label.text = "%02d / %s" % [car, train.car_name(car)]
	if service > 0:
		interface.status_label.text = "SERVICE %d  /  VOYAGE £%d  /  BEST VOYAGE £%d  /  COMPOSURE %d%%" % [service, voyage_total, best_voyage, int(run.composure)]
	if run.finished:
		finish_run()

func change_setting(key: String, value: float) -> void:
	match key:
		"sensitivity": sensitivity = value
		"motion": motion = value
		"volume": volume = value
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume)))
	save_settings()

func load_settings() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data is Dictionary:
				best = maxi(0, int(data.get("best", 0)))
				best_voyage = maxi(0, int(data.get("best_voyage", 0)))
				sensitivity = clampf(float(data.get("sensitivity", 1)), 0.3, 2)
				motion = clampf(float(data.get("motion", 0.35)), 0, 1)
				volume = clampf(float(data.get("volume", 0.65)), 0, 1)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume)))

func save_settings() -> void:
	if smoke or capture:
		return
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"version": 1, "best": best, "best_voyage": best_voyage, "sensitivity": sensitivity, "motion": motion, "volume": volume}))
		file.close()
		DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)

func capture_frame() -> void:
	if "--capture-result" in OS.get_cmdline_user_args():
		run.banked = 740
		run.commissions = {0: true, 1: true, 2: true, 3: true}
		finish_run()
	if "--capture-route" in OS.get_cmdline_user_args():
		paused = true
		interface.show_route(train, freight, run)
	if "--capture-title" in OS.get_cmdline_user_args():
		to_title()
	if "--capture-car" in OS.get_cmdline_user_args():
		player.position = Vector3(0, 0.1, -47)
	for frame in range(40):
		await get_tree().process_frame
	print("RENDER: %d draw calls / %d visible objects" % [Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
	get_viewport().get_texture().get_image().save_png("/tmp/midnight.png")
	await shutdown()

func verify(condition: bool, message: String) -> void:
	# Godot strips assert() from release exports, including argument evaluation.
	# Integration checks must execute and return a failing exit code in every build.
	if not condition:
		test_failed = true
		push_error(message)

func smoke_test() -> void:
	start_ticket(false, 90210)
	verify(freight.size() == 18, "Freight generation failed")
	var cargo := freight[0]
	player.position = cargo.position + Vector3(0, -1.3, 1.3)
	player.rotation.y = 0
	camera.rotation = Vector3.ZERO
	var value := cargo.value
	interact()
	verify(run.inventory.size() == 1 and run.held_value() == value, "Collection failed")
	player.position = Vector3(0, 0.1, 3.7)
	interact()
	verify(run.banked == value and run.inventory.is_empty(), "Banking failed")
	verify(run.upgrade(0) and run.capacity == 4, "Upgrade failed")
	var last_car_cargo_z := freight[15].position.z
	rotate_timetable()
	verify(train.car_order[1] == 6, "Timetable order failed")
	verify(is_equal_approx(freight[15].position.z, last_car_cargo_z + 90), "Timetable freight transfer failed")
	var passenger := passengers[0]
	run.take(MidnightPassenger.NEEDS[0], 30, 200)
	player.position = passenger.position + Vector3(0, 0.05, 1.5)
	interact()
	verify(passenger.completed and run.pending_fares == 75 and run.inventory.is_empty(), "Passenger trade failed")
	player.position = Vector3(0, 0.05, 2)
	# Check actual CharacterBody collision against the floor.
	for frame in range(60):
		await get_tree().physics_frame
	verify(player.is_on_floor() and player.position.y > -0.1, "Floor collision failed")
	test_direction = Vector3.RIGHT
	for frame in range(120):
		await get_tree().physics_frame
	test_direction = Vector3.ZERO
	verify(player.position.x < 3.25 and player.position.x > 2.7, "Window collision failed")
	run.take(2, 30, 100)
	run.take(1, 20, 101)
	player.position.z = -70
	fold_home()
	verify(player.position.z > 0 and run.inventory.size() == 1, "Fold failed")
	player.position = Vector3(0, 0.05, -70)
	conductor.position.z = -70
	grace = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	verify(player.position.z > 0 and run.inventory.is_empty() and run.banked == value and run.recovered == 1, "Catch recovery failed")
	verify(run.pending_fares == 75, "Sealed fare lost during recovery")
	run.remaining = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	verify(run.finished and not playing, "Run completion failed")
	verify(interface.mode == "result", "Result UI failed")
	interface.show_route(train, freight, run)
	verify(interface.mode == "route" and "relics" in interface.subtitle.text, "Route ledger failed")
	interface.show_settings()
	verify(interface.settings_box.visible, "Settings UI failed")
	print("SMOKE %s:" % ("FAIL" if test_failed else "PASS") + " generation, collection, banking, upgrades, passenger trade, floor/window physics, fold, conductor encounter, results, route/settings UI")
	await shutdown()

func walk_test_to(target: Vector3) -> bool:
	var frames := 0
	while Vector2(player.position.x - target.x, player.position.z - target.z).length() > 0.18:
		var offset := target - player.position
		offset.y = 0
		test_direction = offset.normalized()
		await get_tree().physics_frame
		frames += 1
		if frames > 2400:
			push_error("Path blocked: %s -> %s" % [player.position, target])
			test_direction = Vector3.ZERO
			return false
	test_direction = Vector3.ZERO
	for frame in range(5):
		await get_tree().physics_frame
	return true

func soak_test() -> void:
	start_ticket(false, 90210)
	grace = 99999
	# Walk every doorway in both directions using actual CharacterBody collision.
	verify(await walk_test_to(Vector3(0, 0, -114)), "Outbound aisle obstructed")
	verify(await walk_test_to(Vector3(0, 0, 3)), "Inbound aisle obstructed")
	# A strategy that reshuffles rich freight forward must be able to pay the debt.
	for trip in range(3):
		rotate_timetable()
		var candidates: Array[MidnightFreight] = []
		for cargo in freight:
			if not cargo.taken and cargo.position.z > -27 and cargo.position.z < -9:
				candidates.append(cargo)
		for cargo in candidates:
			verify(await walk_test_to(Vector3(0, 0, cargo.position.z)), "Cargo aisle unreachable")
			verify(await walk_test_to(Vector3(signf(cargo.position.x) * 0.7, 0, cargo.position.z)), "Cargo approach blocked")
			var facing := cargo.position - camera.global_position
			player.rotation.y = atan2(-facing.x, -facing.z)
			camera.rotation.x = 0
			interact()
			verify(cargo.taken, "Cargo interaction failed")
			player.rotation.y = 0
			verify(await walk_test_to(Vector3(0, 0, cargo.position.z)), "Cargo exit blocked")
		verify(await walk_test_to(Vector3(0, 0, 3)), "Exchange unreachable")
		interact()
		if run.upgrade_tokens > 0:
			run.upgrade(1)
	verify(run.banked >= MidnightRun.TARGET, "Debt cannot be paid by tested route")
	finish_run()
	verify(run.won and interface.mode == "result", "Winning route failed")
	var winning_total := run.banked
	build_dawn()
	await get_tree().process_frame
	verify(camera.is_inside_tree() and is_instance_valid(world_root), "Dawn epilogue failed")
	service = 2
	start_ticket(false, 90211)
	verify(run.banked == 0 and run.remaining == 255 and conductor.speed > 2.15, "Next service did not reset and escalate")
	for frame in range(30):
		await get_tree().physics_frame
	verify(player.is_on_floor(), "Restart after epilogue failed")
	print("SOAK %s:" % ("FAIL" if test_failed else "PASS") + " 228m aisle round trip, 9 physical pickups, 3 timetable shifts, winning extraction £%d, dawn epilogue, escalating service restart" % winning_total)
	await shutdown()
