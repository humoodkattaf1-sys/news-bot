## Typed schema for one entry in data/story_events.json.
## A StoryEvent is a one-shot cutscene triggered by world conditions.
## Once seen it is recorded in StoryState and never replays.
class_name StoryEventDef
extends RefCounted

## Primary key. Referenced by area triggers, StorySystem, and unlock conditions.
var id: String = ""

## All keys in this dict must evaluate to true for the event to fire.
## Evaluated by StorySystem.should_trigger(). Supported keys (MVP):
##   "creature_evolved": bool  — true after EvolutionSystem.do_evolve() runs.
## Future keys (add to StorySystem.should_trigger as needed):
##   "level_reached":   int   — creature.level >= value
##   "area_visits":     int   — times the player has entered a given area
##   "item_held":       String — item_id present in inventory
var trigger_condition: Dictionary = {}

## Dialogue lines shown one at a time in StoryScene.
## Each string is a single screen of text. Press confirm to advance.
## Supports RichTextLabel BBCode for future emphasis (e.g. [b]bold[/b]).
var dialogue: Array = []

## Item ID added to PlayerData.inventory when the event fires.
## null / empty string = no item granted.
var grants_item: String = ""

## Area ID added to StoryState.unlocked_areas when the event fires.
## null / empty = no area unlock.
var unlocks_area: String = ""

## Clothing item IDs added to StoryState.unlocked_clothing when the event fires.
## These items become available to find or equip after this event.
## Empty array = no clothing unlocked.
var unlocks_clothing: Array = []

## If true, PlayerData.age_stage increments by 1 after the event plays.
## Triggers visual changes and may gate future dialogue (post-MVP).
var advances_player_age: bool = false

# ── Factory ───────────────────────────────────────────────────────────────────

static func from_dict(d: Dictionary) -> StoryEventDef:
	var s := StoryEventDef.new()
	s.id                  = d.get("id", "")
	s.trigger_condition   = d.get("trigger_condition", {}).duplicate()
	s.dialogue            = d.get("dialogue", []).duplicate()
	s.grants_item         = d.get("grants_item", "") if d.get("grants_item") != null else ""
	s.unlocks_area        = d.get("unlocks_area", "") if d.get("unlocks_area") != null else ""
	s.unlocks_clothing    = d.get("unlocks_clothing", []).duplicate()
	s.advances_player_age = d.get("advances_player_age", false)
	return s

# ── Helpers ───────────────────────────────────────────────────────────────────

## True when this event has side-effects beyond displaying dialogue.
func has_rewards() -> bool:
	return not grants_item.is_empty() \
		or not unlocks_area.is_empty() \
		or not unlocks_clothing.is_empty() \
		or advances_player_age
