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
				# side wall quad a, b, b', a' wound so the wall faces away from the region (fixed after render evidence)
				tris.append_array(PackedInt32Array([a, b, dup[b], a, dup[b], dup[a]]))
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

func pick_tri(origin: Vector3, dir: Vector3) -> int:
	# Nearest triangle hit by the ray (Moller-Trumbore, both sides). Returns -1 on a miss.
	var best := -1
	var best_t := INF
	for t in tri_count():
		var a := verts[tris[t * 3]]
		var e1 := verts[tris[t * 3 + 1]] - a
		var e2 := verts[tris[t * 3 + 2]] - a
		var p := dir.cross(e2)
		var det := e1.dot(p)
		if absf(det) < 0.0000001:
			continue
		var inv := 1.0 / det
		var tv := origin - a
		var u := tv.dot(p) * inv
		if u < 0.0 or u > 1.0:
			continue
		var q := tv.cross(e1)
		var v := dir.dot(q) * inv
		if v < 0.0 or u + v > 1.0:
			continue
		var dist := e2.dot(q) * inv
		if dist > 0.0 and dist < best_t:
			best_t = dist
			best = t
	return best

func inset(sel: PackedInt32Array, k: float) -> void:
	# Inset each selected triangle toward its centre by factor k (0..1). Each becomes an inner
	# triangle plus 3 border quads (6 triangles). Winding is kept. This is the face step of a bevel,
	# not a full edge bevel.
	var s := {}
	for t in sel:
		s[t] = true
	var out := PackedInt32Array()
	for t in tri_count():
		var a: int = tris[t * 3]
		var b: int = tris[t * 3 + 1]
		var c: int = tris[t * 3 + 2]
		if not s.has(t):
			out.append_array(PackedInt32Array([a, b, c]))
			continue
		var ctr := tri_center(t)
		var ia := verts.size()
		verts.append(verts[a].lerp(ctr, k))
		verts.append(verts[b].lerp(ctr, k))
		verts.append(verts[c].lerp(ctr, k))
		var ib := ia + 1
		var ic := ia + 2
		out.append_array(PackedInt32Array([ia, ib, ic]))
		out.append_array(PackedInt32Array([a, b, ib, a, ib, ia]))
		out.append_array(PackedInt32Array([b, c, ic, b, ic, ib]))
		out.append_array(PackedInt32Array([c, a, ia, c, ia, ic]))
	tris = out

func region_inset(sel: PackedInt32Array, k: float) -> void:
	# Inset a connected region of triangles toward the region centre by factor k (0..1).
	# Only the region's boundary edges get a border strip, so interior seams stay intact.
	var edge_count := {}
	var ctr := Vector3.ZERO
	var seen := {}
	for t in sel:
		for e in 3:
			var a := tris[t * 3 + e]
			var b := tris[t * 3 + (e + 1) % 3]
			var key := Vector2i(mini(a, b), maxi(a, b))
			edge_count[key] = int(edge_count.get(key, 0)) + 1
			if not seen.has(a):
				seen[a] = true
				ctr += verts[a]
	ctr /= float(seen.size())
	var dup := {}
	for vi in seen.keys():
		dup[vi] = verts.size()
		verts.append(verts[vi].lerp(ctr, k))
	for t in sel:
		for e in 3:
			var a := tris[t * 3 + e]
			var b := tris[t * 3 + (e + 1) % 3]
			var key := Vector2i(mini(a, b), maxi(a, b))
			if edge_count[key] == 1:
				tris.append_array(PackedInt32Array([a, b, dup[b], a, dup[b], dup[a]]))
	for t in sel:
		for e in 3:
			tris[t * 3 + e] = dup[tris[t * 3 + e]]

func bevel_face(sel: PackedInt32Array, k: float, depth: float) -> void:
	# Face bevel: inset the region by k, then push the inner region by -depth along its normal.
	# This is a face-border chamfer (stepped). It is NOT a smooth edge bevel with segments.
	region_inset(sel, k)
	extrude(sel, -depth)

func move_verts(box: AABB, delta: Vector3) -> int:
	# Move every vertex whose position is inside box by delta. Returns how many moved.
	# Use it to slope or taper a part (windshield, nose). Winding is unchanged.
	var n := 0
	for i in verts.size():
		if box.has_point(verts[i]):
			verts[i] += delta
			n += 1
	return n

func smooth(iterations: int, lam: float) -> void:
	# Laplacian smoothing: move each vertex toward the average of its edge neighbours by lam (0..1).
	# Rounds hard forms (shrinks them slightly). Topology and winding are unchanged.
	var nb := []
	nb.resize(verts.size())
	for i in verts.size():
		nb[i] = {}
	for t in tri_count():
		for e in 3:
			var a := tris[t * 3 + e]
			var b := tris[t * 3 + (e + 1) % 3]
			nb[a][b] = true
			nb[b][a] = true
	for it in iterations:
		var np := verts.duplicate()
		for i in verts.size():
			var keys: Array = nb[i].keys()
			if keys.size() == 0:
				continue
			var avg := Vector3.ZERO
			for k in keys:
				avg += verts[k]
			avg /= float(keys.size())
			np[i] = verts[i].lerp(avg, lam)
		verts = np

func to_array_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tri_count():
		for e in 3:
			st.add_vertex(verts[tris[t * 3 + e]])
	st.generate_normals()
	return st.commit()
