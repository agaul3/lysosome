extends "res://ui/modal_panel.gd"
## The student organizations (data/clubs.gd): what each does, when and where
## it meets, your reputation, and joining or leaving. The Office of Student
## Life and the club board list them all; a table at the Club Fair shows its
## own club first, with a word from the student running it.
const Data = preload("res://data/clubs.gd")
const Clothing = preload("res://data/clothing.gd")
var focus := ""
var greeting := ""
var list: VBoxContainer
var count_label: Label
var status: Label

## `focus_id` puts one club first (a fair table); `hello` is what its
## representative says.
func _init(focus_id := "", hello := "") -> void:
	super(640.0)
	focus = focus_id
	greeting = hello

func build() -> void:
	if focus.is_empty():
		set_heading("Office of Student Life", "Student organizations")
	else:
		set_heading("Club Fair", String(Data.get_club(focus).name))
	if not greeting.is_empty():
		add_text(greeting, UI.TEXT, UI.SIZE_BODY)
	count_label = UI.label("", UI.SIZE_LABEL, UI.TEXT_MUTED, 500)
	body.add_child(count_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(width - 52, 360 if focus.is_empty() else 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	status = UI.label("", UI.SIZE_LABEL, UI.SUCCESS, 500)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.x = width - 52
	body.add_child(status)
	add_button("Done", close, true)
	refresh()

func refresh() -> void:
	count_label.text = "Member of %d of %d organizations you can join" % [Clubs.memberships.size(), Data.MAX_MEMBERSHIPS]
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var ids: Array = Data.CLUBS.keys()
	if not focus.is_empty():
		ids.erase(focus)
		ids.push_front(focus)
	for id in ids:
		list.add_child(_card(String(id)))

func _card(id: String) -> Control:
	var club := Data.get_club(id)
	var card := UI.card(Vector4(14, 10, 14, 10))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	column.add_child(top)
	top.add_child(Icon.new(String(club.icon), 18, club.color.lightened(0.25)))
	var name_label := UI.label(String(club.name), UI.SIZE_BODY, UI.TEXT, 600)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	top.add_child(UI.chip(String(club.category), club.color.lightened(0.2)))
	column.add_child(UI.paragraph(String(club.pitch), width - 90, UI.SIZE_LABEL, UI.TEXT_MUTED))
	column.add_child(UI.label("%s  ·  %s" % [Clubs.when_text(id), String(club.where)], UI.SIZE_CAPTION, UI.TEXT_FAINT, 500))
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	column.add_child(bottom)
	var detail := ""
	if Clubs.is_member(id) or Clubs.points(id) > 0:
		var level := Clubs.level(id)
		var progress := Clubs.level_progress(id)
		detail = "Level %d · %s" % [level, Data.LEVEL_NAMES[level - 1]]
		if int(progress[1]) > 0:
			detail += "  ·  %d / %d reputation to the next level" % [progress[0], progress[1]]
	else:
		detail = "Level 2 reward: " + Clothing.item_name(String(club.shirt))
	var detail_label := UI.label(detail, UI.SIZE_CAPTION, UI.REWARD if Clubs.is_member(id) else UI.TEXT_MUTED, 500)
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(detail_label)
	var button := Button.new()
	button.name = ("Leave_" if Clubs.is_member(id) else "Join_") + id
	button.text = "Leave" if Clubs.is_member(id) else "Join"
	button.theme_type_variation = "GhostButton" if Clubs.is_member(id) else "PrimaryButton"
	button.disabled = not Clubs.is_member(id) and not Clubs.join_block(id).is_empty()
	button.pressed.connect(_toggle.bind(id))
	bottom.add_child(button)
	return card

func _toggle(id: String) -> void:
	var club := Data.get_club(id)
	if Clubs.is_member(id):
		Clubs.leave(id)
		status.add_theme_color_override("font_color", UI.TEXT_MUTED)
		status.text = "You left %s. Your reputation is kept if you come back." % club.name
		Sfx.play("ui_close")
	elif Clubs.join(id):
		status.add_theme_color_override("font_color", UI.SUCCESS)
		status.text = "Welcome to %s! %s. It's in your journal." % [club.name, Clubs.when_text(id)]
		Sfx.play("ui_confirm")
	refresh()
