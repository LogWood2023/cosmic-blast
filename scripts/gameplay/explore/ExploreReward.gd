extends Area2D

enum RewardType { CHEST, ORE_VEIN }

@export var reward_type: RewardType = RewardType.CHEST
@export var reward_texture: Texture2D
@export var chest_color: Color = Color(0.95, 0.68, 0.22)
@export var ore_color: Color = Color(0.35, 0.85, 1.0)
@export var outline_samples: int = 48
@export var alpha_threshold: float = 0.1
@export var glow_scale: float = 1.8
@export var max_hp: int = 5
@export var shake_duration: float = 0.2
@export var shake_strength: float = 4.0
@export var fragment_count: int = 12
@export var fragment_speed: float = 300.0
@export var fragment_lifetime: float = 0.8
@export var fragment_size: float = 6.0
@export var ore_fragment_spread_angle: float = 90.0
@export var fragment_texture_scale: float = 0.035

const METAL_HIT_SOUND := preload("res://assets/audio/metal_hit.wav")
const METAL_BREAK_SOUND := preload("res://assets/audio/metal_break.wav")
const GLASS_HIT_SOUND := preload("res://assets/audio/glass_hit.wav")
const GLASS_BREAK_SOUND := preload("res://assets/audio/glass_break.wav")

const CRATE_FRAGMENT_PATHS: Array[Array] = [
	[
		"res://assets/images/fx/debris_fragments/final/crate_fragment_1/crate_fragment_1_01.png",
		"res://assets/images/fx/debris_fragments/final/crate_fragment_1/crate_fragment_1_02.png",
		"res://assets/images/fx/debris_fragments/final/crate_fragment_1/crate_fragment_1_03.png",
	],
	[
		"res://assets/images/fx/debris_fragments/final/crate_fragment_2/crate_fragment_2_01.png",
		"res://assets/images/fx/debris_fragments/final/crate_fragment_2/crate_fragment_2_02.png",
		"res://assets/images/fx/debris_fragments/final/crate_fragment_2/crate_fragment_2_03.png",
	],
	[
		"res://assets/images/fx/debris_fragments/final/crate_fragment_3/crate_fragment_3_01.png",
		"res://assets/images/fx/debris_fragments/final/crate_fragment_3/crate_fragment_3_02.png",
		"res://assets/images/fx/debris_fragments/final/crate_fragment_3/crate_fragment_3_03.png",
	],
]

const CRYSTAL_FRAGMENT_PATHS: Array[Array] = [
	[
		"res://assets/images/fx/debris_fragments/final/crystal_fragment_1/crystal_fragment_1_01.png",
		"res://assets/images/fx/debris_fragments/final/crystal_fragment_1/crystal_fragment_1_02.png",
		"res://assets/images/fx/debris_fragments/final/crystal_fragment_1/crystal_fragment_1_03.png",
	],
	[
		"res://assets/images/fx/debris_fragments/final/crystal_fragment_2/crystal_fragment_2_01.png",
		"res://assets/images/fx/debris_fragments/final/crystal_fragment_2/crystal_fragment_2_02.png",
		"res://assets/images/fx/debris_fragments/final/crystal_fragment_2/crystal_fragment_2_03.png",
	],
	[
		"res://assets/images/fx/debris_fragments/final/crystal_fragment_3/crystal_fragment_3_01.png",
		"res://assets/images/fx/debris_fragments/final/crystal_fragment_3/crystal_fragment_3_02.png",
		"res://assets/images/fx/debris_fragments/final/crystal_fragment_3/crystal_fragment_3_03.png",
	],
]

var _follow_target: Node2D
var _follow_offset: Vector2 = Vector2.ZERO
var _spawn_position: Vector2 = Vector2.ZERO
var _hp: int = 5
var _shake_remaining: float = 0.0
var _base_position_local: Vector2 = Vector2.ZERO
var _broken: bool = false
var _fragment_variant_index: int = 0
var _collision_polygon_points: PackedVector2Array = PackedVector2Array()

@onready var glow_sprite: Sprite2D = $GlowSprite
@onready var sprite: Sprite2D = $Sprite2D
@onready var shine_sprite: Sprite2D = $ShineSprite
@onready var polygon: Polygon2D = $Polygon2D
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:
	add_to_group(&"explore_rewards")
	collision_layer = 4
	collision_mask = 5
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_spawn_position = global_position
	_hp = max_hp
	_apply_shape()


func _process(delta: float) -> void:
	if _broken:
		return
	if is_instance_valid(_follow_target):
		global_position = _follow_target.global_position + _follow_offset
	if _shake_remaining > 0.0:
		_shake_remaining -= delta
		position = _base_position_local + Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		if _shake_remaining <= 0.0:
			position = _base_position_local


func get_reward_type() -> RewardType:
	return reward_type


func get_base_position() -> Vector2:
	return _spawn_position


func get_reward_sprite_texture() -> Texture2D:
	return reward_texture if reward_texture else null


func get_push_out_position(world_pos: Vector2, margin: float) -> Vector2:
	if _collision_polygon_points.size() < 3:
		return world_pos
	var local_pos = to_local(world_pos)
	var inside = Geometry2D.is_point_in_polygon(local_pos, _collision_polygon_points)
	var closest = local_pos
	var closest_dist = INF
	for i in _collision_polygon_points.size():
		var a = _collision_polygon_points[i]
		var b = _collision_polygon_points[(i + 1) % _collision_polygon_points.size()]
		var p = Geometry2D.get_closest_point_to_segment(local_pos, a, b)
		var d = local_pos.distance_to(p)
		if d < closest_dist:
			closest_dist = d
			closest = p
	if inside:
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


func setup(p_type: RewardType) -> void:
	reward_type = p_type
	if is_node_ready():
		_apply_shape()


func set_reward_texture(p_texture: Texture2D) -> void:
	reward_texture = p_texture
	_update_fragment_variant_index()
	if is_node_ready():
		_apply_texture()


func follow_target(target: Node2D, offset: Vector2) -> void:
	_follow_target = target
	_follow_offset = offset
	if is_instance_valid(_follow_target):
		global_position = _follow_target.global_position + _follow_offset


func _apply_shape() -> void:
	_apply_texture()
	if reward_texture:
		return
	if reward_type == RewardType.CHEST:
		var points = PackedVector2Array([
			Vector2(-36.0, -24.0),
			Vector2(36.0, -24.0),
			Vector2(36.0, 24.0),
			Vector2(-36.0, 24.0),
		])
		polygon.polygon = points
		polygon.color = chest_color
		collision_polygon.polygon = points
		_collision_polygon_points = points
	else:
		var points = PackedVector2Array([
			Vector2(-48.0, -12.0),
			Vector2(-20.0, -34.0),
			Vector2(34.0, -28.0),
			Vector2(52.0, 0.0),
			Vector2(28.0, 30.0),
			Vector2(-34.0, 24.0),
		])
		polygon.polygon = points
		polygon.color = ore_color
		collision_polygon.polygon = points
		_collision_polygon_points = points


func _apply_texture() -> void:
	sprite.texture = reward_texture
	sprite.visible = reward_texture != null
	polygon.visible = reward_texture == null
	if reward_texture:
		sprite.centered = true
		sprite.offset = Vector2.ZERO
		collision_polygon.polygon = _build_texture_outline(reward_texture)

		glow_sprite.texture = reward_texture
		glow_sprite.visible = true
		glow_sprite.centered = true
		glow_sprite.offset = Vector2.ZERO
		glow_sprite.scale = Vector2.ONE * glow_scale

		shine_sprite.texture = reward_texture
		shine_sprite.visible = true
		shine_sprite.centered = true
		shine_sprite.offset = Vector2.ZERO
		shine_sprite.scale = Vector2.ONE
	else:
		glow_sprite.visible = false
		shine_sprite.visible = false


func _on_area_entered(_area: Area2D) -> void:
	return


func _on_body_entered(_body: Node2D) -> void:
	return


func take_damage(dmg: int) -> void:
	_take_damage(dmg)


func _take_damage(dmg: int) -> void:
	if _broken:
		return
	_hp -= dmg
	if _hp <= 0:
		_break()
	else:
		_play_hit_feedback()


func _play_hit_feedback() -> void:
	_shake_remaining = shake_duration
	_base_position_local = position
	_play_sfx(METAL_HIT_SOUND if reward_type == RewardType.CHEST else GLASS_HIT_SOUND)


func _break() -> void:
	_broken = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	_play_sfx(METAL_BREAK_SOUND if reward_type == RewardType.CHEST else GLASS_BREAK_SOUND)
	_spawn_fragments()
	sprite.visible = false
	glow_sprite.visible = false
	shine_sprite.visible = false
	polygon.visible = false
	collision_polygon.disabled = true
	await get_tree().create_timer(fragment_lifetime).timeout
	queue_free()


func _spawn_fragments() -> void:
	var parent = get_parent()
	if not parent:
		return
	var is_ore = reward_type == RewardType.ORE_VEIN
	for i in range(fragment_count):
		var frag = _create_fragment_node(is_ore)
		frag.global_position = global_position
		parent.add_child(frag)

		var speed: float
		var dir: Vector2
		if is_ore:
			var half_angle = deg_to_rad(45.0)
			var outward = Vector2.UP.rotated(global_rotation)
			var center_angle = outward.angle()
			var spread = randf_range(-half_angle, half_angle)
			dir = Vector2(cos(center_angle + spread), sin(center_angle + spread))
			speed = randf_range(fragment_speed * 0.6, fragment_speed)
		else:
			dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			speed = randf_range(fragment_speed * 0.4, fragment_speed)

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(frag, "global_position", global_position + dir * speed * fragment_lifetime, fragment_lifetime)
		tween.tween_property(frag, "modulate:a", 0.0, fragment_lifetime)
		tween.chain().tween_callback(frag.queue_free)


func _create_fragment_node(is_ore: bool) -> Node2D:
	var texture = _get_random_fragment_texture(is_ore)
	if texture:
		var frag = Sprite2D.new()
		frag.texture = texture
		frag.centered = true
		frag.scale = Vector2.ONE * fragment_texture_scale
		frag.rotation = randf_range(0.0, TAU)
		return frag
	var poly = Polygon2D.new()
	var s = randf_range(fragment_size * 0.5, fragment_size * 1.5)
	poly.polygon = PackedVector2Array([
		Vector2(-s * randf_range(0.5, 1.0), -s * randf_range(0.5, 1.0)),
		Vector2(s * randf_range(0.5, 1.0), -s * randf_range(0.3, 0.8)),
		Vector2(s * randf_range(0.3, 0.8), s * randf_range(0.5, 1.0)),
		Vector2(-s * randf_range(0.3, 0.8), s * randf_range(0.3, 0.8)),
	])
	poly.color = ore_color if is_ore else chest_color
	return poly


func _get_random_fragment_texture(is_ore: bool) -> Texture2D:
	var paths = CRYSTAL_FRAGMENT_PATHS if is_ore else CRATE_FRAGMENT_PATHS
	var variant_paths: Array = paths[clampi(_fragment_variant_index, 0, paths.size() - 1)]
	var tex = load(variant_paths.pick_random())
	return tex if tex is Texture2D else null


func _update_fragment_variant_index() -> void:
	_fragment_variant_index = 0
	if not reward_texture:
		return
	var path = reward_texture.resource_path
	if path.contains("_02"):
		_fragment_variant_index = 1
	elif path.contains("_03"):
		_fragment_variant_index = 2


func _play_sfx(stream: AudioStream) -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.stream = stream
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)
	else:
		sfx.queue_free()


func _build_texture_outline(tex: Texture2D) -> PackedVector2Array:
	var image = tex.get_image()
	if not image:
		return PackedVector2Array()
	var img_size = image.get_size()
	var center = Vector2(img_size) * 0.5
	var radius = maxf(img_size.x, img_size.y) * 0.5
	var points: Array[Vector2] = []
	for i in outline_samples:
		var angle = TAU * float(i) / float(outline_samples)
		var dir = Vector2(cos(angle), sin(angle))
		var hit = center
		for step in range(int(radius), 0, -1):
			var probe = center + dir * float(step)
			var px = int(round(probe.x))
			var py = int(round(probe.y))
			if px < 0 or py < 0 or px >= img_size.x or py >= img_size.y:
				continue
			if image.get_pixel(px, py).a > alpha_threshold:
				hit = probe
				break
		points.append(hit - center)
	return PackedVector2Array(points)
