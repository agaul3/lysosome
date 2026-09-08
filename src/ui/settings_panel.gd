extends VBoxContainer
## Session-only settings; deliberately independent from future gameplay save data.
signal closed
var volume_slider: HSlider
var fullscreen_toggle: CheckButton
var back_button: Button

func _ready() -> void:
	add_theme_constant_override("separation", 16)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)
	var note := Label.new()
	note.text = "Applies immediately for this session."
	add_child(note)
	var volume_label := Label.new()
	volume_label.text = "Master volume"
	add_child(volume_label)
	volume_slider = HSlider.new()
	volume_slider.name = "MasterVolume"
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.value = AudioServer.get_bus_volume_linear(0) * 100.0
	volume_slider.custom_minimum_size.y = 36
	volume_slider.value_changed.connect(_set_volume)
	add_child(volume_slider)
	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "Fullscreen"
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_set_fullscreen)
	add_child(fullscreen_toggle)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size.y = 48
	back_button.pressed.connect(func() -> void: closed.emit())
	add_child(back_button)

func _set_volume(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, value / 100.0)

func _set_fullscreen(enabled: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
