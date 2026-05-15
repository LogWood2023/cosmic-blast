extends "res://scripts/HellEyeController.gd"
class_name HellEyeGate
## 典狱长 —— 地狱之眼亚种3
## 使用地狱之眼的原版材质
## 技能：5(强化激光), 2(瞪眼收缩环), 3(闭眼传送), 4(红幕扭曲), 6(分身)
## HP:1000, 技能冷却:1s

const GATE_BGM = preload("res://assets/audio/hell_eye_boss_bgm_2.mp3")

func _ready() -> void:
	boss_name = "典狱长"
	mask_rotation_deg = randf_range(0.0, 360.0)
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
	bgm_player.stream = GATE_BGM
