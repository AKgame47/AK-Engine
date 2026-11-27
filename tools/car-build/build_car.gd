# AK Engine car asset v2: detailed procedural model built only with engine mesh code (ArrayMesh via SurfaceTool).
# Lofted body shell (curved panels, tumblehome, hood/windshield/roof/rear-window profile), separate glass surface,
# revolved tyres with sidewall profile, spoked rims, brake discs, lights, mirrors, grille, bumpers, door lines.
# Status: EXPERIMENTAL scripted generation. No UVs/textures, no wheel arches, no interior. Not hyperreal.
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

func _interp(keys: Array, z: float) -> float:
	if z <= keys[0][0]:
		return keys[0][1]
	for i in range(keys.size() - 1):
		var z0: float = keys[i][0]
		var z1: float = keys[i + 1][0]
		if z <= z1:
			var u: float = (z - z0) / (z1 - z0)
			u = u * u * (3.0 - 2.0 * u)
			return lerpf(keys[i][1], keys[i + 1][1], u)
	return keys[keys.size() - 1][1]

func _box(mb: MB, c: Vector3, s: Vector3) -> void:
	var h := s * 0.5
	var idx: Array = []
	for i in 8:
		var p := c + Vector3(h.x if (i & 1) else -h.x, h.y if (i & 2) else -h.y, h.z if (i & 4) else -h.z)
		idx.append(mb.add_v(p, c))
	for f in [[0, 1, 3, 2], [4, 5, 7, 6], [0, 1, 5, 4], [2, 3, 7, 6], [0, 2, 6, 4], [1, 3, 7, 5]]:
		mb.quad(idx[f[0]], idx[f[1]], idx[f[2]], idx[f[3]])

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

func _revolve(mb: MB, c: Vector3, sx: float, prof: Array, anchor_r: float, anchor_dx: float, seg := 40) -> void:
	# revolve (radius, dx) profile around the wheel axis (x). sx = +1/-1 outward side.
	var grid: Array = []
	for pr in prof:
		var row: Array = []
		for j in seg:
			var ph := TAU * j / seg
			var cy := cos(ph)
			var sz := sin(ph)
			var p := c + Vector3(sx * pr[1], pr[0] * cy, pr[0] * sz)
			var an := c + Vector3(sx * anchor_dx, anchor_r * cy, anchor_r * sz)
			row.append(mb.add_v(p, an))
		grid.append(row)
	for i in range(prof.size() - 1):
		for j in seg:
			mb.quad(grid[i][j], grid[i][(j + 1) % seg], grid[i + 1][(j + 1) % seg], grid[i + 1][j])

func _wheel(tyre: MB, rim: MB, brake: MB, c: Vector3, sx: float) -> void:
	_revolve(tyre, c, sx, [[0.25, -0.12], [0.31, -0.135], [0.35, -0.11], [0.365, -0.06], [0.37, 0.0], [0.365, 0.06], [0.35, 0.11], [0.31, 0.135], [0.25, 0.12]], 0.30, 0.0, 48)
	# rim barrel and lip
	_revolve(rim, c, sx, [[0.235, -0.11], [0.245, -0.05], [0.245, 0.09], [0.262, 0.115], [0.25, 0.128]], 0.20, 0.0, 48)
	# hub cap
	_revolve(rim, c, sx, [[0.0, 0.135], [0.04, 0.13], [0.07, 0.115]], 0.0, -0.05, 24)
	# five spokes
	for k in 5:
		var base := TAU * k / 5.0
		var pts: Array = []
		for sp in [[0.065, -0.10], [0.065, 0.10], [0.24, 0.17], [0.24, -0.17]]:
			var ang: float = base + sp[1]
			pts.append(rim.add_v(c + Vector3(sx * 0.108, sp[0] * cos(ang), sp[0] * sin(ang)), c + Vector3(sx * -0.4, 0, 0)))
		rim.quad(pts[0], pts[1], pts[2], pts[3])
	# brake disc behind the spokes
	_revolve(brake, c, sx, [[0.06, 0.035], [0.20, 0.04], [0.205, 0.02]], 0.12, -0.2, 40)
	# caliper
	_box(brake, c + Vector3(sx * 0.05, 0.16, 0.10), Vector3(0.05, 0.10, 0.12))
	# dark backing so gaps between spokes read as depth
	_revolve(tyre, c, sx, [[0.0, 0.05], [0.24, 0.06]], 0.0, -0.4, 40)

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

func _initialize() -> void:
	var NS := 84
	var NM := 40
	var top_keys := [[-2.25, 0.60], [-2.12, 0.86], [-1.75, 0.96], [-1.25, 0.98], [-0.6, 1.43], [0.3, 1.45], [1.0, 1.00], [1.5, 0.93], [2.0, 0.80], [2.25, 0.56]]
	var w_keys := [[-2.25, 0.16], [-2.12, 0.60], [-1.8, 0.85], [-1.3, 0.90], [0.0, 0.92], [1.3, 0.90], [1.8, 0.86], [2.12, 0.66], [2.25, 0.18]]
	var y0_keys := [[-2.25, 0.46], [-2.0, 0.30], [-1.5, 0.24], [1.5, 0.24], [2.0, 0.30], [2.25, 0.44]]
	var belt := 0.97
	var body := MB.new()
	var glass := MB.new()
	var grid: Array = []
	var cen: Array = []
	for i in range(NS + 1):
		var tt := float(i) / NS
		var z := -2.25 + 4.5 * (0.5 - 0.5 * cos(PI * tt))
		var w := _interp(w_keys, z)
		var yt := _interp(top_keys, z)
		var y0 := _interp(y0_keys, z)
		var yc := (yt + y0) * 0.5
		var hy := (yt - y0) * 0.5
		var row: Array = []
		for j in NM:
			var th := TAU * j / NM
			var c := cos(th)
			var s := sin(th)
			var x := w * signf(c) * pow(absf(c), 0.62)
			var y := yc + hy * signf(s) * pow(absf(s), 0.62)
			if y > belt and yt > belt:
				var k := clampf((y - belt) / (yt - belt), 0.0, 1.0)
				x *= 1.0 - 0.24 * k
			row.append(Vector3(x, y, z))
		grid.append(row)
		cen.append(Vector3(0, yc, z))
	var bmap := {}
	var gmap := {}
	for i in NS:
		for j in NM:
			var q := [grid[i][j], grid[i][(j + 1) % NM], grid[i + 1][(j + 1) % NM], grid[i + 1][j]]
			var qi := [Vector2i(i, j), Vector2i(i, (j + 1) % NM), Vector2i(i + 1, (j + 1) % NM), Vector2i(i + 1, j)]
			var cp: Vector3 = (q[0] + q[1] + q[2] + q[3]) * 0.25
			var yt2 := _interp(top_keys, cp.z)
			var is_glass := false
			if cp.y > belt + 0.03:
				var ax := absf(cp.x)
				if cp.z > 0.35 and cp.z < 1.03 and ax < 0.62:
					is_glass = true
				elif cp.z > -1.27 and cp.z < -0.58 and ax < 0.58:
					is_glass = true
				elif cp.y < yt2 - 0.07 and ax > 0.45 and ((cp.z > 0.05 and cp.z < 0.85) or (cp.z > -0.8 and cp.z < -0.04)):
					is_glass = true
			var mb: MB = glass if is_glass else body
			var mp: Dictionary = gmap if is_glass else bmap
			var ids: Array = []
			for n in 4:
				var key: Vector2i = qi[n]
				if not mp.has(key):
					mp[key] = mb.add_v(grid[key.x][key.y], cen[key.x])
				ids.append(mp[key])
			mb.quad(ids[0], ids[1], ids[2], ids[3])
	# end caps
	for end_i in [0, NS]:
		var cidx := body.add_v(cen[end_i], cen[end_i] + Vector3(0, 0, -1.0 if end_i == 0 else 1.0))
		for j in NM:
			var key0 := Vector2i(end_i, j)
			var key1 := Vector2i(end_i, (j + 1) % NM)
			if not bmap.has(key0):
				bmap[key0] = body.add_v(grid[key0.x][key0.y], cen[end_i])
			if not bmap.has(key1):
				bmap[key1] = body.add_v(grid[key1.x][key1.y], cen[end_i])
			body.tri(cidx, bmap[key0], bmap[key1])

	var trim := MB.new()
	var headl := MB.new()
	var taill := MB.new()
	var mirrors := MB.new()
	var tyre := MB.new()
	var rim := MB.new()
	var brake := MB.new()
	_box(trim, Vector3(0, 0.52, 2.14), Vector3(0.62, 0.16, 0.05))
	_box(trim, Vector3(0, 0.30, 2.10), Vector3(1.10, 0.07, 0.10))
	_box(trim, Vector3(0, 0.34, -2.12), Vector3(1.25, 0.08, 0.10))
	_box(trim, Vector3(0, 0.62, -2.19), Vector3(0.50, 0.12, 0.02))
	for sx in [-1.0, 1.0]:
		for dz in [0.55, -0.55]:
			_box(trim, Vector3(sx * 0.926, 0.68, dz), Vector3(0.012, 0.42, 0.012))
		_box(trim, Vector3(sx * 0.93, 0.80, 0.40), Vector3(0.02, 0.025, 0.12))
		_box(trim, Vector3(sx * 0.93, 0.80, -0.70), Vector3(0.02, 0.025, 0.12))
		_ellipsoid(headl, Vector3(sx * 0.56, 0.70, 2.07), Vector3(0.17, 0.065, 0.10))
		_ellipsoid(taill, Vector3(sx * 0.60, 0.80, -2.07), Vector3(0.18, 0.06, 0.07))
		_ellipsoid(mirrors, Vector3(sx * 1.00, 1.04, 0.72), Vector3(0.09, 0.07, 0.05))
		_box(trim, Vector3(sx * 0.93, 1.00, 0.74), Vector3(0.08, 0.03, 0.03))
		for wz in [1.38, -1.38]:
			_wheel(tyre, rim, brake, Vector3(sx * 0.83, 0.37, wz), sx)

	var car := Node3D.new()
	car.name = "AKCar"
	car.add_child(_mesh_node("Body", body, true, _mat(Color(0.7, 0.03, 0.05), 0.0, 0.35)))
	car.add_child(_mesh_node("Glass", glass, true, _mat(Color(0.05, 0.08, 0.11), 0.2, 0.05)))
	car.add_child(_mesh_node("Trim", trim, false, _mat(Color(0.04, 0.04, 0.045), 0.0, 0.6)))
	car.add_child(_mesh_node("Headlights", headl, true, _mat(Color(0.9, 0.8, 0.5), 0.0, 0.3, true)))
	car.add_child(_mesh_node("Taillights", taill, true, _mat(Color(0.9, 0.05, 0.05), 0.0, 0.3, true)))
	car.add_child(_mesh_node("Mirrors", mirrors, true, _mat(Color(0.7, 0.03, 0.05), 0.0, 0.35)))
	car.add_child(_mesh_node("Tyres", tyre, true, _mat(Color(0.025, 0.025, 0.028), 0.0, 0.9)))
	car.add_child(_mesh_node("Rims", rim, false, _mat(Color(0.78, 0.78, 0.82), 0.9, 0.25)))
	car.add_child(_mesh_node("Brakes", brake, false, _mat(Color(0.35, 0.35, 0.38), 0.7, 0.4)))
	for c in car.get_children():
		c.owner = car
	var tris := 0
	for c in car.get_children():
		tris += (c as MeshInstance3D).mesh.get_faces().size() / 3
	print("CAR parts=", car.get_child_count(), " triangles=", tris)
	print("CHECK triangle_count ", "PASS" if tris > 8000 else "FAIL", " ", tris)

	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(car, state)
	print("CHECK gltf_append ", "PASS" if err == OK else "FAIL")
	err = doc.write_to_filesystem(state, "res://ak_car.glb")
	print("CHECK gltf_write ", "PASS" if err == OK else "FAIL")
	var st2 := GLTFState.new()
	var doc2 := GLTFDocument.new()
	err = doc2.append_from_file("res://ak_car.glb", st2)
	var back: Node = doc2.generate_scene(st2) if err == OK else null
	var n_back: int = back.find_children("*", "MeshInstance3D", true, false).size() if back else 0
	print("CHECK gltf_reimport_meshes ", "PASS" if n_back == 9 else "FAIL", " ", n_back)

	var vp := root
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.25, 0.38, 0.6)
	psm.sky_horizon_color = Color(0.7, 0.75, 0.82)
	psm.ground_horizon_color = Color(0.45, 0.46, 0.5)
	psm.ground_bottom_color = Color(0.15, 0.15, 0.17)
	sky.sky_material = psm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -40, 0)
	sun.light_energy = 1.3
	vp.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 140, 0)
	fill.light_energy = 0.4
	vp.add_child(fill)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	ground.mesh = pm
	ground.set_surface_override_material(0, _mat(Color(0.2, 0.2, 0.22), 0.0, 0.8))
	vp.add_child(ground)
	vp.add_child(back if back else car)
	var cam := Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)
	cam.current = true
	var views := [["car.png", Vector3(5.6, 1.7, 6.4)], ["car_side.png", Vector3(8.0, 1.0, 0.3)], ["car_rear.png", Vector3(-5.0, 1.8, -6.6)]]
	for vw in views:
		var cpos: Vector3 = vw[1]
		cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, 0.65, 0) - cpos, Vector3.UP), cpos)
		await create_timer(0.6).timeout
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("res://" + str(vw[0]))
		print("CHECK render_", vw[0], " ", "PASS" if img.get_width() > 0 else "FAIL", " ", img.get_size())
	print("CAR_BUILD DONE")
	quit()
