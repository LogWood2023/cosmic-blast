extends Panel
## 左侧星髓矿计数框：保留截图中的青色扫描线与切角外框。

const FRAME_CYAN := Color("#52e8ff")
const PANEL_DARK := Color("#061018")


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var right := size.x - 1.0
	var bottom := size.y - 1.0
	var frame := PackedVector2Array([
		Vector2(8.0, 1.0), Vector2(right - 1.0, 1.0), Vector2(right, 8.0),
		Vector2(right, bottom - 6.0), Vector2(right - 7.0, bottom), Vector2(1.0, bottom),
		Vector2(1.0, 9.0),
	])
	draw_colored_polygon(frame, PANEL_DARK)
	draw_polyline(frame + PackedVector2Array([frame[0]]), Color(FRAME_CYAN.r, FRAME_CYAN.g, FRAME_CYAN.b, 0.78), 1.5, true)
	draw_line(Vector2(7.0, 4.0), Vector2(right - 5.0, 4.0), Color(FRAME_CYAN.r, FRAME_CYAN.g, FRAME_CYAN.b, 0.32), 1.0)
	draw_line(Vector2(5.0, bottom - 5.0), Vector2(right - 10.0, bottom - 5.0), Color(FRAME_CYAN.r, FRAME_CYAN.g, FRAME_CYAN.b, 0.2), 1.0)
