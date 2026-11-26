extends SceneTree

func _initialize():
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	root.size = Vector2i(960, 540)

func _process(_delta):
	if Engine.get_frames_drawn() < 10:
		return false
	var img = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://").path_join("../shot.png"))
	print("SHOT_SAVED ", img.get_width(), "x", img.get_height(), " renderer=", RenderingServer.get_video_adapter_name())
	quit()
	return true
