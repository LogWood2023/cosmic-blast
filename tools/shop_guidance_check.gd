extends Node


const SHOP_POPUP_SCENE := preload("res://scenes/ui/world_map/ShopPopup.tscn")
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_seed_colossus_route()
	_check_shop_guidance_api()
	if _failed:
		return
	await _check_shop_guidance_ui()
	if _failed:
		return
	print("Shop guidance check passed.")
	get_tree().quit(0)


func _seed_colossus_route() -> void:
	RunManager.minerals = 9999
	RunManager.equipment_inventory = ["pulse_cannon", "colossus_impact_coil"]
	RunManager.equipped_auxiliaries = ["colossus_impact_coil"]
	var node_id := _pick_accessible_node()
	if node_id <= 0:
		return
	var node := RunManager.map_nodes[node_id]
	node["name"] = "撞角残区"
	node["type"] = RunManager.NODE_BATTLE
	node["family_bias"] = EquipmentCatalogScript.FAMILY_COLOSSUS
	node["completed"] = false
	node["route_plan"] = {
		"title": "撞角残区突破线",
		"summary": "中压交战点，敌群会推动星间巨构流派成形。",
		"family": EquipmentCatalogScript.FAMILY_COLOSSUS,
		"family_name": "星间巨构",
		"reward_hint": "优良回收，撤离结算会放大星髓矿收益。",
		"equipment_hint": "装备机会约 35%，掉落池偏向星间巨构。",
	}
	RunManager.map_nodes[node_id] = node


func _check_shop_guidance_api() -> void:
	if not RunManager.has_method("get_shop_guidance"):
		_fail("RunManager should expose get_shop_guidance() for shop planning.")
		return
	var guidance: Dictionary = RunManager.call("get_shop_guidance")
	for key in ["family", "family_name", "title", "summary", "reroll_hint", "copy_text"]:
		if not guidance.has(key) or String(guidance.get(key, "")).strip_edges().is_empty():
			_fail("Shop guidance should include %s: %s" % [key, str(guidance)])
			return
	if String(guidance.get("family", "")) != EquipmentCatalogScript.FAMILY_COLOSSUS:
		_fail("Shop guidance should follow route guidance family, got: %s" % str(guidance))
		return
	var combined := "%s\n%s\n%s\n%s" % [
		String(guidance.get("title", "")),
		String(guidance.get("summary", "")),
		String(guidance.get("reroll_hint", "")),
		String(guidance.get("copy_text", "")),
	]
	for expected in ["采购校准", "星间巨构", "撞角残区", "货单"]:
		if not combined.contains(expected):
			_fail("Shop guidance copy should include %s, got: %s" % [expected, combined])
			return
	if _contains_ascii_identifier(combined):
		_fail("Shop guidance should use Chinese-facing copy, got: %s" % combined)
		return
	var before := RunManager.shop_reroll_count
	var result: Dictionary = RunManager.reroll_shop_offers()
	if not bool(result.get("ok", false)):
		_fail("Guided shop reroll should succeed with enough minerals: %s" % str(result))
		return
	if int(RunManager.shop_reroll_count) != before + 1:
		_fail("Guided shop reroll should increment reroll count.")
		return
	if String(result.get("preferred_family", "")) != EquipmentCatalogScript.FAMILY_COLOSSUS:
		_fail("Blank shop reroll should follow shop guidance family: %s" % str(result))
		return
	if _count_family(RunManager.get_shop_offer_ids(), EquipmentCatalogScript.FAMILY_COLOSSUS) < 2:
		_fail("Guided shop reroll should surface multiple colossus offers: %s" % str(RunManager.get_shop_offer_ids()))
		return


func _check_shop_guidance_ui() -> void:
	var popup := SHOP_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	if popup.get_node_or_null("Panel/ShopGuidanceBar") != null:
		_fail("Shop guidance should not occupy a separate bar in the audited layout.")
		popup.queue_free()
		return
	var focus_option := popup.get_node_or_null("Panel/ControlsBar/FamilyFocusOption") as OptionButton
	if focus_option == null:
		_fail("Shop popup should expose the family focus control.")
		popup.queue_free()
		return
	var combined := focus_option.tooltip_text
	for expected in ["采购校准", "星间巨构", "货单"]:
		if not combined.contains(expected):
			_fail("Shop guidance tooltip should include %s, got: %s" % [expected, combined])
			popup.queue_free()
			return
	if _contains_ascii_identifier(combined):
		_fail("Shop guidance UI should be polished Chinese copy: %s" % combined)
		popup.queue_free()
		return
	popup.queue_free()


func _pick_accessible_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id > 0 and String(node.get("type", "")) != RunManager.NODE_SPECIAL and RunManager.is_node_accessible(node_id):
			return node_id
	return -1


func _count_family(offer_ids: Array, family: String) -> int:
	var count := 0
	for item_id in offer_ids:
		if EquipmentCatalogScript.get_family(String(item_id)) == family:
			count += 1
	return count


func _contains_ascii_identifier(text: String) -> bool:
	for token in ["colossus", "paradise", "warped", "hell_eye", "divine", "preferred_family", "shop", "_"]:
		if text.contains(token):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
