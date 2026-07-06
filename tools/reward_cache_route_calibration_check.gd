extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var ids := _force_reward_node_and_route_target(EquipmentCatalogScript.FAMILY_PARADISE)
	var reward_id := int(ids.get("reward_id", -1))
	var target_id := int(ids.get("target_id", -1))
	if reward_id <= 0 or target_id <= 0:
		_fail("Need a reward cache and adjacent route target for calibration check.")
		return
	var choices: Array = RunManager.prepare_reward_cache_choices(reward_id, 4401)
	var family_choice := _find_choice_by_type(choices, "family")
	var choice_id := String(family_choice.get("choice_id", ""))
	if choice_id.is_empty():
		_fail("Need a family cache choice for route calibration check.")
		return
	var result: Dictionary = RunManager.start_reward_cache_choice(reward_id, choice_id, 5501)
	if not bool(result.get("ok", false)):
		_fail("Starting family reward cache should succeed: %s" % str(result))
		return
	_check_route_calibration_result(result, target_id)
	if _failed:
		return
	await _check_world_map_details(target_id)
	if _failed:
		return
	_check_calibrated_route_explore_config(target_id)
	if _failed:
		return
	print("Reward cache route calibration check passed.")
	get_tree().quit(0)


func _check_route_calibration_result(result: Dictionary, target_id: int) -> void:
	if int(result.get("calibrated_route_count", 0)) <= 0:
		_fail("Family reward cache should report calibrated adjacent routes: %s" % str(result))
		return
	var routes: Array = result.get("reward_cache_calibrated_routes", [])
	var found_target := false
	for raw_route in routes:
		var route := Dictionary(raw_route)
		if int(route.get("node_id", -1)) == target_id:
			found_target = true
			for key in ["node_name", "family_name", "calibration_text"]:
				var text := String(route.get(key, "")).strip_edges()
				if text.is_empty() or _contains_ascii_identifier(text):
					_fail("Calibrated route summary should expose Chinese copy for %s: %s" % [key, str(route)])
					return
	if not found_target:
		_fail("Calibration result should list the adjacent target route: %s" % str(routes))
		return
	var target := RunManager.get_map_node(target_id)
	var calibration: Dictionary = target.get("reward_cache_route_calibration", {})
	if calibration.is_empty():
		_fail("Adjacent route should store reward_cache_route_calibration metadata.")
		return
	if String(calibration.get("family_bias", "")) != EquipmentCatalogScript.FAMILY_PARADISE:
		_fail("Route calibration should inherit cache family, got: %s" % str(calibration))
		return
	if RunManager.get_node_family_bias(target_id) != EquipmentCatalogScript.FAMILY_PARADISE:
		_fail("Route calibration should redirect target family bias.")
		return
	var plan: Dictionary = target.get("route_plan", {})
	if String(plan.get("family", "")) != EquipmentCatalogScript.FAMILY_PARADISE:
		_fail("Route plan should be regenerated toward calibrated family: %s" % str(plan))
		return


func _check_world_map_details(target_id: int) -> void:
	var scene := WORLD_MAP_SCENE.instantiate()
	add_child(scene)
	await get_tree().process_frame
	var world_map := scene.get_node_or_null("WorldMap")
	if world_map == null:
		_fail("WorldMap scene should expose a WorldMap node.")
		scene.queue_free()
		return
	world_map.set("_selected_node_id", target_id)
	world_map.call("_refresh_details")
	var details_body := world_map.get_node_or_null("DetailsPanel/DetailsBody") as RichTextLabel
	if details_body == null:
		_fail("World map details body missing.")
		scene.queue_free()
		return
	var text := details_body.text
	scene.queue_free()
	for expected in ["缓存校准", "天堂号", "货单导向", "流派倾向"]:
		if not text.contains(expected):
			_fail("World map details should show reward cache route calibration %s. Details: %s" % [expected, text])
			return
	if text.contains("reward_cache") or text.contains("cache_family"):
		_fail("World map details should hide reward cache calibration internal ids: %s" % text)


func _check_calibrated_route_explore_config(target_id: int) -> void:
	RunManager.abandon_current_room()
	if not RunManager.start_explore_node(target_id):
		_fail("Calibrated adjacent route should still be enterable.")
		return
	var config := GameManager.next_explore_room_config.duplicate(true)
	var family_key := "%s_family_weight" % EquipmentCatalogScript.FAMILY_PARADISE
	if float(config.get(family_key, 0.0)) < RunManager.EXPLORE_FAMILY_WEIGHT_BOOST:
		_fail("Calibrated route should push family battle weight into room config: %s" % str(config))
		return
	var tip := String(config.get("modifier_tip_text", ""))
	if tip.is_empty() or not tip.contains("缓存校准") or not tip.contains("天堂号"):
		_fail("Calibrated route should add loading modifier copy, got: %s config=%s" % [tip, str(config)])
		return
	if String(RunManager.get_map_node(target_id).get("type", "")) == RunManager.NODE_REWARD:
		if String(config.get("reward_cache_family_bias", "")) != EquipmentCatalogScript.FAMILY_PARADISE:
			_fail("Calibrated reward route should bias reward cache family: %s" % str(config))
			return


func _find_choice_by_type(choices: Array, cache_type: String) -> Dictionary:
	for raw_choice in choices:
		var choice := Dictionary(raw_choice)
		if String(choice.get("cache_type", "")) == cache_type:
			return choice
	return {}


func _force_reward_node_and_route_target(cache_family: String) -> Dictionary:
	var reward_id := -1
	var target_id := -1
	var picked_profile := {}
	for raw_profile in RunManager.get_reward_profiles():
		var profile := Dictionary(raw_profile)
		if String(profile.get("cache_family_bias", "")) == cache_family:
			picked_profile = profile
			break
	if picked_profile.is_empty():
		return {}
	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		reward_id = node_id
		node["type"] = RunManager.NODE_REWARD
		node["completed"] = false
		var links: Array = node.get("links", [])
		if not links.has(RunManager.CENTER_ID):
			links.append(RunManager.CENTER_ID)
		node["links"] = links
		RunManager.call("_apply_reward_profile_data_to_node", node, picked_profile)
		RunManager.map_nodes[i] = node
		var base := RunManager.map_nodes[RunManager.CENTER_ID]
		var base_links: Array = base.get("links", [])
		if not base_links.has(node_id):
			base_links.append(node_id)
		base["links"] = base_links
		RunManager.map_nodes[RunManager.CENTER_ID] = base
		break
	if reward_id <= 0:
		return {}
	for i in range(RunManager.map_nodes.size()):
		var target := RunManager.map_nodes[i]
		var id := int(target.get("id", -1))
		if id <= 0 or id == reward_id or String(target.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		target_id = id
		target["completed"] = false
		target["family_bias"] = EquipmentCatalogScript.FAMILY_COLOSSUS
		target.erase("beacon_echo")
		target.erase("reward_cache_route_calibration")
		RunManager.call("_apply_route_plan_to_node", target)
		RunManager.map_nodes[i] = target
		RunManager.call("_add_link", reward_id, target_id)
		break
	return {"reward_id": reward_id, "target_id": target_id}


func _contains_ascii_identifier(text: String) -> bool:
	for token in ["colossus", "paradise", "warped", "hell_eye", "divine", "reward_cache", "cache_family", "family_bias", "_"]:
		if text.contains(token):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
