# Android performance techniques

**Decision state: research only.** This proposal does not modify export pipelines, set device requirements, or claim APK performance. Compare native Vulkan Mobile with GLES Compatibility on physical handsets before defaulting either across all Android devices. Renderer availability depends on device, OS and driver; see [Godot's renderer overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).

## Establish a reproducible baseline

1. Pick one real low-end phone and one midrange phone with distinct GPU families if available. Capture exact model, SoC/GPU, Android version, driver/renderer, build commit, release/debug state, resolution/render scale and refresh rate.
2. Use the same 2–3 minute scripted run: cold launch, vehicle-free 3D traversal, dense foliage pass, water pass, UI and return to the start. Keep the camera path and scene settings the same across backends.
3. Record both early frames and a sustained run of at least 15 minutes. Log frame-time p50/p95/p99, hitches, frame pacing, peak memory and thermal state. Note ambient temperature and repeats. Verify visual regressions with matched screenshots.
4. Derive budgets from a target: 30 FPS is approximately 33.3 ms/frame; 60 FPS is about 16.7 ms/frame. These are planning math, not AK measurements. Keep headroom rather than tuning a device to exactly the arithmetic limit.

## Try changes in this order

| Bottleneck sign | Candidate change | What to remeasure |
| --- | --- | --- |
| GPU time rises strongly with resolution | Lower internal render scale; simplify transparency, shader passes and shadow filtering | GPU ms, legibility and water/foliage appearance |
| CPU time rises with visible object count | Batch repeated props (e.g. MultiMesh), limit draw distance, split into spatial chunks so culling still works | Main/render CPU time, draw count, memory |
| Hitches at region boundaries | Schedule loading and shader warm-up gradually; reduce simultaneous texture/geometry uploads | p95/p99 frame time, peak memory, cold vs warm runs |
| Memory pressure or long package startup | Budget texture resolution and mip chains; use device-supported block compression; remove unused import outputs | Process memory, content size, first playable frame |
| Good cold performance but worsening hot runs | Adopt tiered shadow/view-distance/scale settings; consider thermal-aware adjustments and frame pacing | Sustained frame-time spread and thresholds, not just average FPS |

Profiling tools: start with the Godot profiler where applicable; use [Android GPU Inspector](https://developer.android.com/agi) on supported devices and [Perfetto](https://perfetto.dev/docs/) for scheduling/system traces. [Android Frame Pacing](https://developer.android.com/games/sdk/frame-pacing) documents Swappy; verify what upstream Godot already uses before proposing integration. [Android Dynamic Performance Framework](https://developer.android.com/games/optimize/adpf) provides thermal and performance signals; support varies by device. Neither SDK is added or enabled by these notes.

Report one change per comparison so reviewers can attribute results. Lock unavailable tests as “not run”; the desktop Shader Lab does not substitute for device measurements.
