# SPDX-License-Identifier: MIT
extends Control

const Scene := preload("res://scene.gd")
const INK := Color("#EDE9E1")
const MUTED := Color("#8E9395")
const SOFT := Color("#B1B4B4")
const ACCENT := Color("#D9A16C")
const BASE := Color("#181A1C")
const DOCK := Color("#1E2022")
const RULE := Color("#303336")
const RAISED := Color("#26282A")
const MARK := "res://mark.svg"

var lab: Node3D
var visual: SubViewport
var viewport_shell: SubViewportContainer
var stage: Control
var tree: Tree
var inspector: VBoxContainer
var tray: HBoxContainer
var status_line: Label
var view_label: Label
var projection_label: Label
var selection: Node3D
var selection_name := "Intake Turbine"
var mode := "Select"
var filter_text := ""
var running := false
var show_guides := false
var changed := false
var list_items := {}
var tab_buttons := {}
var tool_buttons := {}
var file_tabs := {}
var projection: Button
var grid_toggle: Button
var play_toggle: Button
var breadcrumb: Label
var active_folder := "Scene"
var font := SystemFont.new()
var strong := SystemFont.new()
var mono := SystemFont.new()

func _ready() -> void:
	font.font_names = ["Inter","Liberation Sans","DejaVu Sans"]
	strong.font_names = font.font_names
	strong.font_weight = 700
	mono.font_names = ["DejaVu Sans Mono","Liberation Mono"]
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 12
	theme.set_color("font_color","Label",INK)
	_setup()
	_select(selection_name)
	var args := OS.get_cmdline_user_args()
	if args.has("--check"):
		_check()
	elif args.size() == 2 and args[0] == "--capture":
		_capture(args[1])

func _setup() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BASE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var root := _v(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_header(root)
	root.add_child(_rule())
	var central := _h(0)
	central.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(central)
	_left(central)
	central.add_child(_rule(Color("#111315"),true))
	var main := _v(0)
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	central.add_child(main)
	_viewport(main)
	_assets(main)
	central.add_child(_rule(Color("#111315"),true))
	_right(central)
	root.add_child(_rule())
	var bottom := _surface(BASE,27)
	root.add_child(bottom)
	var footer := _h(12)
	bottom.add_child(_margin(footer,12,12,0,0))
	footer.add_child(_label("●",ACCENT,10))
	status_line = _label("Ready",SOFT,11)
	footer.add_child(status_line)
	footer.add_child(_stretch())
	footer.add_child(_label("LOCAL  /  STUDIO PREVIEW",MUTED,10,false,true))
	footer.add_child(_rule(RULE,true))
	footer.add_child(_label("COMPATIBILITY",SOFT,10,false,true))

func _header(root: VBoxContainer) -> void:
	var shell := _surface(BASE,49)
	root.add_child(shell)
	var row := _h(12)
	shell.add_child(_margin(row,15,15,0,0))
	var mark := TextureRect.new()
	mark.texture = load(MARK)
	mark.custom_minimum_size = Vector2(37,24)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(mark)
	row.add_child(_label("AK ENGINE",INK,12,true))
	row.add_child(_rule(RULE,true))
	row.add_child(_label("Studio",SOFT,12))
	row.add_child(_stretch())
	row.add_child(_label("RELAY STUDY",MUTED,10,true,true))
	row.add_child(_label("/",MUTED,12))
	row.add_child(_label("Workspace",INK,12))
	row.add_child(_stretch())
	play_toggle = _btn("Preview","Toggle live turbine animation")
	play_toggle.toggle_mode = true
	play_toggle.toggled.connect(_preview)
	row.add_child(play_toggle)
	row.add_child(_btn("Reset","Reset the model, camera, and selection",_reset))
	row.add_child(_rule(RULE,true))
	row.add_child(_label("LOCAL",ACCENT,10,true,true))

func _left(row: HBoxContainer) -> void:
	var shell := _surface(DOCK)
	shell.custom_minimum_size.x = 222
	row.add_child(shell)
	var col := _v(0)
	shell.add_child(col)
	_heading(col,"SCENE","01")
	var look := LineEdit.new()
	look.placeholder_text = "Filter nodes"
	look.custom_minimum_size.y = 29
	look.add_theme_stylebox_override("normal",_style(BASE,RULE,3,6,4))
	look.add_theme_stylebox_override("focus",_style(BASE,ACCENT,3,6,4))
	look.text_changed.connect(func(t): filter_text=t; _populate_tree())
	col.add_child(_margin(look,11,11,5,7))
	tree = Tree.new()
	tree.hide_root = true
	tree.columns = 1
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.add_theme_stylebox_override("panel",_flat(DOCK))
	tree.add_theme_stylebox_override("selected",_style(Color("#3B332D"),Color("#554237"),2,6,3))
	tree.add_theme_stylebox_override("selected_focus",_style(Color("#3B332D"),Color("#725039"),2,6,3))
	tree.add_theme_color_override("font_color",INK)
	tree.add_theme_color_override("font_selected_color",Color("#F2CCAB"))
	tree.add_theme_constant_override("v_separation",9)
	tree.add_theme_constant_override("h_separation",7)
	tree.add_theme_constant_override("item_margin",12)
	tree.item_selected.connect(_tree_selected)
	col.add_child(_margin(tree,5,5,0,0,true))
	col.add_child(_rule())
	var note := _v(5)
	note.add_child(_label("SCENE SOURCE",MUTED,10,true,true))
	note.add_child(_label("Relay assembly",INK,13,true))
	note.add_child(_label("Procedural native 3D scene",MUTED,10))
	col.add_child(_margin(note,12,10,12,16))

func _viewport(main: VBoxContainer) -> void:
	var tabs := _surface(DOCK,40)
	main.add_child(tabs)
	var tabrow := _h(5)
	tabs.add_child(_margin(tabrow,10,10,0,0))
	var scene_tab := _btn("◧  Relay Lab","Frame the relay assembly",_frame)
	scene_tab.toggle_mode = true
	scene_tab.set_pressed_no_signal(true)
	tabrow.add_child(scene_tab)
	tabrow.add_child(_stretch())
	tabrow.add_child(_label("SCENE  /  01",MUTED,10,false,true))
	main.add_child(_rule())
	var toolbox := _surface(BASE,41)
	main.add_child(toolbox)
	var tools := _h(4)
	toolbox.add_child(_margin(tools,10,10,0,0))
	for data in [["Select","Q"],["Move","W"],["Rotate","E"],["Scale","R"]]:
		var name := String(data[0])
		var b := _btn(name, name+"  ["+String(data[1])+"]", func(): _tool(name))
		b.toggle_mode = true
		tool_buttons[name] = b
		tools.add_child(b)
	tool_buttons[mode].set_pressed_no_signal(true)
	tools.add_child(_rule(RULE,true))
	tools.add_child(_btn("Frame","Reset framing  [F]",_frame))
	tools.add_child(_stretch())
	grid_toggle = _btn("Grid","Show or hide viewport reference grid")
	grid_toggle.toggle_mode = true
	grid_toggle.set_pressed_no_signal(true)
	grid_toggle.toggled.connect(func(v): lab.floor_grid.visible=v; _status("Grid visible" if v else "Grid hidden"))
	tools.add_child(grid_toggle)
	projection = _btn("Perspective","Switch perspective and orthographic projection",_projection)
	projection.custom_minimum_size.x = 96
	tools.add_child(projection)
	main.add_child(_rule())
	stage = Control.new()
	stage.custom_minimum_size = Vector2(400,330)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(stage)
	viewport_shell = SubViewportContainer.new()
	viewport_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_shell.stretch = true
	viewport_shell.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.add_child(viewport_shell)
	visual = SubViewport.new()
	visual.own_world_3d = true
	visual.msaa_3d = Viewport.MSAA_4X
	visual.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_shell.add_child(visual)
	lab = Scene.new()
	visual.add_child(lab)
	viewport_shell.gui_input.connect(_view_input)
	var overlay := _h(7)
	overlay.position = Vector2(15,13)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(overlay)
	var badge := _pill("PERSPECTIVE",true)
	projection_label=badge.get_child(0) as Label
	overlay.add_child(badge)
	view_label = _label("RELAY LAB  /  01",SOFT,10,false,true)
	view_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(view_label)
	var legend := _h(8)
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(legend)
	legend.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	legend.position = Vector2(14,stage.size.y-36)
	stage.resized.connect(func(): legend.position=Vector2(14,stage.size.y-36))
	legend.add_child(_pill("RMB  Orbit",false))
	legend.add_child(_pill("Wheel  Zoom",false))
	var axis := _label("▲ Y  ·  X / Z",ACCENT,11,true,true)
	axis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(axis)
	stage.resized.connect(func(): axis.position=Vector2(stage.size.x-108,stage.size.y-31))

func _right(row: HBoxContainer) -> void:
	var shell := _surface(DOCK)
	shell.custom_minimum_size.x = 285
	row.add_child(shell)
	var col := _v(0)
	shell.add_child(col)
	_heading(col,"INSPECTOR","02")
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(sc)
	inspector = _v(0)
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(inspector)
	col.add_child(_rule())
	var tail := _h(6)
	tail.add_child(_label("●",ACCENT,9))
	tail.add_child(_label("Preview changes are not saved",MUTED,10))
	col.add_child(_margin(tail,12,10,10,10))

func _assets(main: VBoxContainer) -> void:
	main.add_child(_rule(Color("#111315")))
	var panel := _surface(DOCK,160)
	main.add_child(panel)
	var col := _v(0)
	panel.add_child(col)
	var bar := _h(4)
	col.add_child(_margin(bar,10,10,4,4))
	bar.add_child(_label("ASSETS",INK,11,true,true))
	bar.add_child(_rule(RULE,true))
	for name in ["Scene","Materials","Reference"]:
		var b := _btn(name, "Browse "+name+" assets", func(): _folder(name))
		b.toggle_mode = true
		file_tabs[name] = b
		bar.add_child(b)
	bar.add_child(_stretch())
	breadcrumb = _label("",MUTED,10,false,true)
	bar.add_child(breadcrumb)
	col.add_child(_rule())
	tray = _h(8)
	col.add_child(_margin(tray,10,10,9,8))
	_folder("Scene")

func _folder(name: String) -> void:
	if not is_instance_valid(tray): return
	active_folder = name
	for k in file_tabs: file_tabs[k].set_pressed_no_signal(k==name)
	breadcrumb.text = "res://studio/"+name.to_lower()
	for it in tray.get_children():
		tray.remove_child(it)
		it.queue_free()
	match name:
		"Scene":
			for a in [["Intake Turbine","mesh group","◎"],["Relay Housing","mesh group","▤"],["Control Terminal","mesh group","▣"],["Exhaust Assembly","mesh group","▦"]]:
				var key := String(a[0])
				tray.add_child(_tile(key,String(a[1]),String(a[2]),func(): _select(key,true)))
		"Materials":
			for a in [["Copper","#D9A16C"],["Porcelain","#A1A5A1"],["Graphite","#272D31"],["Alloy","#808584"]]:
				var key := String(a[0])
				tray.add_child(_tile(key,"scene material","■",func(): _material_details(key),Color(a[1])))
		"Reference":
			for a in [["Relay Lab","frame full scene","◇"],["Foundation","base dimensions","▱"],["Markings","surface labels","⊞"]]:
				var key := String(a[0])
				tray.add_child(_tile(key,String(a[1]),String(a[2]),func(): _frame() if key=="Relay Lab" else _select(key,true)))

func _tile(name: String, caption: String, glyph: String, cb: Callable, color := ACCENT) -> Button:
	var b := _btn("", "Open "+name, cb)
	b.custom_minimum_size = Vector2(112,87)
	b.add_theme_stylebox_override("normal",_style(RAISED,RULE,3,7,5))
	var v := _v(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top=9
	v.offset_left=10
	v.offset_right=-6
	var icon := _label(glyph,color,24)
	icon.custom_minimum_size.y=30
	v.add_child(icon)
	v.add_child(_label(name,INK,11,true))
	v.add_child(_label(caption,MUTED,10))
	return b

func _populate_tree() -> void:
	if not is_instance_valid(tree) or not is_instance_valid(lab): return
	tree.clear()
	list_items.clear()
	var hidden_root := tree.create_item()
	var root := tree.create_item(hidden_root)
	root.set_text(0,"◇  Relay Lab")
	root.set_custom_color(0,INK)
	root.set_selectable(0,false)
	var groups := [
		["Foundation","▱"],["Relay Housing","▤"],["Intake Turbine","◎"],
		["Control Terminal","▣"],["Exhaust Assembly","▦"],
		["Coolant Manifold","▥"],["Markings","⊞"],["Grid","·"]]
	for pair in groups:
		var key := String(pair[0])
		if not filter_text.is_empty() and not key.to_lower().contains(filter_text.to_lower()): continue
		var item := tree.create_item(root)
		item.set_text(0,String(pair[1])+"   "+key)
		item.set_metadata(0,key)
		list_items[key]=item
		if key==selection_name: item.select(0)

func _tree_selected() -> void:
	var item := tree.get_selected()
	if item and item.get_metadata(0) != null:
		_select(String(item.get_metadata(0)))

func _select(key: String, from_tray := false) -> void:
	if not lab.registry.has(key): return
	selection_name = key
	selection = lab.registry[key]
	if list_items.is_empty():
		_populate_tree()
	if from_tray and list_items.has(key):
		list_items[key].select(0)
	_draw_inspector()
	lab.mark(selection,show_guides)
	_status(key+" selected")

func _draw_inspector() -> void:
	for it in inspector.get_children():
		inspector.remove_child(it)
		it.queue_free()
	var hero := _v(5)
	hero.add_child(_label(String(lab.names[selection_name]).to_upper(),ACCENT,9,true,true))
	hero.add_child(_label(selection_name,INK,19,true))
	hero.add_child(_label("Relay Lab  /  "+selection.name,SOFT,10))
	inspector.add_child(_margin(hero,12,10,14,15))
	inspector.add_child(_rule())
	var content := _v(7)
	var transform_heading := _h()
	transform_heading.add_child(_label("Transform",INK,12,true))
	transform_heading.add_child(_stretch())
	transform_heading.add_child(_label("LOCAL",MUTED,9,true,true))
	content.add_child(transform_heading)
	for field in ["Position","Rotation","Scale"]:
		content.add_child(_label(field,SOFT,10))
		var control := _h(4)
		var values: Vector3 = selection.position if field=="Position" else selection.rotation_degrees if field=="Rotation" else selection.scale
		for i in range(3):
			var n := i
			var box := SpinBox.new()
			box.min_value = .05 if field=="Scale" else -720.0
			box.max_value = 720.0
			box.step = .05 if field!="Rotation" else 1.0
			box.value = values[i]
			box.prefix = ["X","Y","Z"][i]
			box.custom_minimum_size.x = 78
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.get_line_edit().add_theme_stylebox_override("normal",_style(BASE,RULE,3,4,3))
			box.get_line_edit().add_theme_stylebox_override("focus",_style(BASE,ACCENT,3,4,3))
			box.value_changed.connect(func(v): _set_axis(field,n,v))
			control.add_child(box)
		content.add_child(control)
	inspector.add_child(_margin(content,12,12,12,14))
	inspector.add_child(_rule())
	if selection_name == "Intake Turbine":
		var material_panel := _v(9)
		material_panel.add_child(_label("Surface materials",INK,12,true))
		for key in ["Copper","Alloy","Glass Black"]:
			var m: StandardMaterial3D = lab.material_catalog[key]
			var matrow := _h(7)
			var swatch := ColorRect.new()
			swatch.color=m.albedo_color
			swatch.custom_minimum_size = Vector2(18,18)
			matrow.add_child(swatch)
			var b := _btn(key,"Inspect "+key,func(): _material_details(key))
			b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			matrow.add_child(b)
			material_panel.add_child(matrow)
		inspector.add_child(_margin(material_panel,12,12,12,14))
		inspector.add_child(_rule())
	var vis := CheckButton.new()
	vis.text = "Visible in viewport"
	vis.button_pressed = selection.visible
	vis.toggled.connect(func(v): selection.visible=v; _status("Visibility updated"))
	inspector.add_child(_margin(vis,11,11,8,8))

func _material_details(key: String) -> void:
	for it in inspector.get_children():
		inspector.remove_child(it)
		it.queue_free()
	var m: StandardMaterial3D = lab.material_catalog[key]
	var content := _v(11)
	content.add_child(_label("STANDARD MATERIAL 3D",ACCENT,9,true,true))
	content.add_child(_label(key,INK,19,true))
	var swatch := ColorRect.new()
	swatch.color=m.albedo_color
	swatch.custom_minimum_size.y=48
	content.add_child(swatch)
	content.add_child(_rule())
	content.add_child(_label("Roughness",SOFT,11))
	var rough := HSlider.new()
	rough.min_value=0
	rough.max_value=1
	rough.step=.01
	rough.value=m.roughness
	rough.value_changed.connect(func(v): m.roughness=v; _status(key+" roughness "+str(snappedf(v,.01))))
	content.add_child(rough)
	content.add_child(_label("Metallic",SOFT,11))
	var metal := HSlider.new()
	metal.min_value=0
	metal.max_value=1
	metal.step=.01
	metal.value=m.metallic
	metal.value_changed.connect(func(v): m.metallic=v; _status(key+" metallic "+str(snappedf(v,.01))))
	content.add_child(metal)
	content.add_child(_btn("Back to node", "Show selected scene node",_draw_inspector))
	inspector.add_child(_margin(content,12,12,15,10))
	_status(key+" material selected")

func _set_axis(field: String, axis: int, value: float) -> void:
	if not is_instance_valid(selection): return
	var v: Vector3 = selection.position if field=="Position" else selection.rotation_degrees if field=="Rotation" else selection.scale
	v[axis] = value
	if field=="Position": selection.position=v
	elif field=="Rotation": selection.rotation_degrees=v
	else: selection.scale=v
	lab.mark(selection,show_guides)
	_status(selection_name+" · "+field.to_lower()+" updated")

func _tool(next: String) -> void:
	mode=next
	show_guides=mode!="Select"
	for k in tool_buttons: tool_buttons[k].set_pressed_no_signal(k==mode)
	lab.mark(selection,show_guides)
	_status(mode+" tool · drag in viewport or edit in Inspector" if show_guides else "Selection tool")

func _preview(on: bool) -> void:
	running=on
	lab.animation_on=on
	play_toggle.text="Stop Preview" if on else "Preview"
	_status("Turbine animation playing" if on else "Preview stopped")

func _frame() -> void:
	lab.orbit=.73
	lab.elevation=.36
	lab.distance=15
	lab.refresh_camera()
	_status("Scene framed")

func _projection() -> void:
	lab.ortho = not lab.ortho
	projection.text = "Orthographic" if lab.ortho else "Perspective"
	projection_label.text=projection.text.to_upper()
	lab.refresh_camera()
	_status(projection.text+" projection")

func _reset() -> void:
	get_tree().reload_current_scene()

func _view_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP or event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			lab.distance=clampf(lab.distance + (-1.0 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0),5.5,32)
			lab.refresh_camera()
			viewport_shell.accept_event()
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT != 0:
			lab.orbit -= event.relative.x*.009
			lab.elevation=clampf(lab.elevation + event.relative.y*.009,.035,1.36)
			lab.refresh_camera()
		elif event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0 and show_guides and is_instance_valid(selection):
			var x: float = event.relative.x
			var y: float = event.relative.y
			if mode=="Move": selection.position+=Vector3(x*.012,-y*.01,0)
			elif mode=="Rotate": selection.rotation_degrees.y+=x*.45
			elif mode=="Scale": selection.scale=(selection.scale*clampf(1.0-y*.009,.75,1.25)).clamp(Vector3.ONE*.05,Vector3.ONE*20)
			lab.mark(selection,true)
		if event.button_mask != 0: viewport_shell.accept_event()
	if event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT and show_guides:
		_draw_inspector()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q: _tool("Select")
			KEY_W: _tool("Move")
			KEY_E: _tool("Rotate")
			KEY_R: _tool("Scale")
			KEY_F: _frame()
			KEY_G: grid_toggle.button_pressed=not grid_toggle.button_pressed

func _status(message: String) -> void:
	if is_instance_valid(status_line): status_line.text=message

func _heading(col: VBoxContainer, text: String, index: String) -> void:
	var row := _h(8)
	row.add_child(_label(text,INK,10,true,true))
	row.add_child(_stretch())
	row.add_child(_label(index,MUTED,10,false,true))
	col.add_child(_margin(row,12,11,10,10))
	col.add_child(_rule())

func _btn(title: String, help: String, f := Callable()) -> Button:
	var b := Button.new()
	b.text=title
	b.tooltip_text=help
	b.custom_minimum_size.y=31
	b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	b.add_theme_color_override("font_color",SOFT)
	b.add_theme_color_override("font_hover_color",INK)
	b.add_theme_color_override("font_pressed_color",ACCENT)
	b.add_theme_color_override("font_hover_pressed_color",ACCENT)
	b.add_theme_stylebox_override("normal",_style(Color(0,0,0,0),Color(0,0,0,0),3,8,4))
	b.add_theme_stylebox_override("hover",_style(RAISED,RULE,3,8,4))
	b.add_theme_stylebox_override("pressed",_style(Color("#352C26"),Color("#604A39"),3,8,4))
	b.add_theme_stylebox_override("focus",_focus())
	if not f.is_null(): b.pressed.connect(f)
	return b

func _pill(text: String, primary: bool) -> PanelContainer:
	var box := PanelContainer.new()
	box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel",_style(Color("#191B1Ded"),Color("#47423D"),3,6,4))
	box.add_child(_label(text,INK if primary else SOFT,10,false,true))
	return box

func _label(text: String, color: Color, px: int, bold := false, use_mono := false) -> Label:
	var l := Label.new()
	l.text=text
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color",color)
	l.add_theme_font_size_override("font_size",px)
	l.add_theme_font_override("font",mono if use_mono else strong if bold else font)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func _margin(child: Control, left: int, right: int, top: int, bottom: int, expand := false) -> MarginContainer:
	var box := MarginContainer.new()
	box.add_theme_constant_override("margin_left",left)
	box.add_theme_constant_override("margin_right",right)
	box.add_theme_constant_override("margin_top",top)
	box.add_theme_constant_override("margin_bottom",bottom)
	if expand: box.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(child)
	return box

func _flat(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color=color
	return box

func _style(color: Color, border: Color, radius: int, mx: int, my: int) -> StyleBoxFlat:
	var box := _flat(color)
	box.set_border_width_all(1)
	box.border_color=border
	box.set_corner_radius_all(radius)
	box.content_margin_left=mx
	box.content_margin_right=mx
	box.content_margin_top=my
	box.content_margin_bottom=my
	return box

func _focus() -> StyleBoxFlat:
	var box := _style(Color.TRANSPARENT,ACCENT,3,0,0)
	box.draw_center=false
	return box

func _surface(color: Color, height := 0) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_flat(color))
	panel.custom_minimum_size.y=height
	return panel

func _rule(color := RULE, vertical := false) -> ColorRect:
	var line := ColorRect.new()
	line.color=color
	line.custom_minimum_size=Vector2(1,0) if vertical else Vector2(0,1)
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return line

func _v(spacing := 0) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation",spacing)
	return c

func _h(spacing := 5) -> HBoxContainer:
	var c := HBoxContainer.new()
	c.add_theme_constant_override("separation",spacing)
	return c

func _stretch() -> Control:
	var c := Control.new()
	c.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	c.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return c

func _check() -> void:
	await get_tree().process_frame
	if lab.registry.size()!=8 or selection_name!="Intake Turbine":
		push_error("Missing scene setup")
		get_tree().quit(1)
		return
	var old_x := selection.position.x
	tool_buttons["Move"].pressed.emit()
	_set_axis("Position",0,old_x+.5)
	var moved := is_equal_approx(selection.position.x,old_x+.5) and mode=="Move"
	projection.pressed.emit()
	var ortho_test: bool = lab.camera.projection==Camera3D.PROJECTION_ORTHOGONAL and projection_label.text=="ORTHOGRAPHIC"
	file_tabs["Materials"].pressed.emit()
	(tray.get_child(0) as Button).pressed.emit()
	var visible_cards := tray.get_child_count()==4 and status_line.text=="Copper material selected"
	play_toggle.set_pressed_no_signal(true)
	play_toggle.toggled.emit(true)
	var anim_test: bool=lab.animation_on
	grid_toggle.set_pressed_no_signal(false)
	grid_toggle.toggled.emit(false)
	var grid_test: bool=not lab.floor_grid.visible
	print("AK_STUDIO_LAYOUT ",get_viewport_rect().size," stage ",stage.size," subviewport ",visual.size)
	_filter_check(moved and ortho_test and visible_cards and anim_test and grid_test and stage.size.x>400 and stage.size.y>330)

func _filter_check(ok: bool) -> void:
	filter_text="Terminal"
	_populate_tree()
	ok=ok and list_items.size()==1 and list_items.has("Control Terminal")
	if ok: print("AK_STUDIO_FUNCTIONAL_CHECK_OK")
	else: push_error("Studio functional check failed")
	get_tree().quit(0 if ok else 1)

func _capture(out: String) -> void:
	for i in range(10): await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var code := image.save_png(out)
	if code!=OK: push_error("Capture failed: "+error_string(code))
	else: print("AK_STUDIO_CAPTURE_OK "+out)
	get_tree().quit(0 if code==OK else 1)
