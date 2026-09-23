shader_type spatial;
render_mode diffuse_lambert_wrap, cull_disabled;
// Tree and shrub foliage (MultiMesh). Vertex colour x instance colour gives
// per-plant variety; crowns sway very gently, more toward the top.
uniform float sway = 0.035;
varying vec3 tint;

void vertex() {
	// Slightly lifted from sRGB so crowns stay bright and leafy under the sun.
	tint = pow(COLOR.rgb, vec3(1.35));
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float lift = max(VERTEX.y - 1.2, 0.0);
	float phase = TIME * 0.9 + origin.x * 0.37 + origin.z * 0.23;
	VERTEX.x += sin(phase) * sway * lift * 0.25;
	VERTEX.z += cos(phase * 0.8) * sway * lift * 0.18;
}

void fragment() {
	ALBEDO = tint;
	// A little light passes through leaves: lift the shaded side.
	EMISSION = tint * 0.07;
	ROUGHNESS = 0.92;
	SPECULAR = 0.2;
}
