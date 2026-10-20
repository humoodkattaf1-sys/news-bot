extends Area2D

## Emitted once when the player enters the stone's zone.
## ExploreScene.on_evolution_stone_entered() decides what happens next.
signal stone_entered

# Guard so the signal only fires once per visit, not every physics frame.
var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	stone_entered.emit()
	# Reset the guard after a short cooldown so the player can re-trigger
	# (e.g. after returning from a failed evolution check).
	await get_tree().create_timer(1.5).timeout
	_triggered = false

func _draw() -> void:
	var pts := PackedVector2Array([
		Vector2(  0, -26),   # top
		Vector2( 22,   0),   # right
		Vector2(  0,  26),   # bottom
		Vector2(-22,   0),   # left
	])

	# Outer glow
	draw_circle(Vector2.ZERO, 34.0, Color(0.62, 0.42, 0.90, 0.10))

	# Filled diamond
	draw_polygon(pts, PackedColorArray([Color(0.60, 0.38, 0.88, 0.80)]))

	# Outline — close the shape manually
	var outline := PackedVector2Array(pts)
	outline.append(pts[0])
	draw_polyline(outline, Color(0.92, 0.80, 1.0, 0.85), 2.0)

	# Inner sparkle
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.96, 1.0, 0.75))

	# Label drawn below the stone
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-18, 42),
		"EVOLVE STONE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color(0.88, 0.78, 1.0, 0.75)
	)
