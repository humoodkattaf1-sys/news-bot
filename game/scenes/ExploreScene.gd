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

# ── UI setup ──────────────────────────────────────────────────────────────────

func _setup_ui() -> void:
	$InventoryPanel.item_fed.connect(_on_item_fed)
	$UI/EquipPanel.visible = false
	$UI/EquipPanel/VBox/HBox/OutfitBox/OutfitList.item_activated.connect(_on_outfit_activated)
	$UI/EquipPanel/VBox/HBox/AccessoryBox/AccessoryList.item_activated.connect(_on_accessory_activated)
	$UI/MilestonePopup.visible = false
	$HUD.refresh()
	_update_objective_label()

func _on_item_fed(hint_text: String) -> void:
	$HUD.show_hint(hint_text)
	$HUD.refresh()
	_check_milestone()

# ── Bag panel (I) ─────────────────────────────────────────────────────────────

func _toggle_inventory() -> void:
	$UI/EquipPanel.visible = false
	$InventoryPanel.toggle()

# ── Equipment panel (Q) ───────────────────────────────────────────────────────

func _toggle_equipment() -> void:
	$InventoryPanel.close()
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
	var locked  := GrowthSystem.clothing_slots() < 2
	var acc_box := $UI/EquipPanel/VBox/HBox/AccessoryBox
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
	label.text = "Equipped: %s" % (DataLoader.get_clothing(eq_id).get("display_name", eq_id) \
		if not eq_id.is_empty() else "\u2014")

	if available.is_empty():
		list.add_item("\u2014 nothing unlocked yet \u2014")
		return

	for d: Dictionary in available:
		var id  := d.get("id", "")
		var pfx := "[eq]  " if EquipSystem.is_equipped(id) else "         "
		list.add_item(pfx + d.get("display_name", id) + "   " + _fmt_bonus(d.get("stat_bonus", {})))
		list.set_item_metadata(list.item_count - 1, id)

func _fmt_bonus(bonus: Dictionary) -> String:
	var parts: Array = []
	for key: String in bonus:
		var tag := BONUS_TAGS.get(key, key.to_upper())
		var sfx := "%" if key == "xp_boost" else ""
		parts.append("%s +%d%s" % [tag, int(bonus[key]), sfx])
	return "  ".join(parts)

func _refresh_bonus_label() -> void:
	var parts: Array = []
	for k: String in GameState.player.clothing_bonuses:
		var v := int(GameState.player.clothing_bonuses[k])
		if v <= 0:
			continue
		var sfx := "%" if k == "xp_boost" else ""
		parts.append("%s +%d%s" % [BONUS_TAGS.get(k, k.to_upper()), v, sfx])
	for k: String in GameState.creature.bonus_stats:
		var v := int(GameState.creature.bonus_stats[k])
		if v <= 0:
			continue
		parts.append("C-%s +%d" % [BONUS_TAGS.get(k, k.to_upper()), v])
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
		$HUD.show_hint("Removed %s" % def.get("display_name", ""))
	else:
		if EquipSystem.equip(item_id):
			$HUD.show_hint("Equipped %s" % def.get("display_name", ""))
		else:
			$HUD.show_hint("Slot not available yet")
	_populate_equip_panel()
	$HUD.refresh()

func _on_outfit_activated(index: int) -> void:
	_toggle_equip_item(str($UI/EquipPanel/VBox/HBox/OutfitBox/OutfitList.get_item_metadata(index)))

func _on_accessory_activated(index: int) -> void:
	_toggle_equip_item(str($UI/EquipPanel/VBox/HBox/AccessoryBox/AccessoryList.get_item_metadata(index)))

# ── Signals from world nodes ──────────────────────────────────────────────────

func on_node_collected(item_id: String, node_name: String) -> void:
	InventorySystem.add(GameState.player, item_id)
	GameState.world["collected_nodes"].append(node_name)

	var food_def := DataLoader.get_food(item_id)
	if not food_def.is_empty():
		GameState.world["food_gathered_total"] = \
			GameState.world.get("food_gathered_total", 0) + 1
		$HUD.show_hint("Found  " + food_def.get("display_name", item_id))
	else:
		$HUD.show_hint("Found  " + DataLoader.get_evolution_item(item_id).get("display_name", item_id))

	$HUD.refresh()
	_check_milestone()

func on_evolution_stone_entered() -> void:
	var c   := GameState.creature
	var def := DataLoader.get_creature(c.creature_id)

	if c.evolved or not def.get("evolved_form_id"):
		$HUD.show_hint("%s is fully evolved." % def.get("display_name", "?"))
		return

	if EvolutionSystem.can_evolve(c, GameState.player):
		SceneManager.go_to("evolution")
		return

	var req_level : int    = def.get("evolution_level", 999)
	var req_item  : String = def.get("evolution_item_id", "")
	var item_name : String = DataLoader.get_evolution_item(req_item).get("display_name", req_item)
	var has_level : bool   = c.level >= req_level
	var has_item  : bool   = GameState.player.has_item(req_item)

	if not has_level and not has_item:
		$HUD.show_hint("Need Lv. %d and %s to evolve" % [req_level, item_name])
	elif not has_level:
		$HUD.show_hint("Reach Lv. %d to evolve   ( now Lv. %d )" % [req_level, c.level])
	else:
		$HUD.show_hint("Need %s to evolve" % item_name)

# ── Milestone system ──────────────────────────────────────────────────────────

func _check_milestone() -> void:
	var completed := MilestoneSystem.check_and_advance()
	if not completed.is_empty():
		_show_milestone_popup(completed)
	_update_objective_label()

func _update_objective_label() -> void:
	if MilestoneSystem.is_complete():
		$HUD.refresh_objective("")
		return
	$HUD.refresh_objective(
		"  \u25b6  " + MilestoneSystem.objective_text() + MilestoneSystem.progress_text()
	)

func _show_milestone_popup(m: Dictionary) -> void:
	_milestone_popup_open = true
	$UI/MilestonePopup/VBox/PopupTitle.text = m.get("completion_title", "Milestone")
	$UI/MilestonePopup/VBox/PopupBody.text  = m.get("completion_body", "")
	$UI/MilestonePopup.visible = true

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
