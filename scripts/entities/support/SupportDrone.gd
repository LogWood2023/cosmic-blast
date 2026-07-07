extends Node2D


@export var bullet_scene: PackedScene
@export var orbit_radius: float = 78.0
@export var orbit_speed: float = 2.4
@export var follow_speed: float = 10.0
@export var fire_interval: float = 0.55
@export var attack_range: float = 780.0
@export var bullet_speed: float = 880.0
@export var bullet_damage: int = 5
@export var homing_strength: float = 2.0
@export var homing_range: float = 460.0

var mining_radius: float = 0.0  # >0 时僚机会顺手吸拢附近矿物（采矿型僚机）

var owner_player: Node2D
var orbit_index: int = 0
var orbit_count: int = 1

var _fire_timer: float = 0.0
var _orbit_phase: float = 0.0
var _mine_timer: float = 0.0


func setup(owner: Node2D, index: int, count: int, stats: Dictionary = {}) -> void:
	owner_player = owner
	orbit_index = maxi(0, index)
	orbit_count = maxi(1, count)
	bullet_damage = maxi(1, bullet_damage + int(stats.get("atk_bonus", 0)) / 2)
	bullet_damage = maxi(1, int(round(float(bullet_damage) * float(stats.get("drone_damage_mult", 1.0)))))
	fire_interval = maxf(0.08, fire_interval * float(stats.get("drone_fire_interval_mult", 1.0)))
	# 僚机行为原型参数（狙击/连射/采矿由装备提供）
	var range_mult := maxf(0.2, float(stats.get("drone_range_mult", 1.0)))
	attack_range *= range_mult
	orbit_radius += float(orbit_index % 3) * 12.0 + maxf(0.0, float(orbit_count - 1)) * 3.0
	orbit_radius *= 1.0 + (range_mult - 1.0) * 0.35
	orbit_speed *= 1.0 + float(orbit_index) * 0.08
	bullet_speed *= maxf(0.2, float(stats.get("drone_bullet_speed_mult", 1.0)))
	var drone_homing := float(stats.get("drone_homing_strength", 0.0))
	homing_strength = maxf(homing_strength, maxf(drone_homing, float(stats.get("homing_strength", 0.0)) * 0.5))
	homing_range = maxf(homing_range, float(stats.get("homing_range", 0.0)))
	mining_radius = maxf(0.0, float(stats.get("drone_mining_radius", 0.0)))
	if bullet_scene == null and owner != null and owner.get("bullet_scene") != null:
		bullet_scene = owner.get("bullet_scene")


func _ready() -> void:
	add_to_group(&"player_support_drones")
	_orbit_phase = TAU * float(orbit_index) / maxf(float(orbit_count), 1.0)
	if owner_player == null:
		owner_player = get_tree().get_first_node_in_group(&"player") as Node2D


func _process(delta: float) -> void:
	if not is_instance_valid(owner_player):
		queue_free()
		return
	_update_orbit(delta)
	_update_fire(delta)
	if mining_radius > 0.0:
		_update_mining(delta)


func _update_orbit(delta: float) -> void:
	_orbit_phase += orbit_speed * delta
	var desired := owner_player.global_position + Vector2.RIGHT.rotated(_orbit_phase) * orbit_radius
	global_position = global_position.lerp(desired, clampf(follow_speed * delta, 0.0, 1.0))


func _update_fire(delta: float) -> void:
	_fire_timer = maxf(0.0, _fire_timer - delta)
	if _fire_timer > 0.0:
		return
	var target := _find_target()
	if target == null:
		return
	_fire_timer = fire_interval
	_fire_at(target)


func _update_mining(delta: float) -> void:
	_mine_timer -= delta
	if _mine_timer > 0.0:
		return
	_mine_timer = 0.2  # 节流，避免每帧全场扫描
	var r2 := mining_radius * mining_radius
	for pickup in get_tree().get_nodes_in_group(&"mineral_pickups"):
		if not is_instance_valid(pickup) or not pickup is Node2D:
			continue
		if global_position.distance_squared_to((pickup as Node2D).global_position) <= r2:
			if pickup.has_method("trigger_attract"):
				pickup.trigger_attract()


func _find_target() -> Node:
	var best: Node = null
	var best_dist_sq := attack_range * attack_range
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


func _fire_at(target: Node) -> void:
	if bullet_scene == null:
		return
	var target_pos := _get_node_world_position(target)
	var direction := target_pos - global_position
	if direction.length_squared() <= 1.0:
		return
	var bullet = bullet_scene.instantiate()
	var forward := direction.normalized()
	bullet.global_position = global_position + forward * 26.0
	bullet.direction = forward
	bullet.atk = bullet_damage
	if bullet.get("speed") != null:
		bullet.speed = bullet_speed
	if bullet.get("homing_strength") != null:
		bullet.homing_strength = homing_strength
	if bullet.get("homing_range") != null:
		bullet.homing_range = homing_range
	if owner_player != null and owner_player.get("movement_bounds") != null:
		var bounds: Rect2 = owner_player.get("movement_bounds")
		if bounds.size != Vector2.ZERO and bullet.get("world_bounds") != null:
			bullet.world_bounds = bounds
	bullet.rotation = forward.angle()
	bullet.z_index = -80
	get_tree().current_scene.add_child(bullet)


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
