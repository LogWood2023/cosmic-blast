extends Node


const BULLET_SCENE := preload("res://scenes/entities/projectiles/bullet.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	RunManager.compute_capacity = 99
	RunManager.equipment_inventory = ["pulse_cannon", "warped_gravity_lens"]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = ["warped_gravity_lens"]

	var stats := RunManager.get_player_stats()
	if float(stats.get("gravity_pull_strength", 0.0)) <= 0.0:
		_fail("Warped relic should add projectile gravity pull strength.")
		return
	if float(stats.get("gravity_pull_radius", 0.0)) < 180.0:
		_fail("Warped relic should add a meaningful projectile gravity pull radius.")
		return

	var player = PLAYER_SCENE.instantiate()
	player.bullet_scene = BULLET_SCENE
	player.movement_bounds = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	player.global_position = Vector2(500, 500)
	add_child(player)

	player._spawn_player_bullet(Vector2.RIGHT)
	await get_tree().process_frame
	var player_bullet := _find_player_bullet()
	if player_bullet == null:
		_fail("Player should spawn a projectile for warped gravity check.")
		return
	if float(player_bullet.get("gravity_pull_strength")) <= 0.0:
		_fail("Player projectile should carry warped gravity pull strength.")
		return
	if float(player_bullet.get("gravity_pull_radius")) < 180.0:
		_fail("Player projectile should carry warped gravity pull radius.")
		return
	player_bullet.queue_free()

	var pull_bullet = BULLET_SCENE.instantiate()
	pull_bullet.global_position = Vector2(800, 500)
	pull_bullet.direction = Vector2.RIGHT
	pull_bullet.speed = 0.0
	pull_bullet.gravity_pull_strength = 720.0
	pull_bullet.gravity_pull_radius = 240.0
	add_child(pull_bullet)

	var enemy := _make_enemy(Vector2(800, 660))
	add_child(enemy)
	var start_y := enemy.global_position.y
	for _i in range(16):
		await get_tree().process_frame
	if enemy.global_position.y <= start_y + 12.0:
		_fail("Warped repulsor projectile should push nearby enemies away from its center.")
		return

	print("Warped gravity pull check passed.")
	get_tree().quit(0)


func _find_player_bullet() -> Node:
	for node in get_tree().get_nodes_in_group(&"force_field_projectiles"):
		if is_instance_valid(node) and node.has_method("is_player_bullet") and bool(node.call("is_player_bullet")):
			return node
	return null


func _make_enemy(pos: Vector2) -> Area2D:
	var enemy := Area2D.new()
	enemy.name = "WarpedGravityTarget"
	enemy.global_position = pos
	enemy.add_to_group(&"enemies")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	enemy.add_child(shape)
	return enemy


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
