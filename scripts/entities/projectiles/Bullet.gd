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
var pierce_left: int = 0            # 穿透：命中敌人后剩余可穿透次数
var chain_left: int = 0             # 跳弹：命中后剩余可转向次数
var dot_damage_mult: float = 0.0    # DoT：命中后按 atk 比例施加灼烧
var blackhole_strength: float = 0.0 # 黑洞弹：命中处生成引力奇点的吸附力
var slow_ratio: float = 0.0         # 减速扭曲：命中敌人的减速比例
var phase_left: int = 0             # 相位穿透：可穿透的障碍数
var mark_bonus: float = 0.0         # 质量标记：命中打标记，对已标记敌人增伤
const DOT_SCRIPT := preload("res://scripts/fx/DamageOverTime.gd")
const WARP_BLACKHOLE := preload("res://scripts/fx/WarpBlackhole.gd")
const WARP_SLOW := preload("res://scripts/fx/WarpSlow.gd")
const MARK_DURATION_MS: int = 4000
const CHAIN_RANGE: float = 620.0
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
var _hit_enemies: Array[Node] = []
var _homing_target: Node = null
var _homing_retarget_timer: float = 0.0
const HOMING_RETARGET_INTERVAL: float = 0.2
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
		# 出界不算命中：直接移除，不触发分裂和销毁特效
		queue_free()


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
		_hit_enemy(area)
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
		# 相位穿透：无视障碍继续飞
		if phase_left > 0:
			phase_left -= 1
			return
		destroy()


func _hit_enemy(enemy: Node) -> void:
	if _hit_enemies.has(enemy):
		return
	_hit_enemies.append(enemy)
	var dmg := atk
	# 质量标记：对仍在标记有效期内的敌人增伤
	if enemy.has_meta(&"warped_mark_until") and Time.get_ticks_msec() < int(enemy.get_meta(&"warped_mark_until")):
		dmg = maxi(1, int(round(float(dmg) * (1.0 + float(enemy.get_meta(&"warped_mark_bonus", 0.0))))))
	if enemy.has_method("take_damage"):
		enemy.take_damage(dmg, self)
	_apply_bullet_dot(enemy)
	_apply_warp_effects(enemy)
	# 穿透优先（继续直飞）；否则跳弹（转向下一敌）；都没有则销毁
	if pierce_left > 0:
		pierce_left -= 1
		return
	if chain_left > 0:
		var next := _find_chain_target(enemy)
		if next != null:
			chain_left -= 1
			var to_next: Vector2 = (_get_node_world_position(next) - global_position)
			if to_next.length() > 1.0:
				direction = to_next.normalized()
				rotation = direction.angle()
				return
	destroy()


func _apply_bullet_dot(enemy: Node) -> void:
	if dot_damage_mult <= 0.0:
		return
	var dot = DOT_SCRIPT.new()
	dot.setup(enemy, maxi(1, int(round(float(atk) * dot_damage_mult))))
	var scene := get_tree().current_scene
	if scene != null and scene.is_inside_tree():
		scene.add_child(dot)


func _apply_warp_effects(enemy: Node) -> void:
	# 质量标记：给敌人打上标记（后续任意子弹对其增伤）
	if mark_bonus > 0.0:
		enemy.set_meta(&"warped_mark_bonus", mark_bonus)
		enemy.set_meta(&"warped_mark_until", Time.get_ticks_msec() + MARK_DURATION_MS)
	# 黑洞弹：命中处生成引力奇点吸附一片敌人
	if blackhole_strength > 0.0:
		var bh = WARP_BLACKHOLE.new()
		bh.setup(global_position, blackhole_strength, 260.0)
		var scene := get_tree().current_scene
		if scene != null and scene.is_inside_tree():
			scene.add_child(bh)
	# 减速扭曲：每个敌人最多一个减速节点，重复命中刷新
	if slow_ratio > 0.0 and enemy is Node:
		var existing = enemy.get_node_or_null("WarpSlow")
		if existing != null and existing.has_method("refresh"):
			existing.refresh(1.5)
		else:
			var sl = WARP_SLOW.new()
			sl.name = "WarpSlow"
			enemy.add_child(sl)
			sl.setup(slow_ratio, 1.5)


func _find_chain_target(exclude: Node) -> Node:
	var best: Node = null
	var best_dist := CHAIN_RANGE
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if not is_instance_valid(node) or node == exclude or node.is_queued_for_deletion():
			continue
		if _hit_enemies.has(node):
			continue
		if node is CanvasItem and not (node as CanvasItem).visible:
			continue
		var d := global_position.distance_to(_get_node_world_position(node))
		if d < best_dist:
			best_dist = d
			best = node
	return best


func is_player_bullet() -> bool:
	return true


func apply_force_field(accel: Vector2, delta: float) -> void:
	force_field_velocity += accel * delta


func _update_homing(delta: float) -> void:
	if homing_strength <= 0.0 or homing_range <= 0.0:
		return
	# 全场扫描开销大，目标每 0.2s 重选一次即可
	_homing_retarget_timer -= delta
	if _homing_retarget_timer <= 0.0 or not is_instance_valid(_homing_target) or _homing_target.is_queued_for_deletion():
		_homing_target = _find_homing_target()
		_homing_retarget_timer = HOMING_RETARGET_INTERVAL
	var target := _homing_target
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
		# 斥力推开：敌人被推离子弹（原方向取反，与黑洞的"吸"相对）
		target.global_position -= to_center / dist * gravity_pull_strength * falloff * delta


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
