extends Node

const BossBudgetApplicator = preload("res://scripts/core/BossBudgetApplicator.gd")

class BossProbe extends Node:
	var max_hp: int = 1000
	var skill_cooldown: float = 2.0


func _ready() -> void:
	var original_meta := MetaProgressionState.to_dict()
	MetaProgressionState.clear_calibration_selection()
	MetaProgressionState.unlock_crisis(5)
	MetaProgressionState.select_crisis(5)
	RunManager.start_new_run()
	var budget := RunManager.get_formal_boss_budget("星间巨构")
	if int(budget.get("ehp", 0)) != 6776 or int(budget.get("phase_count", 0)) != 4:
		_fail("Formal Boss budget did not apply crisis 5 EHP and phase modifiers exactly once.")
		return
	if float(budget.get("phase_enrage_threshold", 0.0)) != 0.6 or int(budget.get("phase_enrage_count", 0)) != 1:
		_fail("Crisis 5 Boss budget omitted its 60%-HP phase rule.")
		return
	if int(budget.get("heavy_damage", 99)) > 40:
		_fail("Crisis Boss budget exceeded the heavy-hit damage cap.")
		return
	var probe := BossProbe.new()
	add_child(probe)
	BossBudgetApplicator.apply_to(probe, "colossus")
	if BossBudgetApplicator.apply_damage_phase_modifier(probe, int(probe.max_hp * 0.61)):
		_fail("Boss phase rule triggered before crossing the 60%-HP threshold.")
		return
	if not BossBudgetApplicator.apply_damage_phase_modifier(probe, int(probe.max_hp * 0.60)) or not is_equal_approx(probe.skill_cooldown, 1.7):
		_fail("Boss phase rule did not shorten future skill cycles exactly once at 60% HP.")
		return
	if BossBudgetApplicator.apply_damage_phase_modifier(probe, int(probe.max_hp * 0.4)) or not is_equal_approx(probe.skill_cooldown, 1.7):
		_fail("Boss phase rule applied more than once.")
		return
	RunManager.cancel_run()
	MetaProgressionState.unlock_crisis(9)
	MetaProgressionState.select_crisis(9)
	RunManager.start_new_run()
	var deep_probe := BossProbe.new()
	add_child(deep_probe)
	var deep_budget := BossBudgetApplicator.apply_to(deep_probe, "colossus")
	if int(deep_budget.get("family_variant_count", 0)) != 1 or not is_equal_approx(deep_probe.skill_cooldown, 1.8):
		_fail("Crisis 9 Boss cooldown variant did not reach the formal Boss runtime.")
		return
	MetaProgressionState.load_dict(original_meta)
	RunManager.cancel_run()
	print("Advanced crisis boss budget check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	RunManager.cancel_run()
	push_error(message)
	get_tree().quit(1)
