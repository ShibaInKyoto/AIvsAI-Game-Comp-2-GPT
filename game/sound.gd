class_name MidnightSound
extends Node

var effects: Dictionary = {}
var music: AudioStreamPlayer
var rails: AudioStreamPlayer
var chime_timer := 0.0

func _ready() -> void:
	for name in ["take", "bank", "fold", "caught", "chime", "step", "click"]:
		effects[name] = load("res://assets/audio/%s.wav" % name)
	music = loop_player("night", -3)
	rails = loop_player("train", -5)

func loop_player(name: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream := load("res://assets/audio/%s.wav" % name) as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = stream.data.size() / 2
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	player.play()
	return player

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
