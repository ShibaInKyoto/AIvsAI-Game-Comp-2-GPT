extends SceneTree
## Optional balance diagnostic, separate from the deterministic navigation test.
## This porter knows the freight layout. It uses normal movement, economics and
## conductor rules, so success demonstrates a possible route, not novice difficulty.

const BELL := 1
const DOORWAY := 2
var game
var evasions := 0
var abandoned_bells := 0

func _initialize() -> void:
	call_deferred("evaluate")

func slot_for(z: float) -> int:
	return roundi(-z / MidnightTrain.LENGTH)

func walk(target: Vector3, avoid := true) -> bool:
	var frames := 0
	var catches: int = game.run.recovered
	while Vector2(game.player.position.x - target.x, game.player.position.z - target.z).length() > 0.18:
		if not game.playing or game.run.recovered != catches:
			return false
		var offset: Vector3 = target - game.player.position
		offset.y = 0
		var enemy: Vector3 = game.conductor.position - game.player.position
		var ahead: bool = enemy.z * offset.z > 0
		var travel: float = signf(offset.z)
		if avoid:
			game.test_key(KEY_CTRL, ahead and enemy.length() < game.hearing_radius(false, false) + 2)
		var following: bool = not game.conductor.alert and game.conductor.patrol_direction == travel and enemy.length() > game.hearing_radius(false, true) + 0.8
		if avoid and game.player.position.z < -12 and enemy.length() < 12 and ahead and not following:
			if not await shelter(travel):
				return false
			if not await walk(Vector3(0, 0, game.player.position.z), false):
				return false
			offset = target - game.player.position
			offset.y = 0
		# Follow a receding patrol quietly instead of repeatedly retreating to
		# the same refuge. Brake before reaching a waypoint, allowing inertia.
		var toward: float = game.player.velocity.dot(offset.normalized())
		var pacing: bool = avoid and ahead and following and enemy.length() < maxf(8, game.hearing_radius(false, true) + 2)
		var braking := toward > 0.25 and offset.length() < toward * toward / 60.0 + 0.06
		game.test_direction = Vector3.ZERO if pacing or braking else offset.normalized()
		await physics_frame
		frames += 1
		if frames > 3600:
			print("WALK STALLED ", game.player.position, " target=", target)
			return false
	game.test_direction = Vector3.ZERO
	for frame in range(5):
		await physics_frame
	return true

func shelter(travel: float) -> bool:
	evasions += 1
	var position: Vector3 = game.player.position
	var enemy_direction: float = signf(game.conductor.position.z - position.z)
	var refuge := Vector3(0, 0, 3)
	var cost := INF
	for slot in range(1, MidnightTrain.COUNT):
		for local_z in [-2.8, 2.8]:
			var z: float = -slot * MidnightTrain.LENGTH + local_z
			var distance: float = absf(z - position.z)
			if enemy_direction * (z - position.z) <= 3.0 and distance < cost:
				cost = distance
				refuge = Vector3(2.5, 0, z)
	if position.z > -25:
		refuge = Vector3(0, 0, 3)
	game.test_key(KEY_CTRL, false)
	print("SHELTER ", position, " enemy=", game.conductor.position, " refuge=", refuge, " travel=", travel)
	if not await walk(Vector3(0, 0, refuge.z), false) or not await walk(refuge, false):
		return false
	game.test_key(KEY_CTRL, true)
	var center: float = -slot_for(refuge.z) * MidnightTrain.LENGTH
	game.player.rotation.y = PI if refuge.z > center else 0
	var dropped := 0
	for index in range(game.run.inventory.size() - 1, -1, -1):
		if game.run.inventory[index].kind == BELL:
			game.run.selected = index
			game.drop_selected()
			dropped += 1
	var frames := 0
	var safe_distance: float = maxf(6.0, 1.5 + dropped * 3.5 - game.run.ward - game.run.count_kind(3) + 2.0)
	while game.playing:
		var separation: float = game.conductor.position.z - refuge.z
		if refuge.z > 0:
			if game.conductor.position.z < -28:
				break
		elif travel * separation < -safe_distance or (travel * separation > safe_distance and game.conductor.patrol_direction == travel):
			break
		await physics_frame
		frames += 1
		if frames > 1200:
			# At a patrol boundary, leave bells behind instead of waiting for
			# a separation the conductor cannot physically reach.
			if travel * separation < -3.5:
				abandoned_bells += dropped
				dropped = 0
				break
			if frames > 2400:
				print("SHELTER TIMEOUT ", game.player.position, " enemy=", game.conductor.position)
				return false
	for index in range(dropped):
		game.interact()
	game.player.rotation.y = 0
	# Remain crouched while leaving cover; standing immediately beside the
	# conductor would restart pursuit after an otherwise successful pass.
	if not await walk(Vector3(0, 0, refuge.z), false):
		return false
	print("EVADE ", evasions, " time=", snappedf(game.run.remaining, 0.1), " bank=", game.run.banked, " catches=", game.run.recovered)
	return game.playing

func collect(cargo: MidnightFreight) -> bool:
	if not await walk(Vector3(0, 0, cargo.position.z)) or not await walk(Vector3(signf(cargo.position.x) * 0.7, 0, cargo.position.z)):
		return false
	var facing: Vector3 = cargo.position - game.camera.global_position
	game.player.rotation.y = atan2(-facing.x, -facing.z)
	game.camera.rotation.x = 0
	game.interact()
	game.player.rotation.y = 0
	return cargo.taken and await walk(Vector3(0, 0, cargo.position.z))

func board() -> void:
	game = load("res://game/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	# This flag supplies input overrides and suppresses profile writes. It does
	# not change the clock, initial grace, pressure, freight or conductor rules.
	game.smoke = true
	game.start_ticket(false, game.qa_seed)

func pay_debt() -> bool:
	var okay := true
	for trip in range(8):
		if game.run.banked >= MidnightRun.TARGET or not game.playing:
			break
		var trip_catches: int = game.run.recovered
		var richest := 1
		var best := -1
		for slot in range(1, MidnightTrain.COUNT):
			var value := 0
			for cargo in game.freight:
				if not cargo.taken and slot_for(cargo.position.z) == slot:
					value += cargo.value
			if value > best:
				best = value
				richest = slot
		var identity: int = game.train.car_order[richest]
		if richest == 6 and game.run.pressure >= 2:
			game.rotate_timetable()
		elif game.run.pressure >= richest - 1:
			while richest > 1:
				game.shunt_carriages(richest, richest - 1)
				richest -= 1
		game.interface.enter_game()
		var candidates: Array = []
		for cargo in game.freight:
			if not cargo.taken and slot_for(cargo.position.z) == game.train.car_order.find(identity):
				candidates.append(cargo)
		for cargo in candidates:
			if not await collect(cargo):
				okay = false
				break
		if not okay:
			if game.playing and game.run.recovered > trip_catches:
				okay = true
				print("RECOVER / retained bank=", game.run.banked, " time=", game.run.remaining)
				continue
			break
		if game.run.count_kind(DOORWAY) > 0 and game.player.position.z < -35:
			game.fold_home()
		elif not await walk(Vector3(0, 0, 3)):
			okay = false
			break
		game.interact()
		if game.run.upgrade_tokens > 0:
			game.run.upgrade(1)
		print("TRIP ", trip, " bank=", game.run.banked, " time=", snappedf(game.run.remaining, 0.1))
	okay = okay and game.run.banked >= MidnightRun.TARGET
	return okay

func finish_assessment(okay: bool, label: String, all_travelers := false) -> void:
	if okay:
		game.test_key(KEY_Q, true)
		game.test_key(KEY_Q, false)
		okay = game.run.finished and game.run.won and not game.playing and game.interface.mode == "result"
		if all_travelers:
			okay = okay and game.run.commissions.size() == 4 and game.rescued_mask == 15
	print(label, " ", "PASS" if okay else "FAIL", " ticket=", game.run.seed_value, " bank=", game.run.banked, " remaining=", game.run.remaining, " catches=", game.run.recovered, " evasions=", evasions, " abandoned_bells=", abandoned_bells)
	game.test_failed = not okay
	await game.shutdown()

func evaluate() -> void:
	await board()
	await finish_assessment(await pay_debt(), "LIVE JOURNEY")
