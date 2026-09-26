extends "res://world/interior/interior_scene.gd"
## The Harbor Street Community Center, a campus-shuttle ride from the Student
## Center (community_center_builder.gd). Club members serve supper at the
## serving line (Community Kitchen Volunteers) and take vitals at the free
## clinic (Student-Run Free Clinic) while their meetings are on; at the
## Thanksgiving supper any student can help. The shuttle takes you back.
const Builder = preload("res://world/community/community_center_builder.gd")
const Looks = preload("res://data/looks.gd")
const ClubEvents = preload("res://ui/clubs/club_events.gd")
const ClubData = preload("res://data/clubs.gd")
const ShuttlePanel = preload("res://ui/shuttle_panel.gd")
const KitchenPanel = preload("res://ui/clubs/kitchen_panel.gd")
## Filled in by the builder.
var entrance_doors: Array = []
var reception_point: Vector3
var notices_point: Vector3
var serving_point: Vector3
var pantry_point: Vector3
var vitals_point: Vector3
## The interactions, for tests.
var serving_line: Node3D
var vitals: Node3D
var shuttle_stop: Node3D

func zones() -> Dictionary:
	return {"center": {"title": "Harbor Street Community Center", "origin": Vector3.ZERO, "min": Vector2(-7.0, -4.0), "max": Vector2(7.0, 5.0), "view": 20.0}}

func builders() -> Dictionary:
	return {"center": Builder}

func scene_key() -> String:
	return "community"

func arrival() -> Vector3:
	return anchor("entrance")

func arrival_yaw() -> float:
	return 0.0

## The neighborhood's guests and staff: everyday clothes, every face different.
func guest_look(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 6151 + 7
	return Looks.random(rng)

func dressed(look: Dictionary, outfit: Dictionary) -> Dictionary:
	var copy := look.duplicate(true)
	for slot in outfit:
		copy.outfit[slot] = outfit[slot]
	return Looks.sanitize(copy)

func populate() -> void:
	build_root = zone_roots.center
	shuttle_stop = add_endpoint("ShuttleHome", "Take the campus shuttle back", "", anchor("entrance") + Vector3(0, 1.0, 1.0), 1.8)
	shuttle_stop.activated.connect(open_shuttle)
	add_endpoint("Reception", "Talk to the front desk", "\"Welcome to Harbor Street! Supper's at five-thirty on Mondays and Wednesdays, the pantry's open Tuesdays and Saturdays, and the students run their free clinic on Thursday evenings and Saturday mornings. Everyone's welcome here.\"", reception_point, 1.8)
	add_endpoint("Notices", "Read the community notices", "Help applying for SNAP, Tuesdays with a benefits navigator · English classes, free, Wednesday nights · Flu shots at the free clinic in October · Free tax preparation in February · Legal aid for tenants, first Friday of the month · The job center on Harbor Street is hiring for the port.", notices_point, 1.7)
	add_endpoint("Pantry", "The food pantry", "A client-choice pantry: people shop the shelves for what their family will actually eat, rather than being handed a set bag. It wastes less and preserves dignity. Volunteers restock on Tuesday mornings.", pantry_point, 1.7)
	serving_line = add_endpoint("ServingLine", "The serving line", "", serving_point, 1.8)
	serving_line.activated.connect(use_serving_line)
	vitals = add_endpoint("VitalsStation", "The free clinic's vitals station", "", vitals_point, 1.7)
	vitals.activated.connect(use_vitals)
	add_walkers("center", [Vector2(-4.2, 6.2), Vector2(-8.7, 4.4), Vector2(-8.7, 0.3), Vector2(-4.1, 0.3), Vector2(-4.1, -4.6), Vector2(4.6, 0.3), Vector2(4.8, 6.0)],
		[[0, 1], [1, 2], [2, 3], [3, 4], [3, 5], [5, 6]], 3, [[Vector2(-10.4, 5.2), 1.6], [Vector2(-8.0, -5.6), 2.0]])
	add_fill("center", [Vector3(-8, 3.0, 0), Vector3(2, 3.0, -2), Vector3(10, 3.0, 2), Vector3(-6, 3.0, 7)], 0.32, 12.0, Color("fff0da"))
	build_root = self
	_refresh()
	GameClock.minute_changed.connect(_refresh)

## What each station offers right now.
func _refresh() -> void:
	serving_line.display_name = "Serve supper" if _serving_activity() != "" else "The serving line"
	vitals.display_name = "Take vitals at the free clinic" if Clubs.meeting_on("free_clinic") and Clubs.is_member("free_clinic") else "The free clinic's vitals station"

## "club" (a Community Kitchen meeting, for members), an open volunteer
## event's id (the Thanksgiving supper), or "" when nothing is on.
func _serving_activity() -> String:
	if Clubs.meeting_on("community_kitchen") and Clubs.is_member("community_kitchen"):
		return "club"
	var now := GameClock.now_seconds()
	for entry in YearCalendar.events_on(YearCalendar.today_date()):
		if String(entry.get("place", "")) == "community" and not YearCalendar.completed(entry) and now >= YearCalendar.start_of(entry) - 1800.0 and now < YearCalendar.end_of(entry):
			return String(entry.id)
	return ""

func use_serving_line() -> void:
	var activity := _serving_activity()
	if activity == "club":
		hud.open_modal(ClubEvents.panel_for("community_kitchen"))
	elif not activity.is_empty():
		var panel = KitchenPanel.new("community_kitchen")
		panel.event_id = activity
		hud.open_modal(panel)
	elif Clubs.meeting_on("community_kitchen"):
		hud.show_message("The Community Kitchen Volunteers are serving. Join them at the Office of Student Life in the Student Center to help.", 5.0)
	else:
		hud.show_message("Supper is served Mondays and Wednesdays from 5:30 PM: %s." % Clubs.when_text("community_kitchen"), 5.0)

func use_vitals() -> void:
	if Clubs.meeting_on("free_clinic") and Clubs.is_member("free_clinic"):
		hud.open_modal(ClubEvents.panel_for("free_clinic"))
	elif Clubs.meeting_on("free_clinic"):
		hud.show_message("The Student-Run Free Clinic is seeing patients. Join it at the Office of Student Life to volunteer.", 5.0)
	else:
		hud.show_message("The Student-Run Free Clinic runs %s." % ClubData.schedule_text("free_clinic"), 5.0)

func open_shuttle() -> void:
	var panel := ShuttlePanel.new("community")
	panel.ride.connect(ride_home)
	hud.open_modal(panel)

func ride_home(to_stop: String, minutes: int) -> void:
	hud.close_modal()
	YearCalendar.pass_time(minutes)
	Achievements.bump("shuttle_rides")
	AppState.enter_campus("shuttle_" + to_stop)
