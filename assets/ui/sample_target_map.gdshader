shader_type canvas_item;
void fragment() {
	vec3 source = texture(TEXTURE, UV).rgb;
	float land = smoothstep(-0.015, 0.055, max(source.r, source.g) - source.b);
	vec3 ocean = vec3(0.012, 0.055, 0.095);
	vec3 continent = mix(vec3(0.045, 0.20, 0.31), vec3(0.10, 0.39, 0.55), dot(source, vec3(0.299, 0.587, 0.114)));
	COLOR = vec4(mix(ocean, continent, land), 1.0);
}
