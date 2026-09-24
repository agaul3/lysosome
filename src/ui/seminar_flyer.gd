extends Control
## Research seminar flyer for the Learning Center's lobby display (rendered in
## a SubViewport onto the screen). A department bulletin layout: header with
## the department and a "Research Seminar" tab, the speaker's studio headshot
## (a live render of the in-game character), the talk title in a tinted card,
## time and place with icons, and a footer band. Faint neuroscience and
## stem-cell motifs (a hexagonal cell lattice, a neural network, microchip
## traces) sit behind the content without competing with it.
const UI = preload("res://ui/style/ui_style.gd")
const Icon = preload("res://ui/style/icon.gd")
const Appearance = preload("res://player/appearance.gd")
const Geometry = preload("res://world/geometry.gd")
const SIZE := Vector2(1320, 900)
const NAVY := Color("16395c")
const SLATE := Color("4b6173")
const TEAL := Color("2f8f82")
const TAB := Color("d9822b")
const SPEAKER := "Dr. Nyugen"
const DEPARTMENT := "Anatomy and Cell Biology"
const TITLE := "On-Chip Neural Induction Enhances Neural Stem Cell Commitment: Advancing a Pipeline for iPSC-Based Therapies"
const TIME := "10:00 PM"
const DATE := "Monday, September 21, 2026"
const LOCATION := "Anatomy Building, Room R1023"
var headshot: SubViewport
var photo: TextureRect
var title_label: Label

func _ready() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	headshot = build_headshot()
	add_child(headshot)
	# Header: emblem, department and school, then the seminar tab.
	var emblem := Control.new()
	emblem.position = Vector2(56, 40)
	emblem.size = Vector2(104, 104)
	emblem.draw.connect(func() -> void: _draw_emblem(emblem))
	add_child(emblem)
	_text("Department of Anatomy & Cell Biology", Vector2(188, 44), 46, NAVY, 650)
	_text("School of Medicine", Vector2(190, 104), 26, SLATE, 500)
	var tab := Control.new()
	tab.position = Vector2(930, 170)
	tab.size = Vector2(334, 52)
	tab.draw.connect(func() -> void:
		tab.draw_rect(Rect2(Vector2.ZERO, tab.size), TAB)
		tab.draw_string(UI.font(650), Vector2(24, 35), "RESEARCH SEMINAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE))
	add_child(tab)
	# Speaker: studio headshot in a white mount, name and department.
	var mount := Panel.new()
	mount.position = Vector2(62, 236)
	mount.size = Vector2(318, 386)
	var mount_style := StyleBoxFlat.new()
	mount_style.bg_color = Color.WHITE
	mount_style.shadow_color = Color(0.05, 0.12, 0.2, 0.18)
	mount_style.shadow_size = 10
	mount_style.shadow_offset = Vector2(0, 4)
	mount.add_theme_stylebox_override("panel", mount_style)
	add_child(mount)
	photo = TextureRect.new()
	photo.position = Vector2(8, 8)
	photo.size = Vector2(302, 370)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.texture = headshot.get_texture()
	mount.add_child(photo)
	_text(SPEAKER, Vector2(62, 640), 42, NAVY, 700)
	var department := _text("Department of " + DEPARTMENT, Vector2(64, 694), 22, SLATE, 500)
	department.size = Vector2(330, 60)
	department.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Talk title in a tinted card with an accent rule.
	var card := Control.new()
	card.position = Vector2(440, 250)
	card.size = Vector2(824, 262)
	card.draw.connect(func() -> void:
		card.draw_rect(Rect2(Vector2.ZERO, card.size), Color(0.86, 0.92, 0.96, 0.92))
		card.draw_rect(Rect2(Vector2.ZERO, Vector2(8, card.size.y)), TEAL))
	add_child(card)
	title_label = UI.label("“" + TITLE + "”", 37, NAVY, 600)
	title_label.position = Vector2(38, 24)
	title_label.size = Vector2(760, 214)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_constant_override("line_spacing", 4)
	card.add_child(title_label)
	# When and where.
	_detail("clock", Vector2(446, 556), TIME, DATE)
	_detail("pin", Vector2(446, 660), LOCATION, "All are welcome · Open to students, residents and faculty")
	# Footer band.
	var footer := ColorRect.new()
	footer.color = NAVY
	footer.position = Vector2(0, SIZE.y - 66)
	footer.size = Vector2(SIZE.x, 66)
	add_child(footer)
	_text("Anatomy & Cell Biology Seminar Series", Vector2(56, SIZE.y - 50), 24, Color.WHITE, 600)
	var refreshments := _text("Light refreshments provided", Vector2(0, SIZE.y - 50), 22, Color(1, 1, 1, 0.8), 500)
	refreshments.size.x = SIZE.x - 56
	refreshments.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _text(text: String, at: Vector2, font_size: int, color: Color, weight: int) -> Label:
	var label := UI.label(text, font_size, color, weight)
	label.position = at
	add_child(label)
	return label

func _detail(icon: String, at: Vector2, headline: String, note: String) -> void:
	var glyph := Icon.new(icon, 46, TEAL)
	glyph.stroke = 3.2
	glyph.position = at + Vector2(0, 8)
	glyph.size = Vector2(46, 46)
	add_child(glyph)
	_text(headline, at + Vector2(70, -4), 44, NAVY, 700)
	_text(note, at + Vector2(72, 54), 23, SLATE, 500)

## Department emblem: a rounded navy mark with a stylised neuron.
func _draw_emblem(canvas: Control) -> void:
	var box := Rect2(Vector2.ZERO, canvas.size)
	var style := StyleBoxFlat.new()
	style.bg_color = NAVY
	style.set_corner_radius_all(18)
	style.draw(canvas.get_canvas_item(), box)
	var centre := canvas.size / 2.0 + Vector2(0, 4)
	for angle in [-2.4, -1.5, -0.6, 0.5, 1.6, 2.6]:
		var tip := centre + Vector2(cos(angle), sin(angle)) * 36.0
		canvas.draw_line(centre, tip, Color(1, 1, 1, 0.9), 3.0, true)
		canvas.draw_circle(tip, 4.0, TEAL.lightened(0.35))
	canvas.draw_circle(centre, 13.0, Color.WHITE)
	canvas.draw_circle(centre, 6.0, TEAL)

func _draw() -> void:
	# Paper: white into a pale clinical blue.
	var top := Color("ffffff")
	var bottom := Color("dfeaf2")
	for band in range(30):
		var t := band / 29.0
		draw_rect(Rect2(0, SIZE.y * t, SIZE.x, SIZE.y / 29.0 + 1), top.lerp(bottom, t))
	# Hexagonal cell lattice, lower right.
	var hex_color := Color(0.18, 0.43, 0.6, 0.12)
	for row in range(7):
		for column in range(9):
			var centre := Vector2(760 + column * 66 + (33 if row % 2 else 0), 520 + row * 57)
			var points := PackedVector2Array()
			for corner in range(7):
				var angle := PI / 6 + corner * PI / 3
				points.append(centre + Vector2(cos(angle), sin(angle)) * 36)
			draw_polyline(points, hex_color, 2.0, true)
	# A faint neural network across the top right.
	var nodes := [Vector2(880, 70), Vector2(990, 130), Vector2(1100, 60), Vector2(1200, 140), Vector2(1270, 70), Vector2(1060, 190), Vector2(1180, 215)]
	var links := [[0, 1], [1, 2], [2, 3], [3, 4], [1, 5], [5, 6], [3, 6], [2, 4]]
	for link in links:
		draw_line(nodes[link[0]], nodes[link[1]], Color(0.18, 0.56, 0.51, 0.22), 2.0, true)
	for node in nodes:
		draw_circle(node, 6.0, Color(0.18, 0.56, 0.51, 0.3))
	# Microchip traces, lower left.
	var trace := Color(0.09, 0.22, 0.36, 0.1)
	for index in range(6):
		var y := 822.0 - index * 10
		var knee := 150.0 + index * 22
		draw_polyline(PackedVector2Array([Vector2(0, y), Vector2(knee, y), Vector2(knee + 10, y - 10), Vector2(knee + 120, y - 10)]), trace, 2.0, true)
		draw_circle(Vector2(knee + 120, y - 10), 3.5, trace)
	# Header rule.
	draw_rect(Rect2(56, 164, SIZE.x - 112, 3), TEAL)

## A small studio: the speaker in head-and-shoulders framing, key, fill and
## rim light, and a softly lit backdrop. Renders once into its own world.
static func build_headshot() -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = "HeadshotViewport"
	viewport.size = Vector2i(604, 740)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var studio := Node3D.new()
	viewport.add_child(studio)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("7d93a3")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("dfe6ea")
	environment.environment.ambient_light_energy = 0.55
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	studio.add_child(environment)
	var backdrop := MeshInstance3D.new()
	backdrop.mesh = QuadMesh.new()
	backdrop.mesh.size = Vector2(4, 3)
	backdrop.position = Vector3(0, 1.4, 1.2)
	backdrop.rotation.y = PI
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color("8ea4b3")
	cloth.roughness = 1.0
	backdrop.material_override = cloth
	studio.add_child(backdrop)
	var figure: Node3D = Appearance.new()
	figure.name = "Speaker"
	studio.add_child(figure)
	figure.apply_preset("nyugen")
	figure.rotation.y = 0.28
	_dress(figure)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-28, 200, 0)
	key.light_energy = 1.05
	key.light_color = Color("fff4e6")
	studio.add_child(key)
	var halo := OmniLight3D.new()
	halo.position = Vector3(0, 1.45, 0.7)
	halo.omni_range = 1.6
	halo.light_energy = 1.2
	halo.light_color = Color("d8e6ef")
	studio.add_child(halo)
	var camera := Camera3D.new()
	camera.fov = 24.0
	var eye := Vector3(0.12, 1.47, -2.05)
	camera.transform = Transform3D(Basis.looking_at(Vector3(0, 1.4, 0) - eye, Vector3.UP), eye)
	camera.current = true
	studio.add_child(camera)
	return viewport

## Shirt collar, tie and blazer lapels over the torso, and thin-framed glasses.
static func _dress(figure: Node3D) -> void:
	var spine: Node3D = figure.spine
	var up := Vector3(0, -figure.HIP_HEIGHT, 0)
	Geometry.box(spine, "Shirt", Vector3(0.15, 0.22, 0.01), up + Vector3(0, 1.12, -0.153), Color("f1f2ef"))
	Geometry.box(spine, "Tie", Vector3(0.05, 0.21, 0.012), up + Vector3(0, 1.105, -0.158), Color("6b2f3a"))
	Geometry.box(spine, "TieKnot", Vector3(0.06, 0.04, 0.014), up + Vector3(0, 1.205, -0.158), Color("5a2630"))
	for side in [-1, 1]:
		var collar := Geometry.box(spine, "Collar", Vector3(0.07, 0.05, 0.012), up + Vector3(side * 0.045, 1.215, -0.157), Color("f7f7f4"))
		collar.rotation.z = side * 0.5
		var lapel := Geometry.box(spine, "Lapel", Vector3(0.09, 0.3, 0.014), up + Vector3(side * 0.1, 1.09, -0.157), Color("2b3138"))
		lapel.rotation.z = side * 0.32
	var frame := Color("1f2326")
	var eye_y := 1.5
	for side in [-1, 1]:
		var x: float = side * 0.085
		Geometry.box(spine, "GlassesTop", Vector3(0.12, 0.012, 0.01), up + Vector3(x, eye_y + 0.035, -0.205), frame)
		Geometry.box(spine, "GlassesBottom", Vector3(0.12, 0.01, 0.01), up + Vector3(x, eye_y - 0.035, -0.205), frame)
		for edge in [-1, 1]:
			Geometry.box(spine, "GlassesSide", Vector3(0.01, 0.07, 0.01), up + Vector3(x + edge * 0.055, eye_y, -0.205), frame)
		Geometry.box(spine, "GlassesArm", Vector3(0.01, 0.01, 0.2), up + Vector3(side * 0.2, eye_y + 0.03, -0.1), frame)
	Geometry.box(spine, "GlassesBridge", Vector3(0.05, 0.01, 0.01), up + Vector3(0, eye_y + 0.02, -0.206), frame)
