extends Sprite2D
## 爆炸帧动画 —— 逐帧播放 spritesheet，配合淡出 + 缩放过冲 + 加色冲击环/亮闪

const FRAME_COUNT: int = 6
const FRAME_DURATION: float = 0.07       # 每帧持续秒数
const FRAME_WIDTH: float = 3388.0 / 6.0   # 每帧宽 ≈ 170.7px
const FRAME_HEIGHT: float = 2476.0

const FlashScript := preload("res://scripts/fx/ExplosionFlash.gd")

var _frame: int = 0
var _timer: float = 0.0


func _ready() -> void:
	region_enabled = true
	_update_region()

	# 同步淡出
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FRAME_COUNT * FRAME_DURATION)
	tween.tween_callback(queue_free)

	# 缩放冲击：略缩后过冲回落，强化爆发瞬间
	var target := scale
	scale = target * 0.55
	var punch := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	punch.tween_property(self, "scale", target, 0.14)

	# 加色冲击环 + 初始亮闪核心（尺寸随爆炸缩放），独立自毁
	var parent := get_parent()
	if parent:
		var flash := FlashScript.new()
		flash.max_radius = clampf(target.x * 320.0, 24.0, 900.0)
		flash.z_index = z_index
		parent.add_child(flash)
		flash.global_position = global_position


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= FRAME_DURATION:
		_timer -= FRAME_DURATION
		_frame += 1
		if _frame >= FRAME_COUNT:
			set_process(false)      # 播完 6 帧后停止，等淡出删除
			return
		_update_region()


func _update_region() -> void:
	region_rect = Rect2(_frame * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
