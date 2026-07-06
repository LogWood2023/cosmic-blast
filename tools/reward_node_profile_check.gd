extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_force_reward_nodes_for_profiles()
	_check_reward_node_metadata()
	if _failed:
		return
	_check_reward_room_configs()
	if _failed:
		return
	_check_reward_cache_family_bias()
	if _failed:
		return
	print("Reward node profile check passed.")
	get_tree().quit(0)


func _force_reward_nodes_for_profiles() -> void:
	var profile_count := int(RunManager.get_reward_profiles().size()) if RunManager.has_method("get_reward_profiles") else 0
	var changed := 0
	for i in range(RunManager.map_nodes.size()):
		if changed >= maxi(3, profile_count):
			return
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		node["type"] = RunManager.NODE_REWARD
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
		RunManager.start_explore_node(node_id)
		RunManager.abandon_current_room()
		changed += 1


func _check_reward_node_metadata() -> void:
	if not RunManager.has_method("get_reward_profiles"):
		_fail("RunManager should expose get_reward_profiles().")
		return
	var profiles: Array = RunManager.get_reward_profiles()
	if profiles.size() < 5:
		_fail("Reward nodes should have at least 5 reward profiles, got %d." % profiles.size())
		return
	var required_keys := ["id", "title", "description", "room_config", "reward_mult_bonus", "equipment_chance_bonus", "cache_family_bias"]
	for profile in profiles:
		for key in required_keys:
			if not Dictionary(profile).has(key):
				_fail("Reward profile should expose key %s: %s" % [key, str(profile)])
				return
	var profile_ids := {}
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) != RunManager.NODE_REWARD:
			continue
		var profile_id := String(node.get("reward_profile_id", ""))
		var title := String(node.get("reward_title", ""))
		var description := String(node.get("reward_description", ""))
		if profile_id.is_empty() or title.is_empty() or description.is_empty():
			_fail("Reward node %d should carry reward profile metadata." % node_id)
			return
		profile_ids[profile_id] = true
	if profile_ids.size() < 3:
		_fail("Generated reward nodes should use at least 3 distinct reward profiles, got %d." % profile_ids.size())
		return


func _check_reward_room_configs() -> void:
	var seen_configs := {}
	var checked := 0
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) != RunManager.NODE_REWARD:
			continue
		if not RunManager.start_explore_node(node_id):
			_fail("Reward node %d should be startable for config inspection." % node_id)
			return
		var config := GameManager.next_explore_room_config.duplicate(true)
		RunManager.abandon_current_room()
		var profile_id := String(node.get("reward_profile_id", ""))
		if String(config.get("reward_profile_id", "")) != profile_id:
			_fail("Reward room config should include reward_profile_id for node %d." % node_id)
			return
		if int(config.get("chest_crystal_count", 0)) < 12:
			_fail("Reward room should keep a high chest/crystal floor.")
			return
		if float(config.get("reward_mineral_mult", 0.0)) <= 1.0:
			_fail("Reward room config should expose a mineral multiplier.")
			return
		var signature := "%s:%d:%d:%d" % [
			profile_id,
			int(config.get("chest_crystal_count", 0)),
			int(config.get("large_space_rock_count", 0)),
			int(config.get("trap_count", 0)),
		]
		seen_configs[signature] = true
		checked += 1
		if checked >= 5:
			break
	if checked < 3:
		_fail("Need at least 3 reward nodes for config variety check.")
		return
	if seen_configs.size() < 3:
		_fail("Reward room configs should vary by profile.")
		return


func _check_reward_cache_family_bias() -> void:
	RunManager.start_new_run()
	var reward_id := _force_reward_node_with_cache_family(EquipmentCatalogScript.FAMILY_WARPED)
	if reward_id <= 0:
		_fail("Need a forced warped reward node for cache family bias check.")
		return
	var node := RunManager.get_map_node(reward_id)
	if String(node.get("cache_family_bias", "")) != EquipmentCatalogScript.FAMILY_WARPED:
		_fail("Reward node should expose cache_family_bias on map metadata: %s" % str(node))
		return
	if not RunManager.start_explore_node(reward_id):
		_fail("Forced reward node should start exploration.")
		return
	if String(GameManager.next_explore_room_config.get("reward_cache_family_bias", "")) != EquipmentCatalogScript.FAMILY_WARPED:
		_fail("Reward room config should carry reward_cache_family_bias.")
		return
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var previous_inventory: Array[String] = RunManager.equipment_inventory.duplicate()
	var node_copy := RunManager.map_nodes[reward_id]
	node_copy["equipment_drop_chance"] = 1.0
	RunManager.map_nodes[reward_id] = node_copy
	for _i in range(6):
		RunManager.record_reward_broken(0)
	var equipment: Array = RunManager.pending_room_loot.get("equipment", [])
	RunManager.equipment_inventory = previous_inventory
	RunManager.abandon_current_room()
	if equipment.is_empty():
		_fail("Forced reward cache should produce at least one equipment item.")
		return
	for item_id in equipment:
		if EquipmentCatalogScript.get_family(String(item_id)) != EquipmentCatalogScript.FAMILY_WARPED:
			_fail("Reward cache equipment should follow cache family bias, got %s family=%s." % [String(item_id), EquipmentCatalogScript.get_family(String(item_id))])
			return


func _force_reward_node_with_cache_family(cache_family: String) -> int:
	var profiles: Array = RunManager.get_reward_profiles()
	var picked_profile := {}
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		if String(profile.get("cache_family_bias", "")) == cache_family:
			picked_profile = profile
			break
	if picked_profile.is_empty():
		return -1
	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		node["type"] = RunManager.NODE_REWARD
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
		RunManager.call("_apply_reward_profile_data_to_node", node, picked_profile)
		RunManager.map_nodes[i] = node
		return node_id
	return -1


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
