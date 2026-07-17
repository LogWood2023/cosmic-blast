extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_condition_catalog()
	if _failed:
		return
	_check_run_condition_selection()
	if _failed:
		return
	_check_node_condition_effects()
	if _failed:
		return
	await _check_world_map_condition_copy()
	if _failed:
		return
	print("Run condition variety check passed.")
	get_tree().quit(0)


func _check_condition_catalog() -> void:
	if not RunManager.has_method("get_run_condition_profiles"):
		_fail("RunManager should expose get_run_condition_profiles().")
		return
	var catalog: Array = RunManager.get_run_condition_profiles()
	if catalog.size() < 8:
		_fail("Run condition catalog should contain at least 8 global run conditions, got %d." % catalog.size())
		return
	var categories := {}
	for raw_condition in catalog:
		var condition := Dictionary(raw_condition)
		for key in ["id", "title", "description", "effects_text"]:
			if String(condition.get(key, "")).strip_edges().is_empty():
				_fail("Run condition should expose %s: %s" % [key, str(condition)])
				return
		if _contains_ascii_identifier(String(condition.get("title", "")) + String(condition.get("description", "")) + String(condition.get("effects_text", ""))):
			_fail("Run condition copy should be Chinese-facing text: %s" % str(condition))
			return
		categories[String(condition.get("category", ""))] = true
	if categories.size() < 5:
		_fail("Run conditions should cover at least 5 categories, got %d." % categories.size())
		return


func _check_run_condition_selection() -> void:
	if not RunManager.has_method("get_active_run_condition_summaries"):
		_fail("RunManager should expose get_active_run_condition_summaries().")
		return
	var summaries: Array = RunManager.get_active_run_condition_summaries()
	if summaries.size() < 2:
		_fail("A new run should select at least two active run conditions, got %d." % summaries.size())
		return
	var ids := {}
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		var condition_id := String(summary.get("id", ""))
		if condition_id.is_empty() or ids.has(condition_id):
			_fail("Active run conditions should use distinct ids: %s" % str(summaries))
			return
		ids[condition_id] = true
		for key in ["title", "description", "effects_text"]:
			if String(summary.get(key, "")).strip_edges().is_empty():
				_fail("Active condition summary should include %s: %s" % [key, str(summary)])
				return


func _check_node_condition_effects() -> void:
	var node_id := _pick_accessible_explore_node()
	if node_id <= 0:
		_fail("Need an accessible exploration node for run condition check.")
		return
	var node := RunManager.get_map_node(node_id)
	var run_conditions: Array = node.get("run_conditions", [])
	if run_conditions.size() < 2:
		_fail("Exploration nodes should record active run conditions, got: %s" % str(node))
		return
	var has_room_config := false
	var has_reward_or_equipment := false
	for raw_condition in run_conditions:
		var condition := Dictionary(raw_condition)
		if not Dictionary(condition.get("room_config", {})).is_empty():
			has_room_config = true
		if absf(float(condition.get("reward_mult_bonus", 0.0))) > 0.0 or absf(float(condition.get("equipment_chance_bonus", 0.0))) > 0.0:
			has_reward_or_equipment = true
	if not has_room_config:
		_fail("At least one active run condition should alter explore room config.")
		return
	if not has_reward_or_equipment:
		_fail("At least one active run condition should alter reward or equipment pacing.")
		return
	if float(node.get("reward_mult", 1.0)) <= 1.0 and float(node.get("equipment_drop_chance", 0.0)) <= 0.35:
		_fail("Run conditions should visibly alter node reward/equipment values: %s" % str(node))
		return
	if not RunManager.start_explore_node(node_id):
		_fail("Accessible node should start exploration for condition config check.")
		return
	var config := GameManager.next_explore_room_config.duplicate(true)
	if not config.has("run_condition_tip_text"):
		_fail("Explore config should include run_condition_tip_text, got: %s" % str(config))
		return
	if not String(config.get("run_condition_tip_text", "")).contains("航域态势"):
		_fail("Run condition tip should be visible Chinese copy, got: %s" % String(config.get("run_condition_tip_text", "")))
		return
	if not config.has("run_condition_summary_text"):
		_fail("Explore config should include run_condition_summary_text, got: %s" % str(config))
		return
	RunManager.abandon_current_room()


func _check_world_map_condition_copy() -> void:
	var node_id := _pick_accessible_explore_node()
	if node_id <= 0:
		_fail("Need an accessible exploration node for world map condition copy.")
		return
	var scene_root := WORLD_MAP_SCENE.instantiate()
	add_child(scene_root)
	await get_tree().process_frame
	var popup := scene_root.get_node_or_null("WorldMap")
	if popup == null:
		_fail("World map scene should expose the WorldMap UI child.")
		scene_root.queue_free()
		return
	popup.set("_selected_node_id", node_id)
	popup.call("_refresh_details")
	var body := popup.get_node_or_null("UIRoot/MainPanel/DetailsBody") as RichTextLabel
	if body == null:
		body = popup.find_child("DetailsBody", true, false) as RichTextLabel
	if body == null:
		_fail("World map should expose DetailsBody for condition copy.")
		scene_root.queue_free()
		return
	if not body.text.contains("航域态势"):
		_fail("World map details should show run condition copy. Details: %s" % body.text)
		scene_root.queue_free()
		return
	if _contains_ascii_identifier(body.text):
		_fail("World map condition details should hide internal ids: %s" % body.text)
		scene_root.queue_free()
		return
	scene_root.queue_free()


func _pick_accessible_explore_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		if node_id > 0 and node_type != RunManager.NODE_SPECIAL and RunManager.is_node_accessible(node_id):
			return node_id
	return -1


func _contains_ascii_identifier(text: String) -> bool:
	for token in ["condition", "run_", "reward_mult", "equipment", "storm", "protocol", "category"]:
		if text.contains(token):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
