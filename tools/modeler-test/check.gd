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
	var mm = Ops.from_primitive(BoxMesh.new())
	for i in mm.verts.size():
		mm.verts[i] += Vector3(1, 0, 0)
	var n_src: Vector3 = mm.tri_normal(0)
	mm.mirror_x()
	ok("mirror_counts", mm.verts.size() == 16 and mm.tri_count() == 24, "%d verts %d tris" % [mm.verts.size(), mm.tri_count()])
	var n_mir: Vector3 = mm.tri_normal(12)
	ok("mirror_winding", absf(n_mir.x + n_src.x) < 0.001 and absf(n_mir.y - n_src.y) < 0.001 and absf(n_mir.z - n_src.z) < 0.001, "%s vs %s" % [str(n_src), str(n_mir)])
	var xmin: float = 99.0
	for v in mm.verts:
		xmin = minf(xmin, v.x)
	ok("mirror_extent", absf(xmin + 1.5) < 0.001, str(xmin))
	var wm = Ops.from_primitive(BoxMesh.new())
	var wn: int = wm.verts.size()
	wm.verts.append(wm.verts[0] + Vector3(0.0001, 0, 0))
	wm.tris.append_array(PackedInt32Array([wn, 1, 2]))
	var removed: int = wm.weld(0.01)
	ok("weld_removed", removed == 1 and wm.verts.size() == 8, str(removed))
	ok("weld_tris", wm.tri_count() == 13, str(wm.tri_count()))
	var cm = Ops.from_primitive(BoxMesh.new())
	cm.subdivide()
	var a_before: float = cm.area()
	var t_before: int = cm.tri_count()
	var added: int = cm.cut_plane(1, 0.13)
	var on_plane: int = 0
	for v in cm.verts:
		if absf(v.y - 0.13) < 0.0001:
			on_plane += 1
	ok("cut_adds_verts", added > 0 and on_plane >= added, "%d added %d on plane" % [added, on_plane])
	ok("cut_splits_tris", cm.tri_count() > t_before, "%d -> %d" % [t_before, cm.tri_count()])
	ok("cut_area_kept", absf(cm.area() - a_before) < 0.0001, "%f vs %f" % [a_before, cm.area()])
	var flipped: int = 0
	for t in cm.tri_count():
		var c: Vector3 = cm.tri_center(t)
		if cm.tri_normal(t).dot(c) < -0.0001:
			flipped += 1
	ok("cut_winding_outward", flipped == 0, str(flipped))
	var pm = Ops.from_primitive(BoxMesh.new())
	var hit: int = pm.pick_tri(Vector3(0.1, 0.1, 5), Vector3(0, 0, -1))
	ok("pick_front", hit >= 0 and pm.tri_center(hit).z > 0.4, str(hit))
	var hit_back: int = pm.pick_tri(Vector3(0.1, 0.1, -5), Vector3(0, 0, 1))
	ok("pick_back", hit_back >= 0 and pm.tri_center(hit_back).z < -0.4, str(hit_back))
	ok("pick_miss", pm.pick_tri(Vector3(5, 5, 5), Vector3(0, 0, -1)) == -1, "miss")
	var im = Ops.from_primitive(BoxMesh.new())
	var ia0: float = im.area()
	var it0: int = im.tri_count()
	var iv0: int = im.verts.size()
	im.inset(PackedInt32Array([0, 1]), 0.3)
	ok("inset_counts", im.tri_count() == it0 + 12 and im.verts.size() == iv0 + 6, "%d tris %d verts" % [im.tri_count(), im.verts.size()])
	ok("inset_area_kept", absf(im.area() - ia0) < 0.0001, "%f vs %f" % [ia0, im.area()])
	var iflip: int = 0
	for t in im.tri_count():
		if im.tri_normal(t).dot(im.tri_center(t)) < -0.0001:
			iflip += 1
	ok("inset_winding_outward", iflip == 0, str(iflip))
	var rm = Ops.from_primitive(BoxMesh.new())
	var rtop: PackedInt32Array = rm.select_by_aabb(AABB(Vector3(-1, 0.4, -1), Vector3(2, 1, 2)))
	ok("region_top_sel", rtop.size() == 2, str(rtop.size()))
	var rt0: int = rm.tri_count()
	var rv0: int = rm.verts.size()
	rm.region_inset(rtop, 0.25)
	ok("region_inset_counts", rm.tri_count() == rt0 + 8 and rm.verts.size() == rv0 + 4, "%d tris %d verts" % [rm.tri_count(), rm.verts.size()])
	var cap_up: int = 0
	for t in rtop:
		if rm.tri_normal(t).y > 0.9:
			cap_up += 1
	ok("region_inset_cap_up", cap_up == 2, str(cap_up))
	var rflip: int = 0
	for t in rm.tri_count():
		if rm.tri_normal(t).dot(rm.tri_center(t)) < -0.0001:
			rflip += 1
	ok("region_inset_winding_outward", rflip == 0, str(rflip))
	var bm = Ops.from_primitive(BoxMesh.new())
	var btop: PackedInt32Array = bm.select_by_aabb(AABB(Vector3(-1, 0.4, -1), Vector3(2, 1, 2)))
	bm.bevel_face(btop, 0.25, 0.1)
	var inner_y: float = bm.tri_center(btop[0]).y
	ok("bevel_face_depth", absf(inner_y - 0.4) < 0.0001, "inner y %f" % inner_y)
	ok("bevel_face_counts", bm.tri_count() == 12 + 8 + 8 and bm.verts.size() == 8 + 4 + 4, "%d tris %d verts" % [bm.tri_count(), bm.verts.size()])
	var plug = load("res://addons/ak_modeler/plugin.gd")
	ok("plugin_script_parses", plug != null and plug.can_instantiate(), "parse and compile only, UI not opened")
	print("MODELER_TEST DONE")
	quit()
