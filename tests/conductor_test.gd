extends SceneTree

var failed := false
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error(message)

func _initialize() -> void:
	call_deferred("evaluate")

func evaluate() -> void:
	var carriage := Node3D.new()
	carriage.position.z = -45
	root.add_child(carriage)
	var organ := MidnightOrgan.new()
	organ.position = Vector3(1.7, 1.26, 4.8)
	carriage.add_child(organ)
	check(organ.activate() and not organ.activate(), "The choir must have only one call")
	var conductor := MidnightConductor.new()
	root.add_child(conductor)
	conductor.position.z = -80
	conductor.answer_choir(organ)
	var home := Vector3(0, 0, 3)
	conductor.advance(1, home, 9, 0)
	check(conductor.following_music and not conductor.alert and conductor.position.z > -80, "The conductor must approach a sounding organ")
	# A parent transform changes when the real carriage is shunted.
	carriage.position.z = -110
	var previous := conductor.position.z
	conductor.advance(1, home, 9, 0)
	check(conductor.position.z < previous, "Music must follow the moving carriage, not a captured coordinate")
	carriage.position.z = -30
	conductor.position.z = -80
	conductor.advance(0.1, Vector3(0, 0, -84), 9, 0)
	check(conductor.alert and not conductor.following_music and conductor.position.z < -80, "Nearby noise must override the diversion")
	conductor.advance(0.1, home, 9, 0)
	check(conductor.following_music and not conductor.alert, "The call should resume after nearby noise stops")
	carriage.position.z = -64.8
	conductor.position.z = -60
	conductor.answer_choir(organ)
	conductor.advance(0.5, home, 9, 0)
	check(is_equal_approx(conductor.position.z, -60), "An answered call must hold him at the organ")
	conductor.advance(MidnightConductor.CALL_DURATION + 1, home, 9, 0)
	check(not conductor.following_music and conductor.call_remaining == 0 and conductor.music_source == null, "The call must expire")
	previous = conductor.position.z
	conductor.advance(0.1, home, 9, 0)
	check(not is_equal_approx(conductor.position.z, previous), "Normal patrol must resume")
	carriage.position.z = -18
	conductor.position.z = -18
	conductor.answer_choir(organ)
	conductor.advance(10, home, 9, 0)
	check(is_equal_approx(conductor.position.z, -17), "The call must respect the exchange sanctuary boundary")
	conductor.answer_choir(organ)
	carriage.free()
	conductor.advance(0.1, home, 9, 0)
	check(not conductor.following_music and conductor.music_source == null, "A removed source must cancel its call safely")
	conductor.queue_free()
	await process_frame
	print("CONDUCTOR %s: %d checks, single-use organ, moving source, noise priority, arrival, expiry and cleanup" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)
