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

## Returns a short "(have / need)" suffix for countable conditions.
## Binary conditions (has_item, creature_evolved) return "" — no fraction exists.
static func progress_text() -> String:
	if is_complete():
		return ""
	var m := get_milestone(current_phase())
	if m.is_empty():
		return ""
	var required_val = m.get("condition_value")
	match m.get("condition_key", ""):
		"food_gathered_total":
			var have: int = mini(GameState.world.get("food_gathered_total", 0), int(required_val))
			return "  (%d / %d)" % [have, int(required_val)]
		"creature_level":
			return "  (Lv. %d / %d)" % [GameState.creature.level, int(required_val)]
	return ""

## Delegates to StorySystem.eval_condition() so condition logic stays in one place.
static func condition_met() -> bool:
	if is_complete():
		return false
	var m := get_milestone(current_phase())
	if m.is_empty():
		return false
	return StorySystem.eval_condition(m.get("condition_key", ""), m.get("condition_value"))

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
