extends Node2D

@export var endpoint_size: float = 384.0
@export var light_tip_offset_ratio: float = 0.5
@export var light_energy_min: float = 0.8
@export var light_energy_max: float = 1.8
@export var light_pulse_speed: float = 2.6
@export var lightning_width: float = 4.0
@export var lightning_color: Color = Color(0.62, 0.86, 1.0, 0.3)
@export var lightning_jitter_ratio: float = 0.12
@export var lightning_segment_count: int = 16
@export var tip_circle_min_radius: float = 180.0
@export var tip_circle_max_radius: float = 342.0
@export var state_min_duration: float = 5.0
@export var state_max_duration: float = 10.0
@export var static_spark_min_interval: float = 0.1
@export var static_spark_max_interval: float = 2.0
@export var static_spark_min_duration: float = 0.1
@export var static_spark_max_duration: float = 0.3
@export var static_damage: int = 5
@export var moving_damage: int = 30
@export var knockback_speed: float = 900.0
@export var knockback_duration: float = 0.7
@export var hit_distance: float = 32.0
const MAP_ENDPOINT_SIZE: float = 48.0
const ENDPOINT_ROTATION_OFFSET: float = PI * 0.5
const LIGHTNING_LINE_COUNT: int = 5
const TIP_CIRCLE_TEXTURE_SIZE: int = 128

enum ElectricState { STATIC, MOVING }

var _state: ElectricState = ElectricState.STATIC
var _state_time_left: float = 0.0
var _static_spark_time_left: float = 0.0
var _static_spark_interval_left: float = 0.0
var _static_spark_active: bool = false
var _static_final_spark_active: bool = false
var _active_lightning_count: int = 0
var _start_point: Vector2 = Vector2.ZERO
var _end_point: Vector2 = Vector2.ZERO
var _start_texture: Texture2D
var _end_texture: Texture2D
var _start_target: Node2D
var _end_target: Node2D
var _start_offset: Vector2 = Vector2.ZERO
var _end_offset: Vector2 = Vector2.ZERO
var _start_angle: float = 0.0
var _end_angle: float = 0.0
var _pulse_t: float = 0.0
var _light_texture: Texture2D
var _tip_circle_texture: Texture2D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _line_seeds: Array[float] = []
var _last_player_pos: Dictionary = {}

@onready var start_sprite: Sprite2D = $StartEndpoint
@onready var end_sprite: Sprite2D = $EndEndpoint
@onready var start_light: PointLight2D = $StartTipLight
@onready var end_light: PointLight2D = $EndTipLight
@onready var start_tip_circle: Sprite2D = $StartTipCircle
@onready var end_tip_circle: Sprite2D = $EndTipCircle


func _ready() -> void:
	add_to_group(&"electric_isolation_bands")
	_rng.randomize()
	_prepare_line_seeds()
	_setup_lights()
	_setup_tip_circles()
	_switch_state(ElectricState.STATIC)
	_apply_visuals()


func _process(delta: float) -> void:
	_pulse_t += delta * light_pulse_speed
	_update_state(delta)
	if is_instance_valid(_start_target):
		_start_point = _start_target.global_position + _start_offset
	if is_instance_valid(_end_target):
		_end_point = _end_target.global_position + _end_offset
	_apply_positions()
	_apply_light_energy()
	_apply_tip_circles()
	_update_damage()
	_remember_player_positions()
	queue_redraw()


func _draw() -> void:
	_draw_lightning()


func setup(start_point: Vector2, end_point: Vector2, start_angle: float, end_angle: float, start_texture: Texture2D, end_texture: Texture2D) -> void:
	_start_point = start_point
	_end_point = end_point
	_start_angle = start_angle
	_end_angle = end_angle
	_start_texture = start_texture
	_end_texture = end_texture
	if is_node_ready():
		_apply_visuals()


func follow_targets(start_target: Node2D, start_offset: Vector2, end_target: Node2D, end_offset: Vector2) -> void:
	_start_target = start_target
	_start_offset = start_offset
	_end_target = end_target
	_end_offset = end_offset


func get_map_endpoints() -> Array[Dictionary]:
	return [
		{
			"position": _start_point,
			"rotation": _start_angle + ENDPOINT_ROTATION_OFFSET,
			"texture": _start_texture,
			"size": endpoint_size,
			"map_size": MAP_ENDPOINT_SIZE,
		},
		{
			"position": _end_point,
			"rotation": _end_angle + ENDPOINT_ROTATION_OFFSET,
			"texture": _end_texture,
			"size": endpoint_size,
			"map_size": MAP_ENDPOINT_SIZE,
		},
	]


func _switch_state(next_state: ElectricState) -> void:
	_state = next_state
	_state_time_left = _rng.randf_range(state_min_duration, state_max_duration)
	_static_spark_active = false
	_static_final_spark_active = false
	_static_spark_time_left = 0.0
	_static_spark_interval_left = _rng.randf_range(static_spark_min_interval, static_spark_max_interval)
	_active_lightning_count = LIGHTNING_LINE_COUNT if _state == ElectricState.MOVING else 0
	_update_active_visuals()


func _update_state(delta: float) -> void:
	_state_time_left -= delta
	if _state == ElectricState.STATIC:
		_update_static_sparks(delta)
	else:
		_active_lightning_count = LIGHTNING_LINE_COUNT
	if _state_time_left <= 0.0:
		_switch_state(ElectricState.MOVING if _state == ElectricState.STATIC else ElectricState.STATIC)


func _update_static_sparks(delta: float) -> void:
	if _state_time_left <= 1.0:
		_static_spark_active = true
		_static_final_spark_active = true
		_active_lightning_count = 1
		_update_active_visuals()
		return
	_static_final_spark_active = false
	if _static_spark_active:
		_static_spark_time_left -= delta
		if _static_spark_time_left <= 0.0:
			_static_spark_active = false
			_active_lightning_count = 0
			_static_spark_interval_left = _rng.randf_range(static_spark_min_interval, static_spark_max_interval)
	else:
		_static_spark_interval_left -= delta
		if _static_spark_interval_left <= 0.0:
			_static_spark_active = true
			_static_spark_time_left = _rng.randf_range(static_spark_min_duration, static_spark_max_duration)
			_active_lightning_count = 1
	_update_active_visuals()


func _update_active_visuals() -> void:
	var moving = _state == ElectricState.MOVING
	start_light.visible = moving
	end_light.visible = moving
	start_tip_circle.visible = moving
	end_tip_circle.visible = moving


func _prepare_line_seeds() -> void:
	_line_seeds.clear()
	for _i in range(LIGHTNING_LINE_COUNT):
		_line_seeds.append(_rng.randf_range(0.0, TAU))


func _setup_lights() -> void:
	if not _light_texture:
		_light_texture = _create_light_texture()
	for light in [start_light, end_light]:
		light.texture = _light_texture
		light.color = Color(0.45, 0.85, 1.0, 1.0)
		light.texture_scale = 3.0
		light.energy = light_energy_min


func _setup_tip_circles() -> void:
	if not _tip_circle_texture:
		_tip_circle_texture = _create_tip_circle_texture()
	for circle in [start_tip_circle, end_tip_circle]:
		circle.texture = _tip_circle_texture
		circle.centered = true
		circle.z_index = 20


func _apply_visuals() -> void:
	start_sprite.texture = _start_texture
	end_sprite.texture = _end_texture
	_apply_sprite_scale(start_sprite)
	_apply_sprite_scale(end_sprite)
	_apply_positions()
	_apply_light_energy()
	_apply_tip_circles()
	_update_active_visuals()
	queue_redraw()


func _apply_positions() -> void:
	var start_rotation = _start_angle + ENDPOINT_ROTATION_OFFSET
	var end_rotation = _end_angle + ENDPOINT_ROTATION_OFFSET
	start_sprite.global_position = _start_point
	start_sprite.global_rotation = start_rotation
	end_sprite.global_position = _end_point
	end_sprite.global_rotation = end_rotation
	start_light.global_position = _endpoint_tip_position(_start_point, start_rotation)
	end_light.global_position = _endpoint_tip_position(_end_point, end_rotation)
	start_tip_circle.global_position = start_light.global_position
	end_tip_circle.global_position = end_light.global_position


func _apply_sprite_scale(sprite: Sprite2D) -> void:
	if not sprite.texture:
		return
	var size = sprite.texture.get_size()
	var max_side = maxf(size.x, size.y)
	sprite.scale = Vector2.ONE * (endpoint_size / maxf(1.0, max_side))


func _apply_light_energy() -> void:
	var pulse = _pulse_amount()
	var energy = lerpf(light_energy_min, light_energy_max, pulse)
	start_light.energy = energy
	end_light.energy = energy


func _apply_tip_circles() -> void:
	var pulse = _pulse_amount()
	var radius = lerpf(tip_circle_min_radius, tip_circle_max_radius, pulse)
	var scale_value = radius * 2.0 / float(TIP_CIRCLE_TEXTURE_SIZE)
	var alpha = lerpf(0.78, 1.0, pulse)
	for circle in [start_tip_circle, end_tip_circle]:
		circle.scale = Vector2.ONE * scale_value
		circle.modulate = Color(1.0, 1.0, 1.0, alpha)


func _draw_lightning() -> void:
	if _active_lightning_count <= 0:
		return
	var start_pos = to_local(start_light.global_position)
	var end_pos = to_local(end_light.global_position)
	var length = start_pos.distance_to(end_pos)
	if length <= 0.1:
		return
	var segment_count = maxi(2, lightning_segment_count)
	var line_count = mini(_active_lightning_count, LIGHTNING_LINE_COUNT)
	for i in range(line_count):
		var seed = _line_seeds[i] if i < _line_seeds.size() else float(i) * 1.73
		var path_points = _build_lightning_path(start_pos, end_pos, seed, segment_count)
		if path_points.size() < 2:
			continue
		_draw_lightning_path(path_points)


func _draw_lightning_path(path_points: PackedVector2Array) -> void:
	var has_glow = _state == ElectricState.MOVING
	var static_alpha_scale = 1.0 if has_glow else 0.3
	var passes = [
		{"width": lightning_width * 2.3, "color": Color(lightning_color.r, lightning_color.g, lightning_color.b, (0.08 if has_glow else 0.0) * static_alpha_scale)},
		{"width": lightning_width * 1.45, "color": Color(lightning_color.r, lightning_color.g, lightning_color.b, (lightning_color.a if has_glow else 0.2) * static_alpha_scale)},
		{"width": lightning_width, "color": Color(1.0, 1.0, 1.0, 0.78 * static_alpha_scale)},
	]
	for pass_data in passes:
		var color: Color = pass_data["color"]
		if color.a <= 0.0:
			continue
		var width = float(pass_data["width"])
		_draw_polyline_layers(path_points, color, width)


func _draw_polyline_layers(points: PackedVector2Array, base_color: Color, width: float) -> void:
	if points.size() < 2:
		return
	draw_polyline(points, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.45), width * 1.8, true)
	draw_polyline(points, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.85), width * 0.9, true)
	draw_polyline(points, Color(1.0, 1.0, 1.0, maxf(base_color.a, 0.15)), width * 0.35, true)


func _build_lightning_path(start_pos: Vector2, end_pos: Vector2, seed: float, segment_count: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	var delta = end_pos - start_pos
	var length = delta.length()
	if length <= 0.1:
		points.append(start_pos)
		points.append(end_pos)
		return points
	var direction = delta / length
	var perpendicular = direction.orthogonal()
	var amplitude = maxf(12.0, length * lightning_jitter_ratio)
	for j in range(segment_count + 1):
		var t = float(j) / float(segment_count)
		var base = start_pos.lerp(end_pos, t)
		var falloff = 1.0 - absf(t - 0.5) * 1.7
		falloff = clampf(falloff, 0.2, 1.0)
		var sway = sin(_pulse_t * (18.0 + seed * 0.3) + seed + float(j) * 1.85) * amplitude * 0.5
		sway += cos(_pulse_t * (11.0 + seed * 0.2) + seed * 0.7 + float(j) * 0.93) * amplitude * 0.22
		var along = sin(_pulse_t * (9.0 + seed * 0.1) + seed * 1.4 + float(j) * 2.7) * amplitude * 0.08
		var point = base + perpendicular * sway * falloff + direction * along * falloff
		points.append(point)
	return points


func _update_damage() -> void:
	if _active_lightning_count <= 0:
		return
	for player in get_tree().get_nodes_in_group(&"player"):
		if not is_instance_valid(player):
			continue
		if _state == ElectricState.STATIC:
			if _is_player_touching_lightning(player):
				_apply_direct_player_damage(player, static_damage)
		elif _is_player_touching_lightning(player):
			var knock_dir = _get_player_approach_direction(player)
			_apply_player_knockback_damage(player, moving_damage, knock_dir)


func _is_player_touching_lightning(player: Node2D) -> bool:
	var closest = Geometry2D.get_closest_point_to_segment(player.global_position, start_light.global_position, end_light.global_position)
	var radius = hit_distance
	if player.get("collision_radius") != null:
		radius += float(player.get("collision_radius"))
	return player.global_position.distance_to(closest) <= radius


func _apply_direct_player_damage(player: Node, amount: int) -> void:
	if player.get("invincible") == true:
		return
	if player.has_method("take_damage_from_boss"):
		player.take_damage_from_boss(amount)


func _apply_player_knockback_damage(player: Node2D, amount: int, knock_dir: Vector2) -> void:
	if player.get("invincible") == true or player.get("is_knocked_back") == true:
		return
	if knock_dir == Vector2.ZERO:
		knock_dir = Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
	if player.has_method("take_knockback_damage"):
		player.take_knockback_damage(amount, knockback_speed, knockback_duration, knock_dir.normalized())


func _get_player_approach_direction(player: Node2D) -> Vector2:
	var previous = _last_player_pos.get(player.get_instance_id(), null)
	if previous is Vector2:
		var from_previous = player.global_position - previous
		if from_previous.length() > 0.1:
			return -from_previous.normalized()
	var away_from_line = player.global_position - Geometry2D.get_closest_point_to_segment(player.global_position, start_light.global_position, end_light.global_position)
	if away_from_line.length() > 0.1:
		return away_from_line.normalized()
	return Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))


func _remember_player_positions() -> void:
	for player in get_tree().get_nodes_in_group(&"player"):
		if is_instance_valid(player):
			_last_player_pos[player.get_instance_id()] = player.global_position


func _pulse_amount() -> float:
	return (sin(_pulse_t) + 1.0) * 0.5


func _endpoint_tip_position(point: Vector2, rotation: float) -> Vector2:
	return point + Vector2.UP.rotated(rotation) * endpoint_size * light_tip_offset_ratio


func _create_light_texture() -> Texture2D:
	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size * 0.5, size * 0.5)
	var radius = size * 0.5
	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center) / radius
			var alpha = pow(maxf(0.0, 1.0 - dist), 2.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _create_tip_circle_texture() -> Texture2D:
	var image = Image.create(TIP_CIRCLE_TEXTURE_SIZE, TIP_CIRCLE_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var center = Vector2(TIP_CIRCLE_TEXTURE_SIZE * 0.5, TIP_CIRCLE_TEXTURE_SIZE * 0.5)
	var radius = TIP_CIRCLE_TEXTURE_SIZE * 0.5
	for y in range(TIP_CIRCLE_TEXTURE_SIZE):
		for x in range(TIP_CIRCLE_TEXTURE_SIZE):
			var dist = Vector2(x, y).distance_to(center) / radius
			var outer_alpha = pow(maxf(0.0, 1.0 - dist), 2.2) * 0.35
			var core_alpha = pow(maxf(0.0, 1.0 - dist * 2.6), 1.5) * 0.8
			var alpha = clampf(outer_alpha + core_alpha, 0.0, 1.0)
			var color = Color(0.55, 0.9, 1.0, alpha)
			if dist < 0.22:
				color = Color(1.0, 1.0, 1.0, alpha)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
