extends Node2D

const EVENT_ID := "story_event_1"

var _lines:        Array  = []
var _current_line: int    = 0

func _ready() -> void:
	var event := StorySystem.get_event(EVENT_ID)
	_lines = event.get("dialogue", [])
	StorySystem.mark_seen(EVENT_ID)
	_show_line()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		_advance()

func _advance() -> void:
	_current_line += 1
	if _current_line >= _lines.size():
		SceneManager.go_to("end_screen")
	else:
		_show_line()

func _show_line() -> void:
	if has_node("UI/DialogueLabel"):
		$UI/DialogueLabel.text = _lines[_current_line]
