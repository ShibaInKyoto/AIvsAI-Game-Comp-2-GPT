class_name MidnightTrain
extends Node3D
## All structural collision lives here. Decorative details share cached materials.

const LENGTH := 18.0
const COUNT := 7
const NAMES := ["THE EXCHANGE", "THE OBSERVATORY", "THE WINTER GARDEN", "THE DINING ROOM", "THE ARCHIVE", "THE CHOIR", "THE LAST CARRIAGE"]
var materials: Dictionary = {}
var forest_meshes: Array[MultiMesh] = []
var forest_positions: Array[Vector3] = []
var forest_heights: Array[float] = []
var lamps: Array[OmniLight3D] = []
var spawn_points: Array[Vector3] = []
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var cars: Array[Node3D] = []
var car_order: Array[int] = [0, 1, 2, 3, 4, 5, 6]
var current_parent: Node3D
var current_car := 0
var signage: Array[Label3D] = []
var village: Node3D

func mat(hex: String, metal := 0.0, emission := 0.0) -> StandardMaterial3D:
	var key := hex + str(metal) + str(emission)
	if materials.has(key):
		return materials[key]
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(hex)
	result.resource_name = "Palette_" + hex
	result.metallic = metal
	result.roughness = 0.6
	if hex in ["3c3337", "352c30", "30282d"]:
		result.albedo_texture = preload("res://assets/textures/wood.png")
	elif hex == "512b3c":
		result.albedo_color = Color.WHITE
		result.albedo_texture = preload("res://assets/textures/runner.png")
		result.uv1_scale = Vector3(1, 12, 1)
	elif hex == "244c50":
		result.albedo_texture = preload("res://assets/textures/wallpaper.png")
		result.uv1_scale = Vector3(6, 2, 1)
	if emission > 0:
		result.emission_enabled = true
		result.emission = Color(hex)
		result.emission_energy_multiplier = emission
	materials[key] = result
	return result

func block(pos: Vector3, size: Vector3, surface: Material, solid := false) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = surface
	item.position = pos
	(current_parent if current_parent != null else self).add_child(item)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		item.add_child(body)
	return item

func cylinder(pos: Vector3, radius: float, height: float, surface: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	item.mesh = mesh
	item.position = pos
	item.material_override = surface
	(current_parent if current_parent != null else self).add_child(item)
	return item

func sign_text(text: String, pos: Vector3, size := 36, color := Color("edcf98")) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font = preload("res://assets/fonts/display.ttf")
	label.font_size = size
	label.pixel_size = 0.005
	label.modulate = color
	label.no_depth_test = false
	label.outline_size = 0
	(current_parent if current_parent != null else self).add_child(label)
	return label

func generate(seed_value: int) -> void:
	rng.seed = seed_value
	var wood := mat("30282d")
	var dark := mat("121c2a")
	var brass := mat("ba9560", 0.7)
	var velvet := mat("59303f")
	var teal := mat("244c50")
	for car in range(COUNT):
		var group := Node3D.new()
		group.name = NAMES[car].to_pascal_case()
		group.position.z = -car * LENGTH
		add_child(group)
		cars.append(group)
		current_parent = group
		current_car = car
		var z := 0.0
		block(Vector3(0, -0.2, z), Vector3(7, 0.4, LENGTH), wood, true)
		block(Vector3(0, 3.7, z), Vector3(7, 0.2, LENGTH), dark, true)
		# Brass-banded planks and patterned runner.
		for plank in range(24):
			var tone := "3c3337" if plank % 2 == 0 else "352c30"
			block(Vector3(0, 0.006, z - 8.7 + plank * 0.75), Vector3(6.9, 0.01, 0.72), mat(tone))
		block(Vector3(0, 0.025, z), Vector3(1.8, 0.025, 17.8), mat("512b3c"))
		for side in [-1, 1]:
			block(Vector3(side * 0.84, 0.045, z), Vector3(0.025, 0.01, 17.8), brass)
			block(Vector3(side * 3.5, 0.62, z), Vector3(0.2, 1.24, LENGTH), teal, true)
			block(Vector3(side * 3.5, 3.18, z), Vector3(0.2, 1.04, LENGTH), wood, true)
			block(Vector3(side * 3.38, 1.24, z), Vector3(0.18, 0.07, LENGTH), brass)
			block(Vector3(side * 3.38, 2.68, z), Vector3(0.18, 0.07, LENGTH), brass)
			# Clear collision plane, visually open midnight windows.
			var glass := mat("253e55")
			var invisible := StandardMaterial3D.new()
			invisible.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			invisible.albedo_color = Color(0.2, 0.3, 0.5, 0.025)
			block(Vector3(side * 3.5, 1.9, z), Vector3(0.1, 1.55, LENGTH), invisible, true)
			for section in range(6):
				var sz := z - 7.5 + section * 3
				block(Vector3(side * 3.42, 1.95, sz), Vector3(0.17, 1.45, 0.12), brass)
				block(Vector3(side * 3.36, 0.62, sz), Vector3(0.05, 0.9, 2.6), wood)
				block(Vector3(side * 3.32, 0.62, sz), Vector3(0.04, 0.76, 2.4), teal)
				for pleat in range(5):
					cylinder(Vector3(side * 3.30, 2.6, sz + 1.1 + pleat * 0.075), 0.055, 1.6, velvet)
				block(Vector3(side * 3.3, 2.0, sz + 1.25), Vector3(0.32, 0.055, 0.27), brass)
			for section in range(3):
				var sz := z - 6 + section * 6
				# Ceiling ribs imply a curved carriage roof.
				var rib := block(Vector3(side * 2.8, 3.35, sz), Vector3(1.5, 0.08, 0.1), brass)
				rib.rotation.z = side * 0.4
				block(Vector3(side * 1.25, 3.55, sz), Vector3(2.0, 0.06, 0.1), brass)
		for side in [-1, 1]:
			block(Vector3(side * 2.38, 1.8, z - 9), Vector3(2.24, 3.6, 0.2), wood, true)
			block(Vector3(side * 1.27, 1.75, z - 8.85), Vector3(0.09, 3.5, 0.14), brass)
		block(Vector3(0, 3.15, z - 9), Vector3(2.5, 0.9, 0.2), wood, true)
		signage.append(sign_text("%02d  /  %s" % [car, NAMES[car]], Vector3(0, 3.17, z - 8.86), 24))
		for sz in [z - 5, z + 4]:
			cylinder(Vector3(0, 3.45, sz), 0.035, 0.4, brass)
			cylinder(Vector3(0, 3.16, sz), 0.32, 0.18, mat("ffe0a3", 0.0, 1.2))
			cylinder(Vector3(0, 3.28, sz), 0.4, 0.05, brass)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 2.7, z)
		lamp.light_color = Color("ffce91")
		lamp.light_energy = 1.3
		lamp.omni_range = 12
		group.add_child(lamp)
		lamps.append(lamp)
		if car > 0:
			var start := spawn_points.size()
			decorate_car(car, z)
			for index in range(start, spawn_points.size()):
				spawn_points[index].z += group.position.z
		else:
			decorate_exchange()
		batch_geometry(group)
	current_parent = null
	block(Vector3(0, 1.8, 9), Vector3(7, 3.6, 0.2), wood, true)
	block(Vector3(0, 1.8, -117), Vector3(7, 3.6, 0.2), wood, true)
	build_landscape()
	batch_geometry(self)
	refresh_resonance()

func decorate_exchange() -> void:
	var brass := mat("ba9560", 0.7)
	block(Vector3(0, 0.6, 5.4), Vector3(4, 1.2, 1), mat("244c50"), true)
	block(Vector3(0, 1.24, 5.4), Vector3(4.2, 0.12, 1.25), brass)
	for x in [-1.8, 1.8]:
		cylinder(Vector3(x, 2.25, 5.7), 0.04, 2, brass)
	sign_text("THE MIDNIGHT\nEXCHANGE", Vector3(0, 2.35, 5.65), 62).rotation.y = PI
	sign_text("BANK FREIGHT  /  E\nLEAVE THE TRAIN  /  Q", Vector3(0, 0.8, 4.88), 23).rotation.y = PI
	var bell := cylinder(Vector3(-1, 1.4, 5.2), 0.15, 0.2, brass)
	bell.rotation.z = 0.1
	for x in [-2.8, 2.8]:
		block(Vector3(x, 0.6, 0), Vector3(0.9, 1.2, 1.2), mat("30282d"), true)
		cylinder(Vector3(x, 1.5, 0), 0.24, 0.6, brass)
		cylinder(Vector3(x, 1.85, 0), 0.38, 0.15, mat("efbf87", 0, 0.5))

func decorate_car(car: int, z: float) -> void:
	var brass := mat("ba9560", 0.7)
	var green := mat("42706a")
	var wood := mat("30282d")
	for side in [-1, 1]:
		var x: float = side * 2.5
		for section in [-1, 1]:
			var sz: float = z + section * 4.8
			match car:
				1:
					if section == 1:
						prop("telescope", Vector3(x, 0, sz), -side * PI / 2)
					else:
						prop("settee", Vector3(x, 0, sz), -side * PI / 2)
					collision_box(Vector3(x, 0.5, sz), Vector3(1.2, 1, 2))
				6:
					prop("settee" if section < 0 else "luggage", Vector3(x, 0, sz), -side * PI / 2)
					collision_box(Vector3(x, 0.5, sz), Vector3(1.2, 1, 2))
				2:
					prop("winter_fern", Vector3(x, 0, sz))
					collision_box(Vector3(x, 0.35, sz), Vector3(1.2, 0.7, 1.6))
				3:
					prop("dining_table", Vector3(x, 0, sz))
					collision_box(Vector3(x, 0.6, sz), Vector3(1.4, 1.2, 1.7))
				4:
					prop("bookcase", Vector3(x, 0, sz), -side * PI / 2)
					collision_box(Vector3(x, 1.1, sz), Vector3(1.1, 2.2, 1.8))
				5:
					block(Vector3(x, 0.7, sz), Vector3(1.2, 1.4, 1.9), wood, true)
					for pipe in range(5):
						cylinder(Vector3(x, 1.75, sz - 0.6 + pipe * 0.3), 0.1, 1.8 + pipe * 0.2, brass)
					for key in range(12):
						block(Vector3(x - side * 0.64, 1.22, sz - 0.8 + key * 0.14), Vector3(0.25, 0.05, 0.12), mat("e5d7b5"))
						if key % 7 not in [2, 6]:
							block(Vector3(x - side * 0.60, 1.26, sz - 0.73 + key * 0.14), Vector3(0.13, 0.04, 0.06), mat("151923"))
		# Pedestals sit inside the furniture line, leaving the aisle navigable.
		var pedestal_z := z + rng.randf_range(-1.8, 1.8)
		block(Vector3(side * 2.1, 0.45, pedestal_z), Vector3(0.85, 0.9, 0.85), wood, true)
		block(Vector3(side * 2.1, 0.92, pedestal_z), Vector3(0.95, 0.06, 0.95), brass)
		spawn_points.append(Vector3(side * 2.1, 1.4, pedestal_z))
	block(Vector3(2.1, 0.45, z + 7), Vector3(0.85, 0.9, 0.85), wood, true)
	spawn_points.append(Vector3(2.1, 1.4, z + 7))

func build_landscape() -> void:
	# Moving silhouettes establish motion without moving physics or the player.
	block(Vector3(0, -5, -50), Vector3(600, 0.1, 600), mat("101b2a"))
	for index in range(100):
		var side := -1 if index % 2 == 0 else 1
		forest_positions.append(Vector3(side * rng.randf_range(16, 85), -5, rng.randf_range(-160, 50)))
		forest_heights.append(rng.randf_range(5, 24))
	# Four instanced layers render the entire moving forest in four draw calls.
	for layer in range(4):
		var mesh := CylinderMesh.new()
		mesh.top_radius = 1 if layer == 0 else 0
		mesh.bottom_radius = 1
		mesh.height = 1
		mesh.radial_segments = 7
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = mesh
		instances.instance_count = forest_positions.size()
		forest_meshes.append(instances)
		var forest := MultiMeshInstance3D.new()
		forest.multimesh = instances
		forest.material_override = mat(["111d2c", "142c35", "19373e", "20434a"][layer])
		forest.custom_aabb = AABB(Vector3(-110, -10, -180), Vector3(220, 45, 260))
		forest.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(forest)
	update_forest()
	var moon := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 6
	sphere.height = 12
	moon.mesh = sphere
	moon.position = Vector3(-90, 46, -160)
	moon.material_override = mat("dfdec6", 0, 0.6)
	add_child(moon)
	for i in range(100):
		var star := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius = 0.1 + rng.randf() * 0.12
		dot.height = dot.radius * 2
		dot.radial_segments = 4
		dot.rings = 2
		star.mesh = dot
		star.position = Vector3(rng.randf_range(-220, 220), rng.randf_range(25, 100), rng.randf_range(-220, 60))
		star.material_override = mat("b7d5dd", 0, 1.0)
		add_child(star)
	build_village()

func build_village() -> void:
	village = Node3D.new()
	village.name = "PassingVillage"
	village.position.z = -250
	add_child(village)
	current_parent = village
	var walls := mat("30424a")
	var roofs := mat("172530")
	var trim := mat("5a6260")
	var windows := mat("ffcd88", 0, 0.8)
	for house in range(10):
		var side := -1 if house % 2 == 0 else 1
		var x := side * rng.randf_range(20, 38)
		var z := -54.0 + house * 12 + rng.randf_range(-3, 3)
		var width := rng.randf_range(5, 8)
		var depth := rng.randf_range(6, 9)
		var height := rng.randf_range(7.5, 10)
		var base := -5.0
		block(Vector3(x, base + height * 0.5, z), Vector3(width, height, depth), walls)
		block(Vector3(x, base + 0.2, z), Vector3(width + 0.3, 0.4, depth + 0.3), trim)
		var roof := MeshInstance3D.new()
		var gable := PrismMesh.new()
		gable.size = Vector3(width + 0.8, 2.8, depth + 0.8)
		roof.mesh = gable
		roof.position = Vector3(x, base + height + 1.35, z)
		roof.material_override = roofs
		village.add_child(roof)
		block(Vector3(x + width * 0.25, base + height + 2.3, z - depth * 0.2), Vector3(0.7, 2.2, 0.8), trim)
		for level in [0.3, 0.73]:
			var y: float = base + height * level
			for face in [-1, 1]:
				for column in [-1, 0, 1]:
					block(Vector3(x + column * width * 0.28, y, z + face * (depth * 0.5 + 0.03)), Vector3(0.9, 1.25, 0.05), windows)
				for column in [-1, 1]:
					block(Vector3(x + face * (width * 0.5 + 0.03), y, z + column * depth * 0.26), Vector3(0.05, 1.25, 0.9), windows)
		block(Vector3(x, base + 1.2, z + depth * 0.5 + 0.07), Vector3(1.3, 2.4, 0.08), roofs)
	# One movable group, four material batches; no physics or per-window updates.
	batch_geometry(village)
	current_parent = null

func _process(delta: float) -> void:
	elapsed += delta
	if village != null:
		village.position.z += delta * 15
		if village.position.z > 340:
			village.position.z -= 900
	for index in range(forest_positions.size()):
		forest_positions[index].z += delta * 15
		if forest_positions[index].z > 60:
			forest_positions[index].z -= 230
	update_forest()

func update_forest() -> void:
	for index in range(forest_positions.size()):
		var height := forest_heights[index]
		for layer in range(4):
			var center := forest_positions[index]
			var scale: Vector3
			if layer == 0:
				scale = Vector3(0.26, height, 0.26)
				center.y += height * 0.5
			else:
				var radius: float = [0.29, 0.22, 0.14][layer - 1] * height
				scale = Vector3(radius, [0.58, 0.45, 0.32][layer - 1] * height, radius)
				center.y += [0.48, 0.68, 0.87][layer - 1] * height
			var basis := Basis(Vector3.UP, index * 2.4 + layer * 0.5).scaled(scale)
			forest_meshes[layer].set_instance_transform(index, Transform3D(basis, center))

static func seeded_order(ticket: int) -> Array[int]:
	var order: Array[int] = [0, 1, 2, 3, 4, 5, 6]
	var random := RandomNumberGenerator.new()
	random.seed = ticket ^ 0x1893
	for index in range(6, 1, -1):
		var other := random.randi_range(1, index)
		var held := order[index]
		order[index] = order[other]
		order[other] = held
	return order

func shuffle_initial(ticket: int) -> Dictionary:
	var previous := car_order.duplicate()
	car_order = seeded_order(ticket)
	return apply_order(previous)

func rotate_timetable() -> Dictionary:
	var previous := car_order.duplicate()
	var last: int = car_order.pop_back()
	car_order.insert(1, last)
	return apply_order(previous)

func swap_slots(first: int, second: int) -> Dictionary:
	if first < 1 or second < 1 or first >= COUNT or second >= COUNT or absi(first - second) != 1:
		return {}
	var previous := car_order.duplicate()
	var held := car_order[first]
	car_order[first] = car_order[second]
	car_order[second] = held
	return apply_order(previous)

func apply_order(previous: Array) -> Dictionary:
	var changes: Dictionary = {}
	for slot in range(1, COUNT):
		var identity: int = car_order[slot]
		var old_slot := previous.find(identity)
		var offset := float(old_slot - slot) * LENGTH
		cars[identity].position.z = -slot * LENGTH
		signage[identity].text = "%02d  /  %s" % [slot, NAMES[identity]]
		changes[old_slot] = offset
	refresh_resonance()
	return changes

func paired(first: int, second: int) -> bool:
	return absi(car_order.find(first) - car_order.find(second)) == 1

func refresh_resonance() -> void:
	for identity in range(lamps.size()):
		var color := Color("ffce91")
		if identity in [1, 2] and paired(1, 2):
			color = Color("a8dfcf")
		elif identity in [4, 5] and paired(4, 5):
			color = Color("b9b4eb")
		elif identity in [3, 6] and paired(3, 6):
			color = Color("f2b1a7")
		lamps[identity].light_color = color

func car_name(slot: int) -> String:
	return NAMES[car_order[slot]]

func batch_geometry(parent: Node3D) -> void:
	if "--unbatched" in OS.get_cmdline_user_args():
		return
	# Merge immutable architecture and original prop surfaces by material. Keep the
	# carriage roots movable and collision transforms exact; glass sorts separately.
	var batches: Dictionary = {}
	for child in parent.get_children():
		if not child is MeshInstance3D:
			continue
		var eligible := true
		for index in range(child.mesh.get_surface_count()):
			var surface := child.material_override as StandardMaterial3D
			if surface == null:
				surface = child.mesh.surface_get_material(index) as StandardMaterial3D
			if surface == null or surface.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				eligible = false
		if not eligible:
			continue
		for index in range(child.mesh.get_surface_count()):
			var surface := child.material_override as StandardMaterial3D
			if surface == null:
				surface = child.mesh.surface_get_material(index) as StandardMaterial3D
			if not batches.has(surface):
				var tool := SurfaceTool.new()
				tool.set_material(surface)
				batches[surface] = tool
			var tool: SurfaceTool = batches[surface]
			var indices: Variant = child.mesh.surface_get_arrays(index)[Mesh.ARRAY_INDEX]
			if indices == null or indices.is_empty():
				# append_from cannot safely mix indexed and non-indexed surfaces.
				# Normalize custom geometry so later primitives cannot hide its faces.
				var indexed := SurfaceTool.new()
				indexed.create_from(child.mesh, index)
				indexed.index()
				tool.append_from(indexed.commit(), 0, child.transform)
			else:
				tool.append_from(child.mesh, index, child.transform)
		for body in child.get_children():
			if body is StaticBody3D:
				var pose: Transform3D = child.transform * body.transform
				child.remove_child(body)
				parent.add_child(body)
				body.transform = pose
		parent.remove_child(child)
		child.queue_free()
	for surface in batches:
		var item := MeshInstance3D.new()
		var tool: SurfaceTool = batches[surface]
		item.mesh = tool.commit()
		item.material_override = surface
		parent.add_child(item)

func collision_box(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.position = pos
	body.add_child(collision)
	(current_parent if current_parent != null else self).add_child(body)

func prop(name: String, pos: Vector3, rotation_y := 0.0) -> void:
	var packed := load("res://assets/models/%s.glb" % name) as PackedScene
	var source := packed.instantiate()
	var pose := Transform3D(Basis(Vector3.UP, rotation_y), pos)
	flatten_prop(source, pose)
	source.free()

func flatten_prop(source: Node, parent_pose: Transform3D) -> void:
	var pose := parent_pose
	if source is Node3D:
		pose *= source.transform
	if source is MeshInstance3D:
		var instance := MeshInstance3D.new()
		instance.mesh = source.mesh
		instance.material_override = source.material_override
		instance.transform = pose
		(current_parent if current_parent != null else self).add_child(instance)
	for child in source.get_children():
		flatten_prop(child, pose)
