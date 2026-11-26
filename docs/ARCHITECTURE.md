# Architecture decision record 001 (Phase 0)

Status: proposed, based on source inspection and licences only. No benchmarks yet.

## Findings
- Godot is C++ with SCons, scene/node system, Vulkan (RenderingDevice, `servers/rendering/renderer_rd`), a GL compatibility renderer, and exports to Windows, Linux, Android and Web. It is the only one of the three that already covers all four target platforms.
- O3DE is Apache/MIT, CMake, gem-based, with the Atom renderer. Its stack is heavy (about 4.9 GB checkout) and Android/Web support is limited, so it is not a good runtime base for low-end hardware or the browser.
- Blender is GPL and a full DCC application, not an embeddable library.

## Decision
- Runtime base: fork of Godot 4.7.2 as `AK Runtime` (planned), tracked as an upstream-synced branch.
- Rendering: add AK Renderer features in the Godot RenderingDevice stack; port selected O3DE gems (SkyAtmosphere, Terrain, Vegetation) only when a prototype shows a measured benefit.
- Asset Studio: Blender as an isolated out-of-process tool with documented interchange (glTF 2.0 / USD), orchestrated by the editor.
- Original modules in `core/` (CMake, no dependency on Godot) hold the engine's own identifiers, math, memory and frame-timing code, so they can be tested and shared with any backend.

## Open decisions for AK
- Editor licence: MIT with Blender as a bridge (default), or GPL for a deep Blender merge.

## Module map
AK Core, Renderer, Asset Studio, Physics, World, Animation, Audio, AI, Network, Editor, Export, Optimizer, Asset Manager: all planned except AK Core (started).
