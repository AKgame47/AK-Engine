# AK Engine car built with the AK Modeler ops (stage 2.2). Status: EXPERIMENTAL.
# Body, cabin, panels and wheel arches come from AKMeshOps (box, subdivide, region_inset, extrude, bevel_face).
# The script only places parts and sets materials. Stylized sedan, no interior, no textures, no rig.
extends SceneTree

func ok(name: String, cond: bool, info := "") -> void:
	print("CHECK ", name, " ", "PASS" if cond else "FAIL", " ", info)

func _mat(col: Color, metal := 0.0, rough := 0.5, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _shift(o, d: Vector3) -> void:
	for i in o.verts.size():
		o.verts[i] += d

func _panel(o, c: Vector3, half: Vector3, k: float, depth: float) -> int:
	var sel: PackedInt32Array = o.select_by_aabb(AABB(c - half, half * 2.0))
	if sel.size() > 0:
		o.bevel_face(sel, k, depth)
	return sel.size()

func _node(name: String, o, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = o.to_array_mesh()
	mi.material_override = mat
	parent.add_child(mi)
	mi.owner = parent.owner if parent.owner else parent
	return mi

func _box(Ops, size: Vector3, _pos: Vector3, _mat_unused, _name: String, _parent, subs := 1):
	var o = Ops.from_primitive(BoxMesh.new())
	for i in o.verts.size():
		o.verts[i] *= size
	for k in subs:
		o.subdivide()
	return o

func _initialize() -> void:
	var Ops = load("res://addons/ak_modeler/ak_mesh_ops.gd")
	var car := Node3D.new()
	car.name = "AKCar"

	# lower body: 4.4 x 0.6 x 1.9
	var body = Ops.from_primitive(BoxMesh.new())
	for i in body.verts.size():
		body.verts[i] *= Vector3(4.4, 0.6, 1.9)
	body.subdivide()
	body.subdivide()
	var body_tris0: int = body.tri_count()
	var n_hood: int = _panel(body, Vector3(1.1, 0.3, 0), Vector3(1.09, 0.01, 0.47), 0.12, 0.03)
	var n_trunk: int = _panel(body, Vector3(-1.65, 0.3, 0), Vector3(0.54, 0.01, 0.47), 0.12, 0.03)
	var n_door_l: int = _panel(body, Vector3(0.0, 0.0, 0.95), Vector3(1.09, 0.14, 0.01), 0.1, 0.03)
	var n_door_r: int = _panel(body, Vector3(0.0, 0.0, -0.95), Vector3(1.09, 0.14, 0.01), 0.1, 0.03)
	var n_arch := 0
	for wx in [1.65, -1.65]:
		for sz in [0.95, -0.95]:
			n_arch += _panel(body, Vector3(wx, -0.15, sz), Vector3(0.54, 0.14, 0.01), 0.1, 0.1)
	var nose: int = body.move_verts(AABB(Vector3(1.6, 0.2, -1), Vector3(1.0, 0.2, 2)), Vector3(0, -0.14, 0))
	var tail: int = body.move_verts(AABB(Vector3(-2.6, 0.2, -1), Vector3(1.0, 0.2, 2)), Vector3(0, -0.1, 0))
	body.smooth(1, 0.2)
	_shift(body, Vector3(0, 0.55, 0))
	var paint := _mat(Color(0.62, 0.05, 0.07), 0.6, 0.28)
	_node("Body", body, paint, car)
	ok("body_panels", n_hood > 0 and n_trunk > 0 and n_door_l > 0 and n_door_r > 0 and n_arch >= 8, "hood %d trunk %d doors %d/%d arches %d" % [n_hood, n_trunk, n_door_l, n_door_r, n_arch])
	ok("body_tris_grew", body.tri_count() > body_tris0, "%d -> %d" % [body_tris0, body.tri_count()])

	# cabin: a box whose roof is inset (narrowed) with the region_inset op, then raised with extrude
	var cab = Ops.from_primitive(BoxMesh.new())
	for i in cab.verts.size():
		cab.verts[i] *= Vector3(2.3, 0.45, 1.7)
	cab.subdivide()
	var wind: int = cab.move_verts(AABB(Vector3(1.0, 0.2, -1), Vector3(0.5, 0.1, 2)), Vector3(-0.55, 0, 0))
	var rear: int = cab.move_verts(AABB(Vector3(-1.5, 0.2, -1), Vector3(0.5, 0.1, 2)), Vector3(0.45, 0, 0))
	var roof: PackedInt32Array = cab.select_by_aabb(AABB(Vector3(-2, 0.2, -1), Vector3(4, 0.1, 2)))
	cab.region_inset(roof, 0.28)
	cab.extrude(roof, 0.06)
	_shift(cab, Vector3(-0.3, 1.075, 0))
	var glass := _mat(Color(0.28, 0.4, 0.5), 0.2, 0.08)
	_node("Cabin", cab, glass, car)
	ok("cabin_roof_sel", roof.size() > 0, str(roof.size()))
	ok("slopes_moved", nose > 0 and tail > 0 and wind > 0 and rear > 0, "nose %d tail %d windshield %d rear %d" % [nose, tail, wind, rear])

	# lights, bumpers, grille (small boxes built by the same box primitive and ops)
	var lamp_m := _mat(Color(0.85, 0.82, 0.7), 0.0, 0.2)
	lamp_m.emission_enabled = true
	lamp_m.emission = Color(1.0, 0.95, 0.75)
	lamp_m.emission_energy_multiplier = 0.3
	var tail_m := _mat(Color(0.9, 0.0, 0.0), 0.0, 0.3)
	tail_m.emission_enabled = true
	tail_m.emission = Color(0.7, 0.0, 0.0)
	var dark := _mat(Color(0.05, 0.05, 0.06), 0.4, 0.5)
	var bits := [["HeadL", Vector3(0.28, 0.16, 0.4), Vector3(2.2, 0.62, 0.62), lamp_m], ["HeadR", Vector3(0.28, 0.16, 0.4), Vector3(2.2, 0.62, -0.62), lamp_m],
		["TailL", Vector3(0.2, 0.14, 0.45), Vector3(-2.2, 0.68, 0.62), tail_m], ["TailR", Vector3(0.2, 0.14, 0.45), Vector3(-2.2, 0.68, -0.62), tail_m],
		["Grille", Vector3(0.12, 0.2, 0.7), Vector3(2.23, 0.56, 0), dark], ["BumperF", Vector3(0.22, 0.16, 1.95), Vector3(2.25, 0.36, 0), dark], ["BumperR", Vector3(0.22, 0.16, 1.95), Vector3(-2.25, 0.36, 0), dark],
		["SeamL1", Vector3(0.025, 0.3, 0.02), Vector3(-0.55, 0.7, 0.96), dark], ["SeamL2", Vector3(0.025, 0.3, 0.02), Vector3(0.6, 0.7, 0.96), dark], ["SeamL3", Vector3(0.025, 0.3, 0.02), Vector3(-1.2, 0.7, 0.96), dark],
		["SeamR1", Vector3(0.025, 0.3, 0.02), Vector3(-0.55, 0.7, -0.96), dark], ["SeamR2", Vector3(0.025, 0.3, 0.02), Vector3(0.6, 0.7, -0.96), dark], ["SeamR3", Vector3(0.025, 0.3, 0.02), Vector3(-1.2, 0.7, -0.96), dark],
		["MirrorL", Vector3(0.14, 0.1, 0.2), Vector3(0.75, 1.0, 0.93), dark], ["MirrorR", Vector3(0.14, 0.1, 0.2), Vector3(0.75, 1.0, -0.93), dark]]
	for bp in bits:
		var bo = Ops.from_primitive(BoxMesh.new())
		for i in bo.verts.size():
			bo.verts[i] *= bp[1]
		bo.subdivide()
		_shift(bo, bp[2])
		var bn := _node(bp[0], bo, bp[3], car)
		bn.name = bp[0]
	var rim := _mat(Color(0.72, 0.74, 0.78), 0.9, 0.25)

	# wheels: cylinder primitive through the modeler (rotated to lie across Z)
	var tire := _mat(Color(0.03, 0.03, 0.035), 0.0, 0.85)
	var wheels := 0
	for wx in [1.65, -1.65]:
		for sz in [0.9, -0.9]:
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.36
			cyl.bottom_radius = 0.36
			cyl.height = 0.28
			cyl.radial_segments = 32
			var w = Ops.from_primitive(cyl)
			var cap: PackedInt32Array = w.select_by_aabb(AABB(Vector3(-0.2, 0.1, -0.2), Vector3(0.4, 0.1, 0.4)))
			if cap.size() > 0:
				w.region_inset(cap, 0.45)
			var wn := _node("Wheel%d" % wheels, w, tire, car)
			wn.rotation_degrees = Vector3(90, 0, 0)
			wn.position = Vector3(wx, 0.36, sz)
			var rc := CylinderMesh.new()
			rc.top_radius = 0.2
			rc.bottom_radius = 0.2
			rc.height = 0.3
			rc.radial_segments = 24
			var ro = Ops.from_primitive(rc)
			var rn := _node("Rim%d" % wheels, ro, rim, car)
			rn.rotation_degrees = Vector3(90, 0, 0)
			rn.position = Vector3(wx, 0.36, sz)
			wheels += 1
	ok("wheels", wheels == 4, str(wheels))
	var part_count: int = car.get_child_count()
	var total := 0
	for c in car.get_children():
		total += (c as MeshInstance3D).mesh.get_faces().size() / 3
	ok("car_tris", total > 2000, str(total))

	var root_n := Node3D.new()
	root_n.add_child(car)
	car.owner = root_n
	for c in car.get_children():
		c.owner = root_n
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(root_n, state)
	ok("gltf_append", err == OK)
	err = doc.write_to_filesystem(state, "res://ak_car_modeler.glb")
	ok("gltf_write", err == OK)
	var st2 := GLTFState.new()
	var doc2 := GLTFDocument.new()
	err = doc2.append_from_file("res://ak_car_modeler.glb", st2)
	var back: Node = doc2.generate_scene(st2) if err == OK else null
	var nm: int = back.find_children("*", "MeshInstance3D", true, false).size() if back else 0
	ok("gltf_reimport_meshes", nm == part_count, "%d of %d" % [nm, part_count])

	var vp := root
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.25, 0.38, 0.6)
	psm.sky_horizon_color = Color(0.7, 0.75, 0.82)
	sky.sky_material = psm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -35, 0)
	sun.light_energy = 1.3
	vp.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	ground.mesh = pm
	ground.set_surface_override_material(0, _mat(Color(0.2, 0.2, 0.22), 0.0, 0.8))
	vp.add_child(ground)
	if back:
		vp.add_child(back)
	var cam := Camera3D.new()
	cam.fov = 35.0
	vp.add_child(cam)
	cam.current = true
	var views := [["car_modeler.png", Vector3(5.5, 2.4, 5.0)], ["car_modeler_side.png", Vector3(0.0, 1.0, 8.0)], ["car_modeler_front.png", Vector3(8.0, 1.2, 0.5)]]
	for vw in views:
		var cpos: Vector3 = vw[1]
		cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, 0.9, 0) - cpos, Vector3.UP), cpos)
		await create_timer(0.6).timeout
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("res://" + str(vw[0]))
		ok("render_" + str(vw[0]), img.get_width() > 0, str(img.get_size()))
	print("CAR_MODELER DONE")
	quit()
