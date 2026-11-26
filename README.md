# AK Engine

Open-source 3D game engine by AK Studio. Goal: AAA-class graphics, open worlds, Windows/Linux/Android/Web, usable on low-end hardware.

**Honest status: Phase 0 done (research and licence audit), Phase 1 in progress. Only AK Core (math, ids, memory, frame timing) exists as code. There is no editor, renderer or runtime yet.** See `docs/STATUS.md` for what is implemented, planned, blocked and untested.

- Architecture decision: `docs/ARCHITECTURE.md`
- Licence audit: `docs/LICENSE-AUDIT.md`
- Roles: `docs/ROLES.md`
- Roadmap: `docs/ROADMAP.md`

## Build AK Core
    cmake -S . -B build && cmake --build build && ctest --test-dir build --output-on-failure

AK Engine's own code is MIT. Upstream Godot (MIT), O3DE (Apache-2.0 or MIT) and Blender (GPL) are not vendored; see the audit for how each is used.
