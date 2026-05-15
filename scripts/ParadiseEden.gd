extends "res://scripts/ParadiseController.gd"
## 伊甸园 —— 天堂号黑金亚种，技能 1/4/3/5/6，冷却 1s

func _init() -> void:
	boss_name = "伊甸园"
	max_hp = 1000
	skill_cooldown = 1.0
	has_skill_1 = true
	has_skill_2 = false
	has_skill_3 = true
	has_skill_4 = true
	has_skill_5 = false
	has_skill_6 = true
	body_tex = preload("res://assets/images/paradise/paradise_body_eden_cutout.png")
	cannon_tex = preload("res://assets/images/paradise/paradise_cannon_eden_cutout.png")
