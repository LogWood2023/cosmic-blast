extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var summaries: Array = RunManager.get_route_directive_summaries()
	if summaries.size() != RunManager.ROUTE_DIRECTIVE_COUNT:
		_fail("Each run should start with the configured route directive count, got %d." % summaries.size())
		return
	var profile_ids := {}
	for raw_profile in RunManager.get_route_directive_profiles():
		profile_ids[String(Dictionary(raw_profile).get("id", ""))] = true
	var seen_ids := {}
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		for key in ["id", "title", "description", "goal_type", "current", "required", "reward", "reward_text"]:
			if not summary.has(key):
				_fail("Route directive summary is missing %s: %s" % [key, str(summary)])
				return
		var directive_id := String(summary.get("id", ""))
		if not profile_ids.has(directive_id):
			_fail("Active route directive should come from the formal profile catalog: %s" % str(summary))
			return
		if seen_ids.has(directive_id):
			_fail("Active route directives should not duplicate profile ids.")
			return
		seen_ids[directive_id] = true
		if int(summary.get("required", 0)) <= 0 or String(summary.get("reward_text", "")).is_empty():
			_fail("Route directive should expose progress and reward copy: %s" % str(summary))
			return
	_check_completion_and_refill()
	if _failed:
		return
	print("Route directive check passed.")
	get_tree().quit(0)


func _check_completion_and_refill() -> void:
	RunManager.active_route_directives = [{
		"id": "directive_refill_contract",
		"title": "校验航路补位",
		"description": "完成一个节点后更新航路指令。",
		"goal_type": "complete_nodes",
		"target": "",
		"current": 0,
		"required": 1,
		"reward": {"minerals": 17},
		"reward_text": "星髓矿 +17",
	}]
	var node_id := _first_accessible_exploration_node()
	if node_id <= 0 or not RunManager.start_explore_node(node_id):
		_fail("Need an accessible node for directive refill validation.")
		return
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var minerals_before := RunManager.minerals
	var result := RunManager.complete_explore_room_success()
	if Array(result.get("completed_route_directives", [])).size() != 1:
		_fail("Completing the target should settle exactly one route directive: %s" % str(result))
		return
	if RunManager.minerals != minerals_before + 17:
		_fail("Route directive reward should be granted once: %s" % str(result))
		return
	var active_after: Array = RunManager.get_route_directive_summaries()
	if active_after.size() != RunManager.ROUTE_DIRECTIVE_COUNT:
		_fail("Completing a directive should immediately refill the board: %s" % str(active_after))


func _first_accessible_exploration_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		if bool(node.get("completed", false)):
			continue
		if RunManager.is_node_accessible(node_id):
			return node_id
	return -1


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
