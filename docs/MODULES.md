# Module overview

The table separates checked-in implementation from proposed architecture. See [architecture history](ARCHITECTURE.md), [verified status](STATUS.md), and [licence boundaries](LICENSE-AUDIT.md).

| Area | Purpose | Evidence or status |
| --- | --- | --- |
| AK Core | Engine-independent identifiers, large-world coordinates and timing/statistics | Implementation and tests in [core/](../core/) |
| AK Runtime and Editor | Godot scene/node runtime and Godot editor shell | Pinned upstream is fetched externally; recorded AK name patch and render evidence are not a bespoke editor or runtime integration |
| Renderer | Plan for native RenderingDevice work; evaluate ideas from O3DE/Atom before porting | Stock Compatibility scene and render evidence only; sample shaders are content, not an AK Renderer implementation |
| Asset Studio and Asset Manager | Proposed out-of-process Blender authoring and import/asset flow | Planned; use interchange assets, not Blender source or runtime linkage |
| Physics, World and Animation | Proposed simulation, large worlds, streaming and animation pipelines | Planned as AK-specific modules; this is separate from existing upstream Godot features |
| Audio, AI and Network | Proposed AK-specific audio, agents and networking | Planned |
| Export and Optimizer | Target packaging, quality tiers and performance tooling | Targets planned; use status and actual logs to verify individual builds and exports |

## Dependency direction

- Keep AK Core independent of engine and editor packages. Its CMake tests do not need an editor.
- The runtime is based on a pinned Godot version. No Blender GPL source is copied into or linked to the runtime or editor.
- Asset authoring can use Blender separately and exchange files such as glTF 2.0. Treat each imported asset’s licence as a separate check.
- No O3DE code is introduced by these docs or the sample library. Any future port needs a measured benefit and a component-specific licence/NOTICE review.
