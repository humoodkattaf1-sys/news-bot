class_name EquipSystem

## Equip an item by id. Automatically displaces any conflicting item in the same
## slot. Returns false if the required clothing slot isn't unlocked yet.
static func equip(item_id: String) -> bool:
	var def := DataLoader.get_clothing(item_id)
	if def.is_empty():
		return false
	var is_acc: bool = def.get("is_creature_accessory", false)
	if is_acc and GrowthSystem.clothing_slots() < 2:
		return false
	var existing := equipped_in_slot(is_acc)
	if not existing.is_empty():
		GameState.player.equipped_clothing.erase(existing)
	GameState.player.equipped_clothing.append(item_id)
	recalc_bonuses()
	return true

static func unequip(item_id: String) -> void:
	GameState.player.equipped_clothing.erase(item_id)
	recalc_bonuses()

static func is_equipped(item_id: String) -> bool:
	return item_id in GameState.player.equipped_clothing

## Returns the item_id in the given slot, or "" if the slot is empty.
static func equipped_in_slot(is_accessory: bool) -> String:
	for id: String in GameState.player.equipped_clothing:
		var def := DataLoader.get_clothing(id)
		if def.get("is_creature_accessory", false) == is_accessory:
			return id
	return ""

## Recomputes PlayerData.clothing_bonuses and CreatureData.bonus_stats from the
## full equipped_clothing list. Call after every equip / unequip and on scene load.
static func recalc_bonuses() -> void:
	GameState.player.clothing_bonuses.clear()
	GameState.creature.bonus_stats.clear()
	for id: String in GameState.player.equipped_clothing:
		var def := DataLoader.get_clothing(id)
		if def.is_empty():
			continue
		var bonus: Dictionary = def.get("stat_bonus", {})
		var target: Dictionary = GameState.creature.bonus_stats \
			if def.get("is_creature_accessory", false) \
			else GameState.player.clothing_bonuses
		for key: String in bonus:
			target[key] = target.get(key, 0) + int(bonus[key])
