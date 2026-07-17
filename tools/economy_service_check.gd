extends Node
const EconomyService := preload("res://scripts/core/EconomyService.gd")
func _ready() -> void:
	var economy := EconomyService.new()
	if economy.get_salvage_income(1, 0.7) < 55 or economy.get_salvage_income(3, 0.7) > 170:
		push_error("Salvage stage income is outside budget.")
		get_tree().quit(1)
		return
	if economy.get_reroll_cost(0) != 28 or economy.get_reroll_cost(0, 1) != 0 or economy.get_reroll_cost(2, 0, 3, 10) != 86:
		push_error("Reroll cost formula is invalid.")
		get_tree().quit(1)
		return
	print("Economy service check passed.")
	get_tree().quit(0)
