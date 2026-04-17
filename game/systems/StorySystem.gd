class_name StorySystem

static func get_event(event_id: String) -> Dictionary:
	return DataLoader.get_story_event(event_id)

static func mark_seen(event_id: String) -> void:
	GameState.story.mark_seen(event_id)

static func has_seen(event_id: String) -> bool:
	return GameState.story.has_seen(event_id)

## Returns true when all trigger conditions are satisfied and the event is unseen.
## Extend the match block here to support new trigger condition keys.
static func should_trigger(event_id: String) -> bool:
	if has_seen(event_id):
		return false
	var event := get_event(event_id)
	if event.is_empty():
		return false
	var conditions: Dictionary = event.get("trigger_condition", {})
	for key: String in conditions:
		match key:
			"creature_evolved":
				if GameState.creature.evolved != conditions[key]:
					return false
	return true

## Applies all side-effects of a story event: item grants, area unlocks,
## clothing unlocks, age advancement. Call this when the event fires,
## before mark_seen(), so rewards are processed exactly once.
static func apply_rewards(event_id: String) -> void:
	var event := get_event(event_id)
	if event.is_empty():
		return

	# Grant item
	var item: String = event.get("grants_item", "") if event.get("grants_item") != null else ""
	if not item.is_empty():
		InventorySystem.add(GameState.player, item)

	# Unlock area
	var area: String = event.get("unlocks_area", "") if event.get("unlocks_area") != null else ""
	if not area.is_empty():
		GameState.story.unlock_area(area)

	# Unlock clothing items
	for clothing_id: String in event.get("unlocks_clothing", []):
		GameState.story.unlock_clothing_item(clothing_id)

	# Advance protagonist age
	if event.get("advances_player_age", false):
		GameState.player.age_stage += 1
