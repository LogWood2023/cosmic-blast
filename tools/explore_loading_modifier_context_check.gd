extends Node


const EXPLORE_ROOM_SCENE := preload("res://scenes/gameplay/explore/ExploreRoom.tscn")
const DesignedEnemyScript := preload("res://scripts/entities/designed_enemies/DesignedEnemy.gd")
const READY_CONTEXT := "ExploreRoom.ready"
const READY_TIMEOUT_SECONDS := 20.0

var headless_runner_quit_after_seconds: float = READY_TIMEOUT_SECONDS + 3.0
var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var node := _first_accessible_modified_node()
	if node.is_empty():
		_fail("Need an accessible exploration node with domain modifiers.")
		return
	var node_id := int(node.get("id", -1))
	var modifiers: Array = node.get("modifiers", [])
	var first_modifier := Dictionary(modifiers[0])
	var modifier_title := String(first_modifier.get("title", ""))
	if modifier_title.is_empty():
		_fail("Selected node modifier should have a visible title.")
		return
	if not RunManager.start_explore_node(node_id):
		_fail("Accessible node %d should start exploration." % node_id)
		return
	var pending_config := GameManager.next_explore_room_config.duplicate(true)
	if not pending_config.has("modifier_tip_text"):
		_fail("Explore room config should include modifier_tip_text for loading.")
		return
	var pending_tip := String(pending_config.get("modifier_tip_text", ""))
	if pending_tip.find("航域扰动") < 0 or pending_tip.find(modifier_title) < 0:
		_fail("Loading modifier tip should name the domain disturbance. Got: %s" % pending_tip)
		return
	RunManager.abandon_current_room()
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
		"modifier_tip_text": pending_tip,
	})
	var room := EXPLORE_ROOM_SCENE.instantiate()
	add_child(room)
	await get_tree().process_frame
	var loading_screen := room.get_node_or_null("UILayer/LoadingScreen") as Control
	var tip_label := loading_screen.find_child("TipLabel", true, false) as Label if loading_screen else null
	if not tip_label:
		_fail("Explore loading screen should expose TipLabel.")
		return
	var visible_tip := tip_label.text
	if visible_tip.find("航域扰动") < 0 or visible_tip.find(modifier_title) < 0:
		_fail("Explore loading screen should display modifier context. Got: %s" % visible_tip)
		return
	var elapsed := 0.0
	while elapsed < READY_TIMEOUT_SECONDS:
		if GameManager.stutter_context == READY_CONTEXT:
			break
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if GameManager.stutter_context != READY_CONTEXT:
		_fail("Explore room did not finish loading before timeout. Last context: %s" % GameManager.stutter_context)
		return
	remove_child(room)
	room.queue_free()
	await _finish_explore_room_cleanup(room)
	print("Explore loading modifier context check passed.")
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


func _first_accessible_modified_node() -> Dictionary:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		if node_id <= 0 or node_type == RunManager.NODE_SPECIAL or node_type == RunManager.NODE_EVENT:
			continue
		if not RunManager.is_node_accessible(node_id):
			continue
		var modifiers: Array = node.get("modifiers", [])
		if not modifiers.is_empty():
			return node
	return {}


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
