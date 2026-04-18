class_name GrowthSystem

## Returns the full stage definition dict for the player's current age_stage.
static func current_stage_def() -> Dictionary:
	return DataLoader.get_growth_stage(GameState.player.age_stage)

## Movement speed in pixels/second for the current growth stage.
static func speed() -> float:
	return float(current_stage_def().get("speed", 170))

## Maximum total item count the player can carry at the current growth stage.
static func carry_capacity() -> int:
	return int(current_stage_def().get("carry_capacity", 15))

## Number of clothing slots available (1 = protagonist outfit only, 2 = + creature accessory).
static func clothing_slots() -> int:
	return int(current_stage_def().get("clothing_slots", 1))

## Side length in pixels used to draw the protagonist square.
static func draw_size() -> float:
	return float(current_stage_def().get("draw_size", 22))

## Human-readable label for the current stage (e.g. "Child", "Teen").
static func display_name() -> String:
	return current_stage_def().get("display_name", "Child")
