# Status (updated 2026-11-27, 05:00 IST)

Every "Implemented" row has a link to the CI run, release or file that shows it. Everything else is not done.

| Item | State | Evidence |
|---|---|---|
| Phase 0: source fetch, architecture ADR, licence audit | Implemented (docs). Full dependency-tree audit planned. | docs/ARCHITECTURE.md, docs/LICENSE-AUDIT.md |
| AK Core: ids, large-world offsets, frame stats, tests | Implemented, tests pass on Linux + Windows CI | Actions workflow "ci" |
| Upstream Godot 4.7.2 editor builds on free CI (Linux x86_64, raycast/Embree module disabled) | Implemented. Cold build 27m17s, cached about 3.5 min. | Actions runs 45796182937, 45804123055 |
| AK name patch (version string "AK Engine") | Implemented, name only. Binary file name is still godot.*; the editor UI itself is stock Godot, no AK theme, logo or splash applied. | docs/evidence/editor-run6.png |
| Real 3D render by the AK-named build (software OpenGL via llvmpipe, 1152x648) | Implemented, one frame, no performance data | docs/evidence/shot-run5.png |
| Editor window launch with screenshot (stock UI) | Implemented, one screenshot under xvfb | docs/evidence/editor-run6.png |
| Linux export of the demo project | Implemented. Exported binary starts under xvfb (headless smoke run only). Not tested on real hardware, unsigned. | Run 45819090853, release demo-linux-run2 |
| Shader library (water, sky, foliage) and sample glTF props | Implemented, renders in CI (software rendering, stylized, low-poly, not realistic). No GPU or mobile performance data. | Run 45820727265, release shader-check-run1 |
| AK Studio UI | UI concept only: a standalone Godot app showing a workbench layout (scene tree, viewport, inspector). It is not the shipping editor. | Run 45822464749, release shader-check-run2 |
| Branding assets (logo, icon, splash, editor theme file) | Files merged. Not yet applied to the engine editor build. | branding/ |
| Android export (arm64 demo APK) | Builds from source in CI, APK verifies with apksigner (v2/v3, debug key). AK installed run2 on a Galaxy A17 and it runs (his report; first real-hardware pass, no performance data). | Run 45828048503, release android-demo-run2 |
| Android APK branding | App label "AK Engine", adaptive launcher icon and Android 12 splash icon from the AK logo (checked in the built APK with aapt2 and by viewing the extracted images). Boot splash is set in project config, not yet seen on a device. | Run 45860933501, release android-demo-run3 |
| Web export (single-thread wasm, 9.9 MB) | Builds in CI and loads in headless Chromium with software WebGL; one real frame captured. Not tested in a desktop or phone browser, no performance data. | Runs 45833128277 and 45836813148, releases web-demo-run1, web-test-run1 |
| AK splash and app icon in the editor build (AK's red-and-white logo) | Splash verified in a running-editor screenshot. Icon not visually checked. Editor UI and theme are still stock. | Run 45829201524, release ak-editor-run2 |
| Forge ident animation | Rendered in CI with Blender 4.5.9 (Cycles CPU), QA script passed; stills viewed, audio not listened to. | Run 45828518262, release ident-render-run1 |
| Raycast/Embree module | Disabled because the bundled Embree failed to link in run #1. To revisit. | run 45789587511 |
| Renderer upgrades, Asset Studio (Blender bridge), world streaming, physics, AI, AAOS, Web, benchmarks, South Kayal game | Planned. No code. No measurements. | none |

Merges: PR #1 (186b1d4), PR #2 (4b4a74d) and PR #3 (3c0c2e5) came from external AI branches under friday/. Each was reviewed, scripts read, and CI-tested before merge.

Completion (verified milestones only): Phase 0 done. Phase 1: library, build, render proof, editor launch and Linux export are done. Repo-level build docs are still missing.

## Phase order (from the master directive, section 15)

AK's instruction (26 Nov, 18:41 IST): work is continuous until the engine is done. Nothing below is claimed done until it has a link in the table above.

| Phase | Scope | State | Next concrete step |
|---|---|---|---|
| 0 Research | Source analysis, licence audit | Docs done, dependency-tree audit open | Audit O3DE and Blender dependency trees |
| 1 Foundation | Repo, build, branding, first editor, exported 3D scene | Mostly done (see table). Missing: editor UI theme (still stock), repo build docs | Make the editor theme visibly apply; rename binary; build docs |
| 2 Asset Studio | glTF import, Blender headless bridge, modelling, animation, export | Not started | glTF import test in CI, Blender bridge script with CI test |
| 3 Advanced graphics | O3DE-derived or equivalent rendering | Not started | Research which O3DE renderer parts are portable; prototype in isolation |
| 4 Open world | Terrain, streaming, partitioning, NPCs, vehicles | Not started | Terrain and chunk streaming prototype |
| 5 Android and Web | Mobile and browser profiles, real-device tests | Android runs on one device (AK's); Web loads in headless Chromium | Real-browser web test, Android performance test |
| 6 AI integration | Dev assistance, optimisation | Not started | After Phase 2 |
| 7 Production readiness | Test, regressions, stable releases | Not started | Ongoing regression CI |
