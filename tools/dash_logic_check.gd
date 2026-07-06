extends Node


const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := Node2D.new()
	scene.name = "DashLogicCheck"
	add_child(scene)

	var player = PLAYER_SCENE.instantiate()
	player.movement_bounds = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	player.global_position = Vector2(500, 500)
	scene.add_child(player)

	var enemy := _make_test_enemy(Vector2(520, 500))
	scene.add_child(enemy)

	player._start_dash(Vector2.LEFT)
	for i in range(18):
		player._update_dash(1.0 / 60.0)
		if not player._dash_active:
			break

	var traveled: float = player.global_position.distance_to(Vector2(500, 500))
	if traveled <= 160.0:
		push_error("Dash should carry the player out after starting close to a target, traveled=%s" % traveled)
		get_tree().quit(1)
		return
	if not player._dash_active and player._dash_remaining_distance > 0.0:
		push_error("Dash ended with distance still pending.")
		get_tree().quit(1)
		return
	print("Dash logic check passed.")
	get_tree().quit(0)


func _make_test_enemy(pos: Vector2) -> Area2D:
	var enemy := Area2D.new()
	enemy.name = "CloseDashTarget"
	enemy.global_position = pos
	enemy.add_to_group(&"enemies")
	return enemy
