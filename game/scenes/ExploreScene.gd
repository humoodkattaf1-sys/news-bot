extends Node2D

const PlayerScene    := preload("res://entities/Player.tscn")
const CompanionScene := preload("res://entities/CreatureCompanion.tscn")
const FoodScene      := preload("res://entities/FoodPickup.tscn")
const StoneScene     := preload("res://entities/EvolutionStone.tscn")

# ── Map geometry ──────────────────────────────────────────────────────────────

const WALL_COLOR := Color(0.20, 0.14, 0.08, 1.0)

const WALLS: Array = [
	Rect2(   0,   0, 1280,  64),
	Rect2(   0, 656, 1280,  64),
	Rect2(   0,   0,   64, 720),
	Rect2(1216,   0,   64, 720),
	Rect2( 320, 192,   64, 192),
	Rect2( 768, 320,   64, 192),
	Rect2( 512, 448,  192,  64),
	Rect2( 960, 128,   64, 256),
]

const FOOD_NODES: Array = [
	["berrysprig",   Vector2( 180, 160), "food_0"],
	["berrysprig",   Vector2( 600, 200), "food_1"],
	["berrysprig",   Vector2( 900, 480), "food_2"],
	["berrysprig",   Vector2( 200, 560), "food_3"],
	["sunmoss",      Vector2( 440, 300), "food_4"],
	["sunmoss",      Vector2(1100, 200), "food_5"],
	["dewdrop_vial", Vector2( 640, 520), "food_6"],
]

const STONE_POS       := Vector2(1100, 400)
const SHARD_POS       := Vector2( 820, 560)
const SHARD_NODE_NAME := "moonstone_shard_pickup"  # scene-tree name; item_id is "moonstone_shard"
const PLAYER_START    := Vector2( 180, 360)

# Shared label mapping for stat bonus display — used by _fmt_bonus() and _refresh_bonus_label().
const BONUS_TAGS: Dictionary = {
	"speed":          "SPD",
	"resilience":     "RES",
	"forage":         "FOR",
	"carry_capacity": "BAG",
	"xp_boost":       "XP",
	"luck":           "LCK",
}

# ── State ─────────────────────────────────────────────────────────────────────

var _player:               CharacterBody2D = null
var _hint_timer:           SceneTreeTimer  = null
var _milestone_popup_open: bool            = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_walls()
	_place_food()
	_place_stone()
	_place_shard()
	_spawn_player()
	_spawn_companion()
	_restore_collected()
	_setup_ui()
	EquipSystem.recalc_bonuses()  # restore stat bonuses from save data on every load
	_check_milestone()

# ── Map building ──────────────────────────────────────────────────────────────

func _build_walls() -> void:
	for rect: Rect2 in WALLS:
		var body  := StaticBody2D.new()
		body.position = rect.get_center()

		var shape := CollisionShape2D.new()
		var rs    := RectangleShape2D.new()
		rs.size   = rect.size
		shape.shape = rs
		body.add_child(shape)

		var poly    := Polygon2D.new()
		var hw: float = rect.size.x * 0.5
		var hh: float = rect.size.y * 0.5
		poly.polygon = PackedVector2Array([
			Vector2(-hw, -hh), Vector2(hw, -hh),
			Vector2( hw,  hh), Vector2(-hw,  hh),
		])
		poly.color = WALL_COLOR
		body.add_child(poly)

		$Objects.add_child(body)

func _place_food() -> void:
	for entry: Array in FOOD_NODES:
		var pickup      := FoodScene.instantiate()
		pickup.food_id  = entry[0]
		pickup.name     = entry[2]
		pickup.position = entry[1]
		pickup.collected.connect(on_node_collected)
		$Objects.add_child(pickup)

func _place_stone() -> void:
	var stone      := StoneScene.instantiate()
	stone.position = STONE_POS
	stone.stone_entered.connect(on_evolution_stone_entered)
	$Objects.add_child(stone)

func _place_shard() -> void:
	if SHARD_NODE_NAME in GameState.world.get("collected_nodes", []):
		return
	var pickup      := FoodScene.instantiate()
	pickup.food_id  = "moonstone_shard"
	pickup.name     = SHARD_NODE_NAME
	pickup.position = SHARD_POS
	pickup.collected.connect(on_node_collected)
	$Objects.add_child(pickup)

func _spawn_player() -> void:
	_player          = PlayerScene.instantiate()
	_player.position = PLAYER_START
	add_child(_player)

func _spawn_companion() -> void:
	var comp    := CompanionScene.instantiate()
	comp.target = _player
	add_child(comp)

func _restore_collected() -> void:
	var collected: Array = GameState.world.get("collected_nodes", [])

	# One-time respawn: when all food nodes have been picked up, clear the list so
	# they reappear. The respawn_used flag prevents this happening a second time.
	if collected.size() >= FOOD_NODES.size() \
			and not GameState.world.get("respawn_used", false):
		GameState.world["collected_nodes"] = []
		GameState.world["respawn_used"]    = true
		return

	for node_name: String in collected:
		var node := $Objects.find_child(node_name, false, false)
		if node:
			node.queue_free()

# ── UI initialisation ─────────────────────────────────────────────────────────

func _setup_ui() -> void:
	$UI/InventoryPanel.visible = false
	$UI/InventoryPanel/VBox/InvList.item_activated.connect(_on_inv_item_activated)
	$UI/EquipPanel.visible = false
	$UI/EquipPanel/VBox/HBox/OutfitBox/OutfitList.item_activated.connect(_on_outfit_activated)
	$UI/EquipPanel/VBox/HBox/AccessoryBox/AccessoryList.item_activated.connect(_on_accessory_activated)
	$UI/MilestonePopup.visible = false
	_refresh_hud()
	_update_objective_label()

func _refresh_hud() -> void:
	var c   := GameState.creature
	var def := DataLoader.get_creature(c.creature_id)

	$UI/CreatureLabel.text = "%s   Lv. %d" % [def.get("display_name", "?"), c.level]
	$UI/ExpBar.value       = ExpSystem.progress_ratio(c) * 100.0
	_refresh_items_label()
	_refresh_resource_strip()

func _refresh_items_label() -> void:
	var total := 0
	for v: int in GameState.player.inventory.values():
		total += v
	$UI/ItemsLabel.text = "[ I ]  Items: %d / %d" % [total, GrowthSystem.carry_capacity()]

func _refresh_resource_strip() -> void:
	var parts: Array = []
	for entry: Dictionary in InventorySystem.get_display_list(GameState.player):
		if entry["is_food"]:
			parts.append("%s \u00d7%d" % [entry["display_name"], entry["count"]])
	$UI/ResourceStrip.text = "  ".join(parts)

# ── Bag panel (I) ─────────────────────────────────────────────────────────────

func _toggle_inventory() -> void:
	$UI/EquipPanel.visible = false
	var panel := $UI/InventoryPanel
	panel.visible = not panel.visible
	if panel.visible:
		_populate_creature_info()
		_populate_inv_list()

func _populate_creature_info() -> void:
	var c   := GameState.creature
	var def := DataLoader.get_creature(c.creature_id)
	var box := $UI/InventoryPanel/VBox/CreatureInfoBox

	box.get_node("CreaturePanelName").text = def.get("display_name", "?")

	var exp_need: int = ExpSystem.exp_to_next(c.level)
	box.get_node("CreaturePanelLevel").text = \
		"Lv. %d   \u00b7   EXP  %d / %d" % [c.level, c.exp, exp_need]

	box.get_node("CreaturePanelExpBar").value = ExpSystem.progress_ratio(c) * 100.0

	var evo_text: String
	var evo_form: String = def.get("evolved_form_id", "")
	if c.evolved or evo_form.is_empty():
		evo_text = "Fully evolved"
	else:
		var req_level: int   = def.get("evolution_level", 999)
		var req_item: String = def.get("evolution_item_id", "")
		var item_def         := DataLoader.get_evolution_item(req_item)
		var item_name: String = item_def.get("display_name", req_item)
		if c.level >= req_level and GameState.player.has_item(req_item):
			evo_text = "Ready to evolve!   Visit the stone."
		elif c.level >= req_level:
			evo_text = "Level reached \u2014 need %s" % item_name
		else:
			evo_text = "Evolves at Lv. %d   +   %s" % [req_level, item_name]

	box.get_node("EvoReqLabel").text = evo_text

func _populate_inv_list() -> void:
	var list := $UI/InventoryPanel/VBox/InvList
	list.clear()
	var items := InventorySystem.get_display_list(GameState.player)
	if items.is_empty():
		list.add_item("\u2014 bag is empty \u2014")
		return
	for entry: Dictionary in items:
		var row := "%s   \u00d7%d" % [entry["display_name"], entry["count"]]
		if entry["is_food"]:
			row += "      +%d EXP" % entry["exp_value"]
		list.add_item(row)
		list.set_item_metadata(list.item_count - 1, entry["id"])

func _on_inv_item_activated(index: int) -> void:
	var list    := $UI/InventoryPanel/VBox/InvList
	var item_id := str(list.get_item_metadata(index))
	if item_id.is_empty():
		return
	var food_def := DataLoader.get_food(item_id)
	if food_def.is_empty():
		return

	var base_exp    := food_def["exp_value"] as int
	var actual_exp  := ExpSystem.boosted_amount(base_exp)
	var levelled_up := ExpSystem.apply_exp(GameState.creature, base_exp)
	InventorySystem.remove(GameState.player, item_id)
	_populate_creature_info()
	_populate_inv_list()
	_refresh_hud()

	var msg := "Fed %s   (+%d EXP)" % [food_def.get("display_name", ""), actual_exp]
	if levelled_up:
		msg += "   \u2014   Level up!  Lv. %d" % GameState.creature.level
	show_hint(msg)
	_check_milestone()

# ── Equipment panel (Q) ───────────────────────────────────────────────────────

func _toggle_equipment() -> void:
	$UI/InventoryPanel.visible = false
	var panel := $UI/EquipPanel
	panel.visible = not panel.visible
	if panel.visible:
		_populate_equip_panel()

func _populate_equip_panel() -> void:
	_fill_slot(
		$UI/EquipPanel/VBox/HBox/OutfitBox/OutfitList,
		$UI/EquipPanel/VBox/HBox/OutfitBox/EquippedOutfit,
		false
	)
	var locked    := GrowthSystem.clothing_slots() < 2
	var acc_box   := $UI/EquipPanel/VBox/HBox/AccessoryBox
	acc_box.get_node("AccessoryList").visible = not locked
	acc_box.get_node("LockedLabel").visible   = locked
	if not locked:
		_fill_slot(
			acc_box.get_node("AccessoryList"),
			acc_box.get_node("EquippedAccessory"),
			true
		)
	_refresh_bonus_label()

func _fill_slot(list: ItemList, label: Label, want_accessory: bool) -> void:
	list.clear()
	var unlocked: Array = GameState.story.unlocked_clothing
	var available := DataLoader.get_all_clothing().filter(
		func(d: Dictionary) -> bool:
			return d.get("id", "") in unlocked \
				and d.get("is_creature_accessory", false) == want_accessory
	)

	var eq_id := EquipSystem.equipped_in_slot(want_accessory)
	if eq_id.is_empty():
		label.text = "Equipped: \u2014"
	else:
		var ed := DataLoader.get_clothing(eq_id)
		label.text = "Equipped: %s" % ed.get("display_name", eq_id)

	if available.is_empty():
		list.add_item("\u2014 nothing unlocked yet \u2014")
		return

	for d: Dictionary in available:
		var id  := d.get("id", "")
		var pfx := "[eq]  " if EquipSystem.is_equipped(id) else "         "
		var row := pfx + d.get("display_name", id) \
			+ "   " + _fmt_bonus(d.get("stat_bonus", {}))
		list.add_item(row)
		list.set_item_metadata(list.item_count - 1, id)

func _fmt_bonus(bonus: Dictionary) -> String:
	var parts: Array = []
	for key: String in bonus:
		var val := int(bonus[key])
		var tag := BONUS_TAGS.get(key, key.to_upper())
		var sfx := "%" if key == "xp_boost" else ""
		parts.append("%s +%d%s" % [tag, val, sfx])
	return "  ".join(parts)

func _refresh_bonus_label() -> void:
	var parts: Array = []
	for k: String in GameState.player.clothing_bonuses:
		var v := int(GameState.player.clothing_bonuses[k])
		if v <= 0:
			continue
		var tag := BONUS_TAGS.get(k, k.to_upper())
		var sfx := "%" if k == "xp_boost" else ""
		parts.append("%s +%d%s" % [tag, v, sfx])
	for k: String in GameState.creature.bonus_stats:
		var v := int(GameState.creature.bonus_stats[k])
		if v <= 0:
			continue
		var tag := BONUS_TAGS.get(k, k.to_upper())
		parts.append("C-%s +%d" % [tag, v])
	$UI/EquipPanel/VBox/BonusLabel.text = \
		"Active bonuses: " + ("  \u00b7  ".join(parts) if not parts.is_empty() else "\u2014")

func _toggle_equip_item(item_id: String) -> void:
	if item_id.is_empty():
		return
	var def := DataLoader.get_clothing(item_id)
	if def.is_empty():
		return
	if EquipSystem.is_equipped(item_id):
		EquipSystem.unequip(item_id)
		show_hint("Removed %s" % def.get("display_name", ""))
	else:
		if EquipSystem.equip(item_id):
			show_hint("Equipped %s" % def.get("display_name", ""))
		else:
			show_hint("Slot not available yet")
	_populate_equip_panel()
	_refresh_hud()

func _on_outfit_activated(index: int) -> void:
	var list := $UI/EquipPanel/VBox/HBox/OutfitBox/OutfitList
	_toggle_equip_item(str(list.get_item_metadata(index)))

func _on_accessory_activated(index: int) -> void:
	var list := $UI/EquipPanel/VBox/HBox/AccessoryBox/AccessoryList
	_toggle_equip_item(str(list.get_item_metadata(index)))

# ── Signals from world nodes ──────────────────────────────────────────────────

func on_node_collected(item_id: String, node_name: String) -> void:
	InventorySystem.add(GameState.player, item_id)
	GameState.world["collected_nodes"].append(node_name)

	var food_def := DataLoader.get_food(item_id)
	if not food_def.is_empty():
		var total: int = GameState.world.get("food_gathered_total", 0) + 1
		GameState.world["food_gathered_total"] = total
		show_hint("Found  " + food_def.get("display_name", item_id))
	else:
		var evo_def := DataLoader.get_evolution_item(item_id)
		show_hint("Found  " + evo_def.get("display_name", item_id))

	_refresh_hud()
	_check_milestone()

func on_evolution_stone_entered() -> void:
	var c   := GameState.creature
	var def := DataLoader.get_creature(c.creature_id)

	if c.evolved or not def.get("evolved_form_id"):
		show_hint("%s is fully evolved." % def.get("display_name", "?"))
		return

	if EvolutionSystem.can_evolve(c, GameState.player):
		SceneManager.go_to("evolution")
		return

	var req_level : int    = def.get("evolution_level", 10)
	var req_item  : String = def.get("evolution_item_id", "")
	var item_def          := DataLoader.get_evolution_item(req_item)
	var item_name : String = item_def.get("display_name", req_item)
	var has_level : bool   = c.level >= req_level
	var has_item  : bool   = GameState.player.has_item(req_item)

	if not has_level and not has_item:
		show_hint("Need Lv. %d and %s to evolve" % [req_level, item_name])
	elif not has_level:
		show_hint("Reach Lv. %d to evolve   ( now Lv. %d )" % [req_level, c.level])
	else:
		show_hint("Need %s to evolve" % item_name)

# ── Milestone system ─────────────────────────────────────────────────────────

func _check_milestone() -> void:
	var completed := MilestoneSystem.check_and_advance()
	if not completed.is_empty():
		_show_milestone_popup(completed)
	_update_objective_label()

func _update_objective_label() -> void:
	if MilestoneSystem.is_complete():
		$UI/ObjectiveLabel.text = ""
		return
	$UI/ObjectiveLabel.text = \
		"  \u25b6  " + MilestoneSystem.objective_text() + MilestoneSystem.progress_text()

func _show_milestone_popup(m: Dictionary) -> void:
	_milestone_popup_open = true
	$UI/MilestonePopup/VBox/PopupTitle.text = m.get("completion_title", "Milestone")
	$UI/MilestonePopup/VBox/PopupBody.text  = m.get("completion_body", "")
	$UI/MilestonePopup.visible = true

# ── Hint banner ───────────────────────────────────────────────────────────────

func show_hint(text: String, duration: float = 2.8) -> void:
	$UI/HintLabel.text    = text
	$UI/HintLabel.visible = true
	_hint_timer = get_tree().create_timer(duration)
	_hint_timer.timeout.connect(
		func() -> void: $UI/HintLabel.visible = false,
		CONNECT_ONE_SHOT
	)

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _milestone_popup_open and event.is_action_pressed("confirm"):
		$UI/MilestonePopup.visible = false
		_milestone_popup_open = false
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("open_inventory"):
		_toggle_inventory()
	elif event.is_action_pressed("open_equipment"):
		_toggle_equipment()
