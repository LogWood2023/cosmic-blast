extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_route_plan_metadata()
	if _failed:
		return
	await _check_world_map_details()
	if _failed:
		return
	print("World map route plan check passed.")
	get_tree().quit(0)


func _check_route_plan_metadata() -> void:
	var checked_count := 0
	var families := {}
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		if node_id <= 0 or node_type == RunManager.NODE_SPECIAL:
			continue
		var plan: Dictionary = node.get("route_plan", {})
		if plan.is_empty():
			_fail("Node %d should expose route_plan metadata." % node_id)
			return
		for key in ["title", "summary", "family_name", "reward_hint", "equipment_hint", "tactic_hint"]:
			var text := String(plan.get(key, "")).strip_edges()
			if text.is_empty():
				_fail("Node %d route_plan should include %s." % [node_id, key])
				return
			if _contains_ascii_identifier(text):
				_fail("Node %d route_plan %s should read like Chinese game copy: %s" % [node_id, key, text])
				return
		var family := String(plan.get("family", ""))
		if family.is_empty():
			_fail("Node %d route_plan should record family." % node_id)
			return
		var tactic_hint := String(plan.get("tactic_hint", ""))
		var expected_keyword := _family_tactic_keyword(family)
		if expected_keyword.is_empty() or not tactic_hint.contains(expected_keyword):
			_fail("Node %d route_plan tactic hint should include %s, got: %s" % [node_id, expected_keyword, tactic_hint])
			return
		families[family] = true
		checked_count += 1
	if checked_count < 32:
		_fail("Route plan check expected all branching-map nodes, got %d nodes." % checked_count)
		return
	for family in RunManager.FAMILY_BIASES:
		if not families.has(String(family)):
			_fail("Route plans should cover family %s in one generated map." % String(family))
			return


func _check_world_map_details() -> void:
	var node_id := _pick_accessible_non_special_node()
	if node_id <= 0:
		_fail("Need an accessible node for route plan detail check.")
		return
	var scene := WORLD_MAP_SCENE.instantiate()
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	var world_map := scene.get_node_or_null("WorldMap")
	if world_map == null:
		_fail("WorldMap scene should expose a WorldMap node.")
		scene.queue_free()
		return
	world_map.set("_selected_node_id", node_id)
	world_map.call("_refresh_all")
	var details_body := world_map.get_node_or_null("DetailsPanel/DetailsBody") as RichTextLabel
	if details_body == null:
		_fail("WorldMap details body missing.")
		scene.queue_free()
		return
	var details_text := details_body.text
	scene.queue_free()
	var plan: Dictionary = RunManager.get_map_node(node_id).get("route_plan", {})
	var tactic_hint := String(plan.get("tactic_hint", ""))
	for expected in ["航路预案", "流派", "推荐战法", "回收", "装备"]:
		if not details_text.contains(expected):
			_fail("World map details should show route plan text containing %s. Details: %s" % [expected, details_text])
			return
	if tactic_hint.is_empty() or not details_text.contains(tactic_hint):
		_fail("World map details should show route tactic hint. Expected: %s Details: %s" % [tactic_hint, details_text])
		return


func _pick_accessible_non_special_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		if RunManager.is_node_accessible(node_id):
			return node_id
	return -1


func _contains_ascii_identifier(text: String) -> bool:
	for token in ["colossus", "paradise", "warped", "hell_eye", "divine", "route_plan", "family_bias", "_"]:
		if text.contains(token):
			return true
	return false


func _family_tactic_keyword(family: String) -> String:
	match family:
		"colossus":
			return "冲锋"
		"paradise":
			return "火力"
		"warped":
			return "引力"
		"hell_eye":
			return "狂热"
		"divine":
			return "僚机"
	return "通用"


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
