extends Node2D

func _ready() -> void:
	_setup_before()
	await _play_evolution_animation()
	EvolutionSystem.do_evolve(GameState.creature, GameState.player)
	await _setup_after()

# ── Phase helpers ─────────────────────────────────────────────────────────────

func _setup_before() -> void:
	var def   := DataLoader.get_creature(GameState.creature.creature_id)
	var stats := def.get("base_stats", {})
	$UI/TitleLabel.text    = "Something stirs\u2026"
	$UI/CreatureName.text  = def.get("display_name", "?")
	$UI/StatsBefore.text   = _fmt_stats(stats)
	$UI/EvolvedName.visible   = false
	$UI/StatsAfter.visible    = false
	$UI/ConfirmButton.visible = false
	$AnimLayer/BeforeShape.scale   = Vector2(1.0, 1.0)
	$AnimLayer/BeforeShape.visible = true
	$AnimLayer/AfterShape.visible  = false

func _play_evolution_animation() -> void:
	$UI/TitleLabel.text = "Evolving\u2026"
	# Pulse outward then collapse to nothing
	var tw := create_tween()
	tw.tween_property($AnimLayer/BeforeShape, "scale",
		Vector2(1.55, 1.55), 0.42) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property($AnimLayer/BeforeShape, "scale",
		Vector2(0.0, 0.0), 0.38) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	$AnimLayer/BeforeShape.visible = false

func _setup_after() -> void:
	var def   := DataLoader.get_creature(GameState.creature.creature_id)
	var stats := def.get("base_stats", {})
	$UI/TitleLabel.text   = "Evolution complete!"
	$UI/EvolvedName.text  = def.get("display_name", "?")
	$UI/StatsAfter.text   = _fmt_stats(stats)
	$UI/EvolvedName.visible = true
	$UI/StatsAfter.visible  = true
	# Burst the evolved shape in from zero
	$AnimLayer/AfterShape.scale   = Vector2(0.0, 0.0)
	$AnimLayer/AfterShape.visible = true
	var tw := create_tween()
	tw.tween_property($AnimLayer/AfterShape, "scale",
		Vector2(1.0, 1.0), 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	$UI/ConfirmButton.visible = true

# ── Signals ───────────────────────────────────────────────────────────────────

func _on_confirm_pressed() -> void:
	SceneManager.go_to("story")

# ── Helpers ───────────────────────────────────────────────────────────────────

func _fmt_stats(stats: Dictionary) -> String:
	return "SPD %d   RES %d   FOR %d" % [
		stats.get("speed", 0),
		stats.get("resilience", 0),
		stats.get("forage", 0),
	]
