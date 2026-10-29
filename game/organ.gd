class_name MidnightOrgan
extends Node3D
## A single-use stop on the choir's existing organ. Its carriage owns its transform.

var used := false
var caption: Label3D
var surface: StandardMaterial3D

func _ready() -> void:
	var stop := MeshInstance3D.new()
	var knob := CylinderMesh.new()
	knob.top_radius = 0.065
	knob.bottom_radius = 0.045
	knob.height = 0.15
	knob.radial_segments = 12
	stop.mesh = knob
	stop.position.x = 0.1
	stop.rotation.z = PI / 2
	stop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface = StandardMaterial3D.new()
	surface.albedo_color = Color("d8b77e")
	surface.metallic = 0.7
	surface.roughness = 0.3
	surface.emission_enabled = true
	surface.emission = Color("d8b77e")
	surface.emission_energy_multiplier = 0.35
	stop.material_override = surface
	add_child(stop)
	caption = Label3D.new()
	caption.text = "THE CHOIR ORGAN"
	caption.font = preload("res://assets/fonts/body.ttf")
	caption.font_size = 22
	caption.outline_size = 3
	caption.pixel_size = 0.003
	caption.position.y = 0.55
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.modulate = Color("d8b77e")
	add_child(caption)

func activate() -> bool:
	if used:
		return false
	used = true
	surface.emission_enabled = false
	surface.albedo_color = Color("54666a")
	caption.text = "THE CHOIR IS SILENT"
	caption.modulate = Color("71848a")
	return true
