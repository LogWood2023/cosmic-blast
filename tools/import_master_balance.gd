extends SceneTree

const SOURCE_PATH: String = "res://data/balance/master_balance.tsv"
const OUTPUT_DIRECTORY: String = "res://data/balance/generated"
const MANIFEST_PATH: String = "res://data/balance/generated/manifest.tres"
const BalanceRecordScript := preload("res://scripts/data/balance/BalanceRecord.gd")
const BalanceDomainDataScript := preload("res://scripts/data/balance/BalanceDomainData.gd")
const BalanceManifestDataScript := preload("res://scripts/data/balance/BalanceManifestData.gd")
const CombatBalanceConfigScript := preload("res://scripts/data/balance/CombatBalanceConfig.gd")
const EconomyBalanceConfigScript := preload("res://scripts/data/balance/EconomyBalanceConfig.gd")
const RunPacingConfigScript := preload("res://scripts/data/balance/RunPacingConfig.gd")


func _initialize() -> void:
	var rows := _read_rows()
	if rows.is_empty():
		_fail("Master balance table contains no records.")
		return
	var check_only := OS.get_cmdline_args().has("--check") or OS.get_cmdline_user_args().has("--check")
	var ok := _check_generated(rows) if check_only else _generate(rows)
	if ok:
		print("Master balance %s passed: %d records." % ["drift check" if check_only else "import", rows.size()])
		quit(0)
	else:
		quit(1)


func _read_rows() -> Array[Dictionary]:
	var file := FileAccess.open(SOURCE_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s" % SOURCE_PATH)
		return []
	var headers := file.get_csv_line("\t")
	var rows: Array[Dictionary] = []
	while file.get_position() < file.get_length():
		var columns := file.get_csv_line("\t")
		if columns.is_empty() or (columns.size() == 1 and columns[0].is_empty()):
			continue
		if columns.size() != headers.size():
			push_error("Invalid TSV row %d: expected %d columns, got %d." % [rows.size() + 2, headers.size(), columns.size()])
			return []
		var row: Dictionary = {}
		for index in headers.size():
			row[String(headers[index])] = String(columns[index])
		rows.append(row)
	return rows


func _generate(rows: Array[Dictionary]) -> bool:
	var absolute_output := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	if DirAccess.make_dir_recursive_absolute(absolute_output) != OK:
		push_error("Cannot create generated balance directory.")
		return false
	var domains := _group_by_domain(rows)
	var domain_names: Array = domains.keys()
	domain_names.sort()
	for domain_variant in domain_names:
		var domain_name := String(domain_variant)
		var data := BalanceDomainDataScript.new() as Resource
		data.schema_version = String(rows[0].get("schema_version", ""))
		data.domain = domain_name
		for row in Array(domains[domain_name]):
			data.records.append(_make_record(row))
		if ResourceSaver.save(data, "%s/%s.tres" % [OUTPUT_DIRECTORY, domain_name]) != OK:
			push_error("Failed to save generated domain: %s" % domain_name)
			return false
	if not _save_typed_configs(rows):
		return false
	var manifest := BalanceManifestDataScript.new() as Resource
	manifest.schema_version = String(rows[0].get("schema_version", ""))
	manifest.content_version = _row_value(rows, "meta", "balance_content_version")
	manifest.source_sha256 = FileAccess.get_sha256(SOURCE_PATH)
	manifest.total_records = rows.size()
	for domain_variant in domain_names:
		var domain_name := String(domain_variant)
		manifest.domain_counts[domain_name] = Array(domains[domain_name]).size()
	return ResourceSaver.save(manifest, MANIFEST_PATH) == OK


func _check_generated(rows: Array[Dictionary]) -> bool:
	var manifest := load(MANIFEST_PATH) as Resource
	if manifest == null or manifest.source_sha256 != FileAccess.get_sha256(SOURCE_PATH) or manifest.total_records != rows.size():
		push_error("Generated manifest drifted from the master table.")
		return false
	var domains := _group_by_domain(rows)
	for domain_variant in domains:
		var domain_name := String(domain_variant)
		var generated := load("%s/%s.tres" % [OUTPUT_DIRECTORY, domain_name]) as Resource
		var source_rows: Array = domains[domain_name]
		if generated == null or generated.records.size() != source_rows.size():
			push_error("Generated domain drifted: %s" % domain_name)
			return false
		for index in source_rows.size():
			var source: Dictionary = source_rows[index]
			var record: Resource = generated.records[index]
			if record.record_id != String(source.id) or record.raw_value != String(source.value) or record.raw_attributes != String(source.attributes):
				push_error("Generated record drifted: %s/%s" % [domain_name, source.id])
				return false
	return _check_typed_configs(rows)


func _check_typed_configs(rows: Array[Dictionary]) -> bool:
	var combat := load("res://data/balance/combat_balance.tres") as Resource
	var pacing := load("res://data/balance/run_pacing.tres") as Resource
	var economy := load("res://data/balance/economy_balance.tres") as Resource
	if combat == null or combat.enemy_base_hp != int(_row_value(rows, "enemy", "enemy_base_hp")) or combat.elite_ehp != _stage_ints(rows, "elite", "elite_ehp"):
		push_error("Generated combat balance config drifted.")
		return false
	if pacing == null or pacing.crisis_thresholds != _stage_ints(rows, "pacing", "crisis_thresholds") or pacing.equipment_targets_per_boss != _stage_ints(rows, "economy", "equipped_aux_before_boss"):
		push_error("Generated run pacing config drifted.")
		return false
	if economy == null or economy.shop_reroll_base_cost != int(_row_value(rows, "economy", "reroll_base")) or economy.equipment_drop_chances != _stage_floats(rows, "economy", "equipment_drop_chance"):
		push_error("Generated economy balance config drifted.")
		return false
	return true


func _group_by_domain(rows: Array[Dictionary]) -> Dictionary:
	var domains: Dictionary = {}
	for row in rows:
		var domain := String(row.domain)
		if not domains.has(domain):
			domains[domain] = []
		Array(domains[domain]).append(row)
	return domains


func _make_record(row: Dictionary) -> Resource:
	var record := BalanceRecordScript.new() as Resource
	record.schema_version = String(row.schema_version)
	record.domain = String(row.domain)
	record.kind = String(row.kind)
	record.record_id = String(row.id)
	record.display_name = String(row.name)
	record.raw_value = String(row.value)
	record.raw_stage_values = PackedStringArray([String(row.stage_1), String(row.stage_2), String(row.stage_3)])
	record.unit = String(row.unit)
	record.data_type = String(row.data_type)
	record.raw_attributes = String(row.attributes)
	record.formula = String(row.formula)
	record.notes = String(row.notes)
	return record


func _save_typed_configs(rows: Array[Dictionary]) -> bool:
	var combat := CombatBalanceConfigScript.new() as CombatBalanceConfig
	combat.player_max_hp = int(_row_value(rows, "player", "player_max_hp"))
	combat.player_move_speed = float(_row_value(rows, "player", "player_move_speed"))
	combat.player_base_attack = int(_row_value(rows, "player", "base_attack"))
	combat.player_base_fire_interval = float(_row_value(rows, "player", "base_fire_interval"))
	combat.damage_values = {"dot_min": 1, "dot_max": 3, "normal": int(_row_value(rows, "player", "normal_hit_damage")), "dangerous_min": 8, "dangerous_max": 12, "heavy_min": 34, "heavy_max": 40}
	combat.enemy_base_hp = int(_row_value(rows, "enemy", "enemy_base_hp"))
	combat.enemy_stage_multipliers = _stage_floats(rows, "enemy", "enemy_stage_multiplier")
	combat.elite_ehp = _stage_ints(rows, "elite", "elite_ehp")
	combat.boss_ehp = _stage_ints(rows, "boss", "boss_base_ehp")
	combat.dash_charges = int(_row_value(rows, "dash", "dash_charges"))
	combat.dash_charge_seconds = float(_row_value(rows, "dash", "dash_charge_seconds"))
	combat.dash_distance = float(_row_value(rows, "dash", "dash_distance"))
	combat.dash_speed = float(_row_value(rows, "dash", "dash_speed"))
	combat.dash_invulnerable_tail = float(_row_value(rows, "dash", "dash_invulnerable_tail"))
	combat.dash_base_damage_mult = float(_row_value(rows, "dash", "dash_base_damage_mult"))
	combat.dash_enemy_hit_radius = float(_row_value(rows, "dash", "dash_enemy_hit_radius"))
	combat.dash_boss_hit_radius = float(_row_value(rows, "dash", "dash_boss_hit_radius"))
	if ResourceSaver.save(combat, "res://data/balance/combat_balance.tres") != OK:
		return false
	var pacing := RunPacingConfigScript.new() as RunPacingConfig
	pacing.crisis_thresholds = _stage_ints(rows, "pacing", "crisis_thresholds")
	pacing.starting_compute_capacity = int(_row_value(rows, "economy", "starting_compute"))
	pacing.equipment_targets_per_boss = _stage_ints(rows, "economy", "equipped_aux_before_boss")
	pacing.completed_nodes_min = int(_row_value(rows, "pacing", "completed_nodes"))
	pacing.battle_nodes_range = Vector2i(8, 9)
	pacing.event_nodes_range = Vector2i(5, 7)
	pacing.non_battle_nodes_range = Vector2i(5, 7)
	pacing.exploration_minutes_range = Vector2(3.0, 5.0)
	pacing.accelerated_exploration_minutes_range = Vector2(1.5, 3.0)
	pacing.choice_seconds_range = Vector2i(20, 45)
	if ResourceSaver.save(pacing, "res://data/balance/run_pacing.tres") != OK:
		return false
	var economy := EconomyBalanceConfigScript.new() as EconomyBalanceConfig
	economy.reward_minerals_range = Vector2i(45, 105)
	economy.reward_repair_range = Vector2i(26, 52)
	economy.shop_reroll_base_cost = int(_row_value(rows, "economy", "reroll_base"))
	economy.shop_reroll_cost_step = int(_row_value(rows, "economy", "reroll_stage_step"))
	economy.shop_reroll_repeat_step = int(_row_value(rows, "economy", "reroll_repeat_step"))
	economy.shop_offer_count = int(_row_value(rows, "economy", "shop_offer_count"))
	economy.shop_general_slots = int(_row_value(rows, "economy", "shop_general_slots"))
	economy.shop_family_slots = int(_row_value(rows, "economy", "shop_family_slots"))
	economy.shop_build_slots = int(_row_value(rows, "economy", "shop_build_slots"))
	economy.shop_survival_slots = int(_row_value(rows, "economy", "shop_survival_slots"))
	economy.shop_wildcard_slots = int(_row_value(rows, "economy", "shop_wildcard_slots"))
	economy.equipment_drop_chances = _stage_floats(rows, "economy", "equipment_drop_chance")
	economy.equipment_drop_chance_range = Vector2(economy.equipment_drop_chances[0], economy.equipment_drop_chances[2])
	economy.equipment_drop_chance_cap = float(_row_value(rows, "economy", "equipment_drop_chance_cap"))
	economy.equipment_dry_nodes = int(_row_value(rows, "economy", "equipment_dry_nodes"))
	economy.starter_dry_drafts = int(_row_value(rows, "economy", "starter_dry_drafts"))
	economy.amplifier_dry_drafts = int(_row_value(rows, "economy", "amplifier_dry_drafts"))
	return ResourceSaver.save(economy, "res://data/balance/economy_balance.tres") == OK


func _row_value(rows: Array[Dictionary], domain: String, record_id: String, stage: int = 0) -> String:
	for row in rows:
		if String(row.domain) == domain and String(row.id) == record_id:
			return String(row.get("stage_%d" % stage, "")) if stage > 0 else String(row.value)
	return ""


func _stage_ints(rows: Array[Dictionary], domain: String, record_id: String) -> PackedInt32Array:
	return PackedInt32Array([int(_row_value(rows, domain, record_id, 1)), int(_row_value(rows, domain, record_id, 2)), int(_row_value(rows, domain, record_id, 3))])


func _stage_floats(rows: Array[Dictionary], domain: String, record_id: String) -> PackedFloat32Array:
	return PackedFloat32Array([float(_row_value(rows, domain, record_id, 1)), float(_row_value(rows, domain, record_id, 2)), float(_row_value(rows, domain, record_id, 3))])


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
