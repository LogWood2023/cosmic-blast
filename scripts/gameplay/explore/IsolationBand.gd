extends Node2D

@export var start_point: Vector2 = Vector2.ZERO
@export var end_point: Vector2 = Vector2.ZERO
@export var band_width: float = 100.0
@export var band_color: Color = Color.WHITE
@export var band_texture: Texture2D
@export var tile_textures: Array[Texture2D] = []
@export var fallback_center_collision_width: float = 300.0
var _tile_sequence: Array[Texture2D] = []
var _outline: PackedVector2Array = PackedVector2Array()
var _base_position: Vector2 = Vector2.ZERO
var _sway_t: float = 0.0
var _sway_speed: float = 1.0
var _sway_amp: Vector2 = Vector2.ZERO

@onready var line: Line2D = $Line2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var body: StaticBody2D = $StaticBody2D
@onready var collision_polygon: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D


func _ready() -> void:
	add_to_group(&"isolation_bands")
	_apply_visual()


func _process(delta: float) -> void:
	_sway_t += delta * _sway_speed
	position = _base_position + get_sway_offset()


func setup(p_start: Vector2, p_end: Vector2, p_width: float, p_texture: Texture2D = null) -> void:
	start_point = p_start
	end_point = p_end
	band_width = p_width
	band_texture = p_texture
	tile_textures.clear()
	_tile_sequence.clear()
	if p_texture:
		tile_textures.append(p_texture)
	if is_node_ready():
		_apply_visual()


func setup_tiles(p_start: Vector2, p_end: Vector2, p_width: float, p_tile_textures: Array[Texture2D]) -> void:
	start_point = p_start
	end_point = p_end
	band_width = p_width
	band_texture = null
	tile_textures = p_tile_textures.duplicate()
	_tile_sequence.clear()
	if is_node_ready():
		_apply_visual()


func get_map_start() -> Vector2:
	return start_point


func get_map_end() -> Vector2:
	return end_point


func get_map_width() -> float:
	return get_collision_width()


func get_map_texture() -> Texture2D:
	return _tile_sequence[0] if not _tile_sequence.is_empty() else tile_textures[0] if not tile_textures.is_empty() else band_texture


func get_texture_region_size() -> Vector2:
	var texture = get_map_texture()
	if not texture:
		return Vector2.ZERO
	return Vector2(minf(start_point.distance_to(end_point), texture.get_width()), texture.get_height())


func get_collision_width() -> float:
	var texture = get_map_texture()
	return texture.get_height() if texture else band_width


func get_sway_offset() -> Vector2:
	return Vector2(sin(_sway_t) * _sway_amp.x, cos(_sway_t * 0.83) * _sway_amp.y)


func set_sway_profile(profile: Dictionary) -> void:
	_sway_t = profile.get("t", _sway_t)
	_sway_speed = profile.get("speed", _sway_speed)
	_sway_amp = profile.get("amp", _sway_amp)
	position = _base_position + get_sway_offset()


func get_push_out_position(world_pos: Vector2, margin: float) -> Vector2:
	var local_pos = to_local(world_pos)
	var found: bool = false
	var closest = local_pos
	var closest_dist = INF
	var all_poly_children: Array[CollisionPolygon2D] = []
	for child in body.get_children():
		if child is CollisionPolygon2D:
			all_poly_children.append(child)
	if all_poly_children.is_empty():
		var half = Vector2(start_point.distance_to(end_point) * 0.5, get_collision_width() * 0.5)
		if absf(local_pos.x) < half.x + margin and absf(local_pos.y) < half.y + margin:
			if absf(local_pos.x) < half.x and absf(local_pos.y) < half.y:
				found = true
			var dx = half.x + margin - absf(local_pos.x)
			var dy = half.y + margin - absf(local_pos.y)
			if dx < dy:
				local_pos.x = signf(local_pos.x) * (half.x + margin)
			else:
				local_pos.y = signf(local_pos.y) * (half.y + margin)
			return to_global(local_pos)
		return world_pos
	for child in all_poly_children:
		var poly = child.polygon
		if poly.size() < 3:
			continue
		var child_local = local_pos - child.position
		if Geometry2D.is_point_in_polygon(child_local, poly):
			found = true
		for i in poly.size():
			var a = poly[i]
			var b = poly[(i + 1) % poly.size()]
			var p = Geometry2D.get_closest_point_to_segment(child_local, a, b)
			var d = child_local.distance_to(p)
			if d < closest_dist:
				closest_dist = d
				closest = p + child.position
	if found:
		var dir = local_pos.normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		return to_global(closest + dir * margin)
	if closest_dist < margin:
		var dir = (local_pos - closest).normalized()
		if dir == Vector2.ZERO:
			dir = local_pos.normalized()
		return to_global(closest + dir * margin)
	return world_pos


func _apply_visual() -> void:
	_clear_tile_sprites()
	if not tile_textures.is_empty():
		line.visible = false
		sprite.visible = false
		var length = start_point.distance_to(end_point)
		global_position = (start_point + end_point) * 0.5
		_base_position = position
		global_rotation = (end_point - start_point).angle()
		_build_tile_sprites(length)
	elif band_texture:
		line.visible = false
		sprite.visible = true
		sprite.texture = band_texture
		var length = start_point.distance_to(end_point)
		var region_width = minf(length, band_texture.get_width())
		global_position = (start_point + end_point) * 0.5
		_base_position = position
		global_rotation = (end_point - start_point).angle()
		sprite.position = Vector2.ZERO
		sprite.rotation = 0.0
		sprite.centered = true
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2.ZERO, Vector2(region_width, band_texture.get_height()))
		sprite.scale = Vector2.ONE
		collision_polygon.polygon = _build_rect_polygon(Vector2(length, get_collision_width()))
	else:
		sprite.visible = false
		line.visible = true
		line.width = band_width
		line.default_color = band_color
		var length = start_point.distance_to(end_point)
		global_position = (start_point + end_point) * 0.5
		_base_position = position
		global_rotation = (end_point - start_point).angle()
		line.points = PackedVector2Array([Vector2(-length * 0.5, 0.0), Vector2(length * 0.5, 0.0)])
		var half = Vector2(length * 0.5, band_width * 0.5)
		collision_polygon.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])


func _clear_tile_sprites() -> void:
	for child in get_children():
		if child is Sprite2D and child != sprite:
			child.free()
	for child in body.get_children():
		if child is CollisionPolygon2D and child != collision_polygon:
			child.queue_free()


func _build_tile_sprites(length: float) -> void:
	var tile_width = tile_textures[0].get_width()
	var tile_height = tile_textures[0].get_height()
	var count = int(ceil(length / tile_width))
	_ensure_tile_sequence(count)
	collision_polygon.polygon = _build_rect_polygon(Vector2(length, fallback_center_collision_width))
	for i in range(count):
		var texture = _tile_sequence[i]
		var visible_width = minf(tile_width, length - i * tile_width)
		var tile = Sprite2D.new()
		tile.texture = texture
		tile.centered = false
		tile.region_enabled = true
		tile.region_rect = Rect2(Vector2.ZERO, Vector2(visible_width, tile_height))
		tile.position = Vector2(-length * 0.5 + i * tile_width, -tile_height * 0.5)
		add_child(tile)



func _build_rect_polygon(size: Vector2) -> PackedVector2Array:
	var half = size * 0.5
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])


func _ensure_tile_sequence(count: int) -> void:
	if _tile_sequence.is_empty() and not tile_textures.is_empty():
		_tile_sequence.append(tile_textures.pick_random())
	while _tile_sequence.size() < count:
		_tile_sequence.append(_tile_sequence[0])
	if _tile_sequence.size() > count:
		_tile_sequence.resize(count)
