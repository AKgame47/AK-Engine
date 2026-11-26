# Getting started with AK Engine

AK Engine is an early-stage 3D engine project. The repository contains an independently buildable C++ core and a small Godot-format smoke scene. The AK-named editor is a CI build of pinned Godot 4.7.2 with a name-string patch, not a replacement renderer. Check [STATUS.md](STATUS.md) for verified milestones and [evidence/](evidence/) for recorded runs; do not assume a ready-to-distribute engine or working export for every target.

## 1. Clone and test AK Core

Install Git, CMake 3.16 or later, and a C++17 toolchain (GCC or Clang on Linux, MSVC Build Tools on Windows). From a terminal:

```sh
git clone https://github.com/AKgame47/AK-Engine.git
cd AK-Engine
cmake -S . -B build
cmake --build build --config Debug
ctest --test-dir build -C Debug --output-on-failure
```

The core test executable runs independently of Godot and Blender. For single-configuration generators, select a different build type with `-DCMAKE_BUILD_TYPE=Release` at configuration time. If no compiler is found, install one or launch the appropriate MSVC developer shell, then configure into a clean build directory.

## 2. Open or run the smoke scene

Use [Godot](https://godotengine.org/download/) matching the pin in [upstream/README.md](../upstream/README.md), or the compatible AK-named editor if you have obtained it from a verified repository build. In Godot's Project Manager, import `project/project.godot`, open it, then use **F6** with `main.tscn` open or **F5** to run the main project scene. For command-line launch:

```sh
godot --path project --editor
godot --path project
```

Replace `godot` with the installed executable path where needed. The smoke scene uses Compatibility; a display and supported OpenGL driver are needed to visually inspect it. `--headless` is useful for import or startup checks, not rendered-image verification. The stock Godot binary is a tooling fallback, not the AK-branded build. The separately linked [samples](../assets/samples/README.md) show how to try original assets and shaders without altering the smoke project.

## 3. Know what has not been verified

Windows, Linux, Android and Web are targets, not a certification matrix. Linux tooling can be exercised without claiming that distribution builds or export templates are ready. Do not treat a bare workflow or export preset as evidence of a successful export. No Blender installation is required for Core or the smoke scene; the proposed asset bridge is a separate external process. Read [Modules](MODULES.md) and [Contributing](CONTRIBUTING.md) before changing core infrastructure.
