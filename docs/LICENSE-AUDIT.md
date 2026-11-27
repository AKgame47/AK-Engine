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

## Status update, 2026-11-28 (M2): what AK Engine actually contains from each upstream

| Item | Fact | Licence effect |
|---|---|---|
| `project/addons/ak_modeler` (AKMeshOps) | Written for AK Engine. No code was copied from Blender or O3DE. Ops: subdivide, select, extrude, cutout, mirror_x, weld, cut_plane. | AK code under the repository's GPL-3.0. Not Blender-derived, so it needs no upstream header. If a Blender algorithm is ported later, add its SPDX header and an entry in `THIRD_PARTY_NOTICES.md`, and keep it editor-only. |
| O3DE in CI (`o3de-render-probe` and related workflows) | O3DE 2610.0 is fetched and built on the CI runner only. No O3DE source is committed to this repository. A CI-only patch to Atom's Vulkan allocator is applied to the CI checkout and is not stored here. | No O3DE code is redistributed by this repository yet. Apache-2.0 or MIT terms apply when code is ported. Qt is not used. |
| CC0 car (tevy.dev Mid-Engine Supercar v2) | Imported as an experiment. Authorship is unverified, only the publisher's CC0 claim exists (see `THIRD_PARTY_ASSETS.md`). | EXPERIMENTAL. Do not ship in a release until authorship is verified. |
| Godot 4.7.2 | Used as the runtime and built in CI. | MIT. Keep `COPYRIGHT.txt` and notices in any release. |

Still open: the dependency trees of O3DE (3p packages) and Blender (lib repo), and `THIRD_PARTY_NOTICES.md`. Qt (LGPL-3.0) stays out.

## O3DE 3p package inventory, 2026-11-28 (Linux x86_64, tag 2610.0)

Source: `cmake/3rdParty/Platform/Linux/BuiltInPackages_linux_x86_64.cmake` at tag 2610.0 (`ly_associate_package` entries). Only the package names and versions are verified here. Per-package licences are NOT audited yet: O3DE says they are logged in its 3P repository (https://github.com/o3de/3p-package-source) with SPDX tags, and its `LICENSE.txt` names only Qt as copyleft.

Packages: RapidJSON 1.1.0, RapidXML 1.13, pybind11 2.10.0, glad 2.0.0-beta, xxhash 0.7.4, cityhash 1.1, expat 2.4.2, AWS Native SDK 1.11.288, tiff 4.2.0.15, freetype 2.11.1, Lua 5.4.4, mcpp 2.7.2_az.2, mikkelsen 1.0.0.4, googlebenchmark 1.7.0, qt 6.10.2, png 1.6.37, libsamplerate 0.2.1, openimageio-opencolorio 2.3.17, OpenEXR 3.1.3, OpenSSL 1.1.1t, DirectXShaderCompiler (Dxc) 1.8.2505.1, SPIRV-Cross 1.3.275.0, zlib 1.2.11, squish-ccr (deb557d), astc-encoder 3.2, ISPCTexComp (36b80aa), lz4 1.9.4, pyside6 6.10.2, SQLite 3.37.2, AWS IoT Device SDK C++ 1.15.2, Vulkan validation layers 1.2.198.

Rule that follows for AK Engine: take nothing from this list into a release without checking that package's own licence file first. Qt and PySide6 stay out (editor UI toolkit, separate terms). Blender `lib` repo tree: still not audited.

## Blender v5.3.0 in-tree licence scope, 2026-11-28

Verified from the tag `v5.3.0` of https://github.com/blender/blender :
- `doc/license/SPDX-license-identifiers.txt` lists the SPDX identifiers used in the source: Apache-2.0, BSD-2-Clause, BSD-3-Clause, BSL-1.0, GPL-2.0-or-later, GPL-3.0-or-later, LGPL-2.1-or-later, MIT, MPL-2.0, Zlib.
- `extern/` holds these bundled libraries (each has its own licence, not yet checked one by one): audaspace, binreloc, bullet2, cuew, curve_fit_nd, fast_float, gflags, glew-es, glog, gmock, gtest, hipew, json, mantaflow, md4c, nanosvg, quadriflow, rangetree, renderdoc, tinygltf, toml11, tracy_profiler, ufbx, volk, vulkan_memory_allocator, wcwidth, wintab, xdnd, xxhash.
- The separate `lib` repo (prebuilt libraries such as OpenSubdiv, OpenVDB, Embree) is NOT read yet.

Rule that follows: read the SPDX header of every Blender file before copying it (only `editmesh_extrude.cc` has been checked so far: GPL-2.0-or-later). GPL-2.0-or-later and GPL-3.0-or-later files can go into the GPL-3.0 AK Engine editor; a GPL-2.0-only file cannot. Anything under `extern/` or from `lib` needs its own licence read first, and a file with LGPL, MPL or another header keeps that header. Editor-only still applies.
