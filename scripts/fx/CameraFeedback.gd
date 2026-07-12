extends Node
## 全局镜头反馈单例（autoload：CameraFeedback）—— trauma 衰减震屏。
## 震屏只写激活 Camera2D 的 offset：重力爪/扭曲闪电/地狱之眼三套镜头聚焦系统
## 只操作 position/zoom，与本单例正交；个别 Boss 直写 offset 的地震时刻按帧后写者赢。
##
## 注：早期版本用 Engine.time_scale 做受击/击杀顿帧。但本作是高频挨弹的弹幕游戏，
## 每次受伤/击杀都全局慢放 30~50ms 会让画面持续卡顿、并拖慢输入响应（已由玩家反馈证实），
## 故移除顿帧机制，只保留不冻结输入的镜头震动 + 受击闪白作为打击反馈。

const TRAUMA_DECAY := 2.6                # trauma 每秒线性衰减
const MAX_OFFSET := Vector2(26.0, 18.0)  # trauma=1 时的最大偏移

var _trauma: float = 0.0
var intensity_scale: float = 1.0
var _shaking_cam: Camera2D               # 上一帧被写过 offset 的相机，结束时归零
# headless 自检环境无渲染、无激活相机，震动无意义，直接跳过
@onready var _disabled: bool = DisplayServer.get_name() == "headless"


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(0.0, _trauma - TRAUMA_DECAY * delta)
	var cam := get_viewport().get_camera_2d()
	if _shaking_cam != null and (cam != _shaking_cam or _trauma <= 0.0):
		if is_instance_valid(_shaking_cam):
			_shaking_cam.offset = Vector2.ZERO
		_shaking_cam = null
	if cam == null:
		return
	if _trauma <= 0.0:
		return
	var amount := _trauma * _trauma * intensity_scale
	cam.offset = Vector2(
		randf_range(-1.0, 1.0) * MAX_OFFSET.x * amount,
		randf_range(-1.0, 1.0) * MAX_OFFSET.y * amount
	)
	_shaking_cam = cam


func add_trauma(amount: float) -> void:
	if _disabled:
		return
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


## 击杀反馈：轻震（GameManager.on_enemy_killed 统一入口调用）
func enemy_kill_feedback() -> void:
	add_trauma(0.12)


## 玩家受伤反馈：中震（Player 三个受击入口调用）
func player_hurt_feedback() -> void:
	add_trauma(0.35)
