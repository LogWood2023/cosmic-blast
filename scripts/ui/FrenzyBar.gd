extends Panel
## 狂热槽 —— 与生命条匹配的斜角轨道，充能时使用熔金色。

const FRAME_INSET := Vector2(1.0, 1.0)
const FRAME_PADDING := Vector2(2.0, 2.0)
const FRAME_CYAN := Color("#52e8ff")
const TRACK_DARK := Color("#120d08")
const CHARGE_GOLD := Color("#f5b744")
const ACTIVE_ORANGE := Color("#ff6343")

var _last_ratio: float = -1.0
var _last_active: bool = false


func _process(_delta: float) -> void:
	var ratio: float = clampf(GameManager.get_frenzy_ratio(), 0.0, 1.0)
	if not is_equal_approx(ratio, _last_ratio) or GameManager.frenzy_active != _last_active:
		_last_ratio = ratio
		_last_active = GameManager.frenzy_active
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x <= 7.0 or size.y <= 7.0:
		return
	var frame_rect := Rect2(FRAME_INSET, size - FRAME_INSET * 2.0)
	var fill_rect := Rect2(frame_rect.position + FRAME_PADDING, frame_rect.size - FRAME_PADDING * 2.0)
	draw_rect(frame_rect, TRACK_DARK)
	var outline := Color(FRAME_CYAN.r, FRAME_CYAN.g, FRAME_CYAN.b, 0.46)
	draw_line(frame_rect.position, Vector2(frame_rect.end.x, frame_rect.position.y), outline, 1.0)
	draw_line(Vector2(frame_rect.end.x, frame_rect.position.y), frame_rect.end, outline, 1.0)
	draw_line(frame_rect.position, Vector2(frame_rect.position.x, frame_rect.end.y), Color(CHARGE_GOLD.r, CHARGE_GOLD.g, CHARGE_GOLD.b, 0.62), 1.0)
	draw_line(Vector2(frame_rect.position.x, frame_rect.end.y), frame_rect.end, Color(CHARGE_GOLD.r, CHARGE_GOLD.g, CHARGE_GOLD.b, 0.42), 1.0)

	var width := fill_rect.size.x * clampf(GameManager.get_frenzy_ratio(), 0.0, 1.0)
	if width <= 0.0:
		return
	var bevel := minf(3.0, width * 0.5)
	var color := ACTIVE_ORANGE if GameManager.frenzy_active else CHARGE_GOLD
	var points := PackedVector2Array([
		fill_rect.position,
		Vector2(fill_rect.position.x + width - bevel, fill_rect.position.y),
		Vector2(fill_rect.position.x + width, fill_rect.position.y + bevel),
		Vector2(fill_rect.position.x + width, fill_rect.end.y),
		Vector2(fill_rect.position.x, fill_rect.end.y),
	])
	draw_colored_polygon(points, color)
	draw_line(fill_rect.position + Vector2(1.0, 1.0), Vector2(fill_rect.position.x + width - bevel, fill_rect.position.y + 1.0), Color(1.0, 0.9, 0.58, 0.55), 1.0)
