extends Control

const VIEW_SIZE: Vector2 = Vector2(1920, 1080)
# 房间是正方形，地图显示区也用正方形，使内容与边框完全重合、整图一屏显示（无需纵向滚动）
const MAP_SIZE: Vector2 = Vector2(864, 864)
const ROOM_SIZE: Vector2 = Vector2(10800, 10800)
const OUTLINE_SHADER := preload("res://assets/shaders/outline.gdshader")
const FOG_CELL_WORLD_SIZE: float = 240.0
const FOG_REVEAL_RADIUS: float = 720.0
const DANGER_RED := Color("#ff4f6a")
const FURNACE_AMBER := Color("#ffb84d")
const COMMAND_CYAN := Color("#52e8ff")
const VOID_VIOLET := Color("#b78cff")
const DEEP_PANEL := Color("#071018")
const TEXT_MAIN := Color("#f8fbff")
const TEXT_MUTED := Color("#b7c4cf")

@export var space_rocks_path: NodePath
@export var isolation_bands_path: NodePath
@export var electric_isolation_bands_path: NodePath
@export var rewards_path: NodePath
@export var turrets_path: NodePath
@export var evacuation_points_path: NodePath
@export var player_path: NodePath
@export var chest_map_icon: Texture2D
@export var ore_vein_map_icon: Texture2D

var _space_rocks: Node2D
var _isolation_bands: Node2D
var _electric_isolation_bands: Node2D
var _rewards: Node2D
var _turrets: Node2D
var _evacuation_points: Node2D
var _player: Node2D
var _content_offset_y: float = 0.0
var _dragging: bool = false
var _drag_start_mouse_y: float = 0.0
var _drag_start_offset_y: float = 0.0
var _outline_material: ShaderMaterial
var _reward_rects: Array[TextureRect] = []
var _turret_rects: Array[TextureRect] = []
var _electric_endpoint_rects: Array[TextureRect] = []
var _evacuation_rects: Array[TextureRect] = []
var _static_enemy_rects: Array[TextureRect] = []
var _explored_cells: Dictionary = {}
var _fog_tracking_started: bool = false
var _fog_cols: int = int(ceil(ROOM_SIZE.x / FOG_CELL_WORLD_SIZE))
var _fog_rows: int = int(ceil(ROOM_SIZE.y / FOG_CELL_WORLD_SIZE))
var _fog_cleared: bool = false
var _patrol_paths: Array[PackedVector2Array] = []
var _static_enemy_icons: Array[Dictionary] = []
var show_turret_traps: bool = false
var show_patrol_spawns: bool = false


func _ready() -> void:
	add_to_group(&"map_ui")
	size = VIEW_SIZE
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_space_rocks = get_node_or_null(space_rocks_path)
	_isolation_bands = get_node_or_null(isolation_bands_path)
	_electric_isolation_bands = get_node_or_null(electric_isolation_bands_path)
	_rewards = get_node_or_null(rewards_path)
	_turrets = get_node_or_null(turrets_path)
	_evacuation_points = get_node_or_null(evacuation_points_path)
	_player = get_node_or_null(player_path)
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = OUTLINE_SHADER
	_outline_material.set_shader_parameter("outline_color", Color.WHITE)
	_outline_material.set_shader_parameter("outline_width", 40.0)


func _process(_delta: float) -> void:
	_mark_player_area_explored()
	if visible:
		queue_redraw()
		_sync_reward_rects()
		_sync_turret_rects()
		_sync_electric_endpoint_rects()
		_sync_evacuation_rects()
		_sync_static_enemy_rects()


func toggle() -> void:
	visible = not visible
	if visible:
		_center_on_player_y()
		queue_redraw()
		_sync_reward_rects()
		_sync_turret_rects()
		_sync_electric_endpoint_rects()
		_sync_evacuation_rects()
		_sync_static_enemy_rects()
	else:
		for rect in _reward_rects:
			rect.visible = false
		for rect in _turret_rects:
			rect.visible = false
		for rect in _electric_endpoint_rects:
			rect.visible = false
		for rect in _evacuation_rects:
			rect.visible = false
		for rect in _static_enemy_rects:
			rect.visible = false


func set_turret_trap_mode(enabled: bool) -> void:
	show_turret_traps = enabled
	if visible:
		queue_redraw()
		_sync_turret_rects()
		_sync_electric_endpoint_rects()


func toggle_turret_trap_mode() -> bool:
	set_turret_trap_mode(not show_turret_traps)
	return show_turret_traps


func set_patrol_paths(paths: Array[PackedVector2Array]) -> void:
	_patrol_paths.clear()
	for path in paths:
		_patrol_paths.append(path.duplicate())
	if visible:
		queue_redraw()


func get_patrol_paths() -> Array[PackedVector2Array]:
	return _patrol_paths


func set_patrol_spawn_mode(enabled: bool) -> void:
	show_patrol_spawns = enabled
	if visible:
		queue_redraw()


func toggle_patrol_spawn_mode() -> bool:
	set_patrol_spawn_mode(not show_patrol_spawns)
	return show_patrol_spawns


func is_patrol_spawn_mode_enabled() -> bool:
	return show_patrol_spawns


func clear_fog() -> void:
	_fog_cleared = true
	_explored_cells.clear()
	_fog_tracking_started = true
	if visible:
		queue_redraw()
		_sync_reward_rects()
		_sync_turret_rects()
		_sync_electric_endpoint_rects()
		_sync_evacuation_rects()
		_sync_static_enemy_rects()


func set_static_enemy_icons(icons: Array[Dictionary]) -> void:
	_static_enemy_icons.clear()
	for icon in icons:
		_static_enemy_icons.append(icon.duplicate())
	if visible:
		queue_redraw()
		_sync_static_enemy_rects()


func get_static_enemy_icons() -> Array[Dictionary]:
	return _static_enemy_icons


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _map_rect().has_point(event.position):
			_dragging = true
			_drag_start_mouse_y = event.position.y
			_drag_start_offset_y = _content_offset_y
		elif not event.pressed:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		_content_offset_y = _drag_start_offset_y + event.position.y - _drag_start_mouse_y
		_clamp_offset()
		queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var rect = _map_rect()
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.005, 0.008, 0.012, 0.72), true)
	_draw_map_shell(rect)
	var content_origin = rect.position + Vector2(0, _content_offset_y)
	draw_set_transform(content_origin, 0.0, Vector2.ONE)
	_draw_map_content()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_map_overlay(rect)


func _draw_map_shell(rect: Rect2) -> void:
	var outer := rect.grow(24.0)
	draw_rect(outer, Color(0.02, 0.045, 0.07, 0.94), true)
	draw_rect(outer, FURNACE_AMBER.darkened(0.15), false, 3.0)
	draw_rect(outer.grow(-6.0), Color(DANGER_RED.r, DANGER_RED.g, DANGER_RED.b, 0.58), false, 2.0)
	draw_rect(rect, Color(0.015, 0.025, 0.065, 0.96), true)
	draw_line(outer.position + Vector2(0.0, 18.0), outer.position + Vector2(outer.size.x, 18.0), DANGER_RED, 4.0)
	draw_line(outer.position + Vector2(18.0, 0.0), outer.position + Vector2(18.0, outer.size.y), Color(DANGER_RED.r, DANGER_RED.g, DANGER_RED.b, 0.65), 2.0)


func _draw_map_overlay(rect: Rect2) -> void:
	var font := get_theme_default_font()
	var title_pos := rect.position + Vector2(0.0, -46.0)
	var title_rect := Rect2(title_pos, Vector2(rect.size.x, 36.0))
	draw_rect(title_rect, Color(0.027, 0.063, 0.094, 0.9), true)
	draw_rect(title_rect, Color(COMMAND_CYAN.r, COMMAND_CYAN.g, COMMAND_CYAN.b, 0.36), false, 1.0)
	draw_string(font, title_pos + Vector2(18.0, 25.0), "深空战术地图", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, TEXT_MAIN)
	draw_string(font, title_pos + Vector2(rect.size.x - 200.0, 25.0), "已探索区域高亮", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, TEXT_MUTED)

	var legend_pos := rect.position + Vector2(0.0, rect.size.y + 18.0)
	var legend_rect := Rect2(legend_pos, Vector2(rect.size.x, 34.0))
	draw_rect(legend_rect, Color(0.027, 0.063, 0.094, 0.88), true)
	draw_rect(legend_rect, Color(FURNACE_AMBER.r, FURNACE_AMBER.g, FURNACE_AMBER.b, 0.42), false, 1.0)
	_draw_legend_item(font, legend_pos + Vector2(20.0, 22.0), COMMAND_CYAN, "玩家")
	_draw_legend_item(font, legend_pos + Vector2(150.0, 22.0), FURNACE_AMBER, "资源")
	_draw_legend_item(font, legend_pos + Vector2(280.0, 22.0), DANGER_RED, "巡逻/炮塔")
	_draw_legend_item(font, legend_pos + Vector2(440.0, 22.0), VOID_VIOLET, "异常区域")


func _draw_legend_item(font: Font, baseline: Vector2, color: Color, text: String) -> void:
	draw_circle(baseline + Vector2(8.0, -8.0), 6.0, color)
	draw_string(font, baseline + Vector2(22.0, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, TEXT_MUTED)


func _draw_map_content() -> void:
	var scale = MAP_SIZE.x / ROOM_SIZE.x
	var content_height = ROOM_SIZE.y * scale
	draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_SIZE.x, content_height)), Color(0.02, 0.04, 0.11, 1.0), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_SIZE.x, content_height)), Color(0.18, 0.32, 0.65, 0.55), false, 2.0)
	if _isolation_bands:
		for band in _isolation_bands.get_children():
			if is_instance_valid(band):
				_draw_isolation_band(band, scale)
	if _space_rocks:
		for rock in _space_rocks.get_children():
			if is_instance_valid(rock):
				_draw_space_rock_sprite(rock, scale)
	_draw_fog_overlay(scale, content_height)
	if show_patrol_spawns:
		_draw_patrol_paths(scale)
	if _player:
		var player_p = _player.global_position * scale
		draw_circle(player_p, 8.0, Color(0.2, 0.9, 1.0, 1.0))
		draw_circle(player_p, 12.0, Color(0.2, 0.9, 1.0, 0.35), false, 2.0)


func _sync_reward_rects() -> void:
	if not _rewards:
		return
	var reward_nodes: Array[Node] = []
	for child in _rewards.get_children():
		if is_instance_valid(child):
			reward_nodes.append(child)

	while _reward_rects.size() > reward_nodes.size():
		var rect = _reward_rects.pop_back()
		rect.queue_free()

	while _reward_rects.size() < reward_nodes.size():
		var rect = TextureRect.new()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.material = _outline_material
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_reward_rects.append(rect)

	var scale = MAP_SIZE.x / ROOM_SIZE.x
	var content_origin = _map_rect().position + Vector2(0, _content_offset_y)
	for i in range(reward_nodes.size()):
		var reward = reward_nodes[i]
		var rect = _reward_rects[i]
		var reward_type_enum = 0
		var reward_texture: Texture2D = null
		if reward.has_method("get_reward_type"):
			reward_type_enum = int(reward.get_reward_type())
		if reward.has_method("get_reward_sprite_texture"):
			reward_texture = reward.get_reward_sprite_texture()
		var icon: Texture2D = chest_map_icon if reward_type_enum == 0 else ore_vein_map_icon
		var texture_to_draw = icon if icon else reward_texture
		if not texture_to_draw:
			rect.visible = false
			continue
		var reward_pos = reward.get_base_position() if reward.has_method("get_base_position") else reward.global_position
		if not _is_world_pos_explored(reward_pos):
			rect.visible = false
			continue
		rect.visible = true
		rect.texture = texture_to_draw
		var tex_size = texture_to_draw.get_size()
		var icon_size = maxf(64.0, maxf(tex_size.x, tex_size.y) * scale * 0.15)
		var aspect = tex_size.x / maxf(1.0, tex_size.y)
		var draw_size = Vector2(icon_size * maxf(1.0, aspect), icon_size * maxf(1.0, 1.0 / aspect))
		rect.position = content_origin + reward_pos * scale - draw_size * 0.5
		rect.size = draw_size


func _sync_turret_rects() -> void:
	if not show_turret_traps:
		for rect in _turret_rects:
			rect.visible = false
		return
	if not _turrets:
		return
	var turret_nodes: Array[Node] = []
	for child in _turrets.get_children():
		if is_instance_valid(child):
			turret_nodes.append(child)

	while _turret_rects.size() > turret_nodes.size():
		var rect = _turret_rects.pop_back()
		rect.queue_free()

	while _turret_rects.size() < turret_nodes.size():
		var rect = TextureRect.new()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.material = _outline_material
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_rects_append_turret(rect)

	var scale = MAP_SIZE.x / ROOM_SIZE.x
	var content_origin = _map_rect().position + Vector2(0, _content_offset_y)
	for i in range(turret_nodes.size()):
		var turret = turret_nodes[i]
		var rect = _turret_rects[i]
		var tex: Texture2D = null
		if turret.has_method("get_map_icon_texture"):
			tex = turret.get_map_icon_texture()
		if not tex:
			rect.visible = false
			continue
		rect.visible = true
		rect.texture = tex
		var turret_pos = turret.get_map_position() if turret.has_method("get_map_position") else turret.global_position
		if not _is_world_pos_explored(turret_pos):
			rect.visible = false
			continue
		var size = Vector2(64.0, 64.0)
		rect.position = content_origin + turret_pos * scale - size * 0.5
		rect.size = size
		rect.pivot_offset = size * 0.5
		rect.rotation = turret.get_map_icon_rotation() if turret.has_method("get_map_icon_rotation") else -PI * 0.5


func _sync_electric_endpoint_rects() -> void:
	if not show_turret_traps:
		for rect in _electric_endpoint_rects:
			rect.visible = false
		return
	if not _electric_isolation_bands:
		for rect in _electric_endpoint_rects:
			rect.visible = false
		return
	var endpoints: Array[Dictionary] = []
	for band in _electric_isolation_bands.get_children():
		if is_instance_valid(band) and band.has_method("get_map_endpoints"):
			for endpoint in band.get_map_endpoints():
				endpoints.append(endpoint)

	while _electric_endpoint_rects.size() > endpoints.size():
		var rect = _electric_endpoint_rects.pop_back()
		rect.queue_free()

	while _electric_endpoint_rects.size() < endpoints.size():
		var rect = TextureRect.new()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.material = _outline_material
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_electric_endpoint_rects.append(rect)

	var scale = MAP_SIZE.x / ROOM_SIZE.x
	var content_origin = _map_rect().position + Vector2(0, _content_offset_y)
	for i in range(endpoints.size()):
		var endpoint = endpoints[i]
		var rect = _electric_endpoint_rects[i]
		var tex: Texture2D = endpoint.get("texture")
		if not tex:
			rect.visible = false
			continue
		var pos: Vector2 = endpoint.get("position", Vector2.ZERO)
		if not _is_world_pos_explored(pos):
			rect.visible = false
			continue
		var rot: float = endpoint.get("rotation", 0.0)
		var endpoint_size = float(endpoint.get("map_size", float(endpoint.get("size", 96.0)) * 0.25))
		var tex_size = tex.get_size()
		var icon_size = maxf(endpoint_size, maxf(tex_size.x, tex_size.y) * scale * 0.15)
		var aspect = tex_size.x / maxf(1.0, tex_size.y)
		var draw_size = Vector2(icon_size * maxf(1.0, aspect), icon_size * maxf(1.0, 1.0 / aspect))
		rect.visible = true
		rect.texture = tex
		rect.position = content_origin + pos * scale - draw_size * 0.5
		rect.size = draw_size
		rect.pivot_offset = draw_size * 0.5
		rect.rotation = rot


func _sync_evacuation_rects() -> void:
	if not _evacuation_points:
		for rect in _evacuation_rects:
			rect.visible = false
		return
	var nodes: Array[Node] = []
	for child in _evacuation_points.get_children():
		if is_instance_valid(child):
			nodes.append(child)
	while _evacuation_rects.size() > nodes.size():
		var rect = _evacuation_rects.pop_back()
		rect.queue_free()
	while _evacuation_rects.size() < nodes.size():
		var rect = TextureRect.new()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.material = _outline_material
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_evacuation_rects.append(rect)
	var scale = MAP_SIZE.x / ROOM_SIZE.x
	var content_origin = _map_rect().position + Vector2(0, _content_offset_y)
	for i in range(nodes.size()):
		var point = nodes[i]
		var rect = _evacuation_rects[i]
		var tex: Texture2D = point.get("icon_texture") if point.get("icon_texture") != null else null
		if not tex or not _is_world_pos_explored(point.global_position):
			rect.visible = false
			continue
		var size = Vector2(64.0, 64.0)
		rect.visible = true
		rect.texture = tex
		rect.position = content_origin + point.global_position * scale - size * 0.5
		rect.size = size
		rect.pivot_offset = size * 0.5
		rect.rotation = 0.0


func _sync_static_enemy_rects() -> void:
	while _static_enemy_rects.size() > _static_enemy_icons.size():
		var rect = _static_enemy_rects.pop_back()
		rect.queue_free()
	while _static_enemy_rects.size() < _static_enemy_icons.size():
		var rect = TextureRect.new()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.material = _outline_material
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_static_enemy_rects.append(rect)
	var scale = MAP_SIZE.x / ROOM_SIZE.x
	var content_origin = _map_rect().position + Vector2(0, _content_offset_y)
	for i in range(_static_enemy_icons.size()):
		var icon = _static_enemy_icons[i]
		var rect = _static_enemy_rects[i]
		var tex: Texture2D = icon.get("texture")
		var pos: Vector2 = icon.get("position", Vector2.ZERO)
		if not tex or not _is_world_pos_explored(pos):
			rect.visible = false
			continue
		var tex_size = tex.get_size()
		var icon_size = maxf(64.0, maxf(tex_size.x, tex_size.y) * scale * 0.16)
		var aspect = tex_size.x / maxf(1.0, tex_size.y)
		var draw_size = Vector2(icon_size * maxf(1.0, aspect), icon_size * maxf(1.0, 1.0 / aspect))
		rect.visible = true
		rect.texture = tex
		rect.position = content_origin + pos * scale - draw_size * 0.5
		rect.size = draw_size
		rect.pivot_offset = draw_size * 0.5
		rect.rotation = 0.0


func _rects_append_turret(rect: TextureRect) -> void:
	_turret_rects.append(rect)


func _mark_player_area_explored() -> void:
	if _fog_cleared:
		return
	if not _player or not _player.visible:
		return
	if not _fog_tracking_started:
		_explored_cells.clear()
		_fog_tracking_started = true
	var center_cell = Vector2i(
		clampi(int(floor(_player.global_position.x / FOG_CELL_WORLD_SIZE)), 0, _fog_cols - 1),
		clampi(int(floor(_player.global_position.y / FOG_CELL_WORLD_SIZE)), 0, _fog_rows - 1)
	)
	var cell_radius = int(ceil(FOG_REVEAL_RADIUS / FOG_CELL_WORLD_SIZE))
	for y in range(center_cell.y - cell_radius, center_cell.y + cell_radius + 1):
		if y < 0 or y >= _fog_rows:
			continue
		for x in range(center_cell.x - cell_radius, center_cell.x + cell_radius + 1):
			if x < 0 or x >= _fog_cols:
				continue
			var cell_center = Vector2(float(x) + 0.5, float(y) + 0.5) * FOG_CELL_WORLD_SIZE
			if cell_center.distance_to(_player.global_position) <= FOG_REVEAL_RADIUS:
				_explored_cells[_fog_key(x, y)] = true


func _draw_fog_overlay(scale: float, content_height: float) -> void:
	if _fog_cleared:
		return
	var cell_size = FOG_CELL_WORLD_SIZE * scale
	for y in range(_fog_rows):
		for x in range(_fog_cols):
			if _explored_cells.has(_fog_key(x, y)):
				continue
			var pos = Vector2(float(x), float(y)) * cell_size
			var size = Vector2(cell_size + 1.0, cell_size + 1.0)
			if pos.y > content_height:
				continue
			draw_rect(Rect2(pos, size), Color(0.0, 0.0, 0.0, 0.96), true)


func _fog_key(x: int, y: int) -> int:
	return y * _fog_cols + x


func _is_world_pos_explored(pos: Vector2) -> bool:
	if _fog_cleared:
		return true
	var x = clampi(int(floor(pos.x / FOG_CELL_WORLD_SIZE)), 0, _fog_cols - 1)
	var y = clampi(int(floor(pos.y / FOG_CELL_WORLD_SIZE)), 0, _fog_rows - 1)
	return _explored_cells.has(_fog_key(x, y))


func is_world_position_explored(pos: Vector2) -> bool:
	return _is_world_pos_explored(pos)


func _draw_patrol_paths(scale: float) -> void:
	for path in _patrol_paths:
		if path.size() < 2:
			continue
		var points = PackedVector2Array()
		for world_point in path:
			points.append(world_point * scale)
		draw_polyline(points, Color(1.0, 0.06, 0.02, 0.92), 4.0, true)
		draw_circle(points[0], 6.0, Color(0.25, 1.0, 0.3, 0.95))
		draw_circle(points[points.size() - 1], 6.0, Color(1.0, 0.25, 0.15, 0.95))


func _draw_space_rock_sprite(rock: Node2D, scale: float) -> void:
	var sprite = rock.get_node_or_null("Sprite2D")
	if not sprite or not sprite is Sprite2D or not sprite.texture:
		return
	var radius: float = rock.get("radius") if rock.get("radius") != null else 0.0
	var diameter = maxf(2.0, radius * 2.0 * scale)
	var rock_pos = rock.get_base_position() if rock.has_method("get_base_position") else rock.global_position
	if not _is_world_pos_explored(rock_pos):
		return
	var visual_rotation: float = rock.get("visual_rotation") if rock.get("visual_rotation") != null else 0.0
	var content_origin = _map_rect().position + Vector2(0, _content_offset_y)
	draw_set_transform(content_origin + rock_pos * scale, visual_rotation, Vector2.ONE)
	draw_texture_rect(sprite.texture, Rect2(Vector2(-diameter, -diameter) * 0.5, Vector2(diameter, diameter)), false)
	draw_set_transform(content_origin, 0.0, Vector2.ONE)


func _draw_isolation_band(band: Node2D, scale: float) -> void:
	if not band.has_method("get_map_start") or not band.has_method("get_map_end"):
		return
	var start = band.get_map_start() * scale
	var end = band.get_map_end() * scale
	if not _is_world_pos_explored(band.get_map_start()) and not _is_world_pos_explored(band.get_map_end()):
		return
	var width = maxf(1.0, band.get_map_width() * scale) if band.has_method("get_map_width") else 2.0
	var texture = band.get_map_texture() if band.has_method("get_map_texture") else null
	if texture:
		var length = start.distance_to(end)
		var center = (start + end) * 0.5
		var region_size = band.get_texture_region_size() if band.has_method("get_texture_region_size") else texture.get_size()
		var source = Rect2(Vector2.ZERO, region_size)
		var content_origin = _map_rect().position + Vector2(0, _content_offset_y)
		draw_set_transform(content_origin + center, (end - start).angle(), Vector2.ONE)
		draw_texture_rect_region(texture, Rect2(Vector2(-length * 0.5, -width * 0.5), Vector2(length, width)), source)
		draw_set_transform(content_origin, 0.0, Vector2.ONE)
	else:
		draw_line(start, end, Color.WHITE, width)


func _map_rect() -> Rect2:
	return Rect2((VIEW_SIZE - MAP_SIZE) * 0.5, MAP_SIZE)


func _center_on_player_y() -> void:
	if _player:
		var scale = MAP_SIZE.x / ROOM_SIZE.x
		var map_player_y = _player.global_position.y * scale
		_content_offset_y = MAP_SIZE.y * 0.5 - map_player_y
	_clamp_offset()


func _clamp_offset() -> void:
	var content_height = ROOM_SIZE.y * (MAP_SIZE.x / ROOM_SIZE.x)
	var min_offset = minf(0.0, MAP_SIZE.y - content_height)
	_content_offset_y = clampf(_content_offset_y, min_offset, 0.0)
