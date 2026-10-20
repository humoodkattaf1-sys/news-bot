extends Control

func _ready() -> void:
	$Center/VBox/ContinueBtn.visible = SaveSystem.exists()

func _on_new_game_pressed() -> void:
	SaveSystem.clear()
	SceneManager.go_to("character_select")

func _on_continue_pressed() -> void:
	if SaveSystem.load_save():
		SceneManager.go_to("explore")
