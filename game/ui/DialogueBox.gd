extends CanvasLayer

signal dialogue_finished

var _lines:        Array = []
var _current_line: int   = 0

func start(lines: Array) -> void:
	_lines        = lines
	_current_line = 0
	visible       = true
	_show_line()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("confirm"):
		_advance()

func _advance() -> void:
	_current_line += 1
	if _current_line >= _lines.size():
		visible = false
		emit_signal("dialogue_finished")
	else:
		_show_line()

func _show_line() -> void:
	if has_node("Label"):
		$Label.text = _lines[_current_line]
	if has_node("ProgressHint"):
		var remaining := _lines.size() - _current_line - 1
		$ProgressHint.text = "[ SPACE / ENTER ]" if remaining > 0 else "[ Continue ]"
