class_name AKMeshOps
extends RefCounted
# AK Modeler mesh operations (stage 2.1). Status: IMPLEMENTED, tested headless by tools/modeler-test.
# Indexed triangle mesh: verts (PackedVector3Array), tris (PackedInt32Array, 3 ints per triangle).
# Front faces are clockwise (Godot convention).

var verts := PackedVector3Array()
var tris := PackedInt32Array()

static func from_primitive(pm: PrimitiveMesh) -> AKMeshOps:
	var m := AKMeshOps.new()
	var arr: Array = pm.get_mesh_arrays()
	var src: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	# weld duplicate positions so edits stay connected
	var map := {}
	var remap := PackedInt32Array()
	for v in src:
		var key := Vector3i((v * 10000.0).round())
		if not map.has(key):
			map[key] = m.verts.size()
			m.verts.append(v)
		remap.append(map[key])
	for i in idx:
		m.tris.append(remap[i])
	return m

func tri_count() -> int:
	return tris.size() / 3

func tri_normal(t: int) -> Vector3:
	var a := verts[tris[t * 3]]
	var b := verts[tris[t * 3 + 1]]
	var c := verts[tris[t * 3 + 2]]
	# clockwise front: normal = (c-a) x (b-a)
	return (c - a).cross(b - a).normalized()

func tri_center(t: int) -> Vector3:
	return (verts[tris[t * 3]] + verts[tris[t * 3 + 1]] + verts[tris[t * 3 + 2]]) / 3.0

func subdivide() -> void:
	# split every triangle into 4 (edge midpoints), shared midpoints
	var mids := {}
	var nt := PackedInt32Array()
	for t in tri_count():
		var i0 := tris[t * 3]
		var i1 := tris[t * 3 + 1]
		var i2 := tris[t * 3 + 2]
		var m01 := _mid(mids, i0, i1)
		var m12 := _mid(mids, i1, i2)
		var m20 := _mid(mids, i2, i0)
		nt.append_array(PackedInt32Array([i0, m01, m20, m01, i1, m12, m20, m12, i2, m01, m12, m20]))
	tris = nt

func _mid(mids: Dictionary, a: int, b: int) -> int:
	var key := Vector2i(mini(a, b), maxi(a, b))
	if not mids.has(key):
		mids[key] = verts.size()
		verts.append((verts[a] + verts[b]) * 0.5)
	return mids[key]

func select_by_aabb(box: AABB) -> PackedInt32Array:
	var out := PackedInt32Array()
	for t in tri_count():
		if box.has_point(tri_center(t)):
			out.append(t)
	return out

func delete_tris(sel: PackedInt32Array) -> void:
	# window/door cutout: remove selected triangles
	var s := {}
	for t in sel:
		s[t] = true
	var nt := PackedInt32Array()
	for t in tri_count():
		if not s.has(t):
			nt.append_array(PackedInt32Array([tris[t * 3], tris[t * 3 + 1], tris[t * 3 + 2]]))
	tris = nt

func extrude(sel: PackedInt32Array, dist: float) -> void:
	# extrude a region of triangles along their average normal; boundary edges get side walls
	var s := {}
	for t in sel:
		s[t] = true
	var n := Vector3.ZERO
	for t in sel:
		n += tri_normal(t)
	n = n.normalized()
	var edge_count := {}
	for t in sel:
		for e in 3:
			var a := tris[t * 3 + e]
			var b := tris[t * 3 + (e + 1) % 3]
			var key := Vector2i(mini(a, b), maxi(a, b))
			edge_count[key] = int(edge_count.get(key, 0)) + 1
	var dup := {}
	for t in sel:
		for e in 3:
			var vi := tris[t * 3 + e]
			if not dup.has(vi):
				dup[vi] = verts.size()
				verts.append(verts[vi] + n * dist)
	for t in sel:
		for e in 3:
			var a := tris[t * 3 + e]
			var b := tris[t * 3 + (e + 1) % 3]
			var key := Vector2i(mini(a, b), maxi(a, b))
			if edge_count[key] == 1:
				# side wall quad a, b, b', a' with the same winding as the cap
				tris.append_array(PackedInt32Array([a, dup[a], dup[b], a, dup[b], b]))
	# move the cap itself
	for t in sel:
		for e in 3:
			tris[t * 3 + e] = dup[tris[t * 3 + e]]

func mirror_x() -> void:
	# Mirror across the YZ plane (x = 0). Appends mirrored copy, flips winding, welds verts on the seam.
	var n := verts.size()
	var remap := PackedInt32Array()
	remap.resize(n)
	for i in n:
		var v := verts[i]
		if absf(v.x) < 0.0001:
			remap[i] = i
		else:
			remap[i] = verts.size()
			verts.append(Vector3(-v.x, v.y, v.z))
	var t0 := tri_count()
	for t in t0:
		tris.append(remap[tris[t * 3]])
		tris.append(remap[tris[t * 3 + 2]])
		tris.append(remap[tris[t * 3 + 1]])

func weld(dist: float) -> int:
	# Merge vertices closer than dist (grid snap). Drops degenerate triangles. Returns removed vertex count.
	var before := verts.size()
	var map := {}
	var remap := PackedInt32Array()
	var nv := PackedVector3Array()
	for v in verts:
		var key := Vector3i((v / dist).round())
		if not map.has(key):
			map[key] = nv.size()
			nv.append(v)
		remap.append(map[key])
	var nt := PackedInt32Array()
	for t in tri_count():
		var a := remap[tris[t * 3]]
		var b := remap[tris[t * 3 + 1]]
		var c := remap[tris[t * 3 + 2]]
		if a != b and b != c and a != c:
			nt.append_array(PackedInt32Array([a, b, c]))
	verts = nv
	tris = nt
	return before - nv.size()

func area() -> float:
	var a := 0.0
	for t in tri_count():
		a += 0.5 * (verts[tris[t * 3 + 1]] - verts[tris[t * 3]]).cross(verts[tris[t * 3 + 2]] - verts[tris[t * 3]]).length()
	return a

func cut_plane(axis: int, at: float) -> int:
	# Loop-cut style split: cut every triangle crossing the plane coord[axis] == at.
	# New vertices sit on the plane and an edge runs along the plane. Returns new vertex count.
	var eps := 0.00001
	var cache := {}
	var out := PackedInt32Array()
	var added := 0
	for t in tri_count():
		var ids := [tris[t * 3], tris[t * 3 + 1], tris[t * 3 + 2]]
		var sg := []
		for i in ids:
			var d: float = verts[i][axis] - at
			sg.append(1 if d > eps else (-1 if d < -eps else 0))
		if not (sg.has(1) and sg.has(-1)):
			out.append_array(PackedInt32Array(ids))
			continue
		var poly := []
		var first_new := -1
		for k in 3:
			var a: int = ids[k]
			var b: int = ids[(k + 1) % 3]
			poly.append(a)
			if sg[k] * sg[(k + 1) % 3] == -1:
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not cache.has(key):
					var va := verts[a]
					var vb := verts[b]
					var u: float = (at - va[axis]) / (vb[axis] - va[axis])
					var p := va.lerp(vb, u)
					p[axis] = at
					cache[key] = verts.size()
					verts.append(p)
					added += 1
				poly.append(cache[key])
				if first_new < 0:
					first_new = poly.size() - 1
		var n: int = poly.size()
		for j in range(1, n - 1):
			out.append(poly[(first_new) % n])
			out.append(poly[(first_new + j) % n])
			out.append(poly[(first_new + j + 1) % n])
	tris = out
	return added

func to_array_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tri_count():
		for e in 3:
			st.add_vertex(verts[tris[t * 3 + e]])
	st.generate_normals()
	return st.commit()
