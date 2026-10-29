extends "res://scripts/assess_live.gd"
## Optional map-aware route through all four requests, including recovery after
## capture, followed by earning the remaining fare and leaving through Q.
## Uses ordinary rules; a heuristic failure does not prove an impossible ticket.

func speak(identity: int) -> bool:
	var passenger: MidnightPassenger = game.passengers[identity]
	if not await walk(Vector3(0, 0, passenger.position.z)) or not await walk(Vector3(-0.7, 0, passenger.position.z)):
		return false
	var facing: Vector3 = passenger.position + Vector3(0, 1.4, 0) - game.camera.global_position
	game.player.rotation.y = atan2(-facing.x, -facing.z)
	game.camera.rotation.x = 0
	game.interact()
	game.player.rotation.y = 0
	print("COMMISSION ", identity, " helped=", passenger.completed, " time=", game.run.remaining)
	return passenger.completed and await walk(Vector3(0, 0, passenger.position.z))

func evaluate() -> void:
	await board()
	var quest_ok := true
	for index in [0, 1, 2]:
		if not await collect(game.freight[index]):
			quest_ok = false
			break
	for identity in [3, 1]:
		if quest_ok and not await speak(identity):
			quest_ok = false
	if quest_ok:
		quest_ok = await collect(game.freight[3])
	for identity in [2, 0]:
		if quest_ok and not await speak(identity):
			quest_ok = false
	# Recover an interrupted request through normal banking, upgrades and shunts.
	for retry in range(3):
		if quest_ok or not game.playing:
			break
		if game.at_counter() and game.run.pending_fares > 0 and game.run.inventory.is_empty():
			game.player.rotation.y = 0
			game.interact()
			game.test_key(KEY_2, true)
			game.test_key(KEY_2, false)
		quest_ok = true
		for passenger in game.passengers:
			if passenger.completed:
				continue
			var needed: int = MidnightPassenger.NEEDS[passenger.identity]
			var chosen: MidnightFreight = null
			var distance := INF
			for cargo in game.freight:
				var candidate: float = absf(cargo.position.z - game.player.position.z)
				if not cargo.taken and cargo.kind == needed and candidate < distance:
					chosen = cargo
					distance = candidate
			if chosen == null:
				quest_ok = false
				break
			if game.at_counter():
				var slot := slot_for(chosen.position.z)
				if slot == 6 and game.run.pressure >= 2:
					game.rotate_timetable()
				elif game.run.pressure >= slot - 1:
					while slot > 1:
						game.shunt_carriages(slot, slot - 1)
						slot -= 1
				game.interface.enter_game()
			quest_ok = await collect(chosen)
			if quest_ok:
				quest_ok = await speak(passenger.identity)
			if not quest_ok:
				break
	if quest_ok:
		quest_ok = await walk(Vector3(0, 0, 3))
	if quest_ok:
		game.interact()
		game.test_key(KEY_2, true)
		game.test_key(KEY_2, false)
		print("FOUR COMMISSIONS BANKED ", game.run.banked, " time=", game.run.remaining)
	else:
		print("QUEST POLICY FAILED time=", game.run.remaining, " bank=", game.run.banked, " helped=", game.run.commissions.size(), " catches=", game.run.recovered)
		await finish_assessment(false, "FOUR-TRAVELER JOURNEY", true)
		return
	await finish_assessment(await pay_debt(), "FOUR-TRAVELER JOURNEY", true)
