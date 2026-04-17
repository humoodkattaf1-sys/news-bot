extends Node

var player: PlayerData   = PlayerData.new()
var creature: CreatureData = CreatureData.new()
var world: Dictionary    = _default_world()

func _default_world() -> Dictionary:
	return {
		"current_area":      "whispering_grove",
		"collected_nodes":   [],
		"respawn_used":      false,
		"story_events_seen": []
	}

func reset() -> void:
	player   = PlayerData.new()
	creature = CreatureData.new()
	world    = _default_world()

func to_dict() -> Dictionary:
	return {
		"version":  1,
		"player":   player.to_dict(),
		"creature": creature.to_dict(),
		"world":    world.duplicate(true)
	}

func from_dict(data: Dictionary) -> void:
	player   = PlayerData.from_dict(data.get("player", {}))
	creature = CreatureData.from_dict(data.get("creature", {}))
	world    = data.get("world", _default_world()).duplicate(true)
