extends Node2D

var _starters: Array     = []
var _selected_index: int = 0

func _ready() -> void:
	_starters = DataLoader.get_starter_creatures()
	_refresh_display()

func _on_prev_pressed() -> void:
	_selected_index = wrapi(_selected_index - 1, 0, _starters.size())
	_refresh_display()

func _on_next_pressed() -> void:
	_selected_index = wrapi(_selected_index + 1, 0, _starters.size())
	_refresh_display()

func _on_confirm_pressed() -> void:
	if _starters.is_empty():
		return
	var chosen: Dictionary = _starters[_selected_index]
	GameState.creature.creature_id = chosen["id"]
	GameState.creature.stage       = 1
	GameState.creature.level       = 1
	GameState.creature.exp         = 0
	GameState.creature.evolved     = false
	SceneManager.go_to("explore")

func _refresh_display() -> void:
	if _starters.is_empty():
		return
	var def: Dictionary = _starters[_selected_index]
	# Concrete node paths wired in the .tscn.
	if has_node("UI/CreatureName"):
		$UI/CreatureName.text = def.get("display_name", "")
	if has_node("UI/Description"):
		$UI/Description.text = def.get("description", "")
	if has_node("UI/Stats"):
		var stats: Dictionary = def.get("base_stats", {})
		$UI/Stats.text = "SPD %d  RES %d  FOR %d" % [
			stats.get("speed", 0),
			stats.get("resilience", 0),
			stats.get("forage", 0)
		]
