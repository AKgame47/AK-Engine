# AK Engine first character: blocky humanoid built with SurfaceTool, with a limb node hierarchy and an Animation (walk cycle),
# exported to glTF, re-imported, and rendered. Status: EXPERIMENTAL, stylized blocks. Not skinned (no Skeleton3D yet), not hyperreal.
extends SceneTree

func _box_mesh(size: Vector3, offset: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := size * 0.5
	var dirs := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	for n in dirs:
		var u: Vector3 = n.cross(Vector3.UP) if abs(n.dot(Vector3.UP)) < 0.9 else n.cross(Vector3.RIGHT)
		u = u.normalized()
		var v: Vector3 = n.cross(u).normalized()
		var c: Vector3 = offset + n * (h * n.abs()).length()
		var du: Vector3 = u * (h * u.abs()).length()
		var dv: Vector3 = v * (h * v.abs()).length()
		var p := [c - du - dv, c + du - dv, c + du + dv, c - du + dv]
		st.set_normal(n)
		var order := [0, 1, 2, 0, 2, 3]
		var flip := (p[1] - p[0]).cross(p[2] - p[0]).dot(n) < 0.0
		if flip:
			order = [0, 2, 1, 0, 3, 2]
		for i in order:
			st.add_vertex(p[i])
	return st.commit()

func _mi(name: String, size: Vector3, offset: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = _box_mesh(size, offset)
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	mi.set_surface_override_material(0, m)
	return mi

func _initialize() -> void:
	var skin := Color(0.85, 0.65, 0.5)
	var shirt := Color(0.75, 0.05, 0.08)
	var pants := Color(0.1, 0.12, 0.2)
	var root_n := Node3D.new()
	root_n.name = "AKCharacter"
	var torso := _mi("Torso", Vector3(0.5, 0.7, 0.28), Vector3(0, 1.15, 0), shirt)
	root_n.add_child(torso)
	torso.add_child(_mi("Head", Vector3(0.3, 0.32, 0.3), Vector3(0, 1.67, 0), skin))
	var limbs := {}
	for spec in [["ArmL", -0.36, 1.45, Vector3(0.16, 0.6, 0.16), shirt], ["ArmR", 0.36, 1.45, Vector3(0.16, 0.6, 0.16), shirt], ["LegL", -0.13, 0.8, Vector3(0.2, 0.8, 0.2), pants], ["LegR", 0.13, 0.8, Vector3(0.2, 0.8, 0.2), pants]]:
		var pivot := Node3D.new()
		pivot.name = spec[0]
		pivot.position = Vector3(spec[1], spec[2], 0)
		root_n.add_child(pivot)
		var sz: Vector3 = spec[3]
		pivot.add_child(_mi(spec[0] + "Mesh", sz, Vector3(0, -sz.y * 0.5, 0), spec[4]))
		limbs[spec[0]] = pivot
	var tris := 0
	for mi in root_n.find_children("*", "MeshInstance3D", true, false):
		tris += (mi as MeshInstance3D).mesh.get_faces().size() / 3
	print("CHAR meshes=", root_n.find_children("*", "MeshInstance3D", true, false).size(), " triangles=", tris)

	var anim := Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	var swing := {"ArmL": 1.0, "ArmR": -1.0, "LegL": -1.0, "LegR": 1.0}
	for k in swing:
		var t := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(t, NodePath(str(k)))
		for i in 3:
			var ang: float = swing[k] * 0.6 * [0.0, 1.0, 0.0][i]
			anim.rotation_track_insert_key(t, 0.5 * i, Quaternion(Vector3.RIGHT, ang))
	var lib := AnimationLibrary.new()
	lib.add_animation("walk", anim)
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root_n.add_child(ap)
	ap.add_animation_library("", lib)
	for c in root_n.find_children("*", "Node", true, false):
		c.owner = root_n

	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(root_n, state)
	print("CHECK gltf_append ", "PASS" if err == OK else "FAIL")
	err = doc.write_to_filesystem(state, "res://ak_character.glb")
	print("CHECK gltf_write ", "PASS" if err == OK else "FAIL")
	var st2 := GLTFState.new()
	var doc2 := GLTFDocument.new()
	err = doc2.append_from_file("res://ak_character.glb", st2)
	var back: Node = doc2.generate_scene(st2) if err == OK else null
	var nm := back.find_children("*", "MeshInstance3D", true, false).size() if back else 0
	var nanim := back.find_children("*", "AnimationPlayer", true, false).size() if back else 0
	print("CHECK gltf_reimport_meshes ", "PASS" if nm == 6 else "FAIL", " ", nm)
	print("CHECK gltf_reimport_animation ", "PASS" if nanim == 1 else "FAIL", " ", nanim)

	var vp := root
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.06, 0.06, 0.08)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.85)
	e.ambient_light_energy = 1.2
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	vp.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(20, 20)
	ground.mesh = pm
	vp.add_child(ground)
	if back:
		vp.add_child(back)
		var p2 := back.find_children("*", "AnimationPlayer", true, false)
		if p2.size() > 0:
			(p2[0] as AnimationPlayer).play("walk")
			(p2[0] as AnimationPlayer).seek(0.25, true)
	var cam := Camera3D.new()
	vp.add_child(cam)
	var cpos := Vector3(2.8, 1.8, 4.2)
	cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, 0.95, 0) - cpos, Vector3.UP), cpos)
	cam.current = true
	await create_timer(1.0).timeout
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("res://character.png")
	print("CHECK render_png ", "PASS" if img.get_width() > 0 else "FAIL", " ", img.get_size())
	print("CHAR_BUILD DONE")
	quit()
