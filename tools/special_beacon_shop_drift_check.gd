extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var special_id := _first_boss_family_special_node_id()
	if special_id <= 0:
		_fail("World map should generate at least one boss-family special beacon.")
		return
	var special_node := RunManager.get_map_node(special_id)
	var anchor_id := _first_accessible_link(special_node)
	if anchor_id <= 0:
		_fail("Boss-family beacon should connect to an accessible anchor.")
		return

	if not RunManager.start_explore_node(anchor_id):
		_fail("Could not start the beacon anchor node.")
		return
	var result := RunManager.complete_explore_room_success()
	if not bool(result.get("ok", false)):
		_fail("Completing the beacon anchor should succeed.")
		return
	if not RunManager.is_special_bonus_active(special_id):
		_fail("Completing the anchor should activate the linked beacon.")
		return
	var beacon_family := _latest_active_boss_family()
	if beacon_family.is_empty():
		_fail("At least one boss-family beacon should be active after the anchor is completed.")
		return

	var guidance: Dictionary = RunManager.get_shop_guidance()
	if String(guidance.get("family", "")) != beacon_family:
		_fail("Shop guidance should drift toward the active beacon family, got: %s" % str(guidance))
		return
	var guidance_copy := "%s\n%s\n%s" % [
		String(guidance.get("title", "")),
		String(guidance.get("summary", "")),
		String(guidance.get("copy_text", "")),
	]
	var family_name := EquipmentCatalogScript.get_family_display_name(beacon_family)
	for expected in ["采购校准", family_name, "信标"]:
		if not guidance_copy.contains(expected):
			_fail("Beacon shop guidance should mention %s, got: %s" % [expected, guidance_copy])
			return
	if _contains_ascii_identifier(guidance_copy):
		_fail("Beacon shop guidance should not expose internal ids: %s" % guidance_copy)
		return

	var offers := RunManager.get_shop_offer_ids()
	var focused_count := _count_family(offers, beacon_family)
	if focused_count < RunManager.SHOP_FOCUS_MIN_OFFERS:
		_fail("Default shop offers should follow beacon family %s, got %d/%d: %s" % [
			beacon_family,
			focused_count,
			RunManager.SHOP_FOCUS_MIN_OFFERS,
			str(offers),
		])
		return

	print("Special beacon shop drift check passed.")
	get_tree().quit(0)


func _first_boss_family_special_node_id() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var family := String(node.get("family_bias", ""))
		if node_id > 0 and String(node.get("type", "")) == RunManager.NODE_SPECIAL and EquipmentCatalogScript.get_boss_family_ids().has(family):
			return node_id
	return -1


func _latest_active_boss_family() -> String:
	for i in range(RunManager.active_special_bonus_ids.size() - 1, -1, -1):
		var bonus_id := String(RunManager.active_special_bonus_ids[i])
		var family := _bonus_family(bonus_id)
		if EquipmentCatalogScript.get_boss_family_ids().has(family):
			return family
	return ""


func _bonus_family(bonus_id: String) -> String:
	for profile in RunManager.SPECIAL_BONUS_PROFILES:
		if String(profile.get("bonus_id", "")) == bonus_id:
			return String(profile.get("family_bias", ""))
	return ""


func _first_accessible_link(node: Dictionary) -> int:
	for linked_id in node.get("links", []):
		var id := int(linked_id)
		if id > 0 and RunManager.is_node_accessible(id):
			return id
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
