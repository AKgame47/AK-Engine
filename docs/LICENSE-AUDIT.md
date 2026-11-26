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

## Decision update, 2026-11-27: AK Engine is GPL-3.0

AK chose to use Blender source code directly for in-engine modelling and animation, so the AK Engine repository is now GPL-3.0-only (see `LICENSE`). Verified: Blender source files carry `SPDX-License-Identifier: GPL-2.0-or-later` (checked on `editmesh_extrude.cc`), which can be combined into a GPL-3.0 work. Godot (MIT) and O3DE (Apache-2.0 or MIT) code can also be combined into a GPL-3.0 work; keep their headers.

Rules that follow:
1. Keep every upstream copyright and SPDX header on copied or ported files. Record the origin file and commit in `THIRD_PARTY_NOTICES.md` (not yet written).
2. Blender third-party libraries (its `lib` repo, e.g. OpenSubdiv, OpenVDB, Embree) have their own licences. Only take code authored by the Blender project unless that library is audited first. Not yet audited.
3. Do not take Qt (LGPL-3.0, separate terms) from O3DE.
4. Exported games (AK's decision, confirmed 2026-11-27): Blender-derived code stays EDITOR-ONLY. Exported games ship only the Godot MIT runtime plus AK runtime code, with no GPL code. Never put Blender-derived code in runtime modules or export templates.
5. The MIT statement in earlier sections of this file is superseded for new code by the GPL-3.0 decision above.
