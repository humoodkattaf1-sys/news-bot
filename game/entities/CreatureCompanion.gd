extends Node2D

## Set by ExploreScene immediately after instantiation.
var target: Node2D = null

const FOLLOW_SPEED  := 5.0
const FOLLOW_OFFSET := Vector2(-38, 12)

# One color per creature id — mirrors CreatureSelectScene palette.
const COLORS: Dictionary = {
	"frogling":    Color(0.18, 0.48, 0.22, 1),
	"embkit":      Color(0.65, 0.25, 0.08, 1),
	"puffmote":    Color(0.42, 0.30, 0.62, 1),
	"marshwarden": Color(0.18, 0.48, 0.22, 1),
	"cinderhorn":  Color(0.65, 0.25, 0.08, 1),
	"galehallow":  Color(0.42, 0.30, 0.62, 1),
}

var _color: Color = Color(0.35, 0.35, 0.35, 1)

func _ready() -> void:
	_color = COLORS.get(GameState.creature.creature_id, Color(0.35, 0.35, 0.35, 1))

func _process(delta: float) -> void:
	if target == null:
		return
	var goal := target.position + FOLLOW_OFFSET
	position  = position.lerp(goal, FOLLOW_SPEED * delta)

func _draw() -> void:
	# Body — creature-coloured square, slightly smaller than the player
	draw_rect(Rect2(-11, -11, 22, 22), _color)
	# Soft white rim
	draw_rect(Rect2(-11, -11, 22, 22), Color(1.0, 1.0, 1.0, 0.28), false, 1.5)
	# Shadow dot below to suggest depth
	draw_circle(Vector2(0, 14), 5.0, Color(0.0, 0.0, 0.0, 0.18))
