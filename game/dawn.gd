class_name MidnightDawn
extends Node3D
## A real-time epilogue: the people you helped wait on the first morning's platform.

func build(helped: Dictionary) -> Camera3D:
	var art := MidnightTrain.new()
	add_child(art)
	var stone := art.mat("777e7a")
	var brass := art.mat("ba9560", 0.65)
	var dark := art.mat("19292d")
	var green := art.mat("274a48")
	var glow := art.mat("ffdfa2", 0, 0.7)
	art.block(Vector3(0, -0.4, -15), Vector3(14, 0.8, 85), stone)
	art.block(Vector3(0, -1, -40), Vector3(800, 0.2, 800), art.mat("3d5a55"))
	for edge in [-1, 1]:
		art.block(Vector3(edge * 6.5, 0.015, -15), Vector3(0.3, 0.03, 85), brass)
	for index in range(28):
		art.block(Vector3(0, 0.01, 25 - index * 3), Vector3(13, 0.02, 0.04), art.mat("505e5b"))
	for z in [12, -3, -18, -33]:
		art.cylinder(Vector3(4.8, 2.0, z), 0.07, 4, dark)
		art.cylinder(Vector3(4.8, 4.0, z), 0.32, 0.3, glow)
		art.cylinder(Vector3(4.8, 4.2, z), 0.4, 0.06, brass)
	for z in [3, -9, -21, -33]:
		art.prop("station_bench", Vector3(4.6, 0, z), -PI / 2)
	for z in [8, -4, -16, -28]:
		art.prop("winter_fern", Vector3(4.8, 0, z))
	# Rails and the now ordinary-looking train.
	for x in [-9.0, -12.0]:
		art.block(Vector3(x, -0.65, -17), Vector3(0.16, 0.2, 100), brass)
	for z in range(-65, 30, 2):
		art.block(Vector3(-10.5, -0.8, z), Vector3(4.7, 0.2, 0.3), dark)
	for z in [-3, -23]:
		art.block(Vector3(-10.5, 1.5, z), Vector3(4.2, 3.2, 18), green)
		art.block(Vector3(-10.5, 3.3, z), Vector3(4.6, 0.3, 18.4), dark)
		art.block(Vector3(-8.35, 0.6, z), Vector3(0.05, 0.12, 17.7), brass)
		for window in range(6):
			var wz: float = z - 7.5 + window * 3
			art.block(Vector3(-8.35, 2.0, wz), Vector3(0.04, 1.2, 2.3), glow)
			art.block(Vector3(-8.30, 2.0, wz), Vector3(0.06, 1.24, 0.08), brass)
		for axle in [-5.5, 5.5]:
			for side in [-1, 1]:
				var wheel := art.cylinder(Vector3(-10.5 + side * 2, -0.2, z + axle), 0.65, 0.2, dark)
				wheel.rotation.z = PI / 2
	# Open cast-iron spandrels and a pitched roof shelter the dawn platform.
	for z in [-3, -13, -23, -33]:
		art.prop("station_frame", Vector3(0, 0, z))
	for side in [-1, 1]:
		var roof := art.block(Vector3(side * 2.825, 4.975, -18.5), Vector3(5.73, 0.12, 35), green)
		roof.rotation.z = -side * atan(0.95 / 5.65)
		art.block(Vector3(side * 5.63, 4.50, -18.5), Vector3(0.10, 0.16, 35.4), brass)
	art.block(Vector3(0, 5.46, -18.5), Vector3(0.13, 0.13, 35.4), brass)
	art.prop("station_clock", Vector3(2.8, 0, -8))
	art.block(Vector3(0, 4.25, -23), Vector3(6.6, 1.1, 0.2), dark)
	art.sign_text("THE FIRST MORNING", Vector3(0, 4.25, -22.87), 55)
	art.sign_text("YOU MAY KEEP YOUR NAME", Vector3(0, 3.55, -22.85), 22)
	for identity in helped:
		var passenger := MidnightPassenger.new()
		passenger.identity = int(identity)
		passenger.position = Vector3(-2.5 + int(identity) * 1.6, 0, -14)
		passenger.completed = true
		add_child(passenger)
		passenger.caption.hide()
	# Far hills silhouette against the peach-colored sky.
	for index in range(20):
		var hill := art.cylinder(Vector3(-140 + index * 16, 0, -135), 17, 18 + sin(index) * 10, art.mat("596b67"))
		hill.rotation.z = 0.3
	art.batch_geometry(art)
	var camera := Camera3D.new()
	camera.position = Vector3(4, 2.3, 13)
	camera.fov = 68
	camera.far = 450
	add_child(camera)
	camera.look_at(Vector3(-2, 2.3, -25))
	return camera
