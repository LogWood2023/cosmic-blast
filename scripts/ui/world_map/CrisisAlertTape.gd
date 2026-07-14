extends Control
## Animated warning-tape trim for the full-screen crisis alert.

const STRIPE_WIDTH: float = 42.0
const STRIPE_STRIDE: float = 102.0
const SCROLL_SPEED: float = 210.0

@export var scroll_direction: float = 1.0

var _active: bool = false
var _scroll_offset: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func set_active(is_active: bool) -> void:
	_active = is_active
	visible = is_active
	set_process(is_active)
	if is_active:
		_scroll_offset = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_scroll_offset = fposmod(_scroll_offset + SCROLL_SPEED * scroll_direction * delta, STRIPE_STRIDE)
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.18, 0.002, 0.012, 0.92), true)
	var stripe_x: float = -size.y - STRIPE_WIDTH + _scroll_offset - STRIPE_STRIDE
	var stripe_end: float = size.x + STRIPE_STRIDE
	while stripe_x < stripe_end:
		var stripe: PackedVector2Array = PackedVector2Array([
			Vector2(stripe_x, 0.0),
			Vector2(stripe_x + STRIPE_WIDTH, 0.0),
			Vector2(stripe_x + size.y + STRIPE_WIDTH, size.y),
			Vector2(stripe_x + size.y, size.y),
		])
		draw_colored_polygon(stripe, Color(1.0, 0.06, 0.12, 0.92))
		stripe_x += STRIPE_STRIDE
	draw_line(Vector2.ZERO, Vector2(size.x, 0.0), Color(1.0, 0.48, 0.50, 0.95), 1.0)
	draw_line(Vector2(0.0, size.y - 1.0), Vector2(size.x, size.y - 1.0), Color(1.0, 0.16, 0.22, 0.96), 1.0)
