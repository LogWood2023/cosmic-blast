extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_manager = root.get_node_or_null("GameManager")
	if game_manager == null:
		push_error("GameManager autoload not found")
		quit(1)
		return
	game_manager.reset_run_state()
	assert(game_manager.frenzy_value == 0.0)
	game_manager.add_frenzy(99.0)
	assert(is_equal_approx(game_manager.frenzy_value, 99.0))
	assert(not game_manager.frenzy_active)
	game_manager.add_frenzy(1.0)
	assert(game_manager.frenzy_active)
	assert(is_equal_approx(game_manager.frenzy_timer, game_manager.FRENZY_DURATION))
	assert(game_manager.get_incoming_damage_after_frenzy(9) == 5)
	assert(is_equal_approx(game_manager.get_fire_rate_multiplier(), game_manager.FRENZY_FIRE_RATE_MULT))
	game_manager._process(2.5)
	assert(game_manager.frenzy_active)
	assert(game_manager.frenzy_value < game_manager.FRENZY_MAX)
	game_manager._process(2.5)
	assert(not game_manager.frenzy_active)
	assert(is_equal_approx(game_manager.frenzy_value, 0.0))
	print("Frenzy logic check passed.")
	quit()
