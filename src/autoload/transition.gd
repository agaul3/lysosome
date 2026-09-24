extends CanvasLayer
## Scene transitions: fade to the ink colour, swap the scene, fade back in.
## In headless runs (tests) the cover is instant so timing stays deterministic.
const COVER_SECONDS := 0.22
const REVEAL_SECONDS := 0.42
var veil: ColorRect
var tween: Tween

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	veil = ColorRect.new()
	veil.color = Color(0.043, 0.086, 0.11, 0.0)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

func _headless() -> bool:
	return DisplayServer.get_name() == "headless"

## Fades to opaque; await it before changing scenes.
func cover() -> void:
	if tween:
		tween.kill()
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	if _headless():
		veil.color.a = 1.0
		return
	tween = create_tween()
	tween.tween_property(veil, "color:a", 1.0, COVER_SECONDS * (1.0 - veil.color.a)).set_trans(Tween.TRANS_SINE)
	await tween.finished

## Fades the new scene in.
func reveal() -> void:
	if tween:
		tween.kill()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _headless():
		veil.color.a = 0.0
		return
	tween = create_tween()
	tween.tween_interval(0.05)
	tween.tween_property(veil, "color:a", 0.0, REVEAL_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
