# O3DE (Atom) integration plan, 3D renderer track

Status: PLANNED. Research and design only. No O3DE code is in this repo. The O3DE backend does not exist: `select_renderer` keeps its Godot fallback until a real O3DE path renders something and a CI check proves it.

Requirement (AK, 2026-11-27): 2D games use Godot, 3D games use O3DE, switched automatically. Started at AK's instruction on 2026-11-27, in parallel with the other tracks.

## Pinned version
- O3DE release tag 2610.0, published 2026-11-20 (GitHub API: https://api.github.com/repos/o3de/o3de/releases/latest). Repo size about 235 MB (API `size`, KB).
- Licence: Apache-2.0, or MIT at the user's option; contributions under both (LICENSE.txt in the repo, https://github.com/o3de/o3de). GitHub shows NOASSERTION only because of the dual file. Third-party components are listed separately in that file and are NOT yet audited (sub-track D).

## Atom architecture, as documented (source: docs.o3de.org Atom dev guide)
Read from https://docs.o3de.org/docs/atom-guide/dev-guide/rpi/rpi-system/ , .../rhi/rhi/ , .../passes/pass-system/ . Not yet confirmed against source code.
- RHI: thin layer over DirectX 12, Vulkan, Metal. Frame Scheduler treats passes as a graph.
- RPI (Render Pipeline Interface): Scene (rendering context, own scene SRG), Render Pipeline (pass tree for one scene), View (camera matrices), Feature Processor (one per feature type per scene; prepares draw data), Pass (where GPU commands are submitted; data-driven JSON or C++).
- A scene without a render pipeline is not rendered. At least one Scene must exist.

## Mapping to the AK renderer abstraction
| AK concept (core/) | Atom concept | Note |
|---|---|---|
| RendererKind::O3DE | whole Atom stack in an O3DE host app | selected by `select_renderer(classify_game(...), o3de_available)` |
| Game scene (nodes) | RPI Scene + entities with Mesh/Light/Camera components | needs a scene description both backends read |
| Camera | RPI View | |
| Mesh assets (glTF) | Atom Model assets via the O3DE Asset Processor | glTF import into Atom is UNVERIFIED |
| Lights | Feature processors (directional, point) | |
| Large-world `WorldPos` | O3DE uses float transforms | rebase logic stays in AK Core, feed local offsets |

## Design decision (proposed, unproven)
Two engines in one process means two scene graphs, two windows and two asset systems. Proposal: a game is built for ONE runtime, chosen at export from `classify_game`. 3D games export as an O3DE project; 2D games export as the Godot runtime. A neutral scene description (glTF plus a small AK JSON for cameras, lights, gameplay hooks) is the shared input. Web export stays Godot-only, because O3DE does not target web.

## Minimal integration surface (what has to exist for "renders something")
1. An O3DE project containing one AK Gem (C++) that loads the neutral scene description and creates entities (mesh, camera, directional light).
2. glTF to Atom asset path through the Asset Processor (test with the engine-made car and the imported CC0 car).
3. A headless or offscreen frame capture to PNG, run in CI.
4. A one-function bridge in AK Core: `o3de_available` becomes true only when 1 to 3 pass in CI.
Everything else (physics, audio, input, scripting, UI) is out of scope until 1 to 4 work.

## Risks, stated plainly
- GitHub free runners have no GPU. Rendering needs a software Vulkan driver (lavapipe). Whether Atom runs on it is UNKNOWN.
- A full O3DE source build is large (long compile, big disk). Free runner limits (disk, 6 h job cap) may block it. A prebuilt-binary route may be needed; its licence and size are unchecked.
- Licence-wise GPL-3.0 combination with Apache-2.0/MIT is fine per docs/LICENSE-AUDIT.md, but O3DE's third-party components need their own check.

## Milestone ladder (a rung counts only when a CI check proves it)
| # | Milestone | Status |
|---|---|---|
| M0 | Pin release, licence read, architecture notes, this plan | DONE (docs only) |
| M1 | O3DE source fetched in CI at tag 2610.0, size and file counts logged | DONE. Commit b612281, 30,973 files, 2,790 MB checked out (depth 1), 16,219 C/C++ files, 4,747 under Gems/Atom. Runner: 4 CPUs, 15 GB RAM, 83 GB free disk. Evidence: https://github.com/AKgame47/AK-Engine/releases/tag/o3de-probe-run2 |
| M2 | Dependency/third-party licence audit | PLANNED |
| M3 | O3DE core libs (AzCore) build in CI, time and disk logged | PLANNED |
| M4 | O3DE editor or launcher builds, or documented blocker | PLANNED |
| M5 | Atom renders a built-in test scene offscreen, screenshot in CI | PLANNED |
| M6 | AK Gem loads a glTF and renders it | PLANNED |
| M7 | Neutral scene description read by both backends | PLANNED |
| M8 | `o3de_available` set by a real CI probe, `select_renderer` picks O3DE for a 3D sample | PLANNED |

## Sub-tracks (run in parallel; only CI-bound ones are sequenced)
- A. Source fetch + build probe (M1, M3, M4): CI-bound, runs one heavy job at a time.
- B. Architecture mapping from source (this doc, then read Atom/RPI code): no CI.
- C. Abstraction interface design (neutral scene description, backend interface): no CI.
- D. Licence and third-party audit (M2): no CI.
- E. Milestone docs and STATUS updates: no CI.
