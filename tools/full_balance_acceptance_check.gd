extends Node
const Simulator := preload("res://tools/run_seed_simulator.gd")
const Report := preload("res://tools/balance_report.gd")
func _ready() -> void:
	var simulator := Simulator.new()
	var standard_runs := simulator.simulate_many(1000, "standard")
	var report: Dictionary = Report.new().summarize(standard_runs)
	var fixed_seed_failures: Array[int] = []
	for run in standard_runs:
		var loadout: PackedInt32Array = run.get("boss_loadout", PackedInt32Array())
		if int(run.get("event_count", 0)) < 6 or int(run.get("event_count", 0)) > 7 \
				or int(run.get("reward_count", 0)) != 2 \
				or int(run.get("beacon_count", 0)) < 2 or int(run.get("beacon_count", 0)) > 3 \
				or loadout.size() != 3 or loadout[0] < 3 or loadout[1] < 5 or loadout[2] < 8:
			fixed_seed_failures.append(int(run.get("seed", -1)))
	if not fixed_seed_failures.is_empty():
		_fail("Fixed-seed routing/economy regressions: %s" % fixed_seed_failures)
		return
	if float(report.p50) < 45.0 or float(report.p50) > 52.0 or float(report.p90) > 60.0:
		_fail("Run duration acceptance failed.")
		return
	if float(report.event_p50) < 6.0 or float(report.reward_p50) != 2.0 or float(report.beacon_p50) != 2.0:
		_fail("Map event/reward/beacon distribution acceptance failed.")
		return
	var loadouts: Array = report.boss_loadout_p25
	if float(loadouts[0]) < 3.0 or float(loadouts[1]) < 5.0 or float(loadouts[2]) < 8.0:
		_fail("Boss loadout progression acceptance failed.")
		return
	for scenario in Simulator.SCENARIOS:
		var scenario_runs := simulator.simulate_many(1000, scenario)
		if scenario_runs.is_empty():
			_fail("Scenario simulation failed: %s" % scenario)
			return
		var scenario_report: Dictionary = Report.new().summarize(scenario_runs)
		print("Balance scenario evidence: %s" % JSON.stringify({
			"scenario": scenario,
			"p25_minutes": scenario_report.p25,
			"p50_minutes": scenario_report.p50,
			"p75_minutes": scenario_report.p75,
			"p90_minutes": scenario_report.p90,
			"boss_loadout_p25": scenario_report.boss_loadout_p25,
			"pity_trigger_total": scenario_report.pity_trigger_total,
		}))
	print("Balance fixed-seed failures: %s" % JSON.stringify(fixed_seed_failures))
	print("Full balance acceptance check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
