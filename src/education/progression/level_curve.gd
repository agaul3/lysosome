extends RefCounted
## Escalating RPG level curve, configured in data/academic_config.json
## ("level_curve": base_xp, growth, max_level). Every level/XP calculation in
## the game goes through here.
##
## Formula: reaching level L+1 from level L costs round(base_xp × growth^(L−1)).
## With base 80 and growth 1.3: 80, 104, 135, 176, … so the cumulative totals
## are level 2 at 80 XP, level 3 at 184, level 4 at 319, level 5 at 495.
## XP is a running total; overflow past a threshold simply carries into the
## next level. Negative totals (a late arrival before any reward) count as 0.

const DEFAULT_CURVE := {"base_xp": 80, "growth": 1.3, "max_level": 50}

## Looked up at runtime (not by autoload name) so this script also compiles
## when preloaded before the autoloads exist, e.g. by tests.
static func _curve() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var clock: Node = tree.root.get_node_or_null("GameClock") if tree else null
	return clock.config.get("level_curve", DEFAULT_CURVE) if clock else DEFAULT_CURVE

## XP needed to go from `level` to `level + 1`.
static func cost(level: int) -> int:
	var curve := _curve()
	return int(round(float(curve.base_xp) * pow(float(curve.growth), level - 1)))

## Total XP at which `level` is reached (level 1 starts at 0).
static func threshold(level: int) -> int:
	var total := 0
	for index in range(1, level):
		total += cost(index)
	return total

static func level_for_xp(xp: int) -> int:
	var level := 1
	var max_level := int(_curve().max_level)
	var total := maxi(xp, 0)
	while level < max_level and total >= threshold(level + 1):
		level += 1
	return level

## Progress toward the next level, for the HUD.
static func progress(xp: int) -> Dictionary:
	var level := level_for_xp(xp)
	var start := threshold(level)
	var needed := cost(level)
	var into := maxi(xp, 0) - start
	return {"level": level, "into": into, "needed": needed, "fraction": clampf(float(into) / needed, 0.0, 1.0)}
