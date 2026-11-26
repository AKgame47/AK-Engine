extends SceneTree

func _count(n: Node, acc: Dictionary) -> void:
	if n is MeshInstance3D and n.mesh != null:
		acc["meshes"] += 1
		for s in range(n.mesh.get_surface_count()):
			var arr = n.mesh.surface_get_arrays(s)
			acc["verts"] += arr[Mesh.ARRAY_VERTEX].size()
	for c in n.get_children():
		_count(c, acc)

func _init() -> void:
	var failed := false
	for f in ["res://models/bank-rock.gltf", "res://models/marker-buoy.gltf"]:
		var ps = load(f)
		if ps == null or not (ps is PackedScene):
			print("FAIL load ", f)
			failed = true
			continue
		var root = ps.instantiate()
		var acc := {"meshes": 0, "verts": 0}
		_count(root, acc)
		print("RESULT ", f, " meshes=", acc["meshes"], " verts=", acc["verts"])
		if acc["meshes"] < 1 or acc["verts"] < 3:
			print("FAIL empty ", f)
			failed = true
	print("GLTF_TEST ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
