# WebGPU export options

**Decision state: research only.** AK Engine does not ship or claim any WebGPU export. The existing compatibility fallback and any export wiring remain with the export/runtime owners.

## Baseline and options

| Approach | What it proves | Main cost or limitation |
| --- | --- | --- |
| Godot's documented Compatibility/WebGL 2 export path | A browser can load the existing type of Godot project without a new GPU backend, once the AK Web export is built and tested | Compatibility feature set; browser limits; no WebGPU or RenderingDevice support implied |
| Standalone browser WebGPU spike (TypeScript/JavaScript + WGSL, or C/C++ compiled to Wasm with Emdawnwebgpu) | Actual adapter/device availability, pipeline validation, sample mesh/texture upload and resize behaviour | Does not load Godot scenes by itself and does not demonstrate the engine can export |
| Experimental RenderingDevice backend after the standalone spike | Potentially retain scene and material workflows with an engine-native path | Needs GPU API mapping, feature/limit negotiation, resource and pipeline lifetimes, surface creation, shader translation, device loss and backend-specific conformance tests. Not a compiler flag |

**Recommendation:** keep WebGL 2 first. Ask the runtime and export owners to choose whether a standalone WebGPU triangle → glTF mesh → textured depth-pass experiment is worth pursuing. For C++, [Emscripten documents Emdawnwebgpu](https://emscripten.org/docs/porting/multimedia_and_graphics/WebGPU-support.html), a port for browser WebGPU. This is a new backend investigation, not an automatic Vulkan-to-WebGPU translation. Use WGSL for the initial shaders. Check third-party licensing before adding any dependency; this note does not install any.

## Verification gate for a later experiment

1. Serve from HTTPS or a localhost development origin in a supported browser. Check `navigator.gpu`, the adapter request, and required features/limits explicitly. If adapter/device initialization fails, give users a clear error or tested WebGL 2 fallback. Never advertise fallback until it works.
2. Test and log browser version, OS, device and renderer. Start with real Chromium desktop, Firefox, Safari and Android Chrome where available; mark unsupported or not tested instead of assuming parity.
3. Draw and capture a known image. Log validation failures. Test resize, loss/recreation of device resources, and slower adapter/memory cases. Record initial payload, time-to-first-render and frame-time distributions against the same WebGL baseline. No target figures are measurements.
4. Godot's existing web builds have separate threading requirements: a threaded build can need cross-origin isolation and compatible embedding headers. Treat this independently of secure-context requirements for WebGPU. Keep the non-threaded path testable when possible.

Primary references: [Godot Web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html), [Godot rendering architecture](https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html), [W3C WebGPU specification](https://www.w3.org/TR/webgpu/), [Emscripten WebGPU support](https://emscripten.org/docs/porting/multimedia_and_graphics/WebGPU-support.html). The generic water, sky and foliage examples are Godot shader language, not standalone WGSL.
