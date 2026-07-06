extends SceneTree

const EXPECTED_EXPLORATION_NODE_COUNT := 24
const MIN_SPECIAL_NODE_COUNT := 7

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_manager = root.get_node_or_null("RunManager")
	if run_manager == null:
		push_error("RunManager autoload not found")
		quit(1)
		return
	run_manager.start_new_run()
	_check_map_scale(run_manager)
	if _failed:
		return
	_expect(run_manager.compute_capacity == 5, "Run should start with 5 compute.")
	_expect(run_manager.crisis_level == 0, "Run should start with crisis level 0.")
	if _failed:
		return
	var first_accessible := -1
	for node in run_manager.map_nodes:
		var id := int(node.get("id", -1))
		if id > 0 and String(node.get("type", "")) != run_manager.NODE_SPECIAL and run_manager.is_node_accessible(id):
			first_accessible = id
			break
	_expect(first_accessible > 0, "Run should expose at least one accessible exploration node.")
	if _failed:
		return
	_expect(run_manager.start_explore_node(first_accessible), "Accessible exploration node should start.")
	if _failed:
		return
	run_manager.pending_room_loot["minerals"] = 10
	var result: Dictionary = run_manager.complete_explore_room_success()
	var directive_rewards: Dictionary = result.get("route_directive_rewards", {})
	var expected_compute := 6 + int(directive_rewards.get("compute", 0))
	var expected_minerals := 10 + int(directive_rewards.get("minerals", 0))
	_expect(bool(result.get("ok", false)), "Completing an exploration room should succeed.")
	_expect(run_manager.crisis_level == 1, "Completing one node should raise crisis by 1.")
	_expect(run_manager.compute_capacity == expected_compute, "Completing one node should raise compute by 1 plus route directive rewards.")
	_expect(run_manager.minerals == expected_minerals, "Committed room loot and route directive rewards should reach minerals.")
	_expect(run_manager.is_node_completed(first_accessible), "Completed node should stay completed.")
	if _failed:
		return
	run_manager.crisis_level = 5
	_expect(run_manager.is_alert_active(), "Crisis level 5 should trigger alert.")
	if _failed:
		return
	for node in run_manager.map_nodes:
		var id := int(node.get("id", -1))
		if id > 0 and String(node.get("type", "")) != run_manager.NODE_SPECIAL and not run_manager.is_node_completed(id):
			_expect(not run_manager.is_node_accessible(id), "Alert should lock non-core exploration node %d." % id)
			if _failed:
				return
	_expect(run_manager.begin_crisis_boss(), "Alert should allow starting a crisis boss.")
	_expect(not run_manager.pending_boss_scene.is_empty(), "Crisis boss scene should be selected.")
	if _failed:
		return
	print("Run flow check passed.")
	quit(0)


func _check_map_scale(run_manager: Node) -> void:
	var exploration_count := 0
	var special_count := 0
	for node in run_manager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0:
			continue
		if String(node.get("type", "")) == run_manager.NODE_SPECIAL:
			special_count += 1
		else:
			exploration_count += 1
	_expect(exploration_count == EXPECTED_EXPLORATION_NODE_COUNT, "World map should contain %d exploration nodes, got %d." % [EXPECTED_EXPLORATION_NODE_COUNT, exploration_count])
	_expect(special_count >= MIN_SPECIAL_NODE_COUNT, "World map should contain at least %d special nodes, got %d." % [MIN_SPECIAL_NODE_COUNT, special_count])


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	quit(1)
