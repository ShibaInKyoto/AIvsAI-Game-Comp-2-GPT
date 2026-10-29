class_name MidnightSatchel
extends Node3D
## Camera-local presentation of the selected cargo. These meshes have no gameplay
## identity or collision and stay inside the player's clearance from the world.

const COMPACT_SCALE := 2.0 / 3.0
const OFFSET := Vector3(0.10, -0.07, -0.18) * COMPACT_SCALE
const VIEW_SCALE := 0.07 * COMPACT_SCALE
const VIEW_LAYER := 2
var current_kind := -1
var item: Node3D

func _ready() -> void:
	position = OFFSET
	scale = Vector3.ONE * VIEW_SCALE
	var bag := preload("res://assets/models/satchel.glb").instantiate()
	add_child(bag)
	prepare_meshes(bag)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, -20, 0)
	fill.light_color = Color("ffe1b5")
	fill.light_energy = 0.22
	fill.light_cull_mask = VIEW_LAYER
	fill.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(fill)

func update_cargo(kind: int, elapsed: float, steps: float, moving: bool, motion: float) -> void:
	if kind != current_kind:
		if item != null:
			remove_child(item)
			item.queue_free()
			item = null
		current_kind = kind
		if kind >= 0:
			item = MidnightFreight.MODELS[kind].instantiate()
			add_child(item)
			MidnightFreight.apply_materials(item, kind)
			prepare_meshes(item)
	var bob := sin(steps * 11) * 0.002 if moving else 0.0
	position = OFFSET + Vector3(sin(elapsed * 0.8) * 0.001, bob, 0) * motion * COMPACT_SCALE
	if item != null:
		item.position.y = 0.78 + sin(elapsed * 1.8) * 0.03 * motion
		item.rotation.y = -0.15 + sin(elapsed * 0.7) * 0.08 * motion

func prepare_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.layers = VIEW_LAYER
	for child in node.get_children():
		prepare_meshes(child)
