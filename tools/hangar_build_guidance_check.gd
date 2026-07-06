extends Node


const HANGAR_POPUP_SCENE := preload("res://scenes/ui/world_map/HangarPopup.tscn")
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_seed_colossus_route()
	_check_guidance_api()
	if _failed:
		return
	await _check_hangar_guidance_ui()
	if _failed:
		return
	print("Hangar build guidance check passed.")
	get_tree().quit(0)


func _seed_colossus_route() -> void:
	RunManager.compute_capacity = 7
	RunManager.equipment_inventory = [
		"pulse_cannon",
		"colossus_impact_coil",
		"colossus_ramming_keel",
		"paradise_splitter_board",
		"general_stability_chip",
	]
	RunManager.equipped_weapon = "pulse_cannon"
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


func _check_guidance_api() -> void:
	if not RunManager.has_method("get_build_guidance"):
		_fail("RunManager should expose get_build_guidance() for hangar route planning.")
		return
	var guidance: Dictionary = RunManager.call("get_build_guidance", EquipmentCatalogScript.FAMILY_COLOSSUS)
	for key in ["family", "family_name", "title", "summary", "sync_goal_text", "next_node_name", "route_plan_title", "copy_text"]:
		if not guidance.has(key) or String(guidance.get(key, "")).strip_edges().is_empty():
			_fail("Build guidance should include %s: %s" % [key, str(guidance)])
			return
	if String(guidance.get("family", "")) != EquipmentCatalogScript.FAMILY_COLOSSUS:
		_fail("Colossus guidance should keep the requested family, got: %s" % str(guidance))
		return
	var combined := "%s\n%s\n%s\n%s\n%s" % [
		String(guidance.get("title", "")),
		String(guidance.get("summary", "")),
		String(guidance.get("sync_goal_text", "")),
		String(guidance.get("next_node_name", "")),
		String(guidance.get("copy_text", "")),
	]
	for expected in ["航向校准", "星间巨构", "同调", "撞角残区"]:
		if not combined.contains(expected):
			_fail("Build guidance copy should include %s, got: %s" % [expected, combined])
			return
	if _contains_ascii_identifier(combined):
		_fail("Build guidance should use Chinese-facing copy, got: %s" % combined)
		return


func _check_hangar_guidance_ui() -> void:
	var popup := HANGAR_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.set("_active_family_filter", EquipmentCatalogScript.FAMILY_COLOSSUS)
	popup.call("setup")
	await get_tree().process_frame
	var bar := popup.get_node_or_null("Panel/BuildGuidanceBar") as VBoxContainer
	if bar == null:
		_fail("Hangar popup should expose Panel/BuildGuidanceBar for build guidance.")
		popup.queue_free()
		return
	var title_label := bar.get_node_or_null("BuildGuidanceTitle") as Label
	var detail_label := bar.get_node_or_null("BuildGuidanceDetail") as Label
	var node_label := bar.get_node_or_null("BuildGuidanceNode") as Label
	if title_label == null or detail_label == null or node_label == null:
		_fail("Build guidance bar should include title/detail/node labels.")
		popup.queue_free()
		return
	var combined := "%s\n%s\n%s" % [title_label.text, detail_label.text, node_label.text]
	for expected in ["航向校准", "星间巨构", "同调", "撞角残区"]:
		if not combined.contains(expected):
			_fail("Hangar build guidance should include %s, got: %s" % [expected, combined])
			popup.queue_free()
			return
	if _contains_ascii_identifier(combined):
		_fail("Hangar build guidance should be polished Chinese copy: %s" % combined)
		popup.queue_free()
		return
	popup.queue_free()


func _pick_accessible_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id > 0 and String(node.get("type", "")) != RunManager.NODE_SPECIAL and RunManager.is_node_accessible(node_id):
			return node_id
	return -1


func _contains_ascii_identifier(text: String) -> bool:
	for token in ["colossus", "paradise", "warped", "hell_eye", "divine", "family_bias", "route_plan", "_"]:
		if text.contains(token):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
