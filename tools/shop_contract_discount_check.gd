extends Node


const SHOP_POPUP_SCENE := preload("res://scenes/ui/world_map/ShopPopup.tscn")
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_procurement_contract_catalog()
	if _failed:
		return
	_check_procurement_contract_changes_prices_and_expires()
	if _failed:
		return
	await _check_shop_popup_shows_discount_copy()
	if _failed:
		return
	print("Shop contract discount check passed.")
	get_tree().quit(0)


func _check_procurement_contract_catalog() -> void:
	if not RunManager.has_method("get_effective_shop_price"):
		_fail("RunManager should expose get_effective_shop_price() so shop pricing stays centralized.")
		return
	var found := false
	for raw_contract in RunManager.get_event_contract_profiles():
		var contract := Dictionary(raw_contract)
		if String(contract.get("contract_id", "")) != "procurement_discount":
			continue
		found = true
		if float(contract.get("shop_discount_rate", 0.0)) <= 0.0:
			_fail("Procurement contract should expose a shop discount rate: %s" % str(contract))
			return
		var text := "%s\n%s" % [String(contract.get("title", "")), String(contract.get("description", ""))]
		for expected in ["采购", "折扣", "星髓"]:
			if not text.contains(expected):
				_fail("Procurement contract copy should mention %s, got: %s" % [expected, text])
				return
		if _contains_ascii_letter(text):
			_fail("Procurement contract copy should be polished Chinese-facing copy: %s" % text)
			return
	if not found:
		_fail("Event contract library should include procurement_discount.")


func _check_procurement_contract_changes_prices_and_expires() -> void:
	RunManager.start_new_run()
	var event_id := _force_accessible_event_node(1)
	RunManager.force_next_event_id = "procurement_discount"
	var choices: Array = RunManager.prepare_event_choices(event_id, 9901)
	if choices.is_empty() or String(choices[0].get("choice_id", "")) != "procurement_discount":
		_fail("Forced procurement discount event should be offered first: %s" % str(choices))
		return
	var preview := String(choices[0].get("contract_preview", ""))
	if not preview.contains("折扣") or not preview.contains("采购"):
		_fail("Procurement discount choice should preview its shop discount: %s" % str(choices[0]))
		return
	GameManager.player_hp = 100
	RunManager.minerals = 200
	var result: Dictionary = RunManager.resolve_event_choice(event_id, "procurement_discount", 9901)
	if not bool(result.get("ok", false)):
		_fail("Procurement discount event should resolve: %s" % str(result))
		return
	var summaries: Array = RunManager.get_active_event_contract_summaries()
	if summaries.size() != 1:
		_fail("Procurement discount should create one active contract: %s" % str(summaries))
		return
	var summary := Dictionary(summaries[0])
	if not String(summary.get("effects_text", "")).contains("采购折扣"):
		_fail("Active procurement contract summary should show discount copy: %s" % str(summary))
		return

	var item_id := _pick_unowned_shop_item()
	if item_id.is_empty():
		_fail("Shop should provide a buyable unowned item.")
		return
	var base_price := EquipmentCatalogScript.get_price(item_id)
	var discount_price := int(RunManager.call("get_effective_shop_price", item_id))
	if discount_price <= 0 or discount_price >= base_price:
		_fail("Effective shop price should be below base price while contract is active, base=%d effective=%d item=%s." % [base_price, discount_price, item_id])
		return
	RunManager.minerals = discount_price
	var buy_result: Dictionary = RunManager.buy_equipment(item_id)
	if not bool(buy_result.get("ok", false)):
		_fail("Buying with exact discounted minerals should succeed: %s" % str(buy_result))
		return
	if RunManager.minerals != 0:
		_fail("Buying should deduct the effective discounted price, remaining=%d." % int(RunManager.minerals))
		return
	if not String(buy_result.get("message", "")).contains("折扣"):
		_fail("Discounted purchase message should mention the contract discount: %s" % str(buy_result))
		return

	_complete_plain_node()
	if _failed:
		return
	if int(Dictionary(RunManager.get_active_event_contracts()[0]).get("remaining_nodes", 0)) != 1:
		_fail("Procurement discount should tick down after one completed node: %s" % str(RunManager.get_active_event_contracts()))
		return
	_complete_plain_node()
	if _failed:
		return
	if not RunManager.get_active_event_contracts().is_empty():
		_fail("Procurement discount should expire after its duration: %s" % str(RunManager.get_active_event_contracts()))
		return
	var restored_item_id := _pick_unowned_shop_item()
	var restored_price := int(RunManager.call("get_effective_shop_price", restored_item_id))
	var restored_base := EquipmentCatalogScript.get_price(restored_item_id)
	if restored_price != restored_base:
		_fail("Effective shop price should return to base after expiry, base=%d effective=%d." % [restored_base, restored_price])


func _check_shop_popup_shows_discount_copy() -> void:
	RunManager.start_new_run()
	var event_id := _force_accessible_event_node(1)
	RunManager.force_next_event_id = "procurement_discount"
	GameManager.player_hp = 100
	RunManager.minerals = 200
	var result: Dictionary = RunManager.resolve_event_choice(event_id, "procurement_discount", 9917)
	if not bool(result.get("ok", false)):
		_fail("Procurement discount event should resolve before UI check: %s" % str(result))
		return
	var popup := SHOP_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	var combined := _collect_label_text(popup)
	popup.queue_free()
	for expected in ["采购折扣", "折后", "星髓矿"]:
		if not combined.contains(expected):
			_fail("Shop popup should show %s while discount contract is active. Text: %s" % [expected, combined])
			return
	if _contains_ascii_identifier(combined):
		_fail("Shop popup discount copy should stay Chinese-facing: %s" % combined)


func _pick_unowned_shop_item() -> String:
	for item_id in RunManager.get_shop_offer_ids():
		var id := String(item_id)
		if not RunManager.equipment_inventory.has(id) and EquipmentCatalogScript.get_price(id) > 0:
			return id
	return ""


func _complete_plain_node() -> void:
	var node_id := _force_accessible_node(RunManager.NODE_BATTLE, 1)
	RunManager.current_node_id = node_id
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var summary := RunManager.complete_explore_room_success()
	if not bool(summary.get("ok", false)):
		_fail("Completing a plain node should succeed while ticking procurement contract: %s" % str(summary))


func _force_accessible_event_node(tier: int) -> int:
	var node_id := _force_accessible_node(RunManager.NODE_EVENT, tier)
	return node_id


func _force_accessible_node(node_type: String, tier: int) -> int:
	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL or int(node.get("tier", 0)) != tier:
			continue
		node["type"] = node_type
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


func _collect_label_text(root: Node) -> String:
	var parts: Array[String] = []
	_collect_label_text_recursive(root, parts)
	return "\n".join(parts)


func _collect_label_text_recursive(node: Node, parts: Array[String]) -> void:
	if node is Label:
		parts.append((node as Label).text)
	elif node is RichTextLabel:
		parts.append((node as RichTextLabel).text)
	for child in node.get_children():
		_collect_label_text_recursive(child, parts)


func _contains_ascii_identifier(text: String) -> bool:
	for token in ["procurement_discount", "shop_discount_rate", "discount", "shop_", "_"]:
		if text.contains(token):
			return true
	return false


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
