extends Node


const MIN_INTEL_PROFILES: int = 12
const MIN_BATTLE_PROFILES: int = 15
const MIN_REWARD_PROFILES: int = 10
const MIN_EVENT_PROFILES: int = 16
const MIN_MODIFIER_PROFILES: int = 16
const MIN_SPECIAL_BONUS_PROFILES: int = 12

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_intel_profiles()
	if _failed:
		return
	_check_battle_profiles()
	if _failed:
		return
	_check_reward_profiles()
	if _failed:
		return
	_check_event_profiles()
	if _failed:
		return
	_check_modifier_profiles()
	if _failed:
		return
	_check_special_bonus_profiles()
	if _failed:
		return
	print("Run content scale check passed.")
	get_tree().quit(0)


func _check_intel_profiles() -> void:
	var profile_ids := {}
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		_assert_chinese_copy(String(node.get("intel_title", "")), "intel_title")
		_assert_chinese_copy(String(node.get("intel_description", "")), "intel_description")
		if _failed:
			return
		var room_config: Dictionary = node.get("room_config", {})
		for key in ["large_space_rock_count", "trap_count", "chest_crystal_count", "clutter_count", "enemy_spawn_interval", "max_patrol_enemy_count"]:
			if not room_config.has(key):
				_fail("Intel profile on node %d should include room config key %s." % [node_id, key])
				return
		profile_ids[String(node.get("intel_id", ""))] = true
	if profile_ids.size() < MIN_INTEL_PROFILES:
		_fail("World map should sample at least %d intel profiles in one run, got %d." % [MIN_INTEL_PROFILES, profile_ids.size()])


func _check_battle_profiles() -> void:
	var profiles: Array = RunManager.get_battle_profiles()
	if profiles.size() < MIN_BATTLE_PROFILES:
		_fail("Battle profile library should contain at least %d profiles, got %d." % [MIN_BATTLE_PROFILES, profiles.size()])
		return
	var families := {}
	var family_counts := {}
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		_assert_chinese_copy(String(profile.get("title", "")), "battle title")
		_assert_chinese_copy(String(profile.get("description", "")), "battle description")
		if _failed:
			return
		var config: Dictionary = profile.get("room_config", {})
		var family_bias := String(config.get("family_bias", ""))
		families[family_bias] = true
		family_counts[family_bias] = int(family_counts.get(family_bias, 0)) + 1
		if int(profile.get("threat", 0)) <= 0 or int(config.get("max_patrol_enemy_count", 0)) < 5:
			_fail("Battle profile should expose threat and enemy pressure: %s" % str(profile))
			return
	for family in RunManager.FAMILY_BIASES:
		if not families.has(String(family)):
			_fail("Battle profiles should cover family bias %s." % String(family))
			return
		if int(family_counts.get(String(family), 0)) < 3:
			_fail("Battle profiles should give family %s at least 3 tactical tempos, got %d." % [String(family), int(family_counts.get(String(family), 0))])
			return


func _check_reward_profiles() -> void:
	var profiles: Array = RunManager.get_reward_profiles()
	if profiles.size() < MIN_REWARD_PROFILES:
		_fail("Reward profile library should contain at least %d profiles, got %d." % [MIN_REWARD_PROFILES, profiles.size()])
		return
	var cache_families := {}
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		_assert_chinese_copy(String(profile.get("title", "")), "reward title")
		_assert_chinese_copy(String(profile.get("description", "")), "reward description")
		if _failed:
			return
		var config: Dictionary = profile.get("room_config", {})
		if int(config.get("chest_crystal_count", 0)) < 12 or float(config.get("reward_mineral_mult", 0.0)) <= 1.0:
			_fail("Reward profile should keep high reward density and mineral multiplier: %s" % str(profile))
			return
		cache_families[String(profile.get("cache_family_bias", ""))] = true
	for family in RunManager.FAMILY_BIASES:
		if not cache_families.has(String(family)):
			_fail("Reward profiles should include cache family %s." % String(family))
			return


func _check_event_profiles() -> void:
	var profiles: Array = RunManager.get_event_profiles()
	if profiles.size() < MIN_EVENT_PROFILES:
		_fail("Event library should contain at least %d profiles, got %d." % [MIN_EVENT_PROFILES, profiles.size()])
		return
	var categories := {}
	var risk_levels := {}
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		_assert_chinese_copy(String(profile.get("title", "")), "event title")
		_assert_chinese_copy(String(profile.get("description", "")), "event description")
		_assert_chinese_copy(String(profile.get("reward_tag", "")), "event reward tag")
		if _failed:
			return
		categories[String(profile.get("category", ""))] = true
		risk_levels[int(profile.get("risk_level", -1))] = true
	if categories.size() < 7:
		_fail("Event library should cover at least 7 event categories, got %d." % categories.size())
		return
	for risk in [0, 1, 2]:
		if not risk_levels.has(risk):
			_fail("Event library should include risk level %d." % risk)
			return


func _check_modifier_profiles() -> void:
	if not RunManager.has_method("get_modifier_profiles"):
		_fail("RunManager should expose get_modifier_profiles().")
		return
	var catalog: Array = RunManager.get_modifier_profiles()
	if catalog.size() < MIN_MODIFIER_PROFILES:
		_fail("Modifier profile library should contain at least %d profiles, got %d." % [MIN_MODIFIER_PROFILES, catalog.size()])
		return
	var profile_ids := {}
	var tag_groups := {}
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		var modifiers: Array = node.get("modifiers", [])
		for raw_modifier in modifiers:
			var modifier := Dictionary(raw_modifier)
			var modifier_id := String(modifier.get("id", ""))
			_assert_chinese_copy(String(modifier.get("title", "")), "modifier title")
			_assert_chinese_copy(String(modifier.get("description", "")), "modifier description")
			if _failed:
				return
			if modifier_id.is_empty():
				_fail("Modifier profile should expose id: %s" % str(modifier))
				return
			profile_ids[modifier_id] = true
			var tags: Array = modifier.get("tags", [])
			if tags.is_empty():
				_fail("Modifier profile should expose tags: %s" % str(modifier))
				return
			for raw_tag in tags:
				var tag := String(raw_tag)
				_assert_chinese_copy(tag, "modifier tag")
				if _failed:
					return
				tag_groups[tag] = true
			var config: Dictionary = modifier.get("room_config", {})
			if config.is_empty():
				_fail("Modifier profile should alter room config: %s" % str(modifier))
				return
	if profile_ids.size() < MIN_MODIFIER_PROFILES:
		_fail("World map should sample at least %d modifier profiles in one run, got %d." % [MIN_MODIFIER_PROFILES, profile_ids.size()])
		return
	if tag_groups.size() < 14:
		_fail("Modifier library should expose at least 14 readable tag groups in one run, got %d." % tag_groups.size())
		return


func _check_special_bonus_profiles() -> void:
	if not RunManager.has_method("get_active_special_bonus_summaries"):
		_fail("RunManager should expose active special bonus summaries.")
		return
	var special_ids := {}
	var families := {}
	for node in RunManager.map_nodes:
		if String(node.get("type", "")) != RunManager.NODE_SPECIAL:
			continue
		var bonus_id := String(node.get("bonus_id", ""))
		if bonus_id.is_empty():
			_fail("Special bonus node should expose bonus_id: %s" % str(node))
			return
		special_ids[bonus_id] = true
		families[String(node.get("family_bias", ""))] = true
		_assert_chinese_copy(String(node.get("name", "")), "special beacon name")
		_assert_chinese_copy(String(node.get("bonus_name", "")), "special bonus name")
		_assert_chinese_copy(String(node.get("bonus_description", "")), "special bonus description")
		if _failed:
			return
	if special_ids.size() < MIN_SPECIAL_BONUS_PROFILES:
		_fail("World map should generate at least %d special bonus beacons, got %d." % [MIN_SPECIAL_BONUS_PROFILES, special_ids.size()])
		return
	for family in RunManager.FAMILY_BIASES:
		if not families.has(String(family)):
			_fail("Special bonus beacons should cover family %s." % String(family))
			return
	if not families.has("general"):
		_fail("Special bonus beacons should include general protocols.")
		return
	var before := RunManager.get_player_stats()
	var active_ids: Array[String] = []
	for raw_id in special_ids.keys():
		active_ids.append(String(raw_id))
	RunManager.active_special_bonus_ids = active_ids
	var after := RunManager.get_player_stats()
	if not _stats_changed_by_specials(before, after):
		_fail("Special bonus profiles should change player stats when active.")
		return
	var summaries: Array = RunManager.get_active_special_bonus_summaries()
	if summaries.size() < MIN_SPECIAL_BONUS_PROFILES:
		_fail("Active special bonus summaries should cover every special profile, got %d." % summaries.size())
		return
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		_assert_chinese_copy(String(summary.get("name", "")), "special summary name")
		_assert_chinese_copy(String(summary.get("description", "")), "special summary description")
		_assert_chinese_copy(String(summary.get("effects_text", "")), "special summary effects")
		if _failed:
			return


func _stats_changed_by_specials(before: Dictionary, after: Dictionary) -> bool:
	for key in after.keys():
		if before.get(key) != after.get(key):
			return true
	return false


func _assert_chinese_copy(text: String, label: String) -> void:
	if _failed:
		return
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
