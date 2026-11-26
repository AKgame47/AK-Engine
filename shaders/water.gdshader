// SPDX-License-Identifier: MIT
// Copyright (c) 2026 AK Studio
shader_type spatial;
render_mode cull_back;

uniform vec4 shallow : source_color = vec4(0.10, 0.52, 0.50, 1.0);
uniform vec4 deep : source_color = vec4(0.025, 0.18, 0.29, 1.0);
uniform vec4 glint : source_color = vec4(0.60, 0.91, 0.83, 1.0);
uniform float wave_speed : hint_range(0.0, 2.0) = 0.62;
uniform float wave_scale : hint_range(0.1, 6.0) = 1.45;
varying vec2 water_position;

void vertex() {
	water_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = water_position * wave_scale;
	float t = TIME * wave_speed;
	float a = sin(p.x + p.y * 0.57 + t);
	float b = sin(p.y * 1.72 - p.x * 0.36 - t * 1.4);
	float bands = 0.5 + 0.25 * (a + b);
	float edge = pow(1.0 - clamp(NORMAL.z, 0.0, 1.0), 3.0);
	vec3 base = mix(deep.rgb, shallow.rgb, bands);
	ALBEDO = mix(base, glint.rgb, edge * 0.32 + smoothstep(0.83, 0.98, bands) * 0.24);
	SPECULAR = 0.35;
	ROUGHNESS = 0.27 + 0.13 * bands;
}
