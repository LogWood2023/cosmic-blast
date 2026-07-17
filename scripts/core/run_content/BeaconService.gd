class_name BeaconService
extends RefCounted
## Deterministic beacon candidate service. Combat hook validation is injected through a frozen allowlist.

const BEACON_DIRECTORY: String = "res://data/beacons"
const BalanceServiceScript := preload("res://scripts/core/BalanceService.gd")
const FALLBACK_MAX_ACTIVE_BEACONS: int = 3

var _resolver: BeaconResolver = BeaconResolver.new()
var _beacons: Array[BeaconData] = []
var _by_id: Dictionary = {}


func _init() -> void:
	_load_beacons()


func get_beacons() -> Array[BeaconData]:
	return _beacons.duplicate()


func get_beacon(beacon_id: String) -> BeaconData:
	return _by_id.get(beacon_id, null) as BeaconData


func prepare_choices(node_id: int, context: RunContentContext, seed: int, supported_hooks: PackedStringArray) -> Array[Dictionary]:
	var rules := context.get_active_rule_snapshot()
	var active_ids: Array = rules.get("beacon_ids", [])
	var active_keys: Array = rules.get("beacon_rule_keys", [])
	if active_ids.size() >= _max_active_beacons():
		return []
	var family := String(rules.get("primary_family", ""))
	var candidates: Array[BeaconData] = []
	for beacon in _beacons:
		if active_ids.has(beacon.beacon_id) or active_keys.has(beacon.rule_key):
			continue
		if not beacon.mechanic_hook.is_empty() and not supported_hooks.has(beacon.mechanic_hook):
			continue
		candidates.append(beacon)
	var selected := _select_candidates(candidates, family, seed)
	var views: Array[Dictionary] = []
	for beacon in selected:
		views.append(_resolver.make_choice_view(beacon, active_keys))
	return views


func resolve_choice(node_id: int, beacon_id: String, context: RunContentContext) -> RunMutationSet:
	var beacon := _by_id.get(beacon_id, null) as BeaconData
	if beacon == null:
		return null
	var rules := context.get_active_rule_snapshot()
	if Array(rules.get("beacon_ids", [])).size() >= _max_active_beacons() or Array(rules.get("beacon_rule_keys", [])).has(beacon.rule_key):
		return null
	return _resolver.resolve_activation(beacon, context, node_id)


func get_active_rule_snapshot(active_beacons: Array[BeaconData]) -> Dictionary:
	var ids: Array[String] = []
	var rules: Dictionary = {}
	for beacon in active_beacons:
		ids.append(beacon.beacon_id)
		rules[beacon.rule_key] = beacon.rule_parameters.duplicate(true)
	return {"beacon_ids": ids, "rules": rules}.duplicate(true)


func _select_candidates(candidates: Array[BeaconData], family: String, seed: int) -> Array[BeaconData]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var selected: Array[BeaconData] = []
	for wanted_category in ["family", "general", "economy"]:
		var matching: Array[BeaconData] = []
		for beacon in candidates:
			if selected.has(beacon):
				continue
			if wanted_category == "family" and beacon.family_tag == family:
				matching.append(beacon)
			elif wanted_category != "family" and beacon.category == wanted_category:
				matching.append(beacon)
		if not matching.is_empty():
			selected.append(_take_weighted(matching, rng))
	for beacon in candidates:
		if selected.size() >= 3:
			break
		if not selected.has(beacon):
			selected.append(beacon)
	return selected


func _take_weighted(candidates: Array[BeaconData], rng: RandomNumberGenerator) -> BeaconData:
	var total := 0.0
	for beacon in candidates:
		total += maxf(0.0, beacon.weight)
	if total <= 0.0:
		return candidates[rng.randi_range(0, candidates.size() - 1)]
	var roll := rng.randf_range(0.0, total)
	for beacon in candidates:
		roll -= maxf(0.0, beacon.weight)
		if roll <= 0.0:
			return beacon
	return candidates.back()


func _load_beacons() -> void:
	var directory := DirAccess.open(BEACON_DIRECTORY)
	if directory == null:
		push_error("BeaconService: beacon directory is unavailable: %s" % BEACON_DIRECTORY)
		return
	for filename in directory.get_files():
		if not filename.ends_with(".tres"):
			continue
		var beacon := load("%s/%s" % [BEACON_DIRECTORY, filename]) as BeaconData
		if beacon != null and beacon.is_valid_definition():
			_apply_master_balance(beacon)
			_beacons.append(beacon)
			_by_id[beacon.beacon_id] = beacon
	_beacons.sort_custom(func(a: BeaconData, b: BeaconData) -> bool: return a.beacon_id < b.beacon_id)


func _apply_master_balance(beacon: BeaconData) -> void:
	var record := BalanceServiceScript.get_record_snapshot("beacon", beacon.beacon_id)
	if record.is_empty():
		return
	var attributes: Dictionary = record.attributes
	beacon.title = String(record.get("name", beacon.title))
	beacon.family_tag = String(attributes.get("family", beacon.family_tag))
	beacon.role_tag = String(attributes.get("role", beacon.role_tag))
	beacon.weight = float(attributes.get("weight", beacon.weight))
	beacon.risk = int(attributes.get("risk", beacon.risk))
	beacon.rule_key = String(attributes.get("rule_key", beacon.rule_key))
	beacon.rule_parameters = Dictionary(attributes.get("payload", {})).duplicate(true)
	beacon.category = "family" if beacon.family_tag != "general" else ("economy" if beacon.role_tag == "economy" else "general")


func _max_active_beacons() -> int:
	return int(Dictionary(BalanceServiceScript.get_attributes("beacon", "beacon_base_count").get("payload", {})).get("active_cap", FALLBACK_MAX_ACTIVE_BEACONS))
