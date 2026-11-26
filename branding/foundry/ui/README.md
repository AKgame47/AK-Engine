# AK Engine Studio — native UI preview

A standalone Godot 4.7.2 Compatibility project. AK Engine's actual editor source, runtime, exports, workflows, and protected repository areas are not modified. This is a UI/interaction prototype, not an editor integration.

## Launch on Linux

```sh
./launch.sh
./launch.sh --check
./launch.sh --capture /absolute/path/editor-preview.png
```

Requires an official Godot 4.7.2 binary on the PATH; set `GODOT=/path/to/godot` otherwise. Interactive viewing and PNG capture require a graphical session. `--check` verifies behavior headlessly; it does not verify drawn pixels. Launch uses disposable XDG configuration, leaving ordinary editor settings untouched. This preview starts at 1440×900.

## What works

- Scene tree selection/filtering and asset cards that select actual 3D groups in the relay assembly.
- Orbit with right drag, zoom using the wheel; perspective/orthographic projection, grid visibility, and frame reset.
- Move/rotate/scale modes with left drag or numeric transform entry, local node visibility, interactive material roughness/metallic controls, and turbine preview animation.
- Scene, Materials, and Reference tray tabs; changes are temporary. The Reset button restores initial state.

The graphite/paper/copper interface and relay assembly are original AK Studio design work; the monogram is shared with the sibling identity kit. All preview source and assets are MIT. System font fallback is used; no typeface assets are redistributed.
