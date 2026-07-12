extends Control

signal node_selected(node_id: int)

const NODE_RADIUS: float = 28.0
const SPECIAL_RADIUS: float = 31.0
const CENTER_RADIUS: float = 42.0
const MIN_ZOOM: float = 0.55
const MAX_ZOOM: float = 1.80
const DEFAULT_ZOOM: float = 0.82
const ZOOM_STEP: float = 1.12
const DRAG_THRESHOLD: float = 6.0
const PAN_EDGE_VISIBLE: float = 96.0
const MAP_LINE_COLOR: Color = Color(0.24, 0.42, 0.76, 0.62)
const NODE_SURFACE_COLOR: Color = Color(0.018, 0.034, 0.058, 0.98)
const NODE_ICON_COLOR: Color = Color(0.94, 0.98, 1.0, 1.0)
const NODE_MUTED_COLOR: Color = Color(0.36, 0.43, 0.52, 0.92)
const NODE_LABEL_MIN_ZOOM: float = 0.68
const LINK_ROUTE_CLEARANCE: float = 30.0
const LINK_ROUTE_MAX_LANES: int = 12
const LINK_ROUTE_DIRECTION_SAMPLES: int = 8

var selected_node_id: int = RunManager.CENTER_ID
var _zoom: float = DEFAULT_ZOOM
var _pan_offset: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_moved: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _last_drag_position: Vector2 = Vector2.ZERO
var _hovered_node_id: int = -1
var _link_routes: Dictionary = {}


func _ready() -> void:
	clip_contents = true
	resized.connect(_on_resized)
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	call_deferred("reset_view")


func reset_view() -> void:
	_zoom = DEFAULT_ZOOM
	_pan_offset = Vector2.ZERO
	_link_routes.clear()
	_clamp_pan()
	queue_redraw()


func refresh_map(node_id: int) -> void:
	selected_node_id = node_id
	_link_routes.clear()
	_clamp_pan()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(event.position, _zoom * ZOOM_STEP)
			accept_event()
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(event.position, _zoom / ZOOM_STEP)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_dragging = true
				_drag_moved = false
				_press_position = event.position
				_last_drag_position = event.position
				mouse_default_cursor_shape = Control.CURSOR_MOVE
			else:
				var was_dragging := _dragging
				_dragging = false
				mouse_default_cursor_shape = Control.CURSOR_DRAG
				if was_dragging and not _drag_moved and event.button_index == MOUSE_BUTTON_LEFT:
					var node_id := _node_at_position(event.position)
					if node_id >= 0:
						node_selected.emit(node_id)
			accept_event()
			return
	if event is InputEventMouseMotion:
		if _dragging:
			if event.position.distance_to(_press_position) >= DRAG_THRESHOLD:
				_drag_moved = true
			var previous_pan := _pan_offset
			_pan_offset += event.position - _last_drag_position
			_last_drag_position = event.position
			_clamp_pan()
			_translate_cached_link_routes(_pan_offset - previous_pan)
			queue_redraw()
			accept_event()
			return
		_update_hovered_node(event.position)
	if event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_drag_moved = false
			_press_position = event.position
			_last_drag_position = event.position
		else:
			var was_dragging := _dragging
			_dragging = false
			if was_dragging and not _drag_moved:
				var node_id := _node_at_position(event.position)
				if node_id >= 0:
					node_selected.emit(node_id)
		accept_event()
		return
	if event is InputEventScreenDrag:
		_dragging = true
		_drag_moved = true
		var previous_pan := _pan_offset
		_pan_offset += event.relative
		_last_drag_position = event.position
		_clamp_pan()
		_translate_cached_link_routes(_pan_offset - previous_pan)
		queue_redraw()
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.014, 0.03, 0.98), true)
	_draw_background_material()
	_draw_links()
	_draw_nodes()
	_draw_link_ports()
	_draw_node_overlays()
	_draw_view_hint()


func _draw_background_material() -> void:
	var grid_color := Color(0.14, 0.34, 0.48, 0.10)
	var grid_step := 96.0 * _zoom
	var grid_origin := Vector2(fposmod(_pan_offset.x, grid_step), fposmod(_pan_offset.y, grid_step))
	var x := grid_origin.x
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid_color, 1.0)
		x += grid_step
	var y := grid_origin.y
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), grid_color, 1.0)
		y += grid_step
	for star_index in range(30):
		var star := Vector2(
			fposmod(47.0 + float(star_index * 137), maxf(1.0, size.x)),
			fposmod(31.0 + float(star_index * 83), maxf(1.0, size.y))
		)
		draw_circle(star, 1.2 if star_index % 4 else 1.8, Color(0.58, 0.86, 1.0, 0.24))


func _draw_links() -> void:
	var drawn := {}
	for node in RunManager.map_nodes:
		var from_id := int(node.get("id", -1))
		for linked_id in node.get("links", []):
			var to_id := int(linked_id)
			var key := "%d_%d" % [mini(from_id, to_id), maxi(from_id, to_id)]
			if drawn.has(key):
				continue
			drawn[key] = true
			if _link_routes.has(key):
				var cached_route_data: Dictionary = _link_routes[key]
				var cached_route: PackedVector2Array = cached_route_data.get("points", PackedVector2Array())
				if cached_route.size() >= 2:
					draw_polyline(cached_route, Color(0.01, 0.02, 0.04, 0.92), maxf(3.5, 5.0 * _zoom), true)
					draw_polyline(cached_route, MAP_LINE_COLOR, maxf(1.5, 2.6 * _zoom), true)
				continue
			var linked_node := RunManager.get_map_node(to_id)
			if linked_node.is_empty():
				continue
			var route := _build_link_route(node, linked_node)
			if route.size() < 2:
				continue
			_link_routes[key] = {
				"points": route,
				"from_id": from_id,
				"from_type": String(node.get("type", "")),
				"to_id": to_id,
				"to_type": String(linked_node.get("type", "")),
			}
			draw_polyline(route, Color(0.01, 0.02, 0.04, 0.92), maxf(3.5, 5.0 * _zoom), true)
			draw_polyline(route, MAP_LINE_COLOR, maxf(1.5, 2.6 * _zoom), true)


func _draw_link_ports() -> void:
	for route_data in _link_routes.values():
		var points: PackedVector2Array = route_data.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var from_id := int(route_data.get("from_id", -1))
		var from_type := String(route_data.get("from_type", ""))
		var to_id := int(route_data.get("to_id", -1))
		var to_type := String(route_data.get("to_type", ""))
		_draw_link_port(points[0], _get_node_color(from_id, from_type))
		_draw_link_port(points[points.size() - 1], _get_node_color(to_id, to_type))


func _translate_cached_link_routes(offset: Vector2) -> void:
	if offset.is_zero_approx():
		return
	for key in _link_routes.keys():
		var route_data: Dictionary = _link_routes[key]
		var points: PackedVector2Array = route_data.get("points", PackedVector2Array())
		for point_index in range(points.size()):
			points[point_index] += offset
		route_data["points"] = points
		_link_routes[key] = route_data


func _draw_link_port(position: Vector2, color: Color) -> void:
	var port_radius := maxf(2.5, 3.6 * _zoom)
	draw_circle(position, port_radius + maxf(1.0, 1.4 * _zoom), NODE_SURFACE_COLOR)
	draw_circle(position, port_radius, color)


func _build_link_route(from_node: Dictionary, to_node: Dictionary) -> PackedVector2Array:
	var from_id := int(from_node.get("id", -1))
	var to_id := int(to_node.get("id", -1))
	var from_type := String(from_node.get("type", ""))
	var to_type := String(to_node.get("type", ""))
	var from_center := _world_to_screen(from_node.get("position", Vector2.ZERO))
	var to_center := _world_to_screen(to_node.get("position", Vector2.ZERO))
	var route := PackedVector2Array([from_center, to_center])
	if not _route_is_clear(route, from_id, to_id):
		route = _find_clear_parallel_route(from_center, to_center, from_id, to_id)
	if route.size() >= 2:
		route[0] = _get_link_anchor(from_center, route[1], from_id, from_type)
		var last_index := route.size() - 1
		route[last_index] = _get_link_anchor(to_center, route[last_index - 1], to_id, to_type)
	return route


func _find_clear_parallel_route(from_center: Vector2, to_center: Vector2, from_id: int, to_id: int) -> PackedVector2Array:
	var edge_direction := from_center.direction_to(to_center)
	if edge_direction.is_zero_approx():
		return PackedVector2Array([from_center, to_center])
	var edge_normal := Vector2(-edge_direction.y, edge_direction.x)
	var lane_step := maxf(18.0, LINK_ROUTE_CLEARANCE * _zoom)
	var preferred_directions := PackedVector2Array([edge_normal, -edge_normal])
	var route := _search_clear_lane_directions(
		from_center,
		to_center,
		from_id,
		to_id,
		preferred_directions,
		lane_step
	)
	if not route.is_empty():
		return route
	var fallback_directions := PackedVector2Array()
	for sample_index in range(LINK_ROUTE_DIRECTION_SAMPLES):
		fallback_directions.append(Vector2.RIGHT.rotated(TAU * float(sample_index) / float(LINK_ROUTE_DIRECTION_SAMPLES)))
	route = _search_clear_lane_directions(
		from_center,
		to_center,
		from_id,
		to_id,
		fallback_directions,
		lane_step
	)
	return route if not route.is_empty() else PackedVector2Array([from_center, to_center])


func _search_clear_lane_directions(from_center: Vector2, to_center: Vector2, from_id: int, to_id: int, lane_directions: PackedVector2Array, lane_step: float) -> PackedVector2Array:
	for lane_index in range(1, LINK_ROUTE_MAX_LANES + 1):
		var lane_distance := lane_step * float(lane_index)
		var best_route := PackedVector2Array()
		var best_length := INF
		for lane_direction in lane_directions:
			var offset := lane_direction * lane_distance
			var candidate := PackedVector2Array([
				from_center,
				from_center + offset,
				to_center + offset,
				to_center,
			])
			if not _route_is_clear(candidate, from_id, to_id):
				continue
			var candidate_length := _get_route_length(candidate)
			if candidate_length < best_length:
				best_length = candidate_length
				best_route = candidate
		if not best_route.is_empty():
			return best_route
	return PackedVector2Array()


func _route_is_clear(route: PackedVector2Array, from_id: int, to_id: int) -> bool:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id == from_id or node_id == to_id:
			continue
		for point_index in range(route.size() - 1):
			if _route_segment_intersects_node_ui(route[point_index], route[point_index + 1], node):
				return false
	return true


func _get_route_length(route: PackedVector2Array) -> float:
	var total := 0.0
	for point_index in range(route.size() - 1):
		total += route[point_index].distance_to(route[point_index + 1])
	return total


func _route_segment_intersects_node_ui(segment_start: Vector2, segment_end: Vector2, node: Dictionary) -> bool:
	var node_id := int(node.get("id", -1))
	var node_type := String(node.get("type", ""))
	var is_base := node_id == RunManager.CENTER_ID
	var node_center := _world_to_screen(node.get("position", Vector2.ZERO))
	var node_radius := _get_node_radius(node_id, node_type) * _zoom
	var body_clearance := maxf(8.0, 12.0 * _zoom)
	if node_id == selected_node_id:
		body_clearance = maxf(body_clearance, 15.0)
	var obstacle_radius := node_radius + body_clearance
	if _distance_squared_to_segment(node_center, segment_start, segment_end) < obstacle_radius * obstacle_radius:
		return true
	var label_rect := _get_node_label_rect(node_center, node_radius, node_id, is_base, node_type)
	return label_rect.size != Vector2.ZERO and _segment_intersects_rect(segment_start, segment_end, label_rect.grow(maxf(3.0, 4.0 * _zoom)))


func _segment_intersects_rect(segment_start: Vector2, segment_end: Vector2, rect: Rect2) -> bool:
	if rect.has_point(segment_start) or rect.has_point(segment_end):
		return true
	var top_left := rect.position
	var top_right := Vector2(rect.end.x, rect.position.y)
	var bottom_right := rect.end
	var bottom_left := Vector2(rect.position.x, rect.end.y)
	return (
		Geometry2D.segment_intersects_segment(segment_start, segment_end, top_left, top_right) != null
		or Geometry2D.segment_intersects_segment(segment_start, segment_end, top_right, bottom_right) != null
		or Geometry2D.segment_intersects_segment(segment_start, segment_end, bottom_right, bottom_left) != null
		or Geometry2D.segment_intersects_segment(segment_start, segment_end, bottom_left, top_left) != null
	)


func _distance_squared_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment_vector := segment_end - segment_start
	var length_squared := segment_vector.length_squared()
	if length_squared <= 0.0001:
		return point.distance_squared_to(segment_start)
	var progress := clampf((point - segment_start).dot(segment_vector) / length_squared, 0.0, 1.0)
	return point.distance_squared_to(segment_start + segment_vector * progress)


func _get_link_anchor(node_center: Vector2, other_center: Vector2, node_id: int, node_type: String) -> Vector2:
	var direction := node_center.direction_to(other_center)
	if direction.is_zero_approx():
		return node_center
	var radius := _get_node_radius(node_id, node_type) * _zoom
	var edge_distance := radius
	if node_id == RunManager.CENTER_ID:
		edge_distance = _ray_distance_to_regular_polygon(direction, radius, 8, -PI * 0.125)
	else:
		match node_type:
			RunManager.NODE_BATTLE:
				edge_distance = _ray_distance_to_regular_polygon(direction, radius, 4, -PI * 0.5)
			RunManager.NODE_REWARD:
				edge_distance = _ray_distance_to_regular_polygon(direction, radius, 6, -PI * 0.5)
			RunManager.NODE_SPECIAL:
				edge_distance = _ray_distance_to_regular_polygon(direction, radius, 8, -PI * 0.125)
	return node_center + direction * edge_distance


func _ray_distance_to_regular_polygon(direction: Vector2, radius: float, side_count: int, rotation: float) -> float:
	var sector_angle := TAU / float(side_count)
	var first_edge_normal := rotation + sector_angle * 0.5
	var angle_delta := fposmod(direction.angle() - first_edge_normal + sector_angle * 0.5, sector_angle) - sector_angle * 0.5
	var apothem := radius * cos(PI / float(side_count))
	return apothem / maxf(0.001, cos(angle_delta))


func _draw_nodes() -> void:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		var is_base := node_id == RunManager.CENTER_ID
		var position := _world_to_screen(node.get("position", Vector2.ZERO))
		var radius := _get_node_radius(node_id, node_type) * _zoom
		if not Rect2(Vector2.ZERO, size).grow(radius + 32.0).has_point(position):
			continue
		var color := _get_node_color(node_id, node_type)
		_draw_node_selection(position, radius, node_id, color)
		_draw_node_badge(position, radius, node_type, is_base, color)


func _draw_node_overlays() -> void:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		var is_base := node_id == RunManager.CENTER_ID
		var position := _world_to_screen(node.get("position", Vector2.ZERO))
		var radius := _get_node_radius(node_id, node_type) * _zoom
		if not Rect2(Vector2.ZERO, size).grow(radius + 32.0).has_point(position):
			continue
		var color := _get_node_color(node_id, node_type)
		_draw_node_state_badge(position, radius, node_id)
		_draw_node_label(position, radius, node_id, is_base, node_type, color)


func _draw_node_selection(position: Vector2, radius: float, node_id: int, color: Color) -> void:
	if node_id == _hovered_node_id:
		draw_circle(position, radius + 7.0, Color(color.r, color.g, color.b, 0.14))
	if node_id != selected_node_id:
		return
	draw_circle(position, radius + 10.0, Color(1.0, 1.0, 1.0, 0.10))
	var extent := radius + 13.0
	var corner_length := maxf(6.0, radius * 0.24)
	var line_width := maxf(1.5, 2.2 * _zoom)
	for x_sign in [-1.0, 1.0]:
		for y_sign in [-1.0, 1.0]:
			var corner := position + Vector2(extent * x_sign, extent * y_sign)
			draw_line(corner, corner - Vector2(corner_length * x_sign, 0.0), Color.WHITE, line_width, true)
			draw_line(corner, corner - Vector2(0.0, corner_length * y_sign), Color.WHITE, line_width, true)


func _draw_node_badge(position: Vector2, radius: float, node_type: String, is_base: bool, color: Color) -> void:
	if is_base:
		_draw_core_material(position, radius, color)
		return
	match node_type:
		RunManager.NODE_BATTLE:
			_draw_battle_material(position, radius, color)
		RunManager.NODE_EVENT:
			_draw_event_material(position, radius, color)
		RunManager.NODE_REWARD:
			_draw_reward_material(position, radius, color)
		RunManager.NODE_SPECIAL:
			_draw_special_material(position, radius, color)
		_:
			draw_circle(position, radius, NODE_SURFACE_COLOR)
			draw_arc(position, radius, 0.0, TAU, 48, color, maxf(1.5, 2.0 * _zoom), true)


func _draw_core_material(position: Vector2, radius: float, color: Color) -> void:
	var outer := _regular_polygon(position, radius, 8, -PI * 0.125)
	draw_colored_polygon(outer, NODE_SURFACE_COLOR)
	_draw_polygon_outline(outer, color, maxf(2.0, 3.0 * _zoom))
	var inner := _regular_polygon(position, radius * 0.68, 6, -PI * 0.5)
	draw_colored_polygon(inner, color)
	var core := _regular_polygon(position, radius * 0.34, 4, -PI * 0.5)
	draw_colored_polygon(core, NODE_ICON_COLOR)
	for rail_index in range(4):
		var direction := Vector2.RIGHT.rotated(TAU * float(rail_index) / 4.0)
		draw_line(position + direction * radius * 0.70, position + direction * radius * 0.92, NODE_ICON_COLOR, maxf(1.5, 2.0 * _zoom), true)


func _draw_battle_material(position: Vector2, radius: float, color: Color) -> void:
	var badge := _regular_polygon(position, radius, 4, -PI * 0.5)
	draw_colored_polygon(badge, NODE_SURFACE_COLOR)
	_draw_polygon_outline(badge, color, maxf(1.8, 2.6 * _zoom))
	var shield := PackedVector2Array([
		position + Vector2(-radius * 0.42, -radius * 0.42),
		position + Vector2(radius * 0.42, -radius * 0.42),
		position + Vector2(radius * 0.34, radius * 0.24),
		position + Vector2(0.0, radius * 0.58),
		position + Vector2(-radius * 0.34, radius * 0.24),
	])
	draw_colored_polygon(shield, color)
	_draw_polygon_outline(shield, NODE_ICON_COLOR, maxf(1.2, 1.7 * _zoom))
	draw_line(position + Vector2(-radius * 0.22, 0.0), position + Vector2(radius * 0.22, 0.0), NODE_ICON_COLOR, maxf(1.2, 1.7 * _zoom), true)
	draw_line(position + Vector2(0.0, -radius * 0.22), position + Vector2(0.0, radius * 0.22), NODE_ICON_COLOR, maxf(1.2, 1.7 * _zoom), true)


func _draw_event_material(position: Vector2, radius: float, color: Color) -> void:
	draw_circle(position, radius, NODE_SURFACE_COLOR)
	draw_arc(position, radius, 0.0, TAU, 48, color, maxf(1.8, 2.6 * _zoom), true)
	draw_arc(position, radius * 0.66, -PI * 0.82, -PI * 0.18, 20, color, maxf(1.4, 2.0 * _zoom), true)
	draw_line(position + Vector2(0.0, -radius * 0.45), position + Vector2(0.0, radius * 0.16), NODE_ICON_COLOR, maxf(2.0, 3.0 * _zoom), true)
	draw_circle(position + Vector2(0.0, radius * 0.43), maxf(2.4, radius * 0.10), NODE_ICON_COLOR)


func _draw_reward_material(position: Vector2, radius: float, color: Color) -> void:
	var hexagon := _regular_polygon(position, radius, 6, -PI * 0.5)
	draw_colored_polygon(hexagon, NODE_SURFACE_COLOR)
	_draw_polygon_outline(hexagon, color, maxf(1.8, 2.6 * _zoom))
	var gem := PackedVector2Array([
		position + Vector2(0.0, -radius * 0.56),
		position + Vector2(radius * 0.46, -radius * 0.08),
		position + Vector2(radius * 0.25, radius * 0.48),
		position + Vector2(-radius * 0.25, radius * 0.48),
		position + Vector2(-radius * 0.46, -radius * 0.08),
	])
	draw_colored_polygon(gem, color)
	_draw_polygon_outline(gem, NODE_ICON_COLOR, maxf(1.2, 1.7 * _zoom))
	draw_line(gem[0], position + Vector2(0.0, radius * 0.48), NODE_ICON_COLOR, maxf(1.0, 1.4 * _zoom), true)
	draw_line(gem[1], gem[4], NODE_ICON_COLOR, maxf(1.0, 1.4 * _zoom), true)


func _draw_special_material(position: Vector2, radius: float, color: Color) -> void:
	var badge := _regular_polygon(position, radius, 8, -PI * 0.125)
	draw_colored_polygon(badge, NODE_SURFACE_COLOR)
	_draw_polygon_outline(badge, color, maxf(1.8, 2.6 * _zoom))
	var beacon_origin := position + Vector2(0.0, radius * 0.24)
	draw_line(beacon_origin, position + Vector2(0.0, -radius * 0.26), NODE_ICON_COLOR, maxf(1.6, 2.2 * _zoom), true)
	draw_circle(position + Vector2(0.0, -radius * 0.30), maxf(2.3, radius * 0.09), color)
	for arc_index in range(2):
		var arc_radius := radius * (0.38 + float(arc_index) * 0.22)
		draw_arc(position + Vector2(0.0, -radius * 0.24), arc_radius, -PI * 0.82, -PI * 0.18, 18, color, maxf(1.3, 1.8 * _zoom), true)
	var foot := PackedVector2Array([
		beacon_origin + Vector2(0.0, -radius * 0.04),
		beacon_origin + Vector2(radius * 0.28, radius * 0.28),
		beacon_origin + Vector2(-radius * 0.28, radius * 0.28),
	])
	draw_colored_polygon(foot, color)


func _regular_polygon(center: Vector2, radius: float, side_count: int, rotation: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(side_count):
		var angle := rotation + TAU * float(point_index) / float(side_count)
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)
	return points


func _draw_polygon_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.is_empty():
		return
	var closed_points := points.duplicate()
	closed_points.append(points[0])
	draw_polyline(closed_points, color, width, true)


func _draw_node_state_badge(position: Vector2, radius: float, node_id: int) -> void:
	if node_id == RunManager.CENTER_ID:
		return
	var badge_center := position + Vector2(radius * 0.70, -radius * 0.70)
	var badge_radius := maxf(6.0, radius * 0.27)
	draw_circle(badge_center, badge_radius + maxf(1.5, 2.0 * _zoom), NODE_SURFACE_COLOR)
	if RunManager.is_node_completed(node_id):
		var state_color := Color(0.24, 0.92, 0.52, 1.0)
		draw_circle(badge_center, badge_radius, state_color)
		var check_width := maxf(1.4, 1.8 * _zoom)
		draw_line(badge_center + Vector2(-badge_radius * 0.46, 0.0), badge_center + Vector2(-badge_radius * 0.10, badge_radius * 0.34), NODE_SURFACE_COLOR, check_width, true)
		draw_line(badge_center + Vector2(-badge_radius * 0.10, badge_radius * 0.34), badge_center + Vector2(badge_radius * 0.50, -badge_radius * 0.38), NODE_SURFACE_COLOR, check_width, true)
	elif RunManager.is_node_accessible(node_id):
		var state_color := Color(0.28, 0.88, 1.0, 1.0)
		draw_circle(badge_center, badge_radius, state_color)
		var arrow := PackedVector2Array([
			badge_center + Vector2(-badge_radius * 0.32, -badge_radius * 0.48),
			badge_center + Vector2(badge_radius * 0.46, 0.0),
			badge_center + Vector2(-badge_radius * 0.32, badge_radius * 0.48),
		])
		draw_colored_polygon(arrow, NODE_SURFACE_COLOR)
	else:
		draw_circle(badge_center, badge_radius, NODE_MUTED_COLOR)
		var lock_rect := Rect2(
			badge_center + Vector2(-badge_radius * 0.42, -badge_radius * 0.02),
			Vector2(badge_radius * 0.84, badge_radius * 0.68)
		)
		draw_rect(lock_rect, NODE_SURFACE_COLOR, true)
		draw_arc(badge_center + Vector2(0.0, -badge_radius * 0.08), badge_radius * 0.32, PI, TAU, 12, NODE_SURFACE_COLOR, maxf(1.2, 1.6 * _zoom), true)


func _draw_node_label(position: Vector2, radius: float, node_id: int, is_base: bool, node_type: String, color: Color) -> void:
	var plate_rect := _get_node_label_rect(position, radius, node_id, is_base, node_type)
	if plate_rect.size == Vector2.ZERO:
		return
	var label := _get_node_label_text(is_base, node_type)
	var font := get_theme_default_font()
	var font_size := clampi(int(round(13.0 * _zoom)), 11, 16)
	var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var padding := Vector2(maxf(5.0, 6.0 * _zoom), maxf(2.0, 3.0 * _zoom))
	draw_rect(plate_rect, Color(0.008, 0.018, 0.032, 0.94), true)
	draw_rect(plate_rect, Color(color.r, color.g, color.b, 0.78), false, maxf(1.0, 1.3 * _zoom), true)
	var text_position := plate_rect.position + padding + Vector2(0.0, label_size.y * 0.76)
	draw_string(font, text_position, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, NODE_ICON_COLOR)


func _get_node_label_rect(position: Vector2, radius: float, node_id: int, is_base: bool, node_type: String) -> Rect2:
	if _zoom < NODE_LABEL_MIN_ZOOM and node_id != selected_node_id and node_id != _hovered_node_id:
		return Rect2()
	var label := _get_node_label_text(is_base, node_type)
	var font := get_theme_default_font()
	var font_size := clampi(int(round(13.0 * _zoom)), 11, 16)
	var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var padding := Vector2(maxf(5.0, 6.0 * _zoom), maxf(2.0, 3.0 * _zoom))
	var plate_size := label_size + padding * 2.0
	var plate_position := position + Vector2(-plate_size.x * 0.5, radius + maxf(7.0, 9.0 * _zoom))
	return Rect2(plate_position, plate_size)


func _get_node_label_text(is_base: bool, node_type: String) -> String:
	return "方舟核心" if is_base else _node_display_name(node_type)


func _draw_view_hint() -> void:
	var hint := "拖拽平移  ·  滚轮缩放  %d%%" % int(round(_zoom * 100.0))
	var font := get_theme_default_font()
	var font_size := 16
	var hint_size := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(size.x - hint_size.x - 18.0, 28.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.64, 0.80, 0.90, 0.62))


func _get_node_color(node_id: int, node_type: String) -> Color:
	if node_id == RunManager.CENTER_ID:
		return Color(1.0, 0.22, 0.16, 1.0) if RunManager.is_alert_active() else Color(1.0, 0.72, 0.22, 1.0)
	var type_color := Color(0.22, 0.76, 1.0, 1.0)
	match node_type:
		RunManager.NODE_BATTLE:
			type_color = Color(0.16, 0.72, 1.0, 1.0)
		RunManager.NODE_EVENT:
			type_color = Color(1.0, 0.55, 0.20, 1.0)
		RunManager.NODE_REWARD:
			type_color = Color(1.0, 0.80, 0.24, 1.0)
		RunManager.NODE_SPECIAL:
			type_color = Color(0.70, 0.36, 1.0, 1.0)
	if node_type == RunManager.NODE_SPECIAL and RunManager.is_special_bonus_active(node_id):
		return Color(0.18, 1.0, 0.76, 1.0)
	if RunManager.is_node_completed(node_id):
		return type_color.lerp(Color(0.20, 0.84, 0.46, 1.0), 0.58)
	if RunManager.is_node_accessible(node_id):
		return type_color
	if RunManager.is_alert_active():
		return Color(0.28, 0.10, 0.12, 1.0)
	return type_color.darkened(0.63)


func _node_display_name(node_type: String) -> String:
	match node_type:
		RunManager.NODE_BATTLE:
			return "战斗"
		RunManager.NODE_EVENT:
			return "事件"
		RunManager.NODE_REWARD:
			return "补给"
		RunManager.NODE_SPECIAL:
			return "信标"
	return "未知"


func _get_node_radius(node_id: int, node_type: String) -> float:
	if node_id == RunManager.CENTER_ID:
		return CENTER_RADIUS
	if node_type == RunManager.NODE_SPECIAL:
		return SPECIAL_RADIUS
	return NODE_RADIUS


func _node_at_position(position: Vector2) -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		var center := _world_to_screen(node.get("position", Vector2.ZERO))
		var radius := _get_node_radius(node_id, node_type) * _zoom
		if center.distance_to(position) <= radius + 10.0:
			return node_id
	return -1


func _update_hovered_node(mouse_position: Vector2) -> void:
	var hovered_node_id := _node_at_position(mouse_position)
	if hovered_node_id == _hovered_node_id:
		return
	_hovered_node_id = hovered_node_id
	_link_routes.clear()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _hovered_node_id >= 0 else Control.CURSOR_DRAG
	queue_redraw()


func _zoom_at(cursor_position: Vector2, target_zoom: float) -> void:
	var world_at_cursor := _screen_to_world(cursor_position)
	_zoom = clampf(target_zoom, MIN_ZOOM, MAX_ZOOM)
	_pan_offset = cursor_position - size * 0.5 - (world_at_cursor - _map_center()) * _zoom
	_link_routes.clear()
	_clamp_pan()
	queue_redraw()


func _world_to_screen(world_position: Vector2) -> Vector2:
	return (world_position - _map_center()) * _zoom + size * 0.5 + _pan_offset


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return (screen_position - size * 0.5 - _pan_offset) / _zoom + _map_center()


func _map_center() -> Vector2:
	var center_node := RunManager.get_map_node(RunManager.CENTER_ID)
	return center_node.get("position", Vector2(700.0, 590.0)) if not center_node.is_empty() else Vector2(700.0, 590.0)


func _map_bounds() -> Rect2:
	if RunManager.map_nodes.is_empty():
		return Rect2(_map_center() - Vector2.ONE, Vector2.ONE * 2.0)
	var first_position: Vector2 = RunManager.map_nodes[0].get("position", _map_center())
	var bounds := Rect2(first_position, Vector2.ZERO)
	for node in RunManager.map_nodes:
		bounds = bounds.expand(node.get("position", first_position))
	return bounds.grow(64.0)


func _clamp_pan() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var bounds := _map_bounds()
	var center := _map_center()
	var scaled_min := (bounds.position - center) * _zoom + size * 0.5
	var scaled_max := (bounds.end - center) * _zoom + size * 0.5
	_pan_offset.x = _clamp_pan_axis(_pan_offset.x, scaled_min.x, scaled_max.x, size.x)
	_pan_offset.y = _clamp_pan_axis(_pan_offset.y, scaled_min.y, scaled_max.y, size.y)


func _clamp_pan_axis(value: float, content_min: float, content_max: float, viewport_length: float) -> float:
	var lower := PAN_EDGE_VISIBLE - content_max
	var upper := viewport_length - PAN_EDGE_VISIBLE - content_min
	if lower > upper:
		return viewport_length * 0.5 - (content_min + content_max) * 0.5
	return clampf(value, lower, upper)


func _on_resized() -> void:
	_link_routes.clear()
	_clamp_pan()
	queue_redraw()
