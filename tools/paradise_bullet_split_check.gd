extends Node


const BULLET_SCENE := preload("res://scenes/entities/projectiles/bullet.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	RunManager.compute_capacity = 99
	RunManager.equipment_inventory = ["pulse_cannon", "paradise_heavenfall_array"]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = ["paradise_heavenfall_array"]

	var stats := RunManager.get_player_stats()
	if int(stats.get("bullet_split_count", 0)) < 4:
		_fail("Paradise relic should add enough split projectiles for screen coverage.")
		return
	if float(stats.get("bullet_split_spread_degrees", 0.0)) < 20.0:
		_fail("Paradise relic should add a visible split spread angle.")
		return
	if float(stats.get("bullet_split_damage_mult", 0.0)) <= 0.0:
		_fail("Paradise relic should add split projectile damage.")
		return

	var player = PLAYER_SCENE.instantiate()
	player.bullet_scene = BULLET_SCENE
	player.movement_bounds = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	player.global_position = Vector2(500, 500)
	add_child(player)

	player._spawn_player_bullet(Vector2.RIGHT)
	await get_tree().process_frame
	var bullet := _find_player_bullet()
	if bullet == null:
		_fail("Player should spawn a projectile for paradise split check.")
		return
	if int(bullet.get("split_count")) < 4:
		_fail("Player projectile should carry paradise split count.")
		return
	if float(bullet.get("split_spread_degrees")) < 20.0:
		_fail("Player projectile should carry paradise split spread.")
		return

	var before := _player_bullet_count()
	bullet.destroy()
	await get_tree().process_frame
	var after := _player_bullet_count()
	if after < before + int(stats.get("bullet_split_count", 0)) - 1:
		_fail("Paradise projectile should split into additional coverage bullets.")
		return

	for projectile in get_tree().get_nodes_in_group(&"force_field_projectiles"):
		if is_instance_valid(projectile) and projectile.has_method("is_player_bullet") and bool(projectile.call("is_player_bullet")):
			if int(projectile.get("split_count")) != 0:
				_fail("Split projectiles should not recursively split forever.")
				return

	print("Paradise bullet split check passed.")
	get_tree().quit(0)


func _find_player_bullet() -> Node:
	for node in get_tree().get_nodes_in_group(&"force_field_projectiles"):
		if is_instance_valid(node) and node.has_method("is_player_bullet") and bool(node.call("is_player_bullet")):
			return node
	return null


func _player_bullet_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(&"force_field_projectiles"):
		if is_instance_valid(node) and node.has_method("is_player_bullet") and bool(node.call("is_player_bullet")):
			count += 1
	return count


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
