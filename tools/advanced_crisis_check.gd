extends Node
const AdvancedCrisisResolver := preload("res://scripts/core/AdvancedCrisisResolver.gd")
func _ready() -> void:
	var resolver := AdvancedCrisisResolver.new()
	var zero: Dictionary = resolver.resolve(0)
	var ten: Dictionary = resolver.resolve(10)
	if not zero.get("modifier_ids", []).is_empty() or ten.get("modifier_ids", []).size() != 10:
		_fail("Crisis modifiers must be cumulative and unique.")
		return
	var economy: Dictionary = ten.economy
	var exploration: Dictionary = ten.exploration
	var enemy: Dictionary = ten.enemy
	var boss: Dictionary = ten.boss
	if float(economy.get("shop_price_mult", 0.0)) != 1.1 or int(economy.get("reroll_base_bonus", -1)) != 10:
		_fail("Economy crisis modifiers were not resolved.")
		return
	if float(exploration.get("patrol_interval_mult", 0.0)) != 0.9 or int(exploration.get("patrol_enemy_cap_bonus", -1)) != 1:
		_fail("Exploration crisis modifiers were not resolved.")
		return
	if float(enemy.get("elite_ehp_mult", 0.0)) != 1.1 or float(boss.get("ehp_mult", 0.0)) != 1.1 or float(ten.get("enemy_damage_mult", 2.0)) != 1.0:
		_fail("Combat crisis modifiers must remain in their bounded domains.")
		return
	print("Advanced crisis check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
