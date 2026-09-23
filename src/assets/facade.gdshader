shader_type spatial;
render_mode diffuse_burley;
// Matte architectural surfaces coloured per vertex (merged building meshes).
// A soft darkening near the ground plane grounds walls the way ambient
// occlusion does in architectural renders.
uniform float roughness = 0.82;
uniform float metallic = 0.0;
uniform float base_shade = 0.12;
varying vec3 world_position;
varying vec3 tint;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	tint = pow(COLOR.rgb, vec3(2.2)); // sRGB authored colours -> linear
}

void fragment() {
	float grounded = 1.0 - base_shade * (1.0 - smoothstep(0.0, 1.6, world_position.y));
	ALBEDO = tint * grounded;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = 0.4;
}
