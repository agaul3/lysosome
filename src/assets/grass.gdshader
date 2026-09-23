shader_type spatial;
render_mode diffuse_burley;
// Dense, short, vivid turf. Fine blade flecks are drawn procedurally in world
// space: each small cell holds one short blade at a random angle and shade,
// layered at two scales, over a very soft tonal variation. Nothing tiles, and
// the finest layer fades out before it can shimmer at a distance.
uniform vec4 turf_dark : source_color = vec4(0.12, 0.40, 0.09, 1.0);
uniform vec4 turf_mid : source_color = vec4(0.22, 0.56, 0.13, 1.0);
uniform vec4 turf_light : source_color = vec4(0.42, 0.72, 0.20, 1.0);
varying vec3 world_position;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
// Returns (blade coverage, blade shade) for one layer of blades.
vec2 blades(vec2 p) {
	vec2 cell = floor(p);
	float coverage = 0.0;
	float shade = 0.5;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 id = cell + vec2(float(x), float(y));
			vec2 r = hash2(id);
			vec2 center = id + r;
			float angle = r.x * 6.2831;
			vec2 dir = vec2(cos(angle), sin(angle));
			vec2 d = p - center;
			float along = dot(d, dir);
			float across = dot(d, vec2(-dir.y, dir.x));
			// Short tapered blade: about 0.9 cells long, thin across.
			float taper = 1.0 - smoothstep(0.0, 0.45, abs(along));
			float blade = taper * (1.0 - smoothstep(0.03, 0.09 * taper + 0.03, abs(across)));
			if (blade > coverage) {
				coverage = blade;
				shade = hash(id + 4.7);
			}
		}
	}
	return vec2(coverage, shade);
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = world_position.xz;
	// Very gentle broad variation, like light catching the pile differently.
	float broad = noise(p * 0.18) * 0.6 + noise(p * 0.6) * 0.4;
	vec3 color = mix(turf_mid.rgb * 0.94, turf_mid.rgb * 1.05, broad);
	float coarse_scale = 16.0;
	float fine_scale = 34.0;
	vec2 coarse = blades(p * coarse_scale);
	vec2 fine = blades(p * fine_scale + 11.3);
	float coarse_fade = 1.0 - smoothstep(0.35, 0.8, fwidth(p.x * coarse_scale));
	float fine_fade = 1.0 - smoothstep(0.25, 0.6, fwidth(p.x * fine_scale));
	vec3 coarse_color = mix(turf_dark.rgb, turf_light.rgb, coarse.y);
	vec3 fine_color = mix(turf_dark.rgb, turf_light.rgb, fine.y);
	color = mix(color, coarse_color, coarse.x * 0.75 * coarse_fade);
	color = mix(color, fine_color, fine.x * 0.55 * fine_fade);
	// Pile shading between blades.
	color *= 0.9 + 0.1 * max(coarse.x, fine.x);
	ALBEDO = color;
	ROUGHNESS = 0.92;
	SPECULAR = 0.15;
}
