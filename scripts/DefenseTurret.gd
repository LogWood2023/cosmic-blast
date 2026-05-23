extends Area2D

const ROOM_BOUNDS: Rect2 = Rect2(Vector2.ZERO, Vector2(10800, 10800))

@export var hp: int = 50
@export var atk: int = 5
@export var bullet_speed: float = 500.0
@export var min_shoot_cooldown: float = 1.0
@export var max_shoot_cooldown: float = 3.0
@export var max_shoot_distance: float = 2000.0
@export var aim_limit_degrees: float = 30.0
@export var barrel_length: float = 90.0
@export var barrel_width: float = 18.0
@export var base_radius: float = 48.0
@export var fragment_count: int = 10
@export var explosion_scale: float = 0.5

const BASE_TEXTURE_PATHS: Array[String] = [
	"res://assets/images/turret/turret_base_01.png",
	"res://assets/images/turret/turret_base_02.png",
	"res://assets/images/turret/turret_base_03.png",
]
const BARREL_TEXTURE_PATHS: Array[String] = [
	"res://assets/images/turret/turret_barrel_01.png",
	"res://assets/images/turret/turret_barrel_02.png",
	"res://assets/images/turret/turret_barrel_03.png",
]
const BULLET_SCENE := preload("res://scenes/EnemyBullet.tscn")
const EXPLOSION_TEX := preload("res://assets/images/fx/explosion.png")
const DEBRIS_TEX := preload("res://assets/images/fx/debris.png")
const EXPLOSION_SFX := preload("res://assets/audio/explosion.wav")
const HIT_SFX := preload("res://assets/audio/enemy_hit.wav")
const ExplosionScript := preload("res://scripts/Explosion.gd")
const DebrisScript := preload("res://scripts/Debris.gd")
const HealthBarScript := preload("res://scripts/HealthBar.gd")

var _player: Area2D
var _shoot_timer: float = 0.0
var _base_aim_angle: float = 0.0
var _current_barrel_angle: float = 0.0
var _follow_target: Node2D
var _follow_offset: Vector2 = Vector2.ZERO
var _hp: int = 50
var _broken: bool = false
var _health_bar: Node2D
var _is_shaking: bool = false
var _shake_elapsed: float = 0.0
var _map_position: Vector2 = Vector2.ZERO

@onready var base_sprite: Sprite2D = $Base
@onready var barrel_sprite: Sprite2D = $BarrelPivot/Barrel
@onready var barrel_pivot: Node2D = $BarrelPivot
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group(&"enemies")
	add_to_group(&"defense_turrets")
	collision_layer = 2
	collision_mask = 5
	area_entered.connect(_on_area_entered)
	_player = get_tree().get_first_node_in_group(&"player")
	_hp = hp
	_shoot_timer = randf_range(min_shoot_cooldown, max_shoot_cooldown)
	_setup_visuals()
	_setup_health_bar()


func _process(delta: float) -> void:
	if _broken:
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player")
	if is_instance_valid(_follow_target):
		global_position = _follow_target.global_position + _follow_offset
	global_position = global_position.clamp(ROOM_BOUNDS.position, ROOM_BOUNDS.position + ROOM_BOUNDS.size)
	_update_aim()
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = randf_range(min_shoot_cooldown, max_shoot_cooldown)
		_try_shoot()
	if _is_shaking:
		_update_shake(delta)


func setup_anchor(target: Node2D, offset: Vector2, outward_angle: float) -> void:
	_follow_target = target
	_follow_offset = offset
	_base_aim_angle = outward_angle
	_current_barrel_angle = outward_angle
	base_sprite.rotation = outward_angle + PI * 0.5
	global_rotation = 0.0
	if is_instance_valid(_follow_target):
		global_position = _follow_target.global_position + _follow_offset
		if is_instance_valid(_follow_target) and _follow_target.has_method("get_surface_anchor"):
			var outward = Vector2(cos(_base_aim_angle), sin(_base_aim_angle))
			global_position = _follow_target.get_surface_anchor(_base_aim_angle, 0.0) + outward * 24.0
	_map_position = global_position
	_update_aim()


func get_map_position() -> Vector2:
	return _map_position


func get_map_icon_texture() -> Texture2D:
	return base_sprite.texture


func take_damage(amount: int) -> void:
	if _broken:
		return
	_hp -= amount
	if _health_bar:
		_health_bar.take_hit(_hp)
	if _hp <= 0:
		_break()
	else:
		_play_sfx(HIT_SFX)
		_is_shaking = true
		_shake_elapsed = 0.0


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)


func _setup_visuals() -> void:
	if BASE_TEXTURE_PATHS.size() > 0:
		var base_texture = load(BASE_TEXTURE_PATHS.pick_random())
		if base_texture is Texture2D:
			base_sprite.texture = base_texture
	if base_sprite.texture:
		base_sprite.centered = true
		base_sprite.show_behind_parent = false
		base_sprite.z_index = 1
		var base_size = base_sprite.texture.get_size()
		var base_diameter = base_radius * 2.0
		base_sprite.scale = Vector2(
			base_diameter / maxf(1.0, base_size.x),
			base_diameter / maxf(1.0, base_size.y)
		)
	if BARREL_TEXTURE_PATHS.size() > 0:
		var barrel_texture = load(BARREL_TEXTURE_PATHS.pick_random())
		if barrel_texture is Texture2D:
			barrel_sprite.texture = barrel_texture
	if barrel_sprite.texture:
		barrel_sprite.centered = false
		barrel_sprite.z_index = 0
		var tex_size = barrel_sprite.texture.get_size()
		barrel_sprite.scale = Vector2(
			barrel_length / maxf(1.0, tex_size.x),
			barrel_width / maxf(1.0, tex_size.y)
		)
		barrel_sprite.offset = Vector2(0.0, -tex_size.y * 0.5)
	var shape = CircleShape2D.new()
	shape.radius = base_radius
	collision_shape.shape = shape


func _setup_health_bar() -> void:
	_health_bar = Node2D.new()
	_health_bar.set_script(HealthBarScript)
	_health_bar.position = Vector2(0.0, -40.0)
	add_child(_health_bar)
	_health_bar.setup(hp)


func _update_aim() -> void:
	if not is_instance_valid(_player):
		return
	var to_player = _player.global_position - global_position
	if to_player == Vector2.ZERO:
		return
	var desired = to_player.angle()
	var delta = angle_difference(_base_aim_angle, desired)
	var limit = deg_to_rad(aim_limit_degrees)
	_current_barrel_angle = _base_aim_angle + clampf(delta, -limit, limit)
	barrel_pivot.global_rotation = _current_barrel_angle
	base_sprite.rotation = _base_aim_angle + PI * 0.5


func _try_shoot() -> void:
	if not is_instance_valid(_player):
		return
	var to_player = _player.global_position - global_position
	if to_player.length() > max_shoot_distance:
		return
	var desired = to_player.angle()
	var limit = deg_to_rad(aim_limit_degrees)
	if absf(angle_difference(_base_aim_angle, desired)) > limit:
		return
	if _has_obstacle_to_player():
		return
	_shoot(to_player.normalized())


func _has_obstacle_to_player() -> bool:
	var space_state = get_world_2d().direct_space_state
	var dir = (_player.global_position - global_position).normalized()
	var start = global_position + dir * maxf(8.0, base_radius * 0.5 * scale.x)
	var query = PhysicsRayQueryParameters2D.create(start, _player.global_position)
	var excludes: Array[RID] = [get_rid(), _player.get_rid()]
	if is_instance_valid(_follow_target) and _follow_target is CollisionObject2D:
		excludes.append(_follow_target.get_rid())
	query.exclude = excludes
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	return not result.is_empty()


func _shoot(dir: Vector2) -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = global_position + dir * barrel_length
	bullet.direction = dir
	bullet.speed = bullet_speed
	bullet.damage = atk
	if bullet.get("world_bounds") != null:
		bullet.world_bounds = ROOM_BOUNDS
	bullet.rotation = dir.angle()
	get_tree().current_scene.add_child(bullet)


func _break() -> void:
	_broken = true
	GameManager.add_score(100)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	_play_sfx(EXPLOSION_SFX)
	if _health_bar:
		_health_bar.queue_free()
	_spawn_explosion()
	_spawn_debris()
	queue_free()


func _spawn_explosion() -> void:
	var exp = Sprite2D.new()
	exp.set_script(ExplosionScript)
	exp.texture = EXPLOSION_TEX
	exp.global_position = global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
	exp.rotation = randf_range(0.0, TAU)
	exp.scale = Vector2(explosion_scale, explosion_scale)
	exp.z_index = 100
	get_tree().current_scene.add_child(exp)


func _spawn_debris() -> void:
	const QUAD = 512
	for _i in randi_range(6, 10):
		var d = Sprite2D.new()
		d.set_script(DebrisScript)
		d.texture = DEBRIS_TEX
		d.global_position = global_position
		d.scale = Vector2(randf_range(0.05, 0.10), randf_range(0.05, 0.10))
		d.rotation = randf_range(0.0, TAU)
		d.region_enabled = true
		d.region_rect = Rect2(randi_range(0, 1) * QUAD, randi_range(0, 1) * QUAD, QUAD, QUAD)
		var a = randf_range(0.0, TAU)
		d.velocity = Vector2(cos(a), sin(a)) * randf_range(80.0, 280.0)
		d.rotation_speed = randf_range(-10.0, 10.0)
		d.z_index = -100
		get_tree().current_scene.add_child(d)


func _update_shake(delta: float) -> void:
	_shake_elapsed += delta
	if _shake_elapsed >= 0.2:
		barrel_pivot.position = Vector2.ZERO
		base_sprite.position = Vector2.ZERO
		_is_shaking = false
	else:
		var shake_offset = Vector2(
			sin(_shake_elapsed * 50.0) * 4.0,
			cos(_shake_elapsed * 47.0) * 4.0
		)
		barrel_pivot.position = shake_offset
		base_sprite.position = shake_offset


func _play_sfx(stream: AudioStream) -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.stream = stream
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
