extends "res://scripts/ParadiseController.gd"
## 桃源乡 —— 天堂号黑绿亚种，技能 1/2/3，冷却 3s

func _init() -> void:
	boss_name = "桃源乡"
	max_hp = 1000
	skill_cooldown = 3.0
	has_skill_1 = true
	has_skill_2 = true
	has_skill_3 = true
	has_skill_4 = false
	has_skill_5 = false
	has_skill_6 = false
	body_tex = preload("res://assets/images/paradise/paradise_body_peach_cutout.png")
	cannon_tex = preload("res://assets/images/paradise/paradise_cannon_peach_cutout.png")
