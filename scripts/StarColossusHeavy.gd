extends "res://scripts/StarColossusController.gd"
## 星尘重兵 —— 银白亚种，技能 2/3/4/5，冷却 2s

func _init() -> void:
	boss_name = "星尘重兵"
	skill_cooldown = 2.0
	has_skill_1 = false
	has_skill_2 = true
	has_skill_3 = true
	has_skill_4 = true
	has_skill_5 = true
	has_skill_6 = false
	body_tex = preload("res://assets/images/boss/boss_frontier_body_final_cutout.png")
	arm_tex = preload("res://assets/images/boss/boss_frontier_arm_final_cutout.png")
	arm_r_tex = preload("res://assets/images/boss/boss_frontier_arm_final_cutout.png")
