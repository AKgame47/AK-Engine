extends SceneTree

var failed := false

func _check(name: String, ok: bool, detail: String = "") -> void:
	print("CHECK ", name, " ", "PASS" if ok else "FAIL", " ", detail)
	if not ok:
		failed = true

func _init() -> void:
	# Stage 2.1: build a quad with SurfaceTool, edit it with MeshDataTool (move a vertex, extrude by adding a face), save and reload.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var v := [Vector3(0,0,0), Vector3(1,0,0), Vector3(1,1,0), Vector3(0,1,0)]
	for i in [0,1,2, 0,2,3]:
		st.add_vertex(v[i])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_check("surfacetool_quad_vertices", mesh.surface_get_array_len(0) == 6, str(mesh.surface_get_array_len(0)))

	var mdt := MeshDataTool.new()
	_check("mdt_create", mdt.create_from_surface(mesh, 0) == OK)
	var n0 := mdt.get_vertex_count()
	# move vertex 2 up by 0.5 (a mesh edit)
	var before := mdt.get_vertex(2)
	mdt.set_vertex(2, before + Vector3(0, 0.5, 0))
	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	var mdt2 := MeshDataTool.new()
	mdt2.create_from_surface(mesh, 0)
	_check("vertex_edit", is_equal_approx(mdt2.get_vertex(2).y, before.y + 0.5), str(mdt2.get_vertex(2)))
	_check("vertex_count_kept", mdt2.get_vertex_count() == n0, str(n0))

	# extrude: append a second quad (translated in z) with SurfaceTool.append_from
	var st2 := SurfaceTool.new()
	st2.create_from(mesh, 0)
	st2.append_from(mesh, 0, Transform3D(Basis(), Vector3(0, 0, -1)))
	var mesh2: ArrayMesh = st2.commit()
	_check("append_geometry", mesh2.surface_get_array_len(0) == 12, str(mesh2.surface_get_array_len(0)))

	# save and reload as resource
	var path := "user://edited.res"
	_check("save_mesh", ResourceSaver.save(mesh2, path) == OK)
	var back = load(path)
	_check("reload_mesh", back is ArrayMesh and back.surface_get_array_len(0) == 12)

	# glTF export and re-import through GLTFDocument
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh2
	mi.name = "Edited"
	root.add_child(mi)
	mi.owner = root
	var gd := GLTFDocument.new()
	var gs := GLTFState.new()
	_check("gltf_append", gd.append_from_scene(root, gs) == OK)
	var gpath := "user://edited.gltf"
	_check("gltf_write", gd.write_to_filesystem(gs, gpath) == OK)
	var gd2 := GLTFDocument.new()
	var gs2 := GLTFState.new()
	_check("gltf_read", gd2.append_from_file(gpath, gs2) == OK)
	var scene2 = gd2.generate_scene(gs2)
	var found := 0
	var stack := [scene2]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D:
			found += 1
		for c in n.get_children():
			stack.append(c)
	_check("gltf_roundtrip_mesh", found == 1, str(found))

	# Stage 2.2: create an animation with a position track, play it, check sampled values
	var target := Node3D.new()
	target.name = "Thing"
	var holder := Node3D.new()
	holder.add_child(target)
	root.add_child(holder)
	get_root().add_child(holder)
	var anim := Animation.new()
	anim.length = 2.0
	var tr := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(tr, NodePath("Thing"))
	anim.position_track_insert_key(tr, 0.0, Vector3(0, 0, 0))
	anim.position_track_insert_key(tr, 2.0, Vector3(4, 0, 0))
	var lib := AnimationLibrary.new()
	lib.add_animation("slide", anim)
	var player := AnimationPlayer.new()
	holder.add_child(player)
	player.root_node = NodePath("..")
	player.add_animation_library("", lib)
	player.play("slide")
	player.seek(1.0, true)
	_check("animation_midpoint", absf(target.position.x - 2.0) < 0.01, str(target.position))
	player.seek(2.0, true)
	_check("animation_end", absf(target.position.x - 4.0) < 0.01, str(target.position))

	print("ASSET_TOOLS_TEST ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
