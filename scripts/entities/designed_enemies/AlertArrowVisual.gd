extends Node2D

const START_PADDING: float = 10.0
const END_PADDING: float = 16.0
const MIN_VISIBLE_LENGTH: float = 42.0
const LINE_WIDTH: float = 15.0
const HEAD_LENGTH: float = 24.0
const HEAD_WIDTH: float = 54.0

var source: Node2D
var target: Node2D
var source_radius: float = 36.0
var target_radius: float = 32.0
var arrow_color: Color = Color(1.0, 0.16, 0.04, 0.3)
var travel_duration: float = 0.28
var hold_duration: float = 0.5
var fade_duration: float = 0.18
var elapsed: float = 0.0
var _last_start: Vector2 = Vector2.ZERO
var _last_end: Vector2 = Vector2.ZERO


func setup(source_node: Node2D, target_node: Node2D, source_extent: float, target_extent: float, color: Color, travel_time: float, hold_time: float, fade_time: float) -> void:
	source = source_node
	target = target_node
	source_radius = source_extent
	target_radius = target_extent
	arrow_color = color
	travel_duration = maxf(travel_time, 0.01)
	hold_duration = maxf(hold_time, 0.0)
	fade_duration = maxf(fade_time, 0.01)
	z_index = 180
	z_as_relative = false
	set_process(true)
	_update_cached_endpoints()
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= travel_duration + hold_duration + fade_duration:
		queue_free()
		return
	_update_cached_endpoints()
	queue_redraw()


func _draw() -> void:
	var start := _last_start
	var end := _last_end
	var total := end - start
	if total.length() < 4.0:
		return
	var progress := smoothstep(0.0, 1.0, clampf(elapsed / travel_duration, 0.0, 1.0))
	var current_end := start.lerp(end, progress)
	var current_vector := current_end - start
	if current_vector.length() < 4.0:
		return
	var alpha := _current_alpha()
	if alpha <= 0.0:
		return
	var color := Color(arrow_color.r, arrow_color.g, arrow_color.b, arrow_color.a * alpha)
	var dir := current_vector.normalized()
	var head_len := minf(HEAD_LENGTH, current_vector.length() * 0.45)
	var head_width := minf(HEAD_WIDTH, maxf(6.0, current_vector.length() * 0.3))
	var line_end := current_end - dir * head_len * 0.55
	draw_line(to_local(start), to_local(line_end), color, LINE_WIDTH, true)
	var perp := Vector2(-dir.y, dir.x)
	var head := PackedVector2Array([
		to_local(current_end),
		to_local(current_end - dir * head_len + perp * head_width * 0.5),
		to_local(current_end - dir * head_len - perp * head_width * 0.5),
	])
	draw_colored_polygon(head, color)


func _update_cached_endpoints() -> void:
	var source_pos := _last_start
	var target_pos := _last_end
	if is_instance_valid(source):
		source_pos = source.global_position
	if is_instance_valid(target):
		target_pos = target.global_position
	var delta := target_pos - source_pos
	if delta.length() <= 0.01:
		return
	var dir := delta.normalized()
	var start := source_pos + dir * (source_radius + START_PADDING)
	var end := target_pos - dir * (target_radius + END_PADDING)
	if start.distance_to(end) < MIN_VISIBLE_LENGTH:
		start = source_pos.lerp(target_pos, 0.25)
		end = source_pos.lerp(target_pos, 0.75)
	_last_start = start
	_last_end = end


func _current_alpha() -> float:
	var fade_start := travel_duration + hold_duration
	if elapsed <= fade_start:
		return 1.0
	return 1.0 - clampf((elapsed - fade_start) / fade_duration, 0.0, 1.0)
