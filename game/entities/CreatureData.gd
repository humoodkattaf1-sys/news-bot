class_name CreatureData
extends RefCounted

var creature_id: String = ""
var stage: int = 1
var level: int = 1
var exp: int = 0
var evolved: bool = false

func to_dict() -> Dictionary:
	return {
		"id":      creature_id,
		"stage":   stage,
		"level":   level,
		"exp":     exp,
		"evolved": evolved
	}

static func from_dict(data: Dictionary) -> CreatureData:
	var c := CreatureData.new()
	c.creature_id = data.get("id", "")
	c.stage       = data.get("stage", 1)
	c.level       = data.get("level", 1)
	c.exp         = data.get("exp", 0)
	c.evolved     = data.get("evolved", false)
	return c
