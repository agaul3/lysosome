extends Node3D
## Minecraft-style character rig shared by the player and every NPC.
##
## Six textured boxes — head, torso, two arms, and two legs split at the knee —
## wear one painted 64×64 pixel skin (see character/): the base layer shows
## skin, face, top, bottoms and shoes; a slightly larger overlay shell holds
## hair volume, outerwear, hats and glasses. Hair buns, ponytails, cap brims
## and backpacks are small extra boxes. The look (data/looks.gd) chooses
## everything, including build (arm width) and a slight height scale.
##
## Only visuals move here, never collision. Local forward is −Z; the rig's
## joints keep the proportions seating and routes were built for: hips at
## 0.64 m, knees halfway down the leg, a 0.37 m seated hip height.
const Presets = preload("res://data/character_presets.gd")
const Looks = preload("res://data/looks.gd")
const Clothing = preload("res://data/clothing.gd")
const Layout = preload("res://character/skin_layout.gd")
const Painter = preload("res://character/skin_painter.gd")
const RigMesh = preload("res://character/rig_mesh.gd")
const P := Layout.PIXEL
const HIP_HEIGHT := 0.64
const THIGH := 6.0 * P
## Hip-joint height when fully seated; chairs are built so the seat top meets the thighs.
const SEATED_HIP_HEIGHT := 0.37
## Eye point in spine space: the painted eyes (about 1.47 m standing), at the
## front of the head so the first-person view looks out past the face.
const EYE := Vector3(0, 1.467 - HIP_HEIGHT, -4.0 * P - 0.01)
## Painted skins are shared between characters with identical looks.
static var _skins := {}
var preset_id: String
var look: Dictionary = {}
var height_scale := 1.0
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var shoulders: Array[Node3D] = []
var body: Node3D
var pelvis: Node3D
var spine: Node3D
var head: Node3D
## The head and anything on it (the first-person view draws the player's own as shadow only).
var head_parts: Array[MeshInstance3D] = []
var skin_image: Image
var material: StandardMaterial3D
var backpack: MeshInstance3D
var gait_phase := 0.0
var gait_weight := 0.0
## 0 = walking gait, 1 = full sprint; blended from actual ground speed.
var run_weight := 0.0
const RUN_START_SPEED := 3.6
const RUN_FULL_SPEED := 5.4
var seated_pose := false
var sit_blend := 0.0

## Builds the character from a preset (or faculty/crowd extra) id.
func apply_preset(id: String) -> void:
	apply_look(Presets.look_of(id))

## Builds the character from a full look.
func apply_look(target: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	look = Looks.sanitize(target)
	preset_id = String(look.preset)
	hips.clear()
	knees.clear()
	shoulders.clear()
	head_parts.clear()
	gait_weight = 0.0
	gait_phase = 0.0
	run_weight = 0.0
	seated_pose = false
	sit_blend = 0.0
	var slim: bool = look.build == "slim"
	skin_image = _skin(look)
	material = StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(skin_image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	material.roughness = 0.92
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
	var torso := Node3D.new()
	torso.name = "Torso"
	spine.add_child(torso)
	_mesh(torso, "torso", slim)
	head = Node3D.new()
	head.name = "Head"
	head.position.y = 12.0 * P
	spine.add_child(head)
	head_parts.append(_mesh(head, "head", slim))
	if look.hair_style in ["bun", "ponytail"]:
		head_parts.append(_mesh(head, String(look.hair_style), slim))
	var hat := Clothing.item(String(look.outfit.head))
	if not hat.is_empty() and hat.kind == "cap":
		head_parts.append(_mesh(head, "brim", slim))
	var arm_width := 3.0 if slim else 4.0
	for side in [-1, 1]:
		var shoulder := Node3D.new()
		shoulder.name = "RightShoulder" if side > 0 else "LeftShoulder"
		shoulder.position = Vector3(side * (4.0 + arm_width / 2.0) * P, 10.0 * P, 0)
		spine.add_child(shoulder)
		shoulders.append(shoulder)
		_mesh(shoulder, "right_arm" if side > 0 else "left_arm", slim)
		var hip := Node3D.new()
		hip.name = "RightHip" if side > 0 else "LeftHip"
		hip.position = Vector3(side * 2.0 * P, 0, 0)
		pelvis.add_child(hip)
		hips.append(hip)
		_mesh(hip, "right_thigh" if side > 0 else "left_thigh", slim)
		var knee := Node3D.new()
		knee.name = "Knee"
		knee.position.y = -THIGH
		hip.add_child(knee)
		knees.append(knee)
		_mesh(knee, "right_shin" if side > 0 else "left_shin", slim)
	var bag := Clothing.item(String(look.outfit.back))
	backpack = null
	if not bag.is_empty():
		backpack = MeshInstance3D.new()
		backpack.name = "Backpack"
		backpack.mesh = RigMesh.backpack()
		backpack.position = Vector3(0, 6.0 * P, 4.3 * P)
		var bag_material := StandardMaterial3D.new()
		bag_material.albedo_texture = ImageTexture.create_from_image(Painter.paint_backpack(bag.colors))
		bag_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		bag_material.roughness = 0.9
		backpack.material_override = bag_material
		spine.add_child(backpack)
	height_scale = float(look.height)
	scale = Vector3.ONE * height_scale
	set_sit_blend(0.0)

func _mesh(parent: Node3D, key: String, slim: bool) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = key.capitalize().replace(" ", "") + "Mesh"
	instance.mesh = RigMesh.part(key, slim)
	instance.material_override = material
	parent.add_child(instance)
	return instance

## The painted skin for a look, shared across identical looks.
static func _skin(target: Dictionary) -> Image:
	var key_look := target.duplicate(true)
	key_look.erase("height")
	key_look.erase("preset")
	var key := JSON.stringify(key_look)
	if not _skins.has(key):
		if _skins.size() > 96:
			_skins.clear()
		_skins[key] = Painter.new().paint(key_look)
	return _skins[key]

## Instant pose change, used when a scene loads with someone already seated.
func set_seated(seated: bool) -> void:
	set_sit_blend(1.0 if seated else 0.0)

## t = 0 standing, t = 1 seated. Intermediate values give the lowering motion:
## hips hinge and drop, knees bend, and the torso leans forward to balance
## over the feet before settling upright against the backrest. The seated
## hip height is fixed by the chair, whatever the character's height.
func set_sit_blend(t: float) -> void:
	if not is_instance_valid(body):
		return
	sit_blend = clampf(t, 0.0, 1.0)
	seated_pose = sit_blend > 0.0
	var eased := sit_blend * sit_blend * (3.0 - 2.0 * sit_blend)
	pelvis.position.y = lerpf(HIP_HEIGHT, SEATED_HIP_HEIGHT / height_scale, eased)
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
			# Arms swing opposite the legs, pumping harder and tucking in while running.
			shoulders[index].rotation = Vector3(-stride * lerpf(0.42, 0.95, run) + 0.25 * run, 0, (0.12 if index else -0.12) * run)
	var bounce := lerpf(0.035, 0.085, run)
	body.position.y = absf(cos(gait_phase)) * bounce * gait_weight
	body.rotation.z = sin(gait_phase) * lerpf(0.025, 0.04, run) * gait_weight
	body.rotation.x = -0.035 * gait_weight
	spine.rotation.x = -0.24 * run * gait_weight
