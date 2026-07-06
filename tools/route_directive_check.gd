extends Node


const ROUTE_DIRECTIVE_POPUP_PATH := "res://scenes/ui/world_map/RouteDirectivePopup.tscn"

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_directive_generation()
	if _failed:
		return
	_check_directive_completion_reward()
	if _failed:
		return
	await _check_directive_popup()
	if _failed:
		return
	print("Route directive check passed.")
	get_tree().quit(0)


func _check_directive_generation() -> void:
	if not RunManager.has_method("get_route_directive_summaries"):
		_fail("RunManager should expose get_route_directive_summaries().")
		return
	var summaries: Array = RunManager.get_route_directive_summaries()
	if summaries.size() != 3:
		_fail("Each run should begin with exactly 3 route directives, got %d." % summaries.size())
		return
	var goal_types := {}
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		for key in ["directive_id", "title", "description", "progress_text", "reward_text", "goal_type", "current", "required", "completed"]:
			if not summary.has(key):
				_fail("Route directive summary should include %s: %s" % [key, str(summary)])
				return
		for key in ["title", "description", "progress_text", "reward_text"]:
			var text := String(summary.get(key, ""))
			if text.strip_edges().is_empty() or _contains_ascii_letter(text):
				_fail("Route directive %s should be polished Chinese copy, got: %s" % [key, text])
				return
		if int(summary.get("required", 0)) <= 0:
			_fail("Route directive should define a positive target: %s" % str(summary))
			return
		goal_types[String(summary.get("goal_type", ""))] = true
	if goal_types.size() < 2:
		_fail("Route directives should create mixed goals in one run, got: %s" % str(goal_types.keys()))


func _check_directive_completion_reward() -> void:
	if not "active_route_directives" in RunManager:
		_fail("RunManager should keep active_route_directives for run state persistence.")
		return
	RunManager.start_new_run()
	RunManager.active_route_directives = [
		{
			"directive_id": "test_cleanup_order",
			"title": "清扫前哨航线",
			"description": "方舟要求先清出一段稳定航线，让后续回收队能够跟上。",
			"goal_type": "complete_nodes",
			"target": "",
			"current": 0,
			"required": 1,
			"reward": {"minerals": 33, "compute": 1},
			"reward_text": "星髓矿与算力补给",
			"completed": false,
			"claimed": false,
		},
	]
	var node_id := _first_accessible_exploration_node()
	if node_id <= 0:
		_fail("Need an accessible node for directive completion check.")
		return
	if not RunManager.start_explore_node(node_id):
		_fail("Accessible node should start exploration.")
		return
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var result: Dictionary = RunManager.complete_explore_room_success()
	if not bool(result.get("ok", false)):
		_fail("Completing a node should succeed for directive check: %s" % str(result))
		return
	var completed: Array = result.get("completed_route_directives", [])
	if completed.size() != 1:
		_fail("Completing the directive target should report one completed route directive: %s" % str(result))
		return
	var new_directives: Array = result.get("new_route_directives", [])
	if new_directives.size() < 1:
		_fail("Completing a route directive should refill a new active directive: %s" % str(result))
		return
	if RunManager.get_route_directive_summaries().size() != RunManager.ROUTE_DIRECTIVE_COUNT:
		_fail("Route directive board should stay filled after completion: %s" % str(RunManager.get_route_directive_summaries()))
		return
	for raw_summary in RunManager.get_route_directive_summaries():
		var active_summary := Dictionary(raw_summary)
		if String(active_summary.get("directive_id", "")) == "test_cleanup_order":
			_fail("Completed directive should retire from the active board: %s" % str(RunManager.get_route_directive_summaries()))
			return
	var finished := Dictionary(completed[0])
	if String(finished.get("title", "")) != "清扫前哨航线":
		_fail("Completed route directive should preserve player-facing title: %s" % str(finished))
		return
	if RunManager.minerals < 33:
		_fail("Route directive mineral reward should be granted, got %d." % RunManager.minerals)
		return
	if RunManager.compute_capacity < 7:
		_fail("Route directive compute reward should stack with node completion, got %d." % RunManager.compute_capacity)
		return
	var next_id := _first_accessible_exploration_node()
	if next_id <= 0:
		return
	var minerals_after_first := RunManager.minerals
	if not RunManager.start_explore_node(next_id):
		return
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var second: Dictionary = RunManager.complete_explore_room_success()
	for raw_directive in Array(second.get("completed_route_directives", [])):
		if String(Dictionary(raw_directive).get("directive_id", "")) == "test_cleanup_order":
			_fail("Completed route directive should not pay out twice: %s" % str(second))
			return
	if RunManager.minerals != minerals_after_first:
		for raw_directive in Array(second.get("completed_route_directives", [])):
			if String(Dictionary(raw_directive).get("directive_id", "")) == "test_cleanup_order":
				_fail("Completed route directive should not grant duplicate minerals.")
				return


func _check_directive_popup() -> void:
	var packed := load(ROUTE_DIRECTIVE_POPUP_PATH) as PackedScene
	if packed == null:
		_fail("Route directive popup scene should exist at %s." % ROUTE_DIRECTIVE_POPUP_PATH)
		return
	var popup := packed.instantiate()
	add_child(popup)
	popup.call("setup", {
		"completed_directives": [
			{
				"title": "清扫前哨航线",
				"description": "方舟航线已经稳定。",
				"progress_text": "进度已完成",
				"reward_text": "星髓矿与算力补给",
			},
		],
		"new_directives": [
			{
				"title": "回收奖励缓存",
				"progress_text": "进度 0/1",
				"reward_text": "星髓矿 +48",
			},
		],
	})
	await get_tree().process_frame
	var title_label := popup.get_node_or_null("Panel/TitleLabel") as Label
	var body_label := popup.get_node_or_null("Panel/BodyLabel") as RichTextLabel
	if title_label == null or not title_label.text.contains("航路指令"):
		_fail("Route directive popup should expose a title.")
		popup.queue_free()
		return
	if body_label == null or not body_label.text.contains("清扫前哨航线") or not body_label.text.contains("星髓矿") or not body_label.text.contains("新航路指令") or not body_label.text.contains("回收奖励缓存"):
		_fail("Route directive popup should render directive reward copy.")
		popup.queue_free()
		return
	popup.queue_free()


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


func _contains_ascii_letter(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
