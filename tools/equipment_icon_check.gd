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
		if icon_path.is_empty():
			_fail("Item %s should expose an icon path." % item_id)
			return
		if not FileAccess.file_exists(icon_path):
			_fail("Icon file is missing for %s at %s." % [item_id, icon_path])
			return

	var row = ITEM_ROW_SCENE.instantiate()
	add_child(row)
	var icon_node := row.get_node_or_null("InfoPanel/CrestSlot/IconTexture") as TextureRect
	if icon_node == null:
		_fail("EquipmentItemRow should contain InfoPanel/CrestSlot/IconTexture.")
		return
	var family_stripe := row.get_node_or_null("InfoPanel/CrestSlot/FamilyStripe") as ColorRect
	var family_label := row.get_node_or_null("InfoPanel/CrestSlot/FamilyLabel") as Label
	var rarity_badge := row.get_node_or_null("InfoPanel/CrestSlot/RarityBadge") as Label
	if family_stripe == null or family_label == null or rarity_badge == null:
		_fail("EquipmentItemRow should expose family stripe, family label and rarity badge nodes.")
		return

	var sample_id := checked_ids[0]
	var sample_item := EquipmentCatalogScript.get_item(sample_id)
	row.setup(
		sample_id,
		String(sample_item.get("name", sample_id)),
		"weapon",
		String(sample_item.get("description", "")),
		"equip",
		false
	)
	await get_tree().process_frame
	if icon_node.texture == null:
		_fail("EquipmentItemRow should load a texture during setup().")
		return

	var notch_row := row.get_node_or_null("InfoPanel/CrestSlot/NotchRow") as HBoxContainer
	if notch_row == null:
		_fail("EquipmentItemRow should contain a compute notch row.")
		return
	if notch_row.get_child_count() < 7:
		_fail("EquipmentItemRow should show up to 7 compute notches, got %d." % notch_row.get_child_count())
		return

	row.setup(
		"aux_notch_probe",
		"aux notch probe",
		"aux / compute 7",
		"probe",
		"equip",
		false
	)
	await get_tree().process_frame
	var active_notches := 0
	for child in notch_row.get_children():
		if (child as CanvasItem).modulate != Color(0.28, 0.38, 0.45, 0.68):
			active_notches += 1
	if active_notches < 7:
		_fail("EquipmentItemRow should activate 7 compute notches for cost 7, got %d." % active_notches)
		return

	row.setup(
		"impact_servos",
		String(EquipmentCatalogScript.get_display_name("impact_servos")),
		EquipmentCatalogScript.get_ui_meta_text("impact_servos", true, EquipmentCatalogScript.get_price("impact_servos")),
		String(EquipmentCatalogScript.get_item("impact_servos").get("description", "")),
		"购买",
		false
	)
	await get_tree().process_frame
	active_notches = _count_active_notches(notch_row)
	if active_notches != EquipmentCatalogScript.get_compute_cost("impact_servos"):
		_fail("EquipmentItemRow should use catalog compute cost for impact_servos, expected %d notches, got %d." % [EquipmentCatalogScript.get_compute_cost("impact_servos"), active_notches])
		return
	if family_label.text != "巨构":
		_fail("EquipmentItemRow should show short family label for colossus auxiliaries, got %s." % family_label.text)
		return
	if rarity_badge.text != "普通":
		_fail("EquipmentItemRow should show rarity badge for common auxiliaries, got %s." % rarity_badge.text)
		return
	var colossus_color := family_stripe.color

	row.setup(
		"comet_shredder",
		String(EquipmentCatalogScript.get_display_name("comet_shredder")),
		EquipmentCatalogScript.get_ui_meta_text("comet_shredder", true, EquipmentCatalogScript.get_price("comet_shredder")),
		String(EquipmentCatalogScript.get_item("comet_shredder").get("description", "")),
		"购买",
		false
	)
	await get_tree().process_frame
	if row.get_node("InfoPanel/CrestSlot/CrestMark").text != "武":
		_fail("EquipmentItemRow should keep weapon crest mark for weapon rows with rich meta text.")
		return
	active_notches = _count_active_notches(notch_row)
	if active_notches != 0:
		_fail("EquipmentItemRow should not light compute notches for weapons, got %d." % active_notches)
		return
	if family_label.text != "通用":
		_fail("EquipmentItemRow should show general family label for neutral weapons, got %s." % family_label.text)
		return
	if rarity_badge.text != "普通":
		_fail("EquipmentItemRow should show rarity badge for common weapons, got %s." % rarity_badge.text)
		return
	if family_stripe.color == colossus_color:
		_fail("EquipmentItemRow family stripe should change color between families.")
		return

	row.setup(
		"colossus_titan_piston",
		String(EquipmentCatalogScript.get_display_name("colossus_titan_piston")),
		EquipmentCatalogScript.get_ui_meta_text("colossus_titan_piston", false, 0),
		String(EquipmentCatalogScript.get_item("colossus_titan_piston").get("description", "")),
		"装配",
		false
	)
	await get_tree().process_frame
	if rarity_badge.text != "史诗":
		_fail("EquipmentItemRow should show epic rarity badge, got %s." % rarity_badge.text)
		return

	print("Equipment icon check passed.")
	get_tree().quit(0)


func _get_all_equipment_ids() -> Array[String]:
	var ids: Array[String] = []
	for item_id in EquipmentCatalogScript.get_weapon_item_ids():
		ids.append(item_id)
	for item_id in EquipmentCatalogScript.get_auxiliary_item_ids(true):
		ids.append(item_id)
	return ids


func _count_active_notches(notch_row: HBoxContainer) -> int:
	var active_notches := 0
	for child in notch_row.get_children():
		if (child as CanvasItem).modulate != Color(0.28, 0.38, 0.45, 0.68):
			active_notches += 1
	return active_notches


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
