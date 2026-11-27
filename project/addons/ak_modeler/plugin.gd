@tool
extends EditorPlugin
# AK Modeler dock (stage 2.1). Status: EXPERIMENTAL. The dock loads and creates primitives;
# interactive viewport picking is PLANNED. The mesh operations live in ak_mesh_ops.gd and are tested.

var dock: VBoxContainer

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "AK Modeler"
	for spec in [["Add Box", 0], ["Add Cylinder", 1], ["Add Sphere", 2]]:
		var b := Button.new()
		b.text = spec[0]
		b.pressed.connect(_add.bind(spec[1]))
		dock.add_child(b)
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()

func _add(kind: int) -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var pm: PrimitiveMesh = [BoxMesh.new(), CylinderMesh.new(), SphereMesh.new()][kind]
	var ops := AKMeshOps.from_primitive(pm)
	var mi := MeshInstance3D.new()
	mi.mesh = ops.to_array_mesh()
	mi.name = "AKModel"
	root.add_child(mi)
	mi.owner = root
