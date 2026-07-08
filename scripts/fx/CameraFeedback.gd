extends Node
## 全局镜头反馈单例（autoload：CameraFeedback）—— trauma 衰减震屏 + hitstop。
## 震屏只写激活 Camera2D 的 offset：重力爪/扭曲闪电/地狱之眼三套镜头聚焦系统
## 只操作 position/zoom，与本单例正交；个别 Boss 直写 offset 的地震时刻按帧后写者赢。
## hitstop 用 Engine.time_scale（全项目无其它使用方），定时器走真实时间不受缩放影响。

const TRAUMA_DECAY := 2.6                # trauma 每秒线性衰减
const MAX_OFFSET := Vector2(26.0, 18.0)  # trauma=1 时的最大偏移
const KILL_HITSTOP_GATE_MSEC := 150      # 连杀顿帧限流，防高射速下持续卡顿感

var _trauma: float = 0.0
var _shaking_cam: Camera2D               # 上一帧被写过 offset 的相机，结束时归零
var _hitstop_until_msec: int = 0
var _kill_gate_msec: int = 0
# headless 自检环境无渲染，且 time_scale 会干扰按时间断言的测试，整体禁用
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
	var amount := _trauma * _trauma
	cam.offset = Vector2(
		randf_range(-1.0, 1.0) * MAX_OFFSET.x * amount,
		randf_range(-1.0, 1.0) * MAX_OFFSET.y * amount
	)
	_shaking_cam = cam


func add_trauma(amount: float) -> void:
	if _disabled:
		return
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func hitstop(duration: float = 0.04, slow_scale: float = 0.05) -> void:
	if _disabled:
		return
	var until := Time.get_ticks_msec() + int(duration * 1000.0)
	if until <= _hitstop_until_msec:
		return
	_hitstop_until_msec = until
	Engine.time_scale = slow_scale
	get_tree().create_timer(duration, true, false, true).timeout.connect(_end_hitstop)


func _end_hitstop() -> void:
	if Time.get_ticks_msec() >= _hitstop_until_msec:
		Engine.time_scale = 1.0


## 击杀反馈：轻震 + 限流顿帧（GameManager.on_enemy_killed 统一入口调用）
func enemy_kill_feedback() -> void:
	add_trauma(0.12)
	var now := Time.get_ticks_msec()
	if now < _kill_gate_msec:
		return
	_kill_gate_msec = now + KILL_HITSTOP_GATE_MSEC
	hitstop(0.03)


## 玩家受伤反馈：中震 + 明显顿帧（Player 三个受击入口调用）
func player_hurt_feedback() -> void:
	add_trauma(0.4)
	hitstop(0.05)
