extends CanvasLayer

var _hint_timer: SceneTreeTimer = null

func _ready() -> void:
	add_to_group("hud")
	refresh()

# ── Public API ────────────────────────────────────────────────────────────────

func refresh() -> void:
	var c   := GameState.creature
	var def := DataLoader.get_creature(c.creature_id)

	$CreatureLabel.text = "%s   Lv. %d" % [def.get("display_name", "?"), c.level]
	$ExpBar.value       = ExpSystem.progress_ratio(c) * 100.0

	$ItemsLabel.text = "[ I ]  Items: %d / %d" % [InventorySystem.total_count(GameState.player), GrowthSystem.carry_capacity()]

	var food_parts: Array = []
	for entry: Dictionary in InventorySystem.get_display_list(GameState.player):
		if entry["is_food"]:
			food_parts.append("%s \u00d7%d" % [entry["display_name"], entry["count"]])
	$ResourceStrip.text = "  ".join(food_parts)

func refresh_objective(text: String) -> void:
	$ObjectiveLabel.text = text

func show_hint(text: String, duration: float = 2.8) -> void:
	$HintLabel.text    = text
	$HintLabel.visible = true
	if _hint_timer:
		_hint_timer.timeout.disconnect(_clear_hint)
	_hint_timer = get_tree().create_timer(duration)
	_hint_timer.timeout.connect(_clear_hint)

# ── Internal ──────────────────────────────────────────────────────────────────

func _clear_hint() -> void:
	$HintLabel.visible = false
