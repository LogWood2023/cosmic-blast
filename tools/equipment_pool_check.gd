extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_shop_offer_limits()
	_check_crisis_rarity_gates()
	_check_default_shop_variety()
	_check_family_bias()
	_check_run_manager_map_bias()
	print("Equipment pool check passed.")
	get_tree().quit(0)


func _check_shop_offer_limits() -> void:
	var all_shop_ids := EquipmentCatalogScript.get_shop_item_ids()
	var offers := EquipmentCatalogScript.get_shop_offer_item_ids(["pulse_cannon"], 0, "", 12, 101)
	if offers.size() != 12:
		_fail("Shop should expose exactly 12 offers, got %d." % offers.size())
		return
	if offers.size() >= all_shop_ids.size():
		_fail("Shop offers should be a limited draft, not the whole pool.")
		return
	for id in offers:
		if id == "pulse_cannon":
			_fail("Shop offers should exclude owned equipment.")
			return
		if EquipmentCatalogScript.is_boss_drop(id):
			_fail("Shop offers should not include boss-drop equipment: %s." % id)
			return


func _check_crisis_rarity_gates() -> void:
	var early := EquipmentCatalogScript.get_shop_offer_item_ids([], 0, "", 30, 202)
	for id in early:
		if EquipmentCatalogScript.get_rarity(id) == "epic":
			_fail("Early shop offers should not contain epic items: %s." % id)
			return

	var late := EquipmentCatalogScript.get_shop_offer_item_ids([], 21, "", 40, 303)
	var found_epic := false
	for id in late:
		if EquipmentCatalogScript.get_rarity(id) == "epic":
			found_epic = true
			break
	if not found_epic:
		_fail("Late shop offers should be able to contain epic items.")
		return


func _check_default_shop_variety() -> void:
	var seen_families := {}
	var seen_rarities := {}
	for seed in range(30):
		var offers := EquipmentCatalogScript.get_shop_offer_item_ids(["pulse_cannon"], 12, "", 12, 4100 + seed)
		for id in offers:
			seen_families[EquipmentCatalogScript.get_family(id)] = true
			seen_rarities[EquipmentCatalogScript.get_rarity(id)] = true
	for family in [
		EquipmentCatalogScript.FAMILY_COLOSSUS,
		EquipmentCatalogScript.FAMILY_PARADISE,
		EquipmentCatalogScript.FAMILY_WARPED,
		EquipmentCatalogScript.FAMILY_HELL_EYE,
		EquipmentCatalogScript.FAMILY_DIVINE,
		EquipmentCatalogScript.FAMILY_GENERAL,
	]:
		if not seen_families.has(family):
			_fail("Default shop refreshes should surface family %s across repeated drafts." % family)
			return
	if not seen_rarities.has("common") or not seen_rarities.has("rare") or not seen_rarities.has("epic"):
		_fail("Mid-run shop refreshes should show common/rare/epic tiers across repeated drafts, got %s." % str(seen_rarities.keys()))
		return
	for seed in range(20):
		var offers := EquipmentCatalogScript.get_shop_offer_item_ids(["pulse_cannon"], 12, "", 12, 5200 + seed)
		var draft_families := {}
		for id in offers:
			draft_families[EquipmentCatalogScript.get_family(id)] = true
		if draft_families.size() < 4:
			_fail("Each mid-run shop draft should expose at least 4 build families, seed=%d families=%s offers=%s." % [seed, str(draft_families.keys()), str(offers)])
			return
		if not draft_families.has(EquipmentCatalogScript.FAMILY_GENERAL):
			_fail("Each mid-run shop draft should include at least one general flexible item, seed=%d offers=%s." % [seed, str(offers)])
			return


func _check_family_bias() -> void:
	var neutral_colossus := _count_offer_family(EquipmentCatalogScript.FAMILY_COLOSSUS, "")
	var biased_colossus := _count_offer_family(EquipmentCatalogScript.FAMILY_COLOSSUS, EquipmentCatalogScript.FAMILY_COLOSSUS)
	if biased_colossus <= neutral_colossus:
		_fail("Colossus shop bias should increase colossus offers, neutral=%d biased=%d." % [neutral_colossus, biased_colossus])
		return

	var neutral_paradise := _count_loot_family(EquipmentCatalogScript.FAMILY_PARADISE, "")
	var biased_paradise := _count_loot_family(EquipmentCatalogScript.FAMILY_PARADISE, EquipmentCatalogScript.FAMILY_PARADISE)
	if biased_paradise <= neutral_paradise:
		_fail("Paradise loot bias should increase paradise drops, neutral=%d biased=%d." % [neutral_paradise, biased_paradise])
		return


func _check_run_manager_map_bias() -> void:
	RunManager.start_new_run()
	var accessible_id := -1
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id > 0 and RunManager.is_node_accessible(node_id):
			accessible_id = node_id
			break
	if accessible_id < 0:
		_fail("Run map should have an accessible node for bias check.")
		return
	var node := RunManager.get_map_node(accessible_id)
	var family_bias := String(node.get("family_bias", ""))
	if family_bias.is_empty():
		_fail("Exploration nodes should carry a family bias.")
		return
	if not RunManager.start_explore_node(accessible_id):
		_fail("Accessible node should start exploration.")
		return
	var config := GameManager.next_explore_room_config.duplicate(true)
	var key := "%s_family_weight" % family_bias
	if not config.has(key) or float(config.get(key, 1.0)) <= 1.0:
		_fail("Explore room config should boost family weight %s, got %s." % [key, config])
		return
	RunManager.abandon_current_room()


func _count_offer_family(family: String, preferred_family: String) -> int:
	var count := 0
	for seed in range(40):
		var offers := EquipmentCatalogScript.get_shop_offer_item_ids([], 12, preferred_family, 12, 1000 + seed)
		for id in offers:
			if EquipmentCatalogScript.get_family(id) == family:
				count += 1
	return count


func _count_loot_family(family: String, preferred_family: String) -> int:
	var count := 0
	for seed in range(80):
		var id := EquipmentCatalogScript.get_random_loot_item_id([], 12, preferred_family, 2000 + seed)
		if EquipmentCatalogScript.get_family(id) == family:
			count += 1
	return count


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
