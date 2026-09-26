extends RefCounted
## The panel that runs a club's meeting (data/clubs.gd "activity").
const Data = preload("res://data/clubs.gd")
const PANELS := {
	"kitchen": "res://ui/clubs/kitchen_panel.gd",
	"free_clinic": "res://ui/clubs/free_clinic_panel.gd",
	"suturing": "res://ui/clubs/suturing_panel.gd",
	"cpr": "res://ui/clubs/cpr_panel.gd",
	"spanish": "res://ui/clubs/quiz_club_panel.gd",
	"journal": "res://ui/clubs/quiz_club_panel.gd",
	"intramurals": "res://ui/clubs/intramurals_panel.gd",
}

static func panel_for(club_id: String) -> Control:
	var activity := String(Data.get_club(club_id).get("activity", ""))
	return load(PANELS.get(activity, "res://ui/clubs/club_event_panel.gd")).new(club_id)
