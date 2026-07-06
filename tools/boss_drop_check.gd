extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var tree := get_tree()
	if not _check_boss_drop_catalog_scale(tree):
		return
	RunManager.start_new_run()
	RunManager.crisis_level = 5
	RunManager.pending_boss_threshold = 5
	RunManager.pending_boss_scene = "res://scenes/gameplay/boss/BossBattle_Frontier.tscn"

	var drop_id := EquipmentCatalogScript.get_boss_drop_for_family("colossus", RunManager.equipment_inventory)
	if drop_id.is_empty():
		push_error("Colossus family should expose a boss-drop equipment id.")
		tree.quit(1)
		return
	if RunManager.equipment_inventory.has(drop_id):
		push_error("Boss drop check expects drop not to be owned before victory.")
		tree.quit(1)
		return

	var handled := RunManager.handle_boss_victory()
	if not handled:
		push_error("RunManager should handle pending crisis boss victory.")
		tree.quit(1)
		return
	if not RunManager.equipment_inventory.has(drop_id):
		push_error("Boss victory should grant colossus boss-drop equipment: %s." % drop_id)
		tree.quit(1)
		return
	if RunManager.last_boss_reward.get("family", "") != "colossus":
		push_error("Boss reward summary should record colossus family.")
		tree.quit(1)
		return
	if not RunManager.has_method("consume_last_boss_completion_summary"):
		push_error("RunManager should expose a consumable mid-run boss reward summary.")
		tree.quit(1)
		return

	var world_map := WORLD_MAP_SCENE.instantiate()
	tree.root.add_child(world_map)
	await tree.process_frame
	var message_label := world_map.get_node("WorldMap/MessageLabel") as Label
	var message := message_label.text
	var drop_name := EquipmentCatalogScript.get_display_name(drop_id)
	var family_name := EquipmentCatalogScript.get_family_display_name(EquipmentCatalogScript.FAMILY_COLOSSUS)
	for expected in ["执行体肃清", "缴获纹章", drop_name, family_name]:
		if not message.contains(expected):
			push_error("World map boss reward feedback should include %s. Message: %s" % [expected, message])
			tree.quit(1)
			return
	for hidden in [drop_id, "colossus", "BossBattle_Frontier.tscn", "res://"]:
		if message.contains(hidden):
			push_error("World map boss reward feedback should hide internal ids and scene paths. Message: %s" % message)
			tree.quit(1)
			return
	var reward_popup := world_map.get_node_or_null("WorldMap/BossRewardPopup")
	if reward_popup == null:
		push_error("World map should open a standalone BossRewardPopup after mid-run boss victory.")
		tree.quit(1)
		return
	var title_label := reward_popup.get_node_or_null("Panel/TitleLabel") as Label
	var body_label := reward_popup.get_node_or_null("Panel/BodyLabel") as RichTextLabel
	if title_label == null or body_label == null:
		push_error("Boss reward popup should expose title and body labels.")
		tree.quit(1)
		return
	var reward_row := reward_popup.get_node_or_null("Panel/RewardRow")
	if reward_row == null:
		push_error("Boss reward popup should expose Panel/RewardRow for the dropped relic card.")
		tree.quit(1)
		return
	var icon_node := reward_row.get_node_or_null("InfoPanel/CrestSlot/IconTexture") as TextureRect
	var meta_label := reward_row.get_node_or_null("InfoPanel/InfoBox/MetaLabel") as Label
	var action_button := reward_row.get_node_or_null("ActionButton") as Button
	if icon_node == null or meta_label == null or action_button == null:
		push_error("Boss reward card should expose icon, meta label and action button nodes.")
		tree.quit(1)
		return
	if icon_node.texture == null:
		push_error("Boss reward card should load the dropped relic icon.")
		tree.quit(1)
		return
	for expected in ["辅助机", family_name, "遗物", "冲锋"]:
		if not meta_label.text.contains(expected):
			push_error("Boss reward card meta should include %s. Meta: %s" % [expected, meta_label.text])
			tree.quit(1)
			return
	if action_button.text != "已入库":
		push_error("Boss reward card should use a read-only in-storage state, got: %s" % action_button.text)
		tree.quit(1)
		return
	var popup_text := "%s\n%s" % [title_label.text, body_label.text]
	for expected in ["执行体肃清", "缴获纹章", drop_name, family_name]:
		if not popup_text.contains(expected):
			push_error("Boss reward popup should include %s. Popup: %s" % [expected, popup_text])
			tree.quit(1)
			return
	for hidden in [drop_id, "colossus", "BossBattle_Frontier.tscn", "res://"]:
		if popup_text.contains(hidden):
			push_error("Boss reward popup should hide internal ids and scene paths. Popup: %s" % popup_text)
			tree.quit(1)
			return
	world_map.queue_free()

	print("Boss drop check passed.")
	tree.quit(0)


func _check_boss_drop_catalog_scale(tree: SceneTree) -> bool:
	var catalog := EquipmentCatalogScript.new()
	if not catalog.has_method("get_boss_drop_for_family_stage"):
		push_error("EquipmentCatalog should expose get_boss_drop_for_family_stage().")
		tree.quit(1)
		return false
	for family in [
		EquipmentCatalogScript.FAMILY_COLOSSUS,
		EquipmentCatalogScript.FAMILY_PARADISE,
		EquipmentCatalogScript.FAMILY_WARPED,
		EquipmentCatalogScript.FAMILY_HELL_EYE,
		EquipmentCatalogScript.FAMILY_DIVINE,
	]:
		var family_drops: Array[String] = []
		for item_id in EquipmentCatalogScript.get_boss_drop_item_ids():
			if EquipmentCatalogScript.get_family(item_id) == family:
				family_drops.append(item_id)
		if family_drops.size() < 3:
			push_error("Boss family %s should have at least 3 staged relic drops, got %d." % [family, family_drops.size()])
			tree.quit(1)
			return false
		var stage_drops := {}
		for stage in [1, 2, 3]:
			var drop_id := String(catalog.call("get_boss_drop_for_family_stage", family, stage, []))
			if String(drop_id).is_empty():
				push_error("Boss family %s should expose a stage %d drop." % [family, stage])
				tree.quit(1)
				return false
			stage_drops[String(drop_id)] = true
		if stage_drops.size() < 3:
			push_error("Boss family %s should use distinct stage drops." % family)
			tree.quit(1)
			return false
	return true
