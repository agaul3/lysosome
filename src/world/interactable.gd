extends Node3D
## Reusable interaction endpoint; content and behavior belong to its owning scene.
signal activated
@export var display_name := "Object"
@export_multiline var response := ""
@export var reach: float = 1.55
var marker: Label3D
## Off when the highlight dot would sit on the player (e.g. the seat they occupy).
var marker_enabled := true

func _ready() -> void:
	add_to_group("interactables")
	marker = Label3D.new()
	marker.text = "•"
	marker.font_size = 64
	marker.modulate = Color("a3ffe1")
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.position.y = 0.35
	marker.visible = false
	add_child(marker)

func set_highlighted(value: bool) -> void:
	marker.visible = value and marker_enabled

func interact() -> void:
	activated.emit()
