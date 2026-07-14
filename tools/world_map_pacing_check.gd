extends Node


const SAMPLE_SEED_COUNT := 160
const MIN_EXPLORATION_NODE_COUNT := 26
const MIN_BATTLE_NODES := 15
const MIN_EVENT_NODES := 6
const MIN_REWARD_NODES := 3

var _failed: bool = false
var _first_layout_signature: Array[Vector2] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	for seed_value in range(SAMPLE_SEED_COUNT):
		seed(seed_value)
		RunManager.call("_generate_world_map")
		_check_map_pacing(seed_value)
		if _failed:
			return
		_check_branching_spider_geometry(seed_value)
		if _failed:
			return
		_check_layout_variety(seed_value)
		if _failed:
			return
	print("World map pacing check passed.")
	get_tree().quit(0)


func _check_map_pacing(seed_value: int) -> void:
	var counts := {
		RunManager.NODE_BATTLE: 0,
		RunManager.NODE_EVENT: 0,
		RunManager.NODE_REWARD: 0,
	}
	var exploration_count := 0
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0:
			continue
		var node_type := String(node.get("type", ""))
		if node_type == RunManager.NODE_SPECIAL:
			continue
		exploration_count += 1
		counts[node_type] = int(counts.get(node_type, 0)) + 1
	if exploration_count < MIN_EXPLORATION_NODE_COUNT:
		_fail("Seed %d should generate at least %d exploration nodes, got %d." % [
			seed_value,
			MIN_EXPLORATION_NODE_COUNT,
			exploration_count,
		])
		return
	if int(counts.get(RunManager.NODE_BATTLE, 0)) < MIN_BATTLE_NODES:
		_fail("Seed %d should generate at least %d battle nodes, counts=%s." % [seed_value, MIN_BATTLE_NODES, str(counts)])
		return
	if int(counts.get(RunManager.NODE_EVENT, 0)) < MIN_EVENT_NODES:
		_fail("Seed %d should generate at least %d event nodes, counts=%s." % [seed_value, MIN_EVENT_NODES, str(counts)])
		return
	if int(counts.get(RunManager.NODE_REWARD, 0)) < MIN_REWARD_NODES:
		_fail("Seed %d should generate at least %d reward nodes, counts=%s." % [seed_value, MIN_REWARD_NODES, str(counts)])
		return


func _check_branching_spider_geometry(seed_value: int) -> void:
	var edges: Array[Dictionary] = []
	var edge_keys := {}
	var has_bridge_web_link := false
	for node_index in range(RunManager.map_nodes.size()):
		var node: Dictionary = RunManager.map_nodes[node_index]
		var node_id := int(node.get("id", node_index))
		var position: Vector2 = node.get("position", Vector2.ZERO)
		if bool(node.get("web_bridge", false)) and node.get("links", []).size() >= 3:
			has_bridge_web_link = true
		for other_index in range(node_index):
			var other_position: Vector2 = RunManager.map_nodes[other_index].get("position", Vector2.ZERO)
			if position.distance_squared_to(other_position) < RunManager.MAP_NODE_MIN_DISTANCE * RunManager.MAP_NODE_MIN_DISTANCE:
				_fail("Seed %d produced overlapping branching-spider nodes." % seed_value)
				return
		for raw_linked_id in node.get("links", []):
			var linked_id := int(raw_linked_id)
			var edge_key := "%d_%d" % [mini(node_id, linked_id), maxi(node_id, linked_id)]
			if edge_keys.has(edge_key):
				continue
			edge_keys[edge_key] = true
			edges.append({"from": node_id, "to": linked_id})
	for edge_index in range(edges.size()):
		var edge: Dictionary = edges[edge_index]
		var from_id := int(edge["from"])
		var to_id := int(edge["to"])
		var from_position: Vector2 = RunManager.get_map_node(from_id).get("position", Vector2.ZERO)
		var to_position: Vector2 = RunManager.get_map_node(to_id).get("position", Vector2.ZERO)
		for other_index in range(edge_index):
			var other: Dictionary = edges[other_index]
			var other_from := int(other["from"])
			var other_to := int(other["to"])
			if from_id == other_from or from_id == other_to or to_id == other_from or to_id == other_to:
				continue
			var other_from_position: Vector2 = RunManager.get_map_node(other_from).get("position", Vector2.ZERO)
			var other_to_position: Vector2 = RunManager.get_map_node(other_to).get("position", Vector2.ZERO)
			if Geometry2D.segment_intersects_segment(from_position, to_position, other_from_position, other_to_position) != null:
				_fail("Seed %d produced crossing branching-spider links." % seed_value)
				return
	if not has_bridge_web_link:
		_fail("Seed %d should connect at least one long-link bridge node into the local web." % seed_value)


func _check_legacy_spider_geometry(seed_value: int) -> void:
	var path_distances := {}
	var edges: Array[Dictionary] = []
	var edge_keys := {}
	for node_index in range(RunManager.map_nodes.size()):
		var node: Dictionary = RunManager.map_nodes[node_index]
		var node_id := int(node.get("id", node_index))
		var position: Vector2 = node.get("position", Vector2.ZERO)
		for other_index in range(node_index):
			var other_position: Vector2 = RunManager.map_nodes[other_index].get("position", Vector2.ZERO)
			if position.distance_squared_to(other_position) < RunManager.MAP_NODE_MIN_DISTANCE * RunManager.MAP_NODE_MIN_DISTANCE:
				_fail("Seed %d produced overlapping spider-map nodes." % seed_value)
				return
		if node_id != RunManager.CENTER_ID:
			var path_index := int(node.get("path_index", -1))
			var path_depth := int(node.get("path_depth", -1))
			if path_index < 0 or path_depth < 0:
				_fail("Seed %d produced node %d without spider path metadata." % [seed_value, node_id])
				return
			path_distances["%d_%d" % [path_index, path_depth]] = position.distance_to(RunManager.MAP_CENTER)
		for raw_linked_id in node.get("links", []):
			var linked_id := int(raw_linked_id)
			var edge_key := "%d_%d" % [mini(node_id, linked_id), maxi(node_id, linked_id)]
			if edge_keys.has(edge_key):
				continue
			edge_keys[edge_key] = true
			edges.append({"from": node_id, "to": linked_id})
	for path_index in range(4):
		var terminal_depth := 2 if path_index < 2 else 5
		var previous_distance := 0.0
		for path_depth in range(terminal_depth + 1):
			var distance := float(path_distances.get("%d_%d" % [path_index, path_depth], -1.0))
			if distance <= previous_distance:
				_fail("Seed %d produced a non-progressing spider path." % seed_value)
				return
			previous_distance = distance
	for edge_index in range(edges.size()):
		var edge: Dictionary = edges[edge_index]
		var from_id := int(edge["from"])
		var to_id := int(edge["to"])
		var from_position: Vector2 = RunManager.get_map_node(from_id).get("position", Vector2.ZERO)
		var to_position: Vector2 = RunManager.get_map_node(to_id).get("position", Vector2.ZERO)
		for other_index in range(edge_index):
			var other: Dictionary = edges[other_index]
			var other_from := int(other["from"])
			var other_to := int(other["to"])
			if from_id == other_from or from_id == other_to or to_id == other_from or to_id == other_to:
				continue
			var other_from_position: Vector2 = RunManager.get_map_node(other_from).get("position", Vector2.ZERO)
			var other_to_position: Vector2 = RunManager.get_map_node(other_to).get("position", Vector2.ZERO)
			if Geometry2D.segment_intersects_segment(from_position, to_position, other_from_position, other_to_position) != null:
				_fail("Seed %d produced crossing spider-map links." % seed_value)
				return


func _check_layout_variety(seed_value: int) -> void:
	var signature: Array[Vector2] = []
	for node in RunManager.map_nodes:
		if int(node.get("id", -1)) == RunManager.CENTER_ID:
			continue
		signature.append(node.get("position", Vector2.ZERO))
	if seed_value == 0:
		_first_layout_signature = signature
		return
	if seed_value != 1 or signature.size() != _first_layout_signature.size():
		return
	for position_index in range(signature.size()):
		if not signature[position_index].is_equal_approx(_first_layout_signature[position_index]):
			return
	_fail("Different world-map seeds should produce distinct spider-map layouts.")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
