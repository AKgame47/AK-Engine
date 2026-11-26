extends SceneTree

var failed := false

func _check(name: String, ok: bool, detail: String = "") -> void:
	print("CHECK ", name, " ", "PASS" if ok else "FAIL", " ", detail)
	if not ok:
		failed = true

func _init() -> void:
	var expected := int(OS.get_environment("AK_EXPECTED_ID"))
	_check("class_exists", ClassDB.class_exists("AKCore") and ClassDB.class_exists("AKFrameStats"))
	_check("version", AKCore.get_version() == "AK Core 0.0.1", AKCore.get_version())
	var id := AKCore.asset_id("assets/hero.glb")
	_check("asset_id_matches_fnv1a", id == expected, str(id) + " expected " + str(expected))
	_check("asset_id_stable", AKCore.asset_id("a") == AKCore.asset_id("a") and AKCore.asset_id("a") != AKCore.asset_id("b"))
	_check("rebase_far", AKCore.needs_rebase(5000.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1000.0))
	_check("rebase_near", not AKCore.needs_rebase(10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1000.0))
	var fs := AKFrameStats.new()
	for i in range(100):
		fs.add(0.01)
	fs.add(0.1)
	_check("framestats_count", fs.get_count() == 101)
	_check("framestats_avg", absf(fs.avg_fps() - 101.0 / 1.1) < 0.01, str(fs.avg_fps()))
	_check("framestats_low1", absf(fs.low1_fps() - 10.0) < 0.01, str(fs.low1_fps()))
	var scene3 := Node.new()
	for i in range(5):
		scene3.add_child(Node3D.new())
	scene3.add_child(Node2D.new())
	var scene2 := Node.new()
	for i in range(5):
		scene2.add_child(Node2D.new())
	_check("detect_3d", AKCore.detect_game_kind(scene3) == "3d", AKCore.detect_game_kind(scene3))
	_check("detect_2d", AKCore.detect_game_kind(scene2) == "2d", AKCore.detect_game_kind(scene2))
	_check("detect_unknown", AKCore.detect_game_kind(Node.new()) == "unknown")
	_check("select_2d_godot", AKCore.select_renderer("2d", true) == "godot")
	_check("select_3d_o3de_if_available", AKCore.select_renderer("3d", true) == "o3de")
	_check("select_3d_fallback_godot", AKCore.select_renderer("3d", false) == "godot" and AKCore.renderer_is_fallback("3d", false))
	print("AK_MODULE_TEST ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
