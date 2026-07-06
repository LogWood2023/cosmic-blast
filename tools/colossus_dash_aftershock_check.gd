extends Node


const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	RunManager.compute_capacity = 99
	RunManager.equipment_inventory = ["pulse_cannon", "colossus_aftershock_keel"]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = ["colossus_aftershock_keel"]

	var stats := RunManager.get_player_stats()
	if float(stats.get("dash_aftershock_radius", 0.0)) < 80.0:
		_fail("Colossus relic should add a dash aftershock radius.")
		return
	if float(stats.get("dash_aftershock_damage_mult", 0.0)) <= 0.0:
		_fail("Colossus relic should add dash aftershock damage.")
		return

	var scene := Node2D.new()
	scene.name = "ColossusDashAftershockCheckRoot"
	add_child(scene)

	var player = PLAYER_SCENE.instantiate()
	player.movement_bounds = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	player.global_position = Vector2(500, 500)
	scene.add_child(player)

	if float(player.get("_run_dash_aftershock_radius")) < 80.0:
		_fail("Player should apply dash aftershock radius from colossus relic.")
		return
	if float(player.get("_run_dash_aftershock_damage_mult")) <= 0.0:
		_fail("Player should apply dash aftershock damage from colossus relic.")
		return

	var direct_enemy := _make_test_enemy(Vector2(620, 500))
	var nearby_enemy := _make_test_enemy(Vector2(620, 575))
	var far_enemy := _make_test_enemy(Vector2(620, 760))
	scene.add_child(direct_enemy)
	scene.add_child(nearby_enemy)
	scene.add_child(far_enemy)

	player._start_dash(Vector2.RIGHT)
	for _i in range(24):
		player._update_dash(1.0 / 60.0)
		await get_tree().process_frame
		if not player._dash_active:
			break

	if int(direct_enemy.get("hp")) >= 100:
		_fail("Dash impact should damage the directly struck enemy.")
		return
	if int(nearby_enemy.get("hp")) >= 100:
		_fail("Dash aftershock should damage a nearby enemy that was not directly struck.")
		return
	if int(far_enemy.get("hp")) < 100:
		_fail("Dash aftershock should not reach far enemies.")
		return

	print("Colossus dash aftershock check passed.")
	get_tree().quit(0)


func _make_test_enemy(pos: Vector2) -> Area2D:
	var enemy := Area2D.new()
	enemy.name = "ColossusAftershockTarget"
	enemy.global_position = pos
	enemy.set_script(TestEnemyScript)
	enemy.add_to_group(&"enemies")
	return enemy


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)


class TestEnemyScript:
	extends Area2D

	var hp: int = 100

	func take_damage(amount: int, _source: Node = null) -> void:
		hp -= maxi(0, amount)
