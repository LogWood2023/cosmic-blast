class_name MechanicRuntime
extends Node

signal effect_triggered(effect_id: String, payload: Dictionary)
signal lineage_debugged(trigger: String, payload: Dictionary)

const MAX_GENERATION: int = 3
const MAX_EVENTS_PER_SECOND: int = 30
const GENERATION_PROC_COEFFICIENTS: PackedFloat32Array = [1.0, 0.65, 0.35, 0.15]
const SUPPORTED_TRIGGERS: PackedStringArray = ["on_shoot", "on_hit", "on_kill", "on_dash", "on_dash_hit", "on_heavy_hit", "on_frenzy_start", "on_drone_action", "on_mineral_collected"]
const SUPPORTED_ACTIONS: PackedStringArray = ["spawn_projectile", "apply_mark", "area_damage", "modify_cooldown", "add_heat", "drone_action", "modify_resource"]
const SUPPORTED_RULE_KEYS: PackedStringArray = ["projectile_split_once", "frenzy_overheat_bank", "dash_charge_refund", "drone_hit_proc"]

@export var debug_lineage: bool = false

var _effects: Array[MechanicEffectData] = []
var _cooldowns: Dictionary = {}
var _statistics: Dictionary = {}
var _active_rule_keys: Dictionary = {}
var _window_started_msec: int = 0
var _window_event_count: int = 0
var _effect_window_counts: Dictionary = {}

func set_effects(effects: Array[MechanicEffectData]) -> void:
	_effects = effects.duplicate()
	_cooldowns.clear()
	_statistics.clear()
	_effect_window_counts.clear()


func set_active_rule_keys(rule_keys: PackedStringArray) -> void:
	_active_rule_keys.clear()
	for rule_key in rule_keys:
		_active_rule_keys[rule_key] = true


func get_supported_hooks() -> Dictionary:
	return {"triggers": SUPPORTED_TRIGGERS.duplicate(), "actions": SUPPORTED_ACTIONS.duplicate(), "rule_keys": SUPPORTED_RULE_KEYS.duplicate()}

func dispatch(trigger: String, payload: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var generation := int(payload.get("generation", 0))
	if generation >= MAX_GENERATION or not SUPPORTED_TRIGGERS.has(trigger):
		return results
	_refresh_rate_window()
	if _window_event_count >= MAX_EVENTS_PER_SECOND:
		return results
	var lineage: Array = payload.get("lineage_effect_ids", [])
	for effect in _effects:
		if effect.trigger != trigger or lineage.has(effect.effect_id) or not SUPPORTED_ACTIONS.has(effect.action) or not _rules_are_active(effect):
			continue
		if float(_cooldowns.get(effect.effect_id, 0.0)) > 0.0:
			continue
		if effect.max_triggers_per_second > 0 and int(_effect_window_counts.get(effect.effect_id, 0)) >= effect.max_triggers_per_second:
			continue
		var event := payload.duplicate(true)
		event["generation"] = generation + 1
		var next_lineage := lineage.duplicate()
		next_lineage.append(effect.effect_id)
		event["lineage_effect_ids"] = next_lineage
		event["proc_coefficient"] = float(payload.get("proc_coefficient", 1.0)) * effect.proc_coefficient * GENERATION_PROC_COEFFICIENTS[generation + 1]
		event["action"] = effect.action
		event["effect_id"] = effect.effect_id
		event["inherit_mask"] = effect.inherit_mask.duplicate()
		event["parameters"] = effect.parameters.duplicate(true)
		results.append(event)
		_cooldowns[effect.effect_id] = effect.cooldown_seconds
		_statistics[effect.effect_id] = int(_statistics.get(effect.effect_id, 0)) + 1
		_effect_window_counts[effect.effect_id] = int(_effect_window_counts.get(effect.effect_id, 0)) + 1
		_window_event_count += 1
		effect_triggered.emit(effect.effect_id, event)
		if debug_lineage:
			lineage_debugged.emit(trigger, event)
	return results

func _process(delta: float) -> void:
	for effect_id in _cooldowns.keys():
		_cooldowns[effect_id] = maxf(0.0, float(_cooldowns[effect_id]) - delta)

func get_statistics() -> Dictionary:
	return _statistics.duplicate(true)


func _rules_are_active(effect: MechanicEffectData) -> bool:
	for rule_key in effect.required_rule_keys:
		if not _active_rule_keys.has(rule_key):
			return false
	return true


func _refresh_rate_window() -> void:
	var now := Time.get_ticks_msec()
	if _window_started_msec == 0 or now - _window_started_msec >= 1000:
		_window_started_msec = now
		_window_event_count = 0
		_effect_window_counts.clear()
