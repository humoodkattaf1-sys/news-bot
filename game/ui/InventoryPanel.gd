extends CanvasLayer

signal item_fed(item_id: String)

var _visible_state: bool = false

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		_toggle()

func _toggle() -> void:
	_visible_state = not _visible_state
	visible        = _visible_state
	if _visible_state:
		_populate()

func _populate() -> void:
	if not has_node("ItemList"):
		return
	var list := $ItemList
	list.clear()
	var items := InventorySystem.get_display_list(GameState.player)
	for entry: Dictionary in items:
		var label := "%s  x%d" % [entry["display_name"], entry["count"]]
		if entry["is_food"]:
			label += "  (+%d EXP)" % entry["exp_value"]
		list.add_item(label)
		list.set_item_metadata(list.item_count - 1, entry["id"])

func _on_item_list_item_activated(index: int) -> void:
	if not has_node("ItemList"):
		return
	var item_id: String = $ItemList.get_item_metadata(index)
	var food_def := DataLoader.get_food(item_id)
	if food_def.is_empty():
		return
	var levelled_up := ExpSystem.apply_exp(GameState.creature, food_def["exp_value"])
	InventorySystem.remove(GameState.player, item_id)
	emit_signal("item_fed", item_id)
	if levelled_up and get_tree().get_nodes_in_group("hud").size() > 0:
		get_tree().get_nodes_in_group("hud")[0].show_hint(
			"Level up!  Lv. %d" % GameState.creature.level
		)
	_populate()
	if has_node("../HUD"):
		get_node("../HUD").refresh()
