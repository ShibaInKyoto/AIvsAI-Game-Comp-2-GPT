extends Node
## Opt-in telemetry for native OS-input checks. Never supplies gameplay input,
## changes run rules, or writes the profile. Normal play never instantiates it.

var game
var elapsed := 0.0
var previous := ""
var sequence := 0
var output := ""

func _ready() -> void:
	output = OS.get_environment("MIDNIGHT_INPUT_CAPTURE_DIR")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
	call_deferred("sample")

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 0.1:
		elapsed = 0
		sample()

func sample() -> void:
	if game.smoke or game.capture:
		push_error("Native input observation requires ordinary gameplay input")
		set_process(false)
		return
	var state: Dictionary = {"playing": game.playing, "paused": game.paused,
		"mode": game.interface.mode, "ledger": game.interface.route_commissions,
		"mouse": Input.mouse_mode, "sensitivity": game.sensitivity,
		"window": DisplayServer.window_get_mode()}
	if game.run != null:
		state.merge({"bank": game.run.banked, "inventory": game.run.inventory.size(),
			"capacity": game.run.capacity, "pressure": game.run.pressure,
			"remaining": game.run.remaining, "catches": game.run.recovered})
	if game.playing:
		state.merge({"x": game.player.position.x, "z": game.player.position.z,
			"yaw": game.yaw, "pitch": game.pitch, "seed": game.run.seed_value,
			"counter": game.at_counter(), "elapsed": game.elapsed})
	var signature := JSON.stringify([state.playing, state.paused, state.mode, state.ledger,
		state.window, state.get("bank", 0), state.get("inventory", 0), state.get("capacity", 0), state.get("pressure", 0)])
	var changed := signature != previous
	if changed:
		previous = signature
		# The native input runner can disable continuous rendering to keep the
		# software test display from delaying input. These checkpoints still draw.
		RenderingServer.force_draw()
		sequence += 1
		if not output.is_empty():
			var path := output.path_join("input_%03d.png" % sequence)
			if get_viewport().get_texture().get_image().save_png(path) != OK:
				push_error("Native input checkpoint could not be saved")
	state.frame = sequence
	if not output.is_empty():
		# Release builds can buffer stdout. Keep a complete, replace-on-success
		# snapshot for an external input driver without changing global logging.
		var path := output.path_join("state.json")
		var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(state))
			file.close()
			DirAccess.rename_absolute(path + ".tmp", path)
	if changed:
		print("INPUT_QA " + JSON.stringify(state))
