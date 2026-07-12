extends Node

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const ITEM_ROW_SCENE := preload("res://scenes/ui/world_map/EquipmentItemRow.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var checked_ids := _get_all_equipment_ids()
	if checked_ids.is_empty():
		_fail("Equipment icon check needs at least one catalog item.")
		return
	for item_id in checked_ids:
		var item := EquipmentCatalogScript.get_item(item_id)
		var icon_path := String(item.get("icon", ""))
		if icon_path.is_empty() or not FileAccess.file_exists(icon_path):
			_fail("Equipment icon is missing for %s at %s." % [item_id, icon_path])
			return
		if String(item.get("name", "")).strip_edges().is_empty():
			_fail("Equipment name is missing for %s." % item_id)
			return
		if EquipmentCatalogScript.get_effect_summary_text(item_id).strip_edges().is_empty():
			_fail("Equipment effect text is missing for %s." % item_id)
			return
		if String(item.get("description", "")).strip_edges().is_empty():
			_fail("Equipment flavor text is missing for %s." % item_id)
			return

	var row = ITEM_ROW_SCENE.instantiate()
	add_child(row)
	for required_path in [
		"InfoPanel/Margin/Inner/CrestSlot/IconTexture",
		"InfoPanel/Margin/Inner/InfoBox/NameLabel",
		"InfoPanel/Margin/Inner/InfoBox/CategoryLabel",
		"InfoPanel/Margin/Inner/InfoBox/EffectLabel",
		"InfoPanel/Margin/Inner/InfoBox/FlavorLabel",
		"InfoPanel/CardButton",
	]:
		if row.get_node_or_null(required_path) == null:
			_fail("EquipmentItemRow should expose %s." % required_path)
			return
	for removed_path in [
		"InfoPanel/Margin/Inner/CrestSlot/FamilyStripe",
		"InfoPanel/Margin/Inner/CrestSlot/FamilyLabel",
		"InfoPanel/Margin/Inner/CrestSlot/RarityBadge",
		"InfoPanel/Margin/Inner/CrestSlot/NotchRow",
	]:
		if row.get_node_or_null(removed_path) != null:
			_fail("Equipment icon should not include legacy metadata node %s." % removed_path)
			return

	var sample_id := checked_ids[0]
	var sample_item := EquipmentCatalogScript.get_item(sample_id)
	row.setup(sample_id, String(sample_item.get("name", sample_id)), "", String(sample_item.get("description", "")), "装配", false)
	await get_tree().process_frame
	var icon := row.get_node("InfoPanel/Margin/Inner/CrestSlot/IconTexture") as TextureRect
	var category := row.get_node("InfoPanel/Margin/Inner/InfoBox/CategoryLabel") as Label
	var effect := row.get_node("InfoPanel/Margin/Inner/InfoBox/EffectLabel") as Label
	var flavor := row.get_node("InfoPanel/Margin/Inner/InfoBox/FlavorLabel") as Label
	if icon.texture == null:
		_fail("EquipmentItemRow should load the catalog icon during setup().")
		return
	if category.text not in ["武器", "辅助机"]:
		_fail("EquipmentItemRow should show only the equipment category, got %s." % category.text)
		return
	if effect.text != EquipmentCatalogScript.get_effect_summary_text(sample_id):
		_fail("EquipmentItemRow effect text should come from the catalog summary.")
		return
	if flavor.text != String(sample_item.get("description", "")):
		_fail("EquipmentItemRow flavor text should come from the catalog description.")
		return

	print("Equipment icon and copy check passed.")
	get_tree().quit(0)


func _get_all_equipment_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.append_array(EquipmentCatalogScript.get_weapon_item_ids())
	ids.append_array(EquipmentCatalogScript.get_auxiliary_item_ids(true))
	return ids


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
