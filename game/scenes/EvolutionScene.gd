extends Node2D

func _ready() -> void:
	_show_before_state()
	await _play_evolution_animation()
	EvolutionSystem.do_evolve(GameState.creature, GameState.player)
	_show_after_state()

func _show_before_state() -> void:
	var def    := DataLoader.get_creature(GameState.creature.creature_id)
	var stats  := def.get("base_stats", {})
	if has_node("UI/CreatureName"):
		$UI/CreatureName.text = def.get("display_name", "")
	if has_node("UI/StatsBefore"):
		$UI/StatsBefore.text = _format_stats(stats)

func _show_after_state() -> void:
	var def   := DataLoader.get_creature(GameState.creature.creature_id)
	var stats := def.get("base_stats", {})
	if has_node("UI/EvolvedName"):
		$UI/EvolvedName.text = def.get("display_name", "")
	if has_node("UI/StatsAfter"):
		$UI/StatsAfter.text = _format_stats(stats)

func _play_evolution_animation() -> void:
	# Tween wired in the scene; expand with AnimationPlayer later.
	await get_tree().create_timer(1.5).timeout

func _on_confirm_pressed() -> void:
	SceneManager.go_to("story")

func _format_stats(stats: Dictionary) -> String:
	return "SPD %d  RES %d  FOR %d" % [
		stats.get("speed", 0),
		stats.get("resilience", 0),
		stats.get("forage", 0)
	]
