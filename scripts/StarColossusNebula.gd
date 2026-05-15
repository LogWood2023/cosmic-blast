extends "res://scripts/StarColossusController.gd"
## 星云巨构 —— 银白材质，技能 2/3/4/5/6，冷却 1s

func _init() -> void:
	boss_name = "星云巨构"
	skill_cooldown = 1.0
	has_skill_1 = false
	has_skill_2 = true
	has_skill_3 = true
	has_skill_4 = true
	has_skill_5 = true
	has_skill_6 = true
	body_tex = preload("res://assets/images/boss/boss_heavy_body_final_cutout.png")
	arm_tex = preload("res://assets/images/boss/boss_heavy_arm_final_cutout.png")
	arm_r_tex = preload("res://assets/images/boss/boss_heavy_arm_final_cutout.png")
