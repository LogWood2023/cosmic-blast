extends Node

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const SHOP_POPUP_SCENE := preload("res://scenes/ui/world_map/ShopPopup.tscn")
const HANGAR_POPUP_SCENE := preload("res://scenes/ui/world_map/HangarPopup.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_catalog_copy()
	if _failed:
		return
	await _check_shop_card_format()
	if _failed:
		return
	await _check_hangar_card_format()
	if _failed:
		return
	print("Equipment UI summary check passed.")
	get_tree().quit(0)


func _check_catalog_copy() -> void:
	var all_ids: Array[String] = []
	all_ids.append_array(EquipmentCatalogScript.get_weapon_item_ids())
	all_ids.append_array(EquipmentCatalogScript.get_auxiliary_item_ids(true))
	for item_id in all_ids:
		var item := EquipmentCatalogScript.get_item(item_id)
		if String(item.get("name", "")).strip_edges().is_empty():
			_fail("Equipment name should exist for %s." % item_id)
			return
		if EquipmentCatalogScript.get_effect_summary_text(item_id).strip_edges().is_empty():
			_fail("Equipment actual effect should exist for %s." % item_id)
			return
		if String(item.get("description", "")).strip_edges().is_empty():
			_fail("Equipment flavor text should exist for %s." % item_id)
			return


func _check_shop_card_format() -> void:
	RunManager.minerals = 999
	RunManager.shop_offer_ids = ["impact_servos"]
	RunManager.shop_draft_initialized = true
	var popup := SHOP_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	var row := _first_row(popup)
	if row == null:
		return
	_check_row_copy(row, "impact_servos")
	var action_button := row.get_node("ActionButton") as Button
	var card_button := row.get_node("InfoPanel/CardButton") as Button
	var price_label := row.get_node("InfoPanel/Margin/Inner/InfoBox/ContextLabel") as Label
	if action_button.visible:
		_fail("Shop equipment should not show a separate purchase button.")
		return
	if card_button.disabled:
		_fail("Buyable shop equipment card should be clickable.")
		return
	if price_label.get_theme_font_size("font_size") != 23:
		_fail("Shop equipment price should use the enlarged 1.5x font size.")
		return
	card_button.pressed.emit()
	if not RunManager.equipment_inventory.has("impact_servos"):
		_fail("Clicking the shop equipment card should purchase that equipment.")
		return
	popup.queue_free()


func _check_hangar_card_format() -> void:
	RunManager.equipment_inventory = ["pulse_cannon", "impact_servos"]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries.clear()
	var popup := HANGAR_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.set("_active_type", EquipmentCatalogScript.TYPE_AUX)
	popup.call("setup")
	await get_tree().process_frame
	var row := _first_row(popup)
	if row == null:
		return
	_check_row_copy(row, "impact_servos")
	var equipped_frame := popup.get_node("Panel/CurrentEquipment/EquippedFrame") as Panel
	var current_name := popup.get_node("Panel/CurrentEquipment/CurrentName") as Label
	var fixed_weapon_name := current_name.text
	if not equipped_frame.visible:
		_fail("Auxiliary tab should show the fixed equipped auxiliary area.")
		return
	popup.call("_set_active_type", EquipmentCatalogScript.TYPE_WEAPON)
	if not equipped_frame.visible:
		_fail("Weapon tab should keep the equipped auxiliary area visible.")
		return
	if current_name.text != fixed_weapon_name:
		_fail("Switching inventory tabs should not replace the fixed weapon panel.")
		return
	popup.queue_free()


func _first_row(popup: Node) -> Node:
	var list := popup.get_node("Panel/ItemsScroll/ItemsList")
	if list.get_child_count() == 0:
		_fail("Equipment popup should create at least one item row.")
		return null
	return list.get_child(0)


func _check_row_copy(row: Node, item_id: String) -> void:
	var item := EquipmentCatalogScript.get_item(item_id)
	var name_label := row.get_node("InfoPanel/Margin/Inner/InfoBox/NameLabel") as Label
	var category_label := row.get_node("InfoPanel/Margin/Inner/InfoBox/CategoryLabel") as Label
	var effect_label := row.get_node("InfoPanel/Margin/Inner/InfoBox/EffectLabel") as Label
	var flavor_label := row.get_node("InfoPanel/Margin/Inner/InfoBox/FlavorLabel") as Label
	if name_label.text != String(item.get("name", "")):
		_fail("Equipment card name does not match catalog data.")
	elif category_label.text not in ["武器", "辅助机"]:
		_fail("Equipment card should show only its category, got %s." % category_label.text)
	elif effect_label.text != EquipmentCatalogScript.get_effect_summary_text(item_id):
		_fail("Equipment card actual effect does not match catalog summary.")
	elif flavor_label.text != String(item.get("description", "")):
		_fail("Equipment card flavor text does not match catalog description.")
	for forbidden in ["普通", "稀有", "史诗", "星间巨构", "天堂号", "扭曲星核"]:
		if category_label.text.contains(forbidden):
			_fail("Equipment category should not include family or rarity: %s." % category_label.text)
			return


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
