extends Label3D
## Billboard text with an opaque backing; shared by signs and NPC speech.
const FONT = preload("res://assets/outfit_medium.tres")
var backing: MeshInstance3D
var previous_text := ""

func _ready() -> void:
	font = FONT
	font_size = maxi(font_size, 24)
	outline_size = 0
	modulate = Color("f1f6f2")
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	render_priority = 2
	backing = MeshInstance3D.new()
	backing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	backing.mesh = QuadMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("18343c")
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.no_depth_test = true
	material.render_priority = 1
	# Alpha pipeline ensures priority sorting with the Label3D glyphs.
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	backing.material_override = material
	add_child(backing)
	_resize()

func _process(_delta: float) -> void:
	if text != previous_text:
		_resize()

func _resize() -> void:
	previous_text = text
	var extent := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	backing.mesh.size = (extent + Vector2(24, 12)) * pixel_size
	backing.visible = not text.is_empty()
