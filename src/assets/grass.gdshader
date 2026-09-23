shader_type spatial;
render_mode diffuse_burley;
// Lawn ground: soft, non-repeating tonal variation in world space. Patches are
// broad and low contrast so the lawn never reads as a tiled pattern.
uniform vec4 grass_color : source_color = vec4(0.44, 0.67, 0.46, 1.0);
uniform vec4 dry_color : source_color = vec4(0.62, 0.70, 0.45, 1.0);
uniform vec4 deep_color : source_color = vec4(0.30, 0.55, 0.38, 1.0);
varying vec3 world_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int octave = 0; octave < 4; octave++) {
		value += noise(p) * amplitude;
		p = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6)) * p;
		amplitude *= 0.5;
	}
	return value;
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = world_position.xz;
	float patches = fbm(p * 0.22);
	float clumps = fbm(p * 1.3 + 17.0);
	vec3 color = mix(deep_color.rgb, grass_color.rgb, smoothstep(0.25, 0.6, patches));
	color = mix(color, dry_color.rgb, smoothstep(0.62, 0.85, patches) * 0.45);
	// Fine blade speckle, faded out where it would alias at a distance.
	float speckle = noise(p * 38.0) * noise(p * 11.0 + 3.0);
	float fade = 1.0 - smoothstep(0.3, 1.2, fwidth(p.x * 38.0));
	color *= 0.93 + clumps * 0.1 + (speckle - 0.25) * 0.12 * fade;
	ALBEDO = color;
	ROUGHNESS = 0.95;
	SPECULAR = 0.12;
}
