shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
void fragment() {
 float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 4.5);
 ALBEDO = vec3(0.07, 0.38, 0.8);
 ALPHA = rim * 0.35;
}
