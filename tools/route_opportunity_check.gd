extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_opportunity_catalog()
	if _failed:
		return
	_check_opportunity_room_config()
	if _failed:
		return
	await _check_world_map_opportunity_details()
	if _failed:
		return
	print("Route opportunity check passed.")
	get_tree().quit(0)


func _check_opportunity_catalog() -> void:
	if not RunManager.has_method("get_opportunity_profiles"):
		_fail("RunManager should expose get_opportunity_profiles().")
		return
	var profiles: Array = RunManager.get_opportunity_profiles()
	if profiles.size() < 8:
		_fail("Route opportunity catalog should provide at least 8 variants, got %d." % profiles.size())
		return
	var tag_count := {}
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		for key in ["id", "title", "description", "effects_text", "room_effect"]:
			if not profile.has(key):
				_fail("Opportunity profile should include %s: %s" % [key, str(profile)])
				return
		for key in ["title", "description", "effects_text"]:
			_assert_chinese_copy(String(profile.get(key, "")), "opportunity %s" % key)
			if _failed:
				return
		var room_effect: Dictionary = profile.get("room_effect", {})
		if room_effect.is_empty():
			_fail("Opportunity should alter room config: %s" % str(profile))
			return
		for raw_tag in Array(profile.get("tags", [])):
			var tag := String(raw_tag)
			_assert_chinese_copy(tag, "opportunity tag")
			if _failed:
				return
			tag_count[tag] = true
	if tag_count.size() < 10:
		_fail("Route opportunities should expose a broad readable tag set, got %d." % tag_count.size())


func _check_opportunity_room_config() -> void:
	var node_id := _first_accessible_exploration_node()
	if node_id <= 0:
		_fail("Need an accessible exploration node for opportunity config check.")
		return
	var opportunity := _profile_by_id("cold_vault_ore")
	if opportunity.is_empty():
		_fail("Missing cold_vault_ore opportunity profile.")
		return
	var node := RunManager.get_map_node(node_id)
	node["opportunity"] = opportunity.duplicate(true)
	node["opportunity_id"] = String(opportunity.get("id", ""))
	node["opportunity_title"] = String(opportunity.get("title", ""))
	node["opportunity_description"] = String(opportunity.get("description", ""))
	node["opportunity_effects_text"] = String(opportunity.get("effects_text", ""))
	node["room_config"] = {
		"large_space_rock_count": 8,
		"trap_count": 4,
		"chest_crystal_count": 10,
		"clutter_count": 24,
		"enemy_spawn_interval": 40.0,
		"max_patrol_enemy_count": 7,
	}
	node["modifiers"] = []
	node["run_conditions"] = []
	node["ore_source_bias"] = ""
	node["battle_room_config"] = {}
	node["reward_room_config"] = {}
	node["risk_level"] = 1
	RunManager.map_nodes[node_id] = node
	if not RunManager.start_explore_node(node_id):
		_fail("Controlled opportunity node should start exploration.")
		return
	var config := GameManager.next_explore_room_config.duplicate(true)
	if int(config.get("chest_crystal_count", 0)) != 14:
		_fail("Cold vault opportunity should add ore targets, got: %s" % str(config))
		return
	if int(config.get("max_patrol_enemy_count", 0)) != 9:
		_fail("Cold vault opportunity should add patrol pressure, got: %s" % str(config))
		return
	var tip := String(config.get("opportunity_tip_text", ""))
	if not tip.contains("航行机会") or not tip.contains("冷舱丰矿"):
		_fail("Opportunity should add loading tip copy, got: %s" % tip)
		return
	if not String(config.get("modifier_tip_text", "")).contains("冷舱丰矿"):
		_fail("Combined loading context should include opportunity title, got: %s" % String(config.get("modifier_tip_text", "")))
		return
	RunManager.abandon_current_room()


func _check_world_map_opportunity_details() -> void:
	var node_id := _first_accessible_exploration_node()
	if node_id <= 0:
		_fail("Need an accessible node for world map opportunity details.")
		return
	var opportunity := _profile_by_id("blueprint_echo")
	if opportunity.is_empty():
		_fail("Missing blueprint_echo opportunity profile.")
		return
	var node := RunManager.get_map_node(node_id)
	node["opportunity"] = opportunity.duplicate(true)
	node["opportunity_id"] = String(opportunity.get("id", ""))
	node["opportunity_title"] = String(opportunity.get("title", ""))
	node["opportunity_description"] = String(opportunity.get("description", ""))
	node["opportunity_effects_text"] = String(opportunity.get("effects_text", ""))
	RunManager.map_nodes[node_id] = node
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
		_fail("World map details body missing.")
		scene.queue_free()
		return
	var details_text := details_body.text
	scene.queue_free()
	if not details_text.contains("航行机会") or not details_text.contains("蓝图回声") or not details_text.contains("装备检出"):
		_fail("World map details should show opportunity title and effects. Details: %s" % details_text)


func _profile_by_id(profile_id: String) -> Dictionary:
	for raw_profile in RunManager.get_opportunity_profiles():
		var profile := Dictionary(raw_profile)
		if String(profile.get("id", "")) == profile_id:
			return profile
	return {}


func _first_accessible_exploration_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		if node_id <= 0 or node_type == RunManager.NODE_SPECIAL or node_type == RunManager.NODE_EVENT:
			continue
		if RunManager.is_node_accessible(node_id):
			return node_id
	return -1


func _assert_chinese_copy(text: String, label: String) -> void:
	if text.strip_edges().is_empty():
		_fail("%s should not be empty." % label)
		return
	for forbidden in ["TODO", "TBD", "placeholder", "debug"]:
		if text.to_lower().contains(forbidden):
			_fail("%s contains design-note copy: %s" % [label, text])
			return
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			_fail("%s should be Chinese player-facing copy, got: %s" % [label, text])
			return


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
