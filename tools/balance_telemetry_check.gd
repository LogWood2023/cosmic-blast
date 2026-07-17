extends Node
const BalanceTelemetryScript := preload("res://scripts/core/BalanceTelemetry.gd")
func _ready() -> void:
	var telemetry := BalanceTelemetryScript.new()
	telemetry.record("ignored")
	if not telemetry.snapshot().is_empty():
		push_error("Disabled telemetry must not record.")
		get_tree().quit(1)
		return
	telemetry.enabled = true
	telemetry.record("mechanic", {"generation": 1})
	if telemetry.snapshot().size() != 1:
		push_error("Enabled telemetry must record.")
		get_tree().quit(1)
		return
	telemetry.record_mechanic_effect("aftershock", {"generation": 2, "damage": 12.5})
	telemetry.record_mechanic_effect("aftershock", {"generation": 3, "damage": 7.5})
	var stats := telemetry.get_mechanic_statistics()
	var aftershock: Dictionary = stats.get("aftershock", {})
	if int(aftershock.get("trigger_count", 0)) != 2 or float(aftershock.get("damage_contribution", 0.0)) != 20.0 or int(aftershock.get("max_generation", 0)) != 3:
		push_error("Mechanic telemetry aggregation failed.")
		get_tree().quit(1)
		return
	print("Balance telemetry check passed.")
	get_tree().quit(0)
