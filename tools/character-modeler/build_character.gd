# AK Engine character built with the AK Modeler ops (stage 2.2). Status: EXPERIMENTAL.
# Parts come from AKMeshOps (box and sphere and cylinder primitives, subdivide, move_verts, bevel_face, delete_tris).
# Stylized low-poly humanoid, static pose, no rig, no skinning, no fingers, no textures.
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

func _box(Ops, size: Vector3, pos: Vector3, mat: Material, name: String, parent: Node3D, subs := 1):
	var o = Ops.from_primitive(BoxMesh.new())
	for i in o.verts.size():
		o.verts[i] *= size
	for k in subs:
		o.subdivide()
	return o

func _initialize() -> void:
	var Ops = load("res://addons/ak_modeler/ak_mesh_ops.gd")
	var ch := Node3D.new()
	ch.name = "AKCharacter"
	var skin := _mat(Color(0.78, 0.58, 0.45), 0.0, 0.6)
	var shirt := _mat(Color(0.12, 0.35, 0.62), 0.0, 0.7)
	var pants := _mat(Color(0.14, 0.14, 0.18), 0.0, 0.8)
	var shoe := _mat(Color(0.06, 0.05, 0.05), 0.1, 0.5)
	var hair := _mat(Color(0.08, 0.05, 0.03), 0.0, 0.6)
	var dark := _mat(Color(0.02, 0.02, 0.03), 0.0, 0.4)

	# torso: ellipsoid chest (sphere primitive scaled) plus a waist box; collar and hem panels via bevel_face
	var sp0 := SphereMesh.new()
	sp0.radius = 1.0
	sp0.height = 2.0
	sp0.radial_segments = 28
	sp0.rings = 14
	var chestm = Ops.from_primitive(sp0)
	for i in chestm.verts.size():
		chestm.verts[i] *= Vector3(0.27, 0.23, 0.15)
	_shift(chestm, Vector3(0, 1.37, 0))
	_node("Chest", chestm, shirt, ch)
	var waist = _box(Ops, Vector3(0.34, 0.46, 0.22), Vector3.ZERO, shirt, "Waist", ch)
	var t1: int = waist.move_verts(AABB(Vector3(0.15, -0.3, -0.3), Vector3(0.2, 0.15, 0.6)), Vector3(-0.04, 0, 0))
	var t2: int = waist.move_verts(AABB(Vector3(-0.35, -0.3, -0.3), Vector3(0.2, 0.15, 0.6)), Vector3(0.04, 0, 0))
	var hem: PackedInt32Array = waist.select_by_aabb(AABB(Vector3(-0.2, -0.2, 0.11), Vector3(0.4, 0.1, 0.02)))
	if hem.size() > 0:
		waist.bevel_face(hem, 0.1, 0.012)
	waist.taubin(4, 0.5, 0.53)
	_shift(waist, Vector3(0, 1.12, 0))
	_node("Waist", waist, shirt, ch)
	ok("torso_ops", t1 > 0 and t2 > 0, "taper %d/%d hem %d" % [t1, t2, hem.size()])

	var pelvis = _box(Ops, Vector3(0.50, 0.24, 0.27), Vector3.ZERO, pants, "Pelvis", ch, 3)
	pelvis.taubin(6, 0.5, 0.53)
	_shift(pelvis, Vector3(0, 0.8, 0))
	_node("Pelvis", pelvis, pants, ch)

	# limbs: upper and lower segments with joint spheres
	for sx in [1.0, -1.0]:
		var jl := [["Thigh", 0.095, 0.08, 0.4, Vector3(0.12 * sx, 0.6, 0), pants], ["Shin", 0.075, 0.06, 0.4, Vector3(0.12 * sx, 0.2, 0), pants],
			["UpperArm", 0.065, 0.058, 0.3, Vector3(0.35 * sx, 1.25, 0), shirt], ["Forearm", 0.055, 0.045, 0.28, Vector3(0.35 * sx, 0.96, 0), shirt]]
		for j in jl:
			var lc := CylinderMesh.new()
			lc.top_radius = j[1]
			lc.bottom_radius = j[2]
			lc.height = j[3]
			lc.radial_segments = 20
			var seg = Ops.from_primitive(lc)
			_shift(seg, j[4])
			_node("%s%d" % [j[0], int(sx)], seg, j[5], ch)
		var joints := [["Shoulder", 0.075, Vector3(0.34 * sx, 1.4, 0), shirt], ["Elbow", 0.055, Vector3(0.35 * sx, 1.1, 0), shirt], ["Knee", 0.078, Vector3(0.12 * sx, 0.4, 0), pants], ["Hand", 0.055, Vector3(0.35 * sx, 0.8, 0), skin]]
		for jt in joints:
			var hs := SphereMesh.new()
			hs.radius = jt[1]
			hs.height = jt[1] * 2.0
			hs.radial_segments = 16
			hs.rings = 8
			var jo = Ops.from_primitive(hs)
			_shift(jo, jt[2])
			_node("%s%d" % [jt[0], int(sx)], jo, jt[3], ch)
		# hands: palm block plus four fingers and a thumb, built with the same box primitive
		var palm = _box(Ops, Vector3(0.07, 0.1, 0.045), Vector3.ZERO, skin, "Palm", ch, 1)
		palm.smooth(1, 0.3)
		_shift(palm, Vector3(0.35 * sx, 0.73, 0))
		_node("Palm%d" % int(sx), palm, skin, ch)
		for fi in 4:
			var fg = _box(Ops, Vector3(0.016, 0.07, 0.016), Vector3.ZERO, skin, "Finger", ch, 1)
			_shift(fg, Vector3(0.35 * sx, 0.65, -0.0165 * 1.5 + 0.0165 * fi))
			_node("Finger%d_%d" % [int(sx), fi], fg, skin, ch)
		var th = _box(Ops, Vector3(0.016, 0.055, 0.016), Vector3.ZERO, skin, "Thumb", ch, 1)
		_shift(th, Vector3(0.35 * sx + 0.045 * sx, 0.73, 0.0))
		_node("Thumb%d" % int(sx), th, skin, ch)
		var ft = _box(Ops, Vector3(0.15, 0.08, 0.3), Vector3.ZERO, shoe, "Shoe", ch, 2)
		ft.smooth(2, 0.45)
		_shift(ft, Vector3(0.12 * sx, 0.04, 0.07))
		_node("Shoe%d" % int(sx), ft, shoe, ch)

	# neck and head
	var nc := CylinderMesh.new()
	nc.top_radius = 0.05
	nc.bottom_radius = 0.09
	nc.height = 0.17
	var neck = Ops.from_primitive(nc)
	neck.smooth(1, 0.3)
	_shift(neck, Vector3(0, 1.56, 0))
	_node("Neck", neck, skin, ch)
	var sp := SphereMesh.new()
	sp.radius = 1.0
	sp.height = 2.0
	sp.radial_segments = 28
	sp.rings = 14
	var head = Ops.from_primitive(sp)
	for i in head.verts.size():
		head.verts[i] *= Vector3(0.105, 0.13, 0.115)
	_shift(head, Vector3(0, 1.72, 0))
	_node("Head", head, skin, ch)
	# hair: slightly larger sphere with the lower half and the face side removed using delete_tris
	var hr = Ops.from_primitive(sp)
	for i in hr.verts.size():
		hr.verts[i] *= Vector3(0.112, 0.138, 0.122)
	var lowhair: PackedInt32Array = hr.select_by_aabb(AABB(Vector3(-0.2, -0.2, -0.2), Vector3(0.4, 0.15, 0.4)))
	var face_side: PackedInt32Array = hr.select_by_aabb(AABB(Vector3(-0.2, -0.05, 0.075), Vector3(0.4, 0.1, 0.2)))
	var drop := PackedInt32Array()
	for t in lowhair:
		drop.append(t)
	for t in face_side:
		if not drop.has(t):
			drop.append(t)
	var hair_before: int = hr.tri_count()
	hr.delete_tris(drop)
	_shift(hr, Vector3(0, 1.735, -0.004))
	_node("Hair", hr, hair, ch)
	ok("hair_cut", hr.tri_count() < hair_before and hr.tri_count() > 100, "%d -> %d" % [hair_before, hr.tri_count()])
	for sx in [1.0, -1.0]:
		var es := SphereMesh.new()
		es.radius = 0.014
		es.height = 0.028
		es.radial_segments = 10
		es.rings = 6
		var eye = Ops.from_primitive(es)
		_shift(eye, Vector3(0.04 * sx, 1.74, 0.108))
		_node("Eye%d" % int(sx), eye, dark, ch)
	var nose = _box(Ops, Vector3(0.025, 0.04, 0.03), Vector3.ZERO, skin, "Nose", ch, 0)
	_shift(nose, Vector3(0, 1.70, 0.12))
	_node("Nose", nose, skin, ch)

	var part_count: int = ch.get_child_count()
	var total := 0
	for c in ch.get_children():
		total += (c as MeshInstance3D).mesh.get_faces().size() / 3
	ok("parts", part_count >= 25, str(part_count))
	ok("char_tris", total > 3000, str(total))
	var car := ch

	var root_n := Node3D.new()
	root_n.add_child(car)
	car.owner = root_n
	for c in car.get_children():
		c.owner = root_n
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(root_n, state)
	ok("gltf_append", err == OK)
	err = doc.write_to_filesystem(state, "res://ak_character_modeler.glb")
	ok("gltf_write", err == OK)
	var st2 := GLTFState.new()
	var doc2 := GLTFDocument.new()
	err = doc2.append_from_file("res://ak_character_modeler.glb", st2)
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
	cam.fov = 30.0
	vp.add_child(cam)
	cam.current = true
	var views := [["character_modeler.png", Vector3(2.6, 1.7, 3.4)], ["character_modeler_side.png", Vector3(4.2, 1.0, 0.2)], ["character_modeler_front.png", Vector3(0.3, 1.3, 4.5)]]
	for vw in views:
		var cpos: Vector3 = vw[1]
		cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, 0.95, 0) - cpos, Vector3.UP), cpos)
		await create_timer(0.6).timeout
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("res://" + str(vw[0]))
		ok("render_" + str(vw[0]), img.get_width() > 0, str(img.get_size()))
	print("CHAR_MODELER DONE")
	quit()
