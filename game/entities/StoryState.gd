## Runtime story-progression state.
## Tracks what has happened in the narrative so far.
## Stored in GameState.story and persisted to save/save.json.
## Logic lives in StorySystem — this class is a plain data container.
class_name StoryState
extends RefCounted

## IDs of StoryEvents that have already been triggered and displayed.
## StorySystem.should_trigger() returns false for any event already in this list,
## preventing replays.
var seen_events: Array = []

## Area IDs unlocked through story progression.
## "whispering_grove" is always accessible (no entry needed here).
## SceneManager / ExploreScene checks this before allowing entry to locked areas.
var unlocked_areas: Array = []

## Clothing item IDs that have been unlocked by story events and are available
## to find or equip. Populated by StorySystem when processing StoryEventDef.unlocks_clothing.
## In MVP: items from story_event_1 appear here after the first evolution.
var unlocked_clothing: Array = []

# ── Mutation helpers (called only by StorySystem) ─────────────────────────────

func mark_seen(event_id: String) -> void:
	if event_id not in seen_events:
		seen_events.append(event_id)

func unlock_area(area_id: String) -> void:
	if area_id not in unlocked_areas:
		unlocked_areas.append(area_id)

func unlock_clothing_item(clothing_id: String) -> void:
	if clothing_id not in unlocked_clothing:
		unlocked_clothing.append(clothing_id)

# ── Query helpers ─────────────────────────────────────────────────────────────

func has_seen(event_id: String) -> bool:
	return event_id in seen_events

func is_area_unlocked(area_id: String) -> bool:
	# The starting area requires no unlock entry.
	return area_id == "whispering_grove" or area_id in unlocked_areas

func is_clothing_unlocked(clothing_id: String) -> bool:
	return clothing_id in unlocked_clothing

# ── Serialisation ─────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"seen_events":       seen_events.duplicate(),
		"unlocked_areas":    unlocked_areas.duplicate(),
		"unlocked_clothing": unlocked_clothing.duplicate(),
	}

static func from_dict(data: Dictionary) -> StoryState:
	var s := StoryState.new()
	s.seen_events       = data.get("seen_events", []).duplicate()
	s.unlocked_areas    = data.get("unlocked_areas", []).duplicate()
	s.unlocked_clothing = data.get("unlocked_clothing", []).duplicate()
	return s
