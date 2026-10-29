class_name MidnightTitle
extends Node3D
## A miniature night service above the valley. Static scenery is merged by
## material; one instanced steam mesh and a gentle camera drift animate the view.

var camera: Camera3D
var steam: MultiMesh
var clock := 0.0
var camera_motion := 1.0
var camera_origin := Vector3(36, 17, 32)
var camera_target := Vector3(-23, 2, -7)

func build() -> Camera3D:
	var art := MidnightTrain.new()
	art.name = "ViaductMiniature"
	add_child(art)
	var stone := art.mat("263b48")
	stone.cull_mode = BaseMaterial3D.CULL_DISABLED
	var edge := art.mat("425864")
	var iron := art.mat("111f2c", 0.4)
	var brass := art.mat("bb9961", 0.6)
	var enamel := art.mat("17565c", 0.35)
	var windows := art.mat("ffca76", 0.0, 1.15)
	var roof := art.mat("152a37", 0.35)
	# Tall masonry arches make the train feel suspended above the mountains.
	for span in range(9):
		var z := -125.0 + span * 21.0
		arch(art, z, stone, edge)
		art.block(Vector3(0, -14.5, z - 10.5), Vector3(6.6, 11, 5.8), stone)
		art.block(Vector3(0, -8.9, z - 10.5), Vector3(6.9, 0.45, 5.9), edge)
		for side in [-1, 1]:
			art.block(Vector3(side * 3.15, -0.05, z), Vector3(0.35, 0.75, 21), edge)
	art.block(Vector3(0, -0.7, -41), Vector3(6.6, 0.35, 189), edge)
	for z in range(-135, 54, 2):
		art.block(Vector3(0, -0.42, z), Vector3(3.5, 0.16, 0.22), iron)
	for x in [-1.2, 1.2]:
		art.block(Vector3(x, -0.25, -41), Vector3(0.10, 0.20, 189), brass)
	var engine := preload("res://assets/models/locomotive.glb").instantiate()
	engine.position.y = -0.15
	add_child(engine)
	for index in range(4):
		carriage(art, -16.0 - index * 14.7, enamel, roof, brass, windows, iron)
	# Layered angular silhouettes catch the cool light without expensive terrain.
	var random := RandomNumberGenerator.new()
	random.seed = 1893
	for layer in range(3):
		var mountain_color := art.mat(["162a3b", "1c3445", "243e4c"][layer])
		for index in range(11):
			var peak := Vector3(-190 + index * 35, -34, -190 - layer * 45)
			mountain(art, peak, random.randf_range(23, 48), random.randf_range(25, 64), mountain_color, random)
	# A moon above the distant carriages.
	var moon_pos := Vector3(-77, 30, -150)
	var moon := SphereMesh.new()
	moon.radius = 8.2
	moon.height = 16.4
	moon.radial_segments = 32
	moon.rings = 16
	var disc := MeshInstance3D.new()
	disc.mesh = moon
	disc.position = moon_pos
	disc.material_override = art.mat("c7ddd8", 0.0, 0.7)
	art.add_child(disc)
	# Sparse near-bank firs frame the lower edge, leaving the menu side quiet.
	for index in range(24):
		var z := random.randf_range(-115, 50)
		var x := random.randf_range(23, 55)
		var height := random.randf_range(8, 18)
		for layer in range(3):
			var fir := art.cylinder(Vector3(x, -21 + height * (0.35 + layer * 0.2), z), height * (0.22 - layer * 0.045), height * 0.55, art.mat("102731"))
			(fir.mesh as CylinderMesh).top_radius = 0
	art.batch_geometry(art)
	build_mist()
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-37, -28, 0)
	fill.light_color = Color("91bbc9")
	fill.light_energy = 0.7
	add_child(fill)
	var headlight := SpotLight3D.new()
	headlight.position = Vector3(0, 2.35, 4.95)
	headlight.rotation.y = PI
	headlight.light_color = Color("ffce86")
	headlight.light_energy = 3
	headlight.spot_range = 23
	headlight.spot_angle = 24
	add_child(headlight)
	build_steam()
	camera = Camera3D.new()
	camera.position = camera_origin
	camera.fov = 48
	camera.far = 650
	add_child(camera)
	camera.look_at(camera_target)
	return camera

func carriage(art: MidnightTrain, z: float, enamel: Material, roof: Material, brass: Material, windows: Material, iron: Material) -> void:
	art.block(Vector3(0, 1.72, z), Vector3(3, 2.85, 13.2), enamel)
	art.block(Vector3(0, 0.38, z), Vector3(3.1, 0.3, 13.3), iron)
	var curved := art.cylinder(Vector3(0, 3.2, z), 1, 13.55, roof)
	curved.rotation.x = PI / 2
	curved.scale = Vector3(1.65, 1, 0.48)
	for side in [-1, 1]:
		for height in [0.85, 1.02, 2.97]:
			art.block(Vector3(side * 1.515, height, z), Vector3(0.04, 0.055, 13), brass)
		for window in range(7):
			var wz := z - 5.4 + window * 1.8
			art.block(Vector3(side * 1.52, 2.17, wz), Vector3(0.04, 1.12, 1.16), brass)
			art.block(Vector3(side * 1.55, 2.17, wz), Vector3(0.035, 1.0, 1.04), windows)
			art.block(Vector3(side * 1.58, 2.17, wz), Vector3(0.04, 1.04, 0.045), brass)
		for axle in [-4.4, -3.25, 3.25, 4.4]:
			var wheel := art.cylinder(Vector3(side * 1.22, 0.35, z + axle), 0.52, 0.23, iron)
			wheel.rotation.z = PI / 2
	art.block(Vector3(0, 1.6, z + 6.9), Vector3(1.8, 2.2, 0.65), iron)

func arch(art: MidnightTrain, z: float, stone: Material, edge: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 18
	for index in range(segments):
		var a := PI * index / segments
		var b := PI * (index + 1) / segments
		var za := z + cos(a) * 7.6
		var zb := z + cos(b) * 7.6
		var ya := -10 + sin(a) * 7.6
		var yb := -10 + sin(b) * 7.6
		for side in [-1, 1]:
			quad(tool, Vector3(side * 3.15, ya, za), Vector3(side * 3.15, yb, zb), Vector3(side * 3.15, -0.9, zb), Vector3(side * 3.15, -0.9, za), side < 0)
		quad(tool, Vector3(-3.15, ya, za), Vector3(3.15, ya, za), Vector3(3.15, yb, zb), Vector3(-3.15, yb, zb), false)
	tool.generate_normals()
	# The shared batcher also receives indexed BoxMeshes. Index this surface
	# before combining them, otherwise appended box indices omit the arch faces.
	tool.index()
	var body := MeshInstance3D.new()
	body.mesh = tool.commit()
	body.material_override = stone
	art.add_child(body)
	# Individual voussoirs outline the arch and read as masonry from a distance.
	for index in range(17):
		var angle := PI * (index + 0.5) / 17
		for side in [-1, 1]:
			var brick := art.block(Vector3(side * 3.2, -10 + sin(angle) * 7.85, z + cos(angle) * 7.85), Vector3(0.15, 0.44, 1.37), edge)
			brick.rotation.x = angle - PI / 2

func quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, reverse: bool) -> void:
	for vertex in ([a, c, b, a, d, c] if reverse else [a, b, c, a, c, d]):
		tool.add_vertex(vertex)

func mountain(art: MidnightTrain, base: Vector3, radius: float, height: float, surface: Material, random: RandomNumberGenerator) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var apex := base + Vector3(random.randf_range(-radius * 0.3, radius * 0.3), height, 0)
	for facet in range(7):
		var first := TAU * facet / 7
		var second := TAU * (facet + 1) / 7
		tool.add_vertex(base + Vector3(cos(first) * radius, 0, sin(first) * radius))
		tool.add_vertex(apex)
		tool.add_vertex(base + Vector3(cos(second) * radius, 0, sin(second) * radius))
	tool.generate_normals()
	var peak := MeshInstance3D.new()
	peak.mesh = tool.commit()
	peak.material_override = surface
	art.add_child(peak)

func build_mist() -> void:
	# Soft, slowly shifting layers separate the bridge from the distant valley.
	# Compatibility-friendly alpha quads avoid a volumetric-fog dependency.
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float ribbon = exp(-pow((p.y + sin(p.x * 7.0 + TIME * 0.025) * 0.10) * 2.4, 2.0));
	float ends = 1.0 - smoothstep(0.65, 1.0, abs(p.x));
	ALBEDO = vec3(0.12, 0.22, 0.28);
	ALPHA = ribbon * ends * 0.26;
}"""
	var surface := ShaderMaterial.new()
	surface.shader = shader
	for index in range(3):
		var mesh := QuadMesh.new()
		mesh.size = Vector2(350, 25)
		var veil := MeshInstance3D.new()
		veil.mesh = mesh
		veil.material_override = surface
		veil.position = Vector3(-50, -13 - index * 4, -30 - index * 45)
		veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(veil)

func build_steam() -> void:
	var puff := SphereMesh.new()
	puff.radius = 1
	puff.height = 2
	puff.radial_segments = 10
	puff.rings = 5
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;
void fragment() {
	float facing = max(dot(normalize(NORMAL), normalize(VIEW)), 0.0);
	ALBEDO = vec3(0.54, 0.67, 0.71);
	ALPHA = COLOR.a * facing * facing;
}"""
	var surface := ShaderMaterial.new()
	surface.shader = shader
	steam = MultiMesh.new()
	steam.transform_format = MultiMesh.TRANSFORM_3D
	steam.use_colors = true
	steam.mesh = puff
	steam.instance_count = 28
	var cloud := MultiMeshInstance3D.new()
	cloud.multimesh = steam
	cloud.material_override = surface
	cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cloud.custom_aabb = AABB(Vector3(-6, 3, -27), Vector3(12, 17, 34))
	add_child(cloud)
	update_steam()

func update_steam() -> void:
	for index in range(steam.instance_count):
		var age := fmod(clock * 0.16 + float(index) / steam.instance_count, 1.0)
		var center := Vector3(sin(index * 2.7 + age * 4) * age * 1.3, 3.85 + age * 8, 2.75 - age * 25)
		var size := 0.25 + age * 2.9
		steam.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3(size, size * 0.75, size * 1.3)), center))
		steam.set_instance_color(index, Color(1, 1, 1, sin(age * PI) * 0.12))

func _process(delta: float) -> void:
	clock += delta
	if camera != null:
		camera.position = camera_origin + Vector3(sin(clock * 0.07) * 1.2, sin(clock * 0.05) * 0.35, cos(clock * 0.07) * 0.7) * camera_motion
		camera.look_at(camera_target)
	if steam != null:
		update_steam()
