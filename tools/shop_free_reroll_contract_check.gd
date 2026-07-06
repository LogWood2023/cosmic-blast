extends Node


const SHOP_POPUP_SCENE := preload("res://scenes/ui/world_map/ShopPopup.tscn")
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_free_reroll_contract_catalog()
	if _failed:
		return
	_check_free_reroll_consumes_voucher_without_paid_penalty()
	if _failed:
		return
	await _check_shop_popup_free_reroll_copy()
	if _failed:
		return
	print("Shop free reroll contract check passed.")
	get_tree().quit(0)


func _check_free_reroll_contract_catalog() -> void:
	if not RunManager.has_method("get_free_shop_reroll_summary"):
		_fail("RunManager should expose get_free_shop_reroll_summary() for shop reroll vouchers.")
		return
	var found := false
	for raw_contract in RunManager.get_event_contract_profiles():
		var contract := Dictionary(raw_contract)
		if String(contract.get("contract_id", "")) != "shop_reroll_voucher":
			continue
		found = true
		if int(contract.get("free_shop_rerolls", 0)) <= 0:
			_fail("Shop reroll voucher contract should expose free_shop_rerolls: %s" % str(contract))
			return
		var text := "%s\n%s" % [String(contract.get("title", "")), String(contract.get("description", ""))]
		for expected in ["货单", "免矿", "重抽"]:
			if not text.contains(expected):
				_fail("Shop reroll voucher copy should mention %s, got: %s" % [expected, text])
				return
		if _contains_ascii_letter(text):
			_fail("Shop reroll voucher copy should be Chinese-facing copy: %s" % text)
			return
	if not found:
		_fail("Event contract library should include shop_reroll_voucher.")


func _check_free_reroll_consumes_voucher_without_paid_penalty() -> void:
	RunManager.start_new_run()
	var event_id := _force_accessible_event_node(1)
	RunManager.force_next_event_id = "procurement_reroll_voucher"
	var choices: Array = RunManager.prepare_event_choices(event_id, 11031)
	if choices.is_empty() or String(choices[0].get("choice_id", "")) != "procurement_reroll_voucher":
		_fail("Forced reroll voucher event should be offered first: %s" % str(choices))
		return
	var preview := String(choices[0].get("contract_preview", ""))
	if not preview.contains("免矿") or not preview.contains("重抽"):
		_fail("Reroll voucher choice should preview its free reroll: %s" % str(choices[0]))
		return
	GameManager.player_hp = 100
	var result: Dictionary = RunManager.resolve_event_choice(event_id, "procurement_reroll_voucher", 11031)
	if not bool(result.get("ok", false)):
		_fail("Reroll voucher event should resolve: %s" % str(result))
		return
	var summaries: Array = RunManager.get_active_event_contract_summaries()
	if summaries.size() != 1:
		_fail("Reroll voucher should create one active contract: %s" % str(summaries))
		return
	var summary := Dictionary(summaries[0])
	if not String(summary.get("effects_text", "")).contains("免矿重抽"):
		_fail("Active reroll voucher summary should show free reroll copy: %s" % str(summary))
		return
	var voucher_summary: Dictionary = RunManager.call("get_free_shop_reroll_summary")
	if int(voucher_summary.get("remaining", 0)) != 1:
		_fail("Free reroll summary should report one voucher: %s" % str(voucher_summary))
		return

	var before_offers := RunManager.get_shop_offer_ids()
	var paid_cost := RunManager.SHOP_REROLL_BASE_COST
	if int(RunManager.get_shop_reroll_cost()) != 0:
		_fail("Shop reroll cost should be 0 while a free voucher is ready.")
		return
	RunManager.minerals = 0
	var before_reroll_count := int(RunManager.shop_reroll_count)
	var reroll: Dictionary = RunManager.reroll_shop_offers(EquipmentCatalogScript.FAMILY_WARPED)
	if not bool(reroll.get("ok", false)):
		_fail("Free reroll should succeed without minerals: %s" % str(reroll))
		return
	if int(reroll.get("cost", -1)) != 0 or not bool(reroll.get("free_reroll", false)):
		_fail("Free reroll result should expose cost 0 and free_reroll=true: %s" % str(reroll))
		return
	if RunManager.minerals != 0:
		_fail("Free reroll should not spend minerals, remaining=%d." % int(RunManager.minerals))
		return
	if int(RunManager.shop_reroll_count) != before_reroll_count:
		_fail("Free reroll should not raise the paid reroll price ladder.")
		return
	if RunManager.get_shop_offer_ids() == before_offers:
		_fail("Free reroll should still replace the active shop draft.")
		return
	voucher_summary = RunManager.call("get_free_shop_reroll_summary")
	if int(voucher_summary.get("remaining", 0)) != 0:
		_fail("Free reroll voucher should be consumed after use: %s" % str(voucher_summary))
		return
	if int(RunManager.get_shop_reroll_cost()) != paid_cost:
		_fail("Paid reroll cost should return to base after voucher use, got %d." % int(RunManager.get_shop_reroll_cost()))
		return

	_complete_plain_node()
	if _failed:
		return
	_complete_plain_node()
	if _failed:
		return
	if not RunManager.get_active_event_contracts().is_empty():
		_fail("Reroll voucher contract should expire after its duration: %s" % str(RunManager.get_active_event_contracts()))


func _check_shop_popup_free_reroll_copy() -> void:
	RunManager.start_new_run()
	var event_id := _force_accessible_event_node(1)
	RunManager.force_next_event_id = "procurement_reroll_voucher"
	GameManager.player_hp = 100
	var result: Dictionary = RunManager.resolve_event_choice(event_id, "procurement_reroll_voucher", 11047)
	if not bool(result.get("ok", false)):
		_fail("Reroll voucher event should resolve before UI check: %s" % str(result))
		return
	RunManager.minerals = 0
	var popup := SHOP_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	var combined := _collect_text(popup)
	var reroll_button := popup.get_node_or_null("Panel/ControlsBar/RerollButton") as Button
	var button_text := reroll_button.text if reroll_button != null else ""
	var button_disabled := reroll_button.disabled if reroll_button != null else true
	popup.queue_free()
	if button_disabled:
		_fail("Shop reroll button should stay enabled with a free voucher and no minerals.")
		return
	for expected in ["免矿重抽", "货单券"]:
		if not ("%s\n%s" % [combined, button_text]).contains(expected):
			_fail("Shop popup should show %s while free reroll voucher is ready. Text: %s Button: %s" % [expected, combined, button_text])
			return
	if _contains_ascii_identifier("%s\n%s" % [combined, button_text]):
		_fail("Shop popup free reroll copy should stay Chinese-facing: %s / %s" % [combined, button_text])


func _complete_plain_node() -> void:
	var node_id := _force_accessible_node(RunManager.NODE_BATTLE, 1)
	RunManager.current_node_id = node_id
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var summary := RunManager.complete_explore_room_success()
	if not bool(summary.get("ok", false)):
		_fail("Completing a plain node should tick voucher contract: %s" % str(summary))


func _force_accessible_event_node(tier: int) -> int:
	return _force_accessible_node(RunManager.NODE_EVENT, tier)


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


func _collect_text(root: Node) -> String:
	var parts: Array[String] = []
	_collect_text_recursive(root, parts)
	return "\n".join(parts)


func _collect_text_recursive(node: Node, parts: Array[String]) -> void:
	if node is Label:
		parts.append((node as Label).text)
	elif node is RichTextLabel:
		parts.append((node as RichTextLabel).text)
	elif node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		_collect_text_recursive(child, parts)


func _contains_ascii_identifier(text: String) -> bool:
	for token in ["shop_reroll_voucher", "procurement_reroll_voucher", "free_shop_rerolls", "voucher", "shop_", "_"]:
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
