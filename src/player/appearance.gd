extends Node3D
## Shared procedural rig: distance-driven gait plus a continuous sit blend.
## Only visuals move here, never collision. Local forward is -Z.
const Geometry = preload("res://world/geometry.gd")
const Presets = preload("res://data/character_presets.gd")
const HIP_HEIGHT := 0.64
const THIGH := 0.3
## Hip-joint height when fully seated; chairs are built so the seat top meets the thighs.
const SEATED_HIP_HEIGHT := 0.37
var preset_id: String
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var shoulders: Array[Node3D] = []
var body: Node3D
var pelvis: Node3D
var spine: Node3D
var gait_phase := 0.0
var gait_weight := 0.0
## 0 = walking gait, 1 = full sprint; blended from actual ground speed.
var run_weight := 0.0
const RUN_START_SPEED := 3.6
const RUN_FULL_SPEED := 5.4
var seated_pose := false
var sit_blend := 0.0

func apply_preset(id: String) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	hips.clear()
	knees.clear()
	shoulders.clear()
	gait_weight = 0.0
	gait_phase = 0.0
	run_weight = 0.0
	seated_pose = false
	sit_blend = 0.0
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	pelvis = Node3D.new()
	pelvis.name = "Pelvis"
	pelvis.position.y = HIP_HEIGHT
	body.add_child(pelvis)
	spine = Node3D.new()
	spine.name = "Spine"
	pelvis.add_child(spine)
	var data := Presets.get_preset(id)
	preset_id = data.id
	var skin := Color(data.skin)
	var hair := Color(data.hair)
	var shirt := Color(data.shirt)
	var pants := Color(data.pants)
	var up := Vector3(0, -HIP_HEIGHT, 0) # Spine children keep their original standing heights.
	Geometry.box(spine, "Torso", Vector3(0.51, 0.57, 0.3), up + Vector3(0, 0.94, 0), shirt)
	for side in [-1, 1]:
		var hip := Node3D.new()
		hip.position = Vector3(side * 0.14, 0, 0)
		pelvis.add_child(hip)
		hips.append(hip)
		Geometry.box(hip, "Leg", Vector3(0.19, THIGH + 0.02, 0.23), Vector3(0, -THIGH / 2, 0), pants)
		var knee := Node3D.new()
		knee.name = "Knee"
		knee.position.y = -THIGH
		hip.add_child(knee)
		knees.append(knee)
		Geometry.box(knee, "Shin", Vector3(0.18, 0.3, 0.21), Vector3(0, -0.15, 0), pants)
		Geometry.box(knee, "Shoe", Vector3(0.22, 0.12, 0.33), Vector3(0, -0.28, -0.045), Color("efe7d5"))
		var shoulder := Node3D.new()
		shoulder.position = up + Vector3(side * 0.34, 1.17, 0)
		spine.add_child(shoulder)
		shoulders.append(shoulder)
		Geometry.box(shoulder, "Sleeve", Vector3(0.17, 0.37, 0.25), Vector3(0, -0.19, 0), shirt)
		Geometry.sphere(shoulder, Vector3(0.16, 0.24, 0.17), Vector3(0, -0.44, 0), skin)
	Geometry.sphere(spine, Vector3(0.43, 0.48, 0.4), up + Vector3(0, 1.46, 0), skin)
	Geometry.sphere(spine, Vector3(0.46, 0.25, 0.43), up + Vector3(0, 1.65, 0.035), hair)
	if data.hair_style == 0:
		for side in [-1, 1]:
			Geometry.sphere(spine, Vector3(0.22, 0.24, 0.3), up + Vector3(side * 0.18, 1.6, 0.07), hair)
	elif data.hair_style == 2:
		Geometry.box(spine, "Bob", Vector3(0.46, 0.38, 0.19), up + Vector3(0, 1.44, 0.17), hair)
	elif data.hair_style == 3:
		Geometry.sphere(spine, Vector3(0.25, 0.25, 0.25), up + Vector3(0, 1.76, 0.15), hair)
	Geometry.box(spine, "Backpack", Vector3(0.35, 0.42, 0.17), up + Vector3(0, 0.99, 0.23), Color("384f59"))
	Geometry.box(spine, "StudentBadge", Vector3(0.1, 0.15, 0.025), up + Vector3(-0.12, 1.07, -0.17), Color("eee9d9"))

## Instant pose change, used when a scene loads with someone already seated.
func set_seated(seated: bool) -> void:
	set_sit_blend(1.0 if seated else 0.0)

## t = 0 standing, t = 1 seated. Intermediate values give the lowering motion:
## hips hinge and drop, knees bend, and the torso leans forward to balance
## over the feet before settling upright against the backrest.
func set_sit_blend(t: float) -> void:
	if not is_instance_valid(body):
		return
	sit_blend = clampf(t, 0.0, 1.0)
	seated_pose = sit_blend > 0.0
	var eased := sit_blend * sit_blend * (3.0 - 2.0 * sit_blend)
	pelvis.position.y = lerpf(HIP_HEIGHT, SEATED_HIP_HEIGHT, eased)
	for index in range(2):
		hips[index].rotation = Vector3(PI / 2 * eased, 0, 0)
		knees[index].rotation = Vector3(-PI / 2 * eased, 0, 0)
		shoulders[index].rotation = Vector3(0.55 * eased, 0, 0)
	spine.rotation.x = -0.42 * sin(PI * sit_blend) - 0.04 * eased
	body.position.y = 0.0
	body.rotation = Vector3.ZERO

func animate_motion(distance: float, delta: float, lateral := false) -> void:
	if seated_pose or not is_instance_valid(body) or delta <= 0:
		return
	var speed := distance / delta
	var target := clampf(speed / 1.8, 0.0, 1.0)
	gait_weight = move_toward(gait_weight, target, delta * 8.0)
	var run_target := 0.0 if lateral else clampf((speed - RUN_START_SPEED) / (RUN_FULL_SPEED - RUN_START_SPEED), 0.0, 1.0)
	run_weight = move_toward(run_weight, run_target, delta * 5.0)
	var run := run_weight * run_weight * (3.0 - 2.0 * run_weight)
	# A run takes longer strides per cycle than a walk.
	var cycle := 1.0 if lateral else lerpf(1.65, 2.6, run)
	gait_phase = fmod(gait_phase + distance * TAU / cycle, TAU)
	for index in range(2):
		var swing := sin(gait_phase + index * PI)
		var stride := swing * gait_weight
		if lateral:
			# Side-steps swing the legs outward rather than forward.
			hips[index].rotation = Vector3(0, 0, absf(stride) * 0.3 * (1 if index else -1))
			knees[index].rotation.x = 0.0
			shoulders[index].rotation = Vector3.ZERO
		else:
			hips[index].rotation = Vector3(stride * lerpf(0.58, 0.95, run), 0, 0)
			# Walking flexes the trailing knee a little; sprinting folds the
			# recovering leg high behind and lifts the knee through the swing.
			var trailing := maxf(0.0, -swing)
			var recovering := maxf(0.0, cos(gait_phase + index * PI))
			knees[index].rotation.x = -gait_weight * (trailing * lerpf(0.5, 1.35, run) + recovering * 0.55 * run)
			# Arms pump harder and stay slightly bent forward and tucked in while running.
			shoulders[index].rotation = Vector3(-stride * lerpf(0.42, 0.95, run) + 0.25 * run, 0, (0.12 if index else -0.12) * run)
	var bounce := lerpf(0.035, 0.085, run)
	body.position.y = absf(cos(gait_phase)) * bounce * gait_weight
	body.rotation.z = sin(gait_phase) * lerpf(0.025, 0.04, run) * gait_weight
	body.rotation.x = -0.035 * gait_weight
	spine.rotation.x = -0.24 * run * gait_weight
