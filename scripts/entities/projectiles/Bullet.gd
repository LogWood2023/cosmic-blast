extends Area2D
## 玩家子弹 —— 飞行 + 碰撞扣血

@export var speed: float = 500.0
@export var world_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var direction: Vector2 = Vector2.UP
var atk: int = 1
var force_field_velocity: Vector2 = Vector2.ZERO
const FORCE_FIELD_BLEND: float = 10.0
const BulletBurstScript := preload("res://scripts/fx/BulletBurst.gd")
const DESTROY_BURST_COLOR := Color(0.25, 0.75, 1.0, 1.0)
const BULLET_COLOR := Color(0.25, 0.75, 1.0, 1.0)
const ANIM_COLUMNS: int = 5
const ANIM_ROWS: int = 4
const ANIM_FRAME_COUNT: int = ANIM_COLUMNS * ANIM_ROWS
const ANIM_FPS: float = 28.0

var _destroy_burst_spawned: bool = false
var _anim_time: float = 0.0
@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	add_to_group(&"force_field_projectiles")
	collision_mask = 1 | 2 | 4
	_setup_bullet_sprite()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_update_bullet_animation(delta)
	_apply_force_field_velocity(delta)
	if direction.length() > 0.001:
		rotation = direction.angle()
	position += direction * speed * delta
	var bounds = _active_bounds()
	if position.x < bounds.position.x - 50 or position.x > bounds.position.x + bounds.size.x + 50 or position.y < bounds.position.y - 50 or position.y > bounds.position.y + bounds.size.y + 50:
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
	if area.is_in_group(&"enemies"):
		area.take_damage(atk, self)
		destroy()
	elif area.is_in_group(&"explore_rewards"):
		if area.has_method("take_damage"):
			area.take_damage(1)
		destroy()
	elif area.is_in_group(&"space_clutter"):
		if area.has_method("take_damage"):
			area.take_damage(1)
		destroy()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"space_rocks") or (body.get_parent() and body.get_parent().is_in_group(&"isolation_bands")):
		destroy()


func is_player_bullet() -> bool:
	return true


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
