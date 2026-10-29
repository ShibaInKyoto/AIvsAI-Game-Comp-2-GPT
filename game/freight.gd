class_name MidnightFreight
extends Node3D
## Freights have a persistent identity; visual animation never changes interaction position.

const TYPES := ["Stolen hour", "Choir bell", "Folded doorway", "Bottled aurora"]
const COLORS := [Color("84d4d0"), Color("edb568"), Color("c4a3ed"), Color("a3d7a0")]
const MODELS := [preload("res://assets/models/relic_hour.glb"), preload("res://assets/models/relic_bell.glb"), preload("res://assets/models/relic_door.glb"), preload("res://assets/models/relic_aurora.glb")]
static var light_materials: Dictionary = {}
var kind := 0
var value := 0
var serial := 0
var visual: Node3D
var phase := 0.0
var taken := false
var display_position := Vector3.ZERO
var focus_marker: Node3D
var focus_caption: Label3D

func configure(type: int, price: int, identity: int) -> void:
	kind = type
	value = price
	serial = identity
	phase = float(identity) * 1.73

func _ready() -> void:
	visual = MODELS[kind].instantiate()
	add_child(visual)
	apply_materials(visual, kind)
	focus_marker = Node3D.new()
	add_child(focus_marker)
	var ring := MeshInstance3D.new()
	var shape := TorusMesh.new()
	shape.inner_radius = 0.38
	shape.outer_radius = 0.40
	shape.rings = 24
	shape.ring_segments = 8
	ring.mesh = shape
	ring.position.y = -0.39
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("d8b77e")
	gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = gold
	focus_marker.add_child(ring)
	focus_caption = Label3D.new()
	focus_caption.position.y = 0.65
	focus_caption.font = preload("res://assets/fonts/body.ttf")
	focus_caption.font_size = 24
	focus_caption.pixel_size = 0.003
	focus_caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	focus_caption.modulate = Color("efe4cf")
	focus_caption.outline_size = 3
	focus_marker.add_child(focus_caption)
	focus_marker.hide()

func set_focused(focused: bool, can_collect := true) -> void:
	focus_marker.visible = focused
	if focused:
		focus_caption.text = "%s  /  £%d\n%s" % [title(), value, "[E] COLLECT" if can_collect else "SATCHEL FULL"]

static func apply_materials(node: Node, relic_kind: int) -> void:
	if node is MeshInstance3D:
		for index in range(node.mesh.get_surface_count()):
			var surface := node.mesh.surface_get_material(index) as StandardMaterial3D
			if surface == null or not surface.emission_enabled:
				continue
			if not light_materials.has(relic_kind):
				var light := ShaderMaterial.new()
				light.shader = preload("res://game/relic_light.gdshader")
				light.set_shader_parameter("tint", COLORS[relic_kind])
				light.set_shader_parameter("relic_kind", relic_kind)
				light_materials[relic_kind] = light
			node.set_surface_override_material(index, light_materials[relic_kind])
	for child in node.get_children():
		apply_materials(child, relic_kind)

func _process(delta: float) -> void:
	phase += delta
	visual.position.y = sin(phase * 1.5) * 0.07
	visual.rotation.y += delta * 0.25

func title() -> String:
	return TYPES[kind]

func effect() -> String:
	return ["Bank: +18 seconds", "Loud: attracts the conductor • +25% trip bonus", "F: consume to fold home, keeping other freight", "Carried: muffles bells • Bank: restores composure"][kind]
