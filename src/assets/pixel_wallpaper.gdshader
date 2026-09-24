shader_type canvas_item;
// Re-renders a photo as crisp pixel art to match the game's blocky style:
// each cell averages the source under it (so a low-resolution photo gives
// clean blocks instead of an upscaled blur), colours snap to a small set of
// levels, and a light ordered dither keeps gradients from banding.
// `source` crops the image (UV x, y, w, h), and `patch` covers a region
// (e.g. icons baked into a screenshot) with pixels from `patch_offset` away.
uniform vec2 cells = vec2(320.0, 180.0);
uniform float levels = 18.0;
uniform float dither = 0.6;
uniform vec4 source = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 patch = vec4(-1.0, -1.0, 0.0, 0.0);
uniform vec2 patch_offset = vec2(0.0);
uniform float dim : hint_range(0.0, 1.0) = 0.0;
uniform float saturation = 1.08;

// Maps a cell UV to the source image (crop, then the covering patch).
vec2 source_uv(vec2 uv) {
	vec2 p = source.xy + uv * source.zw;
	if (p.x > patch.x && p.x < patch.x + patch.z && p.y > patch.y && p.y < patch.y + patch.w) {
		p += patch_offset;
	}
	return p;
}

void fragment() {
	vec2 cell = floor(UV * cells);
	vec2 step_uv = 1.0 / cells;
	vec2 base = cell * step_uv;
	// Four taps per cell: an average of the photo beneath it.
	vec3 color = (texture(TEXTURE, source_uv(base + step_uv * vec2(0.25, 0.25))).rgb + texture(TEXTURE, source_uv(base + step_uv * vec2(0.75, 0.25))).rgb
		+ texture(TEXTURE, source_uv(base + step_uv * vec2(0.25, 0.75))).rgb + texture(TEXTURE, source_uv(base + step_uv * vec2(0.75, 0.75))).rgb) * 0.25;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(grey), color, saturation);
	// 4×4 Bayer dither, applied per cell.
	int x = int(mod(cell.x, 4.0));
	int y = int(mod(cell.y, 4.0));
	int index = x + y * 4;
	float bayer[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	float threshold = (bayer[index] / 16.0 - 0.5) * dither / levels;
	color = floor((color + threshold) * levels + 0.5) / levels;
	color *= 1.0 - dim;
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
