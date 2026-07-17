extends Node

var _service := BeaconService.new()
var _failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var beacons := _service.get_beacons()
	_assert(beacons.size() == 26, "Expected 26 beacon resources.")
	var keys := {}
	for beacon in beacons:
		_assert(beacon.is_valid_definition(), "Beacon must have exactly one rule key.")
		_assert(not keys.has(beacon.rule_key), "Rule keys must be mutually exclusive.")
		keys[beacon.rule_key] = true
	var context := RunContentContext.from_snapshot({"state_version": 1, "active_rules": {"primary_family": "divine", "beacon_ids": [], "beacon_rule_keys": []}})
	var hooks := PackedStringArray(["on_hit", "on_dash", "on_dash_hit", "on_dash_end", "on_shoot", "on_projectile_exit", "on_kill", "on_cluster", "on_heavy_hit", "on_frenzy_end", "on_frenzy_start", "on_heal", "on_room_complete", "on_drone_hit", "on_drone_action"])
	var choices := _service.prepare_choices(1, context, 99, hooks)
	_assert(choices.size() == 3, "Beacon node must offer three choices.")
	var mutation := _service.resolve_choice(1, String(choices[0].get("choice_id", "")), context)
	_assert(mutation != null and mutation.actions.size() == 1, "Beacon activation must return a mutation.")
	var capped := RunContentContext.from_snapshot({"state_version": 1, "active_rules": {"beacon_ids": ["a", "b", "c"], "beacon_rule_keys": []}})
	_assert(_service.prepare_choices(1, capped, 1, hooks).is_empty(), "No more than three beacons may activate.")
	if not _failed:
		print("Beacon service check passed.")
		get_tree().quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
