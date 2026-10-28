extends SceneTree

var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error(message)
		quit(1)
		assert(false, message)

func _initialize() -> void:
	var run := MidnightRun.new()
	run.begin(123)
	check(run.take(0, 20, 1), "First pickup")
	check(not run.take(0, 20, 1), "Duplicate pickup rejected")
	check(run.take(1, 40, 2), "Bell pickup")
	check(run.take(2, 60, 3), "Door pickup")
	check(not run.take(3, 99, 4), "Capacity enforced")
	check(run.held_value() == 150, "Bell multiplier applies to entire delivery")
	run.remaining = 100
	check(run.bank() == 150, "Correct deposit")
	check(run.remaining == 118 and run.banked == 150, "Clock grants time")
	check(run.upgrade(0) and run.capacity == 4, "Capacity upgrade")
	check(not run.upgrade(1), "No free repeated upgrade")
	check(not run.upgrade(-1), "Invalid upgrade rejected")
	check(run.take(2, 50, 5) and run.take(3, 70, 6), "Second inventory")
	check(run.fold() and run.inventory.size() == 1 and run.folds == 1, "Door consumption")
	check(not run.fold(), "Door cannot be reused")
	run.caught()
	check(run.banked == 150 and run.inventory.is_empty(), "Catch preserves bank")
	run.take(1, 400, 7)
	run.bank()
	run.tick(1000)
	check(run.finished and run.won and run.banked == 650, "Winning terminal state")
	check(not run.take(0, 10, 8), "No pickup after ending")
	var total := run.banked
	check(run.bank() == 0 and run.banked == total, "No banking after ending")
	check(not run.fold() and not run.upgrade(0), "No actions after ending")
	# Random action sequences check conservation, capacity and valid selection.
	for seed_value in range(100):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var state := MidnightRun.new()
		var serial := 0
		var previous_bank := 0
		for step in range(250):
			match rng.randi_range(0, 5):
				0, 1:
					state.take(rng.randi_range(0, 3), rng.randi_range(10, 60), serial)
					serial += 1
				2: state.bank()
				3: state.fold()
				4: state.caught()
				5: state.upgrade(rng.randi_range(0, 2))
			check(state.inventory.size() <= state.capacity, "Capacity invariant")
			check(state.banked >= previous_bank, "Bank never decreases")
			check(state.remaining >= 0 and state.remaining <= MidnightRun.DURATION + 60, "Time bounded")
			check(state.selected >= 0 and state.selected < maxi(1, state.inventory.size()), "Selection in bounds")
			previous_bank = state.banked
	print("STATE PASS: %d checks, 100 randomized runs / 25,000 actions" % checks)
	quit()
