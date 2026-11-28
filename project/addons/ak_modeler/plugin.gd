@tool
extends EditorPlugin
# AK Modeler dock (stage 2.1). Status: EXPERIMENTAL and UNTESTED as a UI.
# The mesh operations in ak_mesh_ops.gd are tested headless (tools/modeler-test).
# This file wires them to dock buttons and to viewport click picking. No CI run has opened
# the editor UI yet, so treat every button below as untested until a display run proves it.

var dock: VBoxContainer
var target: MeshInstance3D
var ops: AKMeshOps
var selection := PackedInt32Array()
var status: Label
var amount: SpinBox

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "AK Modeler"
	status = Label.new()
	status.text = "No model selected"
	dock.add_child(status)
	amount = SpinBox.new()
	amount.min_value = 0.01
	amount.max_value = 10.0
	amount.step = 0.01
	amount.value = 0.25
	dock.add_child(amount)
	for spec in [["Add Box", "_add_box"], ["Add Cylinder", "_add_cyl"], ["Add Sphere", "_add_sph"],
			["Edit selected mesh", "_grab"], ["Subdivide", "_op_subdivide"], ["Extrude selection", "_op_extrude"],
			["Inset selection", "_op_inset"], ["Bevel face selection", "_op_bevel"], ["Mirror X", "_op_mirror"],
			["Weld", "_op_weld"], ["Clear selection", "_op_clear"]]:
		var b := Button.new()
		b.text = spec[0]
		b.pressed.connect(Callable(self, spec[1]))
		dock.add_child(b)
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()

func _handles(object: Object) -> bool:
	return object is MeshInstance3D

func _edit(object: Object) -> void:
	if object is MeshInstance3D:
		target = object

func _make(pm: PrimitiveMesh) -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		status.text = "Open a 3D scene first"
		return
	var o := AKMeshOps.from_primitive(pm)
	var mi := MeshInstance3D.new()
	mi.mesh = o.to_array_mesh()
	mi.name = "AKModel"
	root.add_child(mi)
	mi.owner = root
	target = mi
	ops = o
	selection = PackedInt32Array()
	_refresh()

func _add_box() -> void: _make(BoxMesh.new())
func _add_cyl() -> void: _make(CylinderMesh.new())
func _add_sph() -> void: _make(SphereMesh.new())

func _grab() -> void:
	# Rebuild the editable op mesh from the selected MeshInstance3D's first surface.
	if target == null or target.mesh == null:
		status.text = "Select a MeshInstance3D first"
		return
	var arr: Array = target.mesh.surface_get_arrays(0)
	var src: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx = arr[Mesh.ARRAY_INDEX]
	if idx == null or idx.size() == 0:
		status.text = "Mesh has no index buffer"
		return
	var o := AKMeshOps.new()
	var map := {}
	var remap := PackedInt32Array()
	for v in src:
		var key := Vector3i((v * 10000.0).round())
		if not map.has(key):
			map[key] = o.verts.size()
			o.verts.append(v)
		remap.append(map[key])
	for i in idx:
		o.tris.append(remap[i])
	ops = o
	selection = PackedInt32Array()
	_refresh()

func _refresh() -> void:
	if target != null and ops != null:
		target.mesh = ops.to_array_mesh()
		status.text = "%d tris, %d selected" % [ops.tri_count(), selection.size()]

func _need() -> bool:
	if ops == null or target == null:
		status.text = "Add or grab a mesh first"
		return false
	return true

func _op_subdivide() -> void:
	if _need():
		ops.subdivide()
		selection = PackedInt32Array()
		_refresh()

func _op_extrude() -> void:
	if _need() and selection.size() > 0:
		ops.extrude(selection, amount.value)
		_refresh()

func _op_inset() -> void:
	if _need() and selection.size() > 0:
		ops.region_inset(selection, clampf(amount.value, 0.0, 0.95))
		_refresh()

func _op_bevel() -> void:
	if _need() and selection.size() > 0:
		ops.bevel_face(selection, 0.25, amount.value * 0.4)
		_refresh()

func _op_mirror() -> void:
	if _need():
		ops.mirror_x()
		_refresh()

func _op_weld() -> void:
	if _need():
		ops.weld(0.0001)
		_refresh()

func _op_clear() -> void:
	selection = PackedInt32Array()
	if ops != null:
		_refresh()

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	# Left click picks the nearest triangle under the cursor (shift adds to the selection).
	if ops == null or target == null:
		return AFTER_GUI_INPUT_PASS
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.alt_pressed == false:
		var o: Vector3 = camera.project_ray_origin(event.position)
		var d: Vector3 = camera.project_ray_normal(event.position)
		var inv := target.global_transform.affine_inverse()
		var t := ops.pick_tri(inv * o, (inv.basis * d).normalized())
		if t >= 0:
			if not event.shift_pressed:
				selection = PackedInt32Array()
			if not selection.has(t):
				selection.append(t)
			status.text = "%d tris, %d selected" % [ops.tri_count(), selection.size()]
			return AFTER_GUI_INPUT_STOP
	return AFTER_GUI_INPUT_PASS
