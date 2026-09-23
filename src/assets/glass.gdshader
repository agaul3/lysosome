shader_type spatial;
render_mode diffuse_burley;
// Curtain-wall glazing drawn procedurally in world space: a mullion grid with
// a spandrel band at each floor, panes that reflect a sky gradient (brighter
// toward the top and at grazing angles), and slight per-pane variation, some
// with lit interiors or drawn blinds, as in architectural renders.
uniform vec4 frame_color : source_color = vec4(0.88, 0.89, 0.87, 1.0);
uniform vec4 sky_color : source_color = vec4(0.62, 0.78, 0.88, 1.0);
uniform vec4 deep_color : source_color = vec4(0.12, 0.22, 0.28, 1.0);
uniform vec4 interior_color : source_color = vec4(0.86, 0.80, 0.68, 1.0);
uniform float panel_width = 1.5;
uniform float floor_height = 4.2;
uniform float mullion = 0.045;
uniform float spandrel = 0.32;
varying vec3 world_position;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec2 uv = n.x > n.z ? world_position.zy : world_position.xy;
	if (n.y > 0.7) {
		uv = world_position.xz;
	}
	vec2 cell = vec2(uv.x / panel_width, uv.y / floor_height);
	vec2 f = fract(cell);
	vec2 id = floor(cell);
	float mx = mullion / panel_width;
	float my = mullion / floor_height;
	float frame = step(f.x, mx) + step(1.0 - mx, f.x) + step(f.y, spandrel / floor_height) + step(abs(f.y - 0.72), my);
	float view_facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - view_facing, 3.0);
	float height = clamp(world_position.y / 24.0, 0.0, 1.0);
	float variation = hash(id);
	vec3 pane = mix(deep_color.rgb, sky_color.rgb, 0.25 + 0.55 * height + 0.2 * variation);
	pane = mix(pane, sky_color.rgb * 1.1, fresnel * 0.6);
	// A few panes show a warm interior or drawn blinds.
	float lit = step(0.88, hash(id + 7.1));
	pane = mix(pane, interior_color.rgb * 0.8, lit * 0.45);
	bool is_frame = frame > 0.5 || n.y > 0.7;
	ALBEDO = is_frame ? frame_color.rgb : pane;
	ROUGHNESS = is_frame ? 0.45 : 0.06;
	METALLIC = is_frame ? 0.1 : 0.4;
	SPECULAR = is_frame ? 0.4 : 0.85;
}
