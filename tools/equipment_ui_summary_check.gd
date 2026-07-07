extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const SHOP_POPUP_SCENE := preload("res://scenes/ui/world_map/ShopPopup.tscn")
const HANGAR_POPUP_SCENE := preload("res://scenes/ui/world_map/HangarPopup.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_catalog_summary_api()
	if _failed:
		return
	await _check_shop_rows_show_build_summary()
	if _failed:
		return
	await _check_hangar_rows_show_build_summary()
	if _failed:
		return
	await _check_hangar_family_filter()
	if _failed:
		return
	await _check_hangar_family_recommendation()
	if _failed:
		return
	await _check_hangar_archetype_sync_summary()
	if _failed:
		return
	print("Equipment UI summary check passed.")
	get_tree().quit(0)


func _check_catalog_summary_api() -> void:
	var catalog = EquipmentCatalogScript.new()
	for method in ["get_family_display_name", "get_rarity_display_name", "get_effect_summary_text", "get_build_tags", "get_build_summary_text", "get_ui_meta_text"]:
		if not catalog.has_method(method):
			_fail("EquipmentCatalog should expose %s for equipment UI summaries." % method)
			return
	var summary := String(catalog.call("get_effect_summary_text", "impact_servos"))
	if summary.is_empty() or not summary.contains("冲锋"):
		_fail("Effect summary should explain colossus dash value, got: %s" % summary)
		return
	if _contains_ascii_letter(summary):
		_fail("Effect summary should be Chinese UI copy: %s" % summary)
		return
	var meta := String(catalog.call("get_ui_meta_text", "impact_servos", false, 0))
	for expected in ["星间巨构", "普通", "算力", "冲锋", "撞击"]:
		if not meta.contains(expected):
			_fail("UI meta should include %s, got: %s" % [expected, meta])
			return
	var build_summary := String(catalog.call("get_build_summary_text", "gravity_threader"))
	for expected in ["引力"]:
		if not build_summary.contains(expected):
			_fail("Build summary should name warped play pattern %s, got: %s" % [expected, build_summary])
			return


func _check_shop_rows_show_build_summary() -> void:
	RunManager.minerals = 999
	RunManager.shop_offer_ids = ["impact_servos"]
	RunManager.shop_draft_initialized = true
	var popup := SHOP_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	var meta := _item_meta_containing(popup, "星间巨构")
	for expected in ["星间巨构", "普通", "算力", "星髓矿", "冲锋", "撞击"]:
		if not meta.contains(expected):
			_fail("Shop item row should show %s in build summary, got: %s" % [expected, meta])
			return
	popup.queue_free()


func _check_hangar_rows_show_build_summary() -> void:
	RunManager.equipment_inventory = ["pulse_cannon", "impact_servos"]
	var popup := HANGAR_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	var meta := _first_aux_item_meta(popup)
	for expected in ["星间巨构", "普通", "算力", "冲锋", "撞击"]:
		if not meta.contains(expected):
			_fail("Hangar item row should show %s in build summary, got: %s" % [expected, meta])
			return
	popup.queue_free()


func _check_hangar_family_filter() -> void:
	RunManager.equipment_inventory = [
		"pulse_cannon",
		"impact_servos",
		"paradise_splitter_board",
		"general_stability_chip",
	]
	var popup := HANGAR_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	var filter_bar := popup.get_node_or_null("Panel/FamilyFilterBar") as HBoxContainer
	if filter_bar == null:
		_fail("Hangar popup should expose Panel/FamilyFilterBar for build filtering.")
		return
	var colossus_button := filter_bar.get_node_or_null("ColossusButton") as Button
	if colossus_button == null:
		_fail("Hangar family filter should include ColossusButton.")
		return
	colossus_button.pressed.emit()
	await get_tree().process_frame
	var visible_meta := _visible_item_meta_texts(popup)
	if visible_meta.size() < 2:
		_fail("Colossus filter should keep colossus and general support rows visible, got %d." % visible_meta.size())
		return
	var joined := "\n".join(visible_meta)
	for expected in ["星间巨构", "通用"]:
		if not joined.contains(expected):
			_fail("Colossus filter should show %s rows, got: %s" % [expected, joined])
			return
	if joined.contains("天堂号"):
		_fail("Colossus filter should hide paradise rows, got: %s" % joined)
		return
	var summary_label := popup.get_node_or_null("Panel/LoadoutBar/SummaryLabel") as Label
	if summary_label == null or not summary_label.text.contains("筛选：星间巨构"):
		_fail("Hangar summary should show active family filter, got: %s" % (summary_label.text if summary_label else ""))
		return
	popup.queue_free()


func _check_hangar_family_recommendation() -> void:
	RunManager.compute_capacity = 5
	RunManager.equipped_auxiliaries = []
	RunManager.equipment_inventory = [
		"pulse_cannon",
		"colossus_impact_coil",
		"colossus_ramming_keel",
		"paradise_splitter_board",
		"general_stability_chip",
	]
	var popup := HANGAR_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	var recommendation_bar := popup.get_node_or_null("Panel/RecommendationBar") as HBoxContainer
	if recommendation_bar == null:
		_fail("Hangar popup should expose Panel/RecommendationBar for family recommendations.")
		return
	var filter_bar := popup.get_node_or_null("Panel/FamilyFilterBar") as HBoxContainer
	var colossus_button := filter_bar.get_node_or_null("ColossusButton") as Button
	colossus_button.pressed.emit()
	await get_tree().process_frame
	var title_label := recommendation_bar.get_node_or_null("RecommendationTitle") as Label
	var detail_label := recommendation_bar.get_node_or_null("RecommendationDetail") as Label
	var equip_button := recommendation_bar.get_node_or_null("RecommendationEquipButton") as Button
	if title_label == null or detail_label == null or equip_button == null:
		_fail("Recommendation bar should include title, detail and equip button nodes.")
		return
	if not title_label.text.contains("星间巨构"):
		_fail("Recommendation title should follow active family filter, got: %s" % title_label.text)
		return
	for expected in ["巨构撞击龙骨", "巨构冲击线圈", "算力 5/5"]:
		if not detail_label.text.contains(expected):
			_fail("Recommendation detail should include %s, got: %s" % [expected, detail_label.text])
			return
	if detail_label.text.contains("天堂分流板"):
		_fail("Recommendation detail should not suggest off-family auxiliaries: %s" % detail_label.text)
		return
	equip_button.pressed.emit()
	await get_tree().process_frame
	for expected_item in ["colossus_ramming_keel", "colossus_impact_coil"]:
		if not RunManager.equipped_auxiliaries.has(expected_item):
			_fail("Recommendation equip should install %s, got %s." % [expected_item, str(RunManager.equipped_auxiliaries)])
			return
	if RunManager.equipped_auxiliaries.has("paradise_splitter_board"):
		_fail("Recommendation equip should not install off-family auxiliaries.")
		return
	popup.queue_free()


func _check_hangar_archetype_sync_summary() -> void:
	RunManager.compute_capacity = 7
	RunManager.equipment_inventory = [
		"pulse_cannon",
		"colossus_impact_coil",
		"colossus_ramming_keel",
		"general_stability_chip",
	]
	RunManager.equipped_auxiliaries = [
		"colossus_impact_coil",
		"colossus_ramming_keel",
		"general_stability_chip",
	]
	var popup := HANGAR_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	var sync_label := popup.get_node_or_null("Panel/LoadoutBar/ArchetypeSyncLabel") as Label
	if sync_label == null:
		_fail("Hangar popup should expose Panel/LoadoutBar/ArchetypeSyncLabel for route diagnosis.")
		return
	for expected in ["主导：星间巨构", "同调", "巨构", "通用"]:
		if not sync_label.text.contains(expected):
			_fail("Hangar archetype sync label should include %s, got: %s" % [expected, sync_label.text])
			return
	if _contains_ascii_letter(sync_label.text):
		_fail("Hangar archetype sync label should be Chinese UI copy: %s" % sync_label.text)
		return
	popup.queue_free()


func _visible_item_meta_texts(popup: Node) -> Array[String]:
	var result: Array[String] = []
	var list := popup.get_node("Panel/ItemsScroll/ItemsList")
	for row in list.get_children():
		if row is CanvasItem and not (row as CanvasItem).visible:
			continue
		var meta_label := row.get_node("InfoPanel/InfoBox/MetaLabel") as Label
		result.append(meta_label.text)
	return result


func _first_item_meta(popup: Node) -> String:
	var list := popup.get_node("Panel/ItemsScroll/ItemsList")
	if list.get_child_count() <= 0:
		_fail("Popup should create at least one item row.")
		return ""
	var row := list.get_child(0)
	var meta_label := row.get_node("InfoPanel/InfoBox/MetaLabel") as Label
	return meta_label.text


func _first_aux_item_meta(popup: Node) -> String:
	var list := popup.get_node("Panel/ItemsScroll/ItemsList")
	for row in list.get_children():
		var meta_label := row.get_node("InfoPanel/InfoBox/MetaLabel") as Label
		if meta_label.text.contains("辅助机") and meta_label.text.contains("星间巨构"):
			return meta_label.text
	_fail("Hangar popup should contain an auxiliary item row.")
	return ""


func _item_meta_containing(popup: Node, text: String) -> String:
	var list := popup.get_node("Panel/ItemsScroll/ItemsList")
	for row in list.get_children():
		var meta_label := row.get_node("InfoPanel/InfoBox/MetaLabel") as Label
		if meta_label.text.contains(text):
			return meta_label.text
	_fail("Popup should contain an item row with %s." % text)
	return ""


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
