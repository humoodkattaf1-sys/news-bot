extends Node2D

func _ready() -> void:
	# Show "Continue" only when a save file exists.
	if has_node("UI/ContinueButton"):
		$UI/ContinueButton.visible = SaveSystem.exists()

func _on_new_game_pressed() -> void:
	SaveSystem.clear()
	SceneManager.go_to("character_select")

func _on_continue_pressed() -> void:
	if SaveSystem.load_save():
		SceneManager.go_to("explore")
