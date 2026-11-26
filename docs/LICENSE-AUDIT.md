# Licence audit (Phase 0)

Sources inspected on 2026-11-26. Versions: Godot 4.7.2-stable, O3DE 2610.0, Blender v5.3.0 (git tags on the official repos).

| Component | Licence (verified from the repo's own files) | Use in AK Engine |
|---|---|---|
| Godot Engine 4.7.2 | MIT (`LICENSE.txt`, plus ~69 `thirdparty/` entries with own licences, listed in `COPYRIGHT.txt`) | Candidate runtime base. May be forked and modified. Must keep copyright notices and ship `COPYRIGHT.txt`. |
| O3DE 2610.0 | Apache-2.0 by default, MIT at your option (`LICENSE.txt`). Third-party parts separate (e.g. Qt under LGPL-3.0, see `LICENSE.txt`). | Source of rendering ideas and ported code (Atom, SkyAtmosphere, Terrain, Vegetation gems). Apache-2.0 code can be combined with MIT code; keep NOTICE and headers on ported files. Do not take Qt. |
| Blender v5.3.0 | GPL (`COPYING` points to `doc/license/GPL-license.txt`; no other licence offered). | Do NOT link or copy into the MIT runtime or editor. Use as a separate process (import/export via glTF/USD/FBX, scripted headless jobs). The Asset Studio can ship Blender as an optional, separately licensed download. |
| Godot asset library / store | Each asset has its own licence. | Per-asset check before any inclusion. Nothing included. |

## Distribution architecture that follows
1. AK Engine runtime and editor: MIT, built from original code plus MIT/Apache-2.0 upstream code. Exported games carry no GPL code.
2. Blender stays an external GPL tool. Its source is never merged. Complete modelling inside the editor is therefore a bridge, not a merge, unless AK chooses to license the whole editor GPL (open decision, see ARCHITECTURE).
3. Every imported file keeps its upstream header. `THIRD_PARTY_NOTICES.md` is generated per release (not yet implemented).

Not yet audited: the full dependency trees of O3DE (3p packages) and Blender (lib repo). Status: planned.
