extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_shop_management_api()
	if _failed:
		return
	_check_shop_draft_stability()
	if _failed:
		return
	_check_buying_removes_offer()
	if _failed:
		return
	_check_paid_reroll_rules()
	if _failed:
		return
	_check_family_focus_bias()
	if _failed:
		return
	print("Shop management check passed.")
	get_tree().quit(0)


func _check_shop_management_api() -> void:
	for method in ["get_shop_offer_ids", "get_shop_reroll_cost", "reroll_shop_offers"]:
		if not RunManager.has_method(method):
			_fail("RunManager should expose %s()." % method)
			return


func _check_shop_draft_stability() -> void:
	var first: Array = RunManager.get_shop_offer_ids()
	var second: Array = RunManager.get_shop_offer_ids()
	if first.size() != 12:
		_fail("Shop draft should contain 12 offers, got %d." % first.size())
		return
	if first != second:
		_fail("Shop draft should stay stable while reopening the shop.")
		return
	for item_id in first:
		if RunManager.equipment_inventory.has(item_id):
			_fail("Shop draft should exclude owned equipment: %s." % item_id)
			return
		if EquipmentCatalogScript.is_boss_drop(String(item_id)):
			_fail("Shop draft should exclude boss drops: %s." % item_id)
			return


func _check_buying_removes_offer() -> void:
	var before: Array = RunManager.get_shop_offer_ids()
	var item_id := String(before[0])
	RunManager.minerals = EquipmentCatalogScript.get_price(item_id)
	var result: Dictionary = RunManager.buy_equipment(item_id)
	if not bool(result.get("ok", false)):
		_fail("Buying a shop offer should succeed: %s" % str(result))
		return
	var after: Array = RunManager.get_shop_offer_ids()
	if after.has(item_id):
		_fail("Bought item should disappear from the active shop draft.")
		return
	if after.size() != before.size() - 1:
		_fail("Buying should consume one active offer, before=%d after=%d." % [before.size(), after.size()])
		return


func _check_paid_reroll_rules() -> void:
	RunManager.start_new_run()
	var original: Array = RunManager.get_shop_offer_ids()
	var cost := int(RunManager.get_shop_reroll_cost())
	if cost <= 0:
		_fail("Shop reroll cost should be positive.")
		return
	RunManager.minerals = cost - 1
	var denied: Dictionary = RunManager.reroll_shop_offers()
	if bool(denied.get("ok", false)):
		_fail("Reroll should fail when minerals are insufficient.")
		return
	if RunManager.get_shop_offer_ids() != original:
		_fail("Failed reroll should not change the active shop draft.")
		return
	RunManager.minerals = cost
	var rerolled: Dictionary = RunManager.reroll_shop_offers()
	if not bool(rerolled.get("ok", false)):
		_fail("Paid reroll should succeed with exact minerals: %s" % str(rerolled))
		return
	if RunManager.minerals != 0:
		_fail("Paid reroll should deduct its mineral cost.")
		return
	if int(RunManager.get_shop_reroll_cost()) <= cost:
		_fail("Shop reroll cost should increase after a successful reroll.")
		return
	if RunManager.get_shop_offer_ids() == original:
		_fail("Successful reroll should replace the active shop draft.")
		return


func _check_family_focus_bias() -> void:
	var family := EquipmentCatalogScript.FAMILY_COLOSSUS
	var comparison_family := EquipmentCatalogScript.FAMILY_PARADISE
	var comparison_count := 0
	var focused_count := 0
	for i in range(18):
		RunManager.start_new_run()
		RunManager.minerals = 99999
		var comparison: Dictionary = RunManager.reroll_shop_offers(comparison_family)
		if not bool(comparison.get("ok", false)):
			_fail("Comparison shop reroll should succeed during focus check.")
			return
		comparison_count += _count_family(RunManager.get_shop_offer_ids(), family)
		var focused: Dictionary = RunManager.reroll_shop_offers(family)
		if not bool(focused.get("ok", false)):
			_fail("Focused shop reroll should succeed during focus check.")
			return
		if String(focused.get("preferred_family", "")) != family:
			_fail("Focused shop reroll should report the requested family.")
			return
		var focused_offers := RunManager.get_shop_offer_ids()
		var focused_matches := _count_family(focused_offers, family)
		if focused_matches < RunManager.SHOP_FOCUS_MIN_OFFERS:
			_fail("Focused shop reroll should keep at least %d matching offers, got %d: %s." % [
				RunManager.SHOP_FOCUS_MIN_OFFERS,
				focused_matches,
				str(focused_offers),
			])
			return
		focused_count += focused_matches
	if focused_count <= comparison_count:
		_fail("Family focus should increase matching offers over another explicit focus, comparison=%d focused=%d." % [comparison_count, focused_count])
		return


func _count_family(offer_ids: Array, family: String) -> int:
	var count := 0
	for item_id in offer_ids:
		if EquipmentCatalogScript.get_family(String(item_id)) == family:
			count += 1
	return count


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
