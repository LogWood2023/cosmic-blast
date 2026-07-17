extends Node

const STAR_COLOSSUS_SCENE := preload("res://scenes/entities/bosses/StarColossus.tscn")


func _ready() -> void:
	var original_meta := MetaProgressionState.to_dict()
	MetaProgressionState.clear_calibration_selection()
	MetaProgressionState.unlock_crisis(5)
	MetaProgressionState.select_crisis(5)
	RunManager.start_new_run()
	if not await _verify_colossus_runtime(1.0, 1.7, "crisis 5"):
		MetaProgressionState.load_dict(original_meta)
		return
	RunManager.cancel_run()
	MetaProgressionState.unlock_crisis(9)
	MetaProgressionState.select_crisis(9)
	RunManager.start_new_run()
	if not await _verify_colossus_runtime(0.9, 1.53, "crisis 9"):
		MetaProgressionState.load_dict(original_meta)
		return
	RunManager.cancel_run()
	MetaProgressionState.load_dict(original_meta)
	print("Advanced crisis Boss runtime check passed.")
	get_tree().quit(0)


func _verify_colossus_runtime(base_cooldown_mult: float, enrage_cooldown: float, label: String) -> bool:
	var boss := STAR_COLOSSUS_SCENE.instantiate()
	add_child(boss)
	await get_tree().process_frame
	var expected_budget := RunManager.get_formal_boss_budget("星间巨构")
	if int(boss.get("max_hp")) != int(expected_budget.get("ehp", 0)):
		return _fail("%s did not apply the formal Boss EHP to the live controller." % label)
	if not is_equal_approx(float(boss.get("skill_cooldown")), 2.0 * base_cooldown_mult):
		return _fail("%s did not apply the Boss cooldown multiplier to the live controller." % label)
	boss.set("entering", false)
	boss.call("apply_damage", int(ceil(float(boss.get("max_hp")) * 0.41)))
	if not bool(boss.get_meta(&"formal_boss_enrage_applied", false)):
		return _fail("%s did not trigger its live 60%%-HP phase modifier." % label)
	if not is_equal_approx(float(boss.get("skill_cooldown")), enrage_cooldown):
		return _fail("%s live Boss cooldown did not include the one-time phase modifier." % label)
	boss.queue_free()
	await get_tree().process_frame
	return true


func _fail(message: String) -> bool:
	RunManager.cancel_run()
	push_error(message)
	get_tree().quit(1)
	return false
