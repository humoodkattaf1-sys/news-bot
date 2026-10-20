class_name InventorySystem

static func add(player: PlayerData, item_id: String, amount: int = 1) -> void:
	player.add_item(item_id, amount)

static func remove(player: PlayerData, item_id: String, amount: int = 1) -> bool:
	return player.remove_item(item_id, amount)

static func has(player: PlayerData, item_id: String, amount: int = 1) -> bool:
	return player.has_item(item_id, amount)

static func count(player: PlayerData, item_id: String) -> int:
	return player.item_count(item_id)

static func total_count(player: PlayerData) -> int:
	var total: int = 0
	for v: int in player.inventory.values():
		total += v
	return total

# Returns a flat list ready for UI rendering.
# Each entry: { id, display_name, count, exp_value, is_food }
static func get_display_list(player: PlayerData) -> Array:
	var result: Array = []
	for item_id: String in player.inventory:
		var food_def := DataLoader.get_food(item_id)
		var evo_def  := DataLoader.get_evolution_item(item_id)
		var def      := food_def if not food_def.is_empty() else evo_def
		result.append({
			"id":           item_id,
			"display_name": def.get("display_name", item_id),
			"count":        player.inventory[item_id],
			"exp_value":    def.get("exp_value", 0),
			"is_food":      not food_def.is_empty()
		})
	return result
