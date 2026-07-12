extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var summaries: Array = RunManager.get_route_directive_summaries()
	if summaries.size() != RunManager.ROUTE_DIRECTIVE_COUNT:
		_fail("Each run should start with three elite directives, got %d." % summaries.size())
		return
	var seen_behaviors := {}
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		for key in ["directive_id", "target_behavior", "target_name", "family_name", "description", "reward_minerals"]:
			if not summary.has(key):
				_fail("Elite directive summary is missing %s: %s" % [key, str(summary)])
				return
		var behavior := int(summary.get("target_behavior", -1))
		if not RunManager.ROUTE_DIRECTIVE_ELITE_BEHAVIORS.has(behavior):
			_fail("Directive should only target an elite enemy: %s" % str(summary))
			return
		if seen_behaviors.has(behavior):
			_fail("Active directives should not duplicate the same elite target.")
			return
		seen_behaviors[behavior] = true
		if int(summary.get("reward_minerals", 0)) <= 0:
			_fail("Elite directive should grant star marrow only: %s" % str(summary))
			return
	var completed_directive := Dictionary(summaries[0])
	var minerals_before := RunManager.minerals
	var result := RunManager.record_route_directive_elite_kill(int(completed_directive.get("target_behavior", -1)))
	if Array(result.get("completed", [])).size() != 1:
		_fail("Killing the targeted elite should complete exactly one directive: %s" % str(result))
		return
	if RunManager.minerals != minerals_before + int(completed_directive.get("reward_minerals", 0)):
		_fail("Directive should grant only its star marrow reward: %s" % str(result))
		return
	var active_after: Array = RunManager.get_route_directive_summaries()
	if active_after.size() != RunManager.ROUTE_DIRECTIVE_COUNT:
		_fail("Completing a directive should immediately refill the board: %s" % str(active_after))
		return
	for raw_summary in active_after:
		if String(Dictionary(raw_summary).get("directive_id", "")) == String(completed_directive.get("directive_id", "")):
			_fail("Completed directive should be replaced immediately.")
			return
	print("Route directive check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
