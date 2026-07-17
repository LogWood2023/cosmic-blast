class_name BalanceReport
extends RefCounted

func percentile(values: Array, percentile_value: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(round((sorted.size() - 1) * clampf(percentile_value, 0.0, 1.0))), 0, sorted.size() - 1)])


func summarize(runs: Array[Dictionary]) -> Dictionary:
	var durations: Array[float] = []
	var events: Array[float] = []
	var rewards: Array[float] = []
	var beacons: Array[float] = []
	var loadouts_by_boss: Array[Array] = [[], [], []]
	var pity_total := 0
	for run in runs:
		durations.append(float(run.get("duration_minutes", 0.0)))
		events.append(float(run.get("event_count", 0)))
		rewards.append(float(run.get("reward_count", 0)))
		beacons.append(float(run.get("beacon_count", 0)))
		var loadout: PackedInt32Array = run.get("boss_loadout", PackedInt32Array())
		for index in range(mini(loadout.size(), 3)):
			loadouts_by_boss[index].append(float(loadout[index]))
		for trigger_count in PackedInt32Array(run.get("pity_triggers", PackedInt32Array())):
			pity_total += trigger_count
	return {
		"run_count": runs.size(),
		"p25": percentile(durations, 0.25),
		"p50": percentile(durations, 0.50),
		"p75": percentile(durations, 0.75),
		"p90": percentile(durations, 0.90),
		"event_p50": percentile(events, 0.50),
		"reward_p50": percentile(rewards, 0.50),
		"beacon_p50": percentile(beacons, 0.50),
		"boss_loadout_p25": [percentile(loadouts_by_boss[0], 0.25), percentile(loadouts_by_boss[1], 0.25), percentile(loadouts_by_boss[2], 0.25)],
		"pity_trigger_total": pity_total,
	}
