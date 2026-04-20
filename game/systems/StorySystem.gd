class_name StorySystem

static func get_event(event_id: String) -> Dictionary:
	return DataLoader.get_story_event(event_id)

static func mark_seen(event_id: String) -> void:
	GameState.story.mark_seen(event_id)

static func has_seen(event_id: String) -> bool:
	return GameState.story.has_seen(event_id)

## Evaluates a single condition key/value pair against live game state.
## Called by both should_trigger() and MilestoneSystem.condition_met() so the
## two systems stay in sync without duplicating match logic.
static func eval_condition(key: String, value: Variant) -> bool:
	match key:
		"creature_evolved":
			return GameState.creature.evolved == bool(value)
		"creature_level":
			return GameState.creature.level >= int(value)
		"has_item":
			return GameState.player.has_item(str(value))
		"food_gathered_total":
			return GameState.world.get("food_gathered_total", 0) >= int(value)
	push_warning("StorySystem: unknown condition key '%s' — failing closed" % key)
	return false

## Returns true when all trigger conditions are satisfied and the event is unseen.
## Add new condition types in eval_condition() above; this function needs no edit.
static func should_trigger(event_id: String) -> bool:
	if has_seen(event_id):
		return false
	var event := get_event(event_id)
	if event.is_empty():
		return false
	for key: String in event.get("trigger_condition", {}):
		if not eval_condition(key, event["trigger_condition"][key]):
			return false
	return true

## Applies all side-effects of a story event: item grants, area unlocks,
## clothing unlocks, age advancement. Call this when the event fires,
## before mark_seen(), so rewards are processed exactly once.
static func apply_rewards(event_id: String) -> void:
	var event := get_event(event_id)
	if event.is_empty():
		return

	# Grant item — field is null in JSON when no item is awarded
	var item: Variant = event.get("grants_item")
	if item != null:
		InventorySystem.add(GameState.player, str(item))

	# Unlock area — field is null in JSON when no area is unlocked
	var area: Variant = event.get("unlocks_area")
	if area != null:
		GameState.story.unlock_area(str(area))

	# Unlock clothing items
	for clothing_id: String in event.get("unlocks_clothing", []):
		GameState.story.unlock_clothing_item(clothing_id)

	# Advance protagonist age
	if event.get("advances_player_age", false):
		GameState.player.age_stage += 1
