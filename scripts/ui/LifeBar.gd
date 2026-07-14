extends Panel
## 玩家机体结构（HP）血条 —— 斜角红色轨道 + 青色扫描描边（含受击残影）

const FLASH_DURATION: float = 0.4
const FRAME_INSET := Vector2(1.0, 2.0)
const FRAME_PADDING := Vector2(2.0, 2.0)
const FRAME_CYAN := Color("#52e8ff")
const TRACK_DARK := Color("#10090d")
const HEALTH_RED := Color("#f04c58")
const DAMAGE_AMBER := Color("#ffb84d")

var _flash_hp: int = 0
var _flash_timer: float = FLASH_DURATION
var _last_hp: int = -1


func _process(delta: float) -> void:
	var hp: int = GameManager.player_hp
	var needs_redraw := false
	if _last_hp < 0:
		_last_hp = hp
		needs_redraw = true
	if hp != _last_hp:
		if hp < _last_hp:
			_flash_hp = _last_hp
			_flash_timer = 0.0
		_last_hp = hp
		needs_redraw = true

	if _flash_timer < FLASH_DURATION:
		_flash_timer += delta
		needs_redraw = true
	if needs_redraw:
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x <= 8.0 or size.y <= 8.0:
		return
	var frame_rect := Rect2(FRAME_INSET, size - FRAME_INSET * 2.0)
	var fill_rect := Rect2(frame_rect.position + FRAME_PADDING, frame_rect.size - FRAME_PADDING * 2.0)
	draw_rect(frame_rect, TRACK_DARK)
	_draw_frame(frame_rect)

	var hp := maxi(0, GameManager.player_hp)
	var max_hp := maxi(1, GameManager.PLAYER_MAX_HP)
	var fill_w := fill_rect.size.x * clampf(float(hp) / float(max_hp), 0.0, 1.0)
	_draw_fill(fill_rect, fill_w, HEALTH_RED)
	if _flash_timer < FLASH_DURATION:
		var loss_w := fill_rect.size.x * float(maxi(0, _flash_hp - hp)) / float(max_hp)
		var fade := 1.0 - clampf(_flash_timer / FLASH_DURATION, 0.0, 1.0)
		_draw_fill(Rect2(fill_rect.position + Vector2(fill_w, 0.0), Vector2(fill_rect.size.x - fill_w, fill_rect.size.y)), loss_w * fade, DAMAGE_AMBER)


func _draw_frame(frame_rect: Rect2) -> void:
	var cyan_dim := Color(FRAME_CYAN.r, FRAME_CYAN.g, FRAME_CYAN.b, 0.58)
	draw_line(frame_rect.position, Vector2(frame_rect.end.x, frame_rect.position.y), cyan_dim, 1.5)
	draw_line(Vector2(frame_rect.end.x, frame_rect.position.y), frame_rect.end, cyan_dim, 1.5)
	draw_line(Vector2(frame_rect.position.x, frame_rect.end.y), frame_rect.end, Color(HEALTH_RED.r, HEALTH_RED.g, HEALTH_RED.b, 0.46), 1.0)
	draw_line(frame_rect.position, Vector2(frame_rect.position.x, frame_rect.end.y), Color(HEALTH_RED.r, HEALTH_RED.g, HEALTH_RED.b, 0.72), 1.0)


func _draw_fill(track: Rect2, width: float, color: Color) -> void:
	if width <= 0.0:
		return
	var fill_width := minf(width, track.size.x)
	var bevel := minf(4.0, fill_width * 0.5)
	var points := PackedVector2Array()
	points.append(track.position)
	points.append(Vector2(track.position.x + fill_width - bevel, track.position.y))
	points.append(Vector2(track.position.x + fill_width, track.position.y + bevel))
	points.append(Vector2(track.position.x + fill_width, track.end.y))
	points.append(Vector2(track.position.x, track.end.y))
	draw_colored_polygon(points, color)
	draw_line(track.position + Vector2(1.0, 1.0), Vector2(track.position.x + fill_width - bevel, track.position.y + 1.0), Color(1.0, 0.78, 0.78, 0.42), 1.0)
