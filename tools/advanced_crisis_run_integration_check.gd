extends Node

const RunMutationSet := preload("res://scripts/core/run_content/RunMutationSet.gd")


func _ready() -> void:
	var original_meta := MetaProgressionState.to_dict()
	MetaProgressionState.clear_calibration_selection()
	MetaProgressionState.unlock_crisis(10)
	MetaProgressionState.select_crisis(10)
	RunManager.start_new_run()
	if RunManager.advanced_crisis_level != 10 or RunManager.get_active_rule_snapshot().get("advanced_crisis", {}).get("modifier_ids", []).size() != 10:
		_fail("Crisis snapshot was not injected into the active run.")
		return
	if RunManager.active_run_conditions.size() != 3:
		_fail("Crisis 10 must add the third active run condition.")
		return
	GameManager.player_hp = 50
	var heal := RunMutationSet.create("crisis-heal", "advanced_crisis_check", -1, RunManager.content_state_version)
	heal.add_action(&"heal", {"amount": 20})
	if not bool(RunManager.commit_mutation(heal).get("ok", false)) or GameManager.player_hp != 65:
		_fail("Crisis 7 healing modifier was not consumed exactly once.")
		return
	var base_price := EquipmentCatalog.get_price("general_contract_scanner")
	if RunManager.get_effective_shop_price("general_contract_scanner") != int(ceil(float(base_price) * 1.1)):
		_fail("Crisis 2 shop price modifier was not consumed.")
		return
	if RunManager.get_shop_reroll_cost() != 38:
		_fail("Crisis 2 reroll base modifier was not consumed.")
		return
	var battle_node_id := _find_accessible_battle_node()
	if battle_node_id < 0 or not RunManager.start_explore_node(battle_node_id):
		_fail("Could not start an accessible battle room for crisis configuration verification.")
		return
	var room_config := GameManager.consume_next_explore_room_config()
	if float(room_config.get("advanced_patrol_interval_mult", 0.0)) != 0.9 or int(room_config.get("advanced_patrol_enemy_cap_bonus", 0)) != 1 or float(Dictionary(room_config.get("advanced_crisis_enemy", {})).get("mixed_family_wave_chance", 0.0)) != 0.3:
		_fail("Advanced crisis exploration configuration was dropped before the room consumer.")
		return
	RunManager.save_run()
	RunManager.cancel_run()
	if not RunManager.load_saved_run() or RunManager.advanced_crisis_level != 10 or RunManager.get_active_rule_snapshot().get("advanced_crisis", {}).get("modifier_ids", []).size() != 10:
		_fail("Saved crisis snapshot did not restore exactly once.")
		return
	RunManager.clear_saved_run()
	RunManager.cancel_run()
	MetaProgressionState.load_dict(original_meta)
	print("Advanced crisis run integration check passed.")
	get_tree().quit(0)


func _find_accessible_battle_node() -> int:
	for node in RunManager.map_nodes:
		if String(node.get("type", "")) == RunManager.NODE_BATTLE and RunManager.is_node_accessible(int(node.get("id", -1))):
			return int(node.get("id", -1))
	return -1


func _fail(message: String) -> void:
	RunManager.clear_saved_run()
	RunManager.cancel_run()
	push_error(message)
	get_tree().quit(1)
