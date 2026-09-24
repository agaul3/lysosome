shader_type spatial;
render_mode unshaded, cull_back;
// An idle monitor: the lock-screen photo as pixel art, slightly dimmed.
uniform sampler2D image : source_color, filter_linear;
uniform vec2 cells = vec2(160.0, 90.0);
uniform float levels = 16.0;
uniform float brightness = 0.8;

void fragment() {
	vec2 cell = floor(UV * cells);
	vec2 s = 1.0 / cells;
	vec2 b = cell * s;
	vec3 c = (texture(image, b + s * 0.25).rgb + texture(image, b + s * vec2(0.75, 0.25)).rgb
		+ texture(image, b + s * vec2(0.25, 0.75)).rgb + texture(image, b + s * 0.75).rgb) * 0.25;
	c = floor(c * levels + 0.5) / levels;
	ALBEDO = c * brightness;
}
