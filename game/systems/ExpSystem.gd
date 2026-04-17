class_name ExpSystem

const EXP_PER_LEVEL := 150

# Returns true if the creature levelled up.
static func apply_exp(creature: CreatureData, amount: int) -> bool:
	creature.exp += amount
	if creature.exp >= exp_to_next(creature.level):
		creature.exp  -= exp_to_next(creature.level)
		creature.level += 1
		return true
	return false

# Flat curve for MVP. Replace with a formula here to tune difficulty.
static func exp_to_next(_level: int) -> int:
	return EXP_PER_LEVEL

# 0.0 – 1.0 fill ratio for the EXP progress bar.
static func progress_ratio(creature: CreatureData) -> float:
	return clampf(float(creature.exp) / float(exp_to_next(creature.level)), 0.0, 1.0)
