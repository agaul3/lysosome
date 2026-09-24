extends RefCounted
## The 64×64 character skin atlas, in the Minecraft layout: each box part is
## unwrapped as a cross (top, bottom above; right, front, left, back below).
##
## Face orientation, shared by the mesh builder and the painter (the
## character faces −Z; its right side is +X):
##   front   column 0 is the character's right edge, row 0 the top
##   back    column 0 is the character's left edge
##   right   (+X face) column 0 is the back edge, the last column the front
##   left    (−X face) column 0 is the front edge
##   top     column 0 is the right edge, row 0 the back edge
##   bottom  column 0 is the right edge, row 0 the front edge
## Base layers are opaque; "_overlay" parts are a slightly larger outer shell
## (hair volume, jackets, hats, glasses) whose empty pixels are transparent.
const SIZE := 64
## Pixel size in metres: 12 pixels of leg make the 0.64 m hip height.
const PIXEL := 0.64 / 12.0
const FACES := ["top", "bottom", "right", "front", "left", "back"]

## [u, v, width, height, depth] in pixels. Slim builds have 3-pixel arms.
static func part(name: String, slim := false) -> Array:
	var arm := 3 if slim else 4
	match name:
		"head": return [0, 0, 8, 8, 8]
		"head_overlay": return [32, 0, 8, 8, 8]
		"body": return [16, 16, 8, 12, 4]
		"body_overlay": return [16, 32, 8, 12, 4]
		"right_arm": return [40, 16, arm, 12, 4]
		"right_arm_overlay": return [40, 32, arm, 12, 4]
		"left_arm": return [32, 48, arm, 12, 4]
		"left_arm_overlay": return [48, 48, arm, 12, 4]
		"right_leg": return [0, 16, 4, 12, 4]
		"right_leg_overlay": return [0, 32, 4, 12, 4]
		"left_leg": return [16, 48, 4, 12, 4]
		"left_leg_overlay": return [0, 48, 4, 12, 4]
		# Spare regions of the atlas carry the hair and hat add-ons.
		"bun": return [24, 0, 4, 3, 4]
		"ponytail": return [0, 0, 2, 6, 2]
		"brim": return [56, 0, 8, 1, 3] # Its own face map (see faces_of): 8×3 top and underside.
	return []

## Face rectangles (pixels) of a part.
static func faces(p: Array) -> Dictionary:
	var u: int = p[0]
	var v: int = p[1]
	var w: int = p[2]
	var h: int = p[3]
	var d: int = p[4]
	return {
		"top": Rect2i(u + d, v, w, d),
		"bottom": Rect2i(u + d + w, v, w, d),
		"right": Rect2i(u, v + d, d, h),
		"front": Rect2i(u + d, v + d, w, h),
		"left": Rect2i(u + d + w, v + d, d, h),
		"back": Rect2i(u + 2 * d + w, v + d, w, h),
	}

## Face rectangles of a named part. The cap brim is too wide for a cross
## unwrap in the spare corner, so it packs its faces as rows there instead.
static func faces_of(name: String, slim := false) -> Dictionary:
	if name == "brim":
		return {
			"top": Rect2i(56, 0, 8, 3), "bottom": Rect2i(56, 3, 8, 3),
			"front": Rect2i(56, 6, 8, 1), "back": Rect2i(56, 6, 8, 1),
			"right": Rect2i(56, 7, 3, 1), "left": Rect2i(59, 7, 3, 1),
		}
	return faces(part(name, slim))

static func face(name: String, face_name: String, slim := false) -> Rect2i:
	return faces_of(name, slim)[face_name]
