extends CanvasLayer

var _hint_timer: SceneTreeTimer = null

func _ready() -> void:
	add_to_group("hud")
	refresh()

func refresh() -> void:
	var creature := GameState.creature
	var def      := DataLoader.get_creature(creature.creature_id)

	if has_node("CreatureName"):
		$CreatureName.text = def.get("display_name", "")
	if has_node("LevelLabel"):
		$LevelLabel.text = "Lv. %d" % creature.level
	if has_node("ExpBar"):
		$ExpBar.value = ExpSystem.progress_ratio(creature) * 100.0
	if has_node("ItemCount"):
		var total: int = 0
		for v: int in GameState.player.inventory.values():
			total += v
		$ItemCount.text = "[I] Items: %d" % total

func show_hint(text: String, duration: float = 2.5) -> void:
	if has_node("HintLabel"):
		$HintLabel.text    = text
		$HintLabel.visible = true
	if _hint_timer:
		_hint_timer.timeout.disconnect(_clear_hint)
	_hint_timer = get_tree().create_timer(duration)
	_hint_timer.timeout.connect(_clear_hint)

func _clear_hint() -> void:
	if has_node("HintLabel"):
		$HintLabel.visible = false
