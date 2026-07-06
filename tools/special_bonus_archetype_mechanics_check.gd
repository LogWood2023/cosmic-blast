extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var before := RunManager.get_player_stats()
	RunManager.active_special_bonus_ids = [
		"colossus_charge_beacon",
		"paradise_fire_beacon",
		"warped_gravity_beacon",
		"hell_eye_frenzy_beacon",
		"divine_drone_beacon",
	]
	var after := RunManager.get_player_stats()
	_expect_float_gt(after, before, "dash_aftershock_radius", "Colossus beacon should strengthen dash aftershock.")
	_expect_float_gt(after, before, "dash_aftershock_damage_mult", "Colossus beacon should strengthen aftershock damage.")
	_expect_int_gt(after, before, "bullet_split_count", "Paradise beacon should add split projectile coverage.")
	_expect_float_gt(after, before, "gravity_pull_strength", "Warped beacon should add projectile gravity pull.")
	_expect_float_gt(after, before, "frenzy_damage_mult", "Hell-eye beacon should increase frenzy outgoing damage.")
	_expect_float_lt(after, before, "drone_fire_interval_mult", "Divine beacon should speed up support drones.")
	_expect_float_gt(after, before, "drone_damage_mult", "Divine beacon should strengthen support drone fire.")
	if _failed:
		return

	var summaries: Array = RunManager.get_active_special_bonus_summaries()
	var joined := ""
	for raw_summary in summaries:
		joined += String(Dictionary(raw_summary).get("effects_text", "")) + "\n"
	for expected in ["余震", "分裂弹", "引力牵引", "狂热火力", "僚机射速"]:
		if not joined.contains(expected):
			_fail("Special bonus summaries should mention %s. Got: %s" % [expected, joined])
			return

	print("Special bonus archetype mechanics check passed.")
	get_tree().quit(0)


func _expect_float_gt(after: Dictionary, before: Dictionary, key: String, message: String) -> void:
	if float(after.get(key, 0.0)) <= float(before.get(key, 0.0)):
		_fail("%s before=%s after=%s" % [message, str(before.get(key, null)), str(after.get(key, null))])


func _expect_float_lt(after: Dictionary, before: Dictionary, key: String, message: String) -> void:
	var before_value := float(before.get(key, 1.0))
	if before_value == 0.0:
		before_value = 1.0
	if float(after.get(key, 1.0)) >= before_value:
		_fail("%s before=%s after=%s" % [message, str(before.get(key, null)), str(after.get(key, null))])


func _expect_int_gt(after: Dictionary, before: Dictionary, key: String, message: String) -> void:
	if int(after.get(key, 0)) <= int(before.get(key, 0)):
		_fail("%s before=%s after=%s" % [message, str(before.get(key, null)), str(after.get(key, null))])


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
