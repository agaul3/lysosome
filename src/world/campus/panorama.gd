extends "res://world/campus/campus.gd"
## The campus as scenery for the title screen: the same buildings, paving,
## planting and lighting as the playable commons, without the player, HUD,
## NPCs or interactions, seen from a camera drifting slowly over the quad.
var drift_camera: Camera3D
var angle := 0.0

func _ready() -> void:
	_build_ground()
	_build_paving()
	Buildings.learning_center(self)
	Buildings.residence(self)
	Buildings.medical_center(self)
	Buildings.anatomy_hall(self)
	Buildings.pavilion(self)
	Buildings.hospital(self)
	_build_signs()
	_build_props()
	_build_parking()
	_build_planting()
	_build_grass()
	_build_context()
	_build_lighting()
	# A fixed, flattering morning light rather than the live clock.
	GameClock.minute_changed.disconnect(_update_daylight)
	sun.rotation_degrees = Vector3(-38, -35, 0)
	sun.light_energy = Config.MORNING.sun_energy
	campus_environment.background_color = Color("8cc4dc")
	campus_environment.ambient_light_energy = 0.55
	drift_camera = Camera3D.new()
	drift_camera.fov = 38
	drift_camera.far = 300
	add_child(drift_camera)
	drift_camera.current = true
	_place_camera()

func _process(delta: float) -> void:
	angle += delta * 0.018
	_place_camera()

## A gentle back-and-forth arc over the south-east of the quad, always
## framing the Learning Center across the plaza.
func _place_camera() -> void:
	var sweep := sin(angle) * 0.35
	var focus := Vector3(-2, 5, -18)
	var eye := focus + Vector3(sin(0.55 + sweep) * 44.0, 17.0, cos(0.55 + sweep) * 44.0)
	drift_camera.global_position = eye
	drift_camera.look_at(focus)
