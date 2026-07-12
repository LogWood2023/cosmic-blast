extends Area2D

@export var clutter_texture: Texture2D
@export var visual_size: float = 180.0
@export var max_hp: int = 5
@export var shake_duration: float = 0.18
@export var shake_strength: float = 6.0
@export var sway_speed_min: float = 0.18
@export var sway_speed_max: float = 0.42
@export var sway_amplitude_min: float = 12.0
@export var sway_amplitude_max: float = 28.0
@export var fragment_count: int = 14
@export var fragment_speed: float = 280.0
@export var fragment_lifetime: float = 0.7
@export var explosion_min_radius: float = 14.0
@export var explosion_max_radius: float = 70.0
@export var mineral_min: int = 1
@export var mineral_max: int = 4
@export var mineral_pickup_count_min: int = 1
@export var mineral_pickup_count_max: int = 3

const HIT_SOUND := preload("res://assets/audio/metal_hit.wav")
const BREAK_SOUND := preload("res://assets/audio/ai_explosion_00_4217.wav")
const EXPLOSION_TEXTURE_SIZE: int = 128
const MINERAL_PICKUP_SCENE := preload("res://scenes/gameplay/explore/MineralPickup.tscn")

var _hp: int = 5
var _broken: bool = false
var _base_position: Vector2 = Vector2.ZERO
var _shake_remaining: float = 0.0
var _sway_t: float = 0.0
var _sway_speed: float = 0.3
var _sway_amplitude: float = 6.0
var _outline: PackedVector2Array = PackedVector2Array()
# 爆炸贴图逐像素生成一次即可，全部杂物实例共享（此前每个实例首次破碎都重新生成一张）
static var _explosion_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:
	add_to_group(&"space_clutter")
	collision_layer = 4
	collision_mask = 1
	_hp = max_hp
	_base_position = position
	_sway_t = randf_range(0.0, TAU)
	_sway_speed = randf_range(sway_speed_min, sway_speed_max)
	_sway_amplitude = randf_range(sway_amplitude_min, sway_amplitude_max)
	_apply_texture()


func _process(delta: float) -> void:
	if _broken:
		return
	_sway_t += delta * _sway_speed
	var sway_offset = Vector2(sin(_sway_t), cos(_sway_t * 0.83)) * _sway_amplitude
	if _shake_remaining > 0.0:
		_shake_remaining -= delta
		var shake = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		position = _base_position + sway_offset + shake
		if _shake_remaining <= 0.0:
			position = _base_position + sway_offset
	else:
		position = _base_position + sway_offset


func setup(texture: Texture2D) -> void:
	clutter_texture = texture
	if is_node_ready():
		_apply_texture()


func get_base_position() -> Vector2:
	return _base_position


func get_collision_query_radius() -> float:
	return visual_size * 0.55 + _sway_amplitude + shake_strength


func get_push_out_position(world_pos: Vector2, margin: float) -> Vector2:
	if _outline.size() < 3:
		return world_pos
	var local_pos = to_local(world_pos)
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
		var dir = (closest - local_pos).normalized()
		if dir == Vector2.ZERO:
			dir = closest.normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		return to_global(closest + dir * margin)
	if closest_dist < margin:
		var dir = (local_pos - closest).normalized()
		if dir == Vector2.ZERO:
			dir = local_pos.normalized()
		return to_global(closest + dir * margin)
	return world_pos


func take_damage(dmg: int) -> void:
	if _broken:
		return
	_hp -= dmg
	if _hp <= 0:
		_break()
	else:
		_play_hit_feedback()


func _apply_texture() -> void:
	sprite.texture = clutter_texture
	if not clutter_texture:
		return
	sprite.centered = true
	var tex_size = clutter_texture.get_size()
	var max_side = maxf(tex_size.x, tex_size.y)
	sprite.scale = Vector2.ONE * (visual_size / maxf(1.0, max_side))
	_outline = _build_simple_collision_outline(visual_size * 0.78)
	collision_polygon.polygon = _outline


func _play_hit_feedback() -> void:
	_shake_remaining = shake_duration
	_play_sfx(HIT_SOUND)


func _break() -> void:
	_broken = true
	if RunManager.is_formal_run_active():
		_spawn_mineral_pickups(randi_range(mineral_min, mineral_max), randi_range(mineral_pickup_count_min, mineral_pickup_count_max))
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_polygon.disabled = true
	_play_sfx(BREAK_SOUND)
	_spawn_explosion_effect()
	sprite.visible = false
	await get_tree().create_timer(fragment_lifetime).timeout
	queue_free()


func _spawn_mineral_pickups(total_amount: int, pickup_count: int) -> void:
	var parent = get_parent()
	if not parent:
		return
	var remaining := maxi(1, total_amount)
	var count := maxi(1, mini(pickup_count, remaining))
	var target := _find_player()
	for i in range(count):
		var slots_left := count - i
		var amount := remaining
		if slots_left > 1:
			amount = randi_range(1, maxi(1, remaining - slots_left + 1))
		remaining -= amount
		var pickup = MINERAL_PICKUP_SCENE.instantiate()
		pickup.global_position = global_position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, 36.0)
		parent.add_child(pickup)
		if pickup.has_method("setup"):
			pickup.setup(amount, target)


func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group(&"player"):
		if node is Node2D:
			return node
	return null


func _spawn_explosion_effect() -> void:
	var parent = get_parent()
	if not parent:
		return
	var boom = Sprite2D.new()
	boom.texture = _get_explosion_texture()
	boom.centered = true
	boom.global_position = global_position
	boom.modulate = Color(0.7, 0.9, 1.0, 0.65)
	parent.add_child(boom)
	var pulse = create_tween()
	pulse.tween_property(boom, "scale", Vector2.ONE * randf_range(explosion_min_radius, explosion_max_radius) * 0.04, 0.14)
	pulse.parallel().tween_property(boom, "modulate:a", 0.0, 0.14)
	pulse.tween_callback(boom.queue_free)
	for i in range(fragment_count):
		var frag = Sprite2D.new()
		frag.texture = clutter_texture
		frag.centered = true
		if clutter_texture:
			frag.region_enabled = true
			var tex_size = clutter_texture.get_size()
			var region_size = Vector2(
				minf(randf_range(32.0, 96.0), tex_size.x),
				minf(randf_range(32.0, 96.0), tex_size.y)
			)
			frag.region_rect = Rect2(Vector2(randf_range(0.0, maxf(0.0, tex_size.x - region_size.x)), randf_range(0.0, maxf(0.0, tex_size.y - region_size.y))), region_size)
		frag.global_position = global_position
		frag.scale = Vector2.ONE * randf_range(0.12, 0.28)
		frag.rotation = randf_range(0.0, TAU)
		frag.modulate = Color(1.0, 1.0, 1.0, 0.8)
		parent.add_child(frag)
		var dir = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		var speed = randf_range(fragment_speed * 0.4, fragment_speed)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(frag, "global_position", global_position + dir * speed * fragment_lifetime, fragment_lifetime)
		tween.tween_property(frag, "modulate:a", 0.0, fragment_lifetime)
		tween.tween_property(frag, "rotation", frag.rotation + randf_range(-PI, PI), fragment_lifetime)
		tween.chain().tween_callback(frag.queue_free)


func _play_sfx(stream: AudioStream) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var sfx = AudioStreamPlayer.new()
	sfx.bus = &"SFX"
	sfx.stream = stream
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)
	else:
		sfx.queue_free()


func _get_explosion_texture() -> Texture2D:
	if _explosion_texture:
		return _explosion_texture
	var image = Image.create(EXPLOSION_TEXTURE_SIZE, EXPLOSION_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var center = Vector2(EXPLOSION_TEXTURE_SIZE * 0.5, EXPLOSION_TEXTURE_SIZE * 0.5)
	var radius = EXPLOSION_TEXTURE_SIZE * 0.5
	for y in range(EXPLOSION_TEXTURE_SIZE):
		for x in range(EXPLOSION_TEXTURE_SIZE):
			var dist = Vector2(x, y).distance_to(center) / radius
			var alpha = pow(maxf(0.0, 1.0 - dist), 2.2)
			if dist < 0.2:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
			else:
				image.set_pixel(x, y, Color(0.62, 0.86, 1.0, alpha * 0.7))
	_explosion_texture = ImageTexture.create_from_image(image)
	return _explosion_texture


func _build_simple_collision_outline(size: float) -> PackedVector2Array:
	var half = size * 0.5
	return PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half),
	])

