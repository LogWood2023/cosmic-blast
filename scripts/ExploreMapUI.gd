extends Control

const VIEW_SIZE: Vector2 = Vector2(1920, 1080)
const MAP_SIZE: Vector2 = Vector2(1536, 864)
const ROOM_SIZE: Vector2 = Vector2(10800, 10800)
const OUTLINE_SHADER := preload("res://assets/shaders/outline.gdshader")

@export var space_rocks_path: NodePath
@export var isolation_bands_path: NodePath
@export var rewards_path: NodePath
@export var turrets_path: NodePath
@export var player_path: NodePath
@export var chest_map_icon: Texture2D
@export var ore_vein_map_icon: Texture2D

var _space_rocks: Node2D
var _isolation_bands: Node2D
var _rewards: Node2D
var _turrets: Node2D
var _player: Node2D
var _content_offset_y: float = 0.0
var _dragging: bool = false
var _drag_start_mouse_y: float = 0.0
var _drag_start_offset_y: float = 0.0
var _outline_material: ShaderMaterial
var _reward_rects: Array[TextureRect] = []
var _turret_rects: Array[TextureRect] = []
var show_turret_traps: bool = false


func _ready() -> void:
	add_to_group(&"map_ui")
	size = VIEW_SIZE
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_space_rocks = get_node_or_null(space_rocks_path)
	_isolation_bands = get_node_or_null(isolation_bands_path)
	_rewards = get_node_or_null(rewards_path)
	_turrets = get_node_or_null(turrets_path)
	_player = get_node_or_null(player_path)
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = OUTLINE_SHADER
	_outline_material.set_shader_parameter("outline_color", Color.WHITE)
	_outline_material.set_shader_parameter("outline_width", 40.0)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()
		_sync_reward_rects()
		_sync_turret_rects()
		_sync_electric_endpoint_rects()


func toggle() -> void:
	visible = not visible
	if visible:
		_center_on_player_y()
		queue_redraw()
		_sync_reward_rects()
		_sync_turret_rects()
	else:
		for rect in _reward_rects:
			rect.visible = false
		for rect in _turret_rects:
			rect.visible = false
		for rect in _electric_endpoint_rects:
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
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0, 0, 0, 0.45), true)
	draw_rect(rect, Color(0.015, 0.025, 0.065, 0.96), true)
	var content_origin = rect.position + Vector2(0, _content_offset_y)
	draw_set_transform(content_origin, 0.0, Vector2.ONE)
	_draw_map_content()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
		rect.visible = true
		rect.texture = texture_to_draw
		var tex_size = texture_to_draw.get_size()
		var icon_size = maxf(64.0, maxf(tex_size.x, tex_size.y) * scale * 0.15)
		var aspect = tex_size.x / maxf(1.0, tex_size.y)
		var draw_size = Vector2(icon_size * maxf(1.0, aspect), icon_size * maxf(1.0, 1.0 / aspect))
		var reward_pos = reward.get_base_position() if reward.has_method("get_base_position") else reward.global_position
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
		var size = Vector2(64.0, 64.0)
		rect.position = content_origin + turret_pos * scale - size * 0.5
		rect.size = size
		rect.pivot_offset = size * 0.5
		rect.rotation = -PI * 0.5


func _sync_electric_endpoint_rects() -> void:
	if not show_turret_traps:
		for rect in _electric_endpoint_rects:
			rect.visible = false
		return
	if not _electric_isolation_bands:
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
		var rot: float = endpoint.get("rotation", 0.0)
		var tex_size = tex.get_size()
		var icon_size = maxf(64.0, maxf(tex_size.x, tex_size.y) * scale * 0.15)
		var aspect = tex_size.x / maxf(1.0, tex_size.y)
		var draw_size = Vector2(icon_size * maxf(1.0, aspect), icon_size * maxf(1.0, 1.0 / aspect))
		rect.visible = true
		rect.texture = tex
		rect.position = content_origin + pos * scale - draw_size * 0.5
		rect.size = draw_size
		rect.pivot_offset = draw_size * 0.5
		rect.rotation = rot


func _rects_append_turret(rect: TextureRect) -> void:
	_turret_rects.append(rect)


func _draw_space_rock_sprite(rock: Node2D, scale: float) -> void:
	var sprite = rock.get_node_or_null("Sprite2D")
	if not sprite or not sprite is Sprite2D or not sprite.texture:
		return
	var radius: float = rock.get("radius") if rock.get("radius") != null else 0.0
	var diameter = maxf(2.0, radius * 2.0 * scale)
	var rock_pos = rock.get_base_position() if rock.has_method("get_base_position") else rock.global_position
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
