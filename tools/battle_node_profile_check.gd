extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_forced_battle_node_profile_coordinates()
	if _failed:
		return
	_force_battle_nodes_for_profiles()
	_check_battle_node_metadata()
	if _failed:
		return
	_check_battle_room_configs()
	if _failed:
		return
	print("Battle node profile check passed.")
	get_tree().quit(0)


func _check_forced_battle_node_profile_coordinates() -> void:
	var profiles: Array = RunManager.get_battle_profiles()
	if profiles.is_empty():
		_fail("Battle profile library should not be empty.")
		return
	var node_id := 1
	var node := RunManager.get_map_node(node_id)
	if node.is_empty():
		_fail("Need node 1 for forced battle profile coordinate check.")
		return
	node["type"] = RunManager.NODE_BATTLE
	node["completed"] = false
	node.erase("battle_profile_id")
	node.erase("battle_title")
	node.erase("battle_description")
	node.erase("battle_threat")
	node.erase("battle_room_config")
	RunManager.map_nodes[node_id] = node
	if not RunManager.start_explore_node(node_id):
		_fail("Forced battle node should be startable for profile coordinate check.")
		return
	var expected_profile_id := String(Dictionary(profiles[0]).get("id", ""))
	var actual_profile_id := String(RunManager.get_map_node(node_id).get("battle_profile_id", ""))
	RunManager.abandon_current_room()
	if actual_profile_id != expected_profile_id:
		_fail("Forced battle node should use its ring position profile. Expected %s, got %s." % [expected_profile_id, actual_profile_id])


func _force_battle_nodes_for_profiles() -> void:
	var profile_count := int(RunManager.get_battle_profiles().size()) if RunManager.has_method("get_battle_profiles") else 0
	var changed := 0
	for i in range(RunManager.map_nodes.size()):
		if changed >= maxi(4, profile_count):
			return
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		node["type"] = RunManager.NODE_BATTLE
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


func _check_battle_node_metadata() -> void:
	if not RunManager.has_method("get_battle_profiles"):
		_fail("RunManager should expose get_battle_profiles().")
		return
	var profiles: Array = RunManager.get_battle_profiles()
	if profiles.size() < 6:
		_fail("Battle nodes should have at least 6 battle profiles, got %d." % profiles.size())
		return
	var required_keys := ["id", "title", "description", "threat", "room_config"]
	var family_counts := {}
	for profile in profiles:
		var profile_dict := Dictionary(profile)
		for key in required_keys:
			if not profile_dict.has(key):
				_fail("Battle profile should expose key %s: %s" % [key, str(profile)])
				return
		var config: Dictionary = profile_dict.get("room_config", {})
		var family_bias := String(config.get("family_bias", ""))
		family_counts[family_bias] = int(family_counts.get(family_bias, 0)) + 1
	for family in RunManager.FAMILY_BIASES:
		if int(family_counts.get(String(family), 0)) < 3:
			_fail("Battle profile library should include at least 3 tactical tempos for %s." % String(family))
			return
	var profile_ids := {}
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) != RunManager.NODE_BATTLE:
			continue
		var profile_id := String(node.get("battle_profile_id", ""))
		var title := String(node.get("battle_title", ""))
		var description := String(node.get("battle_description", ""))
		var threat := int(node.get("battle_threat", 0))
		if profile_id.is_empty() or title.is_empty() or description.is_empty() or threat <= 0:
			_fail("Battle node %d should carry battle profile metadata." % node_id)
			return
		profile_ids[profile_id] = true
	if profile_ids.size() < 4:
		_fail("Generated battle nodes should use at least 4 distinct battle profiles, got %d." % profile_ids.size())
		return


func _check_battle_room_configs() -> void:
	var seen_configs := {}
	var checked := 0
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) != RunManager.NODE_BATTLE:
			continue
		if not RunManager.start_explore_node(node_id):
			_fail("Battle node %d should be startable for config inspection." % node_id)
			return
		var config := GameManager.next_explore_room_config.duplicate(true)
		RunManager.abandon_current_room()
		var profile_id := String(node.get("battle_profile_id", ""))
		if String(config.get("battle_profile_id", "")) != profile_id:
			_fail("Battle room config should include battle_profile_id for node %d." % node_id)
			return
		if int(config.get("battle_threat", 0)) <= 0:
			_fail("Battle room config should expose battle threat.")
			return
		if int(config.get("battle_max_patrol_enemy_count", 0)) < 5:
			_fail("Battle room config should expose combat density pressure.")
			return
		var signature := "%s:%d:%d:%d" % [
			profile_id,
			int(config.get("battle_max_patrol_enemy_count", 0)),
			int(config.get("battle_trap_pressure", 0)),
			int(round(float(config.get("battle_enemy_spawn_interval", 0.0)))),
		]
		seen_configs[signature] = true
		checked += 1
		if checked >= 6:
			break
	if checked < 4:
		_fail("Need at least 4 battle nodes for config variety check.")
		return
	if seen_configs.size() < 4:
		_fail("Battle room configs should vary by profile.")
		return


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
