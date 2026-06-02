extends Node2D

var progress: float = 0.0
var radius: float = 42.0
var width: float = 8.0


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	visible = progress > 0.0
	queue_redraw()


func _draw() -> void:
	if progress <= 0.0:
		return
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, PI * 1.5, 96, Color(0.0, 0.0, 0.0, 0.32), width, true)
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 96, Color(0.0, 0.0, 0.0, 0.92), width, true)
