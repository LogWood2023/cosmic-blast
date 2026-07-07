extends Area2D
## Enemy bullet: straight flight, damages player on contact.

@export var speed: float = 500.0
@export var world_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var direction: Vector2 = Vector2.DOWN
var ignore_body: Node2D
var damage: int = 5
var explosion_center: Vector2
var max_travel: float = -1.0
var reflect_bounces_left: int = 0
var force_field_velocity: Vector2 = Vector2.ZERO
const FORCE_FIELD_BLEND: float = 10.0
const BulletBurstScript := preload("res://scripts/fx/BulletBurst.gd")
const DESTROY_BURST_COLOR := Color(1.0, 0.18, 0.12, 1.0)
const BULLET_COLOR := Color(1.0, 0.18, 0.12, 1.0)
const ANIM_COLUMNS: int = 5
const ANIM_ROWS: int = 4
const ANIM_FRAME_COUNT: int = ANIM_COLUMNS * ANIM_ROWS
const ANIM_FPS: float = 28.0

var _destroy_burst_spawned: bool = false
var _anim_time: float = 0.0
@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	add_to_group(&"force_field_projectiles")
	add_to_group(&"enemy_bullets")  # 供护盾僚机识别并拦截
	_setup_bullet_sprite()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_update_bullet_animation(delta)
	_apply_force_field_velocity(delta)
	if direction.length() > 0.001:
		rotation = direction.angle()
	position += direction * speed * delta

	if max_travel > 0 and position.distance_to(explosion_center) > max_travel:
		destroy()
		return

	var bounds := _active_bounds()
	if reflect_bounces_left > 0:
		_reflect_from_bounds(bounds)
		bounds = _active_bounds()
	if position.x < bounds.position.x - 60 or position.x > bounds.position.x + bounds.size.x + 60 or position.y < bounds.position.y - 60 or position.y > bounds.position.y + bounds.size.y + 60:
		destroy()


func _exit_tree() -> void:
	pass


func destroy() -> void:
	_spawn_destroy_burst()
	queue_free()


func _active_bounds() -> Rect2:
	if world_bounds.size != Vector2.ZERO:
		return world_bounds
	return Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		destroy()


func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(ignore_body) and body == ignore_body:
		return
	if body.is_in_group(&"space_rocks") or (body.get_parent() and body.get_parent().is_in_group(&"isolation_bands")):
		if reflect_bounces_left > 0:
			_reflect_from_body(body)
			return
		destroy()


func apply_force_field(accel: Vector2, delta: float) -> void:
	force_field_velocity += accel * delta


func _apply_force_field_velocity(delta: float) -> void:
	if force_field_velocity.length() <= 0.01:
		return
	var velocity := direction.normalized() * speed + force_field_velocity
	if velocity.length() > 0.01:
		direction = velocity.normalized()
	force_field_velocity = force_field_velocity.move_toward(Vector2.ZERO, force_field_velocity.length() * FORCE_FIELD_BLEND * delta)


func _setup_bullet_sprite() -> void:
	if not _sprite:
		return
	_sprite.hframes = ANIM_COLUMNS
	_sprite.vframes = ANIM_ROWS
	_sprite.frame = 0
	_sprite.modulate = BULLET_COLOR


func _update_bullet_animation(delta: float) -> void:
	if not _sprite:
		return
	_anim_time += delta
	_sprite.frame = int(_anim_time * ANIM_FPS) % ANIM_FRAME_COUNT


func _reflect_from_bounds(bounds: Rect2) -> void:
	var bounced := false
	var min_pos := bounds.position
	var max_pos := bounds.position + bounds.size
	if position.x < min_pos.x:
		position.x = min_pos.x
		direction.x = absf(direction.x)
		bounced = true
	elif position.x > max_pos.x:
		position.x = max_pos.x
		direction.x = -absf(direction.x)
		bounced = true
	if position.y < min_pos.y:
		position.y = min_pos.y
		direction.y = absf(direction.y)
		bounced = true
	elif position.y > max_pos.y:
		position.y = max_pos.y
		direction.y = -absf(direction.y)
		bounced = true
	if bounced:
		_consume_reflection()


func _reflect_from_body(body: Node2D) -> void:
	var parent = body.get_parent()
	var center := body.global_position
	if parent and parent is Node2D:
		center = (parent as Node2D).global_position
	var normal := (global_position - center).normalized()
	if normal == Vector2.ZERO:
		normal = -direction.normalized()
	direction = direction.bounce(normal).normalized()
	global_position += normal * 10.0
	_consume_reflection()


func _consume_reflection() -> void:
	reflect_bounces_left -= 1


func _spawn_destroy_burst() -> void:
	if _destroy_burst_spawned:
		return
	_destroy_burst_spawned = true
	var target := get_parent()
	if target == null or target.is_queued_for_deletion() or not target.is_inside_tree():
		return
	var burst = BulletBurstScript.new()
	burst.setup(DESTROY_BURST_COLOR, 16)
	var spawn_pos := global_position
	target.add_child(burst)
	burst.global_position = spawn_pos
