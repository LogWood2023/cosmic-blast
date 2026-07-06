extends Node


const BULLET_SCENE := preload("res://scenes/entities/projectiles/bullet.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	RunManager.compute_capacity = 99
	RunManager.equipment_inventory = ["pulse_cannon", "hell_eye_apocalypse_pupil"]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = ["hell_eye_apocalypse_pupil"]

	var stats := RunManager.get_player_stats()
	if float(stats.get("frenzy_damage_mult", 1.0)) <= 1.0:
		_fail("Hell-eye relic should add outgoing frenzy damage.")
		return

	GameManager.reset_run_state()
	var player = PLAYER_SCENE.instantiate()
	player.bullet_scene = BULLET_SCENE
	player.movement_bounds = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	player.global_position = Vector2(500, 500)
	add_child(player)

	player._spawn_player_bullet(Vector2.RIGHT)
	await get_tree().process_frame
	var normal_bullet := _find_player_bullet()
	if normal_bullet == null:
		_fail("Player should spawn a normal projectile for hell-eye check.")
		return
	var normal_atk := int(normal_bullet.get("atk"))
	normal_bullet.queue_free()

	GameManager.frenzy_active = true
	GameManager.frenzy_timer = GameManager.FRENZY_DURATION
	GameManager.frenzy_value = GameManager.FRENZY_MAX
	player._spawn_player_bullet(Vector2.RIGHT)
	await get_tree().process_frame
	var frenzy_bullet := _find_player_bullet()
	if frenzy_bullet == null:
		_fail("Player should spawn a frenzy projectile for hell-eye check.")
		return
	var frenzy_atk := int(frenzy_bullet.get("atk"))
	if frenzy_atk <= normal_atk:
		_fail("Hell-eye frenzy projectile should deal more damage than normal shots.")
		return

	print("Hell-eye frenzy damage check passed.")
	get_tree().quit(0)


func _find_player_bullet() -> Node:
	for node in get_tree().get_nodes_in_group(&"force_field_projectiles"):
		if is_instance_valid(node) and node.has_method("is_player_bullet") and bool(node.call("is_player_bullet")):
			return node
	return null


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
