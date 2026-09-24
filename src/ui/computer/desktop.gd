extends CanvasLayer
## A usable in-game computer: the dorm PC (a Windows 10–style desktop) or the
## student's MacBook (a macOS-style desktop). Local demo credentials only
## (player1 / 122333); nothing leaves the game.
##
## The operating system is drawn into a SubViewport shown on the device's
## own screen in the world, and the camera eases in to a seated eye point so
## the screen fills about two thirds of the view: you still see the desk, the
## keyboard and the room around it. The mouse is traced onto the screen and
## keys are forwarded to it; nothing reaches the world while it is open.
## With no world screen (a fallback), the display floats in front of a dimmed
## view instead. The layout is 1024×576 (PC) or 1024×640 (Mac), rendered
## sharper on large windows.
signal closed
const Kit = preload("res://ui/computer/os_kit.gd")
const OSWindow = preload("res://ui/computer/os_window.gd")
const AnkiApp = preload("res://ui/computer/anki_app.gd")
const LectureCamera = preload("res://world/lecture_camera.gd")
const KeyPrompt = preload("res://ui/key_prompt.gd")
const UI = preload("res://ui/style/ui_style.gd")
const WINDOWS_LOCK = preload("res://assets/windows_lock.png")
const WINDOWS_HOME = preload("res://assets/windows_desktop.png")
const PIXEL_SHADER = preload("res://assets/pixel_wallpaper.gdshader")
const SIZES := {"windows": Vector2(1024, 576), "macos": Vector2(1024, 640)}
const USERNAME := "player1"
const PASSWORD := "122333"
## Share of the view's height the screen fills once zoomed in.
const SCREEN_FILL := {"windows": 0.6, "macos": 0.58}
const VIEW_FOV := 46.0
const TASKBAR := 40.0
const MENU_BAR := 26.0
var os_style := "windows"
## Set by the HUD: the player (their head is hidden while zoomed in) and the
## screen quad the OS is drawn onto.
var player: Node3D
var screen_mesh: MeshInstance3D
var viewport: SubViewport
var root: Control
var wallpaper: TextureRect
var mac_wallpaper: ColorRect
var content: Control
var username: LineEdit
var password: LineEdit
var login_error: Label
var app: Control
var app_window: PanelContainer
var logged_in := false
var screen := "lock"
var camera: Camera3D
var fallback: TextureRect
var clock_label: Label
var date_label: Label
var desktop_clock: Label
var menu_popup: Control
var taskbar_anki: Button
var dock_anki_dot: Control
var app_name_label: Label
var mac_menus: HBoxContainer
var clock_elapsed := 0.0
var closing := false
var _saved_material: Material
var _selected_icon: Control
var _press_inside := false

func _ready() -> void:
	layer = 8
	_build_viewport()
	if is_instance_valid(screen_mesh):
		_bind_screen()
	else:
		_build_fallback()
	_build_overlay()
	show_lock()

func screen_size() -> Vector2:
	return SIZES[os_style]

func headless() -> bool:
	return DisplayServer.get_name() == "headless"

# --- Viewport, screen, camera --------------------------------------------------------

func _build_viewport() -> void:
	var logical: Vector2 = SIZES[os_style]
	# Render sharper when the window is large; the layout stays logical-sized.
	var window_height := float(get_viewport().get_visible_rect().size.y) * get_viewport().get_final_transform().get_scale().y
	var fill: float = SCREEN_FILL[os_style]
	var sharpness := clampf(window_height * fill / logical.y * 1.25, 1.0, 2.0)
	viewport = SubViewport.new()
	viewport.name = "Screen"
	viewport.size = Vector2i(logical * sharpness)
	viewport.size_2d_override = Vector2i(logical)
	viewport.size_2d_override_stretch = true
	viewport.disable_3d = true
	viewport.gui_embed_subwindows = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	root = Control.new()
	root.name = "OS"
	root.size = logical
	root.theme = _theme()
	viewport.add_child(root)
	wallpaper = TextureRect.new()
	wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wallpaper.stretch_mode = TextureRect.STRETCH_SCALE
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallpaper.material = ShaderMaterial.new()
	wallpaper.material.shader = PIXEL_SHADER
	root.add_child(wallpaper)
	mac_wallpaper = ColorRect.new()
	mac_wallpaper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mac_wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mac_wallpaper.material = ShaderMaterial.new()
	mac_wallpaper.material.shader = preload("res://assets/macos_wallpaper.gdshader")
	root.add_child(mac_wallpaper)
	wallpaper.visible = os_style == "windows"
	mac_wallpaper.visible = os_style == "macos"
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(content)

## A light theme for controls inside the OS (fields, menus, spin boxes).
func _theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = Kit.font(os_style)
	theme.default_font_size = 14
	for type in ["Label", "Button", "LineEdit", "TextEdit", "OptionButton", "MenuButton", "PopupMenu", "SpinBox"]:
		theme.set_color("font_color", type, Color("1f1f1f"))
	theme.set_color("font_hover_color", "PopupMenu", Color("1f1f1f"))
	theme.set_color("font_disabled_color", "PopupMenu", Color("9a9a9a"))
	theme.set_stylebox("panel", "PopupMenu", Kit.box(Color("fbfbfb"), 8 if os_style == "macos" else 0, Color("c8c8c8"), 1, Vector4(4, 4, 4, 4)))
	theme.set_stylebox("hover", "PopupMenu", Kit.box(Color("2f6fcf") if os_style == "macos" else Color("e5f0fb"), 5 if os_style == "macos" else 0))
	theme.set_color("font_hover_color", "PopupMenu", Color.WHITE if os_style == "macos" else Color("1f1f1f"))
	for type in ["OptionButton", "Button", "MenuButton"]:
		theme.set_stylebox("normal", type, Kit.box(Color("fdfdfd"), 6, Color("c4c4c4"), 1, Vector4(10, 5, 10, 5)))
		theme.set_stylebox("hover", type, Kit.box(Color("f0f4fa"), 6, Color("c4c4c4"), 1, Vector4(10, 5, 10, 5)))
		theme.set_stylebox("pressed", type, Kit.box(Color("e2e8f0"), 6, Color("c4c4c4"), 1, Vector4(10, 5, 10, 5)))
		theme.set_stylebox("focus", type, StyleBoxEmpty.new())
		theme.set_color("font_hover_color", type, Color("1f1f1f"))
		theme.set_color("font_pressed_color", type, Color("1f1f1f"))
	theme.set_stylebox("normal", "LineEdit", Kit.box(Color.WHITE, 5, Color("c4c4c4"), 1, Vector4(8, 5, 8, 5)))
	theme.set_stylebox("focus", "LineEdit", Kit.box(Color.WHITE, 5, Color("2f6fcf"), 2, Vector4(8, 5, 8, 5)))
	theme.set_color("caret_color", "LineEdit", Color("1f1f1f"))
	theme.set_stylebox("panel", "TooltipPanel", Kit.box(Color("ffffe8") if os_style == "windows" else Color("f5f5f5"), 4, Color("a0a0a0"), 1, Vector4(8, 4, 8, 4)))
	theme.set_color("font_color", "TooltipLabel", Color("1f1f1f"))
	return theme

## Draws the OS onto the world screen and eases the camera in to it.
func _bind_screen() -> void:
	_saved_material = screen_mesh.material_override
	var surface := StandardMaterial3D.new()
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	surface.albedo_texture = viewport.get_texture()
	surface.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	screen_mesh.material_override = surface
	var source := get_viewport().get_camera_3d()
	if not is_instance_valid(source):
		return
	camera = LectureCamera.new()
	camera.name = "ComputerCamera"
	camera.target_fov = VIEW_FOV
	camera.arc_height = 0.0
	camera.duration = 0.001 if headless() else 0.7
	screen_mesh.get_tree().current_scene.add_child(camera)
	var pose := view_pose()
	camera.focus_distance = pose.origin.distance_to(screen_mesh.global_position)
	camera.enter(source, pose)
	if is_instance_valid(player) and "first_person" in player:
		player.first_person.set_head_hidden(true)

## Where the eyes sit: square to the screen, a little above its centre, at
## the distance where it fills SCREEN_FILL of the view's height.
func view_pose() -> Transform3D:
	var quad := screen_mesh.mesh as QuadMesh
	var basis := screen_mesh.global_basis
	var height := quad.size.y * basis.y.length()
	var normal := basis.z.normalized()
	var up := basis.y.normalized()
	var center := screen_mesh.global_position
	var fill: float = SCREEN_FILL[os_style]
	var distance := height / (2.0 * tan(deg_to_rad(VIEW_FOV) / 2.0) * fill)
	var eye := center + normal * distance + up * height * 0.1
	return Transform3D(Basis.looking_at(center - eye, Vector3.UP), eye)

## Without a world screen: the display floats over a dimmed view.
func _build_fallback() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	fallback = TextureRect.new()
	fallback.texture = viewport.get_texture()
	fallback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fallback.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		fallback.set("offset_" + side, 90.0 if side == "left" else -90.0)
	fallback.offset_top = 60
	fallback.offset_bottom = -70
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fallback)

## A small reminder under the view: how to step away.
func _build_overlay() -> void:
	var hint := HBoxContainer.new()
	hint.add_theme_constant_override("separation", 8)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.position.y -= 14
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key := KeyPrompt.new()
	key.key = "Esc"
	hint.add_child(key)
	var words := UI.label("Step away from the " + ("computer" if os_style == "windows" else "laptop"), UI.SIZE_LABEL, UI.TEXT, 500)
	words.add_theme_color_override("font_outline_color", Color(UI.INK, 0.9))
	words.add_theme_constant_override("outline_size", 5)
	hint.add_child(words)
	add_child(hint)

# --- Input -------------------------------------------------------------------------

## The screen position (in viewport pixels) under a window position, or
## Vector2.INF when the pointer is off the display.
func screen_point(window_position: Vector2, clamp_to_screen := false) -> Vector2:
	var uv := Vector2.INF
	if is_instance_valid(fallback):
		var rect := _fallback_rect()
		uv = (window_position - rect.position) / rect.size
	elif is_instance_valid(screen_mesh):
		var view := get_viewport().get_camera_3d()
		if not is_instance_valid(view):
			return Vector2.INF
		var origin := view.project_ray_origin(window_position)
		var direction := view.project_ray_normal(window_position)
		var xf := screen_mesh.global_transform
		var normal := xf.basis.z.normalized()
		var denominator := normal.dot(direction)
		if absf(denominator) < 0.00001:
			return Vector2.INF
		var distance := normal.dot(xf.origin - origin) / denominator
		if distance < 0.0:
			return Vector2.INF
		var local := xf.affine_inverse() * (origin + direction * distance)
		var quad := (screen_mesh.mesh as QuadMesh).size
		uv = Vector2(local.x / quad.x + 0.5, 0.5 - local.y / quad.y)
	if uv == Vector2.INF:
		return uv
	if clamp_to_screen:
		uv = uv.clamp(Vector2.ZERO, Vector2.ONE)
	elif uv.x < 0.0 or uv.y < 0.0 or uv.x > 1.0 or uv.y > 1.0:
		return Vector2.INF
	return uv * Vector2(viewport.size)

func _fallback_rect() -> Rect2:
	var rect := fallback.get_global_rect()
	var aspect := float(viewport.size.x) / viewport.size.y
	var fit := Vector2(rect.size.y * aspect, rect.size.y)
	if fit.x > rect.size.x:
		fit = Vector2(rect.size.x, rect.size.x / aspect)
	return Rect2(rect.position + (rect.size - fit) / 2.0, fit)

func _input(event: InputEvent) -> void:
	if closing:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if is_instance_valid(menu_popup):
				_close_menu()
			else:
				close()
			return
		if screen == "lock" and event.pressed and not event.echo:
			show_login()
			return
		if is_instance_valid(app) and app.editor_shortcut(event):
			return
		var typing := viewport.gui_get_focus_owner() is LineEdit or viewport.gui_get_focus_owner() is TextEdit
		if not typing and is_instance_valid(app) and app.shortcut(event):
			return
		viewport.push_input(event)
	elif event is InputEventMouse:
		var point := screen_point(event.position, false)
		if event is InputEventMouseButton:
			if event.pressed:
				_press_inside = point != Vector2.INF
				if not _press_inside:
					return
			elif not _press_inside:
				return
			else:
				point = screen_point(event.position, true)
		elif point == Vector2.INF:
			point = screen_point(event.position, true)
			if point == Vector2.INF:
				return
		var forwarded: InputEventMouse = event.duplicate()
		forwarded.position = point
		forwarded.global_position = point
		viewport.push_input(forwarded)

func _unhandled_input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

# --- Screens -----------------------------------------------------------------------

func clear(next_screen: String) -> void:
	screen = next_screen
	app = null
	app_window = null
	clock_label = null
	date_label = null
	desktop_clock = null
	menu_popup = null
	taskbar_anki = null
	dock_anki_dot = null
	app_name_label = null
	mac_menus = null
	_selected_icon = null
	Flashcards.end_review()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var windows := os_style == "windows"
	var locked := next_screen in ["lock", "login"]
	var shader := wallpaper.material as ShaderMaterial
	if windows:
		wallpaper.texture = WINDOWS_LOCK if locked else WINDOWS_HOME
		# The desktop photo is a screenshot: crop its taskbar and cover the
		# icons baked into its top-left corner with nearby sky.
		shader.set_shader_parameter("source", Vector4(0, 0, 1, 1) if locked else Vector4(0, 0, 1, 0.962))
		shader.set_shader_parameter("patch", Vector4(-1, -1, 0, 0) if locked else Vector4(0, 0, 0.055, 0.3))
		shader.set_shader_parameter("patch_offset", Vector2(0.07, 0.0))
		shader.set_shader_parameter("dim", 0.42 if next_screen == "login" else (0.06 if next_screen == "lock" else 0.0))
		shader.set_shader_parameter("cells", Vector2(320, 180))
	else:
		(mac_wallpaper.material as ShaderMaterial).set_shader_parameter("dim", 0.25 if locked else 0.0)

func _fade_in(node: CanvasItem) -> void:
	if headless():
		return
	node.modulate.a = 0.0
	create_tween().tween_property(node, "modulate:a", 1.0, 0.25)

func _big_clock(size: int, weight: int) -> Label:
	var result := Kit.label("", os_style, size, Color.WHITE, weight)
	result.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	result.add_theme_constant_override("shadow_offset_y", 2)
	return result

func show_lock() -> void:
	clear("lock")
	logged_in = false
	var canvas := _stage()
	canvas.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			show_login.call_deferred())
	var area := screen_size()
	clock_label = _big_clock(92 if os_style == "windows" else 96, 300 if os_style == "windows" else 700)
	date_label = _big_clock(26 if os_style == "windows" else 20, 400 if os_style == "windows" else 600)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", -8)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(stack)
	if os_style == "windows":
		stack.add_child(clock_label)
		stack.add_child(date_label)
		stack.position = Vector2(44, area.y - 200)
		var tray := HBoxContainer.new()
		tray.add_theme_constant_override("separation", 14)
		tray.position = Vector2(area.x - 96, area.y - 44)
		for icon in ["wifi", "power"]:
			tray.add_child(Kit.icon_rect(icon, 22))
		canvas.add_child(tray)
	else:
		date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(date_label)
		stack.add_child(clock_label)
		stack.size = Vector2(area.x, 150)
		stack.position = Vector2(0, 48)
		var who := _mac_identity()
		who.position = Vector2((area.x - 200) / 2.0, area.y - 220)
		canvas.add_child(who)
		var prompt := Kit.label("Click or press any key to unlock", os_style, 14, Color(1, 1, 1, 0.8))
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt.size = Vector2(area.x, 20)
		prompt.position = Vector2(0, area.y - 62)
		canvas.add_child(prompt)
	_refresh_clock()

func _stage() -> Control:
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(canvas)
	return canvas

func _avatar(edge: float) -> Control:
	var avatar := Control.new()
	avatar.custom_minimum_size = Vector2(edge, edge)
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var person := Kit.icon("person")
	avatar.draw.connect(func() -> void:
		var r := edge / 2.0
		avatar.draw_circle(Vector2(r, r), r, Color(0.78, 0.83, 0.9, 0.9) if os_style == "windows" else Color(0.62, 0.66, 0.72))
		avatar.draw_texture_rect(person, Rect2(edge * 0.15, edge * 0.12, edge * 0.7, edge * 0.7), false, Color("f4f7fb")))
	return avatar

func _mac_identity() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 200
	column.add_theme_constant_override("separation", 8)
	column.add_child(_avatar(72))
	var name := Kit.label(USERNAME, os_style, 17, Color.WHITE, 600)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name)
	return column

func _login_field(placeholder: String, secret: bool) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.secret = secret
	edit.custom_minimum_size = Vector2(296, 36) if os_style == "windows" else Vector2(220, 32)
	edit.add_theme_font_override("font", Kit.font(os_style))
	edit.add_theme_font_size_override("font_size", 16 if os_style == "windows" else 15)
	edit.add_theme_color_override("font_color", Color.WHITE)
	edit.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.65))
	edit.add_theme_color_override("caret_color", Color.WHITE)
	edit.add_theme_color_override("selection_color", Color(1, 1, 1, 0.3))
	if os_style == "windows":
		edit.add_theme_stylebox_override("normal", Kit.box(Color(0, 0, 0, 0.42), 0, Color(1, 1, 1, 0.55), 2, Vector4(10, 4, 10, 4)))
		edit.add_theme_stylebox_override("focus", Kit.box(Color(0, 0, 0, 0.5), 0, Color(1, 1, 1, 0.9), 2, Vector4(10, 4, 10, 4)))
	else:
		edit.add_theme_stylebox_override("normal", Kit.box(Color(1, 1, 1, 0.22), 14, Color(1, 1, 1, 0.12), 1, Vector4(12, 3, 12, 3)))
		edit.add_theme_stylebox_override("focus", Kit.box(Color(1, 1, 1, 0.3), 14, Color(1, 1, 1, 0.45), 1, Vector4(12, 3, 12, 3)))
		edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return edit

func show_login() -> void:
	clear("login")
	logged_in = false
	var canvas := _stage()
	var area := screen_size()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12 if os_style == "windows" else 8)
	canvas.add_child(column)
	username = _login_field("User name" if os_style == "windows" else "Name", false)
	username.name = "Username"
	username.text = USERNAME
	password = _login_field("Password" if os_style == "windows" else "Enter Password", true)
	password.name = "Password"
	login_error = Kit.label("", os_style, 14 if os_style == "windows" else 12, Color("ffd6cc"))
	login_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	login_error.custom_minimum_size.y = 20
	if os_style == "windows":
		column.custom_minimum_size.x = 340
		column.add_child(_avatar(150))
		var title := Kit.label(USERNAME, os_style, 34, Color.WHITE, 300)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(title)
		column.add_child(_centered(username))
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 0)
		password.custom_minimum_size.x = 262
		row.add_child(password)
		var go := Kit.flat_button("→", os_style, 18, Color.WHITE, [Color(1, 1, 1, 0.25), Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.55)], 0, Vector4(0, 0, 0, 0))
		go.custom_minimum_size = Vector2(34, 34)
		go.tooltip_text = "Submit"
		go.pressed.connect(sign_in)
		row.add_child(go)
		column.add_child(row)
		column.add_child(login_error)
		var options := Kit.label("Sign-in options", os_style, 14, Color(1, 1, 1, 0.8))
		options.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(options)
		var hint := Kit.label("Demo account  ·  password 122333", os_style, 12, Color(1, 1, 1, 0.55))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(hint)
		column.position = Vector2((area.x - 340) / 2.0, 70)
		var account := HBoxContainer.new()
		account.add_theme_constant_override("separation", 10)
		account.position = Vector2(20, area.y - 60)
		var tile := _avatar(40)
		account.add_child(tile)
		account.add_child(Kit.label(USERNAME, os_style, 15, Color.WHITE))
		account.get_child(1).size_flags_vertical = Control.SIZE_SHRINK_CENTER
		canvas.add_child(account)
		var tray := HBoxContainer.new()
		tray.add_theme_constant_override("separation", 6)
		tray.position = Vector2(area.x - 132, area.y - 50)
		for icon in ["wifi", "person", "power"]:
			var b := Kit.flat_button("", os_style, 12, Color.WHITE, [Color.TRANSPARENT, Color(1, 1, 1, 0.18)], 0, Vector4(6, 6, 6, 6))
			b.icon = Kit.icon(icon)
			b.expand_icon = true
			b.custom_minimum_size = Vector2(36, 36)
			if icon == "power":
				b.tooltip_text = "Shut down"
				b.pressed.connect(close)
			tray.add_child(b)
		canvas.add_child(tray)
	else:
		var clock := _mac_small_clock()
		canvas.add_child(clock)
		column.custom_minimum_size.x = 240
		column.add_child(_avatar(72))
		var title := Kit.label(USERNAME, os_style, 17, Color.WHITE, 600)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(title)
		column.add_child(_centered(username))
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		row.add_child(password)
		var go := Kit.flat_button("→", os_style, 15, Color.WHITE, [Color(1, 1, 1, 0.25), Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.55)], 15, Vector4(0, 0, 0, 0), 700)
		go.custom_minimum_size = Vector2(30, 30)
		go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		go.pressed.connect(sign_in)
		row.add_child(go)
		column.add_child(row)
		column.add_child(login_error)
		var hint := Kit.label("Enter your password · demo 122333", os_style, 13, Color(1, 1, 1, 0.7))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(hint)
		column.position = Vector2((area.x - 240) / 2.0, area.y - 300)
		var power := HBoxContainer.new()
		power.add_theme_constant_override("separation", 30)
		power.position = Vector2((area.x - 250) / 2.0, area.y - 44)
		for entry in [["Sleep", "lock"], ["Restart", "wifi"], ["Shut Down", "power"]]:
			var b := Kit.flat_button(entry[0], os_style, 13, Color(1, 1, 1, 0.85), [Color.TRANSPARENT, Color(1, 1, 1, 0.12)], 6, Vector4(6, 3, 6, 3))
			b.pressed.connect(close if entry[0] != "Restart" else show_lock)
			power.add_child(b)
		canvas.add_child(power)
	password.text_submitted.connect(func(_value: String) -> void: sign_in())
	username.text_submitted.connect(func(_value: String) -> void: password.grab_focus())
	_fade_in(column)
	password.grab_focus()
	_refresh_clock()

func _centered(control: Control) -> CenterContainer:
	var holder := CenterContainer.new()
	holder.add_child(control)
	return holder

func _mac_small_clock() -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", -6)
	stack.size = Vector2(screen_size().x, 140)
	stack.position = Vector2(0, 36)
	date_label = _big_clock(20, 600)
	clock_label = _big_clock(88, 700)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(date_label)
	stack.add_child(clock_label)
	return stack

func sign_in() -> bool:
	if screen != "login":
		return false
	if username.text.strip_edges() != USERNAME or password.text != PASSWORD:
		login_error.text = "The user name or password is incorrect. Try again." if os_style == "windows" else "Incorrect name or password."
		password.clear()
		password.grab_focus()
		if os_style == "macos" and not headless():
			# macOS shakes the login fields on a wrong password.
			var column := password.get_parent().get_parent() as Control
			var home := column.position.x
			var tween := create_tween()
			for offset in [-12.0, 12.0, -8.0, 8.0, -4.0, 0.0]:
				tween.tween_property(column, "position:x", home + offset, 0.045)
		return false
	logged_in = true
	show_desktop()
	return true

# --- Desktop ----------------------------------------------------------------------

func show_desktop() -> void:
	if not logged_in:
		return
	clear("desktop")
	var canvas := _stage()
	canvas.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_menu()
			_select_icon(null))
	if os_style == "windows":
		_windows_desktop(canvas)
	else:
		_mac_desktop(canvas)
	_refresh_clock()

func _desktop_icon(name: String, icon: String, action: Callable, dark_label := false) -> Control:
	var cell := Button.new()
	cell.name = "Icon_" + name.replace(" ", "")
	cell.custom_minimum_size = Vector2(78, 76)
	cell.focus_mode = Control.FOCUS_NONE
	cell.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	cell.add_theme_stylebox_override("hover", Kit.box(Color(1, 1, 1, 0.12), 2, Color(1, 1, 1, 0.2), 1))
	cell.add_theme_stylebox_override("pressed", Kit.box(Color(1, 1, 1, 0.2), 2, Color(1, 1, 1, 0.3), 1))
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(column)
	var picture := Kit.icon_rect(icon, 40)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(picture)
	var caption := Kit.label(name, os_style, 12, Color.WHITE)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	caption.add_theme_constant_override("shadow_offset_y", 1)
	caption.add_theme_constant_override("shadow_offset_x", 1)
	column.add_child(caption)
	# One click selects, a double click opens (as on a real desktop).
	cell.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_icon(cell)
			if event.double_click:
				action.call()
			cell.accept_event())
	return cell

func _select_icon(cell: Control) -> void:
	if is_instance_valid(_selected_icon):
		_selected_icon.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_selected_icon = cell
	if is_instance_valid(cell):
		cell.add_theme_stylebox_override("normal", Kit.box(Color(0.6, 0.8, 1.0, 0.28), 2, Color(0.7, 0.85, 1.0, 0.55), 1))

func _windows_desktop(canvas: Control) -> void:
	var icons := VBoxContainer.new()
	icons.add_theme_constant_override("separation", 10)
	icons.position = Vector2(10, 10)
	canvas.add_child(icons)
	icons.add_child(_desktop_icon("Recycle Bin", "recycle", func() -> void: _info_window("Recycle Bin", "recycle", "The Recycle Bin is empty.")))
	icons.add_child(_desktop_icon("This PC", "pc", func() -> void: _info_window("This PC", "pc", "Local Disk (C:)\n212 GB free of 476 GB\n\nDocuments · Pictures · Downloads")))
	icons.add_child(_desktop_icon("Anki", "anki", open_anki))
	var bar := PanelContainer.new()
	bar.name = "Taskbar"
	bar.add_theme_stylebox_override("panel", Kit.box(Color(0.07, 0.08, 0.1, 0.93)))
	bar.position = Vector2(0, screen_size().y - TASKBAR)
	bar.size = Vector2(screen_size().x, TASKBAR)
	canvas.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	bar.add_child(row)
	var start := _task_button("windows", "Start", _toggle_start_menu)
	row.add_child(start)
	var search_box := Kit.flat_button("   Type here to search", os_style, 13, Color("5f5f5f"), [Color("f3f3f3"), Color("ffffff")], 0, Vector4(8, 0, 8, 0))
	search_box.icon = Kit.icon("search", Color("5f5f5f"))
	search_box.alignment = HORIZONTAL_ALIGNMENT_LEFT
	search_box.custom_minimum_size = Vector2(230, TASKBAR)
	search_box.pressed.connect(_toggle_start_menu)
	row.add_child(search_box)
	row.add_child(_task_button("taskview", "Task View", func() -> void: pass))
	row.add_child(_task_button("folder", "File Explorer", func() -> void: _info_window("File Explorer", "folder", "Quick access\n\nDesktop · Downloads · Documents · Pictures\n\nRecent: Pharmacodynamics notes.docx")))
	row.add_child(_task_button("browser", "Browser", func() -> void: _info_window("Browser", "browser", "No internet\n\nThe campus network isn't available in this build. Your study app works offline.")))
	taskbar_anki = _task_button("anki", "Anki", _taskbar_anki_pressed)
	row.add_child(taskbar_anki)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	for icon in ["wifi", "volume"]:
		var tray := Kit.icon_rect(icon, 18)
		tray.custom_minimum_size = Vector2(32, TASKBAR)
		row.add_child(tray)
	desktop_clock = Kit.label("", os_style, 12, Color.WHITE)
	desktop_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desktop_clock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desktop_clock.custom_minimum_size = Vector2(84, TASKBAR)
	row.add_child(desktop_clock)
	var show_desktop_strip := ColorRect.new()
	show_desktop_strip.color = Color(1, 1, 1, 0.15)
	show_desktop_strip.custom_minimum_size = Vector2(1, TASKBAR)
	row.add_child(show_desktop_strip)
	row.add_child(Control.new())
	row.get_child(row.get_child_count() - 1).custom_minimum_size.x = 6

func _task_button(icon: String, tip: String, action: Callable) -> Button:
	var button := Kit.flat_button("", os_style, 12, Color.WHITE, [Color.TRANSPARENT, Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.2)], 0, Vector4(12, 8, 12, 8))
	button.icon = Kit.icon(icon)
	button.expand_icon = true
	button.custom_minimum_size = Vector2(48, TASKBAR)
	button.tooltip_text = tip
	button.pressed.connect(action)
	return button

func _refresh_taskbar() -> void:
	if is_instance_valid(taskbar_anki):
		var running := is_instance_valid(app_window)
		var focused := running and app_window.visible
		taskbar_anki.add_theme_stylebox_override("normal", _running_style(running, focused))
	if is_instance_valid(dock_anki_dot):
		dock_anki_dot.visible = is_instance_valid(app_window)
	if is_instance_valid(app_name_label):
		var anki_front := is_instance_valid(app_window) and app_window.visible
		if app_name_label.text != ("Anki" if anki_front else "Finder"):
			app_name_label.text = "Anki" if anki_front else "Finder"
			_fill_mac_menus(["File", "Edit", "View", "Tools", "Help"] if anki_front else ["File", "Edit", "View", "Go", "Window", "Help"])

func _running_style(running: bool, focused: bool) -> StyleBoxFlat:
	var style := Kit.box(Color(1, 1, 1, 0.1) if focused else Color.TRANSPARENT, 0, Color("76b9ed"), 0, Vector4(12, 8, 12, 8))
	if running:
		style.border_width_bottom = 2
		if not focused:
			style.expand_margin_left = -12
			style.expand_margin_right = -12
	return style

func _taskbar_anki_pressed() -> void:
	if is_instance_valid(app_window):
		app_window.visible = not app_window.visible
		_refresh_taskbar()
	else:
		open_anki()

func _toggle_start_menu() -> void:
	if is_instance_valid(menu_popup):
		_close_menu()
		return
	var panel := PanelContainer.new()
	panel.name = "StartMenu"
	panel.add_theme_stylebox_override("panel", Kit.box(Color(0.12, 0.13, 0.16, 0.97), 0, Color(1, 1, 1, 0.08), 1))
	panel.position = Vector2(0, screen_size().y - TASKBAR - 420)
	panel.size = Vector2(540, 420)
	content.get_child(0).add_child(panel)
	menu_popup = panel
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)
	var rail := VBoxContainer.new()
	rail.custom_minimum_size.x = 48
	rail.add_theme_constant_override("separation", 0)
	row.add_child(rail)
	var rail_fill := Control.new()
	rail_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.add_child(rail_fill)
	for entry in [["person", "player1 · Lock", show_lock], ["folder", "Documents", func() -> void: pass], ["gear", "Settings", func() -> void: _info_window("Settings", "gear", "Signed in as player1 (local account)\n\nSystem · Devices · Network · Personalization · Accounts")], ["power", "Shut down", close]]:
		var b := _task_button(entry[0], entry[1], entry[2])
		rail.add_child(b)
	var apps := VBoxContainer.new()
	apps.custom_minimum_size.x = 230
	apps.add_theme_constant_override("separation", 2)
	var apps_margin := MarginContainer.new()
	apps_margin.add_theme_constant_override("margin_top", 14)
	apps_margin.add_theme_constant_override("margin_left", 8)
	apps_margin.add_child(apps)
	row.add_child(apps_margin)
	apps.add_child(Kit.label("A", os_style, 13, Color("c9c9c9"), 600))
	apps.add_child(_start_entry("anki", "Anki", open_anki))
	apps.add_child(Kit.label("F", os_style, 13, Color("c9c9c9"), 600))
	apps.add_child(_start_entry("folder", "File Explorer", func() -> void: _info_window("File Explorer", "folder", "Quick access\n\nDesktop · Downloads · Documents · Pictures")))
	apps.add_child(Kit.label("S", os_style, 13, Color("c9c9c9"), 600))
	apps.add_child(_start_entry("gear", "Settings", func() -> void: _info_window("Settings", "gear", "Signed in as player1 (local account)")))
	var tiles := VBoxContainer.new()
	tiles.add_theme_constant_override("separation", 8)
	var tiles_margin := MarginContainer.new()
	tiles_margin.add_theme_constant_override("margin_top", 14)
	tiles_margin.add_theme_constant_override("margin_left", 10)
	tiles_margin.add_child(tiles)
	row.add_child(tiles_margin)
	tiles.add_child(Kit.label("Study", os_style, 13, Color.WHITE, 600))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	tiles.add_child(grid)
	grid.add_child(_tile("anki", "Anki", Color("2f6fcf"), open_anki))
	grid.add_child(_tile("folder", "Notes", Color("3a3f4a"), func() -> void: _info_window("File Explorer", "folder", "Documents\n\nPharmacodynamics notes.docx")))
	grid.add_child(_tile("gear", "Settings", Color("3a3f4a"), func() -> void: _info_window("Settings", "gear", "Signed in as player1 (local account)")))
	grid.add_child(_tile("browser", "Browser", Color("0f6cbd"), func() -> void: _info_window("Browser", "browser", "No internet")))
	_fade_in(panel)

func _start_entry(icon: String, text: String, action: Callable) -> Button:
	var b := Kit.flat_button("  " + text, os_style, 14, Color.WHITE, [Color.TRANSPARENT, Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.18)], 0, Vector4(8, 6, 8, 6))
	b.icon = Kit.icon(icon)
	b.expand_icon = false
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("icon_max_width", 24)
	b.pressed.connect(func() -> void:
		_close_menu()
		action.call())
	return b

func _tile(icon: String, text: String, color: Color, action: Callable) -> Button:
	var b := Kit.flat_button("", os_style, 12, Color.WHITE, [color, color.lightened(0.12), color.darkened(0.1)], 0)
	b.custom_minimum_size = Vector2(118, 118)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(column)
	var picture := Kit.icon_rect(icon, 44)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(picture)
	var caption := Kit.label(text, os_style, 12, Color.WHITE)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	b.pressed.connect(func() -> void:
		_close_menu()
		action.call())
	return b

func _close_menu() -> void:
	if is_instance_valid(menu_popup):
		menu_popup.queue_free()
	menu_popup = null

func _mac_desktop(canvas: Control) -> void:
	var bar := PanelContainer.new()
	bar.name = "MenuBar"
	bar.add_theme_stylebox_override("panel", Kit.box(Color(0.1, 0.12, 0.2, 0.42), 0, Color.TRANSPARENT, 0, Vector4(14, 0, 14, 0)))
	bar.size = Vector2(screen_size().x, MENU_BAR)
	canvas.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	bar.add_child(row)
	var fruit := Kit.flat_button("", os_style, 13, Color.WHITE, [Color.TRANSPARENT, Color(1, 1, 1, 0.2)], 5, Vector4(8, 2, 8, 2))
	fruit.icon = Kit.icon("fruit")
	fruit.expand_icon = true
	fruit.custom_minimum_size = Vector2(34, MENU_BAR)
	fruit.pressed.connect(_toggle_system_menu)
	row.add_child(fruit)
	app_name_label = Kit.label("Finder", os_style, 13, Color.WHITE, 700)
	app_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(app_name_label)
	row.add_child(Control.new())
	row.get_child(row.get_child_count() - 1).custom_minimum_size.x = 8
	mac_menus = HBoxContainer.new()
	mac_menus.add_theme_constant_override("separation", 0)
	row.add_child(mac_menus)
	_fill_mac_menus(["File", "Edit", "View", "Go", "Window", "Help"])
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fill)
	var battery := Kit.label("86%", os_style, 12, Color.WHITE)
	battery.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(battery)
	for icon in ["battery", "wifi", "search"]:
		var glyph := Kit.icon_rect(icon, 16)
		glyph.custom_minimum_size = Vector2(28, MENU_BAR)
		row.add_child(glyph)
	desktop_clock = Kit.label("", os_style, 13, Color.WHITE)
	desktop_clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(desktop_clock)
	var dock := PanelContainer.new()
	dock.name = "Dock"
	dock.add_theme_stylebox_override("panel", Kit.box(Color(0.9, 0.93, 0.98, 0.26), 18, Color(1, 1, 1, 0.38), 1, Vector4(8, 6, 8, 4)))
	canvas.add_child(dock)
	var icons := HBoxContainer.new()
	icons.add_theme_constant_override("separation", 6)
	dock.add_child(icons)
	icons.add_child(_dock_item("finder", "Finder", func() -> void: _info_window("Finder", "finder", "Recents\n\nPharmacodynamics notes.pages\nAnki collection (synced with your dorm PC)"), true))
	icons.add_child(_dock_item("launchpad", "Launchpad", func() -> void: pass))
	icons.add_child(_dock_item("safari", "Safari", func() -> void: _info_window("Safari", "safari", "You Are Not Connected to the Internet\n\nThe campus Wi-Fi isn't available in this build. Anki works offline.")))
	icons.add_child(_dock_item("notes", "Notes", func() -> void: _info_window("Notes", "notes", "Study plan\n• Review due cards each morning\n• Add cards right after lecture\n• Keep answers short")))
	var anki := _dock_item("anki", "Anki", _taskbar_anki_pressed)
	icons.add_child(anki)
	dock_anki_dot = anki.get_node("Dot")
	icons.add_child(_dock_item("gear", "System Settings", func() -> void: _info_window("System Settings", "gear", "player1 · Local account\n\nWi-Fi · Bluetooth · Battery 86% · Displays")))
	var divider := ColorRect.new()
	divider.color = Color(1, 1, 1, 0.35)
	divider.custom_minimum_size = Vector2(1, 50)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icons.add_child(divider)
	icons.add_child(_dock_item("trash", "Trash", func() -> void: _info_window("Trash", "trash", "Trash is empty.")))
	dock.reset_size()
	dock.position = Vector2((screen_size().x - dock.get_combined_minimum_size().x) / 2.0, screen_size().y - 74)

func _fill_mac_menus(names: Array) -> void:
	for child in mac_menus.get_children():
		mac_menus.remove_child(child)
		child.queue_free()
	for menu in names:
		mac_menus.add_child(Kit.flat_button(menu, os_style, 13, Color.WHITE, [Color.TRANSPARENT, Color(1, 1, 1, 0.2)], 5, Vector4(8, 2, 8, 2)))

## A Dock icon: grows on hover, shows its name above, and a dot when running.
func _dock_item(icon: String, name: String, action: Callable, running := false) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(56, 64)
	var button := TextureButton.new()
	button.name = "Button"
	button.texture_normal = Kit.icon(icon)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.size = Vector2(52, 52)
	button.position = Vector2(2, 2)
	button.pivot_offset = Vector2(26, 52)
	button.pressed.connect(action)
	holder.add_child(button)
	var dot := ColorRect.new()
	dot.name = "Dot"
	dot.color = Color(1, 1, 1, 0.85)
	dot.size = Vector2(4, 4)
	dot.position = Vector2(26, 58)
	dot.visible = running
	holder.add_child(dot)
	var tip := PanelContainer.new()
	tip.add_theme_stylebox_override("panel", Kit.box(Color(0.2, 0.22, 0.26, 0.9), 6, Color(1, 1, 1, 0.15), 1, Vector4(8, 3, 8, 3)))
	tip.add_child(Kit.label(name, os_style, 12, Color.WHITE))
	tip.visible = false
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(tip)
	button.mouse_entered.connect(func() -> void:
		tip.visible = true
		tip.reset_size()
		tip.position = Vector2(28 - tip.size.x / 2.0, -38)
		if not headless():
			create_tween().tween_property(button, "scale", Vector2(1.22, 1.22), 0.12))
	button.mouse_exited.connect(func() -> void:
		tip.visible = false
		if not headless():
			create_tween().tween_property(button, "scale", Vector2.ONE, 0.12))
	return holder

func _toggle_system_menu() -> void:
	if is_instance_valid(menu_popup):
		_close_menu()
		return
	var panel := PanelContainer.new()
	panel.name = "SystemMenu"
	panel.add_theme_stylebox_override("panel", Kit.box(Color(0.96, 0.96, 0.97, 0.97), 8, Color(0, 0, 0, 0.18), 1, Vector4(5, 5, 5, 5)))
	panel.position = Vector2(10, MENU_BAR + 2)
	content.get_child(0).add_child(panel)
	menu_popup = panel
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.custom_minimum_size.x = 220
	panel.add_child(column)
	for entry in [["About This Mac", func() -> void: _info_window("About This Mac", "fruit", "MacBook Air\nChip: Student M-series\nMemory: 16 GB\nmacOS (in-game)")], ["System Settings…", func() -> void: _info_window("System Settings", "gear", "player1 · Local account")], ["", null], ["Lock Screen", show_lock], ["Log Out player1…", show_lock], ["", null], ["Shut Down…", close]]:
		if entry[0].is_empty():
			var rule := ColorRect.new()
			rule.color = Color(0, 0, 0, 0.1)
			rule.custom_minimum_size.y = 1
			column.add_child(rule)
			continue
		var item := Kit.flat_button(entry[0], os_style, 13, Color("1f1f1f"), [Color.TRANSPARENT, Color("2f6fcf"), Color("2f6fcf")], 5, Vector4(10, 4, 10, 4))
		item.add_theme_color_override("font_hover_color", Color.WHITE)
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var action: Callable = entry[1]
		item.pressed.connect(func() -> void:
			_close_menu()
			action.call())
		column.add_child(item)

## A small native-looking window with a message (Explorer, Finder, …).
func _info_window(title: String, icon: String, message: String) -> void:
	var window := OSWindow.new(os_style, title, icon)
	window.name = "Info_" + title.replace(" ", "")
	content.get_child(0).add_child(window)
	window.work_area = _work_area()
	window.place(Rect2(Vector2(screen_size().x * 0.24, screen_size().y * 0.2) + Vector2(randf() * 50, randf() * 30), Vector2(440, 260)))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	window.content.add_child(margin)
	var column := HBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	column.add_child(Kit.icon_rect(icon, 48))
	var words := Kit.label(message, os_style, 14, Color("1f1f1f"))
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(words)
	window.close_requested.connect(window.queue_free)
	window.minimize_requested.connect(window.queue_free)
	_fade_in(window)

func _work_area() -> Rect2:
	var area := screen_size()
	return Rect2(0, 0, area.x, area.y - TASKBAR) if os_style == "windows" else Rect2(0, MENU_BAR, area.x, area.y - MENU_BAR - 76)

# --- Anki ------------------------------------------------------------------------

func open_anki() -> void:
	if not logged_in:
		return
	_close_menu()
	if screen != "desktop":
		show_desktop()
	if is_instance_valid(app_window):
		app_window.visible = true
		app_window.move_to_front()
		_refresh_taskbar()
		return
	app_window = OSWindow.new(os_style, "player1 - Anki", "anki")
	app_window.name = "AnkiWindow"
	content.get_child(0).add_child(app_window)
	var area := _work_area()
	app_window.work_area = area
	if os_style == "windows":
		app_window.place(Rect2(Vector2(48, 10), Vector2(area.size.x - 96, area.size.y - 20)))
	else:
		app_window.place(Rect2(Vector2(44, area.position.y + 8), Vector2(area.size.x - 88, area.size.y - 12)))
	app = AnkiApp.new(os_style)
	app_window.content.add_child(app)
	app_window.close_requested.connect(_close_anki)
	app_window.minimize_requested.connect(func() -> void:
		app_window.visible = false
		_refresh_taskbar())
	_refresh_taskbar()
	_fade_in(app_window)

func _close_anki() -> void:
	Flashcards.end_review()
	if is_instance_valid(app_window):
		app_window.queue_free()
	app_window = null
	app = null
	_refresh_taskbar.call_deferred()

# --- Clock and closing ---------------------------------------------------------------

func _refresh_clock() -> void:
	var now := Time.get_datetime_dict_from_system()
	var hour: int = now.hour % 12
	var time := "%d:%02d" % [12 if hour == 0 else hour, now.minute]
	var suffix := "AM" if now.hour < 12 else "PM"
	var weekdays := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
	var months := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	if is_instance_valid(clock_label):
		clock_label.text = time
	if is_instance_valid(date_label):
		date_label.text = "%s, %s %d" % [weekdays[now.weekday], months[now.month - 1], now.day]
	if is_instance_valid(desktop_clock):
		desktop_clock.text = "%s %s\n%d/%d/%d" % [time, suffix, now.month, now.day, now.year] if os_style == "windows" else "%s %s %d  %s %s" % [weekdays[now.weekday].left(3), months[now.month - 1].left(3), now.day, time, suffix]

func _process(delta: float) -> void:
	clock_elapsed += delta
	if clock_elapsed >= 1.0:
		clock_elapsed = 0.0
		_refresh_clock()

func close() -> void:
	if closing:
		return
	closing = true
	Flashcards.end_review()
	SaveGame.autosave()
	if is_instance_valid(screen_mesh):
		screen_mesh.material_override = _saved_material
	if is_instance_valid(player) and "first_person" in player:
		player.first_person.set_head_hidden(player.first_person.active)
	if is_instance_valid(camera):
		if camera.current:
			# The camera eases back out, then removes itself.
			camera.transition_finished.connect(camera.queue_free.unbind(1), CONNECT_ONE_SHOT)
			camera.leave()
		else:
			camera.queue_free()
	closed.emit()
	queue_free()
