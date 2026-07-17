extends Node

const DesignedEnemy := preload("res://scripts/entities/designed_enemies/DesignedEnemy.gd")


func _ready() -> void:
	var enemy := DesignedEnemy.new()
	enemy.behavior = 3 # first family elite
	enemy.apply_budgeted_profile(3, {"elite_ehp_mult": 1.1, "elite_family_affix_count": 1})
	if enemy.hp != 22440 or enemy.max_hp != 22440 or enemy.damage > 40:
		enemy.free()
		_fail("Advanced crisis elite budget was not applied to the spawned enemy.")
		return
	var profile: Dictionary = enemy.get_meta(&"budgeted_enemy_profile", {})
	enemy.free()
	if int(profile.get("family_affix_count", 0)) != 1:
		_fail("Advanced crisis elite affix metadata was lost during spawn setup.")
		return
	print("Advanced crisis enemy spawn check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
