extends Node
## Read-only gateway for balance assets. Runtime systems receive values, never mutate Resources.

const MASTER_TABLE_PATH: String = "res://data/balance/master_balance.tsv"
const GENERATED_DIRECTORY: String = "res://data/balance/generated"
const MANIFEST_PATH: String = "res://data/balance/generated/manifest.tres"
const RUN_PACING_PATH: String = "res://data/balance/run_pacing.tres"
const COMBAT_PATH: String = "res://data/balance/combat_balance.tres"
const ECONOMY_PATH: String = "res://data/balance/economy_balance.tres"
const RunPacingConfigScript := preload("res://scripts/data/balance/RunPacingConfig.gd")
const CombatBalanceConfigScript := preload("res://scripts/data/balance/CombatBalanceConfig.gd")
const EconomyBalanceConfigScript := preload("res://scripts/data/balance/EconomyBalanceConfig.gd")
const BalanceDomainDataScript := preload("res://scripts/data/balance/BalanceDomainData.gd")
const BalanceManifestDataScript := preload("res://scripts/data/balance/BalanceManifestData.gd")

static var _run_pacing: Resource
static var _combat: Resource
static var _economy: Resource
static var _manifest: Resource
static var _domains: Dictionary = {}
static var _records_by_key: Dictionary = {}


func _ready() -> void:
	_ensure_loaded()


static func _ensure_loaded() -> void:
	if _manifest != null:
		return
	_run_pacing = _load_or_default(RUN_PACING_PATH, RunPacingConfigScript)
	_combat = _load_or_default(COMBAT_PATH, CombatBalanceConfigScript)
	_economy = _load_or_default(ECONOMY_PATH, EconomyBalanceConfigScript)
	_manifest = load(MANIFEST_PATH) as Resource
	if _manifest == null:
		push_error("BalanceService: generated manifest is missing. Run the master balance importer.")
		return
	var domain_names: Array = _manifest.domain_counts.keys()
	domain_names.sort()
	for domain_variant in domain_names:
		var domain_name := String(domain_variant)
		var data := load("%s/%s.tres" % [GENERATED_DIRECTORY, domain_name]) as Resource
		if data == null:
			push_error("BalanceService: generated domain is missing: %s" % domain_name)
			continue
		_domains[domain_name] = data
		for record in data.records:
			_records_by_key[_record_key(domain_name, record.record_id)] = record


static func get_stage_for_crisis(crisis: int) -> int:
	_ensure_loaded()
	return _run_pacing.get_stage_for_crisis(crisis)


static func get_damage(category: StringName) -> int:
	_ensure_loaded()
	return _combat.get_damage(category)


static func get_elite_ehp(stage: int) -> int:
	_ensure_loaded()
	return _combat.get_stage_value(_combat.elite_ehp, stage)


static func get_boss_ehp(stage: int) -> int:
	_ensure_loaded()
	return _combat.get_stage_value(_combat.boss_ehp, stage)


static func get_economy_snapshot() -> Dictionary:
	_ensure_loaded()
	return {
		"reward_minerals_range": _economy.reward_minerals_range,
		"reward_repair_range": _economy.reward_repair_range,
		"shop_reroll_base_cost": _economy.shop_reroll_base_cost,
		"shop_reroll_cost_step": _economy.shop_reroll_cost_step,
	}


static func get_run_pacing_snapshot() -> Dictionary:
	_ensure_loaded()
	return {
		"crisis_thresholds": _run_pacing.crisis_thresholds.duplicate(),
		"starting_compute_capacity": _run_pacing.starting_compute_capacity,
		"equipment_targets_per_boss": _run_pacing.equipment_targets_per_boss.duplicate(),
	}


static func get_schema_version() -> String:
	_ensure_loaded()
	return _manifest.schema_version if _manifest != null else ""


static func get_content_version() -> String:
	_ensure_loaded()
	return _manifest.content_version if _manifest != null else ""


static func get_total_record_count() -> int:
	_ensure_loaded()
	return _manifest.total_records if _manifest != null else 0


static func is_generated_data_current() -> bool:
	_ensure_loaded()
	if _manifest == null or not FileAccess.file_exists(MASTER_TABLE_PATH):
		return false
	if FileAccess.get_sha256(MASTER_TABLE_PATH) != _manifest.source_sha256:
		return false
	if _records_by_key.size() != _manifest.total_records:
		return false
	for domain_name in _manifest.domain_counts:
		var data := _domains.get(String(domain_name), null) as Resource
		if data == null or data.records.size() != int(_manifest.domain_counts[domain_name]):
			return false
	if _combat == null or _combat.enemy_base_hp != int(get_value("enemy", "enemy_base_hp", -1)):
		return false
	if _combat.elite_ehp != PackedInt32Array([int(get_stage_value("elite", "elite_ehp", 1)), int(get_stage_value("elite", "elite_ehp", 2)), int(get_stage_value("elite", "elite_ehp", 3))]):
		return false
	if _run_pacing == null or _run_pacing.equipment_targets_per_boss != PackedInt32Array([int(get_stage_value("economy", "equipped_aux_before_boss", 1)), int(get_stage_value("economy", "equipped_aux_before_boss", 2)), int(get_stage_value("economy", "equipped_aux_before_boss", 3))]):
		return false
	if _economy == null or _economy.shop_reroll_base_cost != int(get_value("economy", "reroll_base", -1)):
		return false
	return true


static func get_record_snapshot(domain: String, record_id: String) -> Dictionary:
	_ensure_loaded()
	var record := _get_record(domain, record_id)
	if record == null:
		return {}
	var snapshot: Dictionary = record.to_snapshot()
	snapshot["attributes"] = _parse_attributes(record.raw_attributes)
	return snapshot.duplicate(true)


static func get_domain_records(domain: String, kind: String = "") -> Array[Dictionary]:
	_ensure_loaded()
	var data := _domains.get(domain, null) as Resource
	var snapshots: Array[Dictionary] = []
	if data == null:
		return snapshots
	for record in data.records:
		if not kind.is_empty() and record.kind != kind:
			continue
		var snapshot: Dictionary = record.to_snapshot()
		snapshot["attributes"] = _parse_attributes(record.raw_attributes)
		snapshots.append(snapshot)
	return snapshots


static func get_value(domain: String, record_id: String, default_value: Variant = null) -> Variant:
	_ensure_loaded()
	var record := _get_record(domain, record_id)
	return record.get_typed_value(0, default_value) if record != null else default_value


static func get_stage_value(domain: String, record_id: String, stage: int, default_value: Variant = null) -> Variant:
	_ensure_loaded()
	var record := _get_record(domain, record_id)
	return record.get_typed_value(stage, default_value) if record != null else default_value


static func get_attributes(domain: String, record_id: String) -> Dictionary:
	_ensure_loaded()
	var record := _get_record(domain, record_id)
	return _parse_attributes(record.raw_attributes).duplicate(true) if record != null else {}


static func get_equipment_snapshot(item_id: String) -> Dictionary:
	var record := get_record_snapshot("equipment", item_id)
	if record.is_empty() or not String(record.get("kind", "")) in ["weapon", "auxiliary"]:
		return {}
	var attributes: Dictionary = record.attributes
	var item := {
		"name": String(record.name),
		"type": "weapon" if String(record.kind) == "weapon" else "aux",
		"family": String(attributes.get("family", "general")),
		"role": String(attributes.get("role", "starter")),
		"rarity": String(attributes.get("rarity", "common")),
		"price": int(attributes.get("price", 0)),
		"compute_cost": int(attributes.get("compute", 0)),
	}
	for stat_key in Dictionary(attributes.get("stats", {})):
		item[stat_key] = Dictionary(attributes.stats)[stat_key]
	return item


static func get_calibration_effects(calibration_id: String) -> Dictionary:
	var payload := Dictionary(get_attributes("calibration", calibration_id).get("payload", {}))
	match calibration_id:
		"wide_scan": return {"map_intel_layers": int(payload.get("reveal_future_layers", 0))}
		"procurement_voucher": return {"free_shop_rerolls": int(payload.get("free_first_shop_reroll", 0))}
		"resonance_compass": return {"family_weight_mult": float(payload.get("family_weight_mult", 1.0)), "family_weight_draws": int(payload.get("first_drafts", 0)), "general_weight_mult": float(payload.get("general_weight_mult", 1.0))}
		"emergency_bulkhead": return {"emergency_heal_threshold": int(payload.get("trigger_hp", 0)), "emergency_heal_amount": int(payload.get("heal", 0)), "invulnerable_seconds": float(payload.get("invulnerable_seconds", 0.0)), "starting_mineral_debt": int(payload.get("starting_mineral_debt", 0))}
		"overclock_lease": return {"starting_compute_bonus": int(payload.get("starting_compute_add", 0)), "shop_price_mult": float(payload.get("shop_price_mult", 1.0))}
		"frenzy_preheat": return {"starting_heat": float(payload.get("starting_heat", 0.0)), "heat_cap_bonus": float(payload.get("heat_gain_cap_add", 0.0)), "healing_mult": float(payload.get("healing_mult", 1.0))}
		"salvage_probe": return {"mark_high_value_targets": bool(payload.get("mark_high_value_on_start", false)), "mineral_mult": float(payload.get("mineral_mult", 1.0)), "patrol_enemy_cap_bonus": int(payload.get("patrol_cap_add", 0))}
		"chaos_seed": return {"grant_random_common_auxiliary": bool(payload.get("start_random_common_aux", false)), "uses_compute": bool(payload.get("uses_compute", false)), "disable_stage_one_family_focus": not bool(payload.get("stage1_family_shop_focus", true))}
	return {}


static func get_crisis_modifiers(level: int) -> Dictionary:
	if level < 1 or level > 10:
		return {}
	var payload := Dictionary(get_attributes("crisis", "crisis_%d" % level).get("payload", {}))
	match level:
		1: return {"exploration": {"patrol_interval_mult": float(payload.get("patrol_interval_mult", 1.0)), "patrol_enemy_cap_bonus": int(payload.get("enemy_cap_add", 0))}}
		2: return {"economy": {"shop_price_mult": float(payload.get("shop_price_mult", 1.0)), "reroll_base_bonus": int(payload.get("reroll_base_add", 0))}}
		3: return {"enemy": {"elite_family_affix_count": int(payload.get("elite_family_affix", 0)), "elite_ehp_mult": float(payload.get("elite_ehp_mult", 1.0))}}
		4:
			var cost_mult := float(payload.get("event_cost_mult", 1.0))
			return {"event": {"hp_cost_mult": cost_mult, "mineral_cost_mult": cost_mult, "high_risk_reward_mult": float(payload.get("high_risk_reward_mult", 1.0))}}
		5: return {"boss": {"ehp_mult": float(payload.get("boss_ehp_mult", 1.0)), "phase_enrage_threshold": float(payload.get("boss_enhance_at_hp_ratio", 0.0)), "phase_enrage_count": 1}}
		6: return {"exploration": {"trap_count_mult": float(payload.get("trap_count_mult", 1.0)), "trap_damage_mult": 1.0}}
		7: return {"healing": {"mult": float(payload.get("healing_mult", 1.0)), "minimum": int(payload.get("minimum_heal", 0))}}
		8: return {"enemy": {"mixed_family_wave_chance": float(payload.get("mixed_family_wave_chance", 0.0))}}
		9: return {"boss": {"cooldown_mult": float(payload.get("boss_skill_cooldown_mult", 1.0)), "family_variant_count": int(payload.get("family_enhanced_move", 0))}}
		10: return {"run": {"active_condition_count_bonus": maxi(0, int(payload.get("active_conditions", 2)) - 2)}, "boss": {"final_family_affix_count": int(payload.get("final_boss_random_family_verdict", 0))}}
	return {}


static func get_boss_family_multiplier(family_id: String) -> float:
	var normalized := family_id
	var localized := {
		"星间巨构": "colossus", "天堂号": "paradise", "扭曲星核": "warped",
		"地狱之眼": "hell_eye", "神明使者": "divine",
	}
	normalized = String(localized.get(normalized, normalized))
	var attributes := get_attributes("boss", "boss_%s_ehp" % normalized)
	return float(Dictionary(attributes.get("payload", {})).get("family_mult", 1.0))


static func _get_record(domain: String, record_id: String) -> Resource:
	return _records_by_key.get(_record_key(domain, record_id), null) as Resource


static func _record_key(domain: String, record_id: String) -> String:
	return "%s/%s" % [domain, record_id]


static func _parse_attributes(raw: String) -> Dictionary:
	var result: Dictionary = {}
	if raw.is_empty():
		return result
	var nested_key := ""
	for token_variant in raw.split(";", false):
		var token := String(token_variant)
		var separator := token.find("=")
		if separator < 0:
			continue
		var key := token.substr(0, separator)
		var value_text := token.substr(separator + 1)
		if key == "payload" or key == "stats":
			nested_key = key
			result[nested_key] = {}
			if nested_key == "stats":
				result[nested_key] = _parse_stats(value_text)
			else:
				_insert_nested_pair(result[nested_key], value_text)
		elif not nested_key.is_empty():
			Dictionary(result[nested_key])[key] = _parse_scalar(value_text)
		else:
			result[key] = _parse_scalar(value_text)
	return result


static func _parse_stats(raw: String) -> Dictionary:
	var stats: Dictionary = {}
	for token_variant in raw.split("|", false):
		var token := String(token_variant)
		var separator := token.find(":")
		if separator < 0:
			continue
		stats[token.substr(0, separator)] = _parse_scalar(token.substr(separator + 1))
	return stats


static func _insert_nested_pair(target: Dictionary, raw: String) -> void:
	var separator := raw.find("=")
	if separator >= 0:
		target[raw.substr(0, separator)] = _parse_scalar(raw.substr(separator + 1))


static func _parse_scalar(raw: String) -> Variant:
	if raw == "true":
		return true
	if raw == "false":
		return false
	if raw.contains("/"):
		var pieces := raw.split("/", false)
		var all_ints := true
		var all_numbers := true
		for piece in pieces:
			all_ints = all_ints and String(piece).is_valid_int()
			all_numbers = all_numbers and String(piece).is_valid_float()
		if all_ints:
			var ints := PackedInt32Array()
			for piece in pieces: ints.append(int(piece))
			return ints
		if all_numbers:
			var floats := PackedFloat32Array()
			for piece in pieces: floats.append(float(piece))
			return floats
		return PackedStringArray(pieces)
	if raw.contains("|"):
		return PackedStringArray(raw.split("|", false))
	if raw.is_valid_int():
		return int(raw)
	if raw.is_valid_float():
		return float(raw)
	return raw


static func _load_or_default(path: String, script: Script) -> Resource:
	var loaded := load(path) as Resource
	if loaded != null and loaded.get_script() == script:
		return loaded
	push_error("BalanceService: failed to load %s; using safe defaults." % path)
	return script.new() as Resource
