extends Node
## Read-only gateway for balance assets. Runtime systems receive values, never mutate Resources.

const RUN_PACING_PATH: String = "res://data/balance/run_pacing.tres"
const COMBAT_PATH: String = "res://data/balance/combat_balance.tres"
const ECONOMY_PATH: String = "res://data/balance/economy_balance.tres"
const RunPacingConfigScript := preload("res://scripts/data/balance/RunPacingConfig.gd")
const CombatBalanceConfigScript := preload("res://scripts/data/balance/CombatBalanceConfig.gd")
const EconomyBalanceConfigScript := preload("res://scripts/data/balance/EconomyBalanceConfig.gd")

var _run_pacing: Resource
var _combat: Resource
var _economy: Resource


func _ready() -> void:
	_run_pacing = _load_or_default(RUN_PACING_PATH, RunPacingConfigScript)
	_combat = _load_or_default(COMBAT_PATH, CombatBalanceConfigScript)
	_economy = _load_or_default(ECONOMY_PATH, EconomyBalanceConfigScript)


func get_stage_for_crisis(crisis: int) -> int:
	return _run_pacing.get_stage_for_crisis(crisis)


func get_damage(category: StringName) -> int:
	return _combat.get_damage(category)


func get_elite_ehp(stage: int) -> int:
	return _combat.get_stage_value(_combat.elite_ehp, stage)


func get_boss_ehp(stage: int) -> int:
	return _combat.get_stage_value(_combat.boss_ehp, stage)


func get_economy_snapshot() -> Dictionary:
	return {
		"reward_minerals_range": _economy.reward_minerals_range,
		"reward_repair_range": _economy.reward_repair_range,
		"shop_reroll_base_cost": _economy.shop_reroll_base_cost,
		"shop_reroll_cost_step": _economy.shop_reroll_cost_step,
	}


func get_run_pacing_snapshot() -> Dictionary:
	return {
		"crisis_thresholds": _run_pacing.crisis_thresholds.duplicate(),
		"starting_compute_capacity": _run_pacing.starting_compute_capacity,
		"equipment_targets_per_boss": _run_pacing.equipment_targets_per_boss.duplicate(),
	}


func _load_or_default(path: String, script: Script) -> Resource:
	var loaded := load(path) as Resource
	if loaded != null and loaded.get_script() == script:
		return loaded
	push_error("BalanceService: failed to load %s; using safe defaults." % path)
	return script.new() as Resource
