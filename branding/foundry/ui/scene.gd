# SPDX-License-Identifier: MIT
extends Node3D

var registry: Dictionary = {}
var names: Dictionary = {}
var camera: Camera3D
var floor_grid: Node3D
var pick_root: Node3D
var orbit: float = 0.73
var elevation: float = 0.36
var distance: float = 15.0
var ortho := false
var target := Vector3(0, 1.28, 0)
var rotation_group: Node3D
var gizmo: Node3D
var animation_on := false
var material_catalog: Dictionary = {}

func _ready() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#25282B")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#C5CACE")
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	_light(Vector3(-46, -34, 0), Color("#FFF1DD"), 1.20, true)
	_light(Vector3(-29, 144, 0), Color("#CCDAE5"), 0.65, false)
	camera = Camera3D.new()
	camera.fov = 35
	camera.far = 200
	add_child(camera)
	camera.current = true
	refresh_camera()
	var concrete := mat("Porcelain", "#A1A5A1", 0.01, 0.85)
	var panel := mat("Graphite", "#272D31", 0.35, 0.53)
	var panel_side := mat("Carbon", "#141719", 0.21, 0.62)
	var seam := mat("Alloy", "#808584", 0.58, 0.36)
	var copper := mat("Copper", "#D9A16C", 0.50, 0.42)
	var dark_copper := mat("Burnished", "#845736", 0.49, 0.48)
	var glass := mat("Glass Black", "#151D20", 0.28, 0.17)
	var lamp := mat("Pilot Light", "#F8BA73", 0.18, 0.46, true)
	var pad := mat("Ground", "#191C1E", 0.0, 0.93)
	_box(self, Vector3(420,0.08,420), Vector3(0,-0.12,0), pad)
	floor_grid = _group(self, "Grid", "editor reference")
	var fine := mat("Fine Grid", "#3C4145", 0.0, 1.0, false, true)
	var heavy := mat("Major Grid", "#4E5559", 0.0, 1.0, false, true)
	for i in range(-20,21):
		var m := heavy if i % 5 == 0 else fine
		var width := 0.016 if i % 5 == 0 else 0.009
		_box(floor_grid, Vector3(width,.007,40), Vector3(i,-.071,0),m)
		_box(floor_grid, Vector3(40,.006,width), Vector3(0,-.070,i),m)
	var foundation := _group(self, "Foundation", "mesh group")
	_box(foundation, Vector3(6.3,.21,4.3),Vector3(0,.05,0),panel_side)
	_box(foundation, Vector3(6.08,.28,4.06),Vector3(0,.24,0),concrete)
	_box(foundation, Vector3(6.00,.06,3.98),Vector3(0,.41,0),seam)
	_box(foundation, Vector3(5.95,.08,3.94),Vector3(0,.47,0),panel)
	for x in [-2.77,2.77]:
		for z in [-1.78,1.78]:
			_box(foundation,Vector3(.21,.06,.21),Vector3(x,.53,z),copper)
	var enclosure := _group(self, "Relay Housing", "mesh group")
	enclosure.position.y = .5
	_box(enclosure,Vector3(4.7,2.42,2.15),Vector3(-.25,1.23,-.12),panel)
	_box(enclosure,Vector3(4.72,.08,2.17),Vector3(-.25,2.49,-.12),seam)
	_box(enclosure,Vector3(4.69,.10,2.12),Vector3(-.25,2.57,-.12),panel_side)
	_box(enclosure,Vector3(4.67,.09,2.08),Vector3(-.25,.09,-.12),concrete)
	for i in range(17):
		var x := -2.45 + i*.27
		_box(enclosure,Vector3(.115,2.13,.105),Vector3(x,1.25,.985),panel_side)
		_box(enclosure,Vector3(.032,2.06,.037),Vector3(x-.015,1.25,1.052),seam)
	for i in range(8):
		var z := -.96 + i*.25
		_box(enclosure,Vector3(.10,2.11,.115),Vector3(2.154,1.27,z),panel_side)
	var terminal := _group(self, "Control Terminal", "mesh group")
	terminal.position = Vector3(.93,.54,1.12)
	_box(terminal,Vector3(.86,1.4,.26),Vector3(0,.80,0),concrete)
	_box(terminal,Vector3(.69,1.24,.035),Vector3(0,.8,.154),panel_side)
	_box(terminal,Vector3(.49,.31,.016),Vector3(0,1.14,.178),glass)
	_box(terminal,Vector3(.35,.025,.012),Vector3(0,1.18,.189),lamp)
	_box(terminal,Vector3(.24,.017,.012),Vector3(-.055,1.105,.189),seam)
	for i in range(4):
		_box(terminal,Vector3(.055,.045,.021),Vector3(-.17+i*.112,.77,.185),copper if i==0 else seam)
	for i in range(5):
		_box(terminal,Vector3(.35,.015,.015),Vector3(0,.29+i*.041,.183),seam)
	_label3(terminal, "07 / RELAY", Vector3(0,.53,.193), "#F4E4D1", .0012, 30)
	var duct := _group(self, "Exhaust Assembly", "mesh group")
	duct.position = Vector3(-.7,3.15,-.10)
	_box(duct,Vector3(1.52,.19,1.32),Vector3(0,0,0),panel_side)
	for i in range(3):
		var x := -.48+i*.48
		_cyl(duct,.17,.39,Vector3(x,.23,-.14),dark_copper)
		_cyl(duct,.20,.055,Vector3(x,.43,-.14),copper)
		_cyl(duct,.143,.021,Vector3(x,.463,-.14),panel_side)
		_cyl(duct,.065,.43,Vector3(x,.23,.27),seam)
	var frame := _group(self, "Intake Turbine", "mesh group")
	frame.position = Vector3(-1.57,1.80,1.13)
	var face := Node3D.new()
	face.rotation.x = PI / 2
	frame.add_child(face)
	_cyl(face,.79,.27,Vector3(0,0,0),dark_copper)
	_cyl(face,.744,.26,Vector3(0,-.036,0),copper)
	_cyl(face,.665,.25,Vector3(0,-.072,0),panel_side)
	_cyl(face,.56,.08,Vector3(0,-.205,0),glass)
	rotation_group = Node3D.new()
	rotation_group.position.z = .225
	frame.add_child(rotation_group)
	for i in range(12):
		var blade_pivot := Node3D.new()
		rotation_group.add_child(blade_pivot)
		blade_pivot.rotation.z = TAU * i / 12.0
		var blade := _box(blade_pivot,Vector3(.14,.34,.067),Vector3(0,.315,0),seam)
		blade.rotation.z = -.31
	var hub := Node3D.new()
	hub.rotation.x = PI / 2
	hub.position.z = .27
	frame.add_child(hub)
	_cyl(hub,.165,.115,Vector3.ZERO,copper)
	_cyl(hub,.078,.12,Vector3(0,-.018,0),panel_side)
	for i in range(12):
		var angle := TAU*i/12
		_box(frame,Vector3(.035,.035,.035),Vector3(cos(angle)*.705,sin(angle)*.705,.169),seam)
	var markings := _group(self, "Markings", "surface detail")
	_label3(markings, "A K   /   0 7", Vector3(-.32,2.85,1.043), "#EAE3D7", .0024, 34)
	_label3(markings, "MECHANICAL REFERENCE", Vector3(-.36,2.70,1.044), "#D9A16C", .0015, 26)
	for i in range(8):
		_box(markings,Vector3(.093,.013,.29),Vector3(1.9+i*.17,.520,1.75),copper)
	var pipe := _group(self, "Coolant Manifold", "mesh group")
	pipe.position = Vector3(2.35,.58,.69)
	for i in range(2):
		var x := i*.34
		_cyl(pipe,.087,1.40,Vector3(x,.91,0),copper)
		_cyl(pipe,.12,.10,Vector3(x,.35,0),dark_copper)
		_cyl(pipe,.12,.10,Vector3(x,1.50,0),dark_copper)
		_cyl(pipe,.13,.10,Vector3(x,.12,0),seam)
	gizmo = Node3D.new()
	add_child(gizmo)
	gizmo.hide()

func _process(delta: float) -> void:
	if animation_on and is_instance_valid(rotation_group):
		rotation_group.rotation.z -= delta * 1.8

func refresh_camera() -> void:
	if not is_instance_valid(camera): return
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if ortho else Camera3D.PROJECTION_PERSPECTIVE
	camera.size = distance * .66
	camera.position = target + Vector3(sin(orbit)*cos(elevation), sin(elevation), cos(orbit)*cos(elevation))*distance
	camera.look_at(target)

func mark(node: Node3D, active: bool) -> void:
	if not is_instance_valid(gizmo): return
	gizmo.visible = active and is_instance_valid(node)
	if not gizmo.visible: return
	for child in gizmo.get_children():
		gizmo.remove_child(child)
		child.queue_free()
	gizmo.position = node.global_position
	var m := mat("Axis", "#D9A16C", 0, 1, false, true)
	var size := .85
	_box(gizmo,Vector3(size,.012,.012),Vector3(size*.5,0,0),m)
	_box(gizmo,Vector3(.012,size,.012),Vector3(0,size*.5,0),m)
	_box(gizmo,Vector3(.012,.012,size),Vector3(0,0,size*.5),m)

func _group(parent: Node3D, key: String, kind: String) -> Node3D:
	var group := Node3D.new()
	group.name = key.validate_node_name().replace(" ", "_")
	parent.add_child(group)
	registry[key] = group
	names[key] = kind
	return group

func mat(label: String, hex: String, metallic: float, rough: float, lit := false, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = label
	m.albedo_color = Color(hex)
	m.metallic = metallic
	m.roughness = rough
	if lit:
		m.emission_enabled = true
		m.emission = Color(hex)
		m.emission_energy_multiplier = .29
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_catalog[label] = m
	return m

func _box(p: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(p, mesh, pos, material)

func _cyl(p: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 40
	mesh.rings = 1
	return _mesh(p, mesh, pos, material)

func _mesh(p: Node3D, mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material
	p.add_child(instance)
	return instance

func _light(direction: Vector3, hue: Color, energy: float, shadows: bool) -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = direction
	light.light_color = hue
	light.light_energy = energy
	light.shadow_enabled = shadows
	add_child(light)

func _label3(parent: Node3D, caption: String, pos: Vector3, hue: String, pixel_size: float, font_size: int) -> void:
	var label := Label3D.new()
	label.text = caption
	label.position = pos
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = Color(hue)
	label.outline_size = 0
	parent.add_child(label)
