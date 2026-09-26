extends "res://tests/east_campus_test.gd"
## University Hospital's Food Court: through the glass doors off the clinics
## corridor and back, ordering at a counter, a seat at a communal table (and
## the laptop there), the lobby café's counter, and the diners' walking loop
## kept clear of the tables, counters and coolers (they move without
## physics), in both camera views.
var hospital: Node3D

func _run() -> void:
	create_timer(300.0).timeout.connect(func() -> void:
		push_error("Food court test timed out")
		quit(2))
	state = root.get_node("AppState")
	state.start_new_game()
	state.equip("back", "slate_backpack")
	root.get_node("YearCalendar").advance_to(Time.get_unix_time_from_datetime_string("2026-09-23T12:30:00"))
	state.phase = state.Phase.CAMPUS
	state.campus_entry = "hospital"
	change_scene_to_file("res://world/campus/campus.tscn")
	await acquire_world()
	await ticks(3)
	if not await go(func() -> void: state.enter_hospital(), "Enter the hospital"):
		quit(1)
		return
	hospital = dorm
	for walker in hospital.visitors:
		if walker.get_parent() != hospital.zone_roots.food_court:
			walker.process_mode = Node.PROCESS_MODE_DISABLED
			walker.figure.position = Vector3(0, -60, 0)
	print("- lobby café")
	await lobby_cafe()
	print("- to the food court")
	await into_food_court()
	print("- ordering")
	await ordering()
	print("- a seat")
	await sitting()
	print("- walking loop")
	walking_loop()
	await views()
	print("- back to the lobby")
	await back_to_lobby()
	print("FOOD COURT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func lobby_cafe() -> void:
	await place(Vector3(11.6, 0, -7.5), -PI / 2)
	await reach(Vector3(12.4, 0, -7.5), hospital.shops.atrium_cafe, "The Atrium Café's counter")
	await press_interact()
	await ticks(2)
	var panel: Control = hospital.hud.modal
	check(is_instance_valid(panel) and panel.find_child("Buy_drip_coffee", true, false) != null, "The café sells coffee")
	panel.close()
	await ticks(2)

func into_food_court() -> void:
	await place(Vector3(15.5, 0, -16.0), 0.0)
	await walk_to(Vector3(15.5, 0, -19.4))
	await reach(Vector3(15.2, 0, -20.0), hospital.lobby_to_food_court, "The Food Court's doors")
	await capture("lobby-food-court-doors")
	state.set_first_person(true)
	player.appearance.rotation.y = PI / 2
	player.first_person.yaw = PI / 2
	await ticks(4)
	await capture("lobby-food-court-doors-fp")
	state.set_first_person(false)
	await ticks(2)
	await press_interact()
	for index in range(120):
		await ticks(1)
		if hospital.zone == "food_court" and player.movement_enabled:
			break
	check(hospital.zone == "food_court" and player.global_position.distance_to(hospital.anchor("food_court_entrance")) < 0.4, "Through the doors into the Food Court")
	check(hospital.hud.location_title.contains("Food Court"), "The location shows the Food Court")
	check(hospital.zone_roots.food_court.visible and not hospital.zone_roots.lobby.visible, "Only the food court is shown")
	check(state.hospital_entry == "main", "A save here resumes at the main entrance")

func ordering() -> void:
	var offset: Vector3 = hospital.FOOD_COURT_OFFSET
	await walk_to(offset + Vector3(11.0, 0, -4.4))
	await reach(offset + Vector3(8.5, 0, -5.0), hospital.shops.hospital_coffee, "Rounds Coffee's counter")
	var wallet: Node = root.get_node("Wallet")
	var balance: int = wallet.balance
	await press_interact()
	await ticks(2)
	var panel: Control = hospital.hud.modal
	check(is_instance_valid(panel) and panel.find_child("Buy_matcha_latte", true, false) != null, "Rounds Coffee's menu opens")
	if is_instance_valid(panel):
		(panel.find_child("Buy_matcha_latte", true, false) as Button).pressed.emit()
		await ticks(1)
		panel.close()
		await ticks(2)
	check(wallet.balance < balance and root.get_node("Wellbeing").active_boosts().any(func(boost: Dictionary) -> bool: return boost.name == "Calm Focus"), "A matcha latte: paid for, with its boost")
	await walk_to(offset + Vector3(0.0, 0, -4.4))
	await reach(offset + Vector3(0.0, 0, -5.0), hospital.shops.hospital_market, "Fresh Market's counter")
	await walk_to(offset + Vector3(-7.2, 0, -4.4))
	await reach(offset + Vector3(-8.5, 0, -5.0), hospital.shops.hospital_grill, "Grill 24's counter")

func sitting() -> void:
	var free: Array = hospital.seats.filter(func(seat: Node3D) -> bool: return not seat.occupied)
	check(hospital.seats.size() == 12 and free.size() == 8, "Two communal tables: twelve seats, four taken by staff on their break")
	var seat: Node3D = free[0]
	player.global_position = seat.global_transform * Vector3(0.9, 0.05, -0.45)
	player.velocity = Vector3.ZERO
	await ticks(2)
	player.seating.request(seat)
	for index in range(650):
		await ticks(1)
		if player.seating.state == player.seating.State.SEATED:
			break
	check(player.seating.state == player.seating.State.SEATED, "Sit at a communal table")
	check(hospital.hud.can_use_laptop(), "The laptop can come out at the table")
	player.seating.stand_up()
	for index in range(400):
		await ticks(1)
		if player.seating.state == player.seating.State.FREE:
			break
	check(player.seating.state == player.seating.State.FREE and player.movement_enabled, "Stand up again")
	# Out from between the chairs to the aisle.
	await place(hospital.FOOD_COURT_OFFSET + Vector3(-2.2, 0, 0.4), -PI / 2)

## Samples each leg of the diners' loop, on the path and at the edges of the
## lane they step into, with a body-sized shape against the room's colliders.
func walking_loop() -> void:
	var diners: Array = hospital.visitors.filter(func(walker: Node3D) -> bool: return walker.get_parent() == hospital.zone_roots.food_court)
	check(diners.size() == 2, "Two diners walk the food court")
	if diners.is_empty():
		return
	var walker: Node3D = diners[0]
	var space := hospital.get_world_3d().direct_space_state
	var shape := CylinderShape3D.new()
	shape.radius = 0.28
	shape.height = 1.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collide_with_areas = false
	var exclude: Array[RID] = [player.get_rid()]
	for other in hospital.visitors:
		for body in other.find_children("*", "CollisionObject3D", true, false):
			exclude.append(body.get_rid())
	query.exclude = exclude
	var blocked: Array = []
	for edge in walker.edges:
		var a: Vector2 = walker.nodes[edge[0]]
		var b: Vector2 = walker.nodes[edge[1]]
		var side := (b - a).normalized().orthogonal()
		var steps := int((b - a).length() / 0.25)
		for step in range(steps + 1):
			var point := a.lerp(b, step / float(maxi(steps, 1)))
			for lane in [0.0, walker.aside_width, -walker.aside_width]:
				var at: Vector2 = point + side * lane
				query.transform = Transform3D(Basis.IDENTITY, Vector3(at.x, 0.85, at.y))
				if not space.intersect_shape(query, 1).is_empty():
					blocked.append("%.1f,%.1f" % [at.x, at.y - hospital.FOOD_COURT_OFFSET.z])
	check(blocked.is_empty(), "The diners' loop and its side lanes are clear %s" % str(blocked.slice(0, 6)))

func views() -> void:
	await capture("food-court-overhead")
	state.set_first_person(true)
	await ticks(3)
	player.appearance.rotation.y = PI / 2
	player.first_person.yaw = PI / 2
	await ticks(3)
	await capture("food-court-first-person")
	player.appearance.rotation.y = 0.0
	player.first_person.yaw = 0.0
	await ticks(3)
	await capture("food-court-servery")
	check(hospital.layers.all(func(pair: Array) -> bool: return pair[0].visible), "First person shows the whole building")
	state.set_first_person(false)
	await ticks(2)

func back_to_lobby() -> void:
	# The diners are solid and walk this way too; park them.
	for walker in hospital.visitors:
		walker.process_mode = Node.PROCESS_MODE_DISABLED
		walker.figure.position = Vector3(0, -60, 0)
	await ticks(2)
	var offset: Vector3 = hospital.FOOD_COURT_OFFSET
	await walk_to(offset + Vector3(4.0, 0, 0.4))
	await walk_to(offset + Vector3(11.6, 0, 0.4))
	await reach(offset + Vector3(12.6, 0, 0.0), hospital.food_court_to_lobby, "The doors back to the lobby")
	await press_interact()
	for index in range(120):
		await ticks(1)
		if hospital.zone == "lobby" and player.movement_enabled:
			break
	check(hospital.zone == "lobby" and player.global_position.distance_to(Vector3(15.5, 0, -20.0)) < 0.4, "Back in the clinics corridor")
