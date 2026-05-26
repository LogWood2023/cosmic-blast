extends Sprite2D
## 碎片 —— 随机方向飞出，旋转 + 淡出，超出屏幕销毁

var velocity: Vector2
var rotation_speed: float


func _ready() -> void:
	# 淡出动画：1 秒内透明度降到 0，然后销毁
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	position += velocity * delta
	rotation += rotation_speed * delta

	# 超出屏幕销毁
	var screen: Vector2 = get_viewport().get_visible_rect().size
	if position.x < -100 or position.x > screen.x + 100 \
	or position.y < -100 or position.y > screen.y + 100:
		queue_free()
