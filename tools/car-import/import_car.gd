# Import test: load a third-party CC0 glTF car (tevy.dev Mid-Engine Supercar v2, LOD1) with the engine's glTF importer,
# count meshes and triangles, and render it. Status: EXPERIMENTAL import proof. The model is NOT made by AK Engine.
extends SceneTree

func _count(n: Node, acc: Dictionary) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		acc["meshes"] += 1
		acc["tris"] += (n as MeshInstance3D).mesh.get_faces().size() / 3
	for c in n.get_children():
		_count(c, acc)

func _initialize() -> void:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file("res://supercar_lod1.glb", state)
	print("CHECK gltf_load ", "PASS" if err == OK else "FAIL", " err=", err)
	var model: Node = doc.generate_scene(state) if err == OK else null
	print("CHECK scene_generated ", "PASS" if model else "FAIL")
	var acc := {"meshes": 0, "tris": 0}
	if model:
		_count(model, acc)
	print("IMPORT meshes=", acc["meshes"], " triangles=", acc["tris"])
	print("CHECK has_meshes ", "PASS" if acc["meshes"] > 10 else "FAIL", " ", acc["meshes"])
	print("CHECK detailed ", "PASS" if acc["tris"] > 20000 else "FAIL", " ", acc["tris"])
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
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -40, 0)
	sun.light_energy = 1.3
	vp.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.2, 0.2, 0.22)
	ground.set_surface_override_material(0, gm)
	vp.add_child(ground)
	if model:
		vp.add_child(model)
	var cam := Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)
	cam.current = true
	var views := [["import.png", Vector3(5.6, 1.7, 6.4)], ["import_side.png", Vector3(8.4, 1.0, 0.3)]]
	for vw in views:
		var cpos: Vector3 = vw[1]
		cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, 0.6, 0) - cpos, Vector3.UP), cpos)
		await create_timer(0.8).timeout
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("res://" + str(vw[0]))
		print("CHECK render_", vw[0], " ", "PASS" if img.get_width() > 0 else "FAIL")
	print("CAR_IMPORT DONE")
	quit()
