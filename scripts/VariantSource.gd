extends "res://scripts/WarpedCoreController.gd"
## 异变源石 —— 扭曲星核亚种1
## 技能：1(停泊位转移), 2(轨道扩张), 3(咆哮+召唤敌机)
## HP:1000, 技能冷却:3s

func _ready() -> void:
	boss_name = "异变源石"
	max_hp = 1000
	has_skill_1 = true
	has_skill_2 = true
	has_skill_3 = true
	has_skill_4 = false
	has_skill_5 = false
	has_skill_6 = false
	skill_cooldown = 3.0
	super._ready()
	boss_hp = max_hp
