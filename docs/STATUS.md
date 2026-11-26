# Status (updated 2026-11-26, 18:30 IST)

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
| Forge ident video (Blender scripts) | Scripts merged. Never run in CI, untested. | branding/foundry/motion/ |
| Android export | In progress: first CI run started 18:27, result unknown. | run 45824460766 |
| Raycast/Embree module | Disabled because the bundled Embree failed to link in run #1. To revisit. | run 45789587511 |
| Renderer upgrades, Asset Studio (Blender bridge), world streaming, physics, AI, AAOS, Web, benchmarks, South Kayal game | Planned. No code. No measurements. | none |

Merges: PR #1 (186b1d4) and PR #2 (4b4a74d) came from external AI branches under friday/. Each was reviewed, scripts read, and CI-tested before merge.

Completion (verified milestones only): Phase 0 done. Phase 1: library, build, render proof, editor launch and Linux export are done. Repo-level build docs are still missing.
