extends Node2D

const PlayerScene    := preload("res://entities/Player.tscn")
const CompanionScene := preload("res://entities/CreatureCompanion.tscn")
const FoodScene      := preload("res://entities/FoodPickup.tscn")
const StoneScene     := preload("res://entities/EvolutionStone.tscn")

# ── Map geometry ──────────────────────────────────────────────────────────────

# Bark-brown wall colour
const WALL_COLOR := Color(0.20, 0.14, 0.08, 1.0)

# Rect2(x, y, w, h) in world pixels. 1280×720 viewport, 64 px tile unit.
const WALLS: Array = [
	Rect2(   0,   0, 1280,  64),   # top border
	Rect2(   0, 656, 1280,  64),   # bottom border
	Rect2(   0,   0,   64, 720),   # left border
	Rect2(1216,   0,   64, 720),   # right border
	Rect2( 320, 192,   64, 192),   # interior pillar A
	Rect2( 768, 320,   64, 192),   # interior pillar B
	Rect2( 512, 448,  192,  64),   # interior block  C
	Rect2( 960, 128,   64, 256),   # interior pillar D
]

# [food_id, world_position, unique_node_name]
const FOOD_NODES: Array = [
	["berrysprig",   Vector2( 180, 160), "food_0"],
	["berrysprig",   Vector2( 600, 200), "food_1"],
	["berrysprig",   Vector2( 900, 480), "food_2"],
	["berrysprig",   Vector2( 200, 560), "food_3"],
	["sunmoss",      Vector2( 440, 300), "food_4"],
	["sunmoss",      Vector2(1100, 200), "food_5"],
	["dewdrop_vial", Vector2( 640, 520), "food_6"],
]

const STONE_POS    := Vector2(1100, 400)
const PLAYER_START := Vector2( 180, 360)

# ── State ─────────────────────────────────────────────────────────────────────

var _player:     CharacterBody2D = null
var _hint_timer: SceneTreeTimer  = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_walls()
	_place_food()
	_place_stone()
	_spawn_player()
	_spawn_companion()
	_restore_collected()
	_setup_ui()

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

func _spawn_player() -> void:
	_player          = PlayerScene.instantiate()
	_player.position = PLAYER_START
	add_child(_player)

func _spawn_companion() -> void:
	var comp    := CompanionScene.instantiate()
	comp.target = _player
	add_child(comp)

# Remove nodes already collected in a previous session.
# If all food was collected, allow one respawn before locking it out.
func _restore_collected() -> void:
	var collected: Array = GameState.world.get("collected_nodes", [])

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
	_refresh_hud()

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
	$UI/ItemsLabel.text = "[ I ]  Items: %d" % total

func _refresh_resource_strip() -> void:
	# Show each food type and count in a compact strip just below the top bar.
	var parts: Array = []
	for entry: Dictionary in InventorySystem.get_display_list(GameState.player):
		if entry["is_food"]:
			parts.append("%s ×%d" % [entry["display_name"], entry["count"]])
	$UI/ResourceStrip.text = "  ".join(parts)

# ── Inventory panel ───────────────────────────────────────────────────────────

func _toggle_inventory() -> void:
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
		"Lv. %d   ·   EXP  %d / %d" % [c.level, c.exp, exp_need]

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
			evo_text = "Level reached — need %s" % item_name
		else:
			evo_text = "Evolves at Lv. %d   +   %s" % [req_level, item_name]

	box.get_node("EvoReqLabel").text = evo_text

func _populate_inv_list() -> void:
	var list := $UI/InventoryPanel/VBox/InvList
	list.clear()
	var items := InventorySystem.get_display_list(GameState.player)
	if items.is_empty():
		list.add_item("— bag is empty —")
		return
	for entry: Dictionary in items:
		var row := "%s   ×%d" % [entry["display_name"], entry["count"]]
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

	var levelled_up := ExpSystem.apply_exp(GameState.creature, food_def["exp_value"])
	InventorySystem.remove(GameState.player, item_id)
	_populate_creature_info()
	_populate_inv_list()
	_refresh_hud()

	var msg := "Fed %s   (+%d EXP)" % [food_def.get("display_name", ""), food_def.get("exp_value", 0)]
	if levelled_up:
		msg += "   —   Level up!  Lv. %d" % GameState.creature.level
	show_hint(msg)

# ── Signals from world nodes ──────────────────────────────────────────────────

func on_node_collected(item_id: String, node_name: String) -> void:
	InventorySystem.add(GameState.player, item_id)
	GameState.world["collected_nodes"].append(node_name)
	_refresh_hud()
	var def := DataLoader.get_food(item_id)
	show_hint("Found  " + def.get("display_name", item_id))

func on_evolution_stone_entered() -> void:
	var c   := GameState.creature
	var def := DataLoader.get_creature(c.creature_id)

	# Already at max stage — no further evolution possible.
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
	if event.is_action_pressed("open_inventory"):
		_toggle_inventory()
