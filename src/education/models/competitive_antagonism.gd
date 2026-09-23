extends RefCounted
## Interactive competitive-antagonism model. The agonist A and a reversible
## competitive antagonist B share one binding site. At equilibrium (Gaddum):
##   agonist occupancy    fA = (A/KA) / (1 + A/KA + B/KB)
##   antagonist occupancy fB = (B/KB) / (1 + A/KA + B/KB)
## With a full agonist and simple occupancy theory, response = Emax * fA, so
## B raises the agonist's EC50 by the dose ratio (1 + B/KB) and leaves Emax
## unchanged. Concentrations are relative to KA (so EC50 without B is 1).
const DoseResponse = preload("res://education/models/dose_response.gd")
const KA := 1.0
const EMAX := 100.0
## Fixed antagonist level used in the activity: dose ratio 10.
const ANTAGONIST_RATIO := 9.0
const LOG_MIN := -2.0
const LOG_MAX := 3.0
const RECEPTORS := 24

var log_agonist := -1.5
var antagonist := false
## Eased 0..1 amount of antagonist actually present (it washes in visibly).
var antagonist_level := 0.0
var time := 0.0
var receptor_seeds: Array[float] = []

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for index in range(RECEPTORS):
		receptor_seeds.append(rng.randf())

func agonist() -> float:
	return pow(10.0, log_agonist)

func antagonist_ratio() -> float:
	return ANTAGONIST_RATIO * antagonist_level

func agonist_occupancy() -> float:
	var a := agonist() / KA
	return a / (1.0 + a + antagonist_ratio())

func antagonist_occupancy() -> float:
	var a := agonist() / KA
	return antagonist_ratio() / (1.0 + a + antagonist_ratio())

func response() -> float:
	return EMAX * agonist_occupancy()

func apparent_ec50() -> float:
	return DoseResponse.competitive_ec50(KA, antagonist_ratio(), 1.0)

func change_agonist(delta_log: float) -> void:
	log_agonist = clampf(log_agonist + delta_log, LOG_MIN, LOG_MAX)

func advance(delta: float) -> void:
	time += delta
	antagonist_level = move_toward(antagonist_level, 1.0 if antagonist else 0.0, delta / 1.5)

## Receptor i's state for drawing: 0 empty, 1 agonist-bound, 2 antagonist-bound.
## Each receptor's threshold drifts slowly so molecules visibly bind and
## unbind while the overall fractions stay at their equilibrium values.
func receptor_state(index: int) -> int:
	var u := fposmod(receptor_seeds[index] + time * (0.05 + 0.03 * receptor_seeds[index]), 1.0)
	var f_a := agonist_occupancy()
	if u < f_a:
		return 1
	if u < f_a + antagonist_occupancy():
		return 2
	return 0
