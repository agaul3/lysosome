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
	instance.rotation.y = yaw
	# Letters stand proud of the wall by half their depth plus 1 cm.
	instance.position = position + Basis(Vector3.UP, yaw) * Vector3(0, 0, depth / 2.0 + 0.01)
	parent.add_child(instance)
	return instance

## Glazed double door in a frame, set in a wall facing +Z (rotated by yaw about `center`).
static func door(kit: MeshKit, center: Vector3, width: float, yaw := 0.0) -> void:
	var basis := Basis(Vector3.UP, yaw)
	kit.box("metal", center + basis * Vector3(0, 1.3, 0.04), Vector3(width + 0.3, 2.7, 0.1), DARK, basis)
	for side in [-1, 1]:
		kit.box("glass", center + basis * Vector3(side * width / 4.0, 1.2, 0.1), Vector3(width / 2.0 - 0.08, 2.3, 0.04), Color.WHITE, basis)
		kit.box("metal", center + basis * Vector3(side * 0.12, 1.1, 0.14), Vector3(0.05, 0.9, 0.04), Color("c9d0d3"), basis)

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
	kit.box("glass", Vector3(0, 2.2, front - 0.55), Vector3(29.4, 4.4, 0.1), Color.WHITE)
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
	kit.box("glass", Vector3(face + 0.06, 1.7, -2), Vector3(0.08, 3.0, 8), Color.WHITE)
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
	# South end of the east face: projecting grey frame with full-height glazing.
	kit.box("facade", Vector3(face + 0.45, height / 2.0 + 1.7, 6.8), Vector3(0.9, height - 3.4, 4.4), GREY)
	kit.box("glass", Vector3(face + 0.92, height / 2.0 + 1.7, 6.8), Vector3(0.06, height - 3.8, 3.8), Color.WHITE)
	for level in range(1, floors):
		kit.box("facade", Vector3(face + 0.98, level * storey + 0.1, 6.8), Vector3(0.1, 0.18, 4.0), GREY.darkened(0.2))
	# Red accent column at the north-east corner, like a stair core.
	kit.box("facade", Vector3(face + 0.3, height / 2.0 + 0.3, -11.4), Vector3(0.7, height + 0.6, 1.3), RED)
	# Roof: parapet cap and a row of solar panels.
	for index in range(6):
		kit.box("metal", Vector3(-30.5 + index * 1.6, height + 0.95, -6), Vector3(1.4, 0.06, 2.2), Color("27394a"), Basis(Vector3.RIGHT, -0.3))
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
	# Portico: steps, six columns, entablature and pediment.
	for step in range(3):
		kit.solid_box("facade", Vector3(-29, 0.1 + step * 0.2, front + 2.6 - step * 0.5), Vector3(9.6 - step * 0.4, 0.2, 1.4), trim)
	for index in range(6):
		var x := -32.75 + index * 1.5
		kit.cylinder("facade", Vector3(x, 0.6, front + 1.6), Vector3(x, 8.2, front + 1.6), 0.32, stone, 14)
		kit.box("facade", Vector3(x, 8.3, front + 1.6), Vector3(0.85, 0.22, 0.85), trim)
		kit.solid(Vector3(x, 3, front + 1.6), Vector3(0.7, 6, 0.7))
	kit.box("facade", Vector3(-29, 8.8, front + 1.3), Vector3(9.4, 0.9, 2.6), trim)
	kit.box("facade", Vector3(-29, 9.9, front + 1.3), Vector3(9.4, 1.4, 2.4), stone, Basis(Vector3.BACK, 0.0).scaled(Vector3(1, 1, 1)))
	door(kit, Vector3(-29, 0.6, front + 0.02), 2.6)
	kit.commit(parent, "AnatomyHall")
	letters(parent, "ANATOMY HALL", Vector3(-29, 8.8, front + 2.6), 0.0, 0.5, Color("8a7f6c"), 0.04)

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
