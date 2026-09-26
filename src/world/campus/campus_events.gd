extends Node3D
## Things that happen on the quad on their days, set up and taken down as the
## clock passes (it checks every game minute):
##   The Club Fair     a table for each student organization along the walk
##                     north of the plaza, with a banner and a student at
##                     each; talk to one to hear its pitch and join
##                     (ui/club_panel.gd). The first visit marks the event.
##   Intramurals       while Intramural Sports meets, a pick-up game on the
##                     south-west lawn: portable goals, players, a ball; members
##                     join in (ui/clubs/intramurals_panel.gd).
const ClubData = preload("res://data/clubs.gd")
const ClubPanel = preload("res://ui/club_panel.gd")
const ClubEvents = preload("res://ui/clubs/club_events.gd")
const MeshKit = preload("res://world/campus/mesh_kit.gd")
const Geometry = preload("res://world/geometry.gd")
const Appearance = preload("res://player/appearance.gd")
const Student = preload("res://npc/student.gd")
const Endpoint = preload("res://world/interactable.gd")
const Looks = preload("res://data/looks.gd")
const FAIR := "club_fair"
## The fair's tables along the walk from the plaza to the Learning Center:
## [position, yaw the table's front faces]; west of the walk facing east,
## east of it facing west, staggered.
const FAIR_TABLES := [
	[Vector3(-2.7, 0, -13.6), PI / 2], [Vector3(2.7, 0, -12.3), -PI / 2],
	[Vector3(-2.7, 0, -11.0), PI / 2], [Vector3(2.7, 0, -9.7), -PI / 2],
	[Vector3(-2.7, 0, -8.4), PI / 2], [Vector3(2.7, 0, -7.1), -PI / 2],
	[Vector3(-2.7, 0, -5.8), PI / 2],
]
## Classmates browsing between the tables, off the walk: [position, yaw].
const BROWSERS := [[Vector3(-1.9, 0, -12.3), PI / 2], [Vector3(1.9, 0, -11.0), -PI / 2], [Vector3(-1.9, 0, -9.7), PI / 2], [Vector3(1.9, 0, -8.4), -PI / 2]]
## What each club's student says at the fair.
const PITCHES := {
	"community_kitchen": "\"We cook and serve supper on Harbor Street twice a week. Come once and you'll come every week. The shuttle drops you at the door.\"",
	"free_clinic": "\"First-years take vitals at the free clinic from October. Real patients, supervised, and they're so grateful you're there.\"",
	"surgery": "\"Monday nights: suturing with the surgery residents. By December you'll tie faster than the M2s.\"",
	"emig": "\"CPR skills night in the Sim Suite, with the feedback manikin. And Stop the Bleed. Useful whatever you end up doing.\"",
	"spanish": "\"Half the clinic's patients speak Spanish. We practice the history together, twice a week, with snacks.\"",
	"journal": "\"One paper, Friday lunch, free pizza. You'll learn to read a study like a skeptic.\"",
	"intramurals": "\"Soccer on the quad, Wednesdays and Saturdays. Nobody's good. Everybody comes back.\"",
}
var campus: Node3D
var fair_root: Node3D
var pitch_root: Node3D
var fair_tables := {}
var pitch_endpoint: Node3D

func setup(owner_campus: Node3D) -> void:
	campus = owner_campus
	name = "CampusEvents"
	refresh()
	GameClock.minute_changed.connect(refresh)

## Sets up or takes down each event for the current time.
func refresh() -> void:
	var fair_on := fair_open()
	if fair_on and not is_instance_valid(fair_root):
		_build_fair()
	elif not fair_on and is_instance_valid(fair_root):
		fair_root.queue_free()
		fair_root = null
		fair_tables.clear()
	var game_on := not Clubs.meeting_today("intramurals").is_empty() and _within(Clubs.meeting_today("intramurals"), 20.0)
	if game_on and not is_instance_valid(pitch_root):
		_build_pitch()
	elif not game_on and is_instance_valid(pitch_root):
		pitch_root.queue_free()
		pitch_root = null
	if is_instance_valid(pitch_endpoint):
		pitch_endpoint.display_name = "Join the pick-up game" if Clubs.is_member("intramurals") and Clubs.meeting_on("intramurals") else "Intramural soccer"

func _within(meeting: Dictionary, early_minutes: float) -> bool:
	var now := GameClock.now_seconds()
	return now >= float(meeting.start) - early_minutes * 60.0 and now < float(meeting.end)

## The fair is on from an hour before it opens (setting up) until it ends.
func fair_open() -> bool:
	var entry := YearCalendar.event(FAIR)
	if entry.is_empty() or String(entry.date) != YearCalendar.today_date():
		return false
	var now := GameClock.now_seconds()
	return now >= YearCalendar.start_of(entry) - 3600.0 and now < YearCalendar.end_of(entry)

func _figure(look: Dictionary, position: Vector3, yaw: float, parent: Node3D) -> Node3D:
	var holder := Node3D.new()
	holder.position = position
	holder.rotation.y = yaw
	parent.add_child(holder)
	var figure := Appearance.new()
	holder.add_child(figure)
	figure.apply_look(look)
	Student.make_blocker(holder)
	return holder

func _look(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 3571 + 11
	return Looks.random(rng)

func _build_fair() -> void:
	fair_root = Node3D.new()
	fair_root.name = "ClubFair"
	add_child(fair_root)
	var kit := MeshKit.new()
	var ids: Array = ClubData.CLUBS.keys()
	for index in range(ids.size()):
		var id := String(ids[index])
		var club: Dictionary = ClubData.CLUBS[id]
		var at: Vector3 = FAIR_TABLES[index][0]
		var yaw: float = FAIR_TABLES[index][1]
		var basis := Basis(Vector3.UP, yaw)
		var color: Color = club.color
		# A folding table in the club's colour, a banner behind it, flyers on top.
		kit.box("facade", at + Vector3(0, 0.72, 0), (basis * Vector3(1.8, 0.04, 0.76)).abs(), Color("f4f4f1"))
		kit.box("facade", at + basis * Vector3(0, 0.52, 0.37), (basis * Vector3(1.8, 0.42, 0.02)).abs(), color)
		for x in [-0.8, 0.8]:
			kit.box("metal", at + basis * Vector3(x, 0.36, 0), (basis * Vector3(0.04, 0.72, 0.6)).abs(), Color("3a4045"))
		for flyer in range(3):
			kit.box("facade", at + basis * Vector3(-0.5 + flyer * 0.4, 0.745, 0.1), (basis * Vector3(0.22, 0.01, 0.3)).abs(), Color("f2f2ee") if flyer % 2 == 0 else color.lightened(0.4))
		kit.solid(at + Vector3(0, 0.4, 0), (basis * Vector3(1.8, 0.8, 0.76)).abs())
		var banner := at + basis * Vector3(0, 0, -1.3)
		for x in [-0.55, 0.55]:
			kit.cylinder("metal", banner + basis * Vector3(x, 0, 0), banner + basis * Vector3(x, 2.4, 0), 0.025, Color("3a4045"))
		kit.box("facade", banner + Vector3(0, 1.7, 0), (basis * Vector3(1.1, 1.3, 0.03)).abs(), color)
		kit.solid(banner + Vector3(0, 1.2, 0), (basis * Vector3(1.2, 2.4, 0.1)).abs())
		var banner_text := String(club.short) if String(club.short).length() <= 14 else String(club.short).replace(" ", "\n")
		var sign := Geometry.wall_sign(fair_root, banner_text, banner + Vector3(0, 1.75, 0) + basis * Vector3(0, 0, 0.03), yaw, 22, 0.0055)
		sign.name = "Banner_" + id
		# The student running the table, behind it.
		_figure(_look(900 + index), at + basis * Vector3(0.3, 0, -0.62), yaw + PI, fair_root)
		var endpoint := Endpoint.new()
		endpoint.name = "FairTable_" + id
		endpoint.display_name = "%s · club fair" % club.short
		endpoint.reach = 1.7
		endpoint.position = at + basis * Vector3(0, 1.0, 0.75)
		endpoint.activated.connect(visit_table.bind(id))
		fair_root.add_child(endpoint)
		fair_tables[id] = endpoint
	kit.commit(fair_root, "FairTables")
	# A few classmates browsing.
	for index in range(BROWSERS.size()):
		_figure(_look(930 + index), BROWSERS[index][0], BROWSERS[index][1], fair_root)

func visit_table(id: String) -> void:
	YearCalendar.mark_completed(FAIR)
	campus.hud.open_modal(ClubPanel.new(id, PITCHES.get(id, "")))

func _build_pitch() -> void:
	pitch_root = Node3D.new()
	pitch_root.name = "PickUpGame"
	add_child(pitch_root)
	var kit := MeshKit.new()
	for x in [-11.2, -2.4]:
		var face := 1.0 if x < -6.0 else -1.0
		for z in [3.4, 6.6]:
			kit.cylinder("metal", Vector3(x, 0, z), Vector3(x, 1.2, z), 0.04, Color("f2f2ef"))
		kit.cylinder("metal", Vector3(x, 1.2, 3.4), Vector3(x, 1.2, 6.6), 0.04, Color("f2f2ef"))
		kit.box("facade", Vector3(x - face * 0.5, 0.6, 5.0), Vector3(0.02, 1.2, 3.2), Color(0.95, 0.95, 0.95, 1.0))
		kit.solid(Vector3(x - face * 0.25, 0.6, 5.0), Vector3(0.6, 1.2, 3.3))
	kit.box("facade", Vector3(-6.0, 0.11, 5.4), Vector3(0.22, 0.22, 0.22), Color("f2f2ef"))
	kit.commit(pitch_root, "PitchKit")
	var spots := [[Vector3(-9.4, 0, 4.2), -PI / 2], [Vector3(-7.8, 0, 6.0), -PI / 2], [Vector3(-6.6, 0, 3.6), PI / 2], [Vector3(-4.8, 0, 5.4), PI / 2], [Vector3(-3.4, 0, 4.4), PI / 2], [Vector3(-10.6, 0, 5.0), -PI / 2]]
	for index in range(spots.size()):
		var look := _look(950 + index)
		look.outfit.top = "intramural_jersey" if index % 2 == 0 else "white_tee"
		look.outfit.outerwear = ""
		look.outfit.back = ""
		_figure(Looks.sanitize(look), spots[index][0], spots[index][1], pitch_root)
	pitch_endpoint = Endpoint.new()
	pitch_endpoint.name = "PickUpGame"
	pitch_endpoint.display_name = "Intramural soccer"
	pitch_endpoint.reach = 1.8
	pitch_endpoint.position = Vector3(-2.0, 1.0, 1.4)
	pitch_endpoint.activated.connect(join_game)
	pitch_root.add_child(pitch_endpoint)

func join_game() -> void:
	if Clubs.is_member("intramurals") and Clubs.meeting_on("intramurals"):
		campus.hud.open_modal(ClubEvents.panel_for("intramurals"))
	elif Clubs.meeting_on("intramurals"):
		campus.hud.show_message("Intramural Sports is playing. Join it at the Office of Student Life in the Student Center to get a game.", 5.0)
	else:
		campus.hud.show_message("You took part today. Same time next week.", 4.0)
