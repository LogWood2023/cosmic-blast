extends Node


const REQUIRED_SPECIAL_COUNT: int = 7
const REQUIRED_INTEL_VARIETY: int = 4
const REQUIRED_MODIFIER_VARIETY: int = 5
const REQUIRED_OPPORTUNITY_VARIETY: int = 5
const REQUIRED_MAP_WIDTH: float = 1250.0
const REQUIRED_NODE_DISTANCE: float = 118.0

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_map_layout()
	if _failed:
		return
	_check_map_node_variety()
	if _failed:
		return
	_check_node_modifiers()
	if _failed:
		return
	_check_node_opportunities()
	if _failed:
		return
	_check_explore_config_uses_intel()
	if _failed:
		return
	_check_special_bonus_catalog()
	if _failed:
		return
	print("World map variety check passed.")
	get_tree().quit(0)


func _check_map_layout() -> void:
	if RunManager.map_nodes.is_empty():
		_fail("World map should generate nodes before layout validation.")
		return
	var first_position: Vector2 = RunManager.map_nodes[0].get("position", Vector2.ZERO)
	var min_x := first_position.x
	var max_x := first_position.x
	for node_index in range(RunManager.map_nodes.size()):
		var node: Dictionary = RunManager.map_nodes[node_index]
		var node_position: Vector2 = node.get("position", Vector2.ZERO)
		if not node_position.is_finite():
			_fail("World map node %d should have a finite position." % int(node.get("id", node_index)))
			return
		min_x = minf(min_x, node_position.x)
		max_x = maxf(max_x, node_position.x)
		for other_index in range(node_index):
			var other_position: Vector2 = RunManager.map_nodes[other_index].get("position", Vector2.ZERO)
			var distance := node_position.distance_to(other_position)
			if distance + 0.01 < REQUIRED_NODE_DISTANCE:
				_fail(
					"World map nodes %d and %d overlap: distance %.2f, required %.2f."
					% [int(node.get("id", node_index)), int(RunManager.map_nodes[other_index].get("id", other_index)), distance, REQUIRED_NODE_DISTANCE]
				)
				return
	var map_width := max_x - min_x
	if map_width < REQUIRED_MAP_WIDTH:
		_fail("World map should be at least %.0f units wide, got %.2f." % [REQUIRED_MAP_WIDTH, map_width])


func _check_map_node_variety() -> void:
	var special_count := 0
	var bonus_ids := {}
	var intel_ids := {}
	for node in RunManager.map_nodes:
		var node_type := String(node.get("type", ""))
		if node_type == RunManager.NODE_SPECIAL:
			special_count += 1
			var bonus_id := String(node.get("bonus_id", ""))
			if bonus_id.is_empty():
				_fail("Special node should carry bonus_id.")
				return
			bonus_ids[bonus_id] = true
			continue
		if int(node.get("id", -1)) <= 0:
			continue
		var intel_id := String(node.get("intel_id", ""))
		if intel_id.is_empty():
			_fail("Exploration node should carry intel_id.")
			return
		intel_ids[intel_id] = true
		var title := String(node.get("intel_title", ""))
		var description := String(node.get("intel_description", ""))
		if title.is_empty() or description.is_empty():
			_fail("Exploration node intel should be visible in details.")
			return
	if special_count < REQUIRED_SPECIAL_COUNT:
		_fail("World map should generate at least %d special bonus nodes, got %d." % [REQUIRED_SPECIAL_COUNT, special_count])
		return
	if bonus_ids.size() < REQUIRED_SPECIAL_COUNT:
		_fail("Special bonus nodes should use distinct bonus ids.")
		return
	if intel_ids.size() < REQUIRED_INTEL_VARIETY:
		_fail("World map should use at least %d intel variants, got %d." % [REQUIRED_INTEL_VARIETY, intel_ids.size()])
		return


func _check_node_modifiers() -> void:
	var modifier_ids := {}
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		if node_id <= 0 or node_type == RunManager.NODE_SPECIAL:
			continue
		var modifiers: Array = node.get("modifiers", [])
		if modifiers.is_empty():
			_fail("Exploration node %d should carry at least one domain modifier." % node_id)
			return
		for raw_modifier in modifiers:
			var modifier := Dictionary(raw_modifier)
			var modifier_id := String(modifier.get("id", ""))
			var title := String(modifier.get("title", ""))
			var description := String(modifier.get("description", ""))
			var room_config: Dictionary = modifier.get("room_config", {})
			if modifier_id.is_empty() or title.is_empty() or description.is_empty() or room_config.is_empty():
				_fail("Node %d modifier should include id, title, description, and room_config: %s" % [node_id, str(modifier)])
				return
			modifier_ids[modifier_id] = true
	if modifier_ids.size() < REQUIRED_MODIFIER_VARIETY:
		_fail("World map should use at least %d domain modifier variants, got %d." % [REQUIRED_MODIFIER_VARIETY, modifier_ids.size()])
		return


func _check_node_opportunities() -> void:
	if not RunManager.has_method("get_opportunity_profiles"):
		_fail("RunManager should expose get_opportunity_profiles().")
		return
	var catalog: Array = RunManager.get_opportunity_profiles()
	if catalog.size() < REQUIRED_OPPORTUNITY_VARIETY:
		_fail("Opportunity catalog should contain at least %d entries, got %d." % [REQUIRED_OPPORTUNITY_VARIETY, catalog.size()])
		return
	var opportunity_ids := {}
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		if node_id <= 0 or node_type == RunManager.NODE_SPECIAL:
			continue
		var opportunity := Dictionary(node.get("opportunity", {}))
		if opportunity.is_empty():
			_fail("Exploration node %d should carry a route opportunity." % node_id)
			return
		var opportunity_id := String(opportunity.get("id", ""))
		var title := String(opportunity.get("title", ""))
		var description := String(opportunity.get("description", ""))
		var effects_text := String(opportunity.get("effects_text", ""))
		var room_effect: Dictionary = opportunity.get("room_effect", {})
		var tags: Array = opportunity.get("tags", [])
		if opportunity_id.is_empty() or title.is_empty() or description.is_empty() or effects_text.is_empty() or room_effect.is_empty() or tags.is_empty():
			_fail("Node %d opportunity should include id, title, description, effects, tags, and room_effect: %s" % [node_id, str(opportunity)])
			return
		opportunity_ids[opportunity_id] = true
	if opportunity_ids.size() < REQUIRED_OPPORTUNITY_VARIETY:
		_fail("World map should use at least %d route opportunity variants, got %d." % [REQUIRED_OPPORTUNITY_VARIETY, opportunity_ids.size()])
		return


func _check_explore_config_uses_intel() -> void:
	var checked := 0
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		if node_id <= 0 or node_type == RunManager.NODE_SPECIAL or node_type == RunManager.NODE_REWARD:
			continue
		if not RunManager.is_node_accessible(node_id):
			continue
		var expected: Dictionary = node.get("room_config", {})
		if expected.is_empty():
			_fail("Exploration node %d should carry room_config from intel." % node_id)
			return
		if not RunManager.start_explore_node(node_id):
			_fail("Accessible node %d should start exploration." % node_id)
			return
		var actual := GameManager.next_explore_room_config.duplicate(true)
		var run_condition_config := _combined_run_condition_config(node.get("run_conditions", []))
		var modifier_config := _combined_modifier_config(node.get("modifiers", []))
		var opportunity_config := _expected_opportunity_room_config(node)
		var final_config := expected.duplicate(true)
		_merge_config(final_config, run_condition_config)
		_merge_config(final_config, modifier_config)
		_apply_room_effect(final_config, opportunity_config)
		_apply_risk_floor(final_config, int(node.get("risk_level", 1)))
		var ore_source_config := _expected_ore_source_room_config(node)
		_apply_room_effect(final_config, ore_source_config)
		for key in expected.keys():
			if not actual.has(key):
				_fail("Explore config should include intel key %s, got %s." % [String(key), str(actual)])
				return
			if not _same_config_value(actual[key], final_config.get(key, expected[key])):
				_fail("Explore config should preserve layered value for %s, expected %s got %s." % [String(key), str(final_config.get(key, expected[key])), str(actual[key])])
				return
		for key in run_condition_config.keys():
			if not actual.has(key):
				_fail("Explore config should include run condition key %s, got %s." % [String(key), str(actual)])
				return
			if not _same_config_value(actual[key], final_config[key]):
				_fail("Explore config should apply run condition value for %s, expected %s got %s." % [String(key), str(final_config[key]), str(actual[key])])
				return
		for key in modifier_config.keys():
			if not actual.has(key):
				_fail("Explore config should include modifier key %s, got %s." % [String(key), str(actual)])
				return
			if not _same_config_value(actual[key], final_config[key]):
				_fail("Explore config should apply modifier value for %s, expected %s got %s." % [String(key), str(final_config[key]), str(actual[key])])
				return
		for key in opportunity_config.keys():
			if not actual.has(key):
				_fail("Explore config should include opportunity key %s, got %s." % [String(key), str(actual)])
				return
			if not _same_config_value(actual[key], final_config[key]):
				_fail("Explore config should apply opportunity value for %s, expected %s got %s." % [String(key), str(final_config[key]), str(actual[key])])
				return
		for key in ore_source_config.keys():
			if not actual.has(key):
				_fail("Explore config should include ore source key %s, got %s." % [String(key), str(actual)])
				return
			if not _same_config_value(actual[key], final_config[key]):
				_fail("Explore config should apply ore source value for %s, expected %s got %s." % [String(key), str(final_config[key]), str(actual[key])])
				return
		var family_bias := RunManager.get_node_family_bias(node_id)
		var family_key := "%s_family_weight" % family_bias
		if family_bias.is_empty() or not actual.has(family_key):
			_fail("Explore config should still include family bias alongside intel.")
			return
		RunManager.abandon_current_room()
		checked += 1
		if checked >= 2:
			return
	if checked <= 0:
		_fail("Need at least one accessible exploration node for intel config check.")


func _combined_run_condition_config(conditions: Array) -> Dictionary:
	var combined := {}
	for raw_condition in conditions:
		var condition := Dictionary(raw_condition)
		var room_config: Dictionary = condition.get("room_config", {})
		for key in room_config.keys():
			combined[key] = room_config[key]
	return combined


func _combined_modifier_config(modifiers: Array) -> Dictionary:
	var combined := {}
	for raw_modifier in modifiers:
		var modifier := Dictionary(raw_modifier)
		var room_config: Dictionary = modifier.get("room_config", {})
		for key in room_config.keys():
			combined[key] = room_config[key]
	return combined


func _merge_config(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		target[key] = source[key]


func _expected_opportunity_room_config(node: Dictionary) -> Dictionary:
	var opportunity := Dictionary(node.get("opportunity", {}))
	if opportunity.is_empty():
		return {}
	var config := {}
	var room_effect: Dictionary = opportunity.get("room_effect", {})
	for key in room_effect.keys():
		config[key] = room_effect[key]
	var title := String(opportunity.get("title", "")).strip_edges()
	var effects_text := String(opportunity.get("effects_text", "")).strip_edges()
	if not title.is_empty():
		config["opportunity_tip_text"] = "航行机会：%s。%s" % [title, effects_text] if not effects_text.is_empty() else "航行机会：%s。方舟建议把这段偏移纳入回收节奏。" % title
	return config


func _apply_risk_floor(config: Dictionary, risk: int) -> void:
	if risk <= 1:
		return
	config["trap_count"] = maxi(int(config.get("trap_count", 4)), 3 + risk * 2)
	config["enemy_spawn_interval"] = minf(float(config.get("enemy_spawn_interval", 45.0)), maxf(18.0, 48.0 - float(risk) * 5.0))
	config["max_patrol_enemy_count"] = maxi(int(config.get("max_patrol_enemy_count", 8)), 6 + risk * 2)


func _expected_ore_source_room_config(node: Dictionary) -> Dictionary:
	var source_id := String(node.get("ore_source_bias", "")).strip_edges()
	if source_id.is_empty():
		return {}
	var config := {
		"ore_source_bias": source_id,
		"ore_source_name": String(node.get("ore_source_name", "")).strip_edges(),
		"ore_source_weights": _make_ore_source_weight_map(source_id, maxf(1.0, float(node.get("ore_source_weight", 2.4)))),
	}
	var room_effect: Dictionary = node.get("ore_source_room_effect", {})
	for key in room_effect.keys():
		config[key] = room_effect[key]
	var effect_text := String(node.get("ore_source_room_effect_text", "")).strip_edges()
	if not effect_text.is_empty():
		config["ore_source_room_effect_text"] = effect_text
	return config


func _make_ore_source_weight_map(source_id: String, source_weight: float) -> Dictionary:
	var weights := {}
	for profile in RunManager.ORE_SOURCE_BIAS_PROFILES:
		var id := String(profile.get("id", ""))
		if id.is_empty():
			continue
		weights[id] = 1.0
	if not source_id.is_empty():
		weights[source_id] = maxf(float(weights.get(source_id, 1.0)), source_weight)
	return weights


func _apply_room_effect(config: Dictionary, effect_config: Dictionary) -> void:
	for raw_key in effect_config.keys():
		var key := String(raw_key)
		match key:
			"reward_mineral_mult":
				config[key] = maxf(0.1, float(config.get(key, 1.0)) + float(effect_config[raw_key]))
			"enemy_spawn_interval":
				config[key] = maxf(12.0, float(config.get(key, 45.0)) + float(effect_config[raw_key]))
			"large_space_rock_count", "trap_count", "chest_crystal_count", "clutter_count", "max_patrol_enemy_count", "patrol_path_min_count", "patrol_path_max_count":
				config[key] = maxi(0, int(config.get(key, 0)) + int(effect_config[raw_key]))
			_:
				config[key] = effect_config[raw_key]


func _check_special_bonus_catalog() -> void:
	var before := RunManager.get_player_stats()
	RunManager.active_special_bonus_ids = [
		"colossus_charge_beacon",
		"paradise_fire_beacon",
		"warped_gravity_beacon",
		"hell_eye_frenzy_beacon",
		"divine_drone_beacon",
		"vector_supply_beacon",
		"ark_guard_beacon",
	]
	var after := RunManager.get_player_stats()
	if float(after.get("dash_distance_mult", 1.0)) <= float(before.get("dash_distance_mult", 1.0)):
		_fail("Colossus special beacon should improve dash distance.")
		return
	if int(after.get("bullet_count", 1)) <= int(before.get("bullet_count", 1)):
		_fail("Paradise special beacon should improve bullet coverage.")
		return
	if float(after.get("homing_strength", 0.0)) <= float(before.get("homing_strength", 0.0)):
		_fail("Warped special beacon should improve homing.")
		return
	if float(after.get("frenzy_gain_mult", 1.0)) <= float(before.get("frenzy_gain_mult", 1.0)):
		_fail("Hell Eye special beacon should improve frenzy gain.")
		return
	if int(after.get("drone_slots", 0)) <= int(before.get("drone_slots", 0)):
		_fail("Divine special beacon should improve drone slots.")
		return
	if float(after.get("mineral_bonus", 0.0)) <= float(before.get("mineral_bonus", 0.0)):
		_fail("Supply special beacon should improve mineral economy.")
		return
	if float(after.get("damage_taken_mult", 1.0)) >= float(before.get("damage_taken_mult", 1.0)):
		_fail("Ark guard special beacon should reduce incoming damage.")
		return


func _same_config_value(actual, expected) -> bool:
	if typeof(actual) == TYPE_FLOAT or typeof(expected) == TYPE_FLOAT or typeof(actual) == TYPE_INT or typeof(expected) == TYPE_INT:
		return absf(float(actual) - float(expected)) < 0.01
	return str(actual) == str(expected)


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
