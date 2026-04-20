extends Node

const SAVE_PATH := "user://save.json"

func save() -> void:
	if not _game_started():
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveSystem: failed to open save file for writing")
		return
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	file.close()

func load_save() -> bool:
	if not exists():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveSystem: failed to open save file for reading")
		return false
	var text   := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_error("SaveSystem: corrupt save file")
		return false
	GameState.from_dict(parsed)
	return true

func exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	GameState.reset()

# Guard: skip saving before the player has chosen a creature.
func _game_started() -> bool:
	return GameState.creature.creature_id != ""
