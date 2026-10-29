class_name MidnightProfile
extends RefCounted
## Small, versioned local profile. Invalid fields fall back independently.

const DEFAULTS := {"version": 1, "best": 0, "best_voyage": 0, "sensitivity": 1.0, "motion": 0.35, "volume": 0.65}
const LIMITS := {"best": Vector2(0, 2147483647), "best_voyage": Vector2(0, 2147483647), "sensitivity": Vector2(0.3, 2), "motion": Vector2(0, 1), "volume": Vector2(0, 1)}

static func normalize(data: Variant) -> Dictionary:
	var result := DEFAULTS.duplicate()
	if not data is Dictionary:
		return result
	for key in LIMITS:
		var value: Variant = data.get(key)
		if (value is int or value is float) and is_finite(float(value)):
			var bounded := clampf(float(value), LIMITS[key].x, LIMITS[key].y)
			result[key] = int(bounded) if key in ["best", "best_voyage"] else bounded
	return result

static func read_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return DEFAULTS.duplicate()
	var document := JSON.new()
	if document.parse(file.get_as_text()) != OK:
		return DEFAULTS.duplicate()
	return normalize(document.data)

static func write_file(path: String, data: Dictionary) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(normalize(data)))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		DirAccess.remove_absolute(temporary)
		return false
	# Keep the previous complete profile if writing fails or the process stops mid-write.
	return DirAccess.rename_absolute(temporary, path) == OK
