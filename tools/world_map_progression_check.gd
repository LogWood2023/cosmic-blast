extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_node_progression_metadata()
	if _failed:
		return
	_check_reward_multiplier_affects_minerals()
	if _failed:
		return
	_check_equipment_drop_chance_scales()
	if _failed:
		return
	print("World map progression check passed.")
	get_tree().quit(0)


func _check_node_progression_metadata() -> void:
	var tier_counts := {}
	var tier_reward_mults := {}
	var tier_risks := {}
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		if node_id <= 0 or node_type == RunManager.NODE_SPECIAL:
			continue
		var tier := int(node.get("tier", 0))
		var risk := int(node.get("risk_level", 0))
		var reward_mult := float(node.get("reward_mult", 0.0))
		if tier < 1 or risk < 1 or reward_mult <= 0.0:
			_fail("Exploration node %d should carry tier/risk/reward metadata." % node_id)
			return
		tier_counts[tier] = int(tier_counts.get(tier, 0)) + 1
		tier_reward_mults[tier] = maxf(float(tier_reward_mults.get(tier, 0.0)), reward_mult)
		tier_risks[tier] = maxi(int(tier_risks.get(tier, 0)), risk)
	for tier in [1, 2, 3]:
		if int(tier_counts.get(tier, 0)) <= 0:
			_fail("World map should contain tier %d exploration nodes." % tier)
			return
	if float(tier_reward_mults.get(3, 0.0)) <= float(tier_reward_mults.get(1, 0.0)):
		_fail("Outer tier reward multiplier should exceed inner tier.")
		return
	if int(tier_risks.get(3, 0)) <= int(tier_risks.get(1, 0)):
		_fail("Outer tier risk should exceed inner tier.")
		return


func _check_reward_multiplier_affects_minerals() -> void:
	var tier1_minerals := _collect_and_commit_fixed_minerals_for_tier(1, 100)
	var tier3_minerals := _collect_and_commit_fixed_minerals_for_tier(3, 100)
	if tier3_minerals <= tier1_minerals:
		_fail("Tier 3 minerals should commit more than tier 1, tier1=%d tier3=%d." % [tier1_minerals, tier3_minerals])
		return


func _check_equipment_drop_chance_scales() -> void:
	var tier1_id := _first_node_for_tier(1)
	var tier3_id := _first_node_for_tier(3)
	var tier1_chance: float = RunManager.get_node_equipment_drop_chance(tier1_id)
	var tier3_chance: float = RunManager.get_node_equipment_drop_chance(tier3_id)
	if tier3_chance <= tier1_chance:
		_fail("Tier 3 equipment drop chance should exceed tier 1, tier1=%.2f tier3=%.2f." % [tier1_chance, tier3_chance])
		return
	if tier1_chance < 0.2 or tier3_chance > 0.85:
		_fail("Equipment drop chances should stay in a readable design range.")
		return


func _collect_and_commit_fixed_minerals_for_tier(tier: int, amount: int) -> int:
	RunManager.start_new_run()
	GameManager.set_next_explore_room_config({})
	var node_id := _first_node_for_tier(tier)
	var node := RunManager.get_map_node(node_id)
	if node.is_empty():
		return 0
	RunManager.current_node_id = node_id
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	RunManager.record_mineral_collected(amount)
	var result := RunManager.complete_explore_room_success()
	return int(result.get("minerals_committed", 0))


func _first_node_for_tier(tier: int) -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id > 0 and String(node.get("type", "")) != RunManager.NODE_SPECIAL and int(node.get("tier", 0)) == tier:
			return node_id
	return -1


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
