# Renderer interface (PLANNED, nothing here is implemented)

Status: PLANNED. No O3DE backend exists. `select_renderer` still falls back to Godot.
A backend counts as real only after a CI screenshot proves an Atom render of a scene.

## Rule (AK)
2D uses Godot. 3D uses O3DE (Atom). Never fake an O3DE backend.

## Interface a backend must provide
- `name() -> String`: "godot" or "o3de".
- `available() -> bool`: true only if the backend can actually draw (GPU Vulkan present).
- `load_scene(path)`: glTF/GLB first, since the modeler exports GLB.
- `set_camera(transform, fov)`, `set_environment(sky, sun)`.
- `render_frame(width, height) -> Image`: used by CI screenshot checks.
- `shutdown()`.

## select_renderer behaviour
1. 2D project: Godot.
2. 3D project: try O3DE, call `available()`.
3. If not available: Godot fallback, and log the reason. Never report "o3de" in that case.

## Evidence so far (O3DE track)
- Atom Vulkan loads real geometry on llvmpipe at 1920x1080 (runs 13 to 18), then stalls. Partial scene only.
- Run 19 at 640x360: levels loaded, all 3 screenshots blank. Smaller size did not help.
- Colab T4: no Vulkan ICD in the container, loader fails at vkCreateInstance. Unsolved.

## Next steps (all PLANNED)
1. Get one machine with real Vulkan (free route only) and run the probe there.
2. Lit, textured scene screenshot in CI = milestone.
3. Only then write the O3DE backend against the interface above.
