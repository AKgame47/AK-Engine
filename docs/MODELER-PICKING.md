# Modeler viewport picking (design note)

Status: `AKMeshOps.pick_tri` (ray-triangle picking) is IMPLEMENTED and under headless test (see modeler-test). Viewport input, selection overlay and dock buttons are PLANNED and untested.

Goal: let the user click a triangle in the 3D viewport, then run the existing ops (extrude, delete, cut_plane) on the selection.

Plan
1. Ray from the editor camera through the mouse position (EditorPlugin `_forward_3d_gui_input`).
2. Transform the ray into the mesh's local space and test every triangle (Moller-Trumbore) in `AKMeshOps`. Add `pick_tri(origin, dir) -> int` returning the nearest hit or -1. Pure data, so it can be tested headless like the other ops.
3. Selection set as a `PackedInt32Array` of triangle ids, drawn as an overlay mesh in the viewport.
4. Dock buttons call `extrude`, `delete_tris`, `mirror_x`, `weld`, `cut_plane` on the selection or the whole mesh.

Test plan (headless): `pick_tri` on a box from outside along each axis returns the facing triangle; a ray that misses returns -1; nearest hit wins when two triangles overlap along the ray.

Risks: the dock UI cannot be tested headless. It needs a CI screenshot of the editor, which is not set up.
