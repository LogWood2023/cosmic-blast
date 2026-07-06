extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const REWARD_CACHE_CHOICE_POPUP_PATH := "res://scenes/ui/world_map/RewardCacheChoicePopup.tscn"

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var reward_id := _force_reward_node_with_cache_family(EquipmentCatalogScript.FAMILY_COLOSSUS)
	if reward_id <= 0:
		_fail("Need a forced reward node for reward cache depth check.")
		return
	_check_cache_catalog()
	if _failed:
		return
	await _check_family_cache_shop_focus(reward_id)
	if _failed:
		return
	print("Reward cache depth check passed.")
	get_tree().quit(0)


func _check_cache_catalog() -> void:
	if not RunManager.has_method("get_reward_cache_choice_profiles"):
		_fail("RunManager should expose get_reward_cache_choice_profiles() for reward cache archive and UI copy.")
		return
	var profiles: Array = RunManager.get_reward_cache_choice_profiles()
	if profiles.size() < 4:
		_fail("Reward cache choice library should contain at least 4 cache plans, got %d." % profiles.size())
		return
	var seen_types := {}
	var has_shop_focus := false
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		for key in ["cache_type", "title", "description", "preview"]:
			if not profile.has(key):
				_fail("Reward cache profile should include %s: %s" % [key, str(profile)])
				return
		for key in ["title", "description", "preview"]:
			var text := String(profile.get(key, ""))
			if text.strip_edges().is_empty() or _contains_ascii_letter(text):
				_fail("Reward cache %s should be Chinese player-facing copy: %s" % [key, text])
				return
		seen_types[String(profile.get("cache_type", ""))] = true
		if bool(profile.get("shop_focus", false)):
			has_shop_focus = true
	for required_type in ["minerals", "equipment", "family", "shop"]:
		if not seen_types.has(required_type):
			_fail("Reward cache profile library should include %s cache." % required_type)
			return
	if not has_shop_focus:
		_fail("At least one reward cache profile should focus the shop.")


func _check_family_cache_shop_focus(reward_id: int) -> void:
	RunManager.minerals = 120
	RunManager.shop_preferred_family = ""
	RunManager.shop_offer_ids.clear()
	RunManager.shop_draft_initialized = false
	var choices: Array = RunManager.prepare_reward_cache_choices(reward_id, 4401)
	var family_choice := _find_choice_by_type(choices, "family")
	var choice_id := String(family_choice.get("choice_id", ""))
	if choice_id.is_empty():
		_fail("Need a family cache choice for reward cache depth check.")
		return
	if not String(family_choice.get("preview", "")).contains("货单导向"):
		_fail("Family cache preview should show shop focus copy: %s" % str(family_choice))
		return
	var result: Dictionary = RunManager.start_reward_cache_choice(reward_id, choice_id, 5501)
	if not bool(result.get("ok", false)):
		_fail("Starting family reward cache should succeed: %s" % str(result))
		return
	if String(RunManager.shop_preferred_family) != EquipmentCatalogScript.FAMILY_COLOSSUS:
		_fail("Family reward cache should set shop focus to colossus, got %s." % String(RunManager.shop_preferred_family))
		return
	if not bool(result.get("shop_focus_changed", false)):
		_fail("Reward cache start result should report shop focus change: %s" % str(result))
		return
	var config := GameManager.next_explore_room_config.duplicate(true)
	if String(config.get("reward_cache_shop_focus_text", "")).is_empty() or not String(config.get("reward_cache_choice_summary", "")).contains("货单导向"):
		_fail("Explore config should carry reward cache shop focus copy: %s" % str(config))
		return
	var offers := RunManager.get_shop_offer_ids()
	if _count_family(offers, EquipmentCatalogScript.FAMILY_COLOSSUS) < 2:
		_fail("Reward cache shop focus should refresh offers toward colossus, offers=%s" % str(offers))
		return
	await _check_popup_renders_shop_focus(reward_id)


func _check_popup_renders_shop_focus(reward_id: int) -> void:
	var packed := load(REWARD_CACHE_CHOICE_POPUP_PATH) as PackedScene
	if packed == null:
		_fail("Reward cache choice popup scene should exist at %s." % REWARD_CACHE_CHOICE_POPUP_PATH)
		return
	var popup := packed.instantiate()
	add_child(popup)
	var choices: Array = RunManager.prepare_reward_cache_choices(reward_id, 4401)
	popup.call("setup", RunManager.get_map_node(reward_id), choices)
	await get_tree().process_frame
	var list := popup.get_node_or_null("Panel/ChoicesScroll/ChoicesList") as VBoxContainer
	var rendered_text := ""
	if list != null:
		for child in list.get_children():
			if child is Button:
				rendered_text += (child as Button).text
	popup.queue_free()
	if not rendered_text.contains("货单导向"):
		_fail("Reward cache popup should render shop focus copy, got: %s" % rendered_text)


func _find_choice_by_type(choices: Array, cache_type: String) -> Dictionary:
	for raw_choice in choices:
		var choice := Dictionary(raw_choice)
		if String(choice.get("cache_type", "")) == cache_type:
			return choice
	return {}


func _force_reward_node_with_cache_family(cache_family: String) -> int:
	var picked_profile := {}
	for raw_profile in RunManager.get_reward_profiles():
		var profile := Dictionary(raw_profile)
		if String(profile.get("cache_family_bias", "")) == cache_family:
			picked_profile = profile
			break
	if picked_profile.is_empty():
		return -1
	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		node["type"] = RunManager.NODE_REWARD
		node["completed"] = false
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
		RunManager.call("_apply_reward_profile_data_to_node", node, picked_profile)
		RunManager.map_nodes[i] = node
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
