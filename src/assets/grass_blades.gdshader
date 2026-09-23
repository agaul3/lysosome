shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// Grass tufts drawn from a MultiMesh. Per-instance COLOR tints each tuft; the
// blade tips sway gently in a slow, spatially varying breeze.
uniform float sway = 0.045;
varying float tip;

void vertex() {
	tip = clamp(VERTEX.y / 0.35, 0.0, 1.0);
	vec3 world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float phase = TIME * 1.3 + world.x * 0.7 + world.z * 0.45;
	float bend = tip * tip * sway;
	VERTEX.x += sin(phase) * bend;
	VERTEX.z += cos(phase * 0.8) * bend * 0.6;
}
void fragment() {
	// Darker at the root so tufts sit in the lawn rather than on top of it.
	ALBEDO = COLOR.rgb * mix(0.62, 1.08, tip);
	ROUGHNESS = 0.9;
	SPECULAR = 0.1;
}
