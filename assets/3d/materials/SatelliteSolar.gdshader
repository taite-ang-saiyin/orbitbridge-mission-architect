shader_type spatial;
render_mode cull_disabled;
void fragment() {
 vec2 cells = UV * vec2(12.0, 24.0);
 vec2 edge = min(fract(cells), 1.0-fract(cells));
 float grid = 1.0-smoothstep(0.015,0.045,min(edge.x,edge.y));
 float bus = 1.0-smoothstep(0.015,0.025,abs(fract(UV.x*3.0)-0.5));
 vec3 blue = mix(vec3(0.012,0.035,0.12),vec3(0.055,0.17,0.38), UV.y);
 ALBEDO = mix(blue,vec3(0.26,0.42,0.56),max(grid*0.7,bus*0.5));
 METALLIC = 0.65;
 ROUGHNESS = 0.28;
}
