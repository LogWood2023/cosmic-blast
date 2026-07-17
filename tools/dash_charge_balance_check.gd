extends Node

const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	add_child(world)
	var player = PLAYER_SCENE.instantiate()
	player.movement_bounds = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	player.global_position = Vector2(960, 540)
	world.add_child(player)
	if player.get_dash_charges() != 2:
		_fail("Dash must begin with two charges.")
		return
	player._start_dash(Vector2.RIGHT)
	player._end_dash()
	player._start_dash(Vector2.RIGHT)
	player._end_dash()
	if player.get_dash_charges() != 0:
		_fail("Two dashes must consume both charges.")
		return
	player._update_dash_cooldown(1.79)
	if player.get_dash_charges() != 0:
		_fail("Dash must not recover before 1.8 seconds.")
		return
	player._update_dash_cooldown(0.02)
	if player.get_dash_charges() != 1:
		_fail("Dash must recover one charge at 1.8 seconds.")
		return
	if not is_equal_approx(player.DASH_BASE_DAMAGE_MULT, 0.75):
		_fail("Baseline dash damage must stay defensive.")
		return
	print("Dash charge balance check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
