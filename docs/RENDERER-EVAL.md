# Renderer evaluation: Godot (2D) and O3DE Atom (3D)

Status: EVALUATION ONLY. No O3DE code is in AK Engine. Nothing here is tested in this repo.

## Requirement (AK, 2026-11-27)
Automatic per-game renderer switch. 2D uses Godot. 3D uses O3DE. Implemented so far: the decision logic in AK Core (`select_renderer`), with a Godot fallback flag while O3DE is absent.

## Facts checked
- O3DE repo: https://github.com/o3de/o3de . Latest release tag seen on 2026-11-27: 2610.0 (published 2026-11-20), via the GitHub API. GitHub reports the licence as NOASSERTION because the repo ships a dual licence file; the project describes it as Apache-2.0 or MIT. Re-verify the licence file before taking any code.
- Both are compatible with GPL-3.0 combination per docs/LICENSE-AUDIT.md.

## Open questions (not yet answered)
1. Can Atom be built and run without the full O3DE editor, as a library inside another host? Unknown.
2. Window/input/asset ownership: two engines in one process means two scene graphs. Likely design is an out-of-process or per-game build choice: a game is built for either the Godot runtime or the O3DE runtime, chosen at export from `classify_game`. Unverified.
3. Asset pipeline: glTF is the shared format. O3DE has its own asset processor. Needs a test.
4. Platform reach: O3DE targets desktop and mobile; web export is not expected. 3D games on web would stay on Godot.
5. Size of the dependency tree (needs audit before any code is taken).

## Plan
- Phase 3a: build O3DE from source in CI, report the real cost (time, size, free-runner limits).
- Phase 3b: render a glTF in an O3DE project headless and capture a screenshot.
- Phase 3c: only then wire a backend behind the AK Core switch.
Until 3c, 3D games run on the Godot renderer.
