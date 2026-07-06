extends Node


const EXPLORE_ROOM_SCENE := preload("res://scenes/gameplay/explore/ExploreRoom.tscn")
const DesignedEnemyScript := preload("res://scripts/entities/designed_enemies/DesignedEnemy.gd")
const READY_CONTEXT := "ExploreRoom.ready"
const READY_TIMEOUT_SECONDS := 20.0

@export var variant: String = "full"

var headless_runner_quit_after_seconds: float = READY_TIMEOUT_SECONDS + 3.0
var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_apply_variant_config(variant)
	var room := EXPLORE_ROOM_SCENE.instantiate()
	add_child(room)
	var elapsed := 0.0
	while elapsed < READY_TIMEOUT_SECONDS:
		if GameManager.stutter_context == READY_CONTEXT:
			break
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if GameManager.stutter_context != READY_CONTEXT:
		_fail("ExploreRoom variant %s did not finish loading. Last context: %s" % [variant, GameManager.stutter_context])
		return
	remove_child(room)
	room.queue_free()
	await _finish_explore_room_cleanup(room)
	print("Explore room cleanup variant check passed: %s" % variant)
	get_tree().quit(0)


func _finish_explore_room_cleanup(room: Node) -> void:
	while is_instance_valid(room):
		await get_tree().process_frame
	DesignedEnemyScript.release_static_runtime_resources()
	GameManager.set_next_explore_room_config({})
	RunManager.cancel_run()
	for _i in range(90):
		if _count_cleanup_residue() == 0:
			break
		await get_tree().process_frame
	for _i in range(12):
		await get_tree().process_frame


func _count_cleanup_residue() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			count += 1
	count += _count_named_residue(get_tree().root, {
		"EnemyEffects": true,
		"ExploreEnemies": true,
		"PatrolEnemyPool": true,
		"PatrolPaths": true,
		"AlertArrowToPlayer": true,
	})
	return count


func _count_named_residue(node: Node, names: Dictionary) -> int:
	var count := 0
	for child in node.get_children():
		if not is_instance_valid(child) or child.is_queued_for_deletion():
			continue
		if names.has(String(child.name)):
			count += 1
		count += _count_named_residue(child, names)
	return count


func _apply_variant_config(variant: String) -> void:
	match variant:
		"minimal":
			GameManager.set_next_explore_room_config({
				"large_space_rock_count": 0,
				"trap_count": 0,
				"chest_crystal_count": 0,
				"clutter_count": 0,
				"enemy_spawn_interval": 999.0,
				"max_patrol_enemy_count": 0,
				"battle_patrol_path_min_count": 0,
				"battle_patrol_path_max_count": 0,
				"battle_elite_replacement_min": 0,
				"battle_elite_replacement_max": 0,
			})
		"no_enemies":
			GameManager.set_next_explore_room_config({
				"large_space_rock_count": 8,
				"trap_count": 0,
				"chest_crystal_count": 12,
				"clutter_count": 24,
				"enemy_spawn_interval": 999.0,
				"max_patrol_enemy_count": 0,
				"battle_patrol_path_min_count": 0,
				"battle_patrol_path_max_count": 0,
				"battle_elite_replacement_min": 0,
				"battle_elite_replacement_max": 0,
			})
		"enemies":
			GameManager.set_next_explore_room_config({
				"large_space_rock_count": 8,
				"trap_count": 3,
				"chest_crystal_count": 12,
				"clutter_count": 24,
				"enemy_spawn_interval": 30.0,
				"max_patrol_enemy_count": 8,
				"battle_patrol_path_min_count": 2,
				"battle_patrol_path_max_count": 2,
				"battle_elite_replacement_min": 1,
				"battle_elite_replacement_max": 1,
			})
		"patrol_only":
			GameManager.set_next_explore_room_config({
				"large_space_rock_count": 8,
				"trap_count": 3,
				"chest_crystal_count": 12,
				"clutter_count": 24,
				"enemy_spawn_interval": 30.0,
				"max_patrol_enemy_count": 8,
				"battle_patrol_path_min_count": 2,
				"battle_patrol_path_max_count": 2,
				"battle_elite_replacement_min": 0,
				"battle_elite_replacement_max": 0,
			})
		"elite_only":
			GameManager.set_next_explore_room_config({
				"large_space_rock_count": 8,
				"trap_count": 0,
				"chest_crystal_count": 12,
				"clutter_count": 24,
				"enemy_spawn_interval": 999.0,
				"max_patrol_enemy_count": 0,
				"battle_patrol_path_min_count": 0,
				"battle_patrol_path_max_count": 0,
				"battle_elite_replacement_min": 1,
				"battle_elite_replacement_max": 1,
			})
		_:
			pass


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
