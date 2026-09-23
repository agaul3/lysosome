extends RefCounted
## Receptor-occupancy / dose-response math shared by slides and the upcoming
## interactive model. Concentrations are in arbitrary consistent units.

## Hill equation: response for an agonist at concentration c.
static func response(c: float, emax: float, ec50: float, hill := 1.0) -> float:
	if c <= 0.0:
		return 0.0
	var ch := pow(c, hill)
	return emax * ch / (ch + pow(ec50, hill))

## A reversible competitive antagonist at concentration b with dissociation
## constant kb raises the agonist's apparent EC50 by the dose ratio (1 + b/kb)
## (Gaddum/Schild) and leaves Emax unchanged.
static func competitive_ec50(ec50: float, b: float, kb: float) -> float:
	return ec50 * (1.0 + b / kb)

## Classic noncompetitive (insurmountable) antagonism removes a fraction of
## functional receptors: Emax falls, EC50 is unchanged in this simple model.
static func noncompetitive_emax(emax: float, fraction_blocked: float) -> float:
	return emax * (1.0 - clampf(fraction_blocked, 0.0, 1.0))

## Fractional occupancy for a ligand at concentration c with dissociation constant kd.
static func occupancy(c: float, kd: float) -> float:
	return c / (c + kd) if c > 0.0 else 0.0
