extends CharacterBody2D

const SPEED := 180.0

# Slight bob offset — updated each frame so the companion can smooth-follow.
var facing := Vector2.DOWN

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		facing = dir.normalized()
	velocity = dir * SPEED
	move_and_slide()

func _draw() -> void:
	# Body — warm beige square
	draw_rect(Rect2(-13, -13, 26, 26), Color(0.88, 0.78, 0.52, 1.0))
	# Outline
	draw_rect(Rect2(-13, -13, 26, 26), Color(1.0, 1.0, 0.85, 0.70), false, 2.0)
	# Direction dot so the player knows which way they face
	draw_circle(facing * 7.0, 3.5, Color(0.40, 0.30, 0.18, 0.85))
