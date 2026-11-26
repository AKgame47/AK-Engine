# SPDX-License-Identifier: MIT
# Copyright (c) 2026 AK Studio
extends Node3D

const WATER := preload("res://shaders/water.gdshader")
const SKY := preload("res://shaders/sky.gdshader")
const FOLIAGE := preload("res://shaders/foliage.gdshader")
const BUOY := preload("res://models/marker-buoy.gltf")
const ROCK := preload("res://models/bank-rock.gltf")
const SAND := preload("res://materials/sand.tres")

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var backdrop := Sky.new()
	backdrop.sky_material = _material(SKY)
	env.sky = backdrop
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c0dad3")
	env.ambient_light_energy = 0.66
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-43, -35, 0)
	light.light_energy = 1.08
	add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(7.8, 4.0, 9.0)
	camera.fov = 63
	add_child(camera)
	camera.look_at(Vector3(-1.4, 0.62, -3.5))
	camera.current = true
	var sea := PlaneMesh.new()
	sea.size = Vector2(450, 450)
	_mesh(sea, _material(WATER), Vector3(0, -0.11, 0))
	var bank := BoxMesh.new()
	bank.size = Vector3(12.0, 0.4, 27.0)
	var shore := _mesh(bank, SAND, Vector3(9.4, 0.03, -4.0))
	shore.rotation.y = 0.09
	_place(BUOY, Vector3(-1.2, -0.12, -0.8), 0.16, 1.65)
	_place(BUOY, Vector3(-4.1, -0.12, -7.3), 0.8, 0.88)
	for n in range(9):
		_place(ROCK, Vector3(3.45 + sin(float(n) * 2.0) * 0.37, 0.07, 3.0 - n * 1.8), n * 0.8, 0.85 + n % 3 * 0.24)
	var reed := QuadMesh.new()
	reed.size = Vector2(0.29, 1.08)
	var foliage := _material(FOLIAGE)
	for i in range(54):
		var z := 4.3 - i * 0.27
		var x := 3.8 + sin(float(i) * 2.27) * 0.57
		for k in range(3):
			var blade := _mesh(reed, foliage, Vector3(x + k * 0.10, 0.64, z - k * 0.11))
			blade.rotation = Vector3(0.0, i * 1.17 + k * 2.09, sin(float(i + k) * 2.0) * 0.12)
			blade.scale.y = 0.65 + float((i + k) % 5) * 0.13
	var overlay := CanvasLayer.new()
	add_child(overlay)
	var legend := Label.new()
	legend.position = Vector2(26, 20)
	legend.text = "AK ENGINE  /  SHADER LAB\nWater · Sky · Foliage"
	legend.add_theme_color_override("font_color", Color("#ecfdf7"))
	legend.add_theme_color_override("font_shadow_color", Color("#16272a"))
	legend.add_theme_constant_override("shadow_offset_x", 1)
	legend.add_theme_constant_override("shadow_offset_y", 2)
	legend.add_theme_font_size_override("font_size", 18)
	overlay.add_child(legend)
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--capture":
		_capture(args[1])

func _material(shader: Shader) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _mesh(shape: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = shape
	item.material_override = material
	item.position = at
	add_child(item)
	return item

func _place(asset: PackedScene, at: Vector3, angle: float, size: float) -> void:
	var instance := asset.instantiate() as Node3D
	instance.position = at
	instance.rotation.y = angle
	instance.scale = Vector3.ONE * size
	add_child(instance)

func _capture(path: String) -> void:
	for i in range(8):
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("No rendered image; use a graphical display, not headless mode.")
		get_tree().quit(1)
		return
	var result := image.save_png(path)
	if result != OK:
		push_error("Failed to write preview PNG: " + error_string(result))
	get_tree().quit(0 if result == OK else 1)
