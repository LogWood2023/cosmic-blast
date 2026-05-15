extends "res://scripts/StarColossusController.gd"
## 星海前锋 —— 蓝黑亚种，技能 1/2/3，冷却 3s

func _init() -> void:
	boss_name = "星海前锋"
	skill_cooldown = 3.0
	has_skill_1 = true
	has_skill_2 = true
	has_skill_3 = true
	has_skill_4 = false
	has_skill_5 = false
	has_skill_6 = false
	body_tex = preload("res://assets/images/boss/boss_colossus_body_cutout.png")
	arm_tex = preload("res://assets/images/boss/boss_colossus_arm_cutout.png")
	arm_r_tex = preload("res://assets/images/boss/boss_colossus_arm_r_cutout.png")
