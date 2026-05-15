extends "res://scripts/BossBase.gd"
## 星间巨构手臂 —— 呼吸晃动动画

const SIDE_LEFT: int = 0
const SIDE_RIGHT: int = 1
@export var side: int = SIDE_LEFT

var origin_pos: Vector2
var sway_phase: float = 0.0
var base_rotation: float = 0.0
var is_animating: bool = false              # 技能期间暂停晃动


func _ready() -> void:
	super()
	origin_pos = position
	base_rotation = rotation


func _process(delta: float) -> void:
	if is_animating:
		return
	sway_phase += delta * 2.5
	rotation = base_rotation + sin(sway_phase) * 0.04
