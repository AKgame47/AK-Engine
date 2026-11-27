extends SceneTree
# Headless test of AKMeshOps: primitive weld, subdivide, select, extrude, cutout, ArrayMesh build.
func ok(name: String, cond: bool, info := "") -> void:
	print("CHECK ", name, " ", "PASS" if cond else "FAIL", " ", info)

func _initialize() -> void:
	var Ops = load("res://addons/ak_modeler/ak_mesh_ops.gd")
	var m = Ops.from_primitive(BoxMesh.new())
	ok("box_weld", m.verts.size() == 8, str(m.verts.size()))
	ok("box_tris", m.tri_count() == 12, str(m.tri_count()))
	var n0: int = m.tri_count()
	m.subdivide()
	ok("subdivide_x4", m.tri_count() == n0 * 4, str(m.tri_count()))
	var top = m.select_by_aabb(AABB(Vector3(-1, 0.4, -1), Vector3(2, 0.2, 2)))
	ok("select_top", top.size() == 8, str(top.size()))
	var h0: float = 0.0
	for v in m.verts:
		h0 = maxf(h0, v.y)
	var before: int = m.tri_count()
	m.extrude(top, 0.5)
	var h1: float = 0.0
	for v in m.verts:
		h1 = maxf(h1, v.y)
	ok("extrude_height", absf((h1 - h0) - 0.5) < 0.001, "%f -> %f" % [h0, h1])
	ok("extrude_walls", m.tri_count() > before, str(m.tri_count()))
	var side = m.select_by_aabb(AABB(Vector3(0.4, -0.2, -0.2), Vector3(0.2, 0.4, 0.4)))
	var c0: int = m.tri_count()
	m.delete_tris(side)
	ok("cutout", side.size() > 0 and m.tri_count() == c0 - side.size(), str(side.size()))
	var am: ArrayMesh = m.to_array_mesh()
	ok("array_mesh", am.get_surface_count() == 1 and am.surface_get_array_len(0) == m.tri_count() * 3, str(am.get_surface_count()))
	print("MODELER_TEST DONE")
	quit()
