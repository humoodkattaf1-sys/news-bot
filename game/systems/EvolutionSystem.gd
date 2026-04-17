class_name EvolutionSystem

static func can_evolve(creature: CreatureData, player: PlayerData) -> bool:
	var def := DataLoader.get_creature(creature.creature_id)
	if def.is_empty():
		return false
	var req_level: int    = def.get("evolution_level", 999)
	var req_item: String  = def.get("evolution_item_id", "")
	return creature.level >= req_level and player.has_item(req_item)

# Mutates creature and player in place. Call only after can_evolve() == true.
static func do_evolve(creature: CreatureData, player: PlayerData) -> void:
	var def         := DataLoader.get_creature(creature.creature_id)
	var evolved_id  := def.get("evolved_form_id", "") as String
	var item_id     := def.get("evolution_item_id", "") as String
	if evolved_id.is_empty():
		push_error("EvolutionSystem: no evolved_form_id for '%s'" % creature.creature_id)
		return
	player.remove_item(item_id)
	creature.creature_id = evolved_id
	creature.stage       = 2
	creature.evolved     = true

# Convenience: returns base_stats of the creature's current definition.
static func current_stats(creature: CreatureData) -> Dictionary:
	return DataLoader.get_creature(creature.creature_id).get("base_stats", {})
