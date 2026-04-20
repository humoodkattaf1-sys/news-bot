extends CharacterBody2D

var facing := Vector2.DOWN

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		facing = dir.normalized()
		queue_redraw()
	velocity = dir * GrowthSystem.speed()
	move_and_slide()

func _draw() -> void:
	var sz := GrowthSystem.draw_size()
	var h  := sz * 0.5
	draw_rect(Rect2(-h, -h, sz, sz), Color(0.88, 0.78, 0.52, 1.0))
	draw_rect(Rect2(-h, -h, sz, sz), Color(1.0, 1.0, 0.85, 0.70), false, 2.0)
	draw_circle(facing * (h * 0.54), 3.5, Color(0.40, 0.30, 0.18, 0.85))
