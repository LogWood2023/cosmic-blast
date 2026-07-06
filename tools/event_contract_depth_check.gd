extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_contract_catalog_depth()
	if _failed:
		return
	await _check_family_contract_shop_focus_and_world_map_copy()
	if _failed:
		return
	print("Event contract depth check passed.")
	get_tree().quit(0)


func _check_contract_catalog_depth() -> void:
	if not RunManager.has_method("get_event_contract_profiles"):
		_fail("RunManager should expose get_event_contract_profiles() for contract archive and UI summaries.")
		return
	var contracts: Array = RunManager.get_event_contract_profiles()
	if contracts.size() < 10:
		_fail("Event contract library should contain at least 10 temporary contracts, got %d." % contracts.size())
		return
	var family_contracts := {}
	var has_shop_focus := false
	var has_mineral_pressure := false
	var has_equipment_pressure := false
	for raw_contract in contracts:
		var contract := Dictionary(raw_contract)
		for key in ["contract_id", "title", "description", "effect_type", "duration_nodes"]:
			if not contract.has(key):
				_fail("Event contract profile should include %s: %s" % [key, str(contract)])
				return
		for key in ["title", "description"]:
			var text := String(contract.get(key, ""))
			if text.strip_edges().is_empty() or _contains_ascii_letter(text):
				_fail("Event contract %s should be Chinese player-facing copy: %s" % [key, text])
				return
		var family := String(contract.get("family_bias", ""))
		if not family.is_empty():
			family_contracts[family] = true
		if not String(contract.get("shop_focus_family", "")).is_empty():
			has_shop_focus = true
		if float(contract.get("mineral_bonus_rate", 0.0)) > 0.0:
			has_mineral_pressure = true
		if float(contract.get("equipment_chance_bonus", 0.0)) > 0.0:
			has_equipment_pressure = true
	for family in EquipmentCatalogScript.get_boss_family_ids():
		if not family_contracts.has(String(family)):
			_fail("Event contracts should include a route contract for %s." % String(family))
			return
	if not has_shop_focus:
		_fail("At least one event contract should temporarily focus the shop toward a family.")
		return
	if not has_mineral_pressure or not has_equipment_pressure:
		_fail("Event contracts should include both mineral and equipment pressure contracts.")


func _check_family_contract_shop_focus_and_world_map_copy() -> void:
	RunManager.start_new_run()
	var event_id := _force_accessible_event_node(2)
	RunManager.force_next_event_id = "paradise_barrage_route"
	var choices: Array = RunManager.prepare_event_choices(event_id, 8801)
	if choices.is_empty() or String(choices[0].get("choice_id", "")) != "paradise_barrage_route":
		_fail("Forced paradise route should be offered first.")
		return
	var preview := String(choices[0].get("contract_preview", ""))
	if preview.is_empty() or not preview.contains("天堂号货单导向"):
		_fail("Paradise contract preview should show shop focus reward: %s" % str(choices[0]))
		return
	GameManager.player_hp = 100
	var result: Dictionary = RunManager.resolve_event_choice(event_id, "paradise_barrage_route", 8801)
	if not bool(result.get("ok", false)):
		_fail("Paradise route event should resolve: %s" % str(result))
		return
	if String(RunManager.shop_preferred_family) != EquipmentCatalogScript.FAMILY_PARADISE:
		_fail("Family contract should set paradise shop focus, got %s." % String(RunManager.shop_preferred_family))
		return
	var summaries: Array = RunManager.get_active_event_contract_summaries()
	if summaries.size() != 1:
		_fail("Signed family contract should appear in active summaries: %s" % str(summaries))
		return
	var summary := Dictionary(summaries[0])
	if String(summary.get("shop_focus_text", "")).is_empty() or not String(summary.get("effects_text", "")).contains("货单导向"):
		_fail("Active contract summary should include shop focus copy: %s" % str(summary))
		return
	var offers := RunManager.get_shop_offer_ids()
	if _count_family(offers, EquipmentCatalogScript.FAMILY_PARADISE) < 2:
		_fail("Family contract should refresh shop offers toward paradise, offers=%s" % str(offers))
		return
	var details_text := await _get_world_map_center_details_text()
	if not details_text.contains("天堂号货单导向"):
		_fail("World map center details should show contract shop focus copy. Details: %s" % details_text)


func _get_world_map_center_details_text() -> String:
	var scene_root := WORLD_MAP_SCENE.instantiate()
	add_child(scene_root)
	await get_tree().process_frame
	var world_map := scene_root.get_node_or_null("WorldMap")
	if world_map == null:
		_fail("World map scene should expose WorldMap UI child.")
		scene_root.queue_free()
		return ""
	world_map.set("_selected_node_id", RunManager.CENTER_ID)
	world_map.call("_refresh_details")
	var body := world_map.find_child("DetailsBody", true, false) as RichTextLabel
	var text := body.text if body != null else ""
	scene_root.queue_free()
	return text


func _force_accessible_event_node(tier: int) -> int:
	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL or int(node.get("tier", 0)) != tier:
			continue
		node["type"] = RunManager.NODE_EVENT
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
