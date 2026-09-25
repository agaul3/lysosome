extends "res://tests/campus_test.gd"
## Scripted people in the Emergency Department and Emergency Radiology walk
## authored routes without physics, so nothing stops them clipping through the
## furniture except the routes themselves. This sweeps every kind of route
## (walk-ins, triage calls, discharges, EMS cots to each bay and backing out,
## wheelchair and radiology transports, staff paths and their step-aside
## lanes) against every piece of both floors' geometry, visual boxes as well
## as colliders, and the standing figures.
##
## The geometry is recorded by building the two floors again into recording
## kits (the builders are deterministic); a person is a box the size of a
## figure's arm span, a cart is its footprint plus its crew, and at every
## corner the cart is assumed to turn on the spot (stricter than the eased
## turn it makes while moving).
const Kit = preload("res://world/hospital/hospital_kit.gd")
const EDBuilder = preload("res://world/hospital/hospital_ed.gd")
const ImagingBuilder = preload("res://world/hospital/hospital_imaging.gd")
const AmbulanceScript = preload("res://world/hospital/ambulance.gd")
## Half the figure's arm span, and half its depth (with the arms swinging).
const FIGURE := Vector2(0.42, 0.2)
## Deeper than this counts as clipping (a touch doesn't).
const TOLERANCE := 0.03

class Recorder extends "res://world/campus/mesh_kit.gd":
	var boxes: Array
	var layer: String
	func _init(target: Array, layer_name: String) -> void:
		boxes = target
		layer = layer_name
	func box(kind: String, center: Vector3, size: Vector3, color: Color, basis := Basis.IDENTITY) -> void:
		boxes.append({"c": center, "s": size, "b": basis, "l": layer, "k": kind})
	func solid(center: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
		boxes.append({"c": center, "s": size, "b": basis, "l": "solid", "k": "collider"})
	func cylinder(kind: String, a: Vector3, b: Vector3, radius: float, color: Color, segments := 10) -> void:
		var lo := Vector3(minf(a.x, b.x) - radius, minf(a.y, b.y) - radius, minf(a.z, b.z) - radius)
		var hi := Vector3(maxf(a.x, b.x) + radius, maxf(a.y, b.y) + radius, maxf(a.z, b.z) + radius)
		boxes.append({"c": (lo + hi) / 2.0, "s": hi - lo, "b": Basis.IDENTITY, "l": layer, "k": kind + " cylinder"})

var hospital: Node3D
var life: Node
var geometry: Array = []
## 1 m grid of geometry indices.
var grid := {}
## Overlaps found by the current category.
var found: Array = []

func _run() -> void:
	state = root.get_node("AppState")
	state.start_new_game()
	state.phase = state.Phase.HOSPITAL
	state.hospital_entry = "ed"
	change_scene_to_file("res://world/hospital/hospital.tscn")
	await acquire_world()
	await ticks(5)
	hospital = dorm
	life = hospital.ed_life
	life.next_ems = 1.0e6
	var figures := _static_figures()
	var routes := _collect_routes()
	_record_geometry()
	geometry.append_array(figures)
	_index()
	check(geometry.size() > 1500 and figures.size() >= 10, "Recorded both floors (%d boxes, %d standing figures)" % [geometry.size(), figures.size()])
	for category in routes:
		found = []
		for route in routes[category]:
			if route.kind == "walker":
				_walk(route.label, route.start, route.points, route.get("keep_clear", []))
			else:
				_cart(route)
		check(found.is_empty(), "%s keep clear of furniture, walls and people%s" % [category, "" if found.is_empty() else ": " + "; ".join(found.slice(0, 4))])
	print("ED CLEARANCE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

# --- Routes ------------------------------------------------------------------------------------

func _collect_routes() -> Dictionary:
	var layout: Dictionary = life.layout
	var imaging: Dictionary = life.imaging
	var points: Dictionary = layout.points
	var routes := {"Walk-ins": [], "Triage calls": [], "Discharges": [], "EMS cots": [], "Wheelchair transports": [], "Radiology transports": [], "Staff": []}
	# Walk-ins: one to every free seat, from the real route builder.
	var free: int = layout.waiting_seats.filter(func(seat: Dictionary) -> bool: return seat.occupant == null).size()
	for index in range(free):
		var before: int = life.walkers.size()
		life.spawn_walkin()
		if life.walkers.size() > before:
			var walker: Node3D = life.walkers[-1]
			routes["Walk-ins"].append({"kind": "walker", "label": "walk-in %d" % index, "start": points.walkin_outside, "points": _points(walker.steps)})
			walker.visible = false
	# Triage calls: every seated waiting patient, with a recliner free each time.
	for attempt in range(12):
		for recliner in layout.recliners:
			recliner.occupant = null
		var seated: Array = layout.waiting_seats.filter(func(seat: Dictionary) -> bool: return seat.occupant != null and is_instance_valid(seat.occupant) and seat.occupant.is_sitting())
		if seated.is_empty():
			break
		var candidates: Array = seated.map(func(seat: Dictionary) -> Node3D: return seat.occupant)
		life.call_from_waiting()
		for walker in candidates:
			if walker.motion == "rising" and not walker.steps.is_empty():
				var way := _points(walker.steps)
				routes["Triage calls"].append({"kind": "walker", "label": "call %d" % attempt, "start": way[0], "points": way.slice(1)})
				walker.steps = []
	# Discharges from every recliner and every acute room.
	for index in range(layout.recliners.size()):
		var recliner: Dictionary = layout.recliners[index]
		var way := _points(life.recliner_discharge_route(recliner))
		routes["Discharges"].append({"kind": "walker", "label": "home from ST%d" % (index + 1), "start": way[0], "points": way.slice(1)})
	for bay in layout.bays:
		if bay.kind == "acute":
			routes["Discharges"].append({"kind": "walker", "label": "home from room %s" % bay.id, "start": bay.inside, "points": _points(life.room_discharge_route(bay))})
	# EMS cots to every bay the department sends them to, and backing out.
	var ambulance: Node3D = AmbulanceScript.new()
	hospital.zone_roots.ed.add_child(ambulance)
	ambulance.place(layout.garage.stop, AmbulanceScript.yaw_of(Vector3.RIGHT))
	life.ambulance = ambulance
	for bay in layout.bays:
		if bay.occupied and bay.kind == "trauma":
			continue # The active resuscitations stay; they are never a destination.
		var way: Array = life.route_to_bay(bay)
		var side := -signf(float(bay.park.x) - float(bay.center.x))
		routes["EMS cots"].append({"kind": "cart", "label": "EMS to %s" % bay.bed, "start": ambulance.rear_point(1.6), "points": way, "length": 2.08, "width": 0.7, "side": side, "partner": true, "back_out": 0, "ignore": [bay.patient]})
		var back := way.duplicate()
		back.reverse()
		routes["EMS cots"].append({"kind": "cart", "label": "EMS from %s" % bay.bed, "start": bay.park, "points": back.slice(1), "length": 2.08, "width": 0.7, "side": side, "partner": true, "back_out": 3, "ignore": [bay.patient]})
	life.ambulance = null
	ambulance.queue_free()
	# Wheelchair transports from each acute room to the service elevator and back.
	for bay in layout.bays:
		if bay.kind != "acute":
			continue
		life.transport_bay = bay
		var out: Array = life.transport_route()
		routes["Wheelchair transports"].append({"kind": "cart", "label": "to radiology from room %s" % bay.id, "start": bay.inside, "points": out, "length": 0.8, "width": 0.66, "side": 1.0, "partner": false, "back_out": 0, "ignore": [bay.patient]})
		var back := out.duplicate()
		back.reverse()
		routes["Wheelchair transports"].append({"kind": "cart", "label": "back to room %s" % bay.id, "start": back[0], "points": back.slice(1) + [bay.inside], "length": 0.8, "width": 0.66, "side": 1.0, "partner": false, "back_out": 0, "ignore": [bay.patient]})
	life.transport_bay = {}
	# The radiology stretcher to each holding bay and back to the elevator.
	for index in range(imaging.holding.size()):
		var bay: Dictionary = imaging.holding[index]
		routes["Radiology transports"].append({"kind": "cart", "label": "to holding %d" % index, "start": imaging.points.elevator_front, "points": [imaging.points.corridor_west, imaging.points.corridor_holding, bay.front], "length": 2.08, "width": 0.7, "side": 1.0, "partner": false, "back_out": 0})
		routes["Radiology transports"].append({"kind": "cart", "label": "from holding %d" % index, "start": bay.front, "points": [imaging.points.corridor_holding, imaging.points.corridor_west, imaging.points.elevator_front], "length": 2.08, "width": 0.7, "side": 1.0, "partner": false, "back_out": 0})
	# Staff on the department's path graph, and the lanes they step aside into
	# (which never enter their keep-clear zones).
	var staff: Node3D = life.staff[0]
	for edge in staff.edges:
		var a: Vector2 = staff.nodes[edge[0]]
		var b: Vector2 = staff.nodes[edge[1]]
		for lane in [0.0, -staff.ASIDE, staff.ASIDE, -staff.CART_ASIDE, staff.CART_ASIDE]:
			var shift: Vector2 = (b - a).normalized().orthogonal() * lane
			routes["Staff"].append({"kind": "walker", "label": "staff %d-%d" % [edge[0], edge[1]], "start": Vector3(a.x + shift.x, 0, a.y + shift.y), "points": [Vector3(b.x + shift.x, 0, b.y + shift.y)], "keep_clear": staff.obstacles if lane != 0.0 else []})
	return routes

## The walking points of a route (its "to" steps).
func _points(steps: Array) -> Array:
	var result: Array = []
	for step in steps:
		if step.has("to"):
			result.append(Vector3(step.to.x, 0, step.to.z))
	return result

# --- Geometry ----------------------------------------------------------------------------------

func _record_geometry() -> void:
	var saved_ed: Dictionary = hospital.ed_layout
	var saved_imaging: Dictionary = hospital.imaging_layout
	var scratch := Node3D.new()
	scratch.name = "ClearanceScratch"
	scratch.visible = false
	hospital.add_child(scratch)
	hospital.build_root = scratch
	var recorded: Array = []
	for entry in [[EDBuilder, EDBuilder.ORIGIN], [ImagingBuilder, hospital.IMAGING_OFFSET]]:
		var kit = Kit.new(entry[1])
		kit.layers = {"always": Recorder.new(recorded, "always"), "fp": Recorder.new(recorded, "fp"), "tp": Recorder.new(recorded, "tp")}
		entry[0].build(hospital, kit)
	hospital.ed_layout = saved_ed
	hospital.imaging_layout = saved_imaging
	# Only what a standing figure can touch: no floors, cutaway copies or ceilings.
	for box in recorded:
		if box.l == "tp":
			continue
		var half := _half_height(box)
		if box.c.y + half < 0.07 or box.c.y - half > 1.85:
			continue
		geometry.append(box)

## Standing figures placed by the builders (the ones with an NPC blocker).
func _static_figures() -> Array:
	var result: Array = []
	for zone in ["ed", "imaging"]:
		for blocker in hospital.zone_roots[zone].find_children("Blocker", "AnimatableBody3D", true, false):
			var moving := false
			var node: Node = blocker.get_parent()
			while node != null and node != hospital:
				var script: Script = node.get_script()
				if script != null and (script.resource_path.ends_with("route_walker.gd") or script.resource_path.ends_with("cart_crew.gd") or script.resource_path.ends_with("pedestrian.gd")):
					moving = true
					break
				node = node.get_parent()
			if moving or not blocker.is_visible_in_tree():
				continue
			var at: Vector3 = blocker.global_position
			result.append({"c": Vector3(at.x, 0.9, at.z), "s": Vector3(0.5, 1.8, 0.5), "b": Basis.IDENTITY, "l": "figure", "k": "standing figure", "node": blocker})
	return result

func _index() -> void:
	for index in range(geometry.size()):
		var box: Dictionary = geometry[index]
		var reach := _reach(box)
		for cx in range(floori(box.c.x - reach.x), floori(box.c.x + reach.x) + 1):
			for cz in range(floori(box.c.z - reach.y), floori(box.c.z + reach.y) + 1):
				var cell := Vector2i(cx, cz)
				if not grid.has(cell):
					grid[cell] = []
				grid[cell].append(index)

## Half extents of a box's footprint along world x and z.
func _reach(box: Dictionary) -> Vector2:
	var basis: Basis = box.b
	var size: Vector3 = box.s
	return Vector2(absf(basis.x.x) * size.x + absf(basis.y.x) * size.y + absf(basis.z.x) * size.z, absf(basis.x.z) * size.x + absf(basis.y.z) * size.y + absf(basis.z.z) * size.z) / 2.0

func _half_height(box: Dictionary) -> float:
	var basis: Basis = box.b
	var size: Vector3 = box.s
	return (absf(basis.x.y) * size.x + absf(basis.y.y) * size.y + absf(basis.z.y) * size.z) / 2.0

# --- Sweeps ------------------------------------------------------------------------------------

func _walk(label: String, start: Vector3, points: Array, keep_clear: Array) -> void:
	var here := start
	for point in points:
		_sweep(label, here, point, [[Vector3.ZERO, FIGURE]], false, [], keep_clear)
		here = point

## A cart and its crew: the lead behind the head end, the partner (if any)
## just off centre ahead of the foot end, as npc/cart_crew.gd places them.
func _cart(route: Dictionary) -> void:
	var length: float = route.length
	var parts := [[Vector3.ZERO, Vector2(route.width / 2.0, length / 2.0)], [Vector3(0, 0, -(length / 2.0 + 0.5)), FIGURE]]
	if route.partner:
		parts.append([Vector3(0.12 * route.side, 0, length / 2.0 + 0.42), FIGURE])
	var here: Vector3 = route.start
	var index := 0
	for point in route.points:
		_sweep(route.label, here, point, parts, index < int(route.back_out), route.get("ignore", []), [])
		here = point
		index += 1

func _sweep(label: String, from: Vector3, to: Vector3, parts: Array, backwards: bool, ignore: Array, keep_clear: Array) -> void:
	var leg := to - from
	leg.y = 0.0
	var length := leg.length()
	if length < 0.02:
		return
	var direction := leg / length
	var facing := -direction if backwards else direction
	var heading := atan2(facing.x, facing.z)
	var steps := int(ceil(length / 0.1))
	for step in range(steps + 1):
		var at := from + direction * (length * step / steps)
		if keep_clear.any(func(zone: Array) -> bool: return Vector2(at.x, at.z).distance_to(zone[0]) < zone[1]):
			continue
		for part in parts:
			var center: Vector3 = at + Basis(Vector3.UP, heading) * part[0]
			var radius: float = part[1].length()
			var candidates := {}
			for cx in range(floori(center.x - radius), floori(center.x + radius) + 1):
				for cz in range(floori(center.z - radius), floori(center.z + radius) + 1):
					for index in grid.get(Vector2i(cx, cz), []):
						candidates[index] = true
			for index in candidates:
				var box: Dictionary = geometry[index]
				if box.has("node") and ignore.has(box.node):
					continue
				if _overlap(center, heading, part[1], box) > TOLERANCE:
					var note := "%s: %s at (%.1f, %.1f)" % [label, box.k, box.c.x, box.c.z]
					if not found.has(note):
						found.append(note)

## Penetration of a y-rotated rectangle (half extents `half`, facing
## `heading`) into a box, in plan; <= 0 when clear.
func _overlap(center: Vector3, heading: float, half: Vector2, box: Dictionary) -> float:
	var basis: Basis = box.b
	var size: Vector3 = box.s
	var b_axes: Array
	var b_half: Vector2
	if absf(basis.y.y - 1.0) < 0.001:
		b_axes = [Vector2(basis.x.x, basis.x.z).normalized(), Vector2(basis.z.x, basis.z.z).normalized()]
		b_half = Vector2(size.x, size.z) / 2.0
	else:
		b_axes = [Vector2(1, 0), Vector2(0, 1)]
		b_half = _reach(box)
	var a_axes := [Vector2(cos(heading), -sin(heading)), Vector2(sin(heading), cos(heading))]
	var offset := Vector2(box.c.x, box.c.z) - Vector2(center.x, center.z)
	var least := INF
	for axis in a_axes + b_axes:
		var ra: float = half.x * absf(a_axes[0].dot(axis)) + half.y * absf(a_axes[1].dot(axis))
		var rb: float = b_half.x * absf(b_axes[0].dot(axis)) + b_half.y * absf(b_axes[1].dot(axis))
		var gap: float = absf(offset.dot(axis)) - (ra + rb)
		if gap >= 0.0:
			return -gap
		least = minf(least, -gap)
	return least
