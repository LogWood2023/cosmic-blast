extends Node

const COLOSSUS_SAMPLE := preload("res://data/mechanics/runtime_samples/colossus_aftershock.tres")
const PARADISE_SAMPLE := preload("res://data/mechanics/runtime_samples/paradise_split.tres")
const WARPED_SAMPLE := preload("res://data/mechanics/runtime_samples/warped_mark.tres")
const HELL_EYE_SAMPLE := preload("res://data/mechanics/runtime_samples/hell_eye_heat.tres")
const DIVINE_SAMPLE := preload("res://data/mechanics/runtime_samples/divine_drone_copy.tres")

func _ready() -> void:
	var runtime := MechanicRuntime.new()
	add_child(runtime)
	var effect := MechanicEffectData.new()
	effect.effect_id = "split_once"
	effect.trigger = "on_hit"
	effect.action = "spawn_projectile"
	effect.proc_coefficient = 0.35
	runtime.set_effects([effect])
	var first := runtime.dispatch("on_hit", {"generation": 0, "lineage_effect_ids": [], "proc_coefficient": 1.0})
	if first.size() != 1 or not is_equal_approx(float(first[0].get("proc_coefficient", 0.0)), 0.35 * 0.65):
		_fail("Runtime should emit one scaled event.")
		return
	var recursive := runtime.dispatch("on_hit", Dictionary(first[0]))
	if not recursive.is_empty():
		_fail("Same effect must not re-enter its lineage.")
		return
	var capped := runtime.dispatch("on_hit", {"generation": 3, "lineage_effect_ids": [], "proc_coefficient": 1.0})
	if not capped.is_empty():
		_fail("Generation cap must stop events.")
		return
	var combined_runtime := MechanicRuntime.new()
	add_child(combined_runtime)
	combined_runtime.set_effects([COLOSSUS_SAMPLE, PARADISE_SAMPLE, WARPED_SAMPLE, HELL_EYE_SAMPLE, DIVINE_SAMPLE])
	combined_runtime.set_active_rule_keys(["dash_aftershock", "projectile_split_once", "mass_mark", "frenzy_overheat_bank", "drone_hit_proc"])
	var hit_actions := combined_runtime.dispatch("on_hit", {"generation": 0, "lineage_effect_ids": [], "proc_coefficient": 1.0})
	if not _contains_action(hit_actions, "spawn_projectile") or not _contains_action(hit_actions, "apply_mark") or not _contains_action(hit_actions, "add_heat"):
		_fail("The Paradise, Warped, and Hell-eye samples must combine on hit.")
		return
	var dash_actions := combined_runtime.dispatch("on_dash_hit", {"generation": 0, "lineage_effect_ids": [], "proc_coefficient": 1.0})
	if not _contains_action(dash_actions, "area_damage"):
		_fail("The Colossus sample must provide an area-damage hook.")
		return
	var drone_actions := combined_runtime.dispatch("on_drone_action", {"generation": 0, "lineage_effect_ids": [], "proc_coefficient": 1.0})
	if not _contains_action(drone_actions, "drone_action"):
		_fail("The Divine sample must provide a drone-action hook.")
		return
	print("Mechanic runtime check passed.")
	get_tree().quit(0)


func _contains_action(events: Array[Dictionary], action: String) -> bool:
	for event in events:
		if String(event.get("action", "")) == action:
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
