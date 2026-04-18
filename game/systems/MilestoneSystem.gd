class_name MilestoneSystem

static func get_milestone(phase: int) -> Dictionary:
	for m: Dictionary in DataLoader.get_all_milestones():
		if m.get("phase") == phase:
			return m
	return {}

static func current_phase() -> int:
	return GameState.world.get("milestone_phase", 0)

static func is_complete() -> bool:
	return current_phase() >= DataLoader.get_all_milestones().size()

static func objective_text() -> String:
	if is_complete():
		return ""
	return get_milestone(current_phase()).get("objective", "")

static func progress_text() -> String:
	if is_complete():
		return ""
	var m := get_milestone(current_phase())
	if m.is_empty():
		return ""
	match m.get("condition_key", ""):
		"food_gathered_total":
			var have: int = mini(GameState.world.get("food_gathered_total", 0),
								 int(m.get("condition_value", 0)))
			return "  (%d / %d)" % [have, int(m.get("condition_value", 0))]
		"creature_level":
			return "  (Lv. %d / %d)" % [GameState.creature.level,
										 int(m.get("condition_value", 0))]
	return ""

static func condition_met() -> bool:
	if is_complete():
		return false
	var m := get_milestone(current_phase())
	if m.is_empty():
		return false
	var need = m.get("condition_value")
	match m.get("condition_key", ""):
		"food_gathered_total":
			return GameState.world.get("food_gathered_total", 0) >= int(need)
		"creature_level":
			return GameState.creature.level >= int(need)
		"has_item":
			return GameState.player.has_item(str(need))
		"creature_evolved":
			return GameState.creature.evolved == bool(need)
	return false

## Advances to the next phase when conditions are met.
## Returns the just-completed milestone dict, or {} if no advance occurred.
static func check_and_advance() -> Dictionary:
	if is_complete():
		return {}
	if condition_met():
		var m := get_milestone(current_phase())
		GameState.world["milestone_phase"] = current_phase() + 1
		return m
	return {}
