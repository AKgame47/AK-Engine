# Status (updated 2026-11-26, 16:50 IST)

Every "Implemented" row has a link to the CI run or file that shows it. Everything else is not done.

| Item | State | Evidence |
|---|---|---|
| Phase 0: source fetch, architecture ADR, licence audit | Implemented (docs). Full dependency-tree audit planned. | docs/ARCHITECTURE.md, docs/LICENSE-AUDIT.md |
| AK Core: ids, large-world offsets, frame stats, tests | Implemented, tests pass on Linux + Windows CI | Actions workflow "ci" |
| Upstream Godot 4.7.2 editor builds on free CI (Linux x86_64, raycast/Embree module disabled) | Implemented. Cold build 27m17s, cached 3m24s. | Actions runs 45796182937, 45804123055 |
| AK name patch on the fork (version string "AK Engine") | Implemented, name only. Binary file name is still godot.*; no other AK changes. | docs/evidence/render-run5.log |
| Real 3D render by the AK-named build (cube, sphere, plane, light, camera, software OpenGL via llvmpipe, 1152x648) | Implemented, one frame, no performance data | docs/evidence/shot-run5.png |
| Linux export of a project | Planned, not started (needs export templates build) | none |
| Editor UI launch with screenshot | Planned, not started | none |
| Raycast/Embree module | Disabled because the bundled Embree failed to link in run #1. To revisit. | run 45789587511 |
| Renderer upgrades, Asset Studio (Blender bridge), world streaming, physics, AI, AAOS, Android, Web, benchmarks, South Kayal | Planned. No code. No measurements. | none |

Completion (verified milestones only): Phase 0 done; Phase 1: 3 of 6 defined milestones (library, build, render proof), still missing export, editor launch, repo-level build docs.
