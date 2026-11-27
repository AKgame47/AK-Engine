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

func to_array_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tri_count():
		for e in 3:
			st.add_vertex(verts[tris[t * 3 + e]])
	st.generate_normals()
	return st.commit()
