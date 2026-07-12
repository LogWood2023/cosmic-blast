extends Control

signal slice_hovered(detail: String)
signal slice_unhovered

const FAMILIES: Array[String] = ["colossus", "paradise", "warped", "hell_eye", "divine"]
const FAMILY_NAMES := {
	"colossus": "巨构系",
	"paradise": "天堂系",
	"warped": "扭曲系",
	"hell_eye": "地狱之眼系",
	"divine": "神使系",
}
const FAMILY_COLORS := {
	"colossus": Color("ff9a4d"),
	"paradise": Color("64d8ff"),
	"warped": Color("a966ff"),
	"hell_eye": Color("ff526d"),
	"divine": Color("ffe58a"),
}

var _weights: Dictionary = {}
var _slices: Array[Dictionary] = []
var _hovered_slice: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(_clear_hovered_slice)


func set_weights(weights: Dictionary) -> void:
	_weights = weights.duplicate()
	_rebuild_slices()
	queue_redraw()


func _rebuild_slices() -> void:
	_slices.clear()
	var total_weight := 0.0
	for family in FAMILIES:
		total_weight += maxf(0.0, float(_weights.get(family, 0.0)))
	if total_weight <= 0.0:
		return
	var angle := -PI * 0.5
	for family in FAMILIES:
		var weight := maxf(0.0, float(_weights.get(family, 0.0)))
		var span := TAU * weight / total_weight
		_slices.append({
			"family": family,
			"weight": weight,
			"share": weight / total_weight,
			"start": angle,
			"end": angle + span,
		})
		angle += span
	_hovered_slice = -1


func _draw() -> void:
	var radius := maxf(0.0, minf(size.x, size.y) * 0.5 - 6.0)
	if radius <= 0.0 or _slices.is_empty():
		return
	var center := size * 0.5
	for index in range(_slices.size()):
		var slice := _slices[index]
		var start := float(slice["start"])
		var end := float(slice["end"])
		var arc_points := maxi(8, int(ceil(absf(end - start) / TAU * 48.0)))
		var points := PackedVector2Array([center])
		for point_index in range(arc_points + 1):
			var progress := float(point_index) / float(arc_points)
			points.append(center + Vector2.from_angle(lerpf(start, end, progress)) * radius)
		draw_colored_polygon(points, FAMILY_COLORS.get(String(slice["family"]), Color.WHITE))
		draw_arc(center, radius, start, end, arc_points, Color(0.015, 0.03, 0.06, 0.95), 2.0, true)
		if index == _hovered_slice:
			draw_arc(center, radius + 2.0, start, end, arc_points, Color.WHITE, 3.0, true)
	draw_circle(center, radius * 0.42, Color(0.015, 0.03, 0.06, 0.96))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.45, 0.84, 1.0, 0.85), 1.0, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hovered_slice(_slice_at(event.position))


func _slice_at(local_position: Vector2) -> int:
	var center := size * 0.5
	var radius := maxf(0.0, minf(size.x, size.y) * 0.5 - 6.0)
	var distance := local_position.distance_to(center)
	if distance < radius * 0.42 or distance > radius:
		return -1
	var angle := fposmod(center.angle_to_point(local_position), TAU)
	for index in range(_slices.size()):
		var slice := _slices[index]
		var start := fposmod(float(slice["start"]), TAU)
		var end := start + float(slice["end"]) - float(slice["start"])
		if angle >= start and angle < end:
			return index
		if end > TAU and angle < end - TAU:
			return index
	return -1


func _set_hovered_slice(index: int) -> void:
	if _hovered_slice == index:
		return
	_hovered_slice = index
	queue_redraw()
	if index < 0:
		tooltip_text = ""
		slice_unhovered.emit()
		return
	var slice := _slices[index]
	var family := String(slice["family"])
	var detail := "%s敌人｜权重 %.1f（占比 %.1f%%）" % [
		String(FAMILY_NAMES.get(family, family)),
		float(slice["weight"]),
		float(slice["share"]) * 100.0,
	]
	tooltip_text = detail
	slice_hovered.emit(detail)


func _clear_hovered_slice() -> void:
	_set_hovered_slice(-1)
