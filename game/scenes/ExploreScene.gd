extends Node2D

func _ready() -> void:
	_restore_collected_nodes()
	_check_respawn()

func _restore_collected_nodes() -> void:
	var collected: Array = GameState.world.get("collected_nodes", [])
	for node_id: String in collected:
		var node := find_child(node_id, true, false)
		if node:
			node.queue_free()

func _check_respawn() -> void:
	# One-time respawn after the player clears all food nodes.
	if GameState.world.get("respawn_used", false):
		return
	if GameState.world.get("collected_nodes", []).size() == 0:
		return
	var food_nodes := get_tree().get_nodes_in_group("food_pickup")
	if food_nodes.is_empty():
		GameState.world["collected_nodes"] = []
		GameState.world["respawn_used"]    = true
		get_tree().reload_current_scene()

# Called by pickup Area2D nodes via signal.
func on_node_collected(item_id: String, node_name: String) -> void:
	InventorySystem.add(GameState.player, item_id)
	GameState.world["collected_nodes"].append(node_name)
	if has_node("HUD"):
		$HUD.refresh()

# Called by EvolutionStone Area2D on player contact.
func on_evolution_stone_entered() -> void:
	if EvolutionSystem.can_evolve(GameState.creature, GameState.player):
		SceneManager.go_to("evolution")
	else:
		if has_node("HUD"):
			$HUD.show_hint("Your companion is not ready yet.")
