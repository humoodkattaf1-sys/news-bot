extends Node

const SCENES: Dictionary = {
	"title":            "res://scenes/TitleScene.tscn",
	"character_select": "res://scenes/CharacterSelectScene.tscn",
	"creature_select":  "res://scenes/CreatureSelectScene.tscn",
	"explore":          "res://scenes/ExploreScene.tscn",
	"evolution":        "res://scenes/EvolutionScene.tscn",
	"story":            "res://scenes/StoryScene.tscn",
	"end_screen":       "res://scenes/EndScreen.tscn",
}

# Navigate by key. Triggers auto-save before transition.
func go_to(scene_key: String) -> void:
	assert(scene_key in SCENES, "SceneManager: unknown key '%s'" % scene_key)
	SaveSystem.save()
	get_tree().change_scene_to_file(SCENES[scene_key])

# Navigate by full res:// path (used for dynamic loads).
func go_to_path(path: String) -> void:
	SaveSystem.save()
	get_tree().change_scene_to_file(path)
