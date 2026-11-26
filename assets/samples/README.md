# AK original sample assets

- `preview/models/marker-buoy.gltf`: low-poly buoy with four authored materials.
- `preview/models/bank-rock.gltf`: faceted shoreline rock with its own material.
- `preview/textures/sand-tile.svg` and `preview/materials/sand.tres`: original seamlessly repeatable sand texture and Godot material.
- The glTF files contain embedded buffers, explicit vertex normals and editable mesh geometry; no network resources or textures are needed for those models.

These assets are intentionally small and readable, not production art or performance benchmarks. Open the glTF in your authoring tool or copy the `preview/` resource paths into a Godot 4 project. The [shader library](../../shaders/README.md) builds an isolated launchable scene around them.

Everything under `assets/samples/` is original and licensed under the repository [MIT licence](../../LICENSE), © 2026 AK Studio. Nothing was downloaded, generated from proprietary assets, or taken from Blender or O3DE source.
