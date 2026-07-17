extends Node

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const DesignedEnemyCatalogScript := preload("res://scripts/entities/designed_enemies/DesignedEnemyCatalog.gd")
const EventServiceScript := preload("res://scripts/core/run_content/EventService.gd")
const RewardServiceScript := preload("res://scripts/core/run_content/RewardService.gd")
const BeaconServiceScript := preload("res://scripts/core/run_content/BeaconService.gd")
const AdvancedCrisisResolverScript := preload("res://scripts/core/AdvancedCrisisResolver.gd")
const BalanceServiceScript := preload("res://scripts/core/BalanceService.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_generated_source()
	_check_combat_and_pacing()
	_check_equipment_import()
	_check_run_content_import()
	_check_meta_import()
	if not _failed:
		print("Master balance import check passed.")
		get_tree().quit(0)


func _check_generated_source() -> void:
	_assert(BalanceServiceScript.is_generated_data_current(), "Generated balance Resources drifted from master_balance.tsv.")
	_assert(BalanceServiceScript.get_schema_version() == "1.0", "Unexpected balance schema version.")
	_assert(BalanceServiceScript.get_content_version() == "2026.07.16.1", "Unexpected balance content version.")
	_assert(BalanceServiceScript.get_total_record_count() == 373, "The master table must import all 373 records.")


func _check_combat_and_pacing() -> void:
	_assert(BalanceServiceScript.get_value("enemy", "enemy_base_hp") == 240, "Enemy base HP must come from the master table.")
	_assert(BalanceServiceScript.get_stage_value("elite", "elite_ehp", 3) == 20400, "Stage 3 elite EHP must be 20400.")
	_assert(BalanceServiceScript.get_stage_value("boss", "boss_base_ehp", 2) == 14500, "Stage 2 boss EHP must be 14500.")
	_assert(BalanceServiceScript.get_stage_value("economy", "equipped_aux_before_boss", 1) == 3, "Boss 1 equipment target must be 3.")
	_assert(BalanceServiceScript.get_stage_value("economy", "equipped_aux_before_boss", 2) == 5, "Boss 2 equipment target must be 5.")
	_assert(BalanceServiceScript.get_stage_value("economy", "equipped_aux_before_boss", 3) == 8, "Boss 3 equipment target must be 8.")
	var paradise_budget := DesignedEnemyCatalogScript.get_boss_budget("paradise", 1)
	_assert(int(paradise_budget.get("ehp", 0)) == 5320, "Paradise Boss family multiplier must use the master table.")


func _check_equipment_import() -> void:
	_assert(EquipmentCatalogScript.get_all_item_ids().size() == 142, "All 20 weapons and 122 auxiliaries must be imported.")
	var twin_lance := EquipmentCatalogScript.get_item("twin_lance")
	_assert(int(twin_lance.get("price", 0)) == 60, "Weapon price must override the legacy catalog.")
	_assert(is_equal_approx(float(twin_lance.get("projectile_damage_mult", 0.0)), 0.573), "Weapon normalized projectile multiplier is missing.")
	var ore_beacon := EquipmentCatalogScript.get_item("general_ore_beacon_array")
	_assert(is_equal_approx(float(ore_beacon.get("mineral_bonus", 0.0)), 0.14), "Auxiliary stats must override legacy values.")


func _check_run_content_import() -> void:
	var event_service := EventServiceScript.new()
	_assert(event_service.get_definitions().size() == 24, "All 24 event definitions must be available.")
	var supply_event = event_service.get_definition("old_supply_chain")
	_assert(supply_event != null and is_equal_approx(supply_event.weight, 1.2), "Event weight must come from the master table.")
	_assert(supply_event != null and supply_event.title == "旧时代补给链", "Event title must come from the master table.")
	if supply_event != null:
		var supply_amounts: PackedInt32Array = supply_event.options[0].effects[0].get("amount_by_stage", PackedInt32Array())
		_assert(supply_amounts == PackedInt32Array([32, 48, 70]), "Event stage rewards must come from the master table.")
	var reward_service := RewardServiceScript.new()
	_assert(reward_service.get_pools().size() == 8, "All 8 reward pools must be available.")
	var reward_ids: PackedStringArray = PackedStringArray()
	for pool in reward_service.get_pools():
		reward_ids.append(pool.pool_id)
	_assert(reward_ids.has("high_risk_ore"), "The authoritative high_risk_ore reward pool ID was not imported.")
	var beacon_service := BeaconServiceScript.new()
	_assert(beacon_service.get_beacons().size() == 26, "All 26 beacon definitions must be available.")
	var mirror_ram = beacon_service.get_beacon("colossus_mirror_ram")
	_assert(mirror_ram != null and mirror_ram.rule_key == "dash_refund", "Beacon rule key must come from the master table.")
	_assert(mirror_ram != null and int(mirror_ram.rule_parameters.get("normal_hits", 0)) == 3, "Beacon numeric parameters were not imported.")


func _check_meta_import() -> void:
	var calibration: Dictionary = BalanceServiceScript.get_calibration_effects("emergency_bulkhead")
	_assert(int(calibration.get("emergency_heal_threshold", 0)) == 20, "Calibration threshold was not imported.")
	_assert(int(calibration.get("starting_mineral_debt", 0)) == 25, "Calibration drawback was not imported.")
	var crisis := AdvancedCrisisResolverScript.new().resolve(5)
	_assert(is_equal_approx(float(Dictionary(crisis.get("boss", {})).get("ehp_mult", 0.0)), 1.1), "Advanced crisis Boss EHP multiplier was not imported.")
	_assert(is_equal_approx(float(Dictionary(crisis.get("boss", {})).get("phase_enrage_threshold", 0.0)), 0.6), "Advanced crisis phase threshold was not imported.")


func _assert(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
