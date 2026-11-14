shader_type spatial;
void fragment() {
 float edge = min(UV.y,1.0-UV.y);
 float trim = 1.0-smoothstep(0.025,0.04,edge);
 float seam = 1.0-smoothstep(0.006,0.012,abs(fract(UV.x*8.0)-0.5));
 float foil = sin(UV.x*180.0 + sin(UV.y*110.0)*1.8)*sin(UV.y*240.0)*0.025;
 vec3 gold = vec3(0.63,0.43,0.18) + foil;
 ALBEDO = mix(gold,vec3(0.24,0.30,0.35),max(trim,seam*0.5));
 METALLIC = 0.68;
 ROUGHNESS = 0.38 + foil;
}
