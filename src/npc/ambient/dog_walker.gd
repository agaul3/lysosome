extends Node3D
## A student walking a dog on a leash, wandering at random inside a lawn.
##
## The walker strolls between random points in `region`, pausing now and then
## (and waiting when the dog is busy sniffing). The dog has its own moods —
## trotting to a new spot, sniffing, zooming round the walker, play-bowing,
## sitting — but can never go further than the leash allows, and both stay in
## the region and out of `avoid` circles (benches). A sagging leash is drawn
## from the walker's hand to the dog's collar. Both are solid to the player.
const Appearance = preload("res://player/appearance.gd")
const Dog = preload("res://npc/ambient/dog.gd")
const Student = preload("res://npc/student.gd")
const LEASH := 2.6
const WALK_SPEED := 0.95
enum Mood { TROT, SNIFF, ZOOM, BOW, SIT }
## Lawn the pair keeps to (x, z, width, depth in world metres).
var region := Rect2(2.2, 0.2, 9.1, 7.1)
## [centre (Vector2), radius] areas to stay out of.
var avoid: Array = []
var rng := RandomNumberGenerator.new()
var walker: Node3D
var dog: Node3D
var leash_segments: Array[MeshInstance3D] = []
var walker_target := Vector2.ZERO
var walker_wait := 0.0
var dog_target := Vector2.ZERO
var mood := Mood.TROT
var mood_time := 0.0
var zoom_angle := 0.0
var zoom_direction := 1.0
## History of moods entered (tests read it to confirm variety).
var moods_seen := {}

func _ready() -> void:
	rng.randomize()
	walker = Appearance.new()
	walker.name = "Walker"
	add_child(walker)
	walker.apply_look(preload("res://data/looks.gd").random(rng))
	Student.make_blocker(walker)
	dog = Dog.new()
	dog.name = "Dog"
	add_child(dog)
	dog.build(rng.randi())
	var dog_blocker := Student.make_blocker(dog)
	(dog_blocker.get_child(0).shape as CapsuleShape3D).radius = 0.28
	(dog_blocker.get_child(0).shape as CapsuleShape3D).height = 0.8
	dog_blocker.get_child(0).position.y = 0.4
	var start := _random_point()
	walker.position = Vector3(start.x, 0, start.y)
	var near := _constrain_dog(start + Vector2(1.0, 0.4))
	dog.position = Vector3(near.x, 0, near.y)
	walker_target = _random_point()
	dog_target = near
	var leash_material := StandardMaterial3D.new()
	leash_material.albedo_color = Color("b0392b")
	leash_material.roughness = 0.6
	for index in range(7):
		var segment := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.018, 0.018, 1.0)
		segment.mesh = mesh
		segment.material_override = leash_material
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(segment)
		leash_segments.append(segment)
	_set_mood(Mood.TROT)
	# The leash hand reaches forward a little.
	walker.shoulders[1].rotation.x = 0.45

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	_update_walker(delta)
	_update_dog(delta)
	_update_leash()

# --- Walker ---------------------------------------------------------------------------

func _update_walker(delta: float) -> void:
	var here := Vector2(walker.position.x, walker.position.z)
	var moved := 0.0
	if walker_wait > 0.0 or mood == Mood.SNIFF and _dog_distance() > LEASH * 0.8:
		walker_wait = maxf(walker_wait - delta, 0.0)
		# Face the dog while waiting.
		var to_dog := Vector2(dog.position.x, dog.position.z) - here
		if to_dog.length() > 0.1:
			walker.rotation.y = lerp_angle(walker.rotation.y, atan2(-to_dog.x, -to_dog.y), 1.0 - exp(-3.0 * delta))
	else:
		var offset := walker_target - here
		if offset.length() < 0.15:
			walker_wait = rng.randf_range(1.5, 5.0)
			walker_target = _random_point()
		else:
			var step := minf(offset.length(), WALK_SPEED * delta)
			var next := _keep_out(here + offset.normalized() * step)
			moved = next.distance_to(here)
			walker.position = Vector3(next.x, 0, next.y)
			walker.rotation.y = lerp_angle(walker.rotation.y, atan2(-offset.x, -offset.y), 1.0 - exp(-6.0 * delta))
	walker.animate_motion(moved, delta)
	walker.shoulders[1].rotation.x = 0.45

# --- Dog ------------------------------------------------------------------------------

func _set_mood(next: Mood) -> void:
	mood = next
	moods_seen[next] = true
	match next:
		Mood.TROT:
			mood_time = rng.randf_range(1.5, 4.0)
			dog_target = _dog_spot()
		Mood.SNIFF:
			mood_time = rng.randf_range(1.5, 4.0)
		Mood.ZOOM:
			mood_time = rng.randf_range(2.0, 3.5)
			zoom_direction = 1.0 if rng.randf() < 0.5 else -1.0
			var from_walker := Vector2(dog.position.x - walker.position.x, dog.position.z - walker.position.z)
			zoom_angle = atan2(from_walker.y, from_walker.x)
		Mood.BOW:
			mood_time = rng.randf_range(0.8, 1.4)
		Mood.SIT:
			mood_time = rng.randf_range(1.8, 3.5)

func _next_mood() -> void:
	var roll := rng.randf()
	match mood:
		Mood.BOW:
			_set_mood(Mood.ZOOM)
		_:
			if roll < 0.42:
				_set_mood(Mood.TROT)
			elif roll < 0.7:
				_set_mood(Mood.SNIFF)
			elif roll < 0.82:
				_set_mood(Mood.BOW)
			elif roll < 0.9:
				_set_mood(Mood.ZOOM)
			else:
				_set_mood(Mood.SIT)

func _update_dog(delta: float) -> void:
	mood_time -= delta
	if mood_time <= 0.0:
		_next_mood()
	var here := Vector2(dog.position.x, dog.position.z)
	var goal := here
	var speed := 0.0
	dog.sniffing = move_toward(dog.sniffing, 1.0 if mood == Mood.SNIFF else 0.0, delta * 3.0)
	dog.sitting = move_toward(dog.sitting, 1.0 if mood == Mood.SIT else 0.0, delta * 3.0)
	dog.bowing = move_toward(dog.bowing, 1.0 if mood == Mood.BOW else 0.0, delta * 4.0)
	match mood:
		Mood.TROT:
			goal = dog_target
			speed = 1.5
			if here.distance_to(dog_target) < 0.2:
				_set_mood(Mood.SNIFF)
		Mood.SNIFF:
			# Small snuffling steps.
			goal = here + Vector2(sin(dog.time * 1.7), cos(dog.time * 1.3)) * 0.2
			speed = 0.25
		Mood.ZOOM:
			zoom_angle += zoom_direction * delta * 2.2
			var centre := Vector2(walker.position.x, walker.position.z)
			goal = centre + Vector2(cos(zoom_angle), sin(zoom_angle)) * (LEASH * 0.85)
			speed = 3.4
		Mood.BOW, Mood.SIT:
			goal = here
			var to_walker := Vector2(walker.position.x, walker.position.z) - here
			dog.rotation.y = lerp_angle(dog.rotation.y, atan2(-to_walker.x, -to_walker.y), 1.0 - exp(-5.0 * delta))
	var offset := goal - here
	var travel := minf(offset.length(), speed * delta)
	var next := here + (offset.normalized() * travel if offset.length() > 0.0001 else Vector2.ZERO)
	next = _constrain_dog(next)
	var moved := next.distance_to(here)
	dog.position = Vector3(next.x, 0, next.y)
	if moved > 0.001 and mood in [Mood.TROT, Mood.ZOOM, Mood.SNIFF]:
		var heading := next - here
		dog.rotation.y = lerp_angle(dog.rotation.y, atan2(-heading.x, -heading.y), 1.0 - exp(-10.0 * delta))
	dog.speed = moved / delta
	dog.wag_rate = {Mood.ZOOM: 14.0, Mood.BOW: 16.0, Mood.TROT: 8.0, Mood.SNIFF: 4.0, Mood.SIT: 6.0}[mood]
	dog.animate(moved, delta)

func _dog_distance() -> float:
	return Vector2(dog.position.x - walker.position.x, dog.position.z - walker.position.z).length()

## A random spot for the dog within leash reach of the walker.
func _dog_spot() -> Vector2:
	var centre := Vector2(walker.position.x, walker.position.z)
	for attempt in range(12):
		var angle := rng.randf() * TAU
		var point := centre + Vector2(cos(angle), sin(angle)) * rng.randf_range(0.8, LEASH * 0.9)
		if _allowed(point):
			return point
	return centre + Vector2(0.8, 0)

## Within the leash, in the region and out of avoided circles. Pushing out of a
## circle can stretch the leash, so alternate until both hold; the leash wins.
func _constrain_dog(point: Vector2) -> Vector2:
	for attempt in range(6):
		point = _keep_out(_clamp_to_leash(point))
		if _dog_distance_from(point) <= LEASH + 0.001:
			return point
	return _clamp_to_leash(point)

func _dog_distance_from(point: Vector2) -> float:
	return point.distance_to(Vector2(walker.position.x, walker.position.z))

func _clamp_to_leash(point: Vector2) -> Vector2:
	var centre := Vector2(walker.position.x, walker.position.z)
	var offset := point - centre
	return centre + offset.limit_length(LEASH)

# --- Region -----------------------------------------------------------------------------

func _random_point() -> Vector2:
	var inner := region.grow(-0.6)
	for attempt in range(30):
		var point := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		if _allowed(point):
			return point
	return inner.get_center()

func _allowed(point: Vector2) -> bool:
	if not region.grow(-0.3).has_point(point):
		return false
	for entry in avoid:
		if point.distance_to(entry[0]) < entry[1]:
			return false
	return true

## Keeps a point inside the region and outside every avoided circle.
func _keep_out(point: Vector2) -> Vector2:
	var inner := region.grow(-0.3)
	point = Vector2(clampf(point.x, inner.position.x, inner.end.x), clampf(point.y, inner.position.y, inner.end.y))
	for entry in avoid:
		var centre: Vector2 = entry[0]
		var radius: float = entry[1]
		var offset := point - centre
		if offset.length() < radius:
			point = centre + (offset.normalized() if offset.length() > 0.001 else Vector2.RIGHT) * radius
	return point

# --- Leash -------------------------------------------------------------------------------

func hand_position() -> Vector3:
	var shoulder: Node3D = walker.shoulders[1]
	return shoulder.to_global(Vector3(0, -0.5, 0))

## Straight between hand and collar, sagging more the slacker it is.
func _update_leash() -> void:
	var a := hand_position()
	var b: Vector3 = dog.collar.global_position
	var slack := clampf(1.0 - a.distance_to(b) / (LEASH + 0.8), 0.0, 1.0)
	var sag := 0.15 + slack * 0.45
	var count := leash_segments.size()
	var previous := a
	for index in range(count):
		var t := float(index + 1) / count
		var point := a.lerp(b, t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t)
		var segment := leash_segments[index]
		var length := previous.distance_to(point)
		segment.global_position = (previous + point) / 2.0
		if length > 0.001:
			segment.global_basis = Basis.looking_at(point - previous, Vector3.UP if absf((point - previous).normalized().y) < 0.98 else Vector3.RIGHT).scaled_local(Vector3(1, 1, length))
		previous = point
