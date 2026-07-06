extends Node


const BASE_ROOM_CONFIG := {
	"large_space_rock_count": 12,
	"trap_count": 4,
	"chest_crystal_count": 12,
	"clutter_count": 32,
	"enemy_spawn_interval": 50.0,
	"max_patrol_enemy_count": 8,
	"reward_mineral_mult": 1.0,
}

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_ore_source_catalog_effects()
	if _failed:
		return
	_check_room_config_effects()
	if _failed:
		return
	print("Ore source room profile check passed.")
	get_tree().quit(0)


func _check_ore_source_catalog_effects() -> void:
	var effects_seen := {}
	for raw_profile in RunManager.ORE_SOURCE_BIAS_PROFILES:
		var profile := Dictionary(raw_profile)
		var source_id := String(profile.get("id", ""))
		var effect: Dictionary = profile.get("room_effect", {})
		var effect_text := String(profile.get("room_effect_text", ""))
		if effect.is_empty():
			_fail("Ore source %s should expose room_effect." % source_id)
			return
		_assert_chinese_copy(effect_text, "ore source room effect text")
		if _failed:
			return
		effects_seen[str(effect)] = true
	if effects_seen.size() < RunManager.ORE_SOURCE_BIAS_PROFILES.size():
		_fail("Ore source room effects should be distinct, got %d variants." % effects_seen.size())


func _check_room_config_effects() -> void:
	var star := _controlled_config_for_source("star_marrow")
	if _failed:
		return
	if float(star.get("reward_mineral_mult", 0.0)) < 1.04:
		_fail("Star marrow should add stable mineral yield, got: %s" % str(star))
		return
	if int(star.get("clutter_count", 0)) < int(BASE_ROOM_CONFIG["clutter_count"]) + 4:
		_fail("Star marrow should add salvage clutter, got: %s" % str(star))
		return

	var gleam := _controlled_config_for_source("gleam_crystal")
	if _failed:
		return
	if int(gleam.get("chest_crystal_count", 0)) < int(BASE_ROOM_CONFIG["chest_crystal_count"]) + 3:
		_fail("Gleam crystal should add more bright ore targets, got: %s" % str(gleam))
		return
	if float(gleam.get("reward_mineral_mult", 0.0)) < 1.06:
		_fail("Gleam crystal should raise mineral payout, got: %s" % str(gleam))
		return

	var rift := _controlled_config_for_source("rift_cluster")
	if _failed:
		return
	if int(rift.get("clutter_count", 0)) < int(BASE_ROOM_CONFIG["clutter_count"]) + 8:
		_fail("Rift cluster should scatter more salvage fragments, got: %s" % str(rift))
		return
	if int(rift.get("max_patrol_enemy_count", 0)) < int(BASE_ROOM_CONFIG["max_patrol_enemy_count"]) + 1:
		_fail("Rift cluster should add light patrol pressure, got: %s" % str(rift))
		return
	if float(rift.get("enemy_spawn_interval", 999.0)) > float(BASE_ROOM_CONFIG["enemy_spawn_interval"]) - 3.0:
		_fail("Rift cluster should speed up patrol response, got: %s" % str(rift))
		return

	var deep := _controlled_config_for_source("deep_core")
	if _failed:
		return
	if int(deep.get("chest_crystal_count", 99)) > int(BASE_ROOM_CONFIG["chest_crystal_count"]) - 2:
		_fail("Deep core should trade ore count for higher value, got: %s" % str(deep))
		return
	if float(deep.get("reward_mineral_mult", 0.0)) < 1.18:
		_fail("Deep core should sharply raise mineral payout, got: %s" % str(deep))
		return
	if int(deep.get("trap_count", 0)) < int(BASE_ROOM_CONFIG["trap_count"]) + 3:
		_fail("Deep core should add hazard pressure, got: %s" % str(deep))
		return
	if int(deep.get("max_patrol_enemy_count", 0)) < int(BASE_ROOM_CONFIG["max_patrol_enemy_count"]) + 2:
		_fail("Deep core should add patrol pressure, got: %s" % str(deep))
		return


func _controlled_config_for_source(source_id: String) -> Dictionary:
	RunManager.abandon_current_room()
	var node_id := _first_accessible_node()
	if node_id <= 0:
		_fail("Need an accessible node for ore-source config check.")
		return {}
	var profile := _source_profile(source_id)
	if profile.is_empty():
		_fail("Missing source profile %s." % source_id)
		return {}
	var node := RunManager.get_map_node(node_id)
	node["type"] = RunManager.NODE_BATTLE
	node["completed"] = false
	node["risk_level"] = 1
	node["tier"] = 1
	node["room_config"] = BASE_ROOM_CONFIG.duplicate(true)
	node["modifiers"] = []
	node["run_conditions"] = []
	node["opportunity"] = {}
	node["opportunity_id"] = ""
	node["opportunity_title"] = ""
	node["opportunity_description"] = ""
	node["opportunity_effects_text"] = ""
	node["battle_profile_id"] = "测试态势"
	node["battle_room_config"] = {}
	node["reward_room_config"] = {}
	node["ore_source_bias"] = source_id
	node["ore_source_name"] = String(profile.get("name", ""))
	node["ore_source_label"] = String(profile.get("label", ""))
	node["ore_source_hint"] = String(profile.get("hint", ""))
	node["ore_source_weight"] = float(profile.get("weight", 2.4))
	node["ore_source_room_effect"] = Dictionary(profile.get("room_effect", {})).duplicate(true)
	node["ore_source_room_effect_text"] = String(profile.get("room_effect_text", ""))
	RunManager.map_nodes[node_id] = node
	if not RunManager.start_explore_node(node_id):
		_fail("Controlled node should start exploration for %s." % source_id)
		return {}
	return GameManager.next_explore_room_config.duplicate(true)


func _source_profile(source_id: String) -> Dictionary:
	for raw_profile in RunManager.ORE_SOURCE_BIAS_PROFILES:
		var profile := Dictionary(raw_profile)
		if String(profile.get("id", "")) == source_id:
			return profile
	return {}


func _first_accessible_node() -> int:
	for node in RunManager.map_nodes:
		var id := int(node.get("id", -1))
		if id > 0 and String(node.get("type", "")) != RunManager.NODE_SPECIAL and RunManager.is_node_accessible(id):
			return id
	return -1


func _assert_chinese_copy(text: String, label: String) -> void:
	if text.strip_edges().is_empty():
		_fail("%s should not be empty." % label)
		return
	for forbidden in ["TODO", "TBD", "需求", "说明", "placeholder", "debug"]:
		if text.to_lower().contains(forbidden.to_lower()):
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
