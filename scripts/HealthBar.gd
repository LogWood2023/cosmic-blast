extends Node2D
## 血量条 —— 用 _draw() 绘制，漂浮在敌人上方
## 红色底条 + 受击时黄色闪烁段逐渐缩短

const BAR_WIDTH: float = 40.0
const BAR_HEIGHT: float = 5.0

var max_hp: int
var current_hp: int

# 黄色闪烁动画状态
var flash_hp: int = 0              # 受击前的 HP（用于计算黄色段宽度）
var flash_timer: float = 0.0       # 黄色段缩小的计时器
const FLASH_DURATION: float = 0.4  # 黄色段从出现到消失的秒数


func setup(p_max_hp: int) -> void:
	max_hp = p_max_hp
	current_hp = p_max_hp
	# 满血时不显示
	visible = false
	# 脱离父节点坐标系，使用世界坐标
	top_level = true


## 受击后调用，更新 HP 并触发黄色闪烁
func take_hit(new_hp: int) -> void:
	flash_hp = current_hp
	current_hp = new_hp
	flash_timer = 0.0
	visible = true                  # 第一次受击时显示
	queue_redraw()


func _process(delta: float) -> void:
	# 紧跟父节点（敌人）的世界坐标，始终保持在上方 40 像素
	global_position = get_parent().global_position + Vector2(0, -40)

	# 黄色段缩小动画
	if flash_timer < FLASH_DURATION:
		flash_timer += delta
		queue_redraw()

	# 始终水平显示
	global_rotation = 0


func _draw() -> void:
	var left: float = -BAR_WIDTH / 2.0

	# ── 背景（深灰半透明） ──
	draw_rect(Rect2(left, 0, BAR_WIDTH, BAR_HEIGHT),
		Color(0.15, 0.15, 0.15, 0.7))

	# ── 红色 HP 条（从左边开始，宽度 = 当前HP比例） ──
	var red_width: float = BAR_WIDTH * (float(current_hp) / float(max_hp))
	if red_width > 0:
		draw_rect(Rect2(left, 0, red_width, BAR_HEIGHT),
			Color(0.95, 0.2, 0.2, 1.0))

	# ── 黄色闪烁段（从红色条右端开始，向右延伸） ──
	if flash_timer < FLASH_DURATION:
		# 黄色段原始宽度（受击时丢失的 HP 比例 × 条宽）
		var loss: int = flash_hp - current_hp
		var original_flash_w: float = BAR_WIDTH * (float(loss) / float(max_hp))

		# 随 flash_timer 增大，黄色段从原始宽度缩到 0
		var progress: float = clampf(flash_timer / FLASH_DURATION, 0.0, 1.0)
		var current_flash_w: float = original_flash_w * (1.0 - progress)

		if current_flash_w > 0:
			var flash_x: float = left + red_width
			draw_rect(Rect2(flash_x, 0, current_flash_w, BAR_HEIGHT),
				Color(1.0, 0.85, 0.1, 0.9))
