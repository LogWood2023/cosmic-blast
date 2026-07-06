extends Node


const REWARD_CACHE_CHOICE_POPUP_PATH := "res://scenes/ui/world_map/RewardCacheChoicePopup.tscn"
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var reward_id := _force_reward_node_with_cache_family(EquipmentCatalogScript.FAMILY_WARPED)
	if reward_id <= 0:
		_fail("Need a forced reward node for cache choice check.")
		return
	_check_choice_generation(reward_id)
	if _failed:
		return
	await _check_choice_popup(reward_id)
	if _failed:
		return
	_check_choice_application(reward_id)
	if _failed:
		return
	print("Reward cache choice check passed.")
	get_tree().quit(0)


func _check_choice_generation(reward_id: int) -> void:
	if not RunManager.has_method("prepare_reward_cache_choices"):
		_fail("RunManager should expose prepare_reward_cache_choices().")
		return
	var choices: Array = RunManager.prepare_reward_cache_choices(reward_id, 4401)
	if choices.size() != 3:
		_fail("Reward cache should offer exactly 3 choices, got %d." % choices.size())
		return
	var seen_types := {}
	for choice in choices:
		var data := Dictionary(choice)
		var choice_id := String(data.get("choice_id", ""))
		var title := String(data.get("title", ""))
		var description := String(data.get("description", ""))
		var preview := String(data.get("preview", ""))
		var cache_type := String(data.get("cache_type", ""))
		if choice_id.is_empty() or title.is_empty() or description.is_empty() or preview.is_empty() or cache_type.is_empty():
			_fail("Each reward cache choice should expose choice_id/title/description/preview/cache_type: %s" % str(data))
			return
		if _contains_ascii_letter("%s %s %s" % [title, description, preview]):
			_fail("Reward cache choice copy should be polished Chinese UI copy, got: %s" % str(data))
			return
		seen_types[cache_type] = true
	if not seen_types.has("minerals") or not seen_types.has("equipment") or not seen_types.has("family"):
		_fail("Reward cache choices should cover minerals, equipment, and family caches, got: %s" % str(seen_types.keys()))
		return
	var family_choice := _find_choice_by_type(choices, "family")
	if String(family_choice.get("family_bias", "")) != EquipmentCatalogScript.FAMILY_WARPED:
		_fail("Family reward cache should follow node cache family bias: %s" % str(family_choice))
		return
	if not String(family_choice.get("preview", "")).contains("扭曲星核"):
		_fail("Family reward cache preview should show the family name, got: %s" % str(family_choice))
		return


func _check_choice_popup(reward_id: int) -> void:
	var packed := load(REWARD_CACHE_CHOICE_POPUP_PATH) as PackedScene
	if packed == null:
		_fail("Reward cache choice popup scene should exist at %s." % REWARD_CACHE_CHOICE_POPUP_PATH)
		return
	var popup := packed.instantiate()
	add_child(popup)
	var choices: Array = RunManager.prepare_reward_cache_choices(reward_id, 4401)
	popup.call("setup", RunManager.get_map_node(reward_id), choices)
	await get_tree().process_frame
	var title_label := popup.get_node_or_null("Panel/TitleLabel") as Label
	if title_label == null or not title_label.text.contains("奖励缓存"):
		_fail("Reward cache popup should expose a player-facing title.")
		popup.queue_free()
		return
	var list := popup.get_node_or_null("Panel/ChoicesScroll/ChoicesList") as VBoxContainer
	if list == null or list.get_child_count() != 3:
		_fail("Reward cache popup should render 3 selectable cache buttons.")
		popup.queue_free()
		return
	var rendered_text := ""
	for child in list.get_children():
		if child is Button:
			rendered_text += (child as Button).text
	if not rendered_text.contains("星髓") or not rendered_text.contains("蓝图") or not rendered_text.contains("扭曲星核"):
		_fail("Reward cache popup should render mineral, equipment, and family copy, got: %s" % rendered_text)
		popup.queue_free()
		return
	popup.queue_free()


func _check_choice_application(reward_id: int) -> void:
	if not RunManager.has_method("start_reward_cache_choice"):
		_fail("RunManager should expose start_reward_cache_choice().")
		return
	var choices: Array = RunManager.prepare_reward_cache_choices(reward_id, 4401)
	var equipment_choice := _find_choice_by_type(choices, "equipment")
	var choice_id := String(equipment_choice.get("choice_id", ""))
	if choice_id.is_empty():
		_fail("Need an equipment cache choice.")
		return
	var before_chance := RunManager.get_node_equipment_drop_chance(reward_id)
	var result: Dictionary = RunManager.start_reward_cache_choice(reward_id, choice_id, 5501)
	if not bool(result.get("ok", false)):
		_fail("Starting a selected reward cache should succeed: %s" % str(result))
		return
	if RunManager.current_node_id != reward_id:
		_fail("Selected reward cache should enter the chosen reward node.")
		return
	var after_chance := RunManager.get_node_equipment_drop_chance(reward_id)
	if after_chance <= before_chance:
		_fail("Equipment cache should raise equipment drop chance from %.3f to above it, got %.3f." % [before_chance, after_chance])
		return
	var config := GameManager.next_explore_room_config
	if String(config.get("reward_cache_choice_id", "")) != choice_id:
		_fail("Explore room config should carry selected reward_cache_choice_id: %s" % str(config))
		return
	if String(config.get("reward_cache_choice_title", "")).is_empty() or not String(config.get("reward_cache_choice_summary", "")).contains("蓝图"):
		_fail("Explore room config should carry readable reward cache selection copy: %s" % str(config))
		return
	if float(config.get("reward_equipment_chance_bonus", 0.0)) <= 0.0:
		_fail("Explore room config should expose reward_equipment_chance_bonus for selected equipment cache: %s" % str(config))
		return
	GameManager.consume_next_explore_room_config()
	var node_copy := RunManager.map_nodes[reward_id]
	node_copy["equipment_drop_chance"] = 1.0
	RunManager.map_nodes[reward_id] = node_copy
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var previous_inventory: Array[String] = RunManager.equipment_inventory.duplicate()
	for _i in range(4):
		RunManager.record_reward_broken(0)
	var equipment: Array = RunManager.pending_room_loot.get("equipment", [])
	RunManager.equipment_inventory = previous_inventory
	if equipment.is_empty():
		_fail("Selected reward cache should still produce equipment after explore config is consumed.")
		return
	for item_id in equipment:
		if EquipmentCatalogScript.get_family(String(item_id)) != EquipmentCatalogScript.FAMILY_WARPED:
			_fail("Selected reward cache family should survive consumed explore config, got %s family=%s." % [String(item_id), EquipmentCatalogScript.get_family(String(item_id))])
			return
	RunManager.abandon_current_room()


func _find_choice_by_type(choices: Array, cache_type: String) -> Dictionary:
	for choice in choices:
		var data := Dictionary(choice)
		if String(data.get("cache_type", "")) == cache_type:
			return data
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
		node["family_bias"] = EquipmentCatalogScript.FAMILY_COLOSSUS
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
