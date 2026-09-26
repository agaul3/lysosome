extends "res://tests/ed_clearance_test.gd"
## The first-year buildings' passers-by (npc/ambient/pedestrian.gd) walk
## their path graphs without physics, like the Emergency Department's people.
## For each building this sweeps every edge of every walker's graph (the
## centre lane and both step-aside lanes, which honour the walker's keep-clear
## areas) against the building's geometry, recorded by building every zone
## again into recording kits, plus its chairs (and the legs of whoever sits in
## them) and its standing figures.
const BUILDINGS := [
	["med_ed", "res://world/med_ed/med_ed.tscn"],
	["library", "res://world/library/library.tscn"],
	["student_center", "res://world/student_center/student_center.tscn"],
	["anatomy", "res://world/anatomy/anatomy.tscn"],
	["community", "res://world/community/community.tscn"],
]

func _run() -> void:
	state = root.get_node("AppState")
	for entry in BUILDINGS:
		if not ResourceLoader.exists(entry[1]):
			continue
		await _building(String(entry[0]), String(entry[1]))
	print("INTERIOR CLEARANCE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _building(key: String, path: String) -> void:
	state.start_new_game()
	state.phase = state.PHASE_BY_SCENE[key]
	state.interior_entry = "main"
	state.med_ed_entry = "main"
	change_scene_to_file(path)
	await acquire_world()
	await ticks(3)
	var building: Node3D = dorm
	geometry = []
	grid = {}
	var seats: Array = building.seats.duplicate()
	var figures := _figures(building)
	_record(building)
	for seat in seats:
		_add_seat(seat)
	geometry.append_array(figures)
	_index()
	check(geometry.size() > 300, "%s: recorded %d boxes, %d chairs, %d standing figures" % [key, geometry.size(), seats.size(), figures.size()])
	check(not building.walkers.is_empty(), "%s: has passers-by" % key)
	found = []
	var graphs := {}
	for walker in building.walkers:
		graphs[walker.nodes] = walker
	for nodes in graphs:
		var walker: Node3D = graphs[nodes]
		for edge in walker.edges:
			var a: Vector2 = walker.nodes[edge[0]]
			var b: Vector2 = walker.nodes[edge[1]]
			for lane in [0.0, -float(walker.aside_width), float(walker.aside_width)]:
				var shift: Vector2 = (b - a).normalized().orthogonal() * lane
				_walk("%s-%s%s" % [edge[0], edge[1], "" if lane == 0.0 else (" aside %+.1f" % lane)], Vector3(a.x + shift.x, 0, a.y + shift.y), [Vector3(b.x + shift.x, 0, b.y + shift.y)], walker.obstacles if lane != 0.0 else [])
	for note in found:
		print("  ", key, " ", note)
	for argument in OS.get_cmdline_user_args():
		if argument == "--map=" + key:
			_print_map(building)
	check(found.is_empty(), "%s: passers-by keep clear of furniture, walls and people%s" % [key, "" if found.is_empty() else ": " + "; ".join(found.slice(0, 6))])
	change_scene_to_file("res://ui/start_screen.tscn")
	await scene_changed
	await ticks(2)

## Every zone built again into recorders (the builders are deterministic);
## only what a standing figure can touch.
func _record(building: Node3D) -> void:
	var scratch := Node3D.new()
	scratch.name = "ClearanceScratch"
	scratch.visible = false
	building.add_child(scratch)
	building.build_root = scratch
	var recorded: Array = []
	var zones: Dictionary = building.zones()
	var builders: Dictionary = building.builders()
	for zone_name in zones:
		var kit = Kit.new(zones[zone_name].origin)
		kit.layers = {"always": Recorder.new(recorded, "always"), "fp": Recorder.new(recorded, "fp"), "tp": Recorder.new(recorded, "tp")}
		builders[zone_name].build(building, kit)
	building.build_root = building
	for box in recorded:
		if box.l == "tp":
			continue
		var half := _half_height(box)
		if box.c.y + half < 0.07 or box.c.y - half > 1.85:
			continue
		geometry.append(box)

## A chair's footprint, and the seated legs in front of it when it's taken.
func _add_seat(seat: Node3D) -> void:
	var basis := Basis(Vector3.UP, seat.global_rotation.y)
	geometry.append({"c": seat.global_position + Vector3(0, 0.45, 0), "s": Vector3(seat.width, 0.9, 0.55), "b": basis, "l": "seat", "k": "chair " + String(seat.name)})
	if seat.occupied:
		geometry.append({"c": seat.global_position + basis * Vector3(0, 0.25, -0.42), "s": Vector3(0.48, 0.5, 0.32), "b": basis, "l": "seat", "k": "seated legs " + String(seat.name)})

## Standing figures the builders placed (those with an NPC blocker), not the walkers.
func _figures(building: Node3D) -> Array:
	var result: Array = []
	for blocker in building.find_children("Blocker", "AnimatableBody3D", true, false):
		var moving := false
		var node: Node = blocker.get_parent()
		while node != null and node != building:
			var script: Script = node.get_script()
			if script != null and script.resource_path.ends_with("pedestrian.gd"):
				moving = true
				break
			node = node.get_parent()
		if moving or not blocker.is_visible_in_tree() and not _in_zone_root(building, blocker):
			continue
		var at: Vector3 = blocker.global_position
		result.append({"c": Vector3(at.x, 0.9, at.z), "s": Vector3(0.5, 1.8, 0.5), "b": Basis.IDENTITY, "l": "figure", "k": "standing figure", "node": blocker})
	return result

## Figures on a floor the student isn't on are hidden, but still count.
func _in_zone_root(building: Node3D, node: Node) -> bool:
	for root_node in building.zone_roots.values():
		if root_node.is_ancestor_of(node):
			return true
	return false

## Debugging aid (--map=<building>): each zone's plan in 0.5 m cells, north
## up: # geometry, h chair, P standing figure, digits the walkers' nodes.
func _print_map(building: Node3D) -> void:
	var zones: Dictionary = building.zones()
	for zone_name in zones:
		var origin: Vector3 = zones[zone_name].origin
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for box in geometry:
			if box.k != "collider" or absf(box.c.z - origin.z) > 60.0 or absf(box.c.x - origin.x) > 60.0:
				continue
			var reach := _reach(box)
			lo = Vector2(minf(lo.x, box.c.x - reach.x), minf(lo.y, box.c.z - reach.y))
			hi = Vector2(maxf(hi.x, box.c.x + reach.x), maxf(hi.y, box.c.z + reach.y))
		print("ZONE %s  x %.1f..%.1f  z %.1f..%.1f (0.5 m cells)" % [zone_name, lo.x, hi.x, lo.y, hi.y])
		var labels := {}
		for walker in building.walkers:
			for index in range(walker.nodes.size()):
				var node: Vector2 = walker.nodes[index]
				labels[Vector2i(floori(node.x * 2.0), floori(node.y * 2.0))] = str(index % 10) if index < 10 else char(65 + index - 10)
		var ruler := "      "
		var cx := floori(lo.x * 2.0)
		while cx < ceili(hi.x * 2.0):
			if cx % 10 == 0:
				var text := str(cx / 2)
				ruler += text
				cx += text.length()
			else:
				ruler += " "
				cx += 1
		print(ruler)
		for cz in range(floori(lo.y * 2.0), ceili(hi.y * 2.0)):
			var line := "%6.1f" % (cz / 2.0)
			for column in range(floori(lo.x * 2.0), ceili(hi.x * 2.0)):
				var here := Vector3(column / 2.0 + 0.25, 0, cz / 2.0 + 0.25)
				var mark := " "
				if labels.has(Vector2i(column, cz)):
					mark = labels[Vector2i(column, cz)]
				else:
					for index in grid.get(Vector2i(floori(here.x), floori(here.z)), []):
						var box: Dictionary = geometry[index]
						if _overlap(here, 0.0, Vector2(0.24, 0.24), box) > 0.0:
							mark = "P" if box.l == "figure" else ("h" if box.l == "seat" else "#")
							if mark != "#":
								break
				line += mark
			print(line)
