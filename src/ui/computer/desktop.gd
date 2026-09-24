extends CanvasLayer
## Simulated desktop: local demo credentials only, no network authentication.
signal closed
const UI = preload("res://ui/style/ui_style.gd")
const AnkiApp = preload("res://ui/computer/anki_app.gd")
const WINDOWS_LOCK = preload("res://assets/windows_lock.png")
const WINDOWS_HOME = preload("res://assets/windows_desktop.png")
var os_style := "windows"
var root: Control
var area: VBoxContainer
var margins: MarginContainer
var username: LineEdit
var password: LineEdit
var login_error: Label
var app: VBoxContainer
var logged_in := false
var screen := "lock"
var wallpaper: TextureRect
var mac_wallpaper: ColorRect
var shade: ColorRect
var clock_label: Label
var date_label: Label
var desktop_clock: Label
var clock_elapsed := 0.0
var account_panel: PanelContainer

func _ready() -> void:
	layer = 8
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.theme()
	add_child(root)
	wallpaper = TextureRect.new()
	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wallpaper)
	mac_wallpaper = ColorRect.new()
	mac_wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mac_wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/macos_wallpaper.gdshader")
	mac_wallpaper.material = material
	root.add_child(mac_wallpaper)
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	margins = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(margins)
	area = VBoxContainer.new()
	margins.add_child(area)
	show_lock()

func clear(next_screen: String) -> void:
	screen = next_screen
	app = null
	clock_label = null
	date_label = null
	desktop_clock = null
	account_panel = null
	Flashcards.end_review()
	for child in area.get_children():
		area.remove_child(child)
		child.queue_free()
	for side in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, 24 if screen == "app" else 0)
	area.add_theme_constant_override("separation", 10 if screen == "app" else 0)
	wallpaper.visible = os_style == "windows"
	mac_wallpaper.visible = os_style == "macos"
	wallpaper.texture = WINDOWS_LOCK if screen in ["lock", "login"] else WINDOWS_HOME
	# Preserve the supplied desktop screenshot's full composition, including its icons.
	wallpaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if screen in ["lock", "login"] else TextureRect.STRETCH_SCALE
	shade.color = Color(0, 0, 0, 0.38 if screen == "login" else (0.10 if screen == "lock" else 0.0))

func stage() -> Control:
	var result := Control.new()
	result.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.add_child(result)
	return result

func light_button(value: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = value
	for state in ["normal", "hover", "pressed"]:
		result.add_theme_stylebox_override(state, UI.box(Color(1, 1, 1, 0.18 if state == "hover" else 0.07), 6, Color(1, 1, 1, 0.18), 1, Vector4(14, 8, 14, 8)))
	result.pressed.connect(callback)
	return result

func close_control(parent: Control) -> void:
	var button := light_button("Close computer  ·  Esc", close)
	parent.add_child(button)
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	button.position += Vector2(-18, 16)

func show_lock() -> void:
	clear("lock")
	logged_in = false
	var canvas := stage()
	canvas.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_viewport().set_input_as_handled()
			show_login.call_deferred())
	close_control(canvas)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	canvas.add_child(stack)
	if os_style == "windows":
		stack.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		stack.grow_vertical = Control.GROW_DIRECTION_BEGIN
		stack.position += Vector2(46, -68)
	else:
		stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		stack.grow_horizontal = Control.GROW_DIRECTION_BOTH
		stack.position.y = 76
	clock_label = UI.label("", 92 if os_style == "windows" else 106, Color.WHITE, 400 if os_style == "windows" else 600)
	date_label = UI.label("", 28 if os_style == "windows" else 23, Color.WHITE, 400)
	if os_style == "macos":
		clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(date_label)
		stack.add_child(clock_label)
	else:
		stack.add_child(clock_label)
		stack.add_child(date_label)
	_refresh_clock()
	var unlock := light_button("Click or press Enter to sign in", show_login)
	canvas.add_child(unlock)
	unlock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	unlock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	unlock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	unlock.position.y -= 22

func _avatar() -> Control:
	var avatar := Control.new()
	avatar.custom_minimum_size = Vector2(90, 90)
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.draw.connect(func() -> void:
		avatar.draw_circle(Vector2(45, 45), 44, Color(0.8, 0.86, 0.94, 0.35))
		avatar.draw_circle(Vector2(45, 32), 14, Color("edf2f8"))
		avatar.draw_style_box(UI.box(Color("edf2f8"), 22, Color.TRANSPARENT, 0, Vector4.ZERO), Rect2(19, 51, 52, 25)))
	return avatar

func show_login() -> void:
	clear("login")
	logged_in = false
	var canvas := stage()
	close_control(canvas)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(center)
	# No large card: the supplied photo remains the lock/sign-in background.
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 300
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	column.add_child(_avatar())
	var title := UI.label("player1", 32, Color.WHITE, 500)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	username = AnkiApp.field("Username")
	username.name = "Username"
	username.text = "player1"
	column.add_child(username)
	password = AnkiApp.field("Password")
	password.name = "Password"
	password.secret = true
	column.add_child(password)
	password.text_submitted.connect(func(_value: String) -> void: sign_in())
	username.text_submitted.connect(func(_value: String) -> void: password.grab_focus())
	column.add_child(light_button("Sign in  →", sign_in))
	login_error = UI.label("", 14, Color("ffcabf"))
	login_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(login_error)
	var hint := UI.label("Demo password: 122333", 13, Color("e0e7f0"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	password.grab_focus()

func sign_in() -> bool:
	if screen != "login":
		return false
	if username.text.strip_edges() != "player1" or password.text != "122333":
		login_error.text = "Incorrect username or password."
		password.clear()
		password.grab_focus()
		return false
	logged_in = true
	show_desktop()
	return true

func _app_icon(callback: Callable) -> Button:
	var icon := Button.new()
	icon.text = "★"
	icon.custom_minimum_size = Vector2(56, 56)
	icon.add_theme_font_size_override("font_size", 36)
	icon.add_theme_color_override("font_color", Color.WHITE)
	for state in ["normal", "hover", "pressed"]:
		icon.add_theme_stylebox_override(state, UI.box(Color("57a4ed") if state == "hover" else Color("3283d6"), 13, Color("9fd0ff"), 1, Vector4.ZERO))
	icon.tooltip_text = "Anki — Spaced repetition"
	icon.pressed.connect(callback)
	return icon

func show_desktop() -> void:
	if not logged_in:
		return
	clear("desktop")
	var canvas := stage()
	var shortcut := VBoxContainer.new()
	shortcut.add_theme_constant_override("separation", 5)
	canvas.add_child(shortcut)
	if os_style == "windows":
		shortcut.position = Vector2(22, 208) # Below the icons already present in the supplied image.
	else:
		shortcut.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		shortcut.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		shortcut.position += Vector2(-36, 90)
	var app_icon := _app_icon(open_anki)
	shortcut.add_child(app_icon)
	var label := UI.label("Anki", 14, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("outline_size", 3)
	shortcut.add_child(label)
	if os_style == "windows":
		_windows_taskbar(canvas)
	else:
		_mac_bars(canvas)
	close_control(canvas)
	_refresh_clock()

func _windows_taskbar(canvas: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(Color("172432"), 0, Color.TRANSPARENT, 0, Vector4(8, 4, 12, 4)))
	canvas.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -50
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(light_button("▦", show_account))
	row.add_child(AnkiApp.button("Search apps  ·  Anki", open_anki))
	row.add_child(light_button("★  Anki", open_anki))
	row.add_child(UI.spacer(0, 0, true))
	row.add_child(light_button("Lock", show_lock))
	desktop_clock = UI.label("", 13, Color.WHITE)
	desktop_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(desktop_clock)

func _mac_bars(canvas: Control) -> void:
	var menu := PanelContainer.new()
	menu.add_theme_stylebox_override("panel", UI.box(Color(0.08, 0.12, 0.22, 0.52), 0, Color.TRANSPARENT, 0, Vector4(16, 4, 220, 4)))
	canvas.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var row := HBoxContainer.new()
	menu.add_child(row)
	row.add_child(UI.label("●   Finder     File     Edit     View     Go     Window     Help", 14, Color.WHITE, 600))
	row.add_child(UI.spacer(0, 0, true))
	desktop_clock = UI.label("", 13, Color.WHITE)
	row.add_child(desktop_clock)
	var dock := PanelContainer.new()
	dock.add_theme_stylebox_override("panel", UI.box(Color(0.75, 0.84, 0.95, 0.25), 18, Color(1, 1, 1, 0.35), 1, Vector4(10, 8, 10, 8)))
	canvas.add_child(dock)
	dock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.position.y -= 12
	var icons := HBoxContainer.new()
	icons.add_theme_constant_override("separation", 12)
	dock.add_child(icons)
	icons.add_child(AnkiApp.button("Finder", show_account))
	icons.add_child(_app_icon(open_anki))
	icons.add_child(light_button("Lock", show_lock))

func show_account() -> void:
	if is_instance_valid(account_panel):
		account_panel.queue_free()
		account_panel = null
		return
	account_panel = PanelContainer.new()
	account_panel.add_theme_stylebox_override("panel", UI.box(Color("182936"), 12, UI.LINE, 1, Vector4(22, 18, 22, 18)))
	var canvas := area.get_child(0) as Control
	canvas.add_child(account_panel)
	account_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	account_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	account_panel.position += Vector2(12, -64)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	account_panel.add_child(column)
	column.add_child(UI.label("player1", 23))
	column.add_child(UI.label("Local student account", 14, UI.TEXT_MUTED))
	column.add_child(light_button("Open Anki", open_anki))
	column.add_child(light_button("Lock computer", show_lock))

func top_bar(title: String) -> void:
	var row := HBoxContainer.new()
	area.add_child(row)
	row.add_child(UI.label(title, 15, Color.WHITE, 600))
	row.add_child(UI.spacer(0, 0, true))
	row.add_child(light_button("Close computer  ·  Esc", close))

func open_anki() -> void:
	if not logged_in:
		return
	clear("app")
	top_bar("Windows  /  Anki" if os_style == "windows" else "●  Anki     File     Edit     Tools     Help")
	var window := PanelContainer.new()
	window.size_flags_vertical = Control.SIZE_EXPAND_FILL
	window.add_theme_stylebox_override("panel", UI.box(Color("f8fafc"), 12 if os_style == "macos" else 5, Color("a6b8ce"), 1, Vector4(24, 14, 24, 18)))
	area.add_child(window)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	window.add_child(column)
	var chrome := HBoxContainer.new()
	column.add_child(chrome)
	if os_style == "macos":
		for color in [Color("ff6059"), Color("ffbd2e"), Color("28c840")]:
			chrome.add_child(UI.label("●", 18, color))
	chrome.add_child(UI.label("Anki — player1", 14, AnkiApp.INK))
	chrome.add_child(UI.spacer(0, 0, true))
	chrome.add_child(AnkiApp.button("Desktop", show_desktop))
	app = AnkiApp.new()
	column.add_child(app)

func _refresh_clock() -> void:
	var now := Time.get_datetime_dict_from_system()
	var time := "%d:%02d" % [now.hour, now.minute]
	var weekdays := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
	var months := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	if is_instance_valid(clock_label):
		clock_label.text = time
	if is_instance_valid(date_label):
		date_label.text = "%s, %s %d" % [weekdays[now.weekday], months[now.month - 1], now.day]
	if is_instance_valid(desktop_clock):
		desktop_clock.text = "%s\n%d/%d/%d" % [time, now.month, now.day, now.year] if os_style == "windows" else "%s %d   %s" % [months[now.month - 1].left(3), now.day, time]

func _process(delta: float) -> void:
	clock_elapsed += delta
	if clock_elapsed >= 1.0:
		clock_elapsed = 0.0
		_refresh_clock()

func close() -> void:
	Flashcards.end_review()
	SaveGame.autosave()
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif screen == "lock" and event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		show_login()
	elif is_instance_valid(app) and app.shortcut(event):
		get_viewport().set_input_as_handled()

func _unhandled_input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
