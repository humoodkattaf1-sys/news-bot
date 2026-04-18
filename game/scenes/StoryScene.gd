extends Node2D

const EVENT_ID := "story_event_1"

enum _Phase { DIALOGUE, GROWTH }

var _lines:        Array  = []
var _current_line: int    = 0
var _phase:        _Phase = _Phase.DIALOGUE
var _old_stage:    int    = 0
var _age_advanced: bool   = false

func _ready() -> void:
	var event  := StorySystem.get_event(EVENT_ID)
	_lines      = event.get("dialogue", [])
	_old_stage  = GameState.player.age_stage

	# Apply rewards and mark seen exactly once; guards against replayed loads.
	if not StorySystem.has_seen(EVENT_ID):
		StorySystem.apply_rewards(EVENT_ID)
		StorySystem.mark_seen(EVENT_ID)

	_age_advanced = GameState.player.age_stage > _old_stage
	_show_dialogue()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		_advance()

# ── Phase stepping ────────────────────────────────────────────────────────────

func _advance() -> void:
	match _phase:
		_Phase.DIALOGUE:
			_current_line += 1
			if _current_line >= _lines.size():
				if _age_advanced:
					_phase = _Phase.GROWTH
					_show_growth()
				else:
					SceneManager.go_to("end_screen")
			else:
				_show_dialogue()
		_Phase.GROWTH:
			SceneManager.go_to("end_screen")

# ── Display helpers ───────────────────────────────────────────────────────────

func _show_dialogue() -> void:
	$UI/DialoguePanel.visible = true
	$UI/GrowthPanel.visible   = false
	$UI/DialoguePanel/VBox/DialogueLabel.text = _lines[_current_line]

func _show_growth() -> void:
	$UI/DialoguePanel.visible = false
	$UI/GrowthPanel.visible   = true

	var old_def := DataLoader.get_growth_stage(_old_stage)
	var new_def := DataLoader.get_growth_stage(GameState.player.age_stage)

	$UI/GrowthPanel/VBox/GrowthLabel.text = "%s  \u2192  %s" % [
		old_def.get("display_name", "?"),
		new_def.get("display_name", "?"),
	]

	# Build a delta summary of what changed.
	var parts: Array = []
	var spd_delta  := int(new_def.get("speed", 0))         - int(old_def.get("speed", 0))
	var cap_delta  := int(new_def.get("carry_capacity", 0)) - int(old_def.get("carry_capacity", 0))
	var slot_delta := int(new_def.get("clothing_slots", 1)) - int(old_def.get("clothing_slots", 1))
	if spd_delta  > 0: parts.append("Move  +%d" % spd_delta)
	if cap_delta  > 0: parts.append("Bag  +%d" % cap_delta)
	if slot_delta > 0: parts.append("Clothing slot unlocked")
	$UI/GrowthPanel/VBox/GrowthStats.text = "   \u00b7   ".join(parts)
