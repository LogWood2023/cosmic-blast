extends Control
## Persistent top-bar warning tape for an active crisis threshold.

const TAPE_STRIDE: float = 88.0
const TAPE_WIDTH: float = 34.0
const TAPE_SPEED: float = 172.0
var _alert_active: bool = false
var _tape_offset: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	if not _alert_active:
		return
	_tape_offset = fposmod(_tape_offset + TAPE_SPEED * delta, TAPE_STRIDE)
	queue_redraw()


func set_alert_active(is_active: bool) -> void:
	if _alert_active == is_active:
		return
	_alert_active = is_active
	visible = is_active
	set_process(is_active)
	if is_active:
		_tape_offset = 0.0
	queue_redraw()


func _draw() -> void:
	if not _alert_active:
		return
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.23, 0.006, 0.018, 0.9))
	var stripe_x: float = -size.y - TAPE_WIDTH + _tape_offset - TAPE_STRIDE
	var stripe_end: float = size.x + TAPE_STRIDE
	while stripe_x < stripe_end:
		var stripe: PackedVector2Array = PackedVector2Array([
			Vector2(stripe_x, 0.0),
			Vector2(stripe_x + TAPE_WIDTH, 0.0),
			Vector2(stripe_x + size.y + TAPE_WIDTH, size.y),
			Vector2(stripe_x + size.y, size.y),
		])
		draw_colored_polygon(stripe, Color(1.0, 0.07, 0.11, 0.88))
		stripe_x += TAPE_STRIDE
	draw_line(Vector2(0.0, 1.0), Vector2(size.x, 1.0), Color(1.0, 0.68, 0.54, 0.95), 1.0)
	draw_line(Vector2(0.0, size.y - 1.0), Vector2(size.x, size.y - 1.0), Color(1.0, 0.32, 0.32, 0.9), 1.0)
