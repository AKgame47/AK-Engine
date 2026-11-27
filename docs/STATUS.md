# Status (updated 2026-11-27, 05:30 IST)

Every "Implemented" row has a link to the CI run, release or file that shows it. Everything else is not done.

| Item | State | Evidence |
|---|---|---|
| Phase 0: source fetch, architecture ADR, licence audit | Implemented (docs). Full dependency-tree audit planned. | docs/ARCHITECTURE.md, docs/LICENSE-AUDIT.md |
| AK Core: ids, large-world offsets, frame stats, tests | Implemented, tests pass on Linux + Windows CI | Actions workflow "ci" |
| Upstream Godot 4.7.2 editor builds on free CI (Linux x86_64, raycast/Embree module disabled) | Implemented. Cold build 27m17s, cached about 3.5 min. | Actions runs 45796182937, 45804123055 |
| AK name patch (version string "AK Engine") | Implemented, name only. Binary file name is still godot.*; the editor UI itself is stock Godot, no AK theme, logo or splash applied. | docs/evidence/editor-run6.png |
| Real 3D render by the AK-named build (software OpenGL via llvmpipe, 1152x648) | Implemented, one frame, no performance data | docs/evidence/shot-run5.png |
| Editor window launch with screenshot (stock UI) | Implemented, one screenshot under xvfb | docs/evidence/editor-run6.png |
| Scripted car (benchmark v6) | Implemented, EXPERIMENTAL visuals: 14,352 triangles, 9 meshes, glTF write and re-import pass. Stylized, blocky seams, no textures. Scripted generation has reached its ceiling (v7 and v8 gave little). Not hyperreal. | https://github.com/AKgame47/AK-Engine/releases/tag/car-build-run8 |
| Scripted character v2 | Implemented, EXPERIMENTAL visuals: 8,968 triangles, 12 meshes, 1 walk Animation, glTF re-import pass. Mannequin-like, no skinning, no textures. | https://github.com/AKgame47/AK-Engine/releases/tag/character-build-run3 |
| CC0 car import (workflow proof, model by tevy.dev, NOT made by AK Engine) | Implemented. 23 meshes, 44,632 triangles imported after CI preprocessing (meshopt decode, dequantize, textures stripped). Untextured. CC0 is the publisher's claim, authorship unverified. | https://github.com/AKgame47/AK-Engine/releases/tag/car-import-run3 , docs/THIRD_PARTY_ASSETS.md |
| AK Core Godot module (classify_game, select_renderer) | Implemented and tested headless, 15 checks pass | https://github.com/AKgame47/AK-Engine/releases/tag/ak-module-test-run2 |
| AK Modeler plugin (stage 2.1): mesh ops (subdivide, select, extrude, cutout, mirror_x, weld, cut_plane) | Experimental. Headless test modeler-test-run4 PASSED (17 CHECKs incl. mirror_x, weld, cut_plane). Dock UI untested; viewport picking planned. | project/addons/ak_modeler , workflow modeler-test |
| O3DE integration | EXPERIMENTAL probe only. Release 2610.0 pinned. M3/M4 done in CI: configure and build of the game launcher passed. Atom (Vulkan, software llvmpipe) starts and draws its HUD (render-probe run 8). With a CI-only patch to Atom's Vulkan allocator, LoadLevel of a stock test level draws a ground grid and grey blocks, then stalls (runs 13 to 15). Run 17 stack samples show the stall is the llvmpipe software GPU busy rendering (engine threads idle, no deadlock). A lit scene needs a real GPU or much more time. No lit scene yet, so M5 is NOT reached. O3DE probing capped here (release o3de-render-probe-run17). Run 18 tried +r_width 640 +r_height 360: the setting was accepted but Atom still ran at 1920x1080 (HUD), so the speed test is INCONCLUSIVE (release o3de-render-probe-run18). No AK backend. | docs/O3DE-INTEGRATION.md |
| Linux export of the demo project | Implemented. Exported binary starts under xvfb (headless smoke run only). Not tested on real hardware, unsigned. | Run 45819090853, release demo-linux-run2 |
| Shader library (water, sky, foliage) and sample glTF props | Implemented, renders in CI (software rendering, stylized, low-poly, not realistic). No GPU or mobile performance data. | Run 45820727265, release shader-check-run1 |
| AK Studio UI | UI concept only: a standalone Godot app showing a workbench layout (scene tree, viewport, inspector). It is not the shipping editor. | Run 45822464749, release shader-check-run2 |
| Branding assets (logo, icon, splash, editor theme file) | Files merged. Logo, icon and splash applied to the editor build. The old mint theme file is not used. | branding/ |
| AK editor colour theme | Applied: near-black with AK red accent, via built-in editor settings (screenshot viewed). It is the stock Godot layout recoloured, not a new editor UI. | Run 45911858273, release ak-editor-run4 |
| glTF import | Headless import of the two sample glTF props in CI, mesh and vertex counts checked (bank-rock 1 mesh/54 verts, marker-buoy 4 meshes/336 verts). | Run 45911510929, release gltf-test-run1 |
| Android export (arm64 demo APK) | Builds from source in CI, APK verifies with apksigner (v2/v3, debug key). AK installed run2 on a Galaxy A17 and it runs (his report; first real-hardware pass, no performance data). | Run 45828048503, release android-demo-run2 |
| Android APK branding | App label "AK Engine", adaptive launcher icon and Android 12 splash icon from the AK logo (checked in the built APK with aapt2 and by viewing the extracted images). Boot splash is set in project config, not yet seen on a device. | Run 45860933501, release android-demo-run3 |
| Web export (single-thread wasm, 9.9 MB) | Builds in CI and loads in headless Chromium with software WebGL; one real frame captured. Not tested in a desktop or phone browser, no performance data. | Runs 45833128277 and 45836813148, releases web-demo-run1, web-test-run1 |
| AK splash and app icon in the editor build (AK's red-and-white logo) | Splash verified in a running-editor screenshot. Icon not visually checked. Editor UI and theme are still stock. | Run 45829201524, release ak-editor-run2 |
| Forge ident animation | Rendered in CI with Blender 4.5.9 (Cycles CPU), QA script passed; stills viewed, audio not listened to. | Run 45828518262, release ident-render-run1 |
| Raycast/Embree module | Disabled because the bundled Embree failed to link in run #1. To revisit. | run 45789587511 |
| Renderer upgrades, in-engine asset creation, world streaming, physics, AI, AAOS, Web, benchmarks, South Kayal game | Planned. No code. No measurements. | none |

Merges: PR #1 (186b1d4), PR #2 (4b4a74d) and PR #3 (3c0c2e5) came from external AI branches under friday/. Each was reviewed, scripts read, and CI-tested before merge.

Completion (verified milestones only): Phase 0 done. Phase 1: library, build, render proof, editor launch and Linux export are done. Repo-level build docs are still missing.

## Phase order (from the master directive, section 15)

AK's instruction (26 Nov, 18:41 IST): work is continuous until the engine is done. Nothing below is claimed done until it has a link in the table above.

| Phase | Scope | State | Next concrete step |
|---|---|---|---|
| 0 Research | Source analysis, licence audit | Docs done, dependency-tree audit open | Audit O3DE and Blender dependency trees |
| 1 Foundation | Repo, build, branding, first editor, exported 3D scene | Mostly done (see table). Missing: editor UI theme (still stock), repo build docs | Make the editor theme visibly apply; rename binary; build docs |
| 2 In-engine asset creation | glTF import (done in CI), own modelling and animation tools inside the editor, export. See the stage table below. | glTF import test passes; modelling and animation not started | Headless mesh-edit prototype and animation CI test |
| 3 Advanced graphics | O3DE-derived or equivalent rendering | Not started | Research which O3DE renderer parts are portable; prototype in isolation |
| 4 Open world | Terrain, streaming, partitioning, NPCs, vehicles | Not started | Terrain and chunk streaming prototype |
| 5 Android and Web | Mobile and browser profiles, real-device tests | Android runs on one device (AK's); Web loads in headless Chromium | Real-browser web test, Android performance test |
| 6 AI integration | Dev assistance, optimisation | Not started | After Phase 2 |
| 7 Production readiness | Test, regressions, stable releases | Not started | Ongoing regression CI |

## Decisions

- 2026-11-27, AK: asset creation and animation happen inside the engine ("own Blender"), not through an external Blender bridge. glTF import stays as a complement for free third-party assets.
- 2026-11-27, AK: use Blender source code directly for the in-engine modelling and animation tools. AK Engine is now GPL-3.0 (`LICENSE`). Godot MIT and O3DE Apache-2.0/MIT code stay under their own notices inside the combined work. Details and rules: `docs/LICENSE-AUDIT.md`. AK confirmed on 2026-11-27: Blender-derived code stays editor-only. Exported games ship the Godot MIT runtime plus AK runtime code, no GPL.
- 2026-11-27, AK: design requirement. AK Engine switches renderer automatically per game: 2D games use the Godot renderer, 3D games use the O3DE (Atom) renderer. Architecture is a renderer-abstraction layer in AK Core with automatic 2D/3D detection. Status: abstraction logic implemented (`core/`, unit-tested natively); O3DE backend NOT integrated, so 3D currently falls back to Godot with fell_back=true. See `docs/RENDERER-EVAL.md`.
- 2026-11-27, AK: Phase 2 acceptance milestone: a car and a character built with AK Engine's own tools, exportable (glTF), with real screenshots and files, no mockups. Starts after stages 2.1 and 2.2 land as interactive tools.
- 2026-11-27, AK: standing rule, run independent work in parallel and report what runs in parallel.
- Package id stays com.akstudio.akenginedemo for now.

## Phase 2 replaced: In-engine asset creation (modelling and animation)

| Stage | Scope | State | Next concrete step |
|---|---|---|---|
| 2.0 | glTF import for third-party assets (complement) | CI test passes | Add material and animation import checks |
| 2.1 | In-editor primitives and mesh editing (vertex, edge, face select, extrude, bevel, delete), saved as ArrayMesh/glTF | Not started. Research first: Godot base has SurfaceTool, ArrayMesh, MeshDataTool, ImporterMesh and editor plugins (GDScript or C++). | Headless prototype that builds, edits and saves a mesh in CI |
| 2.2 | In-editor animation: AnimationPlayer, animation editor and skeleton tools already ship in the Godot base | Not verified headless | CI test that creates an Animation with tracks, plays it and checks the result |
| 2.3 | Procedural tools (roads, buildings, terrain) | Not started | After 2.1 |
| 2.4 | DCC-grade modelling (long term): port Blender BMesh-style editing, modifiers, sculpt, rigging | Not started. Blender source may now be used (GPL). | Audit which Blender modules are separable |

## AK Core and renderer switch

| Item | State |
|---|---|
| core/ C++ library: asset_id, rebase, classify_game, select_renderer | Implemented, native tests pass locally |
| godot_module/ak_core (AKCore, AKFrameStats) | EXPERIMENTAL. Compile check in CI workflow ak-module-test; not yet passing |
| O3DE backend | Planned, not integrated |
| Automatic 2D/3D switch with real O3DE | Planned. Switch point exists; only the Godot path is live |
