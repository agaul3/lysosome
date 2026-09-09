extends RefCounted
## Stable IDs can be serialized by a future save system. All visuals are original geometry.
const DEFAULT_ID := "sage"
const PRESETS: Array[Dictionary] = [
	{"id": "sage", "name": "Sage", "description": "Sage overshirt · dark curls", "skin": "b77958", "hair": "29282c", "shirt": "648f81", "pants": "283c50", "hair_style": 0},
	{"id": "indigo", "name": "Indigo", "description": "Indigo scrubs · cropped hair", "skin": "704b3b", "hair": "221f24", "shirt": "667fab", "pants": "343d5c", "hair_style": 1},
	{"id": "ochre", "name": "Ochre", "description": "Ochre sweater · auburn bob", "skin": "e6b494", "hair": "854b37", "shirt": "cd9a4c", "pants": "4b5359", "hair_style": 2},
	{"id": "clay", "name": "Clay", "description": "Clay jacket · dark bun", "skin": "d29d78", "hair": "332c32", "shirt": "b7766a", "pants": "304b4e", "hair_style": 3},
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
	return PRESETS[0].duplicate()
