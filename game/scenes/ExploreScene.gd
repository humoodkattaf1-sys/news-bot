extends Node2D

# Colours match CreatureSelectScene so the companion art feels consistent.
const CREATURE_COLORS: Dictionary = {
	"frogling":  Color(0.18, 0.48, 0.22, 1),
	"embkit":    Color(0.65, 0.25, 0.08, 1),
	"puffmote":  Color(0.42, 0.30, 0.62, 1),
	# Stage-2 forms share the same hue family
	"marshwarden": Color(0.18, 0.48, 0.22, 1),
	"cinderhorn":  Color(0.65, 0.25, 0.08, 1),
	"galehallow":  Color(0.42, 0.30, 0.62, 1),
}

func _ready() -> void:
	_update_ui()

func _update_ui() -> void:
	var creature := GameState.creature
	var player   := GameState.player
	var def      := DataLoader.get_creature(creature.creature_id)

	var ui := $UI/Root

	# Greeting
	ui.get_node("Center/VBox/GreetLabel").text = \
		"%s's journey begins..." % player.player_name

	# Companion line
	ui.get_node("Center/VBox/CompanionLabel").text = \
		"Companion:  %s  —  Lv. %d" % [def.get("display_name", "?"), creature.level]

	# Placeholder art
	var col: Color = CREATURE_COLORS.get(creature.creature_id, Color(0.3, 0.3, 0.3, 1))
	var art: ColorRect = ui.get_node("Center/VBox/CreatureArt")
	art.color = col
	art.get_node("ArtInitial").text = def.get("display_name", "?")[0].to_upper()

# ── Called by pickup Area2D nodes (wired up in full explore scene) ────────────

func on_node_collected(item_id: String, node_name: String) -> void:
	InventorySystem.add(GameState.player, item_id)
	GameState.world["collected_nodes"].append(node_name)

# ── Called by EvolutionStone Area2D on player contact ─────────────────────────

func on_evolution_stone_entered() -> void:
	if EvolutionSystem.can_evolve(GameState.creature, GameState.player):
		SceneManager.go_to("evolution")
