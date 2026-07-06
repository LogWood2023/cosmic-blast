extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_map_nodes_expose_ore_source_bias()
	if _failed:
		return
	_check_start_explore_passes_ore_source_config()
	if _failed:
		return
	await _check_world_map_details_show_ore_source()
	if _failed:
		return
	print("Ore source route bias check passed.")
	get_tree().quit(0)


func _check_map_nodes_expose_ore_source_bias() -> void:
	var source_ids := {}
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		var source_id := String(node.get("ore_source_bias", "")).strip_edges()
		var source_name := String(node.get("ore_source_name", "")).strip_edges()
		if source_id.is_empty() or source_name.is_empty():
			_fail("Node %d should expose ore source bias and name." % node_id)
			return
		_assert_chinese_copy(source_name, "ore source name")
		if _failed:
			return
		source_ids[source_id] = true
		var plan: Dictionary = node.get("route_plan", {})
		var hint := String(plan.get("ore_source_hint", "")).strip_edges()
		if hint.is_empty() or not hint.contains(source_name) or not hint.contains("矿源"):
			_fail("Node %d route plan should show ore source hint, got: %s." % [node_id, hint])
			return
		_assert_chinese_copy(hint, "ore source route hint")
		if _failed:
			return
	if source_ids.size() < 4:
		_fail("World map should distribute at least 4 ore source biases, got %d." % source_ids.size())


func _check_start_explore_passes_ore_source_config() -> void:
	var node_id := _first_accessible_non_special_node()
	if node_id <= 0:
		_fail("Need an accessible node for ore source room config check.")
		return
	var node := RunManager.get_map_node(node_id)
	var source_id := String(node.get("ore_source_bias", ""))
	var source_name := String(node.get("ore_source_name", ""))
	if not RunManager.start_explore_node(node_id):
		_fail("Could not start accessible node %d." % node_id)
		return
	var config: Dictionary = GameManager.next_explore_room_config
	if String(config.get("ore_source_bias", "")) != source_id:
		_fail("Explore room config should inherit ore source bias %s, got: %s." % [source_id, str(config)])
		return
	if String(config.get("ore_source_name", "")) != source_name:
		_fail("Explore room config should inherit ore source display name.")
		return
	var weights: Dictionary = config.get("ore_source_weights", {})
	if weights.is_empty() or float(weights.get(source_id, 0.0)) <= 1.0:
		_fail("Explore room config should boost biased ore source weight, got: %s." % str(weights))
		return


func _check_world_map_details_show_ore_source() -> void:
	RunManager.start_new_run()
	var node_id := _first_accessible_non_special_node()
	if node_id <= 0:
		_fail("Need an accessible node for world map details check.")
		return
	var node := RunManager.get_map_node(node_id)
	var source_name := String(node.get("ore_source_name", ""))
	var room_effect_text := String(node.get("ore_source_room_effect_text", "")).strip_edges()
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
		_fail("WorldMap details body missing.")
		scene.queue_free()
		return
	var text := details_body.text
	scene.queue_free()
	if not text.contains("矿源") or not text.contains(source_name):
		_fail("World map details should show ore source bias %s. Details: %s" % [source_name, text])
		return
	if room_effect_text.is_empty() or not text.contains("矿区回声") or not text.contains(room_effect_text):
		_fail("World map details should show ore source room echo. Details: %s" % text)
		return
	for hidden in ["ore_source_bias", "star_marrow", "gleam_crystal", "rift_cluster", "deep_core"]:
		if text.contains(hidden):
			_fail("World map details should hide internal ore source ids: %s" % text)
			return


func _first_accessible_non_special_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		if RunManager.is_node_accessible(node_id):
			return node_id
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
