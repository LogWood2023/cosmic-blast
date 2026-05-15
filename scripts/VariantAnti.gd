extends "res://scripts/WarpedCoreController.gd"
## 反物质核 —— 扭曲星核亚种3
## 负片效果，扭曲混乱
## 技能：6(连续冲刺), 2(轨道扩张), 3(咆哮+召唤敌机), 4(强吸力咆哮), 5(十字激光连射)
## HP:1000, 技能冷却:1s

func _ready() -> void:
	boss_name = "反物质核"
	max_hp = 1000
	has_skill_1 = false
	has_skill_2 = true
	has_skill_3 = true
	has_skill_4 = true
	has_skill_5 = true
	has_skill_6 = true
	skill_cooldown = 1.0
	super._ready()
	boss_hp = max_hp
