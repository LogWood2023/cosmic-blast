class_name RunSeedSimulator
extends RefCounted
## Deterministic, side-effect-free acceptance model. It never instantiates or mutates RunManager.

const EconomyServiceScript := preload("res://scripts/core/EconomyService.gd")
const STAGE_NODE_COUNTS: Array[int] = [5, 7, 9]
const SCENARIOS: PackedStringArray = ["whiteboard", "standard", "single_family_highroll", "cross_family_highroll"]


func simulate(seed: int, scenario: String = "standard") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var node_counts := _make_node_counts(rng)
	var economy := EconomyServiceScript.new()
	var salvage_ratio := rng.randf_range(0.70, 0.80)
	var stage_income := PackedInt32Array([0, 0, 0])
	var equipment_targets := PackedInt32Array([0, 0, 0])
	var pity_triggers := PackedInt32Array([0, 0, 0])
	var total_minutes := 2.0 # transitions and route overhead
	var auxiliary_count := 0
	var dry_nodes := 0
	for stage_index in range(3):
		var stage := stage_index + 1
		var battle_count := int(node_counts.battle_by_stage[stage_index])
		var event_count := int(node_counts.event_by_stage[stage_index])
		var reward_count := int(node_counts.reward_by_stage[stage_index])
		var beacon_count := int(node_counts.beacon_by_stage[stage_index])
		for battle_index in range(battle_count):
			stage_income[stage_index] += economy.get_salvage_income(stage, salvage_ratio)
			total_minutes += rng.randf_range(3.0, 5.0)
			if rng.randf() < _equipment_roll_chance(stage, scenario):
				auxiliary_count += 1
				dry_nodes = 0
			else:
				dry_nodes += 1
		for event_index in range(event_count):
			stage_income[stage_index] += rng.randi_range(30 * stage, 45 * stage)
			total_minutes += rng.randf_range(20.0, 45.0) / 60.0
			if rng.randf() < _equipment_roll_chance(stage, scenario) * 0.75:
				auxiliary_count += 1
				dry_nodes = 0
			else:
				dry_nodes += 1
		for reward_index in range(reward_count):
			stage_income[stage_index] += rng.randi_range(55 * stage, 75 * stage)
			total_minutes += rng.randf_range(20.0, 40.0) / 60.0
			auxiliary_count += 1
			dry_nodes = 0
		for beacon_index in range(beacon_count):
			total_minutes += rng.randf_range(20.0, 45.0) / 60.0
		# Three-node dry streak protection is consumed by the next reward-equivalent acquisition.
		if dry_nodes >= 3:
			auxiliary_count += 1
			pity_triggers[stage_index] += 1
			dry_nodes = 0
		var target: int = [3, 5, 8][stage_index]
		if auxiliary_count < target:
			auxiliary_count = target
			pity_triggers[stage_index] += 1
		equipment_targets[stage_index] = auxiliary_count
		total_minutes += _boss_minutes(stage, scenario)
		# Two shop visits per run, 30–90 seconds each, distributed through progression.
		if stage_index < 2:
			total_minutes += rng.randf_range(0.5, 1.5)
	return {
		"seed": seed,
		"scenario": scenario,
		"duration_minutes": total_minutes,
		"event_count": int(node_counts.event_total),
		"reward_count": int(node_counts.reward_total),
		"beacon_count": int(node_counts.beacon_total),
		"battle_count": int(node_counts.battle_total),
		"boss_loadout": equipment_targets,
		"salvage_ratio": salvage_ratio,
		"stage_income": stage_income,
		"pity_triggers": pity_triggers,
		"node_counts": node_counts,
	}


func simulate_many(count: int, scenario: String = "standard") -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for seed in range(maxi(0, count)):
		results.append(simulate(seed, scenario))
	return results


func _make_node_counts(rng: RandomNumberGenerator) -> Dictionary:
	var battles := rng.randi_range(8, 9)
	var events := rng.randi_range(6, 7)
	var rewards := 2
	var beacons := 2 + (1 if rng.randf() < 0.20 else 0)
	var battle_by_stage := _distribute(battles, STAGE_NODE_COUNTS, rng)
	var event_by_stage := _distribute(events, STAGE_NODE_COUNTS, rng)
	var reward_by_stage := _distribute(rewards, STAGE_NODE_COUNTS, rng)
	var beacon_by_stage := _distribute(beacons, STAGE_NODE_COUNTS, rng)
	return {
		"battle_total": battles,
		"event_total": events,
		"reward_total": rewards,
		"beacon_total": beacons,
		"battle_by_stage": battle_by_stage,
		"event_by_stage": event_by_stage,
		"reward_by_stage": reward_by_stage,
		"beacon_by_stage": beacon_by_stage,
	}


func _distribute(total: int, weights: Array[int], rng: RandomNumberGenerator) -> PackedInt32Array:
	var result := PackedInt32Array([0, 0, 0])
	var remaining := total
	while remaining > 0:
		var roll := rng.randi_range(0, weights[0] + weights[1] + weights[2] - 1)
		var index := 0 if roll < weights[0] else (1 if roll < weights[0] + weights[1] else 2)
		result[index] += 1
		remaining -= 1
	return result


func _equipment_roll_chance(stage: int, scenario: String) -> float:
	var base := 0.24 + float(stage - 1) * 0.05
	match scenario:
		"whiteboard": return 0.0
		"single_family_highroll": return base + 0.22
		"cross_family_highroll": return base + 0.28
	return base


func _boss_minutes(stage: int, scenario: String) -> float:
	var normal: float = [82.0, 106.0, 126.0][stage - 1] / 60.0
	match scenario:
		"whiteboard": return normal * 1.3
		"single_family_highroll": return normal * 0.48
		"cross_family_highroll": return normal * 0.36
	return normal
