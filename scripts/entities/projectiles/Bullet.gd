extends Area2D
## 玩家子弹 —— 飞行 + 碰撞扣血

@export var speed: float = 500.0
@export var world_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var direction: Vector2 = Vector2.UP
var atk: int = 1
var force_field_velocity: Vector2 = Vector2.ZERO
var split_count: int = 0
var split_spread_degrees: float = 0.0
var split_damage_mult: float = 0.0
var homing_strength: float = 0.0
var homing_range: float = 0.0
var gravity_pull_strength: float = 0.0
var gravity_pull_radius: float = 0.0
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
	_update_homing(delta)
	_apply_gravity_pull(delta)
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
	_spawn_split_projectiles()
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


func _update_homing(delta: float) -> void:
	if homing_strength <= 0.0 or homing_range <= 0.0:
		return
	var target := _find_homing_target()
	if target == null:
		return
	var to_target := _get_node_world_position(target) - global_position
	if to_target.length_squared() <= 1.0:
		return
	direction = direction.normalized().lerp(to_target.normalized(), clampf(homing_strength * delta, 0.0, 1.0)).normalized()


func _find_homing_target() -> Node:
	var best: Node = null
	var best_dist_sq := homing_range * homing_range
	for group_name in [&"enemies", &"boss", &"defense_turrets"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(node) or node.is_queued_for_deletion():
				continue
			if node is CanvasItem and not (node as CanvasItem).visible:
				continue
			var dist_sq := global_position.distance_squared_to(_get_node_world_position(node))
			if dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best = node
	return best


func _get_node_world_position(node: Node) -> Vector2:
	if node.has_method("get_map_position"):
		var map_pos = node.call("get_map_position")
		if map_pos is Vector2:
			return map_pos
	if node.has_method("get_base_position"):
		var base_pos = node.call("get_base_position")
		if base_pos is Vector2:
			return base_pos
	if node is Node2D:
		return (node as Node2D).global_position
	return global_position


func _apply_force_field_velocity(delta: float) -> void:
	if force_field_velocity.length() <= 0.01:
		return
	var velocity := direction.normalized() * speed + force_field_velocity
	if velocity.length() > 0.01:
		direction = velocity.normalized()
	force_field_velocity = force_field_velocity.move_toward(Vector2.ZERO, force_field_velocity.length() * FORCE_FIELD_BLEND * delta)


func _apply_gravity_pull(delta: float) -> void:
	if gravity_pull_strength <= 0.0 or gravity_pull_radius <= 0.0:
		return
	var radius_sq := gravity_pull_radius * gravity_pull_radius
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if node is CanvasItem and not (node as CanvasItem).visible:
			continue
		if not node is Node2D:
			continue
		var target := node as Node2D
		var to_center := global_position - target.global_position
		var dist_sq := to_center.length_squared()
		if dist_sq <= 1.0 or dist_sq > radius_sq:
			continue
		var dist := sqrt(dist_sq)
		var falloff := 1.0 - clampf(dist / gravity_pull_radius, 0.0, 1.0)
		target.global_position += to_center / dist * gravity_pull_strength * falloff * delta


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


func _spawn_split_projectiles() -> void:
	if split_count <= 0 or split_spread_degrees <= 0.0 or split_damage_mult <= 0.0:
		return
	var target := get_parent()
	if target == null or target.is_queued_for_deletion() or not target.is_inside_tree():
		return
	var count := maxi(1, split_count)
	var spread_rad := deg_to_rad(split_spread_degrees)
	for i in range(count):
		var offset := 0.0
		if count > 1:
			offset = lerpf(-spread_rad * 0.5, spread_rad * 0.5, float(i) / float(count - 1))
		var child = duplicate()
		child.direction = direction.normalized().rotated(offset)
		child.atk = maxi(1, int(round(float(atk) * split_damage_mult)))
		child.split_count = 0
		child.split_spread_degrees = 0.0
		child.split_damage_mult = 0.0
		child.force_field_velocity = Vector2.ZERO
		child.global_position = global_position + child.direction * 12.0
		child.rotation = child.direction.angle()
		target.add_child(child)
