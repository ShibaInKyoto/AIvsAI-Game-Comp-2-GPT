extends Node3D
## Composition root: input, physics and presentation coordinate the isolated run simulation.

const SAVE_PATH := "user://porter.json"
var run: MidnightRun
var train: MidnightTrain
var conductor: MidnightConductor
var player: CharacterBody3D
var camera: Camera3D
var lantern: SpotLight3D
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
var qa_seed := 90210
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
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-seed="):
			qa_seed = maxi(1, argument.get_slice("=", 1).to_int())
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
	interface.shunt_requested.connect(shunt_carriages)
	interface.resume_requested.connect(resume)
	interface.quit_requested.connect(to_title)
	interface.exit_requested.connect(shutdown)
	interface.setting_changed.connect(change_setting)
	interface.set_meta("sensitivity", sensitivity)
	interface.set_meta("volume", volume)
	interface.set_meta("motion", motion)
	interface.show_title(best, best_voyage)
	build_title_world()
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
	world_root.name = "NightService"
	add_child(world_root)
	train = MidnightTrain.new()
	train.name = "TimetableTrain"
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
		cargo.name = "Freight_%02d" % index
		cargo.configure(kind, 12 + (index / 3 + 1) * 8 + rng.randi_range(0, 8), index)
		cargo.position = train.spawn_points[index]
		cargo.display_position = cargo.position
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
	move_carriage_contents(train.shuffle_initial(ticket))
	for cargo in freight:
		var starting_slot := clampi(roundi(-cargo.position.z / MidnightTrain.LENGTH), 1, 6)
		cargo.value = 12 + starting_slot * 8 + rng.randi_range(0, 8)
	build_player()

func build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Porter"
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
	lantern = SpotLight3D.new()
	lantern.position = Vector3(0.18, -0.15, 0.1)
	lantern.light_color = Color("ffdb9e")
	lantern.light_energy = 0.25
	lantern.spot_range = 11
	lantern.spot_angle = 44
	lantern.spot_attenuation = 1.1
	lantern.shadow_enabled = true
	lantern.shadow_bias = 0.04
	camera.add_child(lantern)
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

func _input(event: InputEvent) -> void:
	# Menu shortcuts must run before focused buttons consume Tab for navigation.
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_TAB and playing and (not paused or interface.mode == "route"):
		if paused:
			resume()
		else:
			paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			interface.show_route(train, freight, run, at_counter())
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and playing:
		if paused:
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and playing and not paused and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0022 * sensitivity
		pitch = clampf(pitch - event.relative.y * 0.0022 * sensitivity, -1.35, 1.35)
		player.rotation.y = yaw
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and not event.echo:
		if not playing or paused:
			return
		match event.keycode:
			KEY_E: interact()
			KEY_F: fold_home()
			KEY_L: lantern.visible = not lantern.visible
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
	build_title_world()
	interface.show_title(best, best_voyage)

func build_title_world() -> void:
	if is_instance_valid(world_root):
		remove_child(world_root)
		world_root.queue_free()
	freight.clear()
	passengers.clear()
	var platform := MidnightTitle.new()
	platform.camera_motion = motion
	world_root = platform
	add_child(platform)
	camera = platform.build()
	camera.make_current()
	sky_material.set_shader_parameter("dawn", 0.0)
	atmosphere.ambient_light_color = Color("9bb3c4")
	atmosphere.ambient_light_energy = 0.48
	moon.light_color = Color("90b8dc")

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

func passenger_fare(identity: int) -> int:
	return roundi(MidnightPassenger.FARES[identity] * (1.25 if train.paired(3, 6) else 1.0))

func nearest_passenger() -> MidnightPassenger:
	for passenger in passengers:
		var offset := passenger.position + Vector3(0, 1.4, 0) - camera.global_position
		if offset.length() < 2.4 and -camera.global_transform.basis.z.dot(offset.normalized()) > 0.4:
			return passenger
	return null

func interact() -> void:
	var cargo := nearest_freight()
	if at_counter() and cargo == null:
		var aurora_time := run.count_kind(3) * 12 if train.paired(1, 2) else 0
		var earned := run.bank()
		if earned > 0:
			run.remaining = minf(MidnightRun.DURATION + 60, run.remaining + aurora_time)
			sound.play("bank")
			notify("£%d exchanged. %s" % [earned, "Your debt is paid! Q at the counter to leave, or keep going." if run.banked >= MidnightRun.TARGET else "Your savings are safe."], 5)
		else:
			notify("The counter banks your freight. Find relics in the carriages ahead.")
		return
	var passenger := nearest_passenger()
	if passenger != null:
		if passenger.completed:
			notify(MidnightPassenger.THANKS[passenger.identity], 6)
		elif run.trade(MidnightPassenger.NEEDS[passenger.identity], passenger_fare(passenger.identity), passenger.identity):
			passenger.completed = true
			sound.play("bank", 0.8)
			notify("%s  /  £%d fare sealed. Bank it at the exchange." % [MidnightPassenger.THANKS[passenger.identity], passenger_fare(passenger.identity)], 7)
		else:
			notify(MidnightPassenger.REQUESTS[passenger.identity], 7)
		return
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
	if not run.charge_switch(2, 10):
		notify("Rotation needs 2 pressure and 15 seconds. Each £150 banked earns 1 pressure.")
		return
	var changes := train.rotate_timetable()
	move_carriage_contents(changes)
	grace = maxf(grace, 5)
	sound.play("fold", 0.7)
	notify("The timetable turns. %s is now carriage 01. −10 seconds." % train.car_name(1).to_lower(), 5)

func move_carriage_contents(changes: Dictionary) -> void:
	for cargo in freight:
		var display_slot := clampi(roundi(-cargo.display_position.z / MidnightTrain.LENGTH), 1, 6)
		cargo.display_position.z += float(changes.get(display_slot, 0))
		var old_slot := clampi(roundi(-cargo.position.z / MidnightTrain.LENGTH), 0, 6)
		if changes.has(old_slot):
			cargo.position.z += float(changes[old_slot])
	for passenger in passengers:
		var old_slot := clampi(roundi(-passenger.position.z / MidnightTrain.LENGTH), 1, 6)
		passenger.position.z += float(changes.get(old_slot, 0))
	var conductor_slot := clampi(roundi(-conductor.position.z / MidnightTrain.LENGTH), 1, 6)
	conductor.position.z = clampf(conductor.position.z + float(changes.get(conductor_slot, 0)), -110, -13)

func shunt_carriages(first: int, second: int) -> void:
	if not playing or not at_counter() or first < 1 or second < 1 or first > 6 or second > 6 or absi(first - second) != 1:
		return
	if not run.charge_switch(1, 6):
		return
	var changes := train.swap_slots(first, second)
	if changes.is_empty():
		return
	move_carriage_contents(changes)
	grace = maxf(grace, 3)
	sound.play("fold", 0.9)
	interface.show_route(train, freight, run, true)

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
				cargo.position = cargo.display_position
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
	interface.show_result(run, best, service, voyage_total, best_voyage)
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
	var noise := hearing_radius(sprinting, sneaking)
	threat = conductor.advance(delta, player.position, noise, grace)
	sound.threat(delta, threat, conductor.global_position + Vector3(0, 1.6, 0))
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
			message = "YOUR DEBT IS PAID  /  Q leave the train  ·  E bank more freight  ·  T rotate (2 pressure / 10s)"
		else:
			message = "E  BANK FREIGHT  /  T rotate (2 pressure / 10s)  /  First two deliveries earn upgrades."
	else:
		var cargo := nearest_freight()
		if cargo != null:
			message = "E  %s  /  £%d  /  %s" % [cargo.title().to_upper(), cargo.value, cargo.effect()]
		elif run.inventory.size() == run.capacity:
			message = "SATCHEL FULL  /  Return to carriage 00. F folds home if you carry a doorway."
	var counter_cargo := nearest_freight() if at_counter() else null
	if counter_cargo != null:
		message = "E  %s  /  £%d  /  %s" % [counter_cargo.title().to_upper(), counter_cargo.value, counter_cargo.effect()]
	var passenger := nearest_passenger()
	if passenger != null and not at_counter():
		message = "E  %s  /  %s for a £%d sealed fare" % [MidnightPassenger.NAMES[passenger.identity], MidnightFreight.TYPES[MidnightPassenger.NEEDS[passenger.identity]], passenger_fare(passenger.identity)]
		if passenger.completed:
			message = "E  %s  /  A traveler you helped. Speak to them again." % MidnightPassenger.NAMES[passenger.identity]
	interface.update(run, car, energy, threat, message, sneaking)
	if threat > 0.35:
		if conductor.alert:
			interface.threat_label.text = "HE HEARS YOU  /  Bells carry far. Run, fold home, or drop them and sneak aside."
		elif sneaking and absf(player.position.x) > noise:
			interface.threat_label.text = "KEEP QUIET  /  Let the red lantern pass."
	if run.pending_fares > 0:
		interface.manifest_label.text = "MANIFEST %d/%d   /   £%d SEALED FARES TO BANK   /   %d OF 4 PASSENGERS HELPED" % [run.inventory.size(), run.capacity, run.pending_fares, run.commissions.size()]
	interface.room_label.text = "%02d / %s" % [car, train.car_name(car)]
	interface.status_label.text += "   /   BOILER %d/6" % run.pressure
	if service > 0:
		interface.status_label.text = "SERVICE %d / VOYAGE £%d / BOILER %d/6 / CALM %d%%" % [service, voyage_total, run.pressure, int(run.composure)]
	if run.finished:
		finish_run()

func hearing_radius(sprinting: bool, is_sneaking: bool) -> float:
	var current_identity: int = train.car_order[clampi(roundi(-player.position.z / MidnightTrain.LENGTH), 0, 6)]
	var muffled: bool = current_identity in [4, 5] and train.paired(4, 5)
	var bells := 0 if muffled else run.count_kind(1)
	# Quiet crouching fits inside the side passages. Bells still betray a hiding porter.
	if is_sneaking:
		return maxf(1.1, 1.5 + bells * 3.5 - run.ward - run.count_kind(3))
	return maxf(3, 9.0 + bells * 9.0 + (7.0 if sprinting else 0.0) - run.ward * 4 - run.count_kind(3) * 3)

func change_setting(key: String, value: float) -> void:
	match key:
		"sensitivity": sensitivity = value
		"motion": motion = value
		"volume": volume = value
	if world_root is MidnightTitle:
		world_root.camera_motion = motion
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume)))
	save_settings()

func load_settings() -> void:
	var data := MidnightProfile.read_file(SAVE_PATH)
	best = data.best
	best_voyage = data.best_voyage
	sensitivity = data.sensitivity
	motion = data.motion
	volume = data.volume
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume)))

func save_settings() -> void:
	if smoke or capture:
		return
	if not MidnightProfile.write_file(SAVE_PATH, {"best": best, "best_voyage": best_voyage, "sensitivity": sensitivity, "motion": motion, "volume": volume}):
		push_warning("The local profile could not be saved. This journey can continue.")

func capture_frame() -> void:
	notice_time = 0
	interface.notice_label.text = ""
	if "--capture-result" in OS.get_cmdline_user_args():
		run.banked = 740
		run.commissions = {0: true, 1: true, 2: true, 3: true}
		finish_run()
	if "--capture-route" in OS.get_cmdline_user_args():
		paused = true
		interface.show_route(train, freight, run, at_counter())
	if "--capture-title" in OS.get_cmdline_user_args():
		to_title()
	if "--capture-car" in OS.get_cmdline_user_args():
		player.position = Vector3(0, 0.1, -47)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-car="):
			var identity := clampi(argument.get_slice("=", 1).to_int(), 1, 6)
			player.position = Vector3(0, 0.05, -train.car_order.find(identity) * MidnightTrain.LENGTH + 7)
		elif argument.begins_with("--capture-relic="):
			var cargo := freight[clampi(argument.get_slice("=", 1).to_int(), 0, 3)]
			player.position = cargo.position + Vector3(0, -1.35, 1.4)
			camera.rotation.x = -0.15
			grace = 999
	if "--capture-portrait" in OS.get_cmdline_user_args():
		player.position = passengers[0].position + Vector3(1.8, 0.05, 0.8)
		player.look_at(passengers[0].position + Vector3(0, 0.05, 0))
	if "--capture-inventory" in OS.get_cmdline_user_args():
		run.capacity = 4
		for kind in range(4):
			run.take(kind, 20 + kind * 10, 700 + kind)
	for frame in range(40):
		await get_tree().process_frame
	print("RENDER: %d draw calls / %d visible objects" % [Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
	var capture_path := OS.get_environment("MIDNIGHT_CAPTURE_PATH")
	if capture_path.is_empty():
		capture_path = "/tmp/midnight.png"
	verify(get_viewport().get_texture().get_image().save_png(capture_path) == OK, "Screenshot could not be saved")
	await shutdown()

func verify(condition: bool, message: String) -> void:
	# Godot strips assert() from release exports, including argument evaluation.
	# Integration checks must execute and return a failing exit code in every build.
	if not condition:
		test_failed = true
		push_error(message)

func smoke_test() -> void:
	verify(world_root is MidnightTitle and camera.is_inside_tree(), "Title scene did not build")
	var qa_profile := "user://qa_scene_%d.json" % OS.get_process_id()
	verify(MidnightProfile.write_file(qa_profile, {"best": 600}), "Initial profile write failed")
	verify(MidnightProfile.write_file(qa_profile, {"best": 800}) and MidnightProfile.read_file(qa_profile).best == 800, "Profile replacement failed")
	DirAccess.remove_absolute(qa_profile)
	start_ticket(false, qa_seed)
	verify(freight.size() == 18, "Freight generation failed")
	var cargo := freight[0]
	player.position = cargo.position + Vector3(0, -1.3, 1.3)
	player.rotation.y = 0
	camera.rotation = Vector3.ZERO
	var value := cargo.value
	interact()
	verify(run.inventory.size() == 1 and run.held_value() == value, "Collection failed")
	drop_selected()
	verify(run.inventory.is_empty() and not cargo.taken, "Dropping freight failed")
	interact()
	verify(run.inventory.size() == 1 and cargo.taken, "Dropped freight cannot be recovered")
	player.position = Vector3(0, 0.1, 3.7)
	interact()
	verify(run.banked == value and run.inventory.is_empty(), "Banking failed")
	verify(run.upgrade(0) and run.capacity == 4, "Upgrade failed")
	var last_identity := train.car_order[6]
	var last_cargo := freight[(last_identity - 1) * 3]
	var last_car_cargo_z := last_cargo.position.z
	rotate_timetable()
	verify(train.car_order[1] == last_identity, "Timetable order failed")
	verify(is_equal_approx(last_cargo.position.z, last_car_cargo_z + 90), "Timetable freight transfer failed")
	var time_before_shunt := run.remaining
	paused = true
	interface.show_route(train, freight, run, true)
	(interface.route_buttons.get_child(0) as Button).grab_focus()
	test_key(KEY_TAB, true)
	verify(not paused and not interface.menu.visible, "Tab must close the route with a focused button")
	test_key(KEY_TAB, false)
	test_key(KEY_TAB, true)
	verify(paused and interface.mode == "route", "Tab must reopen the route")
	test_key(KEY_TAB, false)
	(interface.route_buttons.get_child(0) as Button).pressed.emit()
	verify(is_equal_approx(run.remaining, time_before_shunt - 6), "Shunt time cost failed")
	verify(run.pressure == 0, "Switchboard pressure cost failed")
	# Isolate geometry/resonance stress from normal resource scarcity.
	run.pressure = 30
	var desired := [0, 1, 2, 6, 3, 4, 5]
	for target_slot in range(1, 7):
		var current_slot := train.car_order.find(desired[target_slot])
		while current_slot > target_slot:
			shunt_carriages(current_slot, current_slot - 1)
			current_slot -= 1
	verify(train.paired(1, 2) and train.paired(4, 5) and train.paired(3, 6), "Resonance couplings failed")
	verify(is_equal_approx(last_cargo.position.z, last_car_cargo_z + (6 - train.car_order.find(last_identity)) * MidnightTrain.LENGTH), "Shunt freight transfer failed")
	verify(train.swap_slots(0, 1).is_empty(), "Exchange must never move")
	verify(passenger_fare(3) == 138, "Resonant commission bonus failed")
	run.take(1, 20, 202)
	player.position.z = -train.car_order.find(4) * MidnightTrain.LENGTH
	var quiet_radius := hearing_radius(false, false)
	player.position.z = 3.7
	verify(hearing_radius(false, false) > quiet_radius, "Archive/choir bell muffling failed")
	run.inventory.clear()
	var first_fare := passenger_fare(0)
	var passenger := passengers[0]
	run.take(MidnightPassenger.NEEDS[0], 30, 200)
	player.position = passenger.position + Vector3(0, 0.05, 1.5)
	interact()
	verify(passenger.completed and run.pending_fares == first_fare and run.inventory.is_empty(), "Passenger trade failed")
	resume()
	await test_quiet_encounter()
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
	# A relic dropped at home still belongs to its original moving display on capture.
	var returned_cargo := freight[1]
	var original_display := returned_cargo.display_position
	player.position = Vector3(0, 0.05, 3.7)
	run.take(returned_cargo.kind, returned_cargo.value, returned_cargo.serial)
	returned_cargo.taken = true
	returned_cargo.hide()
	drop_selected()
	interact()
	verify(returned_cargo.taken and run.inventory.size() == 1, "Dropped cargo could not be collected at home")
	shunt_carriages(1, 2)
	verify(is_equal_approx(returned_cargo.display_position.z, original_display.z - MidnightTrain.LENGTH) and returned_cargo.position.z > 0, "Display and dropped cargo must travel independently")
	shunt_carriages(1, 2)
	interface.enter_game()
	run.take(2, 30, 100)
	player.position.z = -70
	fold_home()
	verify(player.position.z > 0 and run.inventory.size() == 1, "Fold failed")
	player.position = Vector3(0, 0.05, -70)
	conductor.position.z = -70
	grace = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	verify(player.position.z > 0 and run.inventory.is_empty() and run.banked == value and run.recovered == 1, "Catch recovery failed")
	verify(run.pending_fares == first_fare, "Sealed fare lost during recovery")
	verify(not returned_cargo.taken and returned_cargo.position.is_equal_approx(original_display) and not run.collected_ids.has(returned_cargo.serial), "Captured dropped cargo must return to its display")
	player.position = Vector3(0, 0.05, 3.7)
	run.remaining = 100
	run.take(3, 10, 203)
	interact()
	verify(is_equal_approx(run.remaining, 112), "Observatory/garden time resonance failed")
	verify(run.banked == value + first_fare + 10, "Fare and relic combined banking failed")
	run.remaining = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	verify(run.finished and not playing, "Run completion failed")
	verify(interface.mode == "result", "Result UI failed")
	verify(interface.guide_panel.visible and not interface.title_shade.visible, "Result epilogue must replace title presentation")
	interface.show_route(train, freight, run, at_counter())
	verify(interface.mode == "route" and "relics" in interface.subtitle.text, "Route ledger failed")
	interface.show_settings()
	verify(interface.settings_box.visible, "Settings UI failed")
	print("SMOKE %s:" % ("FAIL" if test_failed else "PASS") + " generation, collection, banking, upgrades, shunting/resonances, passenger trade, floor/window physics, quiet evasion, fold, conductor capture, results, focused route/settings UI")
	await shutdown()

func test_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func test_quiet_encounter() -> void:
	# Test the advertised escape using actual movement, input and live patrol logic.
	player.position = Vector3(0, 0.05, -51.2)
	player.velocity = Vector3.ZERO
	grace = 10
	verify(await walk_test_to(Vector3(2.5, 0, -51.2)), "Side refuge is obstructed")
	conductor.position.z = -57.2
	conductor.patrol_direction = 1
	grace = 0
	for frame in range(2):
		await get_tree().physics_frame
	verify(conductor.alert, "Normal footsteps must attract the approaching conductor")
	test_key(KEY_CTRL, true)
	for frame in range(480):
		await get_tree().physics_frame
	verify(sneaking and not conductor.alert, "Quiet side refuge must break pursuit")
	verify(conductor.position.z > player.position.z + 8, "Conductor must pass a quiet porter")
	verify(run.recovered == 0 and run.composure > 50, "Hiding should not force a capture")
	run.take(1, 20, 999)
	conductor.position.z = player.position.z - 3
	for frame in range(2):
		await get_tree().physics_frame
	verify(conductor.alert, "A carried bell must betray an otherwise quiet porter")
	run.inventory.clear()
	test_key(KEY_CTRL, false)
	grace = 10
	conductor.position.z = -78

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
	start_ticket(false, qa_seed)
	grace = 99999
	# Walk every doorway in both directions using actual CharacterBody collision.
	verify(await walk_test_to(Vector3(0, 0, -114)), "Outbound aisle obstructed")
	verify(await walk_test_to(Vector3(0, 0, 3)), "Inbound aisle obstructed")
	# Navigation stress is independent of the extraction deadline. Start a fresh timed route here.
	run.remaining = MidnightRun.DURATION
	run.pressure = 3
	var pickups := 0
	var turns := 0
	for trip in range(6):
		if run.banked >= MidnightRun.TARGET:
			break
		# Bring the richest remaining carriage forward through the public controls.
		var richest_slot := 1
		var richest_value := -1
		for slot in range(1, 7):
			var value := 0
			for cargo in freight:
				if not cargo.taken and roundi(-cargo.position.z / MidnightTrain.LENGTH) == slot:
					value += cargo.value
			if value > richest_value:
				richest_value = value
				richest_slot = slot
		var target_identity: int = train.car_order[richest_slot]
		if richest_slot == 6 and run.pressure >= 2:
			rotate_timetable()
			turns += 1
		elif run.pressure >= richest_slot - 1:
			while richest_slot > 1:
				shunt_carriages(richest_slot, richest_slot - 1)
				richest_slot -= 1
		interface.enter_game()
		var target_slot := train.car_order.find(target_identity)
		var candidates: Array[MidnightFreight] = []
		for cargo in freight:
			if not cargo.taken and roundi(-cargo.position.z / MidnightTrain.LENGTH) == target_slot:
				candidates.append(cargo)
		for cargo in candidates:
			verify(await walk_test_to(Vector3(0, 0, cargo.position.z)), "Cargo aisle unreachable")
			verify(await walk_test_to(Vector3(signf(cargo.position.x) * 0.7, 0, cargo.position.z)), "Cargo approach blocked")
			var facing := cargo.position - camera.global_position
			player.rotation.y = atan2(-facing.x, -facing.z)
			camera.rotation.x = 0
			interact()
			verify(cargo.taken, "Cargo interaction failed")
			pickups += 1
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
	print("SOAK %s:" % ("FAIL" if test_failed else "PASS") + " 228m navigation stress, %d physical pickups, %d rotations, timed extraction £%d, dawn epilogue, escalating service restart" % [pickups, turns, winning_total])
	await shutdown()
