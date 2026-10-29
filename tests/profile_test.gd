extends SceneTree

var failed := false
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error(message)

func _initialize() -> void:
	for invalid in [null, [], "broken", 4, true]:
		check(MidnightProfile.normalize(invalid) == MidnightProfile.DEFAULTS, "Invalid profile root")
	var partial := MidnightProfile.normalize({"best": 650, "volume": [], "motion": {}, "sensitivity": "fast"})
	check(partial.best == 650 and partial.volume == 0.65 and partial.motion == 0.35 and partial.sensitivity == 1.0, "Malformed fields must not discard valid records")
	var bounded := MidnightProfile.normalize({"best": -10, "best_voyage": 1234.0, "volume": 99, "motion": -4, "sensitivity": 0})
	check(bounded.best == 0 and bounded.best_voyage == 1234, "Record conversion")
	check(bounded.volume == 1 and bounded.motion == 0 and is_equal_approx(bounded.sensitivity, 0.3), "Settings bounds")
	check(MidnightProfile.normalize({"volume": NAN, "motion": INF}) == MidnightProfile.DEFAULTS, "Nonfinite numbers must not poison audio/camera state")
	var path := "user://qa_profile_%d.json" % OS.get_process_id()
	check(MidnightProfile.read_file(path) == MidnightProfile.DEFAULTS, "Missing profile defaults")
	check(MidnightProfile.write_file(path, {"best": 600, "volume": 0.4}), "First save")
	check(MidnightProfile.read_file(path).best == 600, "First save reload")
	check(MidnightProfile.write_file(path, {"best": 850, "volume": 0.2}), "Replace existing save")
	check(MidnightProfile.read_file(path).best == 850, "Replacement reload")
	var interrupted := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	interrupted.store_string('{"best":')
	interrupted.close()
	check(MidnightProfile.read_file(path).best == 850, "Partial temporary file must not replace a good record")
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	corrupt.store_string('{"best":')
	corrupt.close()
	check(MidnightProfile.read_file(path) == MidnightProfile.DEFAULTS, "Corrupt JSON recovery")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".tmp")
	print("PROFILE %s: %d checks, invalid data, bounds, replacement and interrupted saves" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)
