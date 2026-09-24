extends "res://tests/campus_test.gd"
## Ambient campus life: students on benches (lunch, reading, notes), the dog
## walker roaming the south-east lawn, and students strolling the paths.
## Checks placement, variety, bounds, the leash, that everything keeps moving,
## and that pedestrians make way for the player.
# Loaded at run time: these scripts use autoloads, which a --script test
# cannot resolve at compile time.
var Campus: GDScript
var Pedestrian: GDScript
var Student: GDScript

func _run() -> void:
	Campus = load("res://world/campus/campus.gd")
	Pedestrian = load("res://npc/ambient/pedestrian.gd")
	Student = load("res://npc/student.gd")
	state = root.get_node("AppState")
	state.start_new_game()
	state.select_character("indigo")
	state.enter_dorm()
	await acquire_world()
	state.enter_campus("dorm")
	await acquire_world()
	check(dorm.name == "Campus", "Campus loaded")
	# Park the player well away from the quad so nobody yields to them.
	player.movement_enabled = false
	player.global_position = Vector3(-19, 0.05, 8)
	await check_benches()
	await check_dog_walker()
	await check_pedestrians()
	print("AMBIENT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check_benches() -> void:
	var students: Array = dorm.bench_students
	check(students.size() == Campus.BENCH_STUDENTS.size(), "Bench students placed (%d)" % students.size())
	var activities := {}
	var seated := true
	var on_bench := true
	var hips_on_seat := true
	var props := true
	for index in range(students.size()):
		var student: Node3D = students[index]
		var entry: Array = Campus.BENCH_STUDENTS[index]
		var bench: Array = Campus.BENCHES[entry[0]]
		activities[student.activity] = true
		seated = seated and student.figure.seated_pose
		on_bench = on_bench and student.global_position.distance_to(bench[0]) < 0.6
		var hip_height: float = student.figure.pelvis.global_position.y
		hips_on_seat = hips_on_seat and hip_height > 0.3 and hip_height < 0.5
		match student.activity:
			"lunch":
				props = props and student.find_child("Bread", true, false) != null and student.find_child("LunchBox", true, false) != null
			"reading":
				props = props and student.find_child("Book", true, false) != null
			"notes":
				props = props and student.find_child("Notebook", true, false) != null and student.find_child("Pen", true, false) != null
		# Seated students face out from the bench, the way its seat faces.
		var facing: Vector3 = student.global_basis * Vector3.FORWARD
		var seat_facing := Basis(Vector3.UP, bench[1]) * Vector3.FORWARD
		on_bench = on_bench and facing.dot(seat_facing) > 0.99
	check(activities.has("lunch") and activities.has("reading") and activities.has("notes"), "Students eat lunch, read and take notes")
	check(seated, "Bench students use the seated pose")
	check(on_bench, "Each student sits on their bench, facing out")
	check(hips_on_seat, "Hips rest on the slats (seat height)")
	check(props, "Activity props: sandwich and lunch box, book, notebook and pen")
	var plaza_facing := true
	for index in range(9, 13):
		var bench: Array = Campus.BENCHES[index]
		var to_planter: Vector3 = (Campus.PLAZA_CENTER - bench[0]).normalized()
		plaza_facing = plaza_facing and (Basis(Vector3.UP, bench[1]) * Vector3.FORWARD).dot(to_planter) > 0.99
	check(plaza_facing, "Plaza benches face the planter")
	var occupied := {}
	for entry in Campus.BENCH_STUDENTS:
		occupied[entry[0]] = true
	check(dorm.get_node("SeatedFeetColliders").get_child_count() == occupied.size(), "Seated knees and feet are solid on occupied benches")
	# Everyone gestures (bite, page turn, look up) on their own random timing.
	var starts := {}
	var arm_moved := {}
	var first_done := {}
	for student in students:
		starts[student] = student.figure.shoulders[1].rotation
	for tick in range(600):
		await ticks(1)
		for student in students:
			if not student.figure.shoulders[1].rotation.is_equal_approx(starts[student]):
				arm_moved[student] = true
			if student.gestures_done >= 1 and not first_done.has(student):
				first_done[student] = tick
	var gestured := true
	for student in students:
		gestured = gestured and student.gestures_done >= 1
	check(gestured, "Every bench student completes a gesture")
	check(arm_moved.size() == students.size(), "Arms move (eating, turning pages, writing)")
	var distinct := {}
	for student in first_done:
		distinct[first_done[student]] = true
	check(distinct.size() > students.size() / 2, "Gestures are not in lockstep (%d distinct timings)" % distinct.size())

func check_dog_walker() -> void:
	var walk: Node3D = dorm.dog_walker
	var lawn: Array = Campus.LAWNS[3]
	var region: Rect2 = walk.region
	check(region == Campus.DOG_LAWN, "Dog walker keeps to the defined lawn")
	check(region.position.x >= lawn[0] and region.position.y >= lawn[1] and region.end.x <= lawn[2] and region.end.y <= lawn[3], "The roaming area is grass")
	var walker_blocker: Node = walk.walker.get_node("Blocker")
	var dog_blocker: Node = walk.dog.get_node("Blocker")
	check(walker_blocker.collision_layer == Student.NPC_LAYER and dog_blocker.collision_layer == Student.NPC_LAYER, "Walker and dog are solid to the player")
	var inside := true
	var leashed := true
	var clear := true
	var leash_attached := true
	var sags := true
	var walker_path := 0.0
	var dog_path := 0.0
	var targets := {}
	var last_walker: Vector3 = walk.walker.position
	var last_dog: Vector3 = walk.dog.position
	for sample in range(240):
		await ticks(15)
		var w: Vector3 = walk.walker.position
		var d: Vector3 = walk.dog.position
		walker_path += w.distance_to(last_walker)
		dog_path += d.distance_to(last_dog)
		last_walker = w
		last_dog = d
		targets[walk.walker_target] = true
		for point in [Vector2(w.x, w.z), Vector2(d.x, d.z)]:
			inside = inside and region.grow(0.01).has_point(point)
			for entry in walk.avoid:
				clear = clear and point.distance_to(entry[0]) >= entry[1] - 0.01
		leashed = leashed and Vector2(d.x - w.x, d.z - w.z).length() <= walk.LEASH + 0.01
		var segments: Array = walk.leash_segments
		var hand: Vector3 = walk.hand_position()
		var collar: Vector3 = walk.dog.collar.global_position
		leash_attached = leash_attached and segments[0].global_position.distance_to(hand) < 0.6 and segments[-1].global_position.distance_to(collar) < 0.6
		var middle: Vector3 = segments[3].global_position
		sags = sags and middle.y < hand.lerp(collar, 4.0 / 7.0).y + 0.001
	check(inside, "Walker and dog stay inside the lawn for a minute")
	check(clear, "Neither walks into the bench on the lawn's edge")
	check(leashed, "The dog never gets further than the leash allows")
	check(leash_attached and sags, "The leash runs hand to collar and sags")
	check(walker_path > 4.0, "The walker wanders (%.1f m)" % walker_path)
	check(targets.size() >= 3, "Walk targets are random points (%d)" % targets.size())
	check(dog_path > walker_path, "The dog covers more ground than the walker (%.1f m)" % dog_path)
	check(walk.moods_seen.size() >= 3, "The dog changes what it is doing (%d moods)" % walk.moods_seen.size())

func check_pedestrians() -> void:
	var walkers: Array = dorm.pedestrians
	check(walkers.size() == 3, "Students stroll the paths")
	var start := {}
	for walker in walkers:
		start[walker] = walker.distance_walked
	var on_paths := true
	for sample in range(80):
		await ticks(15)
		for walker in walkers:
			var point := Vector2(walker.figure.position.x, walker.figure.position.z)
			on_paths = on_paths and Pedestrian.distance_to_paths(point) <= Pedestrian.ASIDE * 1.5
	var walking := true
	for walker in walkers:
		walking = walking and walker.distance_walked - start[walker] > 6.0
		walking = walking and walker.figure.get_node("Blocker").collision_layer == Student.NPC_LAYER
	check(walking, "Each keeps walking and is solid")
	check(on_paths, "Pedestrians keep to the paths")
	# Stand in one pedestrian's way on the north walk: they step aside and pass.
	var walker: Node3D = walkers[0]
	walker.from_node = 0
	walker.to_node = 1
	walker.path_point = Pedestrian.NODES[0].lerp(Pedestrian.NODES[1], 0.2)
	walker.figure.position = Vector3(walker.path_point.x, 0, walker.path_point.y)
	walker.aside = 0.0
	walker.pause = 0.0
	walker.yielding = false
	player.global_position = Vector3(walker.path_point.x + 1.9, 0.05, walker.path_point.y)
	await ticks(2)
	var closest := INF
	var stepped := 0.0
	var passed := false
	for index in range(480):
		await ticks(1)
		var gap := Vector2(walker.figure.position.x - player.global_position.x, walker.figure.position.z - player.global_position.z).length()
		closest = minf(closest, gap)
		stepped = maxf(stepped, absf(walker.aside))
		if walker.path_point.x > player.global_position.x + 1.0:
			passed = true
			break
	check(stepped > 0.6, "A pedestrian steps aside for the player (%.2f m)" % stepped)
	check(passed, "They walk on past the player")
	check(closest > 0.5, "They never walk into the player (%.2f m)" % closest)
	player.global_position = Vector3(-19, 0.05, 8)
	await ticks(180)
	check(absf(walker.aside) < 0.05, "Back to the middle of the path once clear")
