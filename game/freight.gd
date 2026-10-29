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

func configure(type: int, price: int, identity: int) -> void:
	kind = type
	value = price
	serial = identity
	phase = float(identity) * 1.73

func _ready() -> void:
	visual = MODELS[kind].instantiate()
	add_child(visual)
	style_relic(visual)

func style_relic(node: Node) -> void:
	if node is MeshInstance3D:
		for index in range(node.mesh.get_surface_count()):
			var surface := node.mesh.surface_get_material(index) as StandardMaterial3D
			if surface == null or not surface.emission_enabled:
				continue
			if not light_materials.has(kind):
				var light := ShaderMaterial.new()
				light.shader = preload("res://game/relic_light.gdshader")
				light.set_shader_parameter("tint", COLORS[kind])
				light.set_shader_parameter("relic_kind", kind)
				light_materials[kind] = light
			node.set_surface_override_material(index, light_materials[kind])
	for child in node.get_children():
		style_relic(child)

func _process(delta: float) -> void:
	phase += delta
	visual.position.y = sin(phase * 1.5) * 0.07
	visual.rotation.y += delta * 0.25

func title() -> String:
	return TYPES[kind]

func effect() -> String:
	return ["Bank: +18 seconds", "Loud: attracts the conductor • +25% trip bonus", "F: consume to fold home, keeping other freight", "Carried: muffles bells • Bank: restores composure"][kind]
