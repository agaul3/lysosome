extends RefCounted
## Stable IDs can be serialized by a future save system. All visuals are original geometry.
const DEFAULT_ID := "sage"
const PRESETS: Array[Dictionary] = [
	{"id": "sage", "name": "Sage", "description": "Sage overshirt · dark curls", "skin": "b77958", "hair": "29282c", "shirt": "648f81", "pants": "283c50", "hair_style": 0},
	{"id": "indigo", "name": "Indigo", "description": "Indigo scrubs · cropped hair", "skin": "704b3b", "hair": "221f24", "shirt": "667fab", "pants": "343d5c", "hair_style": 1},
	{"id": "ochre", "name": "Ochre", "description": "Ochre sweater · auburn bob", "skin": "e6b494", "hair": "854b37", "shirt": "cd9a4c", "pants": "4b5359", "hair_style": 2},
	{"id": "clay", "name": "Clay", "description": "Clay jacket · dark bun", "skin": "d29d78", "hair": "332c32", "shirt": "b7766a", "pants": "304b4e", "hair_style": 3},
]

## Non-selectable looks for classmates and faculty; same schema as PRESETS.
const EXTRAS: Array[Dictionary] = [
	{"id": "professor", "name": "Professor", "description": "White coat · silver hair", "skin": "c89373", "hair": "b9b6b0", "shirt": "eef1ee", "pants": "3a4148", "hair_style": 1},
	{"id": "teal", "name": "Teal", "description": "Teal hoodie", "skin": "8d5a44", "hair": "1f1c20", "shirt": "3f8f8c", "pants": "2d3441", "hair_style": 3},
	{"id": "plum", "name": "Plum", "description": "Plum cardigan", "skin": "f0c7a8", "hair": "c79a5b", "shirt": "7d5a86", "pants": "3b3f4a", "hair_style": 2},
]

static func is_valid(id: String) -> bool:
	for preset in PRESETS:
		if preset.id == id:
			return true
	return false

static func get_preset(id: String) -> Dictionary:
	for preset in PRESETS:
		if preset.id == id:
			return preset.duplicate()
	for preset in EXTRAS:
		if preset.id == id:
			return preset.duplicate()
	return PRESETS[0].duplicate()
