extends Node


const ExploreRoomScript := preload("res://scripts/gameplay/explore/ExploreRoom.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_battle_profile_pressure_config()
	if _failed:
		return
	_check_explore_room_applies_battle_pressure()
	if _failed:
		return
	print("Battle profile pressure check passed.")
	get_tree().quit(0)


func _check_battle_profile_pressure_config() -> void:
	var profiles: Array = RunManager.get_battle_profiles()
	for profile in profiles:
		var room_config: Dictionary = Dictionary(profile).get("room_config", {})
		for key in [
			"family_bias",
			"family_weight_boost",
			"patrol_path_min_count",
			"patrol_path_max_count",
			"elite_replacement_min",
			"elite_replacement_max",
		]:
			if not room_config.has(key):
				_fail("Battle profile %s should define pressure key %s." % [String(Dictionary(profile).get("id", "")), key])
				return
	var node_id := _force_first_battle_node_to_profile(String(Dictionary(profiles[0]).get("id", "")))
	if node_id <= 0:
		_fail("Could not prepare battle node for pressure config inspection.")
		return
	if not RunManager.start_explore_node(node_id):
		_fail("Battle node %d should be startable." % node_id)
		return
	var config := GameManager.next_explore_room_config.duplicate(true)
	RunManager.abandon_current_room()
	if String(config.get("battle_family_bias", "")).is_empty():
		_fail("Battle room config should include battle_family_bias.")
		return
	if float(config.get("battle_family_weight_boost", 0.0)) <= 1.0:
		_fail("Battle room config should include meaningful family boost.")
		return
	if int(config.get("battle_patrol_path_min_count", 0)) < 2:
		_fail("Battle room config should include patrol path pressure.")
		return
	if int(config.get("battle_elite_replacement_max", 0)) < int(config.get("battle_elite_replacement_min", 0)):
		_fail("Battle elite replacement range should be ordered.")
		return


func _check_explore_room_applies_battle_pressure() -> void:
	var room = ExploreRoomScript.new()
	room.setup_room_config({
		"colossus_family_weight": 1.0,
		"paradise_family_weight": 1.0,
		"warped_family_weight": 1.0,
		"hell_eye_family_weight": 1.0,
		"divine_family_weight": 1.0,
		"battle_family_bias": "warped",
		"battle_family_weight_boost": 6.0,
		"battle_patrol_path_min_count": 4,
		"battle_patrol_path_max_count": 6,
		"battle_elite_replacement_min": 3,
		"battle_elite_replacement_max": 5,
	})
	var config: Dictionary = room.get_room_config()
	if float(config.get("warped_family_weight", 0.0)) < 6.0:
		room.free()
		_fail("Battle family bias should boost the targeted family, got %s." % str(config))
		return
	if int(config.get("patrol_path_min_count", 0)) != 4:
		room.free()
		_fail("Battle patrol path minimum should be applied, got %s." % str(config))
		return
	if int(config.get("patrol_path_max_count", 0)) != 6:
		room.free()
		_fail("Battle patrol path maximum should be applied, got %s." % str(config))
		return
	if int(config.get("elite_replacement_min_count", 0)) != 3:
		room.free()
		_fail("Battle elite minimum should be applied, got %s." % str(config))
		return
	if int(config.get("elite_replacement_max_count", 0)) != 5:
		room.free()
		_fail("Battle elite maximum should be applied, got %s." % str(config))
		return
	room.free()


func _force_first_battle_node_to_profile(profile_id: String) -> int:
	var profile := _get_profile_by_id(profile_id)
	if profile.is_empty():
		return -1
	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		node["type"] = RunManager.NODE_BATTLE
		node["completed"] = false
		node["battle_profile_id"] = String(profile.get("id", ""))
		node["battle_title"] = String(profile.get("title", ""))
		node["battle_description"] = String(profile.get("description", ""))
		node["battle_threat"] = int(profile.get("threat", 1))
		node["battle_room_config"] = Dictionary(profile).get("room_config", {}).duplicate(true)
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


func _get_profile_by_id(profile_id: String) -> Dictionary:
	for profile in RunManager.get_battle_profiles():
		if String(Dictionary(profile).get("id", "")) == profile_id:
			return Dictionary(profile).duplicate(true)
	return {}


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
