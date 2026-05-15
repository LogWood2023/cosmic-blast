extends Node2D
## 技能3信号环绘制器

var rings: Array = []

func _draw() -> void:
	for r in rings:
		if r.elapsed < 0 or r.elapsed >= r.duration:
			continue
		var progress = r.elapsed / r.duration
		var radius = progress * r.max_r
		var alpha = 1.0 - abs(progress - 0.5) * 2.0
		var col = Color(1, 1 - progress * 0.7, 1 - progress * 0.9, alpha * 0.3)
		draw_circle(r.pos, radius, col, false, 15.0)
