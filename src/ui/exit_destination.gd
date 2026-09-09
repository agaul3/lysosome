extends Control
## Temporary scene proves the dorm transition. It contains no campus environment.
var return_button: Button
var title_button: Button

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	center.add_child(layout)
	var heading := Label.new()
	heading.text = "Ready for the day"
	heading.add_theme_font_size_override("font_size", 38)
	layout.add_child(heading)
	var note := Label.new()
	note.text = "You left the dorm.

This is the temporary transition destination.
The campus arrives in Milestone 3."
	note.add_theme_font_size_override("font_size", 22)
	layout.add_child(note)
	return_button = Button.new()
	return_button.text = "Return to dorm"
	return_button.custom_minimum_size.y = 48
	return_button.pressed.connect(AppState.enter_dorm)
	layout.add_child(return_button)
	title_button = Button.new()
	title_button.text = "Return to title"
	title_button.custom_minimum_size.y = 48
	title_button.pressed.connect(AppState.return_to_title)
	layout.add_child(title_button)
	return_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel") and not event.is_echo():
		AppState.return_to_title()
		get_viewport().set_input_as_handled()
