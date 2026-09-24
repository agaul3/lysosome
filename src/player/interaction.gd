extends Node3D
## Chooses one nearest visible endpoint. Player collision is layer 2.
signal target_changed(target: Node3D)
signal interacted(target: Node3D)
signal device_changed(controller: bool)
var target: Node3D
var enabled := true
## Set by the first-person view: prefer what you are looking at, ignore what is behind you.
var view_forward := Vector3.ZERO
var using_controller := false

func _physics_process(_delta: float) -> void:
	# A freed Object can compare equal to null; explicitly notify the UI on removal.
	if typeof(target) == TYPE_OBJECT and not is_instance_valid(target):
		target = null
		target_changed.emit(null)
	var nearest: Node3D
	var nearest_distance := INF
	if enabled:
		for candidate in get_tree().get_nodes_in_group("interactables"):
			var distance := global_position.distance_to(candidate.global_position)
			if distance > candidate.reach:
				continue
			var score := distance
			if view_forward != Vector3.ZERO:
				var flat := Vector3(candidate.global_position.x - global_position.x, 0, candidate.global_position.z - global_position.z)
				var facing := view_forward.dot(flat.normalized()) if flat.length() > 0.3 else 1.0
				if facing < -0.1:
					continue
				score = distance * (2.0 - facing)
			if score >= nearest_distance:
				continue
			var query := PhysicsRayQueryParameters3D.create(global_position, candidate.global_position, 1)
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				continue
			nearest = candidate
			nearest_distance = score
	if nearest != target:
		if is_instance_valid(target):
			target.set_highlighted(false)
		target = nearest
		if is_instance_valid(target):
			target.set_highlighted(true)
		target_changed.emit(target)

func _input(event: InputEvent) -> void:
	var controller := using_controller
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.25):
		controller = true
	elif event is InputEventKey or event is InputEventMouseButton:
		controller = false
	if controller != using_controller:
		using_controller = controller
		device_changed.emit(controller)

func _unhandled_input(event: InputEvent) -> void:
	if enabled and event.is_action_pressed("interact") and not event.is_echo() and is_instance_valid(target):
		target.interact()
		interacted.emit(target)
		get_viewport().set_input_as_handled()
