extends SceneTree

func _initialize() -> void:
	call_deferred("check_batch")

func check_batch() -> void:
	var train := MidnightTrain.new()
	root.add_child(train)
	var material := train.mat("ffffff")
	var triangle := SurfaceTool.new()
	triangle.begin(Mesh.PRIMITIVE_TRIANGLES)
	triangle.add_vertex(Vector3(-9, 0, 0))
	triangle.add_vertex(Vector3(-8, 1, 0))
	triangle.add_vertex(Vector3(-8, 0, 0))
	triangle.generate_normals()
	var custom := MeshInstance3D.new()
	custom.mesh = triangle.commit()
	custom.material_override = material
	train.add_child(custom)
	train.block(Vector3(4, 0, 0), Vector3.ONE, material)
	train.batch_geometry(train)
	var merged := train.get_child(0) as MeshInstance3D
	# One triangle plus the cube's twelve faces must all survive the merge.
	var valid: bool = train.get_child_count() == 1 and merged.mesh.surface_get_array_index_len(0) == 39
	var arrays := merged.mesh.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var custom_referenced := false
	for index in indices:
		if positions[index].x < -7:
			custom_referenced = true
	valid = valid and custom_referenced
	train.queue_free()
	await process_frame
	if not valid:
		push_error("Batched custom geometry lost its triangles")
	print("GEOMETRY %s: custom triangles and indexed primitives survive shared-material batching" % ("PASS" if valid else "FAIL"))
	quit(0 if valid else 1)
