extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const WORLD_MAP_SCENE := preload("res://scenes/ui/world_map/WorldMapUI.tscn")
const ARCHIVE_POPUP_PATH: String = "res://scenes/ui/world_map/EquipmentArchivePopup.tscn"

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	RunManager.equipment_inventory = [
		"pulse_cannon",
		"impact_servos",
		"colossus_titan_piston",
	]
	await _check_archive_popup_catalog_rows()
	if _failed:
		return
	await _check_archive_filters()
	if _failed:
		return
	await _check_world_map_archive_entry()
	if _failed:
		return
	print("Equipment archive check passed.")
	get_tree().quit(0)


func _check_archive_popup_catalog_rows() -> void:
	var archive_scene := _load_archive_scene()
	if archive_scene == null:
		return
	var popup := archive_scene.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	if _failed:
		return

	for path in [
		"Panel/ItemsScroll/ItemsList",
		"Panel/FamilyFilterBar/ColossusButton",
		"Panel/FamilyFilterBar/ParadiseButton",
		"Panel/TypeFilterBar/AllButton",
		"Panel/TypeFilterBar/WeaponButton",
		"Panel/TypeFilterBar/AuxButton",
		"Panel/SummaryLabel",
		"Panel/CloseButton",
	]:
		if popup.get_node_or_null(path) == null:
			_fail("Equipment archive popup should expose %s." % path)
			return

	var expected_count := EquipmentCatalogScript.get_weapon_item_ids().size() + EquipmentCatalogScript.get_auxiliary_item_ids(true).size()
	var list := popup.get_node("Panel/ItemsScroll/ItemsList")
	if list.get_child_count() != expected_count:
		_fail("Equipment archive should show the full catalog, expected %d rows, got %d." % [expected_count, list.get_child_count()])
		return

	var joined := _join_visible_row_text(popup)
	for expected in ["脉冲机炮", "冲击伺服肢", "已入库", "未入库", "星间巨构", "史诗"]:
		if not joined.contains(expected):
			_fail("Equipment archive should include %s, got: %s" % [expected, joined])
			return
	if _contains_ascii_letter(joined):
		_fail("Equipment archive visible copy should stay Chinese, got: %s" % joined)
		return

	var summary_label := popup.get_node("Panel/SummaryLabel") as Label
	var expected_weapon_count := EquipmentCatalogScript.get_weapon_item_ids().size()
	var expected_auxiliary_count := EquipmentCatalogScript.get_auxiliary_item_ids(true).size()
	for expected in ["纹章", "已入库 3", "武器 %d" % expected_weapon_count, "辅助机 %d" % expected_auxiliary_count]:
		if not summary_label.text.contains(expected):
			_fail("Archive summary should include %s, got: %s" % [expected, summary_label.text])
			return
	popup.queue_free()


func _check_archive_filters() -> void:
	var archive_scene := _load_archive_scene()
	if archive_scene == null:
		return
	var popup := archive_scene.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	if _failed:
		return

	var family_bar := popup.get_node("Panel/FamilyFilterBar")
	var colossus_button := family_bar.get_node("ColossusButton") as Button
	colossus_button.pressed.emit()
	await get_tree().process_frame
	var colossus_text := _join_visible_row_text(popup)
	if not colossus_text.contains("星间巨构"):
		_fail("Colossus archive filter should keep colossus rows visible.")
		return
	if _visible_meta_contains(popup, "辅助机 / 天堂号"):
		_fail("Colossus archive filter should hide paradise auxiliary rows, got: %s" % colossus_text)
		return

	var type_bar := popup.get_node("Panel/TypeFilterBar")
	var weapon_button := type_bar.get_node("WeaponButton") as Button
	weapon_button.pressed.emit()
	await get_tree().process_frame
	var weapon_text := _join_visible_row_text(popup)
	if not weapon_text.contains("武器"):
		_fail("Weapon archive filter should keep weapon rows visible.")
		return
	if weapon_text.contains("辅助机"):
		_fail("Weapon archive filter should hide auxiliary rows, got: %s" % weapon_text)
		return
	popup.queue_free()


func _check_world_map_archive_entry() -> void:
	var world_map := WORLD_MAP_SCENE.instantiate()
	add_child(world_map)
	await get_tree().process_frame
	var archive_button := world_map.get_node_or_null("DetailsPanel/ArchiveButton") as Button
	if archive_button == null:
		_fail("World map center panel should expose DetailsPanel/ArchiveButton.")
		return
	if archive_button.text != "纹章档案":
		_fail("Archive button should use polished Chinese copy, got: %s" % archive_button.text)
		return
	archive_button.pressed.emit()
	await get_tree().process_frame
	if _failed:
		return
	if world_map.get_node_or_null("EquipmentArchivePopup") == null:
		_fail("Archive button should open EquipmentArchivePopup as an independent scene.")
		return
	world_map.queue_free()


func _join_visible_row_text(popup: Node) -> String:
	var list := popup.get_node("Panel/ItemsScroll/ItemsList")
	var parts: Array[String] = []
	for row in list.get_children():
		if row is CanvasItem and not (row as CanvasItem).visible:
			continue
		var labels: Array[String] = []
		for label_path in [
			"InfoPanel/InfoBox/NameLabel",
			"InfoPanel/InfoBox/MetaLabel",
			"InfoPanel/InfoBox/DescriptionLabel",
			"ActionButton",
		]:
			var label := row.get_node_or_null(label_path)
			if label != null and label.get("text") != null:
				labels.append(String(label.get("text")))
		parts.append(" / ".join(labels))
	return "\n".join(parts)


func _visible_meta_contains(popup: Node, text: String) -> bool:
	var list := popup.get_node("Panel/ItemsScroll/ItemsList")
	for row in list.get_children():
		if row is CanvasItem and not (row as CanvasItem).visible:
			continue
		var meta_label := row.get_node_or_null("InfoPanel/InfoBox/MetaLabel") as Label
		if meta_label != null and meta_label.text.contains(text):
			return true
	return false


func _load_archive_scene() -> PackedScene:
	if not ResourceLoader.exists(ARCHIVE_POPUP_PATH):
		_fail("Equipment archive popup should be a standalone scene at %s." % ARCHIVE_POPUP_PATH)
		return null
	var scene := load(ARCHIVE_POPUP_PATH) as PackedScene
	if scene == null:
		_fail("Equipment archive popup scene should load as a PackedScene.")
	return scene


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
