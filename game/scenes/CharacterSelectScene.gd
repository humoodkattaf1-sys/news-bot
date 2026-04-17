extends Control

var _gender: String = "boy"

func _on_boy_pressed() -> void:
	_gender = "boy"
	$Center/VBox/GenderRow/BoyBtn.button_pressed  = true
	$Center/VBox/GenderRow/GirlBtn.button_pressed = false

func _on_girl_pressed() -> void:
	_gender = "girl"
	$Center/VBox/GenderRow/GirlBtn.button_pressed = true
	$Center/VBox/GenderRow/BoyBtn.button_pressed  = false

func _on_confirm_pressed() -> void:
	var raw: String = $Center/VBox/NameInput.text.strip_edges()
	GameState.player.player_name = raw if not raw.is_empty() else "Traveller"
	GameState.player.gender      = _gender
	SceneManager.go_to("creature_select")
