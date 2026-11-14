shader_type spatial;
render_mode unshaded, cull_front, blend_add, depth_draw_never;
void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.8);
	ALBEDO = vec3(0.02, 0.45, 1.0);
	ALPHA = rim * 0.45;
}
