extends Node


const REQUIRED_EVENT_COUNT: int = 8
const REQUIRED_CATEGORY_COUNT: int = 5

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_event_catalog_shape()
	if _failed:
		return
	_check_event_result_variety()
	if _failed:
		return
	_check_event_rewards_scale_by_tier()
	if _failed:
		return
	print("Event node variety check passed.")
	get_tree().quit(0)


func _check_event_catalog_shape() -> void:
	if not RunManager.has_method("get_event_profiles"):
		_fail("RunManager should expose get_event_profiles().")
		return
	var profiles: Array = RunManager.get_event_profiles()
	if profiles.size() < REQUIRED_EVENT_COUNT:
		_fail("Event catalog should contain at least %d profiles, got %d." % [REQUIRED_EVENT_COUNT, profiles.size()])
		return
	var categories := {}
	for profile in profiles:
		var id := String(profile.get("id", ""))
		var title := String(profile.get("title", ""))
		var category := String(profile.get("category", ""))
		if id.is_empty() or title.is_empty() or category.is_empty():
			_fail("Every event profile should expose id/title/category.")
			return
		categories[category] = true
	if categories.size() < REQUIRED_CATEGORY_COUNT:
		_fail("Event catalog should cover at least %d categories, got %d." % [REQUIRED_CATEGORY_COUNT, categories.size()])
		return


func _check_event_result_variety() -> void:
	if not RunManager.has_method("resolve_event_node"):
		_fail("RunManager should expose resolve_event_node().")
		return
	var categories := {}
	var seen_ids := {}
	var event_id := _force_accessible_event_node(1)
	for seed in range(18):
		RunManager.start_new_run()
		event_id = _force_accessible_event_node(1)
		var result: Dictionary = RunManager.call("resolve_event_node", event_id, 7000 + seed)
		if not bool(result.get("ok", false)):
			_fail("Forced event node should resolve successfully.")
			return
		var id := String(result.get("event_id", ""))
		var title := String(result.get("event_title", ""))
		var category := String(result.get("event_category", ""))
		if id.is_empty() or title.is_empty() or category.is_empty():
			_fail("Event result should include event_id/event_title/event_category.")
			return
		seen_ids[id] = true
		categories[category] = true
	if seen_ids.size() < 5 or categories.size() < 4:
		_fail("Seeded event results should show variety, ids=%d categories=%d." % [seen_ids.size(), categories.size()])
		return


func _check_event_rewards_scale_by_tier() -> void:
	RunManager.start_new_run()
	var tier1_event := _force_accessible_event_node(1)
	var tier3_event := _force_accessible_event_node(3)
	RunManager.force_next_event_id = "old_supply_chain"
	var tier1_result: Dictionary = RunManager.call("resolve_event_node", tier1_event, 9101)
	var tier1_minerals := int(tier1_result.get("minerals_gained", 0))
	RunManager.start_new_run()
	tier3_event = _force_accessible_event_node(3)
	RunManager.force_next_event_id = "old_supply_chain"
	var tier3_result: Dictionary = RunManager.call("resolve_event_node", tier3_event, 9101)
	var tier3_minerals := int(tier3_result.get("minerals_gained", 0))
	if tier1_minerals <= 0 or tier3_minerals <= tier1_minerals:
		_fail("Same mineral event should scale by tier, tier1=%d tier3=%d." % [tier1_minerals, tier3_minerals])
		return
	if int(tier3_result.get("node_tier", 0)) != 3:
		_fail("Event result should report node tier.")
		return


func _force_accessible_event_node(tier: int) -> int:
	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL or int(node.get("tier", 0)) != tier:
			continue
		node["type"] = RunManager.NODE_EVENT
		node["completed"] = false
		var links: Array = node.get("links", [])
		if not links.has(RunManager.CENTER_ID):
			links.append(RunManager.CENTER_ID)
		node["links"] = links
		RunManager.map_nodes[i] = node
		var base := RunManager.map_nodes[RunManager.CENTER_ID]
		var base_links: Array = base.get("links", [])
		if not base_links.has(node_id):
			base_links.append(node_id)
		base["links"] = base_links
		RunManager.map_nodes[RunManager.CENTER_ID] = base
		return node_id
	return -1


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
