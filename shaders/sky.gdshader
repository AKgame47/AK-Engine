// SPDX-License-Identifier: MIT
// Copyright (c) 2026 AK Studio
shader_type sky;

uniform vec4 upper_sky : source_color = vec4(0.13, 0.37, 0.57, 1.0);
uniform vec4 horizon : source_color = vec4(0.65, 0.79, 0.83, 1.0);
uniform vec4 lower : source_color = vec4(0.35, 0.50, 0.52, 1.0);
uniform vec4 sun_tint : source_color = vec4(1.0, 0.82, 0.54, 1.0);
uniform vec3 sun_direction = vec3(-0.6, 0.35, -0.65);

void sky() {
	float y = EYEDIR.y;
	vec3 color = mix(horizon.rgb, upper_sky.rgb, smoothstep(0.0, 0.86, y));
	color = mix(color, lower.rgb, smoothstep(0.0, 0.35, -y));
	vec3 direction = normalize(sun_direction + vec3(0.0, 0.0001, 0.0));
	float facing = max(dot(EYEDIR, direction), 0.0);
	vec3 glow = sun_tint.rgb * (pow(facing, 18.0) * 0.20 + smoothstep(0.9986, 0.9994, facing) * 0.75);
	COLOR = color + glow;
}
