extends Node


func _ready() -> void:
	var original_meta: Dictionary = MetaProgressionState.to_dict()
	if not _check_overclock() or not _check_voucher() or not _check_compass() or not _check_scan_and_salvage() or not _check_chaos_seed() or not _check_frenzy_and_bulkhead():
		MetaProgressionState.load_dict(original_meta)
		RunManager.cancel_run()
		return
	MetaProgressionState.load_dict(original_meta)
	RunManager.cancel_run()
	print("Preflight run integration check passed.")
	get_tree().quit(0)


func _select(calibration_id: String, family_id: String = "") -> void:
	MetaProgressionState.unlock_calibration(calibration_id)
	MetaProgressionState.select_calibration(calibration_id)
	if not family_id.is_empty():
		MetaProgressionState.select_calibration_family(family_id)


func _check_overclock() -> bool:
	_select("overclock_lease")
	RunManager.start_new_run()
	if RunManager.compute_capacity != 7 or float(RunManager.calibration_shop_price_mult) != 1.08:
		return _fail("Overclock calibration was not injected into the new-run budget.")
	return true


func _check_voucher() -> bool:
	_select("procurement_voucher")
	RunManager.start_new_run()
	if RunManager.get_shop_reroll_cost() != 0:
		return _fail("Procurement voucher did not grant the first free reroll.")
	return true


func _check_compass() -> bool:
	_select("resonance_compass", "warped")
	RunManager.start_new_run()
	var resonance_offers := RunManager.get_shop_offer_ids()
	var warped_count := 0
	for item_id in resonance_offers:
		if EquipmentCatalog.get_family(item_id) == "warped":
			warped_count += 1
	if RunManager.calibration_resonance_family != "warped" or RunManager.calibration_resonance_offer_remaining != 0 or warped_count < 4:
		return _fail("Resonance compass did not apply exactly its first four family candidates.")
	return true


func _check_scan_and_salvage() -> bool:
	_select("wide_scan")
	RunManager.start_new_run()
	var found_revealed := false
	for node in RunManager.map_nodes:
		if bool(node.get("preflight_intel_revealed", false)):
			found_revealed = true
			break
	if not found_revealed:
		return _fail("Wide scan did not reveal the first two map layers.")
	_select("salvage_probe")
	RunManager.start_new_run()
	if float(RunManager.calibration_mineral_mult) != 1.08:
		return _fail("Salvage probe did not reach exploration reward scaling.")
	return true


func _check_chaos_seed() -> bool:
	_select("chaos_seed")
	RunManager.start_new_run()
	if RunManager.equipment_inventory.size() < 2:
		return _fail("Chaos seed did not grant a starting auxiliary item.")
	return true


func _check_frenzy_and_bulkhead() -> bool:
	_select("frenzy_preheat")
	RunManager.start_new_run()
	if GameManager.frenzy_value != 40.0 or float(GameManager.call("_get_frenzy_gain_cap")) != 14.0:
		return _fail("Frenzy preheat did not initialize heat and its per-second cap.")
	_select("emergency_bulkhead")
	RunManager.start_new_run()
	RunManager.minerals += 10
	if RunManager.minerals != 0 or RunManager.calibration_mineral_debt != 15:
		return _fail("Emergency bulkhead mineral debt did not consume incoming income first.")
	RunManager.minerals += 20
	if RunManager.minerals != 5 or RunManager.calibration_mineral_debt != 0:
		return _fail("Emergency bulkhead mineral debt did not settle exactly once.")
	GameManager.player_hp = 15
	if GameManager.player_hp != 35 or not GameManager.is_preflight_invulnerable():
		return _fail("Emergency bulkhead did not trigger its one-time recovery and invulnerability.")
	GameManager.player_hp = 10
	if GameManager.player_hp != 35:
		return _fail("Emergency bulkhead invulnerability did not block follow-up damage.")
	GameManager.call("_process", 1.1)
	GameManager.player_hp = 10
	if GameManager.player_hp != 10:
		return _fail("Emergency bulkhead invulnerability did not expire.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
