extends Node2D
## 爆炸增强层：初始亮闪核心 + 扩张冲击环（加色混合）。
## 由 Explosion.gd 在 _ready 中按爆炸尺寸生成，独立自毁——一处增强惠及所有爆炸调用点。
## 单节点、单 _process、单 _draw（draw_arc + draw_circle），开销低。

const LIFE := 0.28

var max_radius: float = 80.0

var _t: float = 0.0


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var p := clampf(_t / LIFE, 0.0, 1.0)
	# 冲击环：先快后慢扩张，透明度与线宽随时间衰减
	var r := max_radius * ease(p, 0.35)
	var ring_a := (1.0 - p) * 0.9
	var width := maxf(1.5, max_radius * 0.05 * (1.0 - p))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 0.55, 0.2, ring_a), width, true)
	# 初始核心亮闪：前 40% 快速膨胀并淡出
	if p < 0.4:
		var cp := p / 0.4
		var core_r := max_radius * (0.28 + 0.22 * cp)
		draw_circle(Vector2.ZERO, core_r, Color(1.0, 0.96, 0.82, (1.0 - cp) * 0.85))
