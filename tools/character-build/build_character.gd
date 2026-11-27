# AK Engine character v2: detailed procedural humanoid built only with engine mesh code (smooth tapered limbs,
# head with nose/ears/eyes/hair, torso, sleeves, trousers, shoes), pivoted limbs with a walk Animation, exported to glTF.
# Status: EXPERIMENTAL scripted generation. No skinning/Skeleton3D, no fingers, no face detail beyond eyes/nose/ears, no textures.
extends SceneTree

class MB extends RefCounted:
	var v := PackedVector3Array()
	var a := PackedVector3Array()
	var t := PackedInt32Array()
	func add_v(p: Vector3, anchor: Vector3) -> int:
		v.append(p)
		a.append(anchor)
		return v.size() - 1
	func tri(i: int, j: int, k: int) -> void:
		var n: Vector3 = (v[i] - v[j]).cross(v[i] - v[k])
		var cen: Vector3 = (v[i] + v[j] + v[k]) / 3.0
		var anc: Vector3 = (a[i] + a[j] + a[k]) / 3.0
		if n.dot(cen - anc) > 0.0:
			var tmp := j
			j = k
			k = tmp
		t.append(i)
		t.append(j)
		t.append(k)
	func quad(i: int, j: int, k: int, l: int) -> void:
		tri(i, j, k)
		tri(i, k, l)
	func tris() -> int:
		return t.size() / 3
	func build(smooth: bool) -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var sn := PackedVector3Array()
		sn.resize(v.size())
		for q in range(0, t.size(), 3):
			var n: Vector3 = (v[t[q]] - v[t[q + 2]]).cross(v[t[q]] - v[t[q + 1]])
			for r in 3:
				sn[t[q + r]] += n
		for q in range(0, t.size(), 3):
			var fn: Vector3 = (v[t[q]] - v[t[q + 2]]).cross(v[t[q]] - v[t[q + 1]]).normalized()
			for r in 3:
				var idx: int = t[q + r]
				st.set_normal(sn[idx].normalized() if smooth else fn)
				st.add_vertex(v[idx])
		return st.commit()

func _ellipsoid(mb: MB, c: Vector3, r: Vector3, seg := 14, rings := 8) -> void:
	var grid: Array = []
	for i in range(rings + 1):
		var th := PI * i / rings
		var row: Array = []
		for j in seg:
			var ph := TAU * j / seg
			var p := c + Vector3(r.x * sin(th) * cos(ph), r.y * cos(th), r.z * sin(th) * sin(ph))
			row.append(mb.add_v(p, c))
		grid.append(row)
	for i in rings:
		for j in seg:
			mb.quad(grid[i][j], grid[i][(j + 1) % seg], grid[i + 1][(j + 1) % seg], grid[i + 1][j])

func _mat(col: Color, metal := 0.0, rough := 0.5, emit := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 0.5
	return m

func _mesh_node(name: String, mb: MB, smooth: bool, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mb.build(smooth)
	mi.set_surface_override_material(0, mat)
	return mi


# tapered capsule/limb: rings of radius r(t) along a segment a->b (smooth, closed with domes)
func _limb(mb: MB, a: Vector3, b: Vector3, ra: float, rb: float, squash := 1.0, seg := 20, rings := 14) -> void:
	var axis := (b - a)
	var seglen: float = axis.length()
	var up := axis.normalized()
	var side := up.cross(Vector3.FORWARD).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var fwd := side.cross(up).normalized()
	var grid: Array = []
	for i in range(rings + 1):
		var t := float(i) / rings
		var r := lerpf(ra, rb, t)
		# round the two ends with a quarter-ellipse falloff
		var cap := 1.0
		if t < 0.12:
			cap = sqrt(maxf(0.0, 1.0 - pow((0.12 - t) / 0.12, 2.0)))
		elif t > 0.88:
			cap = sqrt(maxf(0.0, 1.0 - pow((t - 0.88) / 0.12, 2.0)))
		var c := a + up * (seglen * t)
		var row: Array = []
		for j in seg:
			var ph := TAU * j / seg
			var p := c + side * (cos(ph) * r * cap) + fwd * (sin(ph) * r * cap * squash)
			row.append(mb.add_v(p, c))
		grid.append(row)
	for i in rings:
		for j in seg:
			mb.quad(grid[i][j], grid[i][(j + 1) % seg], grid[i + 1][(j + 1) % seg], grid[i + 1][j])

func _initialize() -> void:
	var skin := MB.new()
	var shirt := MB.new()
	var pants := MB.new()
	var shoes := MB.new()
	var hair := MB.new()
	var eyes := MB.new()
	var root_n := Node3D.new()
	root_n.name = "AKCharacter"
	# torso, neck, head built in the root frame
	_limb(shirt, Vector3(0, 0.98, 0), Vector3(0, 1.55, 0), 0.20, 0.25, 0.62)
	_limb(shirt, Vector3(0, 0.84, 0), Vector3(0, 1.06, 0), 0.19, 0.20, 0.62)
	_limb(skin, Vector3(0, 1.50, 0), Vector3(0, 1.68, 0), 0.065, 0.06)
	_ellipsoid(skin, Vector3(0, 1.80, 0), Vector3(0.105, 0.13, 0.115), 24, 16)
	_ellipsoid(skin, Vector3(0, 1.77, 0.115), Vector3(0.022, 0.03, 0.03), 10, 6)
	_ellipsoid(hair, Vector3(0, 1.86, -0.015), Vector3(0.112, 0.105, 0.12), 24, 12)
	for sx in [-1.0, 1.0]:
		_ellipsoid(eyes, Vector3(sx * 0.04, 1.82, 0.105), Vector3(0.016, 0.012, 0.01), 8, 6)
		_ellipsoid(skin, Vector3(sx * 0.108, 1.80, 0.0), Vector3(0.016, 0.034, 0.024), 8, 6)
	root_n.add_child(_mesh_node("Shirt", shirt, true, _mat(Color(0.7, 0.04, 0.07), 0.0, 0.85)))
	root_n.add_child(_mesh_node("Skin", skin, true, _mat(Color(0.82, 0.6, 0.47), 0.0, 0.6)))
	root_n.add_child(_mesh_node("Hair", hair, true, _mat(Color(0.06, 0.04, 0.03), 0.0, 0.5)))
	root_n.add_child(_mesh_node("Eyes", eyes, true, _mat(Color(0.02, 0.02, 0.02), 0.0, 0.2)))
	# limbs as pivoted nodes so the walk animation can rotate them
	var pivots := {}
	var specs := [
		["ArmL", Vector3(-0.30, 1.48, 0), true], ["ArmR", Vector3(0.30, 1.48, 0), true],
		["LegL", Vector3(-0.11, 0.92, 0), false], ["LegR", Vector3(0.11, 0.92, 0), false]]
	for sp in specs:
		var piv := Node3D.new()
		piv.name = sp[0]
		piv.position = sp[1]
		root_n.add_child(piv)
		pivots[sp[0]] = piv
		var is_arm: bool = sp[2]
		var sleeve := MB.new()
		var limb_skin := MB.new()
		var limb_cloth := MB.new()
		var foot := MB.new()
		if is_arm:
			_limb(limb_cloth, Vector3.ZERO, Vector3(0, -0.24, 0), 0.062, 0.056, 1.0)
			_limb(limb_skin, Vector3(0, -0.22, 0), Vector3(0, -0.50, 0), 0.052, 0.040, 1.0)
			_ellipsoid(limb_skin, Vector3(0, -0.56, 0.0), Vector3(0.042, 0.06, 0.028), 14, 8)
			piv.add_child(_mesh_node(sp[0] + "Sleeve", limb_cloth, true, _mat(Color(0.7, 0.04, 0.07), 0.0, 0.85)))
			piv.add_child(_mesh_node(sp[0] + "Forearm", limb_skin, true, _mat(Color(0.82, 0.6, 0.47), 0.0, 0.6)))
		else:
			_limb(limb_cloth, Vector3.ZERO, Vector3(0, -0.46, 0), 0.098, 0.068, 1.0)
			_limb(limb_cloth, Vector3(0, -0.42, 0), Vector3(0, -0.84, 0), 0.068, 0.052, 1.0)
			_ellipsoid(foot, Vector3(0, -0.90, 0.05), Vector3(0.055, 0.045, 0.12), 16, 8)
			piv.add_child(_mesh_node(sp[0] + "Trousers", limb_cloth, true, _mat(Color(0.08, 0.1, 0.18), 0.0, 0.85)))
			piv.add_child(_mesh_node(sp[0] + "Shoe", foot, true, _mat(Color(0.9, 0.9, 0.9), 0.0, 0.5)))
	var tris := 0
	var meshes := root_n.find_children("*", "MeshInstance3D", true, false)
	for mi in meshes:
		tris += (mi as MeshInstance3D).mesh.get_faces().size() / 3
	print("CHAR meshes=", meshes.size(), " triangles=", tris)
	print("CHECK triangle_count ", "PASS" if tris > 5000 else "FAIL", " ", tris)

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
	var nm: int = back.find_children("*", "MeshInstance3D", true, false).size() if back else 0
	var nanim: int = back.find_children("*", "AnimationPlayer", true, false).size() if back else 0
	print("CHECK gltf_reimport_meshes ", "PASS" if nm == meshes.size() else "FAIL", " ", nm)
	print("CHECK gltf_reimport_animation ", "PASS" if nanim == 1 else "FAIL", " ", nanim)

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
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 140, 0)
	fill.light_energy = 0.4
	vp.add_child(fill)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	ground.mesh = pm
	ground.set_surface_override_material(0, _mat(Color(0.2, 0.2, 0.22), 0.0, 0.8))
	vp.add_child(ground)
	if back:
		vp.add_child(back)
		var p2: Array = back.find_children("*", "AnimationPlayer", true, false)
		if p2.size() > 0:
			(p2[0] as AnimationPlayer).play("walk")
			(p2[0] as AnimationPlayer).seek(0.25, true)
	var cam := Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)
	cam.current = true
	var views := [["character.png", Vector3(2.6, 1.6, 3.4)], ["character_side.png", Vector3(4.2, 1.0, 0.2)], ["character_front.png", Vector3(0.3, 1.3, 4.5)]]
	for vw in views:
		var cpos: Vector3 = vw[1]
		cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, 0.95, 0) - cpos, Vector3.UP), cpos)
		await create_timer(0.6).timeout
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("res://" + str(vw[0]))
		print("CHECK render_", vw[0], " ", "PASS" if img.get_width() > 0 else "FAIL", " ", img.get_size())
	print("CHAR_BUILD DONE")
	quit()
