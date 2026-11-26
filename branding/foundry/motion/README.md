# AK Engine / Forge ident

An original five-second Blender logo reveal with engineered metal assembly, a single hand-keyed copper strike, and bespoke synthesized foley. Nothing is sampled from a film, trailer, game, or effects library.

- **AK-Engine-Forge-Ident.mp4** — 1280×720 at 24 fps, H.264 video and stereo AAC.
- **AK-Engine-Ident.blend** — editable geometry, camera, lighting, and color from the companion AK Engine SVG artwork; custom wordmark strokes come directly from its SVG. DejaVu Sans is packed for the small AK Studio signature only. The matching sound is also packed on the Blender timeline.
- **AK-Engine-Ident-Sound.wav** — original 48 kHz stereo mix. Use this stem for external editing; it is also packed in the Blend file.
- **build_ident.py** — Blender scene generator; reads SVGs in `../identity/`.
- **sound_design.py** — source synthesizer, requiring NumPy and SciPy.
- **assemble_ident.sh** — FFmpeg H.264/AAC packaging; holds the last frame for the end card and applies a light denoise.

Re-render with Blender 4.3+:

```sh
python sound_design.py
blender -b --python build_ident.py -- render
./assemble_ident.sh
```

Delete or move `render/frame_*.png` before a full re-render; the build script otherwise resumes at the first missing frame. The engineered impact lands on frame 44, about 1.79 seconds after frame 1. The source clock is 24 fps. The original moving section runs through frame 73; the MP4 intentionally holds this frame to 5.0 seconds.

Branding artwork and original motion/audio authored for AK Studio. Source scripts available under MIT. No third-party sound or imagery; the small open-font signature font has DejaVu's separate license.
