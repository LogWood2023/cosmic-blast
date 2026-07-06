class_name CompassMiniMap
extends Control

const DEFAULT_COMPASS_SIZE: float = 260.0
const WORLD_VIEW_RADIUS: float = 1600.0
const ROOM_SIZE: Vector2 = Vector2(10800, 10800)
const OUTLINE_SHADER := preload("res://assets/shaders/outline.gdshader")
const CIRCLE_MASK_SHADER := preload("res://assets/shaders/circle_mask.gdshader")
const COMPASS_FRAME_TEXTURE_PATH: String = "res://assets/images/ui/compass/ui/天蓝赛博指南针实心边框/天蓝赛博指南针实心边框_00_1024x1024_3eb9.png"

@export_range(120.0, 520.0, 1.0) var compass_size: float = DEFAULT_COMPASS_SIZE
@export_range(0.1, 3.0, 0.01) var compass_frame_scale: float = 0.5
@export var space_rocks_path: NodePath
@export var isolation_bands_path: NodePath
@export var electric_isolation_bands_path: NodePath
@export var rewards_path: NodePath
@export var turrets_path: NodePath
@export var evacuation_points_path: NodePath
@export var map_ui_path: NodePath
@export var player_path: NodePath
@export var chest_map_icon: Texture2D
@export var ore_vein_map_icon: Texture2D
@export var debug_logging: bool = false

var _space_rocks: Node2D
var _isolation_bands: Node2D
var _electric_isolation_bands: Node2D
var _rewards: Node2D
var _turrets: Node2D
var _evacuation_points: Node2D
var _map_ui: Control
var _player: Node2D
var _outline_material: ShaderMaterial
var _mask_material: ShaderMaterial
var _viewport: SubViewport
var _viewport_polygon: Polygon2D
var _frame_sprite: Sprite2D
var _frame_texture: Texture2D
var _drawer: CompassMiniMap
var _debug_timer: float = 0.0
var _debug_drawn_rocks: int = 0
var _debug_drawn_bands: int = 0
var _debug_drawn_rewards: int = 0
var _debug_drawn_turrets: int = 0
var _debug_drawn_electric: int = 0
var _debug_drawn_evac: int = 0
var _is_viewport_drawer: bool = false


func _ready() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_apply_exported_size()
	_space_rocks = _space_rocks if is_instance_valid(_space_rocks) else get_node_or_null(space_rocks_path)
	_isolation_bands = _isolation_bands if is_instance_valid(_isolation_bands) else get_node_or_null(isolation_bands_path)
	_electric_isolation_bands = _electric_isolation_bands if is_instance_valid(_electric_isolation_bands) else get_node_or_null(electric_isolation_bands_path)
	_rewards = _rewards if is_instance_valid(_rewards) else get_node_or_null(rewards_path)
	_turrets = _turrets if is_instance_valid(_turrets) else get_node_or_null(turrets_path)
	_evacuation_points = _evacuation_points if is_instance_valid(_evacuation_points) else get_node_or_null(evacuation_points_path)
	_map_ui = _map_ui if is_instance_valid(_map_ui) else get_node_or_null(map_ui_path)
	_player = _player if is_instance_valid(_player) else get_node_or_null(player_path)
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = OUTLINE_SHADER
	_outline_material.set_shader_parameter("outline_color", Color.WHITE)
	_outline_material.set_shader_parameter("outline_width", 24.0)
	_mask_material = ShaderMaterial.new()
	_mask_material.shader = CIRCLE_MASK_SHADER
	_mask_material.set_shader_parameter("radius", 0.5)
	_mask_material.set_shader_parameter("feather", 0.01)
	if DisplayServer.get_name() == "headless":
		_is_viewport_drawer = true
	elif not _is_viewport_drawer and not _drawer:
		_setup_masked_viewport()
	print("[指南针小地图] ready size=%s visible=%s player=%s rocks=%s bands=%s rewards=%s turrets=%s electric=%s evac=%s" % [size, visible, _node_info(_player), _node_info(_space_rocks), _node_info(_isolation_bands), _node_info(_rewards), _node_info(_turrets), _node_info(_electric_isolation_bands), _node_info(_evacuation_points)])


func _process(delta: float) -> void:
	if not _is_viewport_drawer:
		_apply_exported_size()
	_update_viewport_size()
	if debug_logging:
		_debug_timer += delta
		if _debug_timer >= 1.0:
			_debug_timer = 0.0
			_print_debug_state()
	queue_redraw()


func _draw() -> void:
	if not _is_viewport_drawer:
		return
	_reset_debug_counts()
	if not _player or not _player.visible:
		return
	var center = size * 0.5
	var compass_radius = _compass_radius()
	draw_circle(center, compass_radius + 6.0, Color(0.0, 0.0, 0.0, 0.7))
	draw_circle(center, compass_radius, Color(0.015, 0.025, 0.065, 0.92))
	_draw_clipped_world(center)
	_draw_square_to_circle_mask(center)
	_draw_edge_mask(center)
	draw_arc(center, compass_radius - 2.0, 0.0, TAU, 96, Color(1.0, 1.0, 1.0, 0.85), 3.0)
	draw_line(center + Vector2(0.0, -compass_radius + 14.0), center + Vector2(0.0, -compass_radius + 34.0), Color(1.0, 1.0, 1.0, 0.8), 3.0)
	draw_circle(center, 6.0, Color(0.2, 0.9, 1.0, 1.0))
	draw_circle(center, 10.0, Color(0.2, 0.9, 1.0, 0.35), false, 2.0)



func _apply_exported_size() -> void:
	var target_size = Vector2(compass_size, compass_size)
	custom_minimum_size = target_size
	size = target_size


func _compass_radius() -> float:
	return minf(size.x, size.y) * 0.5


func _setup_masked_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(int(size.x), int(size.y))
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_drawer = duplicate() as CompassMiniMap
	_drawer.name = "CompassMiniMapDrawer"
	_drawer.material = null
	_drawer._viewport = null
	_drawer._viewport_polygon = null
	_drawer._drawer = null
	_drawer._mask_material = null
	_drawer._is_viewport_drawer = true
	_drawer._space_rocks = _space_rocks
	_drawer._isolation_bands = _isolation_bands
	_drawer._electric_isolation_bands = _electric_isolation_bands
	_drawer._rewards = _rewards
	_drawer._turrets = _turrets
	_drawer._evacuation_points = _evacuation_points
	_drawer._map_ui = _map_ui
	_drawer._player = _player
	_drawer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_drawer.position = Vector2.ZERO
	_drawer.size = size
	_drawer.custom_minimum_size = Vector2.ZERO
	_viewport.add_child(_drawer)
	_viewport_polygon = Polygon2D.new()
	_viewport_polygon.name = "CompassMiniMapMaskedPolygon"
	_viewport_polygon.texture = _viewport.get_texture()
	_viewport_polygon.polygon = _build_circle_polygon()
	_viewport_polygon.uv = _build_circle_uvs()
	_viewport_polygon.position = Vector2.ZERO
	add_child(_viewport_polygon)
	_frame_texture = load(COMPASS_FRAME_TEXTURE_PATH) as Texture2D
	if _frame_texture:
		_frame_sprite = Sprite2D.new()
		_frame_sprite.name = "CompassFrame"
		_frame_sprite.texture = _frame_texture
		_frame_sprite.centered = true
		_frame_sprite.position = size * 0.5
		_frame_sprite.z_index = 10
		add_child(_frame_sprite)
		_update_frame_transform()


func _update_viewport_size() -> void:
	if not _viewport or not _viewport_polygon:
		return
	var target_size = Vector2i(maxi(1, int(size.x)), maxi(1, int(size.y)))
	if _viewport.size != target_size:
		_viewport.size = target_size
		_viewport_polygon.polygon = _build_circle_polygon()
		_viewport_polygon.uv = _build_circle_uvs()
	_viewport_polygon.position = Vector2.ZERO
	if _frame_sprite:
		_update_frame_transform()
	if _drawer:
		_drawer.position = Vector2.ZERO
		_drawer.size = size
		_debug_drawn_rocks = _drawer._debug_drawn_rocks
		_debug_drawn_bands = _drawer._debug_drawn_bands
		_debug_drawn_rewards = _drawer._debug_drawn_rewards
		_debug_drawn_turrets = _drawer._debug_drawn_turrets
		_debug_drawn_electric = _drawer._debug_drawn_electric
		_debug_drawn_evac = _drawer._debug_drawn_evac


func _update_frame_transform() -> void:
	if not _frame_sprite or not _frame_texture:
		return
	_frame_sprite.position = size * 0.5
	var texture_size = _frame_texture.get_size()
	var frame_midline_diameter = texture_size.x * 0.25
	var target_midline_diameter = minf(size.x, size.y)
	var scale_value = target_midline_diameter / maxf(1.0, frame_midline_diameter) * compass_frame_scale
	_frame_sprite.scale = Vector2.ONE * scale_value


func _build_circle_polygon() -> PackedVector2Array:
	var points = PackedVector2Array()
	var center = size * 0.5
	points.append(center)
	for i in range(97):
		var angle = TAU * float(i) / 96.0
		points.append(center + Vector2(cos(angle), sin(angle)) * minf(size.x, size.y) * 0.5)
	return points


func _build_circle_uvs() -> PackedVector2Array:
	var points = PackedVector2Array()
	var center = size * 0.5
	points.append(center)
	for i in range(97):
		var angle = TAU * float(i) / 96.0
		points.append(center + Vector2(cos(angle), sin(angle)) * minf(size.x, size.y) * 0.5)
	return points


func _update_mask_params() -> void:
	if not _mask_material:
		return
	_mask_material.set_shader_parameter("center_local", size * 0.5)
	_mask_material.set_shader_parameter("radius_px", minf(size.x, size.y) * 0.5)
	_mask_material.set_shader_parameter("feather_px", 2.0)


func _draw_square_to_circle_mask(center: Vector2) -> void:
	var points = 96
	var cover_color = Color(0.0, 0.0, 0.0, 0.0)
	var outer_top_left = PackedVector2Array()
	outer_top_left.append(Vector2.ZERO)
	outer_top_left.append(Vector2(size.x, 0.0))
	for i in range(points + 1):
		var angle = lerpf(0.0, PI, float(i) / float(points))
		outer_top_left.append(center + Vector2(cos(angle), sin(angle)) * _compass_radius())
	draw_colored_polygon(outer_top_left, cover_color)
	var outer_bottom = PackedVector2Array()
	outer_bottom.append(Vector2(size.x, size.y))
	outer_bottom.append(Vector2(0.0, size.y))
	for i in range(points + 1):
		var angle = lerpf(PI, TAU, float(i) / float(points))
		outer_bottom.append(center + Vector2(cos(angle), sin(angle)) * _compass_radius())
	draw_colored_polygon(outer_bottom, cover_color)


func _draw_edge_mask(center: Vector2) -> void:
	var ring_count = 14
	for i in range(ring_count):
		var t = float(i) / float(ring_count - 1)
		var radius = lerpf(_compass_radius() - 18.0, _compass_radius() + 10.0, t)
		var alpha = lerpf(0.15, 0.95, t)
		draw_arc(center, radius, 0.0, TAU, 128, Color(0.0, 0.0, 0.0, alpha), 4.0)


func _draw_clipped_world(center: Vector2) -> void:
	var player_pos = _player.global_position
	if _isolation_bands:
		for band in _isolation_bands.get_children():
			if is_instance_valid(band):
				_draw_band(band, center, player_pos)
	if _space_rocks:
		for rock in _space_rocks.get_children():
			if is_instance_valid(rock):
				_draw_rock(rock, center, player_pos)
	_draw_patrol_paths(center, player_pos)
	_draw_static_enemy_icons(center, player_pos)
	_draw_rewards(center, player_pos)
	_draw_turrets(center, player_pos)
	_draw_electric_endpoints(center, player_pos)
	_draw_evacuation_points(center, player_pos)


func _draw_rock(rock: Node2D, center: Vector2, player_pos: Vector2) -> void:
	var sprite = rock.get_node_or_null("Sprite2D")
	if not sprite or not sprite is Sprite2D or not sprite.texture:
		return
	var rock_pos = rock.get_base_position() if rock.has_method("get_base_position") else rock.global_position
	if not _is_world_pos_explored(rock_pos):
		return
	var local = _world_to_compass(rock_pos, center, player_pos)
	if not _is_inside_compass(local, _compass_radius() + 80.0):
		return
	_debug_drawn_rocks += 1
	var radius: float = rock.get("radius") if rock.get("radius") != null else 0.0
	var diameter = radius * 2.0 * _world_scale()
	var visual_rotation: float = rock.get("visual_rotation") if rock.get("visual_rotation") != null else 0.0
	draw_set_transform(local, visual_rotation, Vector2.ONE)
	draw_texture_rect(sprite.texture, Rect2(Vector2(-diameter, -diameter) * 0.5, Vector2(diameter, diameter)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_band(band: Node2D, center: Vector2, player_pos: Vector2) -> void:
	if not band.has_method("get_map_start") or not band.has_method("get_map_end"):
		return
	var start_world: Vector2 = band.get_map_start()
	var end_world: Vector2 = band.get_map_end()
	if not _is_world_pos_explored(start_world) and not _is_world_pos_explored(end_world):
		return
	var start = _world_to_compass(start_world, center, player_pos)
	var end = _world_to_compass(end_world, center, player_pos)
	if not _segment_may_touch_compass(start, end):
		return
	_debug_drawn_bands += 1
	var width = maxf(1.0, band.get_map_width() * _world_scale()) if band.has_method("get_map_width") else 2.0
	var texture = band.get_map_texture() if band.has_method("get_map_texture") else null
	if texture:
		var length = start.distance_to(end)
		var mid = (start + end) * 0.5
		var region_size = band.get_texture_region_size() if band.has_method("get_texture_region_size") else texture.get_size()
		draw_set_transform(mid, (end - start).angle(), Vector2.ONE)
		draw_texture_rect_region(texture, Rect2(Vector2(-length * 0.5, -width * 0.5), Vector2(length, width)), Rect2(Vector2.ZERO, region_size))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_line(start, end, Color.WHITE, width)


func _draw_rewards(center: Vector2, player_pos: Vector2) -> void:
	if not _rewards:
		return
	for reward in _rewards.get_children():
		if not is_instance_valid(reward):
			continue
		var reward_type = int(reward.get_reward_type()) if reward.has_method("get_reward_type") else 0
		var tex: Texture2D = chest_map_icon if reward_type == 0 else ore_vein_map_icon
		if not tex and reward.has_method("get_reward_sprite_texture"):
			tex = reward.get_reward_sprite_texture()
		if not tex:
			continue
		var pos = reward.get_base_position() if reward.has_method("get_base_position") else reward.global_position
		if not _is_world_pos_explored(pos):
			continue
		if _draw_icon(tex, pos, center, player_pos, Vector2(28.0, 28.0), 0.0, false):
			_debug_drawn_rewards += 1


func _draw_turrets(center: Vector2, player_pos: Vector2) -> void:
	if not _turrets:
		return
	for turret in _turrets.get_children():
		if not is_instance_valid(turret) or not turret.has_method("get_map_icon_texture"):
			continue
		var tex = turret.get_map_icon_texture()
		if not tex:
			continue
		var pos = turret.get_map_position() if turret.has_method("get_map_position") else turret.global_position
		if not _is_world_pos_explored(pos):
			continue
		var rot = turret.get_map_icon_rotation() if turret.has_method("get_map_icon_rotation") else 0.0
		if _draw_icon(tex, pos, center, player_pos, Vector2(32.0, 32.0), rot, false):
			_debug_drawn_turrets += 1


func _draw_electric_endpoints(center: Vector2, player_pos: Vector2) -> void:
	if not _electric_isolation_bands:
		return
	for band in _electric_isolation_bands.get_children():
		if not is_instance_valid(band) or not band.has_method("get_map_endpoints"):
			continue
		for endpoint in band.get_map_endpoints():
			var tex: Texture2D = endpoint.get("texture")
			if not tex:
				continue
			var pos: Vector2 = endpoint.get("position", Vector2.ZERO)
			if not _is_world_pos_explored(pos):
				continue
			var rot: float = endpoint.get("rotation", 0.0)
			if _draw_icon(tex, pos, center, player_pos, Vector2(28.0, 28.0), rot, false):
				_debug_drawn_electric += 1


func _draw_evacuation_points(center: Vector2, player_pos: Vector2) -> void:
	if not _evacuation_points:
		return
	for point in _evacuation_points.get_children():
		if not is_instance_valid(point):
			continue
		var tex: Texture2D = point.get("icon_texture") if point.get("icon_texture") != null else null
		if not _is_world_pos_explored(point.global_position):
			continue
		if tex and _draw_icon(tex, point.global_position, center, player_pos, Vector2(36.0, 36.0), 0.0, true):
			_debug_drawn_evac += 1


func _is_world_pos_explored(pos: Vector2) -> bool:
	if is_instance_valid(_map_ui) and _map_ui.has_method("is_world_position_explored"):
		return _map_ui.is_world_position_explored(pos)
	return true


func _draw_patrol_paths(center: Vector2, player_pos: Vector2) -> void:
	if not is_instance_valid(_map_ui):
		return
	if not _map_ui.has_method("is_patrol_spawn_mode_enabled") or not _map_ui.is_patrol_spawn_mode_enabled():
		return
	if not _map_ui.has_method("get_patrol_paths"):
		return
	for path in _map_ui.get_patrol_paths():
		if path.size() < 2:
			continue
		var points = PackedVector2Array()
		for world_point in path:
			points.append(_world_to_compass(world_point, center, player_pos))
		var visible_segment = false
		for i in range(points.size() - 1):
			if _segment_may_touch_compass(points[i], points[i + 1]):
				visible_segment = true
				break
		if not visible_segment:
			continue
		draw_polyline(points, Color(1.0, 0.06, 0.02, 0.92), 3.0, true)
		draw_circle(points[0], 4.0, Color(0.25, 1.0, 0.3, 0.95))
		draw_circle(points[points.size() - 1], 4.0, Color(1.0, 0.25, 0.15, 0.95))


func _draw_static_enemy_icons(center: Vector2, player_pos: Vector2) -> void:
	if not is_instance_valid(_map_ui) or not _map_ui.has_method("get_static_enemy_icons"):
		return
	for icon in _map_ui.get_static_enemy_icons():
		var tex: Texture2D = icon.get("texture")
		var pos: Vector2 = icon.get("position", Vector2.ZERO)
		if not tex or not _is_world_pos_explored(pos):
			continue
		if _draw_icon(tex, pos, center, player_pos, Vector2(34.0, 34.0), 0.0, true):
			_debug_drawn_rewards += 1


func _draw_icon(tex: Texture2D, world_pos: Vector2, center: Vector2, player_pos: Vector2, draw_size: Vector2, rotation: float, outlined: bool) -> bool:
	var pos = _world_to_compass(world_pos, center, player_pos)
	var half_diagonal = draw_size.length() * 0.5
	if not _is_inside_compass(pos, _compass_radius() + half_diagonal):
		return false
	var rect = Rect2(-draw_size * 0.5, draw_size)
	if outlined:
		_draw_icon_outline(tex, pos, rect, rotation)
	else:
		draw_set_transform(pos, rotation, Vector2.ONE)
		draw_texture_rect(tex, rect, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


func _draw_icon_outline(tex: Texture2D, pos: Vector2, rect: Rect2, rotation: float) -> void:
	draw_set_transform(pos, rotation, Vector2.ONE)
	var offsets = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1.0, -1.0).normalized(), Vector2(1.0, -1.0).normalized(), Vector2(-1.0, 1.0).normalized(), Vector2(1.0, 1.0).normalized()]
	for offset in offsets:
		draw_texture_rect(tex, Rect2(rect.position + offset * 4.0, rect.size), false, Color.WHITE)
	draw_texture_rect(tex, rect, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _reset_debug_counts() -> void:
	_debug_drawn_rocks = 0
	_debug_drawn_bands = 0
	_debug_drawn_rewards = 0
	_debug_drawn_turrets = 0
	_debug_drawn_electric = 0
	_debug_drawn_evac = 0


func _node_info(node: Node) -> String:
	if not is_instance_valid(node):
		return "null"
	return "%s children=%d visible=%s" % [node.name, node.get_child_count(), node.visible if node is CanvasItem else true]


func _print_debug_state() -> void:
	var player_info = "null"
	if is_instance_valid(_player):
		player_info = "pos=%s visible=%s" % [_player.global_position, _player.visible]
	print("[指南针小地图] state drawer=%s viewport=%s viewport_polygon=%s tex=%s size=%s global_rect=%s player=%s mask_center=%s radius=%.1f nodes rocks=%d bands=%d rewards=%d turrets=%d electric_bands=%d evac=%d drawn rocks=%d bands=%d rewards=%d turrets=%d electric=%d evac=%d" % [
		_node_info(_drawer),
		_node_info(_viewport),
		_node_info(_viewport_polygon),
		_viewport_polygon.texture != null if is_instance_valid(_viewport_polygon) else false,
		size,
		get_global_rect(),
		player_info,
		size * 0.5,
		minf(size.x, size.y) * 0.5,
		_space_rocks.get_child_count() if is_instance_valid(_space_rocks) else -1,
		_isolation_bands.get_child_count() if is_instance_valid(_isolation_bands) else -1,
		_rewards.get_child_count() if is_instance_valid(_rewards) else -1,
		_turrets.get_child_count() if is_instance_valid(_turrets) else -1,
		_electric_isolation_bands.get_child_count() if is_instance_valid(_electric_isolation_bands) else -1,
		_evacuation_points.get_child_count() if is_instance_valid(_evacuation_points) else -1,
		_debug_drawn_rocks,
		_debug_drawn_bands,
		_debug_drawn_rewards,
		_debug_drawn_turrets,
		_debug_drawn_electric,
		_debug_drawn_evac,
	])


func _world_to_compass(world_pos: Vector2, center: Vector2, player_pos: Vector2) -> Vector2:
	return center + (world_pos - player_pos) * _world_scale()


func _world_scale() -> float:
	return _compass_radius() / WORLD_VIEW_RADIUS


func _is_inside_compass(pos: Vector2, radius: float) -> bool:
	return pos.distance_to(size * 0.5) <= radius


func _segment_may_touch_compass(start: Vector2, end: Vector2) -> bool:
	var center = size * 0.5
	if _is_inside_compass(start, _compass_radius()) or _is_inside_compass(end, _compass_radius()):
		return true
	var closest = Geometry2D.get_closest_point_to_segment(center, start, end)
	return center.distance_to(closest) <= _compass_radius()
