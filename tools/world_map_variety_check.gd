extends Node


const REQUIRED_SPECIAL_COUNT: int = 2
const REQUIRED_INTEL_VARIETY: int = 4
const REQUIRED_MODIFIER_VARIETY: int = 5
const REQUIRED_OPPORTUNITY_VARIETY: int = 5
const REQUIRED_MAP_WIDTH: float = 1000.0
const REQUIRED_NODE_DISTANCE: float = 118.0

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_map_layout()
	if _failed:
		return
	_check_branching_spider_topology()
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


func _check_branching_spider_topology() -> void:
	var layer_counts := {}
	var layer_type_counts := {}
	var type_counts := {RunManager.NODE_BATTLE: 0, RunManager.NODE_EVENT: 0, RunManager.NODE_REWARD: 0}
	var child_counts := {}
	var special_count := 0
	var lateral_links := {}
	var relay_count := 0
	var bridge_count := 0
	for raw_node in RunManager.map_nodes:
		var node: Dictionary = raw_node
		var node_id := int(node.get("id", -1))
		if node_id == RunManager.CENTER_ID:
			continue
		var node_type := String(node.get("type", ""))
		var layer := int(node.get("web_layer", -1))
		var parent_id := int(node.get("web_parent_id", -1))
		if layer < 0 or parent_id < 0:
			_fail("Branching spider node %d should expose layer and parent metadata." % node_id)
			return
		if node_type == RunManager.NODE_SPECIAL:
			special_count += 1
			if layer != RunManager.MAP_SPIDER_LAYER_COUNT or node.get("links", []).size() != 1:
				_fail("Beacon nodes should be unbranched outer terminals.")
				return
			continue
		if bool(node.get("web_bridge", false)):
			bridge_count += 1
			if node.get("links", []).size() < 2:
				_fail("Long-link bridge nodes should preserve their two route segments.")
				return
			continue
		if bool(node.get("web_relay", false)):
			relay_count += 1
			var relay_links: Array = node.get("links", [])
			if relay_links.size() < 2:
				_fail("Horizontal relay nodes should connect their two neighboring nodes.")
				return
			var left_position: Vector2 = RunManager.get_map_node(int(relay_links[0])).get("position", Vector2.ZERO)
			var right_position: Vector2 = RunManager.get_map_node(int(relay_links[1])).get("position", Vector2.ZERO)
			var relay_position: Vector2 = node.get("position", Vector2.ZERO)
			if _distance_squared_to_segment(relay_position, left_position, right_position) > 0.01:
				_fail("Horizontal relay nodes must remain on a single straight connection line.")
				return
			continue
		type_counts[node_type] = int(type_counts.get(node_type, 0)) + 1
		layer_counts[layer] = int(layer_counts.get(layer, 0)) + 1
		var types_in_layer: Dictionary = Dictionary(layer_type_counts.get(layer, {}))
		types_in_layer[node_type] = int(types_in_layer.get(node_type, 0)) + 1
		layer_type_counts[layer] = types_in_layer
		if layer == 0:
			if parent_id != RunManager.CENTER_ID or not _has_connection_via_bridges(RunManager.CENTER_ID, node_id):
				_fail("Each initial branching-spider node must connect directly to the core.")
				return
		else:
			var parent: Dictionary = RunManager.get_map_node(parent_id)
			if parent.is_empty() or not _has_connection_via_bridges(parent_id, node_id):
				_fail("Branching-spider node %d must link to its parent." % node_id)
				return
			var node_position: Vector2 = node.get("position", Vector2.ZERO)
			var parent_position: Vector2 = parent.get("position", Vector2.ZERO)
			if node_position.distance_to(RunManager.MAP_CENTER) <= parent_position.distance_to(RunManager.MAP_CENTER):
				_fail("Branching-spider nodes must expand away from the core.")
				return
			child_counts[parent_id] = int(child_counts.get(parent_id, 0)) + 1
		for linked_id in node.get("links", []):
			var linked: Dictionary = RunManager.get_map_node(int(linked_id))
			if not linked.is_empty() and int(linked.get("web_layer", -2)) == layer:
				lateral_links["%d_%d" % [mini(node_id, int(linked_id)), maxi(node_id, int(linked_id))]] = true
	var main_node_count := 0
	for layer in range(RunManager.MAP_SPIDER_LAYER_COUNT):
		var layer_count := int(layer_counts.get(layer, 0))
		if layer_count <= 0:
			_fail("Branching spider layer %d should contain at least one node." % layer)
			return
		var types_in_layer: Dictionary = Dictionary(layer_type_counts.get(layer, {}))
		if int(types_in_layer.get(RunManager.NODE_BATTLE, 0)) <= 0 or int(types_in_layer.get(RunManager.NODE_EVENT, 0)) <= 0:
			_fail("Branching spider layer %d should mix battle and event nodes." % layer)
			return
		main_node_count += layer_count
		if layer > 0:
			var previous_layer_count := int(layer_counts.get(layer - 1, 0))
			if layer_count < previous_layer_count or layer_count > previous_layer_count * 2:
				_fail("Branching spider layer %d should expand within its parent connection budget." % layer)
				return
	if main_node_count < RunManager.MAP_SPIDER_MAIN_NODE_COUNT_MIN or main_node_count > RunManager.MAP_SPIDER_MAIN_NODE_COUNT_MAX:
		_fail("Branching spider should generate %d-%d main nodes, got %d." % [RunManager.MAP_SPIDER_MAIN_NODE_COUNT_MIN, RunManager.MAP_SPIDER_MAIN_NODE_COUNT_MAX, main_node_count])
		return
	if int(layer_counts.get(0, 0)) < RunManager.MAP_SPIDER_INITIAL_NODE_COUNT_MIN or int(layer_counts.get(0, 0)) > RunManager.MAP_SPIDER_INITIAL_NODE_COUNT_MAX:
		_fail("Branching spider should start with %d-%d initial routes." % [RunManager.MAP_SPIDER_INITIAL_NODE_COUNT_MIN, RunManager.MAP_SPIDER_INITIAL_NODE_COUNT_MAX])
		return
	var expected_reward_count := int(round(float(main_node_count) / 8.0))
	var expected_event_count := int(round(float(main_node_count) / 4.0))
	var expected_battle_count := main_node_count - expected_reward_count - expected_event_count
	if type_counts[RunManager.NODE_BATTLE] != expected_battle_count or type_counts[RunManager.NODE_EVENT] != expected_event_count or type_counts[RunManager.NODE_REWARD] != expected_reward_count:
		_fail("Branching spider map must retain battle:event:reward = 5:2:1.")
		return
	if special_count != 2:
		_fail("Branching spider map should expose two outer beacon terminals.")
		return
	if relay_count < 2:
		_fail("Branching spider map should add at least two straight horizontal relay nodes, got %d." % relay_count)
		return
	if bridge_count <= 0:
		_fail("Branching spider map should split at least one long connection with bridge nodes.")
		return
	var branch_count := 0
	for count in child_counts.values():
		if int(count) >= 2:
			branch_count += 1
	if branch_count < 2 or lateral_links.size() < 6:
		_fail("Branching spider should contain multiple splits and local web links.")
		return
	_check_spider_links_do_not_cross()
	if _failed:
		return
	_check_web_link_constraints()
	if _failed:
		return
	_check_all_nodes_reachable()


func _check_web_link_constraints() -> void:
	for raw_node in RunManager.map_nodes:
		var node: Dictionary = raw_node
		var node_id := int(node.get("id", -1))
		if node_id < RunManager.CENTER_ID or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		var links: Array = node.get("links", [])
		var route_links: Array[int] = []
		for raw_link_id in links:
			var link_id := int(raw_link_id)
			if String(RunManager.get_map_node(link_id).get("type", "")) != RunManager.NODE_SPECIAL:
				route_links.append(link_id)
		var degree_limit := RunManager.MAP_WEB_ROOT_MAX_DEGREE if node_id == RunManager.CENTER_ID else RunManager.MAP_WEB_NODE_MAX_DEGREE
		if bool(node.get("is_path_terminal", false)):
			degree_limit = RunManager.MAP_WEB_TERMINAL_MAX_DEGREE
		elif bool(node.get("web_relay", false)):
			degree_limit = RunManager.MAP_WEB_RELAY_MAX_DEGREE
		elif bool(node.get("web_bridge", false)):
			degree_limit = RunManager.MAP_WEB_BRIDGE_MAX_DEGREE
		if route_links.size() > degree_limit:
			_fail("Node %d exceeds its route degree budget (%d > %d)." % [node_id, route_links.size(), degree_limit])
			return
		var node_position: Vector2 = node.get("position", Vector2.ZERO)
		for first_index in range(route_links.size()):
			var first_angle := node_position.angle_to_point(RunManager.get_map_node(route_links[first_index]).get("position", Vector2.ZERO))
			for second_index in range(first_index + 1, route_links.size()):
				var second_angle := node_position.angle_to_point(RunManager.get_map_node(route_links[second_index]).get("position", Vector2.ZERO))
				var angle_difference := absf(wrapf(first_angle - second_angle, -PI, PI))
				if angle_difference + 0.001 < RunManager.MAP_WEB_MIN_LINK_ANGLE:
					_fail("Node %d has route edges with only %.1f degrees of separation." % [node_id, rad_to_deg(angle_difference)])
					return


func _check_all_nodes_reachable() -> void:
	var pending: Array[int] = [RunManager.CENTER_ID]
	var visited := {RunManager.CENTER_ID: true}
	while not pending.is_empty():
		var current_id := pending.pop_back()
		for raw_link_id in RunManager.get_map_node(current_id).get("links", []):
			var link_id := int(raw_link_id)
			if visited.has(link_id):
				continue
			visited[link_id] = true
			pending.append(link_id)
	for raw_node in RunManager.map_nodes:
		var node_id := int(raw_node.get("id", -1))
		if node_id >= RunManager.CENTER_ID and not visited.has(node_id):
			_fail("World map node %d must be reachable from the core." % node_id)
			return


func _has_connection_via_bridges(from_id: int, to_id: int) -> bool:
	var pending: Array[int] = [from_id]
	var visited := {from_id: true}
	while not pending.is_empty():
		var current_id := pending.pop_back()
		for raw_linked_id in RunManager.get_map_node(current_id).get("links", []):
			var linked_id := int(raw_linked_id)
			if linked_id == to_id:
				return true
			if visited.has(linked_id):
				continue
			if not bool(RunManager.get_map_node(linked_id).get("web_bridge", false)):
				continue
			visited[linked_id] = true
			pending.append(linked_id)
	return false


func _distance_squared_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment := segment_end - segment_start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_squared_to(segment_start)
	var progress := clampf((point - segment_start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_squared_to(segment_start + segment * progress)


func _check_legacy_spider_topology() -> void:
	var type_counts := {
		RunManager.NODE_BATTLE: 0,
		RunManager.NODE_EVENT: 0,
		RunManager.NODE_REWARD: 0,
	}
	var paths := {}
	var beacon_count := 0
	for raw_node in RunManager.map_nodes:
		var node: Dictionary = raw_node
		var node_id := int(node.get("id", -1))
		if node_id == RunManager.CENTER_ID:
			continue
		if not node.has("path_index") or not node.has("path_depth"):
			_fail("Spider-map node %d should declare its path and depth." % node_id)
			return
		var path_index := int(node["path_index"])
		var path_depth := int(node["path_depth"])
		if path_index < 0 or path_index >= 4 or path_depth < 0:
			_fail("Spider-map node %d has invalid path metadata." % node_id)
			return
		var path_nodes: Dictionary = paths.get(path_index, {})
		if path_nodes.has(path_depth):
			_fail("Spider-map path %d has multiple nodes at depth %d." % [path_index, path_depth])
			return
		path_nodes[path_depth] = node
		paths[path_index] = path_nodes
		var node_type := String(node.get("type", ""))
		if node_type == RunManager.NODE_SPECIAL:
			beacon_count += 1
			if not bool(node.get("is_path_terminal", false)) or node.get("links", []).size() != 1:
				_fail("Beacon %d must be an unbranched path terminal." % node_id)
				return
		else:
			type_counts[node_type] = int(type_counts.get(node_type, 0)) + 1
	if int(type_counts.get(RunManager.NODE_BATTLE, 0)) != 10 or int(type_counts.get(RunManager.NODE_EVENT, 0)) != 4 or int(type_counts.get(RunManager.NODE_REWARD, 0)) != 2:
		_fail("Spider-map exploration ratio must be battle:event:reward = 5:2:1, got %s." % str(type_counts))
		return
	if beacon_count != 2 or beacon_count != int(type_counts.get(RunManager.NODE_REWARD, 0)):
		_fail("Spider-map reward and beacon terminals must be balanced 1:1.")
		return
	for path_index in range(4):
		var path_nodes: Dictionary = paths.get(path_index, {})
		var terminal_depth := 2 if path_index < 2 else 5
		var previous_node := {}
		var previous_distance := 0.0
		for path_depth in range(terminal_depth + 1):
			var node: Dictionary = path_nodes.get(path_depth, {})
			if node.is_empty():
				_fail("Spider-map path %d is missing depth %d." % [path_index, path_depth])
				return
			var position: Vector2 = node.get("position", Vector2.ZERO)
			var distance := position.distance_to(RunManager.MAP_CENTER)
			if path_depth > 0:
				if distance <= previous_distance:
					_fail("Spider-map path %d must move farther from the core at every step." % path_index)
					return
				var previous_links: Array = previous_node.get("links", [])
				if not previous_links.has(int(node.get("id", -1))):
					_fail("Spider-map path %d has a missing forward link at depth %d." % [path_index, path_depth])
					return
			previous_node = node
			previous_distance = distance
		var terminal_type := String(previous_node.get("type", ""))
		if terminal_type != (RunManager.NODE_REWARD if path_index < 2 else RunManager.NODE_SPECIAL):
			_fail("Spider-map path %d must end in its assigned reward or beacon terminal." % path_index)
			return
		if not bool(previous_node.get("is_path_terminal", false)):
			_fail("Spider-map path %d terminal must be marked as terminal." % path_index)
			return
		var root_node: Dictionary = path_nodes[0]
		if not RunManager.get_map_node(RunManager.CENTER_ID).get("links", []).has(int(root_node.get("id", -1))):
			_fail("Spider-map path %d must start at the core." % path_index)
			return
	for lateral_depth in range(1):
		var lateral_link_count := 0
		for path_index in range(4):
			var current: Dictionary = Dictionary(paths[path_index][lateral_depth])
			var next: Dictionary = Dictionary(paths[(path_index + 1) % 4][lateral_depth])
			if current.get("links", []).has(int(next.get("id", -1))):
				lateral_link_count += 1
		if lateral_link_count <= 0:
			_fail("Spider-map needs lateral links near the core to form its web.")
			return
	_check_spider_links_do_not_cross()


func _check_spider_links_do_not_cross() -> void:
	var checked_links := {}
	for from_node in RunManager.map_nodes:
		var from_id := int(from_node.get("id", -1))
		for raw_to_id in from_node.get("links", []):
			var to_id := int(raw_to_id)
			var link_key := "%d_%d" % [mini(from_id, to_id), maxi(from_id, to_id)]
			if checked_links.has(link_key):
				continue
			checked_links[link_key] = {"from": from_id, "to": to_id}
	for link_key in checked_links:
		var link: Dictionary = checked_links[link_key]
		var from_id := int(link["from"])
		var to_id := int(link["to"])
		var start: Vector2 = RunManager.get_map_node(from_id).get("position", Vector2.ZERO)
		var end: Vector2 = RunManager.get_map_node(to_id).get("position", Vector2.ZERO)
		for other_key in checked_links:
			if String(other_key) <= String(link_key):
				continue
			var other: Dictionary = checked_links[other_key]
			var other_from := int(other["from"])
			var other_to := int(other["to"])
			if from_id == other_from or from_id == other_to or to_id == other_from or to_id == other_to:
				continue
			var other_start: Vector2 = RunManager.get_map_node(other_from).get("position", Vector2.ZERO)
			var other_end: Vector2 = RunManager.get_map_node(other_to).get("position", Vector2.ZERO)
			if Geometry2D.segment_intersects_segment(start, end, other_start, other_end) != null:
				_fail("Spider-map links %s and %s must not cross." % [String(link_key), String(other_key)])
				return


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
