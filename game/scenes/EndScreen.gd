extends Node2D

func _ready() -> void:
	if has_node("UI/PlayerName"):
		$UI/PlayerName.text = GameState.player.player_name
	if has_node("UI/CreatureName"):
		var def := DataLoader.get_creature(GameState.creature.creature_id)
		$UI/CreatureName.text = def.get("display_name", "")

func _on_title_pressed() -> void:
	SceneManager.go_to("title")
