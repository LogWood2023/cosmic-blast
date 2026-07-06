extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const OFFER_COUNT := 12
const MIN_CHANGED_PER_REROLL := 4
const MIN_FOCUSED_OFFERS := 6

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	RunManager.crisis_level = 12
	RunManager.minerals = 999999
	_check_focused_rerolls_stay_fresh_and_broad()
	if _failed:
		return
	print("Shop reroll freshness check passed.")
	get_tree().quit(0)


func _check_focused_rerolls_stay_fresh_and_broad() -> void:
	var family := EquipmentCatalogScript.FAMILY_COLOSSUS
	var previous: Array = []
	for index in range(8):
		var result: Dictionary = RunManager.reroll_shop_offers(family)
		if not bool(result.get("ok", false)):
			_fail("Focused reroll %d should succeed: %s" % [index, str(result)])
			return
		var offers: Array = RunManager.get_shop_offer_ids()
		if offers.size() != OFFER_COUNT:
			_fail("Focused reroll %d should keep %d offers, got %d: %s" % [index, OFFER_COUNT, offers.size(), str(offers)])
			return
		_check_offer_pool_rules(index, offers, family)
		if _failed:
			return
		if not previous.is_empty():
			var changed := _count_changed(previous, offers)
			if changed < MIN_CHANGED_PER_REROLL:
				_fail("Focused reroll %d should replace at least %d offers, changed=%d previous=%s current=%s" % [
					index,
					MIN_CHANGED_PER_REROLL,
					changed,
					str(previous),
					str(offers),
				])
				return
		previous = offers.duplicate()


func _check_offer_pool_rules(index: int, offers: Array, family: String) -> void:
	var family_count := 0
	var general_count := 0
	var off_family_count := 0
	var seen := {}
	for item_id_value in offers:
		var item_id := String(item_id_value)
		if seen.has(item_id):
			_fail("Focused reroll %d should not repeat an item inside one draft: %s" % [index, item_id])
			return
		seen[item_id] = true
		if RunManager.equipment_inventory.has(item_id):
			_fail("Focused reroll %d should exclude owned equipment: %s" % [index, item_id])
			return
		if EquipmentCatalogScript.is_boss_drop(item_id):
			_fail("Focused reroll %d should exclude boss drops: %s" % [index, item_id])
			return
		var item_family := EquipmentCatalogScript.get_family(item_id)
		if item_family == family:
			family_count += 1
		elif item_family == EquipmentCatalogScript.FAMILY_GENERAL:
			general_count += 1
		else:
			off_family_count += 1
	if family_count < MIN_FOCUSED_OFFERS:
		_fail("Focused reroll %d should surface at least %d target-family offers, got %d: %s" % [
			index,
			MIN_FOCUSED_OFFERS,
			family_count,
			str(offers),
		])
		return
	if general_count <= 0:
		_fail("Focused reroll %d should keep at least one general flexible item: %s" % [index, str(offers)])
		return
	if off_family_count <= 0:
		_fail("Focused reroll %d should keep at least one off-family build pivot: %s" % [index, str(offers)])
		return


func _count_changed(previous: Array, current: Array) -> int:
	var overlap := 0
	for item_id in current:
		if previous.has(item_id):
			overlap += 1
	return current.size() - overlap


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
