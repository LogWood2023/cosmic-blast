extends Area2D

@export var speed: float = 500.0
@export var damage: int = 5
@export var lifetime: float = 8.0

var direction: Vector2 = Vector2.RIGHT
var ignore_body: Node2D
var _age: float = 0.0
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
	_setup_bullet_sprite()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_update_bullet_animation(delta)
	_age += delta
	if _age >= lifetime:
		destroy()
		return
	_apply_force_field_velocity(delta)
	if direction.length() > 0.001:
		rotation = direction.angle()
	global_position += direction * speed * delta


func _exit_tree() -> void:
	pass


func destroy() -> void:
	_spawn_destroy_burst()
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		destroy()


func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(ignore_body) and body == ignore_body:
		return
	var parent = body.get_parent()
	if body.is_in_group(&"space_rocks") or (parent and parent.is_in_group(&"isolation_bands")):
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
