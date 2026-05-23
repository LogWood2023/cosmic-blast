extends StaticBody2D

@export var radius: float = 600.0
@export var texture: Texture2D
@export var visual_rotation: float = 0.0
@export var use_simple_collision: bool = false
@export var outline_samples: int = 96
@export var alpha_threshold: float = 0.1

var _base_scale: Vector2 = Vector2.ONE
var _base_position: Vector2 = Vector2.ZERO
var _sway_t: float = 0.0
var _sway_speed: float = 1.0
var _sway_amp: Vector2 = Vector2.ZERO
var _outline: PackedVector2Array = PackedVector2Array()

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:
	add_to_group(&"space_rocks")
	_base_position = position
	rotation = 0.0
	if texture:
		sprite.texture = texture
	if sprite.texture:
		_base_scale = Vector2.ONE * (radius * 2.0 / sprite.texture.get_width())
		sprite.scale = _base_scale
		sprite.rotation = visual_rotation
		if use_simple_collision:
			_build_circle_outline_polygon()
		else:
			_build_outline_polygon()
	_sway_t = randf() * TAU
	_sway_speed = randf_range(0.35, 0.75)
	_sway_amp = Vector2(randf_range(12.0, 36.0), randf_range(12.0, 36.0))


func _process(delta: float) -> void:
	_sway_t += delta * _sway_speed
	position = _base_position + get_sway_offset()


func get_base_position() -> Vector2:
	return _base_position


func get_sway_offset() -> Vector2:
	return Vector2(sin(_sway_t) * _sway_amp.x, cos(_sway_t * 0.83) * _sway_amp.y)


func get_sway_profile() -> Dictionary:
	return {
		"t": _sway_t,
		"speed": _sway_speed,
		"amp": _sway_amp,
	}


func set_sway_profile(profile: Dictionary) -> void:
	_sway_t = profile.get("t", _sway_t)
	_sway_speed = profile.get("speed", _sway_speed)
	_sway_amp = profile.get("amp", _sway_amp)
	position = _base_position + get_sway_offset()


func get_surface_anchor(angle: float, inset: float = 0.0) -> Vector2:
	var world_dir = Vector2(cos(angle), sin(angle))
	var local_dir = world_dir.rotated(-visual_rotation)
	if _outline.size() < 3:
		return _base_position + local_dir.rotated(visual_rotation) * maxf(0.0, radius - inset)
	var best = local_dir * radius
	var best_dot = -INF
	for point in _outline:
		var dot = point.normalized().dot(local_dir)
		if dot > best_dot:
			best_dot = dot
			best = point
	return _base_position + (best - local_dir * inset).rotated(visual_rotation)


func _build_outline_polygon() -> void:
	var image = sprite.texture.get_image()
	if not image:
		return
	var size = image.get_size()
	var center = size * 0.5
	var max_radius = maxf(size.x, size.y) * 0.5
	var points: Array[Vector2] = []
	for i in outline_samples:
		var angle = TAU * float(i) / float(outline_samples)
		var dir = Vector2(cos(angle), sin(angle))
		var hit = center
		for step in range(int(max_radius), 0, -1):
			var pixel_pos = center + dir * float(step)
			var px = int(round(pixel_pos.x))
			var py = int(round(pixel_pos.y))
			if px < 0 or py < 0 or px >= size.x or py >= size.y:
				continue
			if image.get_pixel(px, py).a > alpha_threshold:
				hit = pixel_pos
				break
		points.append((hit - center) * _base_scale)
	_outline = PackedVector2Array(points)
	_apply_rotated_collision_polygon()


func _build_circle_outline_polygon() -> void:
	var points: Array[Vector2] = []
	var samples = 24
	for i in samples:
		var angle = TAU * float(i) / float(samples)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	_outline = PackedVector2Array(points)
	_apply_rotated_collision_polygon()


func _apply_rotated_collision_polygon() -> void:
	var rotated_points: Array[Vector2] = []
	for point in _outline:
		rotated_points.append(point.rotated(visual_rotation))
	collision_polygon.polygon = PackedVector2Array(rotated_points)


func get_push_out_position(world_pos: Vector2, margin: float) -> Vector2:
	if _outline.size() < 3:
		return world_pos
	var local_pos = to_local(world_pos).rotated(-visual_rotation)
	var inside = Geometry2D.is_point_in_polygon(local_pos, _outline)
	var closest = local_pos
	var closest_dist = INF
	for i in _outline.size():
		var a = _outline[i]
		var b = _outline[(i + 1) % _outline.size()]
		var p = Geometry2D.get_closest_point_to_segment(local_pos, a, b)
		var d = local_pos.distance_to(p)
		if d < closest_dist:
			closest_dist = d
			closest = p
	if inside:
		var dir = local_pos.normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		return to_global((closest + dir * margin).rotated(visual_rotation))
	if closest_dist < margin:
		var dir = (local_pos - closest).normalized()
		if dir == Vector2.ZERO:
			dir = local_pos.normalized()
		return to_global((closest + dir * margin).rotated(visual_rotation))
	return world_pos
