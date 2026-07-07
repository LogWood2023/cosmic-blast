extends Node2D
## 支援僚机：环绕玩家，按 behavior 表现不同行为
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

const SHIELD_TICK: float = 0.12
const SHIELD_MAX_PER_TICK: int = 3
const KAMI_CHARGE_TIME: float = 4.5
const KAMI_COOLDOWN: float = 2.5
const KAMI_DASH_SPEED: float = 940.0
const KAMI_MAX_DASH_TIME: float = 1.4

var behavior: String = "shooter"
var mining_radius: float = 0.0
var shield_radius: float = 230.0
var blast_radius: float = 190.0
var blast_damage: int = 42
var heal_amount: int = 4
var heal_interval: float = 4.5

var owner_player: Node2D
var orbit_index: int = 0
var orbit_count: int = 1

var _fire_timer: float = 0.0
var _orbit_phase: float = 0.0
var _mine_timer: float = 0.0
var _shield_timer: float = 0.0
var _heal_timer: float = 0.0
var _kami_state: int = 0  # 0=充能环绕 1=冲刺 2=冷却
var _kami_timer: float = 0.0
var _kami_target: Node2D


func setup(owner: Node2D, index: int, count: int, spec: Dictionary = {}) -> void:
	owner_player = owner
	orbit_index = maxi(0, index)
	orbit_count = maxi(1, count)
	behavior = String(spec.get("behavior", "shooter"))
	bullet_damage = maxi(1, bullet_damage + int(spec.get("atk_bonus", 0)) / 2)
	bullet_damage = maxi(1, int(round(float(bullet_damage) * float(spec.get("drone_damage_mult", 1.0)))))
	fire_interval = maxf(0.08, fire_interval * float(spec.get("drone_fire_interval_mult", 1.0)))
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
	add_to_group(&"player_support_drones")
	_orbit_phase = TAU * float(orbit_index) / maxf(float(orbit_count), 1.0)
	if owner_player == null:
		owner_player = get_tree().get_first_node_in_group(&"player") as Node2D


func _process(delta: float) -> void:
	if not is_instance_valid(owner_player):
		queue_free()
		return
	match behavior:
		"guardian":
			_update_orbit(delta)
			_update_shield(delta)
		"kamikaze":
			_update_kamikaze(delta)
		"medic":
			_update_orbit(delta)
			_update_heal(delta)
		"miner":
			_update_orbit(delta)
			_update_fire(delta)
			_update_mining(delta)
		_:
			_update_orbit(delta)
			_update_fire(delta)


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


## 护盾僚机：摧毁靠近的敌方子弹（每 tick 限量，防止无脑清屏）
func _update_shield(delta: float) -> void:
	_shield_timer -= delta
	if _shield_timer > 0.0:
		return
	_shield_timer = SHIELD_TICK
	var r2 := shield_radius * shield_radius
	var destroyed := 0
	for b in get_tree().get_nodes_in_group(&"enemy_bullets"):
		if destroyed >= SHIELD_MAX_PER_TICK:
			break
		if not is_instance_valid(b) or not b is Node2D:
			continue
		if global_position.distance_squared_to((b as Node2D).global_position) <= r2:
			if b.has_method("destroy"):
				b.destroy()
			else:
				b.queue_free()
			destroyed += 1


## 自爆僚机：充能→冲向最近敌人→到位爆炸→冷却重生
func _update_kamikaze(delta: float) -> void:
	match _kami_state:
		1:
			if not is_instance_valid(_kami_target) or _kami_target.is_queued_for_deletion():
				_kami_state = 2
				_kami_timer = KAMI_COOLDOWN
				return
			_kami_timer -= delta
			var to_target := _get_node_world_position(_kami_target) - global_position
			global_position += to_target.normalized() * KAMI_DASH_SPEED * delta
			if to_target.length() <= blast_radius * 0.5 or _kami_timer <= 0.0:
				_explode()
				_kami_state = 2
				_kami_timer = KAMI_COOLDOWN
		2:
			_update_orbit(delta)
			_kami_timer -= delta
			if _kami_timer <= 0.0:
				_kami_state = 0
				_kami_timer = KAMI_CHARGE_TIME
		_:
			_update_orbit(delta)
			_kami_timer -= delta
			if _kami_timer <= 0.0:
				var t := _find_target()
				if t != null and t is Node2D:
					_kami_target = t as Node2D
					_kami_state = 1
					_kami_timer = KAMI_MAX_DASH_TIME
				else:
					_kami_timer = 0.6  # 无目标，短暂后重试


func _explode() -> void:
	var r2 := blast_radius * blast_radius
	for group_name in [&"enemies", &"boss", &"defense_turrets"]:
		for e in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(e) or not e is Node2D:
				continue
			if global_position.distance_squared_to((e as Node2D).global_position) <= r2:
				if e.has_method("take_damage"):
					e.take_damage(blast_damage, self)
				elif e.has_method("apply_damage"):
					e.apply_damage(blast_damage)
	var parent := get_tree().current_scene
	if parent != null and parent.is_inside_tree():
		var burst = BulletBurstScript.new()
		burst.setup(Color(0.4, 0.85, 1.0, 1.0), 22)
		parent.add_child(burst)
		burst.global_position = global_position


## 治疗僚机：周期回复玩家少量 HP
func _update_heal(delta: float) -> void:
	_heal_timer -= delta
	if _heal_timer > 0.0:
		return
	_heal_timer = heal_interval
	if GameManager.player_hp > 0 and GameManager.player_hp < GameManager.PLAYER_MAX_HP:
		GameManager.player_hp = mini(GameManager.PLAYER_MAX_HP, GameManager.player_hp + heal_amount)


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
