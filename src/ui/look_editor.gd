extends VBoxContainer
## Appearance editor shared by the character creator and the closet mirror:
## rows for build, skin tone and height; hair style and colour; eyes, brows,
## mouth, cheeks and facial hair; and (in the creator) a starting outfit from
## the unlocked clothing. Emits `look_changed` with the full look after any edit.
signal look_changed(look: Dictionary)
const UI = preload("res://ui/style/ui_style.gd")
const Looks = preload("res://data/looks.gd")
const Clothing = preload("res://data/clothing.gd")
const OptionRow = preload("res://ui/option_row.gd")
var look: Dictionary = Looks.default_look()
var rows := {}
var include_outfit := false

func _init(with_outfit := false) -> void:
	include_outfit = with_outfit

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_heading("Body")
	_row("build", "Build", Looks.BUILDS)
	_row("skin", "Skin tone", Looks.SKIN_TONES, true)
	var heights: Array = []
	for step in range(13):
		var scale := snappedf(Looks.HEIGHT_MIN + step * 0.01, 0.01)
		heights.append([str(scale), _height_text(scale)])
	_row("height", "Height", heights)
	_heading("Hair")
	_row("hair_style", "Style", Looks.HAIR_STYLES)
	_row("hair_color", "Colour", Looks.HAIR_COLORS, true)
	_heading("Face")
	_row("eye_style", "Eyes", Looks.EYE_STYLES)
	_row("eye_color", "Eye colour", Looks.EYE_COLORS, true)
	_row("brows", "Brows", Looks.BROWS)
	_row("mouth", "Mouth", Looks.MOUTHS)
	_row("cheeks", "Cheeks", Looks.CHEEKS)
	_row("facial_hair", "Facial hair", Looks.FACIAL_HAIR)
	if include_outfit:
		_heading("Starting outfit")
		for slot in ["outerwear", "top", "bottom", "shoes", "eyewear", "head"]:
			_row("outfit:" + slot, Clothing.SLOT_NAMES[slot], _outfit_choices(slot))
	set_look(look)

static func _height_text(scale: float) -> String:
	var cm := Looks.height_cm(scale)
	var inches := int(round(cm / 2.54))
	return "%d cm · %d′%d″" % [cm, inches / 12, inches % 12]

func _heading(text: String) -> void:
	if get_child_count() > 0:
		add_child(UI.spacer(4))
	add_child(UI.label(text, UI.SIZE_CAPTION, UI.TEXT_FAINT, 600, true))

func _row(key: String, title: String, choices: Array, swatches := false) -> void:
	var row := OptionRow.new(key, title, choices, swatches)
	row.name = key.replace(":", "_").capitalize().replace(" ", "") + "Row"
	add_child(row)
	rows[key] = row
	row.changed.connect(_on_row_changed.bind(key))

func _outfit_choices(slot: String) -> Array:
	var choices: Array = []
	if not Clothing.REQUIRED.has(slot):
		choices.append(["", "None"])
	for id in Clothing.items_for(slot):
		if Clothing.unlocked(id):
			choices.append([id, Clothing.ITEMS[id][0]])
	return choices

func set_look(target: Dictionary) -> void:
	look = Looks.sanitize(target)
	for key in rows:
		var row: Button = rows[key]
		if key.begins_with("outfit:"):
			row.set_value(String(look.outfit[key.trim_prefix("outfit:")]))
		elif key == "height":
			row.set_value(str(snappedf(float(look.height), 0.01)))
		else:
			row.set_value(String(look[key]))

func _on_row_changed(value: String, key: String) -> void:
	if key.begins_with("outfit:"):
		look.outfit[key.trim_prefix("outfit:")] = value
	elif key == "height":
		look.height = float(value)
	else:
		look[key] = value
	look_changed.emit(look.duplicate(true))

## A fresh random look (keeps the rows in step).
func randomize_look(rng: RandomNumberGenerator) -> void:
	var fresh := Looks.random(rng)
	for slot in fresh.outfit:
		if fresh.outfit[slot] != "" and not Clothing.unlocked(fresh.outfit[slot]):
			fresh.outfit[slot] = look.outfit[slot]
	if not include_outfit:
		fresh.outfit = look.outfit
	set_look(fresh)
	look_changed.emit(look.duplicate(true))

func first_row() -> Control:
	return rows.get("build")
