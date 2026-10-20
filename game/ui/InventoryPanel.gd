extends CanvasLayer

## Emitted when the player feeds an item to their creature.
## hint_text is pre-formatted for display (e.g. "Fed Berrysprig (+30 EXP) — Level up! Lv. 5").
signal item_fed(hint_text: String)

@onready var _info_box: VBoxContainer = $PanelBG/VBox/CreatureInfoBox
@onready var _item_list: ItemList     = $PanelBG/VBox/ItemList

func _ready() -> void:
	visible = false
	_item_list.item_activated.connect(_on_item_activated)

# ── Public API ────────────────────────────────────────────────────────────────

func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()

func close() -> void:
	visible = false

# ── Populate ──────────────────────────────────────────────────────────────────

func _refresh() -> void:
	_refresh_creature_info()
	_refresh_item_list()

func _refresh_creature_info() -> void:
	var c   := GameState.creature
	var def := DataLoader.get_creature(c.creature_id)

	_info_box.get_node("CreatureName").text  = def.get("display_name", "?")
	_info_box.get_node("CreatureLevel").text = \
		"Lv. %d   \u00b7   EXP  %d / %d" % [c.level, c.exp, ExpSystem.exp_to_next(c.level)]
	_info_box.get_node("ExpBar").value       = ExpSystem.progress_ratio(c) * 100.0
	_info_box.get_node("EvoReq").text        = _evo_req_text(c, def)

func _refresh_item_list() -> void:
	_item_list.clear()
	var items := InventorySystem.get_display_list(GameState.player)
	if items.is_empty():
		_item_list.add_item("\u2014 bag is empty \u2014")
		return
	for entry: Dictionary in items:
		var row := "%s   \u00d7%d" % [entry["display_name"], entry["count"]]
		if entry["is_food"]:
			row += "      +%d EXP" % entry["exp_value"]
		_item_list.add_item(row)
		_item_list.set_item_metadata(_item_list.item_count - 1, entry["id"])

# ── Feeding ───────────────────────────────────────────────────────────────────

func _on_item_activated(index: int) -> void:
	var item_id  := str(_item_list.get_item_metadata(index))
	var food_def := DataLoader.get_food(item_id)
	if food_def.is_empty():
		return

	var base_exp    := food_def["exp_value"] as int
	var boosted_exp := ExpSystem.boosted_amount(base_exp)
	var levelled_up := ExpSystem.apply_exp(GameState.creature, base_exp)
	InventorySystem.remove(GameState.player, item_id)

	var msg := "Fed %s   (+%d EXP)" % [food_def.get("display_name", ""), boosted_exp]
	if levelled_up:
		msg += "   \u2014   Level up!  Lv. %d" % GameState.creature.level

	_refresh()
	item_fed.emit(msg)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _evo_req_text(c: CreatureData, def: Dictionary) -> String:
	if c.evolved or not def.get("evolved_form_id"):
		return "Fully evolved"
	var req_level: int    = def.get("evolution_level", 999)
	var req_item: String  = def.get("evolution_item_id", "")
	var item_name: String = DataLoader.get_evolution_item(req_item).get("display_name", req_item)
	if c.level >= req_level and GameState.player.has_item(req_item):
		return "Ready to evolve!   Visit the stone."
	if c.level >= req_level:
		return "Level reached \u2014 need %s" % item_name
	return "Evolves at Lv. %d   +   %s" % [req_level, item_name]
