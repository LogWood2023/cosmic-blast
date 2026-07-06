extends Node


const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")
const BULLET_SCENE := preload("res://scenes/entities/projectiles/bullet.tscn")
const DRONE_SCENE_PATH := "res://scenes/entities/support/SupportDrone.tscn"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(DRONE_SCENE_PATH):
		_fail("Support drone scene should exist as an editable standalone scene.")
		return

	RunManager.start_new_run()
	RunManager.compute_capacity = 99
	RunManager.equipment_inventory = ["pulse_cannon", "divine_oracle_swarm_core"]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = ["divine_oracle_swarm_core"]

	var stats := RunManager.get_player_stats()
	if int(stats.get("drone_slots", 0)) < 3:
		_fail("High-stage divine relic should command a visible support drone swarm.")
		return
	if float(stats.get("drone_fire_interval_mult", 1.0)) >= 1.0:
		_fail("High-stage divine relic should shorten support drone fire interval.")
		return
	if float(stats.get("drone_damage_mult", 1.0)) <= 1.0:
		_fail("High-stage divine relic should amplify support drone damage.")
		return

	var player = PLAYER_SCENE.instantiate()
	player.bullet_scene = BULLET_SCENE
	player.movement_bounds = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	player.global_position = Vector2(500, 500)
	add_child(player)

	await get_tree().process_frame
	var drones := get_tree().get_nodes_in_group(&"player_support_drones")
	if drones.size() < 3:
		_fail("Equipping a high-stage divine relic should spawn at least three support drones.")
		return
	var drone := drones[0]
	if drone.scene_file_path != DRONE_SCENE_PATH:
		_fail("Support drone should be instanced from %s, got %s." % [DRONE_SCENE_PATH, drone.scene_file_path])
		return
	if float(drone.get("fire_interval")) >= 0.55:
		_fail("Support drone should apply divine swarm fire interval scaling.")
		return
	if int(drone.get("bullet_damage")) < 10:
		_fail("Support drone should apply divine swarm damage scaling.")
		return

	var enemy := _make_enemy(Vector2(760, 500))
	add_child(enemy)

	for _i in range(180):
		await get_tree().process_frame
		if int(enemy.get("hp")) < 12:
			print("Support drone check passed.")
			get_tree().quit(0)
			return

	_fail("Support drone should automatically damage a nearby enemy.")


func _make_enemy(pos: Vector2) -> Area2D:
	var enemy := Area2D.new()
	enemy.name = "SupportDroneTarget"
	enemy.global_position = pos
	enemy.set_script(TestEnemyScript)
	enemy.add_to_group(&"enemies")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	shape.shape = circle
	enemy.add_child(shape)
	return enemy


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)


class TestEnemyScript:
	extends Area2D

	var hp: int = 12

	func take_damage(amount: int, _source: Node = null) -> void:
		hp -= maxi(0, amount)
