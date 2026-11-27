# AK Engine first asset: a low-poly car built only with engine mesh APIs (SurfaceTool), exported to glTF, then rendered.
# Status: EXPERIMENTAL, stylized low-poly. Not an interactive editor tool yet and not hyperreal.
extends SceneTree

func _box(st: SurfaceTool, c: Vector3, s: Vector3, top_scale := 1.0) -> void:
	# axis-aligned box centred at c with size s; the top face can be narrowed (top_scale) for a cabin taper.
	var h := s * 0.5
	var v := []
	for i in 8:
		var x := -h.x if (i & 1) == 0 else h.x
		var y := -h.y if (i & 2) == 0 else h.y
		var z := -h.z if (i & 4) == 0 else h.z
		if y > 0.0:
			x *= top_scale
		v.append(c + Vector3(x, y, z))
	var faces := [[0,1,3,2],[4,6,7,5],[0,2,6,4],[1,5,7,3],[0,4,5,1],[2,3,7,6]]
	for f in faces:
		var a: Vector3 = v[f[0]]
		var b: Vector3 = v[f[1]]
		var d: Vector3 = v[f[2]]
		var e: Vector3 = v[f[3]]
		var n := (b - a).cross(e - a).normalized()
		# make sure the normal points away from the box centre
		if n.dot(a - c) < 0.0:
			n = -n
			var tmp := b; b = e; e = tmp
		st.set_normal(n)
		for p in [a, b, d, a, d, e]:
			st.add_vertex(p)

func _wheel(st: SurfaceTool, c: Vector3, r: float, w: float, seg := 16) -> void:
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var p0 := Vector3(0, sin(a0) * r, cos(a0) * r)
		var p1 := Vector3(0, sin(a1) * r, cos(a1) * r)
		var xo := Vector3(w * 0.5, 0, 0)
		var n := Vector3(0, sin((a0 + a1) * 0.5), cos((a0 + a1) * 0.5))
		st.set_normal(n)
		for p in [c - xo + p0, c + xo + p0, c + xo + p1, c - xo + p0, c + xo + p1, c - xo + p1]:
			st.add_vertex(p)
		st.set_normal(Vector3.RIGHT)
		for p in [c + xo, c + xo + p0, c + xo + p1]:
			st.add_vertex(p)
		st.set_normal(Vector3.LEFT)
		for p in [c - xo, c - xo + p1, c - xo + p0]:
			st.add_vertex(p)

func _part(name: String, color: Color, fn: Callable) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	fn.call(st)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = 0.6 if name != "Tyres" else 0.0
	m.roughness = 0.35 if name != "Tyres" else 0.9
	mi.set_surface_override_material(0, m)
	return mi

func _initialize() -> void:
	var car := Node3D.new()
	car.name = "AKCar"
	car.add_child(_part("Body", Color(0.75, 0.05, 0.08), func(st): _box(st, Vector3(0, 0.55, 0), Vector3(1.8, 0.5, 4.2))))
	car.add_child(_part("Cabin", Color(0.12, 0.14, 0.18), func(st): _box(st, Vector3(0, 1.05, -0.2), Vector3(1.6, 0.55, 2.2), 0.8)))
	car.add_child(_part("Tyres", Color(0.12, 0.12, 0.13), func(st):
		for x in [-0.95, 0.95]:
			for z in [-1.35, 1.35]:
				_wheel(st, Vector3(x, 0.38, z), 0.38, 0.3)))
	car.add_child(_part("Lights", Color(1.0, 0.9, 0.6), func(st):
		for x in [-0.6, 0.6]:
			_box(st, Vector3(x, 0.6, 2.11), Vector3(0.4, 0.15, 0.05))))
	for c in car.get_children():
		c.owner = car
	var tris := 0
	for c in car.get_children():
		tris += (c as MeshInstance3D).mesh.get_faces().size() / 3
	print("CAR parts=", car.get_child_count(), " triangles=", tris)

	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(car, state)
	print("CHECK gltf_append ", "PASS" if err == OK else "FAIL")
	err = doc.write_to_filesystem(state, "res://ak_car.glb")
	print("CHECK gltf_write ", "PASS" if err == OK else "FAIL")
	var st2 := GLTFState.new()
	var doc2 := GLTFDocument.new()
	err = doc2.append_from_file("res://ak_car.glb", st2)
	var back := doc2.generate_scene(st2) if err == OK else null
	var n := 0
	if back:
		for c in back.find_children("*", "MeshInstance3D", true, false):
			n += 1
	print("CHECK gltf_reimport_meshes ", "PASS" if n == 4 else "FAIL", " ", n)

	# render
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
	sun.light_energy = 1.4
	vp.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(30, 30)
	ground.mesh = pm
	vp.add_child(ground)
	vp.add_child(back if back else car)
	var cam := Camera3D.new()
	vp.add_child(cam)
	cam.position = Vector3(7.5, 3.2, 8.5)
	cam.fov = 55.0
	var cpos := Vector3(7.5, 3.2, 8.5)
	var tgt := Vector3(0, 0.6, 0)
	cam.global_transform = Transform3D(Basis.looking_at(tgt - cpos, Vector3.UP), cpos)
	print('CAM ', cam.global_transform, ' CARPOS ', (back if back else car).global_position)
	cam.current = true
	await create_timer(1.0).timeout
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("res://car.png")
	print("CHECK render_png ", "PASS" if img.get_width() > 0 else "FAIL", " ", img.get_size())
	print("CAR_BUILD DONE")
	quit()
