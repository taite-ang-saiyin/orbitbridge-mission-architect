shader_type spatial;
render_mode specular_schlick_ggx;
uniform sampler2D terrain_noise : repeat_enable;
void fragment() {
	float terrain = texture(terrain_noise, UV * vec2(1.0, 1.0)).r;
	float latitude = abs(UV.y - 0.5) * 2.0;
	float land = smoothstep(0.49, 0.52, terrain);
	vec3 ocean = mix(vec3(0.018, 0.12, 0.25), vec3(0.025, 0.37, 0.5), smoothstep(0.41, 0.5, terrain));
	vec3 ground = mix(vec3(0.13, 0.34, 0.18), vec3(0.46, 0.44, 0.24), smoothstep(0.55, 0.72, terrain));
	vec3 color = mix(ocean, ground, land);
	color = mix(color, vec3(0.73, 0.85, 0.91), smoothstep(0.83, 0.97, latitude));
	float clouds = smoothstep(0.60, 0.72, texture(terrain_noise, UV * 2.0 + vec2(0.21, 0.12)).r);
	ALBEDO = mix(color, vec3(0.82, 0.9, 0.96), clouds * 0.65);
	ROUGHNESS = 0.8;
	EMISSION = color * 0.12;
}
