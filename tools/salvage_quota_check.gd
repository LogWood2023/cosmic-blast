extends Node

const SalvageQuotaController := preload("res://scripts/gameplay/explore/SalvageQuotaController.gd")

func _ready() -> void:
	var quota := SalvageQuotaController.new()
	add_child(quota)
	quota.register_value(100)
	quota.collect_value(50)
	if quota.evacuation_is_unlocked or not quota.should_show_evacuation_guidance():
		_fail("Guidance must precede evacuation unlock.")
		return
	quota.collect_value(15)
	if not quota.evacuation_is_unlocked or not is_equal_approx(quota.get_progress_ratio(), 0.65):
		_fail("Evacuation must unlock at 65% salvage.")
		return
	print("Salvage quota check passed.")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
