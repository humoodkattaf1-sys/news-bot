extends Control

# One distinct hue per starter — updated at runtime to match creature index.
const CREATURE_COLORS: Array = [
	Color(0.18, 0.48, 0.22, 1),   # Frogling    — forest green
	Color(0.65, 0.25, 0.08, 1),   # Embkit      — ember orange
	Color(0.42, 0.30, 0.62, 1),   # Puffmote    — soft purple
]

var _starters: Array     = []
var _idx:      int       = 0

func _ready() -> void:
	_starters = DataLoader.get_starter_creatures()
	_refresh()

# ── Navigation ────────────────────────────────────────────────────────────────

func _on_prev_pressed() -> void:
	_idx = wrapi(_idx - 1, 0, _starters.size())
	_refresh()

func _on_next_pressed() -> void:
	_idx = wrapi(_idx + 1, 0, _starters.size())
	_refresh()

# ── Confirm ───────────────────────────────────────────────────────────────────

func _on_confirm_pressed() -> void:
	if _starters.is_empty():
		return
	var chosen: Dictionary     = _starters[_idx]
	GameState.creature.creature_id = chosen["id"]
	GameState.creature.stage       = 1
	GameState.creature.level       = 1
	GameState.creature.exp         = 0
	GameState.creature.evolved     = false
	SceneManager.go_to("explore")

# ── Display ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	if _starters.is_empty():
		return

	var def:   Dictionary = _starters[_idx]
	var stats: Dictionary = def.get("base_stats", {})
	var card:  Node       = $Center/VBox/NavRow/Card

	# Placeholder colour art + ghost initial letter
	var col: Color = CREATURE_COLORS[_idx % CREATURE_COLORS.size()]
	card.get_node("CreatureColor").color        = col
	card.get_node("CreatureColor/Initial").text = def.get("display_name", "?")[0].to_upper()

	card.get_node("CreatureName").text          = def.get("display_name", "")
	card.get_node("Description").text           = def.get("description", "")
	card.get_node("StatRow/StatSpeed").text     = "SPD  %d" % stats.get("speed", 0)
	card.get_node("StatRow/StatRes").text       = "RES  %d" % stats.get("resilience", 0)
	card.get_node("StatRow/StatFor").text       = "FOR  %d" % stats.get("forage", 0)

	# Dot indicator — filled dot for current, hollow for others
	var dots: Node = $Center/VBox/DotRow
	for i: int in range(_starters.size()):
		var dot: Label = dots.get_node("Dot%d" % i)
		if i == _idx:
			dot.text = "●"
			dot.add_theme_color_override("font_color", Color(0.8, 0.95, 0.7, 1))
		else:
			dot.text = "○"
			dot.add_theme_color_override("font_color", Color(0.38, 0.5, 0.35, 1))
