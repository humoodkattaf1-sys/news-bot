extends Area2D

## Emitted when a player body enters the pickup zone.
## ExploreScene connects this on instantiation.
signal collected(item_id: String, node_name: String)

## Set by ExploreScene before add_child() so _ready() has it available.
var food_id: String = ""

# Visual style per food type
const STYLES: Dictionary = {
	"berrysprig":      { "color": Color(0.85, 0.18, 0.18, 1.0), "radius": 9.0 },
	"sunmoss":         { "color": Color(0.88, 0.72, 0.10, 1.0), "radius": 11.0 },
	"dewdrop_vial":    { "color": Color(0.28, 0.58, 0.92, 1.0), "radius": 9.0 },
	"moonstone_shard": { "color": Color(0.78, 0.72, 0.96, 1.0), "radius": 13.0 },
}

var _color:  Color  = Color(0.75, 0.75, 0.75, 1.0)
var _radius: float  = 9.0

func _ready() -> void:
	var style := STYLES.get(food_id, STYLES["berrysprig"])
	_color    = style["color"]
	_radius   = style["radius"]
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collected.emit(food_id, name)
		queue_free()

func _draw() -> void:
	# Soft ambient glow
	draw_circle(Vector2.ZERO, _radius + 6.0, Color(_color.r, _color.g, _color.b, 0.15))
	# Main orb
	draw_circle(Vector2.ZERO, _radius, _color)
	# Specular highlight
	draw_circle(
		Vector2(-_radius * 0.28, -_radius * 0.32),
		_radius * 0.30,
		Color(1.0, 1.0, 1.0, 0.38)
	)
