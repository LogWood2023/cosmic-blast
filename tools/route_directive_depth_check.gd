extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const ROUTE_DIRECTIVE_POPUP_PATH := "res://scenes/ui/world_map/RouteDirectivePopup.tscn"

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_directive_catalog_depth()
	if _failed:
		return
	_check_shop_focus_reward()
	if _failed:
		return
	await _check_popup_reward_detail()
	if _failed:
		return
	print("Route directive depth check passed.")
	get_tree().quit(0)


func _check_directive_catalog_depth() -> void:
	if not RunManager.has_method("get_route_directive_profiles"):
		_fail("RunManager should expose get_route_directive_profiles() for route directive archive and testing.")
		return
	var profiles: Array = RunManager.get_route_directive_profiles()
	if profiles.size() < 14:
		_fail("Route directive pool should contain at least 14 run goals, got %d." % profiles.size())
		return
	var goal_types := {}
	var target_families := {}
	var has_shop_focus_reward := false
	var has_equipment_reward := false
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		for key in ["id", "title", "description", "goal_type", "required", "reward", "reward_text"]:
			if not profile.has(key):
				_fail("Route directive profile should include %s: %s" % [key, str(profile)])
				return
		for key in ["title", "description", "reward_text"]:
			var text := String(profile.get(key, ""))
			if text.strip_edges().is_empty() or _contains_ascii_letter(text):
				_fail("Route directive %s should be Chinese player-facing copy: %s" % [key, text])
				return
		goal_types[String(profile.get("goal_type", ""))] = true
		if String(profile.get("goal_type", "")) == "complete_family":
			target_families[String(profile.get("target", ""))] = true
		var reward: Dictionary = profile.get("reward", {})
		if not String(reward.get("shop_focus_family", "")).is_empty():
			has_shop_focus_reward = true
		if not String(reward.get("equipment_family", "")).is_empty() or not Array(reward.get("equipment", [])).is_empty():
			has_equipment_reward = true
	if goal_types.size() < 4:
		_fail("Route directives should cover at least 4 goal types, got %s." % str(goal_types.keys()))
		return
	for family in EquipmentCatalogScript.get_boss_family_ids():
		if not target_families.has(String(family)):
			_fail("Route directive pool should include a family route for %s." % String(family))
			return
	if not has_shop_focus_reward:
		_fail("At least one route directive should reward a temporary shop family focus.")
		return
	if not has_equipment_reward:
		_fail("At least one route directive should reward equipment.")


func _check_shop_focus_reward() -> void:
	RunManager.start_new_run()
	RunManager.minerals = 160
	RunManager.shop_preferred_family = ""
	RunManager.shop_beacon_family = ""
	RunManager.shop_offer_ids.clear()
	RunManager.shop_draft_initialized = false
	RunManager.active_route_directives = [
		{
			"directive_id": "test_shop_focus",
			"title": "点亮天堂货栈",
			"description": "方舟把下一批货单导向明亮火线。",
			"goal_type": "complete_nodes",
			"target": "",
			"current": 0,
			"required": 1,
			"reward": {
				"minerals": 12,
				"shop_focus_family": EquipmentCatalogScript.FAMILY_PARADISE,
				"shop_focus_text": "天堂号货单导向",
			},
			"reward_text": "星髓矿 +12，天堂号货单导向",
			"completed": false,
			"claimed": false,
		},
	]
	var node_id := _first_accessible_exploration_node()
	if node_id <= 0:
		_fail("Need an accessible node for shop focus directive check.")
		return
	if not RunManager.start_explore_node(node_id):
		_fail("Accessible node should start exploration.")
		return
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var result: Dictionary = RunManager.complete_explore_room_success()
	var completed: Array = result.get("completed_route_directives", [])
	if completed.size() != 1:
		_fail("Shop focus directive should complete after one node: %s" % str(result))
		return
	if String(RunManager.shop_preferred_family) != EquipmentCatalogScript.FAMILY_PARADISE:
		_fail("Route directive should set shop_preferred_family to paradise, got %s." % String(RunManager.shop_preferred_family))
		return
	if not bool(result.get("shop_directive_focus_changed", false)):
		_fail("Completion summary should flag shop directive focus change: %s" % str(result))
		return
	var reward_summary: Dictionary = result.get("route_directive_rewards", {})
	if String(reward_summary.get("shop_focus_family", "")) != EquipmentCatalogScript.FAMILY_PARADISE:
		_fail("Reward summary should include shop focus family: %s" % str(reward_summary))
		return
	var offers := RunManager.get_shop_offer_ids()
	if _count_family(offers, EquipmentCatalogScript.FAMILY_PARADISE) < 2:
		_fail("Shop focus reward should refresh offers toward paradise, offers=%s" % str(offers))


func _check_popup_reward_detail() -> void:
	var packed := load(ROUTE_DIRECTIVE_POPUP_PATH) as PackedScene
	if packed == null:
		_fail("Route directive popup scene should exist at %s." % ROUTE_DIRECTIVE_POPUP_PATH)
		return
	var item_id := EquipmentCatalogScript.get_random_family_loot_item_id([], 12, EquipmentCatalogScript.FAMILY_WARPED, 777)
	if item_id.is_empty():
		_fail("Need a warped equipment item for popup detail check.")
		return
	var item_name := EquipmentCatalogScript.get_display_name(item_id)
	var popup := packed.instantiate()
	add_child(popup)
	popup.call("setup", {
		"completed_directives": [
			{
				"title": "收束扭曲潮汐",
				"description": "方舟锁住了一段星核回响。",
				"progress_text": "进度 2/2",
				"reward_text": "扭曲星核蓝图，商店导向",
				"reward_result": {
					"equipment": [item_id],
					"equipment_names": [item_name],
					"shop_focus_family": EquipmentCatalogScript.FAMILY_WARPED,
					"shop_focus_text": "扭曲星核货单导向",
				},
			},
		],
		"reward_summary": {
			"equipment": [item_id],
			"equipment_names": [item_name],
			"shop_focus_family": EquipmentCatalogScript.FAMILY_WARPED,
			"shop_focus_text": "扭曲星核货单导向",
		},
	})
	await get_tree().process_frame
	var body_label := popup.get_node_or_null("Panel/BodyLabel") as RichTextLabel
	if body_label == null:
		_fail("Route directive popup should expose BodyLabel.")
		popup.queue_free()
		return
	if not body_label.text.contains(item_name):
		_fail("Route directive popup should show rewarded equipment name %s. Body: %s" % [item_name, body_label.text])
		popup.queue_free()
		return
	if not body_label.text.contains("扭曲星核货单导向"):
		_fail("Route directive popup should show shop focus reward copy. Body: %s" % body_label.text)
		popup.queue_free()
		return
	popup.queue_free()


func _first_accessible_exploration_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		if bool(node.get("completed", false)):
			continue
		if RunManager.is_node_accessible(node_id):
			return node_id
	return -1


func _count_family(item_ids: Array, family: String) -> int:
	var count := 0
	for item_id in item_ids:
		if EquipmentCatalogScript.get_family(String(item_id)) == family:
			count += 1
	return count


func _contains_ascii_letter(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
