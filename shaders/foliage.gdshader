// SPDX-License-Identifier: MIT
// Copyright (c) 2026 AK Studio
shader_type spatial;
render_mode cull_disabled;

uniform vec4 young_leaf : source_color = vec4(0.48, 0.66, 0.22, 1.0);
uniform vec4 shaded_leaf : source_color = vec4(0.08, 0.25, 0.16, 1.0);
uniform float wind_speed : hint_range(0.0, 4.0) = 1.5;
uniform float wind_amount : hint_range(0.0, 0.5) = 0.14;

void vertex() {
	float tip = 1.0 - UV.y;
	vec3 center = MODEL_MATRIX[3].xyz;
	float phase = center.x * 1.9 + center.z * 1.4;
	VERTEX.x += sin(TIME * wind_speed + phase) * wind_amount * tip * tip;
}

void fragment() {
	float t = 1.0 - UV.y;
	float curve = 0.46 + 0.16 * t * t;
	float width = 0.26 * (1.0 - t) + 0.014;
	if (abs(UV.x - curve) > width) {
		discard;
	}
	ALBEDO = mix(shaded_leaf.rgb, young_leaf.rgb, t);
	ROUGHNESS = 0.92;
}
