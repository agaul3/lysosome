extends Node3D
## Compact silver clamshell. Origin is the desk surface; screen faces local +Z.
const Geometry = preload("res://world/geometry.gd")
var with_tray := false
## The display surface (a quad facing local +Z).
var screen: MeshInstance3D

func _ready() -> void:
	if with_tray:
		Geometry.box(self, "WritingTray", Vector3(0.66, 0.025, 0.43), Vector3(0, -0.014, 0), Color("61544b"))
		Geometry.box(self, "TrayArm", Vector3(0.025, 0.035, 0.55), Vector3(-0.31, -0.045, 0.21), Color("484a50"))
	Geometry.box(self, "AluminiumBase", Vector3(0.56, 0.022, 0.36), Vector3(0, 0.012, 0), Color("bcc4cd"))
	Geometry.box(self, "Keyboard", Vector3(0.49, 0.003, 0.15), Vector3(0, 0.025, -0.052), Color("30343b"))
	for row in range(4):
		for key in range(11):
			Geometry.box(self, "Key", Vector3(0.033, 0.003, 0.022), Vector3(-0.218 + key * 0.0435, 0.028, -0.106 + row * 0.033), Color("69727b"))
	Geometry.box(self, "Trackpad", Vector3(0.2, 0.003, 0.085), Vector3(0, 0.026, 0.099), Color("929da8"))
	var lid := Node3D.new()
	lid.position = Vector3(0, 0.022, -0.17)
	lid.rotation.x = -0.13
	add_child(lid)
	Geometry.box(lid, "DisplayLid", Vector3(0.56, 0.35, 0.015), Vector3(0, 0.175, 0), Color("acb5bf"))
	Geometry.box(lid, "DisplayBezel", Vector3(0.53, 0.32, 0.004), Vector3(0, 0.176, 0.009), Color("252830"))
	# 16:10 display the computer draws into; the camera frames it from the seat.
	screen = MeshInstance3D.new()
	screen.name = "Screen"
	screen.mesh = QuadMesh.new()
	screen.mesh.size = Vector2(0.5, 0.3125)
	screen.position = Vector3(0, 0.178, 0.0125)
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color("0b0d12")
	screen.material_override = black
	lid.add_child(screen)
	Geometry.box(lid, "Camera", Vector3(0.008, 0.008, 0.002), Vector3(0, 0.34, 0.012), Color("0f1114"))
