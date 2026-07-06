extends Node2D

const DANGER_RED := Color("#ff4f6a")
const VOID_VIOLET := Color("#b78cff")
const COMMAND_CYAN := Color("#52e8ff")

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
	draw_arc(Vector2.ZERO, radius + 3.0, -PI * 0.5, PI * 1.5, 96, Color(0.0, 0.0, 0.0, 0.52), width + 4.0, true)
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, PI * 1.5, 96, Color(VOID_VIOLET.r, VOID_VIOLET.g, VOID_VIOLET.b, 0.28), width, true)
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 96, Color(DANGER_RED.r, DANGER_RED.g, DANGER_RED.b, 0.96), width, true)
	draw_arc(Vector2.ZERO, radius + 7.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 96, Color(COMMAND_CYAN.r, COMMAND_CYAN.g, COMMAND_CYAN.b, 0.34), 2.0, true)
