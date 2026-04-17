class_name PlayerData
extends RefCounted

var player_name: String = ""
var gender: String = "boy"
var age_stage: int = 0
var inventory: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + amount

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false
	inventory[item_id] -= amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return inventory.get(item_id, 0) >= amount

func item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

func to_dict() -> Dictionary:
	return {
		"name": player_name,
		"gender": gender,
		"age_stage": age_stage,
		"inventory": inventory.duplicate()
	}

static func from_dict(data: Dictionary) -> PlayerData:
	var p := PlayerData.new()
	p.player_name = data.get("name", "")
	p.gender      = data.get("gender", "boy")
	p.age_stage   = data.get("age_stage", 0)
	p.inventory   = data.get("inventory", {}).duplicate()
	return p
