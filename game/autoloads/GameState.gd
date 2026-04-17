extends Node

## Runtime player data — inventory, gender, name, clothing, age.
var player: PlayerData     = PlayerData.new()

## Runtime creature data — id, level, exp, evolved flag, accessory bonuses.
var creature: CreatureData = CreatureData.new()

## Story progression — seen events, unlocked areas, unlocked clothing.
var story: StoryState      = StoryState.new()

## Exploration-specific state — not story-related, resets with the map.
##   current_area    — area ID currently loaded in ExploreScene.
##   collected_nodes — node names already picked up this sweep (removed from scene).
##   respawn_used    — true once the one-time node respawn has fired.
var world: Dictionary = _default_world()

func _default_world() -> Dictionary:
	return {
		"current_area":    "whispering_grove",
		"collected_nodes": [],
		"respawn_used":    false,
	}

func reset() -> void:
	player   = PlayerData.new()
	creature = CreatureData.new()
	story    = StoryState.new()
	world    = _default_world()

func to_dict() -> Dictionary:
	return {
		"version":  1,
		"player":   player.to_dict(),
		"creature": creature.to_dict(),
		"story":    story.to_dict(),
		"world":    world.duplicate(true),
	}

func from_dict(data: Dictionary) -> void:
	player   = PlayerData.from_dict(data.get("player", {}))
	creature = CreatureData.from_dict(data.get("creature", {}))
	story    = StoryState.from_dict(data.get("story", {}))
	world    = data.get("world", _default_world()).duplicate(true)
