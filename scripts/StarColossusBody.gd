extends "res://scripts/BossBase.gd"
## 星间巨构身体 —— Sprite 层摇动，本体位置不受干扰

var sway_phase: float = 0.0
var is_animating: bool = false              # 技能期间暂停晃动


func _process(delta: float) -> void:
	if is_animating:
		return
	sway_phase += delta * 2.0
	rotation = sin(sway_phase) * 0.03
	if sprite:
		sprite.position.y = sin(sway_phase * 0.7) * 8
