extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

const MIN_MINERAL_OFFERS: int = 3

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_catalog_exposes_mineral_offer_pool()
	if _failed:
		return
	_check_ore_source_focus_reinforces_shop_offers()
	if _failed:
		return
	print("Shop ore source focus check passed.")
	get_tree().quit(0)


func _check_catalog_exposes_mineral_offer_pool() -> void:
	var offers: Array = EquipmentCatalogScript.get_mineral_shop_offer_item_ids(
		[],
		12,
		EquipmentCatalogScript.FAMILY_COLOSSUS,
		8,
		7101
	)
	if offers.size() < 5:
		_fail("Mineral shop offer pool should provide enough choices, got: %s" % str(offers))
		return
	for item_id in offers:
		if _mineral_bonus(String(item_id)) <= 0.0:
			_fail("Mineral offer pool should only return recovery equipment, got %s." % String(item_id))
			return
		if EquipmentCatalogScript.is_boss_drop(String(item_id)):
			_fail("Mineral offer pool should exclude boss drops: %s." % String(item_id))
			return


func _check_ore_source_focus_reinforces_shop_offers() -> void:
	RunManager.start_new_run()
	RunManager.crisis_level = 12
	RunManager.minerals = 99999
	RunManager.shop_ore_source_focus = "gleam_crystal"
	RunManager.shop_ore_source_focus_text = "辉晶采购校准"
	var result: Dictionary = RunManager.reroll_shop_offers(EquipmentCatalogScript.FAMILY_PARADISE)
	if not bool(result.get("ok", false)):
		_fail("Ore-source focused reroll should succeed: %s" % str(result))
		return
	var offers: Array = RunManager.get_shop_offer_ids()
	if offers.size() != RunManager.SHOP_OFFER_COUNT:
		_fail("Ore-source focused shop should keep a full offer list: %s" % str(offers))
		return
	var mineral_count := _count_mineral_offers(offers)
	if mineral_count < MIN_MINERAL_OFFERS:
		_fail("Ore-source focus should keep at least %d recovery offers, got %d: %s" % [
			MIN_MINERAL_OFFERS,
			mineral_count,
			str(offers),
		])
		return
	if _count_family(offers, EquipmentCatalogScript.FAMILY_PARADISE) < RunManager.SHOP_FOCUS_MIN_OFFERS:
		_fail("Ore-source focus should preserve family shop focus, got: %s" % str(offers))
		return
	var guidance: Dictionary = RunManager.get_shop_guidance()
	var copy := "%s\n%s\n%s" % [
		String(guidance.get("summary", "")),
		String(guidance.get("copy_text", "")),
		String(guidance.get("ore_source_focus_text", "")),
	]
	for expected in ["辉晶采购校准", "矿源", "货单"]:
		if not copy.contains(expected):
			_fail("Shop guidance should explain ore-source focus with %s, got: %s" % [expected, copy])
			return
	if _contains_internal_id(copy):
		_fail("Ore-source shop guidance should hide internal ids: %s" % copy)
		return


func _count_mineral_offers(offer_ids: Array) -> int:
	var count := 0
	for item_id in offer_ids:
		if _mineral_bonus(String(item_id)) > 0.0:
			count += 1
	return count


func _count_family(offer_ids: Array, family: String) -> int:
	var count := 0
	for item_id in offer_ids:
		if EquipmentCatalogScript.get_family(String(item_id)) == family:
			count += 1
	return count


func _mineral_bonus(item_id: String) -> float:
	return float(EquipmentCatalogScript.get_item(item_id).get("mineral_bonus", 0.0))


func _contains_internal_id(text: String) -> bool:
	for token in ["gleam_crystal", "shop_ore_source", "shop_focus", "_"]:
		if text.contains(token):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
