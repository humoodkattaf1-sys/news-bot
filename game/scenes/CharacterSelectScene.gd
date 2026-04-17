extends Node2D

var _gender: String = "boy"

func _ready() -> void:
	pass

func _on_boy_pressed() -> void:
	_gender = "boy"

func _on_girl_pressed() -> void:
	_gender = "girl"

func _on_confirm_pressed() -> void:
	var name_input: String = ""
	if has_node("UI/NameInput"):
		name_input = $UI/NameInput.text.strip_edges()
	if name_input.is_empty():
		name_input = "Traveller"
	GameState.player.player_name = name_input
	GameState.player.gender      = _gender
	SceneManager.go_to("creature_select")
