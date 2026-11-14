shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_never;
uniform sampler2D cloud_noise : repeat_enable;
void fragment() {
 float cloud = texture(cloud_noise, UV * vec2(3.0, 2.0)).r;
 float wisps = texture(cloud_noise, UV * vec2(12.0, 8.0) + vec2(0.3)).r;
 ALBEDO = vec3(0.89, 0.94, 1.0);
 ALPHA = smoothstep(0.53, 0.76, cloud * 0.8 + wisps * 0.2) * 0.72;
 ROUGHNESS = 1.0;
}
