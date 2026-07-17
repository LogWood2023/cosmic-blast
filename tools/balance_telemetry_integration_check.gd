extends Node

const BalanceTelemetry := preload("res://scripts/core/BalanceTelemetry.gd")
const RunMutationSet := preload("res://scripts/core/run_content/RunMutationSet.gd")

const TEST_PATH := "user://balance_telemetry_integration_check.jsonl"


func _ready() -> void:
	_remove_test_files()
	var telemetry := BalanceTelemetry.new()
	telemetry.enabled = true
	telemetry.output_path = TEST_PATH
	RunManager.balance_telemetry = telemetry
	MetaProgressionState.unlock_crisis(2)
	MetaProgressionState.select_crisis(2)
	RunManager.start_new_run()
	var mutation := RunMutationSet.create("telemetry-check", "acceptance", -1, RunManager.content_state_version)
	mutation.add_action(&"grant_minerals", {"amount": 7})
	var result := RunManager.commit_mutation(mutation)
	if not bool(result.get("ok", false)):
		_fail("Telemetry integration mutation was rejected.")
		return
	RunManager.finish_run(false)
	var events := _read_events(TEST_PATH)
	if events.size() != 3:
		_fail("Expected start, mutation, and finish telemetry events.")
		return
	if String(events[0].get("event", "")) != "run_started" or String(events[1].get("event", "")) != "mutation_committed" or String(events[2].get("event", "")) != "run_finished":
		_fail("Telemetry event sequence was incorrect.")
		return
	if int(Dictionary(events[0].get("payload", {})).get("advanced_crisis_level", -1)) != 2:
		_fail("Selected crisis level was not injected into the run telemetry.")
		return
	telemetry.max_output_bytes = 1
	telemetry.record("rotation_probe")
	if telemetry.flush() != OK or not FileAccess.file_exists("%s.1" % TEST_PATH):
		_fail("Telemetry log rotation failed.")
		return
	_remove_test_files()
	RunManager.cancel_run()
	print("Balance telemetry integration check passed.")
	get_tree().quit(0)


func _read_events(path: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)
	var events: Array[Dictionary] = []
	if file == null:
		return events
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parsed = JSON.parse_string(line)
		if parsed is Dictionary:
			events.append(parsed)
	file.close()
	return events


func _remove_test_files() -> void:
	for path in [TEST_PATH, "%s.1" % TEST_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(message: String) -> void:
	_remove_test_files()
	RunManager.cancel_run()
	push_error(message)
	get_tree().quit(1)
