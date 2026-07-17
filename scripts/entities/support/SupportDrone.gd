extends Node2D
## 支援僚机：护盾型环绕玩家，其余类型在巡航时保持三角编队、交战时执行战术换位。
## shooter 射击 / miner 采矿 / guardian 护盾拦弹 / kamikaze 自爆 / medic 治疗

const BulletBurstScript := preload("res://scripts/fx/BulletBurst.gd")

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
@export var formation_row_gap: float = 46.0
@export var formation_spacing: float = 54.0
@export var combat_speed: float = 210.0
@export var combat_acceleration: float = 760.0
@export var combat_roam_radius: float = 145.0

const FREQUENCY_MULTIPLIER: float = 3.0
const EFFECT_MULTIPLIER: float = 1.0 / FREQUENCY_MULTIPLIER
const COMBAT_SCAN_INTERVAL: float = 0.14
const COMBAT_RANGE_MULTIPLIER: float = 1.25
const COMBAT_WAYPOINT_MIN_TIME: float = 0.62
const COMBAT_WAYPOINT_MAX_TIME: float = 1.15
const COMBAT_ARRIVE_RADIUS: float = 82.0
const FORMATION_FIRST_ROW_DISTANCE: float = 72.0
const FORMATION_LEASH_DISTANCE: float = 285.0
const DRONE_SEPARATION_RADIUS: float = 44.0
const MINING_TICK: float = 0.2 / FREQUENCY_MULTIPLIER
const SHIELD_TICK: float = 0.12 / FREQUENCY_MULTIPLIER
const SHIELD_MAX_PER_TICK: int = 1
const KAMI_CHARGE_TIME: float = 4.5 / FREQUENCY_MULTIPLIER
const KAMI_COOLDOWN: float = 2.5 / FREQUENCY_MULTIPLIER
const KAMI_DASH_SPEED: float = 940.0 * FREQUENCY_MULTIPLIER
const KAMI_MAX_DASH_TIME: float = 1.4 / FREQUENCY_MULTIPLIER

enum KamikazeState { CHARGING, DASHING, COOLDOWN }

var behavior: StringName = &"shooter"
var mining_radius: float = 0.0
var shield_radius: float = 230.0
var blast_radius: float = 190.0
var blast_damage: int = 42
var heal_amount: int = 4
var heal_interval: float = 4.5

var owner_player: Node2D
var orbit_index: int = 0
var orbit_count: int = 1
var formation_index: int = 0
var formation_count: int = 1

var _fire_timer: float = 0.0
var _orbit_phase: float = 0.0
var _mine_timer: float = 0.0
var _mine_cursor: int = 0
var _shield_timer: float = 0.0
var _heal_timer: float = 0.0
var _kami_state: KamikazeState = KamikazeState.CHARGING
var _kami_timer: float = 0.0
var _kami_target: Node2D
var _combat_target: Node
var _combat_scan_timer: float = 0.0
var _combat_waypoint: Vector2 = Vector2.ZERO
var _combat_waypoint_timer: float = 0.0
var _formation_sync_timer: float = 0.0
var _movement_velocity: Vector2 = Vector2.ZERO
var _visual_time: float = 0.0
var _ability_flash: float = 0.0
var _bullet_effect_carry: float = 0.0
var _heal_effect_carry: float = 0.0
var _blast_effect_carry: float = 0.0
var _rng := RandomNumberGenerator.new()

@onready var visual: Node2D = $Visual
@onready var glow_outer: Polygon2D = $Visual/GlowOuter
@onready var glow_inner: Polygon2D = $Visual/GlowInner
@onready var glow_core: Polygon2D = $Visual/GlowCore
@onready var body: Polygon2D = $Visual/Body
@onready var shadow: Polygon2D = $Visual/Shadow
@onready var fold: Polygon2D = $Visual/Fold
@onready var core: Polygon2D = $Visual/Signal
@onready var rear_node_left: Polygon2D = $Visual/RearNodeLeft
@onready var rear_node_right: Polygon2D = $Visual/RearNodeRight


func setup(owner: Node2D, index: int, count: int, spec: Dictionary = {}) -> void:
	owner_player = owner
	orbit_index = maxi(0, index)
	orbit_count = maxi(1, count)
	formation_index = maxi(0, int(spec.get("formation_index", orbit_index)))
	formation_count = maxi(1, int(spec.get("formation_count", orbit_count)))
	behavior = StringName(spec.get("behavior", &"shooter"))
	bullet_damage = maxi(1, bullet_damage + int(spec.get("atk_bonus", 0)) / 2)
	bullet_damage = maxi(1, int(round(float(bullet_damage) * float(spec.get("drone_damage_mult", 1.0)))))
	# 三倍触发频率；单次效果在实际结算时按三分之一并保留整数余数。
	fire_interval = maxf(0.08 / FREQUENCY_MULTIPLIER, fire_interval * float(spec.get("drone_fire_interval_mult", 1.0)) / FREQUENCY_MULTIPLIER)
	heal_interval = maxf(0.1, heal_interval / FREQUENCY_MULTIPLIER)
	var range_mult := maxf(0.2, float(spec.get("drone_range_mult", 1.0)))
	attack_range *= range_mult
	orbit_radius += float(orbit_index % 3) * 12.0 + maxf(0.0, float(orbit_count - 1)) * 3.0
	orbit_radius *= 1.0 + (range_mult - 1.0) * 0.35
	orbit_speed *= 1.0 + float(orbit_index) * 0.08
	bullet_speed *= maxf(0.2, float(spec.get("drone_bullet_speed_mult", 1.0)))
	homing_strength = maxf(homing_strength, float(spec.get("drone_homing_strength", 0.0)))
	homing_range = maxf(homing_range, float(spec.get("drone_homing_range", 0.0)))
	mining_radius = maxf(0.0, float(spec.get("drone_mining_radius", 0.0)))
	shield_radius = maxf(120.0, float(spec.get("drone_shield_radius", shield_radius)))
	blast_damage = maxi(1, int(round(float(blast_damage) * float(spec.get("drone_blast_damage_mult", 1.0)))))
	heal_amount = maxi(1, int(round(float(spec.get("drone_heal_amount", heal_amount)))))
	_kami_timer = KAMI_CHARGE_TIME
	if bullet_scene == null and owner != null and owner.get("bullet_scene") != null:
		bullet_scene = owner.get("bullet_scene")


func _ready() -> void:
	top_level = true
	if is_instance_valid(owner_player):
		global_position = owner_player.global_position + Vector2(42.0, 0.0).rotated(TAU * float(orbit_index) / maxf(float(orbit_count), 1.0))
	add_to_group(&"player_support_drones")
	_orbit_phase = TAU * float(orbit_index) / maxf(float(orbit_count), 1.0)
	_rng.seed = hash("%s:%d" % [str(owner_player.get_instance_id() if owner_player != null else 0), orbit_index])
	if owner_player == null:
		owner_player = get_tree().get_first_node_in_group(&"player") as Node2D
	_apply_behavior_visuals()
	_combat_waypoint = global_position


func _process(delta: float) -> void:
	if not is_instance_valid(owner_player):
		queue_free()
		return
	_update_combat_target(delta)
	match behavior:
		&"guardian":
			_update_orbit(delta)
			_update_shield(delta)
		&"kamikaze":
			_update_kamikaze(delta)
		&"medic":
			_update_flight(delta)
			_update_heal(delta)
		&"miner":
			_update_flight(delta)
			_update_fire(delta)
			_update_mining(delta)
		_:
			_update_flight(delta)
			_update_fire(delta)
	_update_visual_animation(delta)


func _update_combat_target(delta: float) -> void:
	_combat_scan_timer -= delta
	if _combat_scan_timer > 0.0:
		return
	_combat_scan_timer = COMBAT_SCAN_INTERVAL
	var was_in_combat := is_instance_valid(_combat_target)
	_combat_target = _find_target(attack_range * COMBAT_RANGE_MULTIPLIER)
	if is_instance_valid(_combat_target) and not was_in_combat:
		_combat_waypoint_timer = 0.0


func _update_flight(delta: float) -> void:
	_formation_sync_timer -= delta
	if _formation_sync_timer <= 0.0:
		_formation_sync_timer = 0.5
		_sync_formation_slot()
	if is_instance_valid(_combat_target):
		_update_combat_movement(delta)
	else:
		_update_formation(delta)


func _sync_formation_slot() -> void:
	var resolved_index := 0
	var resolved_count := 0
	for node in get_tree().get_nodes_in_group(&"player_support_drones"):
		if not is_instance_valid(node) or node.is_queued_for_deletion() or node.get("owner_player") != owner_player:
			continue
		if StringName(node.get("behavior")) == &"guardian":
			continue
		resolved_count += 1
		if int(node.get("orbit_index")) < orbit_index:
			resolved_index += 1
	formation_index = resolved_index
	formation_count = maxi(1, resolved_count)


func _update_formation(delta: float) -> void:
	var previous := global_position
	var desired := _get_formation_position()
	var blend := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, blend)
	_movement_velocity = (global_position - previous) / maxf(delta, 0.0001)


func _get_formation_position() -> Vector2:
	var slot := formation_index
	var row := 0
	var row_capacity := 1 if formation_count <= 1 else 2
	var row_start := 0
	while slot >= row_capacity:
		slot -= row_capacity
		row_start += row_capacity
		row += 1
		row_capacity = row + 1
		if formation_count > 1:
			row_capacity += 1
	var occupied_in_row := mini(row_capacity, formation_count - row_start)
	var forward := Vector2.UP.rotated(owner_player.global_rotation)
	var right := forward.rotated(PI * 0.5)
	var lateral_slot := float(slot) - float(occupied_in_row - 1) * 0.5
	var behind_distance := FORMATION_FIRST_ROW_DISTANCE + float(row) * formation_row_gap
	return owner_player.global_position - forward * behind_distance + right * lateral_slot * formation_spacing


## 持久战术航点 + 到达减速 + 编队回拉 + 僚机分离：随机性只在换点时发生，不会形成布朗抖动。
func _update_combat_movement(delta: float) -> void:
	_combat_waypoint_timer -= delta
	if _combat_waypoint_timer <= 0.0 or global_position.distance_squared_to(_combat_waypoint) < 18.0 * 18.0:
		_pick_combat_waypoint()
	var to_waypoint := _combat_waypoint - global_position
	var distance := to_waypoint.length()
	var arrive_scale := clampf(distance / COMBAT_ARRIVE_RADIUS, 0.0, 1.0)
	var desired_velocity := Vector2.ZERO
	if distance > 1.0:
		desired_velocity = to_waypoint / distance * combat_speed * arrive_scale
	desired_velocity += _get_separation_velocity()
	var owner_distance := global_position.distance_to(owner_player.global_position)
	if owner_distance > FORMATION_LEASH_DISTANCE:
		var leash_strength := clampf((owner_distance - FORMATION_LEASH_DISTANCE) / 120.0, 0.0, 1.0)
		desired_velocity = desired_velocity.lerp(global_position.direction_to(owner_player.global_position) * combat_speed, leash_strength)
	_movement_velocity = _movement_velocity.move_toward(desired_velocity, combat_acceleration * delta)
	global_position += _movement_velocity * delta
	_clamp_to_owner_bounds()


func _pick_combat_waypoint() -> void:
	_combat_waypoint_timer = _rng.randf_range(COMBAT_WAYPOINT_MIN_TIME, COMBAT_WAYPOINT_MAX_TIME)
	var formation_anchor := _get_formation_position()
	var target_direction := Vector2.UP.rotated(owner_player.global_rotation)
	if is_instance_valid(_combat_target):
		var to_target := _get_node_world_position(_combat_target) - owner_player.global_position
		if to_target.length_squared() > 1.0:
			target_direction = to_target.normalized()
	var tangent := target_direction.rotated(PI * 0.5)
	var strafe := _rng.randf_range(-combat_roam_radius, combat_roam_radius)
	var advance := _rng.randf_range(-combat_roam_radius * 0.35, combat_roam_radius * 0.62)
	_combat_waypoint = formation_anchor + tangent * strafe + target_direction * advance
	_combat_waypoint = _clamp_point_to_owner_bounds(_combat_waypoint, 26.0)


func _get_separation_velocity() -> Vector2:
	var separation := Vector2.ZERO
	for node in get_tree().get_nodes_in_group(&"player_support_drones"):
		if node == self or not is_instance_valid(node) or not node is Node2D:
			continue
		if node.get("owner_player") != owner_player:
			continue
		var offset := global_position - (node as Node2D).global_position
		var distance := offset.length()
		if distance > 0.01 and distance < DRONE_SEPARATION_RADIUS:
			separation += offset / distance * combat_speed * (1.0 - distance / DRONE_SEPARATION_RADIUS)
	return separation.limit_length(combat_speed * 0.65)


func _update_orbit(delta: float) -> void:
	_orbit_phase += orbit_speed * delta
	var previous := global_position
	var desired := owner_player.global_position + Vector2.RIGHT.rotated(_orbit_phase) * orbit_radius
	var blend := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, blend)
	_movement_velocity = (global_position - previous) / maxf(delta, 0.0001)


func _update_fire(delta: float) -> void:
	_fire_timer = maxf(0.0, _fire_timer - delta)
	if _fire_timer > 0.0:
		return
	var target := _get_attack_target()
	if target == null:
		return
	_fire_timer = fire_interval
	_fire_at(target)
	_ability_flash = 1.0


func _update_mining(delta: float) -> void:
	_mine_timer -= delta
	if _mine_timer > 0.0 or mining_radius <= 0.0:
		return
	_mine_timer = MINING_TICK
	var candidates: Array[Node] = []
	var r2 := mining_radius * mining_radius
	for pickup in get_tree().get_nodes_in_group(&"mineral_pickups"):
		if not is_instance_valid(pickup) or not pickup is Node2D:
			continue
		if global_position.distance_squared_to((pickup as Node2D).global_position) <= r2:
			candidates.append(pickup)
	if candidates.is_empty():
		return
	# 每次处理约三分之一候选，三倍频率轮转后覆盖量与原实现一致。
	var budget := maxi(1, int(ceil(float(candidates.size()) * EFFECT_MULTIPLIER)))
	var triggered := 0
	for offset in range(budget):
		var pickup := candidates[(_mine_cursor + offset) % candidates.size()]
		if pickup.has_method("trigger_attract"):
			pickup.trigger_attract()
			triggered += 1
	_mine_cursor = (_mine_cursor + budget) % candidates.size()
	if triggered > 0:
		_ability_flash = 1.0
		_dispatch_owner_mechanic_event("on_mineral_collected", {"position": global_position, "amount": triggered, "proc_coefficient": 1.0})


## 护盾僚机三倍频率检查，但每次最多拦截一发：吞吐仍为原来的 3 / 0.12 秒。
func _update_shield(delta: float) -> void:
	_shield_timer -= delta
	if _shield_timer > 0.0:
		return
	_shield_timer = SHIELD_TICK
	var r2 := shield_radius * shield_radius
	var destroyed := 0
	for bullet in get_tree().get_nodes_in_group(&"enemy_bullets"):
		if destroyed >= SHIELD_MAX_PER_TICK:
			break
		if not is_instance_valid(bullet) or bullet.is_queued_for_deletion() or not bullet is Node2D:
			continue
		if global_position.distance_squared_to((bullet as Node2D).global_position) <= r2:
			if bullet.has_method("destroy"):
				bullet.destroy()
			else:
				bullet.queue_free()
			destroyed += 1
	if destroyed > 0:
		_ability_flash = 1.0
		queue_redraw()


## 自爆僚机：快速充能→冲向最近敌人→到位爆炸→短冷却重生。
func _update_kamikaze(delta: float) -> void:
	match _kami_state:
		KamikazeState.DASHING:
			if not is_instance_valid(_kami_target) or _kami_target.is_queued_for_deletion():
				_kami_state = KamikazeState.COOLDOWN
				_kami_timer = KAMI_COOLDOWN
				return
			_kami_timer -= delta
			var to_target := _get_node_world_position(_kami_target) - global_position
			_movement_velocity = to_target.normalized() * KAMI_DASH_SPEED if to_target.length_squared() > 1.0 else Vector2.ZERO
			global_position += _movement_velocity * delta
			if to_target.length() <= blast_radius * 0.5 or _kami_timer <= 0.0:
				_explode()
				_kami_state = KamikazeState.COOLDOWN
				_kami_timer = KAMI_COOLDOWN
		KamikazeState.COOLDOWN:
			_update_flight(delta)
			_kami_timer -= delta
			if _kami_timer <= 0.0:
				_kami_state = KamikazeState.CHARGING
				_kami_timer = KAMI_CHARGE_TIME
		_:
			_update_flight(delta)
			_kami_timer -= delta
			if _kami_timer <= 0.0:
				var target := _get_attack_target()
				if target is Node2D:
					_kami_target = target as Node2D
					_kami_state = KamikazeState.DASHING
					_kami_timer = KAMI_MAX_DASH_TIME
					_ability_flash = 1.0
				else:
					_kami_timer = 0.6 / FREQUENCY_MULTIPLIER


func _explode() -> void:
	var r2 := blast_radius * blast_radius
	for group_name in [&"enemies", &"boss", &"defense_turrets"]:
		for enemy in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(enemy) or not enemy is Node2D:
				continue
			if global_position.distance_squared_to((enemy as Node2D).global_position) <= r2:
				var amount := _next_blast_damage()
				if enemy.has_method("take_damage"):
					enemy.take_damage(amount, self)
				elif enemy.has_method("apply_damage"):
					enemy.apply_damage(amount)
	var parent := get_tree().current_scene
	if parent != null and parent.is_inside_tree():
		var burst = BulletBurstScript.new()
		burst.setup(Color(0.4, 0.85, 1.0, 1.0), 22)
		parent.add_child(burst)
		burst.global_position = global_position
	_ability_flash = 1.0


func _update_heal(delta: float) -> void:
	_heal_timer -= delta
	if _heal_timer > 0.0:
		return
	_heal_timer = heal_interval
	if GameManager.player_hp > 0 and GameManager.player_hp < GameManager.PLAYER_MAX_HP:
		var amount := _next_heal_amount()
		if amount > 0:
			GameManager.player_hp = mini(GameManager.PLAYER_MAX_HP, GameManager.player_hp + amount)
		_ability_flash = 1.0


func _find_target(max_range: float = attack_range) -> Node:
	var best: Node = null
	var best_dist_sq := max_range * max_range
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


func _get_attack_target() -> Node:
	if is_instance_valid(_combat_target) and not _combat_target.is_queued_for_deletion():
		var distance_sq := global_position.distance_squared_to(_get_node_world_position(_combat_target))
		if distance_sq <= attack_range * attack_range:
			return _combat_target
	return _find_target()


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
	bullet.atk = _next_bullet_damage()
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
	if owner_player != null and bullet.has_method("configure_mechanic_context") and owner_player.get("mechanic_runtime") != null:
		bullet.configure_mechanic_context(owner_player.get("mechanic_runtime"), 0, [], 1.0)
	get_tree().current_scene.add_child(bullet)
	_dispatch_owner_mechanic_event("on_drone_action", {"position": global_position, "direction": forward, "target": target, "damage": bullet.atk, "proc_coefficient": 1.0})


func _next_bullet_damage() -> int:
	_bullet_effect_carry += float(bullet_damage) * EFFECT_MULTIPLIER
	var amount := int(floor(_bullet_effect_carry + 0.0001))
	_bullet_effect_carry -= float(amount)
	return amount


func _next_heal_amount() -> int:
	_heal_effect_carry += float(heal_amount) * EFFECT_MULTIPLIER
	var amount := int(floor(_heal_effect_carry + 0.0001))
	_heal_effect_carry -= float(amount)
	return amount


func _next_blast_damage() -> int:
	_blast_effect_carry += float(blast_damage) * EFFECT_MULTIPLIER
	var amount := int(floor(_blast_effect_carry + 0.0001))
	_blast_effect_carry -= float(amount)
	return amount


func trigger_mechanic_action(event: Dictionary) -> void:
	_ability_flash = 1.0
	if behavior == &"shooter" and is_instance_valid(_combat_target):
		_fire_at(_combat_target)


func _dispatch_owner_mechanic_event(trigger: String, payload: Dictionary) -> void:
	if is_instance_valid(owner_player) and owner_player.has_method("dispatch_combat_event"):
		owner_player.call("dispatch_combat_event", trigger, payload)


func _apply_behavior_visuals() -> void:
	var accent_color := Color(0.45, 0.9, 1.0, 1.0)
	match behavior:
		&"guardian":
			accent_color = Color(0.36, 0.68, 1.0, 1.0)
		&"kamikaze":
			accent_color = Color(1.0, 0.38, 0.2, 1.0)
		&"medic":
			accent_color = Color(0.38, 1.0, 0.68, 1.0)
		&"miner":
			accent_color = Color(1.0, 0.82, 0.28, 1.0)
	body.color = Color(0.92, 0.9, 0.82, 1.0)
	shadow.color = Color(0.62, 0.61, 0.56, 1.0)
	fold.color = Color(0.16, 0.17, 0.16, 0.96)
	core.color = accent_color
	glow_outer.color = Color(accent_color, 0.1)
	glow_inner.color = Color(accent_color, 0.2)
	glow_core.color = Color(accent_color, 0.28)
	rear_node_left.color = Color(0.88, 0.86, 0.78, 1.0)
	rear_node_right.color = Color(0.88, 0.86, 0.78, 1.0)
	queue_redraw()


func _update_visual_animation(delta: float) -> void:
	_visual_time += delta
	_ability_flash = move_toward(_ability_flash, 0.0, delta * 4.8)
	var facing_target := _get_facing_target()
	if is_instance_valid(facing_target):
		var to_target := _get_node_world_position(facing_target) - global_position
		if to_target.length_squared() > 1.0:
			visual.global_rotation = to_target.angle() + PI * 0.5
	else:
		visual.global_rotation = owner_player.global_rotation
	var facing_right := Vector2.RIGHT.rotated(visual.global_rotation)
	var lateral_speed := _movement_velocity.dot(facing_right)
	var bank := clampf(lateral_speed / maxf(combat_speed, 1.0), -1.0, 1.0)
	var pulse := sin(_visual_time * (8.0 if is_instance_valid(_combat_target) else 4.0) + float(orbit_index))
	var glow_pulse := 0.5 + pulse * 0.5
	visual.position.y = pulse * (1.5 if is_instance_valid(_combat_target) else 0.8)
	visual.scale = Vector2(1.0 - absf(bank) * 0.16, 1.0 + _ability_flash * 0.1)
	glow_outer.scale = Vector2.ONE * (1.4 + glow_pulse * 0.08 + _ability_flash * 0.16)
	glow_inner.scale = Vector2.ONE * (1.18 + glow_pulse * 0.055 + _ability_flash * 0.1)
	glow_core.scale = Vector2.ONE * (2.2 + glow_pulse * 0.35 + _ability_flash * 0.6)
	glow_outer.modulate.a = 0.62 + glow_pulse * 0.2 + _ability_flash * 0.18
	glow_inner.modulate.a = 0.72 + glow_pulse * 0.18 + _ability_flash * 0.1
	glow_core.modulate.a = 0.78 + glow_pulse * 0.16 + _ability_flash * 0.06
	core.scale = Vector2.ONE * (1.0 + pulse * 0.045 + _ability_flash * 0.28)
	core.modulate.a = 0.72 + _ability_flash * 0.28
	var rear_pulse := Vector2.ONE * (1.0 + absf(pulse) * 0.035)
	rear_node_left.scale = rear_pulse
	rear_node_right.scale = rear_pulse
	if behavior == &"guardian" and (_ability_flash > 0.0 or int(_visual_time * 8.0) % 2 == 0):
		queue_redraw()


func _get_facing_target() -> Node:
	if behavior == &"kamikaze" and _kami_state == KamikazeState.DASHING and is_instance_valid(_kami_target) and not _kami_target.is_queued_for_deletion():
		return _kami_target
	if is_instance_valid(_combat_target) and not _combat_target.is_queued_for_deletion():
		return _combat_target
	return null


func _draw() -> void:
	if behavior != &"guardian":
		return
	var ring_alpha := 0.08 + _ability_flash * 0.28
	var ring_radius := minf(shield_radius, 118.0) * (1.0 + (1.0 - _ability_flash) * 0.025)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 64, Color(0.35, 0.72, 1.0, ring_alpha), 2.0, true)


func _clamp_to_owner_bounds() -> void:
	global_position = _clamp_point_to_owner_bounds(global_position, 22.0)


func _clamp_point_to_owner_bounds(point: Vector2, margin: float) -> Vector2:
	if owner_player == null or owner_player.get("movement_bounds") == null:
		return point
	var bounds: Rect2 = owner_player.get("movement_bounds")
	if bounds.size == Vector2.ZERO:
		return point
	return Vector2(
		clampf(point.x, bounds.position.x + margin, bounds.end.x - margin),
		clampf(point.y, bounds.position.y + margin, bounds.end.y - margin)
	)


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
