class_name MidnightSound
extends Node

var effects: Dictionary = {}
var music: AudioStreamPlayer
var rails: AudioStreamPlayer
var morning: AudioStreamPlayer
const ROOMS := ["exchange", "observatory", "garden", "dining", "archive", "choir", "last"]
const ROOM_LEVELS := [-3.0, -3.0, -6.0, -3.0, -6.0, -9.0, -3.0]
var room_players: Array[AudioStreamPlayer] = []
var room_gains: Array[float] = []
var current_room := -1
var dawn_target := 0.0
var dawn_mix := 0.0
var chime_timer := 0.0

func _ready() -> void:
	for name in ["take", "bank", "fold", "caught", "chime", "step", "click"]:
		effects[name] = load("res://assets/audio/%s.wav" % name)
	music = loop_player("night", -3)
	rails = loop_player("train", -5)
	morning = loop_player("morning", -80)
	apply_gain(morning, 0, -3)
	for name in ROOMS:
		var player := loop_player("room_" + name, -80)
		apply_gain(player, 0, 0)
		room_players.append(player)
		room_gains.append(0.0)

func loop_player(name: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream := load("res://assets/audio/%s.wav" % name) as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	# Imported WAVs can use QOA compression; bytes are not decoded sample frames.
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	player.play()
	return player

func enter_room(identity: int) -> void:
	current_room = clampi(identity, -1, ROOMS.size() - 1)

func set_dawn(arrived: bool) -> void:
	if arrived and dawn_target == 0:
		morning.play(0)
	dawn_target = 1.0 if arrived else 0.0

func apply_gain(player: AudioStreamPlayer, gain: float, base_db: float) -> void:
	# Silent loops pause playback and resume at their saved phase.
	player.stream_paused = gain <= 0.0001
	player.volume_db = base_db + linear_to_db(maxf(0.0001, gain))

func _process(delta: float) -> void:
	var next_mix := move_toward(dawn_mix, dawn_target, delta / 1.5)
	if next_mix != dawn_mix:
		dawn_mix = next_mix
		apply_gain(music, 1.0 - dawn_mix, -3)
		apply_gain(rails, 1.0 - dawn_mix, -5)
		apply_gain(morning, dawn_mix, -3)
	for index in range(room_players.size()):
		var target := 1.0 if index == current_room else 0.0
		var gain := move_toward(room_gains[index], target, delta / 0.9)
		if gain != room_gains[index]:
			room_gains[index] = gain
			apply_gain(room_players[index], gain, ROOM_LEVELS[index])

func play(name: String, pitch := 1.0, volume := 0.0) -> void:
	if not effects.has(name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = effects[name]
	player.pitch_scale = pitch
	player.volume_db = volume
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func threat(delta: float, level: float, source: Vector3) -> void:
	chime_timer -= delta
	if level > 0.3 and chime_timer <= 0:
		# A real world-space cue lets headphones reveal which way he is approaching.
		var player := AudioStreamPlayer3D.new()
		player.stream = effects.chime
		player.position = source
		player.pitch_scale = 0.85 + level * 0.15
		player.unit_size = 7
		player.max_distance = 35
		player.volume_db = -2
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
		chime_timer = lerpf(5, 1.8, level)

func silence() -> void:
	set_process(false)
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
		elif child is AudioStreamPlayer3D:
			child.stop()
			child.stream = null
	effects.clear()

func _exit_tree() -> void:
	silence()
