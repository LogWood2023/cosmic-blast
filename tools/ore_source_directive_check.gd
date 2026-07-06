extends Node


const ROUTE_DIRECTIVE_POPUP_PATH := "res://scenes/ui/world_map/RouteDirectivePopup.tscn"

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_directive_catalog_contains_ore_sources()
	if _failed:
		return
	_check_ore_source_directive_completion()
	if _failed:
		return
	await _check_popup_copy()
	if _failed:
		return
	print("Ore source directive check passed.")
	get_tree().quit(0)


func _check_directive_catalog_contains_ore_sources() -> void:
	var profiles: Array = RunManager.get_route_directive_profiles()
	var targets := {}
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		if String(profile.get("goal_type", "")) != "complete_ore_source":
			continue
		var target := String(profile.get("target", ""))
		targets[target] = true
		for key in ["title", "description", "reward_text"]:
			_assert_chinese_copy(String(profile.get(key, "")), "ore source directive %s" % key)
			if _failed:
				return
		var reward: Dictionary = profile.get("reward", {})
		if int(reward.get("minerals", 0)) <= 0:
			_fail("Ore source directive should grant minerals: %s" % str(profile))
			return
	if targets.size() < 4:
		_fail("Route directive catalog should include all ore source goals, got: %s" % str(targets.keys()))


func _check_ore_source_directive_completion() -> void:
	RunManager.start_new_run()
	var source_id := "gleam_crystal"
	var node_id := _first_node_with_source(source_id)
	if node_id <= 0:
		_fail("Need an accessible or reachable gleam crystal node for directive check.")
		return
	RunManager.active_route_directives = [
		{
			"directive_id": "test_gleam_chain",
			"title": "采亮辉晶航线",
			"description": "方舟把辉晶簇标成优先回收目标。",
			"goal_type": "complete_ore_source",
			"target": source_id,
			"current": 0,
			"required": 1,
			"reward": {"minerals": 44, "shop_focus_ore_source": source_id, "shop_focus_text": "辉晶采购校准"},
			"reward_text": "星髓矿 +44，辉晶采购校准",
			"completed": false,
			"claimed": false,
		},
	]
	_force_accessible(node_id)
	if not RunManager.start_explore_node(node_id):
		_fail("Ore source target node should start exploration.")
		return
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var result: Dictionary = RunManager.complete_explore_room_success()
	var completed: Array = result.get("completed_route_directives", [])
	if completed.size() != 1:
		_fail("Completing matching ore source should finish directive: %s" % str(result))
		return
	var reward_summary: Dictionary = result.get("route_directive_rewards", {})
	if int(reward_summary.get("minerals", 0)) < 44:
		_fail("Ore source directive should grant mineral reward: %s" % str(reward_summary))
		return
	if String(reward_summary.get("shop_focus_ore_source", "")) != source_id:
		_fail("Reward summary should include shop focus ore source: %s" % str(reward_summary))
		return
	if not String(RunManager.shop_ore_source_focus).contains("gleam_crystal"):
		_fail("RunManager should remember ore source shop focus, got %s." % String(RunManager.shop_ore_source_focus))
		return


func _check_popup_copy() -> void:
	var packed := load(ROUTE_DIRECTIVE_POPUP_PATH) as PackedScene
	if packed == null:
		_fail("Route directive popup scene should exist.")
		return
	var popup := packed.instantiate()
	add_child(popup)
	popup.call("setup", {
		"completed_directives": [
			{
				"title": "采亮辉晶航线",
				"description": "辉晶航线已被方舟接管。",
				"progress_text": "进度 1/1",
				"reward_text": "星髓矿 +44，辉晶采购校准",
				"reward_result": {
					"minerals": 44,
					"shop_focus_ore_source": "gleam_crystal",
					"shop_focus_text": "辉晶采购校准",
				},
			},
		],
		"reward_summary": {
			"minerals": 44,
			"shop_focus_ore_source": "gleam_crystal",
			"shop_focus_text": "辉晶采购校准",
		},
	})
	await get_tree().process_frame
	var body := popup.get_node_or_null("Panel/BodyLabel") as RichTextLabel
	if body == null:
		_fail("Route directive popup should expose body label.")
		popup.queue_free()
		return
	if not body.text.contains("采亮辉晶航线") or not body.text.contains("辉晶采购校准"):
		_fail("Route directive popup should show ore source reward copy. Body: %s" % body.text)
		popup.queue_free()
		return
	for hidden in ["gleam_crystal", "complete_ore_source", "shop_focus_ore_source"]:
		if body.text.contains(hidden):
			_fail("Ore source directive popup should hide internal ids: %s" % body.text)
			popup.queue_free()
			return
	popup.queue_free()


func _first_node_with_source(source_id: String) -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		if String(node.get("ore_source_bias", "")) == source_id:
			return node_id
	return -1


func _force_accessible(node_id: int) -> void:
	var node := RunManager.get_map_node(node_id)
	for raw_link in node.get("links", []):
		var link_id := int(raw_link)
		if link_id < 0 or link_id >= RunManager.map_nodes.size():
			continue
		var linked := RunManager.map_nodes[link_id]
		linked["completed"] = true
		RunManager.map_nodes[link_id] = linked
		return


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
