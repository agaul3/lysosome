extends RefCounted
## Campus architecture, modelled on contemporary medical-school buildings:
## a stacked, finned Learning Center; a residence hall with framed windows and
## coloured fins; a medical-centre tower with vertical panels and a timber
## canopy; a classical stone hall closing the quad; and a glazed café pavilion.
## Each building is merged by MeshKit into a few draw calls, with simple box
## collision. Coordinates are world metres (+Z faces the default camera).
const MeshKit = preload("res://world/campus/mesh_kit.gd")

const WHITE := Color("f3f2ee")
const FIN := Color("f8f7f3")
const STONE := Color("d9d5cb")
const CREAM := Color("efe4c8")
const ORANGE := Color("e0893e")
const RED := Color("c2452d")
const GREY := Color("8e979c")
const DARK := Color("3f464b")
const SOIL := Color("4a3b2e")
const PAVER := Color("e2ddd1")

## Raised 3D lettering (relief sign) facing +Z after `yaw`.
static func letters(parent: Node3D, text: String, position: Vector3, yaw: float, height: float, color: Color, depth := 0.06) -> MeshInstance3D:
	var text_mesh := TextMesh.new()
	text_mesh.text = text
	# The built-in fallback font triangulates cleanly (the variable UI font does not).
	text_mesh.font = ThemeDB.fallback_font
	text_mesh.font_size = 64
	text_mesh.pixel_size = height / 64.0
	text_mesh.depth = depth
	var instance := MeshInstance3D.new()
	instance.name = "Letters_" + text.replace(" ", "_")
	instance.mesh = text_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.4
	material.metallic = 0.5
	instance.material_override = material
	# Thin relief letters' shadows read as a ghost copy on the wall from eye level.
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.rotation.y = yaw
	# Letters stand proud of the wall by half their depth plus 1 cm.
	instance.position = position + Basis(Vector3.UP, yaw) * Vector3(0, 0, depth / 2.0 + 0.01)
	parent.add_child(instance)
	return instance

## Glazed double entrance door set in a wall facing +Z (rotated by yaw about
## `center`, which sits on the wall face at ground level). A dark metal portal
## stands proud of the facade, so the door reads apart from any curtain wall
## around it: jambs, head and a transom bar; two framed leaves (stiles, top
## rail, deep kick rail) with tinted glass and long pull handles on standoffs;
## a dark vestibule behind the glass; a steel threshold.
static func door(kit: MeshKit, center: Vector3, width: float, yaw := 0.0) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var at := func(local: Vector3) -> Vector3: return center + basis * local
	var half := width / 2.0
	var frame := Color("2c3236")
	var steel := Color("c9d0d3")
	kit.box("facade", at.call(Vector3(0, 1.4, -0.02)), Vector3(width + 0.1, 2.8, 0.02), Color("20272b"), basis)
	for side in [-1, 1]:
		kit.box("metal", at.call(Vector3(side * (half + 0.09), 1.5, 0.1)), Vector3(0.18, 3.0, 0.3), frame, basis)
	kit.box("metal", at.call(Vector3(0, 2.92, 0.1)), Vector3(width + 0.36, 0.16, 0.3), frame, basis)
	kit.box("metal", at.call(Vector3(0, 2.5, 0.08)), Vector3(width, 0.07, 0.2), frame, basis)
	kit.box("tinted", at.call(Vector3(0, 2.69, 0.03)), Vector3(width, 0.3, 0.03), Color("30414a"), basis)
	for side in [-1, 1]:
		var leaf_width := half - 0.015
		var middle: float = side * half / 2.0
		for edge in [-1, 1]:
			kit.box("metal", at.call(Vector3(middle + edge * (leaf_width / 2.0 - 0.05), 1.23, 0.07)), Vector3(0.1, 2.46, 0.07), frame, basis)
		kit.box("metal", at.call(Vector3(middle, 2.41, 0.07)), Vector3(leaf_width, 0.1, 0.07), frame, basis)
		kit.box("metal", at.call(Vector3(middle, 0.14, 0.07)), Vector3(leaf_width, 0.28, 0.07), frame, basis)
		kit.box("tinted", at.call(Vector3(middle, 1.32, 0.06)), Vector3(leaf_width - 0.18, 2.0, 0.02), Color("3a4d57"), basis)
		# Pull handle near the meeting stiles, standing off the glass.
		var handle_x: float = middle - side * (leaf_width / 2.0 - 0.17)
		kit.box("metal", at.call(Vector3(handle_x, 1.05, 0.19)), Vector3(0.045, 0.95, 0.045), steel.lightened(0.1), basis)
		for y in [0.66, 1.44]:
			kit.box("metal", at.call(Vector3(handle_x, y, 0.14)), Vector3(0.022, 0.022, 0.09), steel, basis)
	kit.box("metal", at.call(Vector3(0, 0.03, 0.12)), Vector3(width + 0.36, 0.06, 0.32), steel.darkened(0.2), basis)

## Tall panelled timber double door for the classical hall: stone architrave
## with a cornice, a glazed fanlight with bars, raised panels, brass pulls and
## kick plates, and a stone threshold. `center` is on the wall face at the sill.
static func classical_door(kit: MeshKit, center: Vector3, width: float, height: float, trim: Color) -> void:
	var timber := Color("4d3222")
	var panel := Color("5d3d29")
	var brass := Color("c9a25a")
	var half := width / 2.0
	kit.box("facade", center + Vector3(0, height / 2.0 + 0.4, 0.01), Vector3(width, height + 0.8, 0.02), Color("2a211c"))
	for side in [-1, 1]:
		kit.box("facade", center + Vector3(side * (half + 0.16), (height + 0.8) / 2.0, 0.08), Vector3(0.32, height + 0.8, 0.16), trim)
	kit.box("facade", center + Vector3(0, height + 0.95, 0.08), Vector3(width + 0.64, 0.3, 0.16), trim)
	kit.box("facade", center + Vector3(0, height + 1.14, 0.12), Vector3(width + 0.9, 0.1, 0.26), trim.darkened(0.06))
	# Fanlight over the doors.
	kit.box("facade", center + Vector3(0, height + 0.04, 0.05), Vector3(width, 0.08, 0.08), timber)
	kit.box("tinted", center + Vector3(0, height + 0.42, 0.03), Vector3(width - 0.06, 0.68, 0.03), Color("34454e"))
	for bar in [-0.5, 0.0, 0.5]:
		kit.box("facade", center + Vector3(bar * half, height + 0.42, 0.05), Vector3(0.04, 0.7, 0.04), timber)
	for side in [-1, 1]:
		var middle: float = side * half / 2.0
		kit.box("facade", center + Vector3(middle, height / 2.0, 0.05), Vector3(half - 0.02, height, 0.07), timber)
		for block in [[0.18 + 0.45, 0.9], [height - 0.2 - 0.85, 1.3]]:
			kit.box("facade", center + Vector3(middle, block[0], 0.095), Vector3(half - 0.26, block[1], 0.02), panel)
			kit.box("facade", center + Vector3(middle, block[0], 0.11), Vector3(half - 0.38, block[1] - 0.12, 0.012), panel.lightened(0.06))
		kit.box("metal", center + Vector3(middle - side * (half / 2.0 - 0.14), height * 0.45, 0.13), Vector3(0.04, 0.34, 0.04), brass)
		kit.box("metal", center + Vector3(middle, 0.12, 0.09), Vector3(half - 0.08, 0.2, 0.012), brass)
	kit.box("facade", center + Vector3(0, -0.02, 0.2), Vector3(width + 0.5, 0.06, 0.4), trim.darkened(0.05))

# --- Learning Center ---------------------------------------------------------------

## Podium x[-15,15] z[-36,-24] with a glazed front and green roof terrace;
## three stacked, offset floor plates wrapped in white vertical fins; a
## timber-soffit entry canopy over the doors at (0, -24).
static func learning_center(parent: Node3D) -> void:
	var kit := MeshKit.new()
	var front := -24.0
	# Podium: solid core, glass front and sides, white roof slab.
	kit.solid(Vector3(0, 2.5, -30.3), Vector3(30, 5, 11.4))
	kit.box("facade", Vector3(0, 2.5, -30.3), Vector3(29.6, 5, 11.2), STONE)
	# Front glazing, cut around the entrance doors (their frame stands proud of it).
	for side in [-1, 1]:
		kit.box("glass", Vector3(side * 8.35, 2.2, front - 0.55), Vector3(12.7, 4.4, 0.1), Color.WHITE)
	kit.box("glass", Vector3(0, 3.7, front - 0.55), Vector3(4.0, 1.4, 0.1), Color.WHITE)
	for side in [-1, 1]:
		kit.box("glass", Vector3(side * 14.85, 2.2, -30), Vector3(0.1, 4.4, 11), Color.WHITE)
	kit.box("facade", Vector3(0, 4.7, -30), Vector3(31.2, 0.6, 12.6), WHITE)
	for index in range(7):
		var x := -15.0 + index * 5.0
		if absf(x) < 3.0:
			continue # Keep the entrance clear.
		kit.cylinder("facade", Vector3(x, 0, front - 0.2), Vector3(x, 4.4, front - 0.2), 0.18, WHITE)
	# Entry: doors, canopy with a timber soffit on two slim columns.
	door(kit, Vector3(0, 0, front - 0.55), 3.6)
	kit.box("facade", Vector3(0, 4.25, front + 1.9), Vector3(12.0, 0.35, 4.2), WHITE)
	kit.box("wood", Vector3(0, 4.05, front + 1.9), Vector3(11.6, 0.06, 3.9), Color.WHITE)
	for x in [-5.4, 5.4]:
		kit.cylinder("metal", Vector3(x, 0, front + 3.6), Vector3(x, 4.08, front + 3.6), 0.12, Color("d8dcde"))
		kit.solid(Vector3(x, 1.5, front + 3.6), Vector3(0.3, 3, 0.3))
	# Green roof terrace at the front of the podium roof, with a glass balustrade.
	kit.box("facade", Vector3(0, 5.12, front - 1.6), Vector3(29, 0.24, 2.6), Color("5d8a45"))
	kit.box("glass", Vector3(0, 5.55, front + 0.5), Vector3(30.8, 1.0, 0.04), Color.WHITE)
	# Upper floor plates: slab edge, glazing, perimeter fins; each shifted.
	var shifts := [1.0, -0.8, 0.5]
	for level in range(3):
		var y0 := 5.0 + level * 4.2
		var cx: float = shifts[level]
		var width := 24.0
		var depth := 8.6
		var cz := -30.6
		kit.box("glass", Vector3(cx, y0 + 2.1, cz), Vector3(width - 1.2, 4.2, depth - 1.2), Color.WHITE)
		kit.box("facade", Vector3(cx, y0 + 4.2, cz), Vector3(width + 0.8, 0.5, depth + 0.8), WHITE)
		var fin_height := 3.7
		var spacing := 0.55
		var count_x := int(width / spacing)
		for index in range(count_x + 1):
			var x := cx - width / 2.0 + index * spacing
			for z in [cz + depth / 2.0, cz - depth / 2.0]:
				kit.box("facade", Vector3(x, y0 + fin_height / 2.0 + 0.1, z), Vector3(0.09, fin_height, 0.42), FIN)
		var count_z := int(depth / spacing)
		for index in range(count_z + 1):
			var z := cz - depth / 2.0 + index * spacing
			for x in [cx - width / 2.0, cx + width / 2.0]:
				kit.box("facade", Vector3(x, y0 + fin_height / 2.0 + 0.1, z), Vector3(0.42, fin_height, 0.09), FIN)
	kit.solid(Vector3(0, 11.6, -30.6), Vector3(26, 13.2, 9.6))
	# Roof: parapet and plant screens.
	kit.box("facade", Vector3(0.5, 17.95, -30.6), Vector3(25, 0.5, 9.6), WHITE)
	kit.box("metal", Vector3(-4, 18.8, -31.5), Vector3(5, 1.2, 3), Color("c9cdd0"))
	kit.box("metal", Vector3(5, 18.6, -30), Vector3(3, 0.8, 2.4), Color("c9cdd0"))
	kit.commit(parent, "LearningCenter")

# --- Cedar Residence ---------------------------------------------------------------

## x[-34,-22] z[-12,9], four storeys. Entry on the east face (x = -22) at z = -2.
static func residence(parent: Node3D) -> void:
	var kit := MeshKit.new()
	var face := -22.0
	var floors := 4
	var storey := 3.4
	var height := floors * storey
	kit.solid(Vector3(-28, height / 2.0, -1.5), Vector3(12, height, 21))
	kit.box("facade", Vector3(-28, height / 2.0, -1.5), Vector3(12, height, 21), CREAM)
	kit.box("facade", Vector3(-28, height + 0.35, -1.5), Vector3(12.3, 0.7, 21.3), WHITE)
	# Ground floor: glazed lobby around the entry, stone plinth elsewhere.
	kit.box("facade", Vector3(face + 0.04, 0.45, -1.5), Vector3(0.1, 0.9, 21), STONE)
	for span in [[-6.0, -3.4], [-0.6, 2.0]]:
		kit.box("glass", Vector3(face + 0.06, 1.7, (span[0] + span[1]) / 2.0), Vector3(0.08, 3.0, span[1] - span[0]), Color.WHITE)
	kit.box("glass", Vector3(face + 0.06, 3.1, -2), Vector3(0.08, 0.2, 2.8), Color.WHITE)
	door(kit, Vector3(face + 0.08, 0, -2), 2.4, PI / 2)
	kit.box("facade", Vector3(face + 1.6, 3.3, -2), Vector3(3.2, 0.3, 8.6), WHITE)
	kit.box("wood", Vector3(face + 1.6, 3.12, -2), Vector3(3.0, 0.05, 8.3), Color.WHITE)
	# Upper floors: punched windows with deep frames and orange side fins.
	for level in range(1, floors):
		var y := level * storey + 1.55
		for index in range(7):
			var z := -10.2 + index * 2.6
			if z > 4.5:
				continue # The glazed bay occupies the south end.
			_window(kit, Vector3(face, y, z), PI / 2, index % 3 == 1)
		for index in range(4):
			var x := -32.5 + index * 3.0
			_window(kit, Vector3(x, y, 9.0), 0.0, index % 2 == 0)
			# The north end faces the Anatomy Hall lawn.
			_window(kit, Vector3(x, y, -12.0), PI, index % 2 == 1)
		for index in range(7):
			_window(kit, Vector3(-34.0, y, -9.5 + index * 2.9), -PI / 2, index % 3 == 2)
	# South end of the east face: projecting grey frame with full-height glazing.
	kit.box("facade", Vector3(face + 0.45, height / 2.0 + 1.7, 6.8), Vector3(0.9, height - 3.4, 4.4), GREY)
	kit.box("glass", Vector3(face + 0.92, height / 2.0 + 1.7, 6.8), Vector3(0.06, height - 3.8, 3.8), Color.WHITE)
	for level in range(1, floors):
		kit.box("facade", Vector3(face + 0.98, level * storey + 0.1, 6.8), Vector3(0.1, 0.18, 4.0), GREY.darkened(0.2))
	# Red accent column at the north-east corner, like a stair core.
	kit.box("facade", Vector3(face + 0.3, height / 2.0 + 0.3, -11.4), Vector3(0.7, height + 0.6, 1.3), RED)
	# Roof: parapet cap and a row of solar panels, set back from every edge so
	# none overhangs the facade.
	for index in range(6):
		kit.box("metal", Vector3(-32.4 + index * 1.5, height + 0.95, -6), Vector3(1.35, 0.06, 2.2), Color("27394a"), Basis(Vector3.RIGHT, -0.3))
	kit.commit(parent, "CedarResidence")

## A punched window: recessed glass, dark reveals, a sill and optionally an orange fin.
static func _window(kit: MeshKit, center: Vector3, yaw: float, fin: bool) -> void:
	var basis := Basis(Vector3.UP, yaw)
	kit.box("glass", center + basis * Vector3(0, 0, 0.03), Vector3(1.4, 1.8, 0.04), Color.WHITE, basis)
	for side in [-1, 1]:
		kit.box("facade", center + basis * Vector3(side * 0.74, 0, 0.1), Vector3(0.08, 1.96, 0.2), DARK, basis)
	kit.box("facade", center + basis * Vector3(0, 0.94, 0.1), Vector3(1.56, 0.08, 0.2), DARK, basis)
	kit.box("facade", center + basis * Vector3(0, -0.96, 0.14), Vector3(1.6, 0.08, 0.28), WHITE, basis)
	if fin:
		kit.box("facade", center + basis * Vector3(0.95, 0, 0.25), Vector3(0.28, 2.1, 0.5), ORANGE, basis)

# --- Medical Center ------------------------------------------------------------------

## Backdrop tower in the north-east: two-storey podium with a timber canopy
## and a ten-storey tower of vertical panels and glazing bands.
static func medical_center(parent: Node3D) -> void:
	var kit := MeshKit.new()
	kit.solid(Vector3(26, 4, -29), Vector3(16, 8, 14))
	kit.box("glass", Vector3(26, 4, -29), Vector3(16, 8, 14), Color.WHITE)
	kit.box("facade", Vector3(26, 8.15, -29), Vector3(16.6, 0.3, 14.6), WHITE)
	# Timber canopy along the podium front (south), on slim columns.
	kit.box("facade", Vector3(26, 5.3, -20.4), Vector3(15, 0.4, 3.4), Color("d9d2c4"))
	kit.box("wood", Vector3(26, 5.07, -20.4), Vector3(14.8, 0.06, 3.3), Color.WHITE)
	for x in [19.5, 23.8, 28.2, 32.5]:
		kit.cylinder("metal", Vector3(x, 0, -19.0), Vector3(x, 5.1, -19.0), 0.14, Color("d8dcde"))
		kit.solid(Vector3(x, 1.5, -19.0), Vector3(0.32, 3, 0.32))
	door(kit, Vector3(26, 0, -21.96), 3.2)
	# Tower: glazing behind a rhythm of light and dark vertical panels.
	var base_y := 8.3
	var tower_height := 30.0
	kit.solid(Vector3(28, base_y + tower_height / 2.0, -30), Vector3(12, tower_height, 10))
	kit.box("glass", Vector3(28, base_y + tower_height / 2.0, -30), Vector3(11.6, tower_height, 9.6), Color.WHITE)
	for index in range(24):
		var x := 22.2 + index * 0.5
		var shade := Color("d3d6d8") if index % 3 != 1 else Color("6b747a")
		kit.box("facade", Vector3(x, base_y + tower_height / 2.0, -24.95), Vector3(0.16, tower_height, 0.3), shade)
	for index in range(20):
		var z := -34.8 + index * 0.5
		var shade := Color("d3d6d8") if index % 3 != 1 else Color("6b747a")
		kit.box("facade", Vector3(22.05, base_y + tower_height / 2.0, z), Vector3(0.3, tower_height, 0.16), shade)
	for level in range(9):
		kit.box("facade", Vector3(28, base_y + 3.3 * (level + 1), -30), Vector3(12.3, 0.22, 10.3), Color("e3e5e6"))
	kit.box("facade", Vector3(28, base_y + tower_height + 0.4, -30), Vector3(12.4, 0.8, 10.4), WHITE)
	kit.commit(parent, "MedicalCenter")

# --- Anatomy Hall --------------------------------------------------------------------

## Classical stone hall in the north-west, facing south onto the quad:
## rusticated base, rows of tall windows, cornice and a six-column portico.
static func anatomy_hall(parent: Node3D) -> void:
	var kit := MeshKit.new()
	var stone := Color("e6e1d6")
	var trim := Color("d3cdbf")
	var front := -24.0
	kit.solid(Vector3(-29, 7, -30.5), Vector3(18, 14, 13))
	kit.box("facade", Vector3(-29, 7, -30.5), Vector3(18, 14, 13), stone)
	kit.box("facade", Vector3(-29, 1.0, front - 0.45), Vector3(18.2, 2.0, 0.3), trim)
	kit.box("facade", Vector3(-29, 13.2, front - 0.35), Vector3(18.6, 0.8, 0.5), trim)
	kit.box("facade", Vector3(-29, 14.3, -30.5), Vector3(18.4, 0.6, 13.4), trim)
	for level in range(3):
		for index in range(7):
			var x := -37.0 + index * 2.6
			if absf(x + 29.0) < 3.5 and level == 0:
				continue # Portico entrance.
			var y := 3.2 + level * 3.6
			kit.box("glass", Vector3(x, y, front + 0.03), Vector3(1.1, 2.3, 0.04), Color.WHITE)
			kit.box("facade", Vector3(x, y - 1.25, front + 0.1), Vector3(1.4, 0.14, 0.2), trim)
			kit.box("facade", Vector3(x, y + 1.3, front + 0.1), Vector3(1.4, 0.2, 0.2), trim)
	# Tall windows on the side walls too (both are seen from the lawns).
	for level in range(3):
		for index in range(4):
			var z := -35.4 + index * 3.1
			for side in [[-19.97, PI / 2], [-38.03, -PI / 2]]:
				_classical_window(kit, Vector3(side[0], 3.2 + level * 3.6, z), side[1], trim)
	# Portico: a raised stone floor reached by three steps across its width
	# (colliding as one gentle ramp), handrails, six columns with a wide central
	# bay, entablature and pediment.
	var cx := -29.0
	var deck_top := 0.6
	var deck_front := front + 2.2
	kit.box("facade", Vector3(cx, deck_top / 2.0, (front + deck_front) / 2.0), Vector3(9.8, deck_top, deck_front - front), trim)
	# The floor's collider stops where the ramp reaches its height, so there is no lip.
	kit.solid(Vector3(cx, deck_top / 2.0, (front + deck_front - 0.17) / 2.0), Vector3(9.8, deck_top, deck_front - 0.17 - front))
	kit.box("facade", Vector3(cx, deck_top + 0.005, (front + deck_front) / 2.0), Vector3(9.6, 0.01, deck_front - front - 0.2), stone)
	for step in range(3):
		var top := 0.15 * (step + 1)
		var tread_front := deck_front + (3 - step) * 0.34
		kit.box("facade", Vector3(cx, top / 2.0, tread_front - 0.17), Vector3(9.8 + (3 - step) * 0.2, top, 0.34), trim if step % 2 == 0 else trim.lightened(0.04))
	var slope := atan2(deck_top, 1.36)
	var ramp_basis := Basis(Vector3.RIGHT, slope)
	var ramp_top := Vector3(cx, deck_top / 2.0, deck_front + 0.51)
	kit.solid(ramp_top - ramp_basis.y * 0.05, Vector3(10.2, 0.1, sqrt(deck_top * deck_top + 1.36 * 1.36)), ramp_basis)
	for x in [cx - 4.7, cx + 4.7]:
		for post in [[deck_front + 1.2, 0.0], [deck_front - 0.1, deck_top]]:
			kit.cylinder("metal", Vector3(x, post[1], post[0]), Vector3(x, post[1] + 0.95, post[0]), 0.025, DARK)
		kit.cylinder("metal", Vector3(x, 0.95, deck_front + 1.2), Vector3(x, deck_top + 0.95, deck_front - 0.1), 0.028, DARK)
	for offset in [-3.9, -2.6, -1.3, 1.3, 2.6, 3.9]:
		var x: float = cx + offset
		kit.box("facade", Vector3(x, deck_top + 0.1, front + 1.7), Vector3(0.82, 0.2, 0.82), trim)
		kit.cylinder("facade", Vector3(x, deck_top + 0.2, front + 1.7), Vector3(x, 8.2, front + 1.7), 0.32, stone, 14)
		kit.box("facade", Vector3(x, 8.3, front + 1.7), Vector3(0.85, 0.22, 0.85), trim)
		kit.solid(Vector3(x, 3, front + 1.7), Vector3(0.7, 6, 0.7))
	kit.box("facade", Vector3(cx, 8.8, front + 1.3), Vector3(9.4, 0.9, 2.6), trim)
	kit.box("facade", Vector3(cx, 9.9, front + 1.3), Vector3(9.4, 1.4, 2.4), stone)
	classical_door(kit, Vector3(cx, deck_top, front), 2.0, 3.0, trim)
	kit.commit(parent, "AnatomyHall")
	letters(parent, "ANATOMY HALL", Vector3(-29, 8.8, front + 2.6), 0.0, 0.5, Color("8a7f6c"), 0.04)

## A tall sash window with a stone sill and head, in a wall facing +Z after `yaw`.
static func _classical_window(kit: MeshKit, center: Vector3, yaw: float, trim: Color) -> void:
	var basis := Basis(Vector3.UP, yaw)
	kit.box("glass", center + basis * Vector3(0, 0, 0.0), Vector3(1.1, 2.3, 0.04), Color.WHITE, basis)
	kit.box("facade", center + basis * Vector3(0, 0, 0.03), Vector3(1.1, 0.05, 0.03), trim, basis)
	kit.box("facade", center + basis * Vector3(0, -1.25, 0.08), Vector3(1.4, 0.14, 0.2), trim, basis)
	kit.box("facade", center + basis * Vector3(0, 1.3, 0.08), Vector3(1.4, 0.2, 0.2), trim, basis)

# --- Café pavilion -------------------------------------------------------------------

## Low glazed pavilion east of the quad with a deep timber-soffit roof.
static func pavilion(parent: Node3D) -> void:
	var kit := MeshKit.new()
	kit.solid(Vector3(25, 1.8, -3), Vector3(9, 3.6, 12))
	kit.box("glass", Vector3(25, 1.8, -3), Vector3(9, 3.6, 12), Color.WHITE)
	# Planted green roof inside a slim timber fascia, with a timber soffit below.
	kit.box("facade", Vector3(25, 3.9, -3), Vector3(11.2, 0.3, 14.2), Color("d9d6cf"))
	kit.box("facade", Vector3(25, 4.08, -3), Vector3(10.6, 0.08, 13.6), Color("6f9a4d"))
	for side in [-1, 1]:
		kit.box("wood", Vector3(25 + side * 5.55, 4.0, -3), Vector3(0.12, 0.5, 14.2), Color.WHITE)
		kit.box("wood", Vector3(25, 4.0, -3 + side * 7.05), Vector3(11.2, 0.5, 0.12), Color.WHITE)
	kit.box("wood", Vector3(25, 3.73, -3), Vector3(11.0, 0.06, 14.0), Color.WHITE)
	for x in [19.8, 30.2]:
		for z in [-9.6, 3.6]:
			kit.cylinder("metal", Vector3(x, 0, z), Vector3(x, 3.75, z), 0.1, Color("d8dcde"))
	door(kit, Vector3(20.46, 0, -3), 2.2, -PI / 2)
	kit.commit(parent, "CafePavilion")

# --- University Hospital ---------------------------------------------------------------

## Across the street from the parking lot and the quad: a two-storey podium
## x[-32,24] z[44,70] (glazed, with a white spandrel band and fins on the
## upper floor) and an inpatient tower x[-16,8] z[56,70] set back from the
## street. The main entrance faces east onto a drop-off plaza, under a timber
## canopy, so it faces the overhead camera; the tower is held low and far
## enough back that it never hides the parking lot or the crosswalk.
const HOSPITAL_ENTRANCE := Vector3(27.5, 0, 50)
## The Emergency Department on the south face: the walk-in entrance under a
## red EMERGENCY canopy, and the ambulance bay (a drive-through portal under
## the building, like the covered ambulance garages of downtown trauma
## centers) with its automatic doors at the back.
const ED_ENTRANCE := Vector3(15.0, 0, 70.0)
const AMBULANCE_BAY := Rect2(-9.0, 58.0, 18.0, 12.0)
const AMBULANCE_DOORS := Vector3(0.0, 0, 58.3)
const LIMESTONE := Color("d8d0c0")
const GRANITE := Color("5b5752")
const EMERGENCY_RED := Color("c3302b")

## One glazed block of the podium (the ambulance bay is cut out between blocks).
static func _podium_block(kit: MeshKit, x0: float, x1: float, z0: float, z1: float, y0 := 0.0, y1 := 8.4) -> void:
	var center := Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, (z0 + z1) / 2.0)
	var size := Vector3(x1 - x0, y1 - y0, z1 - z0)
	kit.solid(center, size)
	kit.box("facade", center, size - Vector3(0.6, 0, 0.6), STONE)
	var glass_bottom := maxf(y0, 0.2)
	kit.box("glass", Vector3(center.x, (glass_bottom + 7.6) / 2.0, center.z), Vector3(size.x, 7.6 - glass_bottom, size.z), Color.WHITE)
	if y0 < 0.3:
		kit.box("facade", Vector3(center.x, 0.15, center.z), Vector3(size.x + 0.3, 0.3, size.z + 0.3), Color("b9b4a8"))
		kit.box("facade", Vector3(center.x, 4.15, center.z), Vector3(size.x + 0.4, 0.7, size.z + 0.4), WHITE)
	else:
		kit.box("facade", Vector3(center.x, y0 + 0.2, center.z), Vector3(size.x + 0.4, 0.4, size.z + 0.4), WHITE)
	kit.box("facade", Vector3(center.x, y1 - 0.2, center.z), Vector3(size.x + 0.6, 0.8, size.z + 0.6), WHITE)

static func hospital(parent: Node3D) -> void:
	var kit := MeshKit.new()
	var podium_top := 8.4
	# Podium: glazed blocks around the ambulance bay, which runs under the building.
	var bay := AMBULANCE_BAY
	_podium_block(kit, -32.0, bay.position.x, 44.0, 70.0)
	_podium_block(kit, bay.end.x, 24.0, 44.0, 70.0)
	_podium_block(kit, bay.position.x, bay.end.x, 44.0, bay.position.y)
	_podium_block(kit, bay.position.x, bay.end.x, bay.position.y, 70.0, 4.6)
	_emergency_front(kit, parent)
	# Ground-floor mullions and upper-floor fins along the street (north) and entrance (east) faces.
	for index in range(29):
		var x := -31.5 + index * 2.0
		kit.box("metal", Vector3(x, 1.95, 43.96), Vector3(0.1, 3.6, 0.1), DARK)
	for index in range(47):
		var x := -31.6 + index * 1.2
		kit.box("facade", Vector3(x, 6.2, 43.8), Vector3(0.09, 3.2, 0.42), FIN)
	for index in range(22):
		var z := 44.6 + index * 1.2
		if z > 45.2 and z < 54.8:
			continue # The entrance pavilion stands here.
		kit.box("facade", Vector3(24.2, 6.2, z), Vector3(0.42, 3.2, 0.09), FIN)
	for index in range(13):
		var z := 45.0 + index * 2.0
		if z > 45.2 and z < 54.8:
			continue
		kit.box("metal", Vector3(24.04, 1.95, z), Vector3(0.1, 3.6, 0.1), DARK)
	# Entrance pavilion: a double-height glass box projecting toward the plaza.
	kit.solid(Vector3(25.75, podium_top / 2.0, 50), Vector3(3.5, podium_top, 9))
	kit.box("glass", Vector3(25.75, 3.9, 50), Vector3(3.5, 7.6, 9), Color.WHITE)
	kit.box("facade", Vector3(25.8, podium_top - 0.15, 50), Vector3(3.9, 0.5, 9.4), WHITE)
	for z in [45.6, 47.3, 52.7, 54.4]:
		kit.box("metal", Vector3(27.52, 3.9, z), Vector3(0.1, 7.6, 0.1), DARK)
	kit.box("metal", Vector3(27.52, 3.4, 50), Vector3(0.1, 0.12, 9.0), DARK)
	door(kit, HOSPITAL_ENTRANCE, 3.2, PI / 2)
	# Drop-off canopy over the lane: white slab with a timber soffit, on slim
	# columns beyond the lane's far edge.
	kit.box("facade", Vector3(31.85, 4.6, 50), Vector3(8.7, 0.4, 8.6), WHITE)
	kit.box("wood", Vector3(31.85, 4.38, 50), Vector3(8.5, 0.06, 8.4), Color.WHITE)
	for point in [Vector3(35.9, 0, 46.2), Vector3(35.9, 0, 53.8)]:
		kit.cylinder("metal", point, point + Vector3(0, 4.4, 0), 0.13, Color("d8dcde"))
		kit.solid(point + Vector3(0, 1.5, 0), Vector3(0.3, 3.0, 0.3))
	# Inpatient tower (Levels 3–8): glazing behind light and dark vertical panels.
	var tower_height := 19.5
	var tower_centre := Vector3(-4, podium_top + tower_height / 2.0, 63)
	kit.solid(tower_centre, Vector3(24, tower_height, 14))
	kit.box("glass", tower_centre, Vector3(23.6, tower_height, 13.6), Color.WHITE)
	for index in range(48):
		var x := -15.75 + index * 0.5
		var shade := Color("d3d6d8") if index % 3 != 1 else Color("6b747a")
		for z in [55.95, 70.05]:
			kit.box("facade", Vector3(x, tower_centre.y, z), Vector3(0.16, tower_height, 0.3), shade)
	for index in range(28):
		var z := 56.25 + index * 0.5
		var shade := Color("d3d6d8") if index % 3 != 1 else Color("6b747a")
		kit.box("facade", Vector3(8.05, tower_centre.y, z), Vector3(0.3, tower_height, 0.16), shade)
	for level in range(6):
		kit.box("facade", Vector3(-4, podium_top + 3.25 * (level + 1), 63), Vector3(24.3, 0.22, 14.3), Color("e3e5e6"))
	kit.box("facade", Vector3(-4, podium_top + tower_height + 0.4, 63), Vector3(24.4, 0.8, 14.4), WHITE)
	kit.box("metal", Vector3(-8, podium_top + tower_height + 1.2, 64), Vector3(6, 1.2, 4), Color("c9cdd0"))
	# Green roof on the podium in front of the tower, and rooftop plant.
	kit.box("facade", Vector3(-4, podium_top + 0.22, 49.5), Vector3(54, 0.12, 10), Color("5d8a45"))
	kit.box("metal", Vector3(16, podium_top + 0.7, 64), Vector3(5, 1.2, 3), Color("c9cdd0"))
	kit.commit(parent, "UniversityHospital")
	# Name on the street parapet (seen from the campus), the canopy and the tower.
	letters(parent, "UNIVERSITY HOSPITAL", Vector3(-4, 7.95, 43.7), PI, 0.72, Color("3a4247"))
	letters(parent, "UNIVERSITY HOSPITAL", Vector3(36.22, 4.56, 50), PI / 2, 0.26, Color("3a4247"), 0.03)
	letters(parent, "MAIN ENTRANCE", Vector3(27.62, 3.1, 50), PI / 2, 0.16, Color("3a4247"), 0.03)
	letters(parent, "UNIVERSITY HOSPITAL", Vector3(8.2, podium_top + tower_height - 1.4, 63), PI / 2, 0.9, Color("3a4247"))

## The Emergency Department frontage: limestone pilasters on a granite base,
## the ambulance bay with red walls and automatic doors (the doors themselves
## are added by the campus EMS loop), and the walk-in entrance.
static func _emergency_front(kit: MeshKit, parent: Node3D) -> void:
	var bay := AMBULANCE_BAY
	for x in [-13.0, bay.position.x - 0.45, bay.end.x + 0.45, 12.0, 18.0, 21.0, 23.55]:
		kit.box("facade", Vector3(x, 4.2, 70.2), Vector3(0.9, 8.4, 0.4), LIMESTONE)
		kit.box("facade", Vector3(x, 0.3, 70.24), Vector3(0.96, 0.6, 0.46), GRANITE)
		for groove in [-0.22, 0.22]:
			kit.box("facade", Vector3(x + groove, 4.2, 70.41), Vector3(0.03, 8.0, 0.01), LIMESTONE.darkened(0.12))
	kit.box("facade", Vector3(5.5, 8.5, 70.3), Vector3(37.0, 0.6, 0.5), LIMESTONE)
	# The bay: red-painted walls, a lit soffit, the ED doors at the back.
	var red := Color("a8322c")
	kit.box("facade", Vector3(0, 2.3, bay.position.y + 0.05), Vector3(bay.size.x - 0.2, 4.5, 0.1), red)
	for x in [bay.position.x + 0.05, bay.end.x - 0.05]:
		kit.box("facade", Vector3(x, 2.3, bay.get_center().y), Vector3(0.1, 4.5, bay.size.y), red)
	kit.box("facade", Vector3(0, 4.55, bay.get_center().y), Vector3(bay.size.x, 0.1, bay.size.y), Color("d9dcde"))
	for x in [-5.0, 0.0, 5.0]:
		kit.box("light", Vector3(x, 4.49, bay.get_center().y), Vector3(1.6, 0.02, 0.5), Color("fffaf0"))
	var doors := AMBULANCE_DOORS
	kit.box("facade", Vector3(doors.x, 1.4, bay.position.y + 0.11), Vector3(3.0, 2.8, 0.02), Color("20272b"))
	for side in [-1, 1]:
		kit.box("metal", Vector3(doors.x + side * 1.45, 1.4, bay.position.y + 0.2), Vector3(0.14, 2.8, 0.22), DARK)
	kit.box("metal", Vector3(doors.x, 2.86, bay.position.y + 0.2), Vector3(3.04, 0.14, 0.22), DARK)
	for x in [bay.position.x - 0.6, bay.end.x + 0.6, -3.6, 3.6]:
		kit.cylinder("facade", Vector3(x, 0, 70.9 if absf(x) > 5.0 else bay.position.y + 0.9), Vector3(x, 1.0, 70.9 if absf(x) > 5.0 else bay.position.y + 0.9), 0.11, Color("e0b93a"), 12)
		kit.solid(Vector3(x, 0.5, 70.9 if absf(x) > 5.0 else bay.position.y + 0.9), Vector3(0.24, 1.0, 0.24))
	kit.box("facade", Vector3(0, 4.95, 70.32), Vector3(bay.size.x, 0.62, 0.12), Color("20262b"))
	# Walk-in entrance: glazed doors under a canopy with the red EMERGENCY band.
	door(kit, ED_ENTRANCE, 3.0)
	kit.box("facade", Vector3(ED_ENTRANCE.x, 3.65, 71.7), Vector3(5.8, 0.3, 3.4), Color("e8e6e0"))
	kit.box("facade", Vector3(ED_ENTRANCE.x, 3.35, 73.42), Vector3(5.8, 0.5, 0.06), EMERGENCY_RED)
	for side in [-1, 1]:
		kit.cylinder("metal", Vector3(ED_ENTRANCE.x + side * 2.7, 0, 73.1), Vector3(ED_ENTRANCE.x + side * 2.7, 3.5, 73.1), 0.09, Color("d8dcde"))
		kit.solid(Vector3(ED_ENTRANCE.x + side * 2.7, 1.5, 73.1), Vector3(0.2, 3.0, 0.2))
	# The red EMERGENCY pylon in a planter by the sidewalk.
	kit.solid_box("facade", Vector3(27.2, 0.3, 73.4), Vector3(2.6, 0.6, 1.4), GRANITE)
	kit.box("facade", Vector3(27.2, 0.62, 73.4), Vector3(2.4, 0.04, 1.2), SOIL)
	kit.solid_box("facade", Vector3(27.2, 1.85, 73.4), Vector3(0.9, 2.5, 0.35), EMERGENCY_RED)
	kit.commit(parent, "EmergencyFront")
	letters(parent, "+  AMBULANCE ONLY  +", Vector3(0, 4.95, 70.38), 0.0, 0.34, Color.WHITE, 0.02)
	letters(parent, "EMERGENCY  ·  AMBULANCE ENTRANCE", Vector3(doors.x, 3.25, bay.position.y + 0.12), 0.0, 0.2, Color.WHITE, 0.02)
	letters(parent, "+  EMERGENCY", Vector3(ED_ENTRANCE.x, 3.2, 73.46), 0.0, 0.3, Color.WHITE, 0.02)
	letters(parent, "EMERGENCY", Vector3(ED_ENTRANCE.x, 6.3, 70.42), 0.0, 0.9, EMERGENCY_RED, 0.06)
	letters(parent, "EMERGENCY", Vector3(27.2, 2.6, 73.59), 0.0, 0.16, Color.WHITE, 0.02)
	letters(parent, "<  +", Vector3(27.2, 2.2, 73.59), 0.0, 0.3, Color.WHITE, 0.02)
