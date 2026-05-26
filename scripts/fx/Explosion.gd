extends Sprite2D
## 爆炸帧动画 —— 逐帧播放 spritesheet，配合淡出

const FRAME_COUNT: int = 6
const FRAME_DURATION: float = 0.07       # 每帧持续秒数
const FRAME_WIDTH: float = 3388.0 / 6.0   # 每帧宽 ≈ 170.7px
const FRAME_HEIGHT: float = 2476.0

var _frame: int = 0
var _timer: float = 0.0


func _ready() -> void:
	region_enabled = true
	_update_region()

	# 同步淡出
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FRAME_COUNT * FRAME_DURATION)
	tween.tween_callback(queue_free)


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
