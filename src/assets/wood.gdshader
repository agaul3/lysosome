shader_type spatial;
render_mode diffuse_burley;
uniform vec4 wood_color : source_color = vec4(0.61, 0.40, 0.23, 1.0);
uniform bool floor_planks = false;
varying vec3 local_position;
varying vec3 local_normal;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 f = fract(point);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x), mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}
void fragment() {
	vec3 normal_axis = abs(local_normal);
	vec2 wood_uv = local_position.xz;
	if (normal_axis.z > 0.5) { wood_uv = local_position.xy; }
	if (normal_axis.x > 0.5) { wood_uv = local_position.zy; }
	float board = floor((wood_uv.x + 5.0) / 0.72);
	float board_offset = hash(vec2(board, 7.0));
	vec2 grain_uv = wood_uv + vec2(board_offset * 3.0, board_offset * 8.0);
	float broad = noise(grain_uv * vec2(3.5, 0.38));
	float warp = noise(grain_uv * vec2(2.8, 0.55));
	float grain = sin(grain_uv.x * 105.0 + warp * 14.0 + sin(grain_uv.y * 1.4) * 2.0);
	grain *= 1.0 - smoothstep(0.6, 2.0, fwidth(grain_uv.x * 105.0));
	float fine = noise(grain_uv * vec2(130.0, 3.0));
	float tone = 0.94 + broad * 0.10 + grain * 0.025 + fine * 0.035;
	if (floor_planks) {
		float across = fract((wood_uv.x + 5.0) / 0.72);
		float along = fract((wood_uv.y + board_offset * 3.8) / 3.8);
		float edge = min(across, 1.0 - across) * 0.72;
		float end = min(along, 1.0 - along) * 3.8;
		float joint = 1.0 - smoothstep(0.002, 0.009, min(edge, end));
		tone *= 0.97 + board_offset * 0.055;
		tone *= 1.0 - joint * 0.16;
	}
	ALBEDO = wood_color.rgb * tone;
	ROUGHNESS = 0.88 + broad * 0.1;
	SPECULAR = 0.18;
}
