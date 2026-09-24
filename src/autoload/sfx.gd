extends Node
## Plays the game's sound effects on the Master bus (so the settings volume
## applies). Keeps a small pool so overlapping sounds do not cut each other off.
const SOUNDS := {
	"correct": preload("res://audio/sfx/correct.wav"),
	"incorrect": preload("res://audio/sfx/incorrect.wav"),
	"level_up": preload("res://audio/sfx/level_up.wav"),
	"achievement": preload("res://audio/sfx/achievement.wav"),
	"ui_move": preload("res://audio/sfx/ui_move.wav"),
	"ui_confirm": preload("res://audio/sfx/ui_confirm.wav"),
	"ui_open": preload("res://audio/sfx/ui_open.wav"),
	"ui_close": preload("res://audio/sfx/ui_close.wav"),
}
const VOLUME_DB := {"correct": -6.0, "incorrect": -9.0, "level_up": -2.0, "achievement": -4.0, "ui_move": -22.0, "ui_confirm": -16.0, "ui_open": -17.0, "ui_close": -18.0}
var players: Array[AudioStreamPlayer] = []
## Names of sounds played, newest last (used by tests and debugging).
var history: Array[String] = []

func _ready() -> void:
	for index in range(6):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		players.append(player)
	# Answer and level-up sounds follow the academic record, wherever answers come from.
	AcademicSession.answer_recorded.connect(func(result: Dictionary) -> void: play("correct" if result.correct else "incorrect"))
	AcademicSession.level_up.connect(_on_level_up)

func _on_level_up(_from: int, _to: int) -> void:
	# Let the answer chime land first; the fanfare is the more prominent sound.
	await get_tree().create_timer(0.25).timeout
	play("level_up")

func play(sound: String) -> void:
	if not SOUNDS.has(sound):
		return
	history.append(sound)
	if history.size() > 32:
		history.pop_front()
	# Headless runs (tests) use a dummy audio driver that never frees finished
	# playbacks; record the request but don't start audio there.
	if DisplayServer.get_name() == "headless":
		return
	var player := players[0]
	for candidate in players:
		if not candidate.playing:
			player = candidate
			break
	player.stream = SOUNDS[sound]
	player.volume_db = VOLUME_DB.get(sound, -6.0)
	player.play()

## Release playbacks on shutdown so nothing is left referencing the streams.
func _exit_tree() -> void:
	for player in players:
		player.stop()
		player.stream = null
