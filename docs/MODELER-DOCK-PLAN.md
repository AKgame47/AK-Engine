# AK Modeler dock UI plan

Status: PLANNED. Nothing in this file is implemented or tested. The mesh ops in
`project/addons/ak_modeler/ak_mesh_ops.gd` are implemented and tested headless (modeler-test-run6, 23 CHECKs).

## Goal
Let a person drive the tested ops from the Godot editor, so the Phase 2 car and character are made with the engine's own tools.

## Pieces
1. Dock panel (`EditorPlugin.add_control_to_dock`): buttons for subdivide, extrude (distance field), inset (factor field), cut plane (axis + position), mirror X, weld (distance). Each button calls the matching AKMeshOps method on the selected MeshInstance3D.
2. Selection: `pick_tri` ray picking from the 3D viewport (`EditorPlugin._forward_3d_gui_input`), shift to add. Design in docs/MODELER-PICKING.md.
3. Overlay: draw selected triangles through `_forward_3d_draw_over_viewport`.
4. Undo: wrap every op in `EditorUndoRedoManager` with a mesh snapshot (verts + tris arrays) for undo.
5. Export: write the edited ArrayMesh as .tres and as glTF through Godot's exporter.

## Test plan
- Headless: ops already covered. Add a check that snapshot restore gives identical verts and tris.
- UI: not testable headless. Needs a CI run with a virtual display and a screenshot, or it stays UNTESTED and is labelled so.

## Not yet planned in detail
Full edge bevel (needs vertex splitting around the edge ends; `inset` is only the face step).
