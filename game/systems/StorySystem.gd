class_name StorySystem

static func get_event(event_id: String) -> Dictionary:
	return DataLoader.get_story_event(event_id)

static func mark_seen(event_id: String) -> void:
	var seen: Array = GameState.world["story_events_seen"]
	if event_id not in seen:
		seen.append(event_id)

static func has_seen(event_id: String) -> bool:
	return event_id in GameState.world["story_events_seen"]

# Returns true when all trigger conditions are satisfied and event not yet seen.
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
