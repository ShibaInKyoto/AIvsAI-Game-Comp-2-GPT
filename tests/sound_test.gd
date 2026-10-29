extends SceneTree

var failed := false
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error(message)

func check_loop(player: AudioStreamPlayer, seconds: int) -> void:
	var stream := player.stream as AudioStreamWAV
	check(stream != null and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Loop resource missing")
	check(stream.loop_end == seconds * stream.mix_rate, "Compressed audio must loop at its decoded frame count")

func _initialize() -> void:
	call_deferred("evaluate")

func evaluate() -> void:
	var sound := MidnightSound.new()
	root.add_child(sound)
	# Advance transition time explicitly, independent of the test machine's audio
	# clock. The actual imported compressed resources are still loaded and played.
	sound.set_process(false)
	check_loop(sound.music, 48)
	check_loop(sound.rails, 8)
	check_loop(sound.morning, 24)
	check(sound.morning.stream_paused, "Morning must start silent")
	for player in sound.room_players:
		check_loop(player, 12)
		check(player.stream_paused, "Unvisited room loops must start paused")
	sound.enter_room(1)
	sound._process(0.9)
	check(not sound.room_players[1].stream_paused and sound.room_players[2].stream_paused, "Only the entered carriage should sound")
	sound.enter_room(2)
	sound._process(0.45)
	check(not sound.room_players[1].stream_paused and not sound.room_players[2].stream_paused, "Neighboring room ambience should crossfade")
	sound._process(0.45)
	check(sound.room_players[1].stream_paused and not sound.room_players[2].stream_paused, "Departed carriage must pause after fading")
	sound.enter_room(-1)
	sound.set_dawn(true)
	sound._process(1.5)
	check(sound.music.stream_paused and sound.rails.stream_paused and not sound.morning.stream_paused, "Dawn must resolve the music and stop the wheels")
	for player in sound.room_players:
		check(player.stream_paused, "Carriage ambience must leave the station ending")
	sound.set_dawn(false)
	sound._process(1.5)
	check(not sound.music.stream_paused and not sound.rails.stream_paused and sound.morning.stream_paused, "A new night must restore train audio")
	sound.silence()
	for child in sound.get_children():
		check(child.stream == null and not child.playing, "Shutdown must release every audio stream")
	sound.queue_free()
	await process_frame
	# Let the audio mix thread release stopped compressed-stream playbacks.
	await create_timer(0.3).timeout
	print("SOUND %s: %d checks, compressed loop lengths, carriage crossfades, dawn/restart and shutdown" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)
