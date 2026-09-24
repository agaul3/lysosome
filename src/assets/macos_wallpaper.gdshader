shader_type canvas_item;
render_mode unshaded;

// Original flowing coastal colour bands, drawn as pixel art (a coarse cell
// grid) to match the game's blocky style.
uniform vec2 cells = vec2(208.0, 130.0);
uniform float dim : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = (floor(UV * cells) + 0.5) / cells;
	vec3 color = mix(vec3(0.09, 0.17, 0.42), vec3(0.26, 0.51, 0.70), p.y);
	float wave = 0.53 + 0.21 * sin(p.x * 3.8 - 0.6) - 0.22 * p.x;
	color = mix(color, mix(vec3(0.78, 0.25, 0.34), vec3(0.98, 0.64, 0.45), p.x), smoothstep(wave - 0.12, wave - 0.09, p.y));
	color = mix(color, mix(vec3(0.31, 0.17, 0.49), vec3(0.67, 0.32, 0.56), p.x), smoothstep(wave + 0.04, wave + 0.065, p.y));
	color = mix(color, mix(vec3(0.08, 0.28, 0.50), vec3(0.29, 0.61, 0.71), p.x), smoothstep(wave + 0.20, wave + 0.22, p.y));
	color = mix(color, vec3(0.055, 0.15, 0.32), smoothstep(wave + 0.43, wave + 0.51, p.y));
	color += 0.045 * (1.0 - distance(p, vec2(0.75, 0.2)));
	color = floor(color * 20.0 + 0.5) / 20.0;
	COLOR = vec4(color * (1.0 - dim), 1.0);
}
