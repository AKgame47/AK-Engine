# AK shader library

Original MIT-licensed Godot 4 shaders. No dependencies on upstream shader snippets, rendering-engine ports, plugins, or textures.

| Shader | Where to apply it | Controls and limits |
| --- | --- | --- |
| `water.gdshader` | Spatial material on a horizontal plane | Deep/shallow colours and animated bands; no depth trace, foam geometry, compute, or true reflection/refraction |
| `sky.gdshader` | Sky material in a WorldEnvironment | Upper/horizon colours and a soft sun disc; not an atmospheric-scattering simulation, and the scene light must be positioned separately |
| `foliage.gdshader` | Spatial material on a quad facing camera with UV map | Height-weighted wind and opaque alpha cutout via discard; use top UV.y=0, allow margin in bounds, and profile heavy overdraw before using in dense scenes |

## Run a local preview

On Linux or another host with a POSIX shell and Godot 4.7.2 on the PATH:

```sh
./shaders/run-preview.sh
./shaders/run-preview.sh --check # import/startup only; no GPU validation
GODOT=/path/to/godot ./shaders/run-preview.sh --capture /absolute/path/shore.png
```

A graphical display is needed. The script stages canonical assets and shaders in a disposable project, imports the assets and starts Compatibility rendering. No files in the primary engine/smoke project are modified. To use separately, copy the shaders into your project and create a ShaderMaterial for each appropriate resource.

These are example materials, not features integrated into the AK Runtime. No Android or Web export compatibility or performance claim is made here. All shader source and preview files are original AK Studio contributions licensed under the repository [MIT licence](../LICENSE), © 2026 AK Studio.
