extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	if not RunManager.has_method("get_active_event_contracts"):
		_fail("RunManager should expose get_active_event_contracts().")
		return
	var event_id := _force_accessible_node(RunManager.NODE_EVENT, 2)
	_check_salvage_contract_starts_contract(event_id)
	if _failed:
		return
	_check_contract_applies_and_expires()
	if _failed:
		return
	RunManager.start_new_run()
	_check_crisis_blackbox_starts_pressure_contract()
	if _failed:
		return
	_check_blackbox_contract_modifies_stats_and_expires()
	if _failed:
		return
	RunManager.start_new_run()
	_check_family_contract_catalog()
	if _failed:
		return
	_check_colossus_family_contract_modifies_dash_and_expires()
	if _failed:
		return
	print("Event contract effect check passed.")
	get_tree().quit(0)


func _check_salvage_contract_starts_contract(event_id: int) -> void:
	RunManager.force_next_event_id = "salvage_contract"
	var choices: Array = RunManager.prepare_event_choices(event_id, 4401)
	if choices.is_empty() or String(choices[0].get("choice_id", "")) != "salvage_contract":
		_fail("Forced salvage contract should be offered first.")
		return
	GameManager.player_hp = 80
	var result: Dictionary = RunManager.resolve_event_choice(event_id, "salvage_contract", 4401)
	if not bool(result.get("ok", false)):
		_fail("Salvage contract event should resolve: %s" % str(result))
		return
	var contracts: Array = RunManager.call("get_active_event_contracts")
	if contracts.size() != 1:
		_fail("Salvage contract should create one active event contract, got %d: %s" % [contracts.size(), str(contracts)])
		return
	var contract := Dictionary(contracts[0])
	if String(contract.get("contract_id", "")) != "salvage_contract":
		_fail("Active contract should identify salvage_contract: %s" % str(contract))
		return
	if int(contract.get("remaining_nodes", 0)) != 2:
		_fail("Salvage contract should last for 2 completed nodes: %s" % str(contract))
		return
	if float(contract.get("mineral_bonus_rate", 0.0)) <= 0.0 or int(contract.get("extra_crisis_on_complete", 0)) <= 0:
		_fail("Salvage contract should expose mineral bonus and crisis pressure: %s" % str(contract))
		return
	if String(result.get("contract_title", "")).is_empty():
		_fail("Event result should expose gained contract title: %s" % str(result))
		return


func _check_contract_applies_and_expires() -> void:
	var node_one := _force_accessible_node(RunManager.NODE_BATTLE, 1)
	var minerals_before := RunManager.minerals
	var crisis_before := RunManager.crisis_level
	RunManager.current_node_id = node_one
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	RunManager.record_mineral_collected(100)
	var first_summary := RunManager.complete_explore_room_success()
	if not bool(first_summary.get("ok", false)):
		_fail("Completing first contracted node should succeed: %s" % str(first_summary))
		return
	var gained_one := RunManager.minerals - minerals_before
	if gained_one <= 100:
		_fail("First contracted node should grant mineral bonus, gained=%d." % gained_one)
		return
	if RunManager.crisis_level - crisis_before < 2:
		_fail("First contracted node should add normal crisis plus contract crisis.")
		return
	if int(first_summary.get("event_contract_crisis_added", 0)) <= 0 or int(first_summary.get("event_contract_minerals_added", 0)) <= 0:
		_fail("Completion summary should expose contract effects: %s" % str(first_summary))
		return
	var contracts_after_first: Array = RunManager.call("get_active_event_contracts")
	if contracts_after_first.size() != 1 or int(Dictionary(contracts_after_first[0]).get("remaining_nodes", 0)) != 1:
		_fail("Contract should tick to 1 node after first completion: %s" % str(contracts_after_first))
		return

	var node_two := _force_accessible_node(RunManager.NODE_BATTLE, 1)
	RunManager.current_node_id = node_two
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	RunManager.record_mineral_collected(100)
	var second_summary := RunManager.complete_explore_room_success()
	if not bool(second_summary.get("ok", false)):
		_fail("Completing second contracted node should succeed: %s" % str(second_summary))
		return
	if RunManager.crisis_level != 5 or not RunManager.is_alert_active():
		_fail("Contract crisis pressure should stop at the next uncleared alert threshold, crisis=%d." % RunManager.crisis_level)
		return
	var contracts_after_second: Array = RunManager.call("get_active_event_contracts")
	if not contracts_after_second.is_empty():
		_fail("Contract should expire after second completed node: %s" % str(contracts_after_second))
		return
	if int(second_summary.get("expired_event_contract_count", 0)) <= 0:
		_fail("Second summary should report expired contract: %s" % str(second_summary))
		return


func _check_crisis_blackbox_starts_pressure_contract() -> void:
	var event_id := _force_accessible_node(RunManager.NODE_EVENT, 2)
	RunManager.force_next_event_id = "crisis_blackbox"
	var choices: Array = RunManager.prepare_event_choices(event_id, 5501)
	if choices.is_empty() or String(choices[0].get("choice_id", "")) != "crisis_blackbox":
		_fail("Forced crisis blackbox should be offered first.")
		return
	if String(choices[0].get("contract_preview", "")).is_empty():
		_fail("Crisis blackbox choice should preview its temporary contract: %s" % str(choices[0]))
		return
	GameManager.player_hp = 80
	var result: Dictionary = RunManager.resolve_event_choice(event_id, "crisis_blackbox", 5501)
	if not bool(result.get("ok", false)):
		_fail("Crisis blackbox event should resolve: %s" % str(result))
		return
	var contracts: Array = RunManager.call("get_active_event_contracts")
	if contracts.size() != 1:
		_fail("Crisis blackbox should create one active event contract, got %d: %s" % [contracts.size(), str(contracts)])
		return
	var contract := Dictionary(contracts[0])
	if String(contract.get("contract_id", "")) != "crisis_blackbox":
		_fail("Active blackbox contract should identify crisis_blackbox: %s" % str(contract))
		return
	if int(contract.get("remaining_nodes", 0)) != 2:
		_fail("Crisis blackbox contract should last for 2 completed nodes: %s" % str(contract))
		return
	if float(contract.get("equipment_chance_bonus", 0.0)) <= 0.0 or float(contract.get("frenzy_gain_mult", 1.0)) >= 1.0:
		_fail("Blackbox contract should raise equipment chance and reduce frenzy gain: %s" % str(contract))
		return


func _check_blackbox_contract_modifies_stats_and_expires() -> void:
	var battle_id := _force_accessible_node(RunManager.NODE_BATTLE, 1)
	var base_chance := float(RunManager.get_map_node(battle_id).get("equipment_drop_chance", 0.0))
	var boosted_chance := RunManager.get_node_equipment_drop_chance(battle_id)
	var contracted_frenzy_mult := RunManager.get_frenzy_gain_mult()
	if boosted_chance <= base_chance:
		_fail("Blackbox contract should boost equipment chance, base=%.2f boosted=%.2f." % [base_chance, boosted_chance])
		return
	if contracted_frenzy_mult >= 1.0:
		_fail("Blackbox contract should temporarily reduce frenzy gain, got %.2f." % contracted_frenzy_mult)
		return
	RunManager.current_node_id = battle_id
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var first_summary := RunManager.complete_explore_room_success()
	if not bool(first_summary.get("ok", false)):
		_fail("Completing first blackbox node should succeed: %s" % str(first_summary))
		return
	if int(Dictionary(RunManager.call("get_active_event_contracts")[0]).get("remaining_nodes", 0)) != 1:
		_fail("Blackbox contract should tick to 1 node after first completion.")
		return

	var second_id := _force_accessible_node(RunManager.NODE_BATTLE, 1)
	RunManager.current_node_id = second_id
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var second_summary := RunManager.complete_explore_room_success()
	if not bool(second_summary.get("ok", false)):
		_fail("Completing second blackbox node should succeed: %s" % str(second_summary))
		return
	if not RunManager.call("get_active_event_contracts").is_empty():
		_fail("Blackbox contract should expire after two completed nodes.")
		return
	var recovered_frenzy_mult := RunManager.get_frenzy_gain_mult()
	if recovered_frenzy_mult <= contracted_frenzy_mult:
		_fail("Frenzy gain should recover after blackbox contract expires, before=%.2f after=%.2f." % [contracted_frenzy_mult, recovered_frenzy_mult])
		return


func _check_family_contract_catalog() -> void:
	var expected_families := {
		RunManager.FAMILY_BIASES[0]: "dash_distance_mult",
		RunManager.FAMILY_BIASES[1]: "bullet_count_bonus",
		RunManager.FAMILY_BIASES[2]: "gravity_pull_strength_bonus",
		RunManager.FAMILY_BIASES[3]: "frenzy_gain_mult",
		RunManager.FAMILY_BIASES[4]: "drone_slots_bonus",
	}
	var seen := {}
	for raw_profile in RunManager.get_event_profiles():
		var profile := Dictionary(raw_profile)
		var contract: Dictionary = profile.get("contract", {})
		if contract.is_empty():
			continue
		var family := String(contract.get("family_bias", ""))
		if family.is_empty():
			continue
		seen[family] = true
		if String(contract.get("effect_type", "")) != "family_route":
			_fail("Family contract should use family_route effect type: %s" % str(contract))
			return
		if String(contract.get("description", "")).is_empty():
			_fail("Family contract should expose Chinese description: %s" % str(contract))
			return
		var required_key := String(expected_families.get(family, ""))
		if required_key.is_empty() or not contract.has(required_key):
			_fail("Family contract for %s should expose %s: %s" % [family, required_key, str(contract)])
			return
	for family in expected_families.keys():
		if not seen.has(String(family)):
			_fail("Event library should include a family route contract for %s." % String(family))
			return


func _check_colossus_family_contract_modifies_dash_and_expires() -> void:
	var event_id := _force_accessible_node(RunManager.NODE_EVENT, 2)
	RunManager.force_next_event_id = "colossus_impact_route"
	var choices: Array = RunManager.prepare_event_choices(event_id, 6601)
	if choices.is_empty() or String(choices[0].get("choice_id", "")) != "colossus_impact_route":
		_fail("Forced colossus family route should be offered first.")
		return
	var preview := String(choices[0].get("contract_preview", ""))
	if preview.is_empty() or not preview.contains("冲锋"):
		_fail("Colossus route choice should preview dash contract effects: %s" % str(choices[0]))
		return
	GameManager.player_hp = 90
	var result: Dictionary = RunManager.resolve_event_choice(event_id, "colossus_impact_route", 6601)
	if not bool(result.get("ok", false)):
		_fail("Colossus route event should resolve: %s" % str(result))
		return
	var contracts: Array = RunManager.call("get_active_event_contracts")
	if contracts.size() != 1:
		_fail("Colossus route should create one active event contract, got %d: %s" % [contracts.size(), str(contracts)])
		return
	var contract := Dictionary(contracts[0])
	if String(contract.get("family_bias", "")) != RunManager.FAMILY_BIASES[0]:
		_fail("Colossus route contract should record family bias: %s" % str(contract))
		return
	var boosted_stats := RunManager.get_player_stats()
	if float(boosted_stats.get("dash_distance_mult", 1.0)) <= 1.0 or float(boosted_stats.get("dash_damage_mult", 1.0)) <= 1.0:
		_fail("Colossus route contract should boost dash stats: %s" % str(boosted_stats))
		return
	for _i in range(2):
		var battle_id := _force_accessible_node(RunManager.NODE_BATTLE, 1)
		RunManager.current_node_id = battle_id
		RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
		var summary := RunManager.complete_explore_room_success()
		if not bool(summary.get("ok", false)):
			_fail("Completing node under colossus route should succeed: %s" % str(summary))
			return
	if not RunManager.call("get_active_event_contracts").is_empty():
		_fail("Colossus route contract should expire after its duration.")
		return
	RunManager.active_special_bonus_ids.clear()
	var recovered_stats := RunManager.get_player_stats()
	if float(recovered_stats.get("dash_distance_mult", 1.0)) != 1.0:
		_fail("Dash distance contract should leave no temporary residue after expiry: %s" % str(recovered_stats))
		return
	if float(recovered_stats.get("dash_damage_mult", 1.0)) != 1.0:
		_fail("Dash damage contract should leave no temporary residue after expiry: %s" % str(recovered_stats))
		return


func _force_accessible_node(node_type: String, tier: int) -> int:
	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		if bool(node.get("completed", false)) or int(node.get("tier", 0)) != tier:
			continue
		node["type"] = node_type
		node["completed"] = false
		var links: Array = node.get("links", [])
		if not links.has(RunManager.CENTER_ID):
			links.append(RunManager.CENTER_ID)
		node["links"] = links
		RunManager.map_nodes[i] = node
		var base := RunManager.map_nodes[RunManager.CENTER_ID]
		var base_links: Array = base.get("links", [])
		if not base_links.has(node_id):
			base_links.append(node_id)
		base["links"] = base_links
		RunManager.map_nodes[RunManager.CENTER_ID] = base
		return node_id
	return -1


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
