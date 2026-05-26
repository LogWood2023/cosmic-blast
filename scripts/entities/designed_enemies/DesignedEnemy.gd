extends "res://scripts/entities/enemies/BaseEnemy.gd"

const BULLET_SCENE = preload("res://scenes/entities/projectiles/EnemyBullet.tscn")

enum Behavior {
	COLOSSUS_SHARD_ARM,
	COLOSSUS_SHIELD_BEE,
	COLOSSUS_GRAVITY_CLAW,
	COLOSSUS_GUARD,
	COLOSSUS_CORE_DEVOURER,
	PARADISE_PATROL,
	PARADISE_ARC_SCATTER,
	PARADISE_RAIL_CHAIN,
	PARADISE_CALIBRATOR,
	PARADISE_SANCTUM_SUPPRESSOR,
	WARPED_MICRO_CORE,
	WARPED_REFRACTION_SHOOTER,
	WARPED_ORBIT_DISRUPTOR,
	WARPED_COLLAPSE_BEACON,
	WARPED_DEFLECTION_MATRIX,
	HELLEYE_INVERTED_MOTH,
	HELLEYE_BLIND_MOTH,
	HELLEYE_MISALIGNED_GAZER,
	HELLEYE_INVERT_PRIEST,
	HELLEYE_HORIZON_DEFLECTOR,
	DIVINE_WING_RAIDER,
	DIVINE_BLINK_BEACON,
	DIVINE_BROKEN_WING_ASSASSIN,
	DIVINE_SERAPH_HUNTER,
	DIVINE_ORACLE_PHANTOM
}

@export var behavior: Behavior = Behavior.PARADISE_PATROL
@export var enemy_title: String = "测试敌机"
@export var body_size: Vector2 = Vector2(42, 42)
@export var body_color: Color = Color(0.8, 0.8, 0.8, 1.0)
@export var accent_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var detection_range: float = 800.0
@export var turn_speed: float = 6.0
@export var pursuit_timeout: float = 3.0

const ENEMY_TEXTURE_PATHS: Array[String] = [
	"res://assets/images/enemy/designed_25/props/01_巨构碎臂/01_巨构碎臂_00_1024x1024_e3af.png",
	"res://assets/images/enemy/designed_25/props/02_装甲盾蜂/02_装甲盾蜂_00_1024x1024_824b.png",
	"res://assets/images/enemy/designed_25/props/03_引力钩爪/03_引力钩爪_00_1024x1024_7c8f.png",
	"res://assets/images/enemy/designed_25/props/04_巨构护卫/04_巨构护卫_00_1024x1024_bcbf.png",
	"res://assets/images/enemy/designed_25/props/05_核心吞噬者/05_核心吞噬者_00_1024x1024_2962.png",
	"res://assets/images/enemy/designed_25/props/06_天堂巡逻机/06_天堂巡逻机_00_1024x1024_0e48.png",
	"res://assets/images/enemy/designed_25/props/07_弧光散射机/07_弧光散射机_00_1024x1024_af07.png",
	"res://assets/images/enemy/designed_25/props/08_圣轨连射机/08_圣轨连射机_00_1024x1024_c6fd.png",
	"res://assets/images/enemy/designed_25/props/09_天堂校准者/09_天堂校准者_00_1024x1024_1653.png",
	"res://assets/images/enemy/designed_25/props/10_圣域压制者/10_圣域压制者_00_1024x1024_ee61.png",
	"res://assets/images/enemy/designed_25/props/11_微型引力核/11_微型引力核_00_1024x1024_d9f9.png",
	"res://assets/images/enemy/designed_25/props/12_折光射手/12_折光射手_00_1024x1024_ab98.png",
	"res://assets/images/enemy/designed_25/props/13_轨道扰流器/13_轨道扰流器_00_1024x1024_1719.png",
	"res://assets/images/enemy/designed_25/props/14_坍缩信标/14_坍缩信标_00_1024x1024_a1f1.png",
	"res://assets/images/enemy/designed_25/props/15_偏转矩阵/15_偏转矩阵_00_1024x1024_f8ab.png",
	"res://assets/images/enemy/designed_25/props/16_倒影眼虫/16_倒影眼虫_00_1024x1024_4798.png",
	"res://assets/images/enemy/designed_25/props/17_盲点飞蛾/17_盲点飞蛾_00_1024x1024_55b0.png",
	"res://assets/images/enemy/designed_25/props/18_错位凝视者/18_错位凝视者_00_1024x1024_98fa.png",
	"res://assets/images/enemy/designed_25/props/19_颠倒司祭/19_颠倒司祭_00_1024x1024_de10.png",
	"res://assets/images/enemy/designed_25/props/20_视界偏转者/20_视界偏转者_00_1024x1024_4e5b.png",
	"res://assets/images/enemy/designed_25/props/21_圣羽掠袭者/21_圣羽掠袭者_00_1024x1024_a781.png",
	"res://assets/images/enemy/designed_25/props/22_闪现信标/22_闪现信标_00_1024x1024_f6c1.png",
	"res://assets/images/enemy/designed_25/props/23_折翼刺客/23_折翼刺客_00_1024x1024_523c.png",
	"res://assets/images/enemy/designed_25/props/24_炽天追猎者/24_炽天追猎者_00_1024x1024_5a52.png",
	"res://assets/images/enemy/designed_25/props/25_神谕幻影/25_神谕幻影_00_1024x1024_6a7c.png"
]

var _attack_timer: float = 0.0
var _special_timer: float = 0.0
var _burst_left: int = 0
var _burst_gap: float = 0.0
var _charge_target: Vector2 = Vector2.ZERO
var _is_charging: bool = false
var _charge_time: float = 0.0
var _suction_time: float = 0.0
var _shield_energy: int = 0
var _phase: int = 0
var _visual_parts: Array[ColorRect] = []
var _active_effects: Array[Dictionary] = []
var _last_safe_position: Vector2 = Vector2.ZERO
var _obstacle_bounce_velocity: Vector2 = Vector2.ZERO
var _obstacle_bounce_time: float = 0.0
var _obstacle_radius: float = 34.0
var _shard_retreat_start: Vector2 = Vector2.ZERO
var _shard_retreat_target: Vector2 = Vector2.ZERO
var _shard_retreat_elapsed: float = 0.0
var _shard_retreat_duration: float = 0.35
var _shard_charge_target: Vector2 = Vector2.ZERO
var _shard_is_retreating: bool = false
var _shard_is_fast_charging: bool = false
var _is_pursuing_player: bool = false
var _pursuit_target: Vector2 = Vector2.ZERO
var _pursuit_repath_timer: float = 0.0
var _clear_line_stability: float = 0.0
var _ai_alert: bool = false
var _pursuit_elapsed: float = 0.0


func _ready() -> void:
	_build_placeholder_visuals()
	_apply_behavior_defaults()
	super()
	_obstacle_radius = maxf(body_size.x, body_size.y) * 0.55
	_last_safe_position = global_position
	area_entered.connect(_on_area_entered)
	_enter_idle_ai(true)
	_update_placeholder_rotation()


func _exit_tree() -> void:
	if behavior == Behavior.WARPED_MICRO_CORE or behavior == Behavior.WARPED_COLLAPSE_BEACON:
		GameManager.suction_active = false
		GameManager.suction_center = Vector2.ZERO
	if behavior == Behavior.HELLEYE_INVERTED_MOTH or behavior == Behavior.HELLEYE_INVERT_PRIEST:
		GameManager.controls_inverted = false


func _build_placeholder_visuals() -> void:
	var sprite_proxy := get_node_or_null("Sprite2D") as Sprite2D
	if not sprite_proxy:
		sprite_proxy = Sprite2D.new()
		sprite_proxy.name = "Sprite2D"
		add_child(sprite_proxy)
		move_child(sprite_proxy, 0)
	sprite_proxy.visible = true
	var texture := _load_behavior_texture()
	if texture:
		sprite_proxy.texture = texture
		sprite_proxy.scale = Vector2(body_size.x / texture.get_width(), body_size.y / texture.get_height())
		sprite_proxy.modulate = Color.WHITE
	else:
		var img := Image.create(maxi(1, int(body_size.x)), maxi(1, int(body_size.y)), false, Image.FORMAT_RGBA8)
		img.fill(body_color)
		sprite_proxy.texture = ImageTexture.create_from_image(img)
		sprite_proxy.modulate = Color(1, 1, 1, 0.01)
	sprite_proxy.centered = true
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is RectangleShape2D:
		shape_node.shape.size = body_size
	if texture:
		return
	var sprite_rect := ColorRect.new()
	sprite_rect.name = "PlaceholderBody"
	sprite_rect.color = body_color
	sprite_rect.size = body_size
	sprite_rect.position = -body_size * 0.5
	add_child(sprite_rect)
	_visual_parts.append(sprite_rect)
	_add_part(Vector2(0, -body_size.y * 0.25), Vector2(body_size.x * 0.6, 6), accent_color)
	_add_part(Vector2(-body_size.x * 0.28, body_size.y * 0.18), Vector2(8, body_size.y * 0.35), accent_color.darkened(0.15))
	_add_part(Vector2(body_size.x * 0.28, body_size.y * 0.18), Vector2(8, body_size.y * 0.35), accent_color.darkened(0.15))


func _add_part(center: Vector2, size: Vector2, color: Color) -> void:
	var part := ColorRect.new()
	part.color = color
	part.size = size
	part.position = center - size * 0.5
	add_child(part)
	_visual_parts.append(part)


func _load_behavior_texture() -> Texture2D:
	var index := int(behavior)
	if index < 0 or index >= ENEMY_TEXTURE_PATHS.size():
		return null
	var texture = load(ENEMY_TEXTURE_PATHS[index])
	return texture as Texture2D


func _apply_behavior_defaults() -> void:
	match behavior:
		Behavior.COLOSSUS_SHARD_ARM:
			hp = 30; damage = 12; move_speed = 520; move_cooldown = 2.5
		Behavior.COLOSSUS_SHIELD_BEE:
			hp = 42; damage = 8; move_speed = 250; move_cooldown = 3.0
		Behavior.COLOSSUS_GRAVITY_CLAW:
			hp = 32; damage = 10; move_speed = 330; move_cooldown = 3.0
		Behavior.COLOSSUS_GUARD:
			hp = 115; damage = 14; move_speed = 360; move_cooldown = 3.5
		Behavior.COLOSSUS_CORE_DEVOURER:
			hp = 125; damage = 15; move_speed = 210; move_cooldown = 3.0
		Behavior.PARADISE_PATROL:
			hp = 24; damage = 8; move_speed = 260; move_cooldown = 2.5
		Behavior.PARADISE_ARC_SCATTER:
			hp = 28; damage = 7; move_speed = 220; move_cooldown = 3.0
		Behavior.PARADISE_RAIL_CHAIN:
			hp = 34; damage = 6; move_speed = 260; move_cooldown = 2.8
		Behavior.PARADISE_CALIBRATOR:
			hp = 105; damage = 10; move_speed = 260; move_cooldown = 3.2
		Behavior.PARADISE_SANCTUM_SUPPRESSOR:
			hp = 125; damage = 10; move_speed = 220; move_cooldown = 4.0
		Behavior.WARPED_MICRO_CORE:
			hp = 34; damage = 12; move_speed = 200; move_cooldown = 3.0
		Behavior.WARPED_REFRACTION_SHOOTER:
			hp = 28; damage = 10; move_speed = 250; move_cooldown = 2.8
		Behavior.WARPED_ORBIT_DISRUPTOR:
			hp = 38; damage = 8; move_speed = 240; move_cooldown = 3.0
		Behavior.WARPED_COLLAPSE_BEACON:
			hp = 120; damage = 14; move_speed = 190; move_cooldown = 4.5
		Behavior.WARPED_DEFLECTION_MATRIX:
			hp = 115; damage = 12; move_speed = 230; move_cooldown = 3.5
		Behavior.HELLEYE_INVERTED_MOTH:
			hp = 24; damage = 8; move_speed = 280; move_cooldown = 3.0
		Behavior.HELLEYE_BLIND_MOTH:
			hp = 24; damage = 10; move_speed = 360; move_cooldown = 2.0
		Behavior.HELLEYE_MISALIGNED_GAZER:
			hp = 30; damage = 9; move_speed = 230; move_cooldown = 2.8
		Behavior.HELLEYE_INVERT_PRIEST:
			hp = 120; damage = 14; move_speed = 210; move_cooldown = 4.0
		Behavior.HELLEYE_HORIZON_DEFLECTOR:
			hp = 135; damage = 16; move_speed = 220; move_cooldown = 4.0
		Behavior.DIVINE_WING_RAIDER:
			hp = 24; damage = 12; move_speed = 620; move_cooldown = 2.0
		Behavior.DIVINE_BLINK_BEACON:
			hp = 28; damage = 8; move_speed = 260; move_cooldown = 2.5
		Behavior.DIVINE_BROKEN_WING_ASSASSIN:
			hp = 32; damage = 14; move_speed = 520; move_cooldown = 2.5
		Behavior.DIVINE_SERAPH_HUNTER:
			hp = 115; damage = 16; move_speed = 480; move_cooldown = 3.0
		Behavior.DIVINE_ORACLE_PHANTOM:
			hp = 130; damage = 12; move_speed = 300; move_cooldown = 3.5
	lifetime = 120.0
	explosion_scale = clampf(body_size.length() / 90.0, 0.45, 0.9)


func _pick_path_target() -> void:
	if not player:
		path_target = _find_reachable_target(Vector2(randf_range(120, 1800), randf_range(120, 900)))
		return
	match behavior:
		Behavior.COLOSSUS_SHARD_ARM:
			_prepare_shard_charge_path()
		Behavior.DIVINE_WING_RAIDER:
			var dir := (player.global_position - global_position).normalized()
			path_target = _find_reachable_target(player.global_position + dir * randf_range(120, 260))
		Behavior.HELLEYE_BLIND_MOTH:
			path_target = _find_reachable_target(player.global_position + Vector2(randf_range(-260, 260), randf_range(-180, 180)))
		Behavior.DIVINE_BROKEN_WING_ASSASSIN, Behavior.DIVINE_SERAPH_HUNTER:
			var side := -1.0 if randf() < 0.5 else 1.0
			path_target = _find_reachable_target(player.global_position + Vector2(220 * side, randf_range(-120, 120)))
		_:
			path_target = _find_reachable_target(Vector2(randf_range(140, screen_size.x - 140), randf_range(120, screen_size.y * 0.72)))


func _update_cooldown(delta: float) -> void:
	if _update_detection_pursuit(delta):
		return
	if not _ai_alert:
		_update_idle_facing(delta)
		_update_effects(delta)
		return
	var before := global_position
	if _apply_obstacle_bounce(delta):
		_update_effects(delta)
		return
	super(delta)
	_resolve_obstacle_contact(before, false)
	if state != State.COOLDOWN:
		return
	_attack_timer -= delta
	_special_timer -= delta
	_update_effects(delta)
	match behavior:
		Behavior.COLOSSUS_SHIELD_BEE:
			_shield_pulse(delta)
		Behavior.COLOSSUS_GRAVITY_CLAW:
			_periodic_claw()
		Behavior.COLOSSUS_GUARD:
			_guard_charge(delta)
		Behavior.COLOSSUS_CORE_DEVOURER:
			_devourer_attack()
		Behavior.PARADISE_PATROL:
			_periodic_shot(1.2, 280, damage)
		Behavior.PARADISE_ARC_SCATTER:
			_periodic_spread(1.7, 7, PI / 2.8, 190, damage)
		Behavior.PARADISE_RAIL_CHAIN:
			_burst_shot(2.0, 3, 0.16, 320, damage)
		Behavior.PARADISE_CALIBRATOR:
			_calibrator_attack(delta)
		Behavior.PARADISE_SANCTUM_SUPPRESSOR:
			_sanctum_attack()
		Behavior.WARPED_MICRO_CORE:
			_micro_core_suction(delta)
		Behavior.WARPED_REFRACTION_SHOOTER:
			_refracted_shot()
		Behavior.WARPED_ORBIT_DISRUPTOR:
			_periodic_spread(1.6, 6, TAU, 170, damage)
		Behavior.WARPED_COLLAPSE_BEACON:
			_collapse_beacon(delta)
		Behavior.WARPED_DEFLECTION_MATRIX:
			_deflection_matrix()
		Behavior.HELLEYE_INVERTED_MOTH:
			_inverting_ray(false)
		Behavior.HELLEYE_BLIND_MOTH:
			_blind_cloud()
		Behavior.HELLEYE_MISALIGNED_GAZER:
			_misaligned_shot()
		Behavior.HELLEYE_INVERT_PRIEST:
			_invert_priest(delta)
		Behavior.HELLEYE_HORIZON_DEFLECTOR:
			_horizon_attack()
		Behavior.DIVINE_WING_RAIDER:
			_raider_drop()
		Behavior.DIVINE_BLINK_BEACON:
			_blink_beacon()
		Behavior.DIVINE_BROKEN_WING_ASSASSIN:
			_assassin_dash(delta)
		Behavior.DIVINE_SERAPH_HUNTER:
			_seraph_hunter(delta)
		Behavior.DIVINE_ORACLE_PHANTOM:
			_oracle_phantom()


func _update_movement(delta: float) -> void:
	if _update_detection_pursuit(delta):
		return
	if behavior == Behavior.COLOSSUS_SHARD_ARM:
		_update_shard_charge(delta)
		return
	var before := global_position
	if _apply_obstacle_bounce(delta):
		_update_effects(delta)
		return
	super(delta)
	_resolve_obstacle_contact(before, true)
	_update_effects(delta)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		handle_player_collision(area)


func _update_detection_pursuit(delta: float) -> bool:
	if state == State.WARNING or state == State.MOVING:
		return false
	if not player or detection_range <= 0.0:
		_enter_idle_ai()
		return false
	var distance := global_position.distance_to(player.global_position)
	var blocked_from_player := _path_blocked_by_obstacle(global_position, player.global_position)
	if _is_pursuing_player:
		_pursuit_elapsed += delta
	if distance > detection_range * 1.2 or (_is_pursuing_player and _pursuit_elapsed >= pursuit_timeout):
		_enter_idle_ai()
		return true
	if distance <= detection_range * 0.8 and not blocked_from_player:
		_clear_line_stability += delta
		if _is_pursuing_player and _clear_line_stability < 0.35:
			_update_pursuit_movement(delta)
			return true
		if not _ai_alert or _is_pursuing_player:
			_enter_alert_ai()
		return false
	_clear_line_stability = 0.0
	if _ai_alert and blocked_from_player:
		_enter_pursuit_ai()
		_update_pursuit_movement(delta)
		return true
	if distance <= detection_range * 1.5 or (_ai_alert and blocked_from_player):
		_enter_pursuit_ai()
		_update_pursuit_movement(delta)
		return true
	_enter_idle_ai()
	return true


func _enter_idle_ai(force: bool = false) -> void:
	if not force and (state == State.WARNING or state == State.MOVING):
		return
	_ai_alert = false
	_is_pursuing_player = false
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	_pursuit_target = Vector2.ZERO
	_pursuit_repath_timer = 0.0
	_clear_line_stability = 0.0
	_pursuit_elapsed = 0.0
	state = State.COOLDOWN
	cooldown_remaining = move_cooldown
	source_position = global_position
	queue_redraw()


func _enter_alert_ai() -> void:
	_ai_alert = true
	_is_pursuing_player = false
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	_pursuit_target = Vector2.ZERO
	_pursuit_repath_timer = 0.0
	_clear_line_stability = 0.0
	_pursuit_elapsed = 0.0
	source_position = global_position
	_pick_path_target()
	warning_timer = WARNING_DURATION
	state = State.WARNING
	queue_redraw()


func _enter_pursuit_ai() -> void:
	_ai_alert = true
	_is_pursuing_player = true
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	state = State.COOLDOWN
	cooldown_remaining = move_cooldown
	if _pursuit_elapsed <= 0.0:
		_pursuit_elapsed = 0.001
	queue_redraw()


func _update_pursuit_movement(delta: float) -> void:
	if _apply_obstacle_bounce(delta):
		_update_effects(delta)
		return
	_pursuit_repath_timer -= delta
	if _pursuit_target == Vector2.ZERO or _pursuit_repath_timer <= 0.0 or _path_blocked_by_obstacle(global_position, _pursuit_target):
		_pursuit_target = _find_pursuit_target()
		_pursuit_repath_timer = 0.45
	var desired_velocity := _pursuit_target - global_position
	if desired_velocity.length() > 8.0:
		var move_dir := desired_velocity.normalized()
		var next_pos := global_position + move_dir * move_speed * delta
		var pushed := _push_out_from_obstacles(next_pos)
		if pushed.distance_to(next_pos) > 2.0:
			_pursuit_target = _find_pursuit_target()
			_pursuit_repath_timer = 0.45
			desired_velocity = _pursuit_target - global_position
			if desired_velocity.length() > 8.0:
				move_dir = desired_velocity.normalized()
				next_pos = global_position + move_dir * move_speed * delta
			else:
				next_pos = global_position
		global_position = _push_out_from_obstacles(next_pos)
		_smooth_face_direction(move_dir, delta, turn_speed)
	else:
		source_position = global_position
		_pursuit_repath_timer = 0.0
	_update_effects(delta)


func _prepare_shard_charge_path() -> void:
	if not player:
		path_target = _find_reachable_target(global_position + Vector2.DOWN * 220.0)
		return
	var charge_dir := (player.global_position - global_position).normalized()
	if charge_dir.length() <= 0.01:
		charge_dir = Vector2.DOWN
	_shard_charge_target = _find_reachable_target(player.global_position + charge_dir * 260.0)
	var retreat_dir := -charge_dir
	_shard_retreat_start = global_position
	_shard_retreat_target = _push_out_from_obstacles(_clamped_point(global_position + retreat_dir * 50.0))
	_shard_retreat_elapsed = 0.0
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	path_target = _shard_charge_target


func _update_shard_charge(delta: float) -> void:
	var before := global_position
	if _apply_obstacle_bounce(delta):
		_update_effects(delta)
		return
	if not _shard_is_retreating and not _shard_is_fast_charging:
		_shard_is_retreating = true
		_shard_retreat_elapsed = 0.0
		_shard_retreat_start = global_position
		path_target = _shard_charge_target
	if _shard_is_retreating:
		_shard_retreat_elapsed += delta
		var retreat_t := clampf(_shard_retreat_elapsed / _shard_retreat_duration, 0.0, 1.0)
		global_position = _shard_retreat_start.lerp(_shard_retreat_target, smoothstep(0.0, 1.0, retreat_t))
		state = State.WARNING
		var hit_obstacle := _resolve_obstacle_contact(before, false)
		state = State.WARNING
		if hit_obstacle:
			_shard_is_retreating = false
			_update_effects(delta)
			return
		if player:
			var face_dir := _shard_charge_target - global_position
			_smooth_face_direction(face_dir, delta, 8.0)
		if retreat_t >= 1.0:
			_shard_is_retreating = false
			_shard_is_fast_charging = true
			source_position = global_position
			path_target = _shard_charge_target
			move_elapsed = 0.0
			move_duration = maxf(source_position.distance_to(path_target) / (move_speed * 5.0), 0.05)
		_update_effects(delta)
		return
	if _shard_is_fast_charging:
		state = State.MOVING
		move_elapsed += delta
		var t := clampf(move_elapsed / move_duration, 0.0, 1.0)
		var eased_t := 1.0 - pow(1.0 - t, 3.0)
		global_position = source_position.lerp(path_target, eased_t)
		if _resolve_obstacle_contact(before, true):
			_shard_is_fast_charging = false
			_update_effects(delta)
			return
		var dir := path_target - global_position
		_smooth_face_direction(dir, delta, 12.0)
		if t >= 1.0:
			global_position = path_target
			_shard_is_fast_charging = false
			state = State.COOLDOWN
			cooldown_remaining = move_cooldown * randf_range(0.6, 1.4)
			_on_arrive()
		_update_effects(delta)


func _begin_move() -> void:
	if behavior == Behavior.COLOSSUS_SHARD_ARM:
		move_elapsed = 0.0
		move_duration = _shard_retreat_duration + maxf(global_position.distance_to(_shard_charge_target) / (move_speed * 5.0), 0.05)
		return
	super()


func take_damage(amount: int) -> void:
	if behavior == Behavior.COLOSSUS_SHIELD_BEE or behavior == Behavior.COLOSSUS_GUARD or behavior == Behavior.COLOSSUS_CORE_DEVOURER:
		if state == State.COOLDOWN:
			amount = ceili(amount * 0.65)
			_shield_energy += 1
			if _shield_energy >= 5:
				_shield_energy = 0
				_spawn_ring(10, 10, 180)
	super(amount)


func _periodic_shot(interval: float, speed: float, dmg: int) -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = interval
	_shoot_at_player(speed, dmg)


func _periodic_spread(interval: float, count: int, arc: float, speed: float, dmg: int) -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = interval
	var base := Vector2.DOWN.angle()
	if player:
		base = (player.global_position - global_position).angle()
	for i in count:
		var t := 0.0 if count == 1 else float(i) / float(count - 1)
		var dir := Vector2.RIGHT.rotated(base - arc * 0.5 + arc * t)
		_spawn_bullet(dir, speed, dmg)


func _burst_shot(interval: float, count: int, gap: float, speed: float, dmg: int) -> void:
	if _burst_left <= 0 and _attack_timer <= 0.0:
		_burst_left = count
		_burst_gap = 0.0
		_attack_timer = interval
	if _burst_left > 0:
		_burst_gap -= get_process_delta_time()
		if _burst_gap <= 0.0:
			_burst_left -= 1
			_burst_gap = gap
			_shoot_at_player(speed, dmg)


func _shield_pulse(delta: float) -> void:
	_special_timer -= delta
	if _special_timer <= 0.0:
		_special_timer = 3.0
		_spawn_ring(8, 10, 150)


func _periodic_claw() -> void:
	if _attack_timer > 0.0 or not player:
		return
	_attack_timer = 2.4
	var dir := (player.global_position - global_position).normalized()
	_spawn_bullet(dir, 420, 10, 1.4)
	if global_position.distance_to(player.global_position) < 180:
		player.take_knockback_damage(8, 450, 0.18, -dir)


func _guard_charge(delta: float) -> void:
	if _is_charging:
		var before := global_position
		_charge_time -= delta
		var dir := (_charge_target - global_position).normalized()
		position += dir * 560 * delta
		if _resolve_obstacle_contact(before, true):
			_is_charging = false
			_attack_timer = 2.2
			return
		if _charge_time <= 0.0 or global_position.distance_to(_charge_target) < 16:
			_is_charging = false
			_attack_timer = 2.2
		return
	if _attack_timer <= 0.0 and player:
		_charge_target = _find_reachable_target(player.global_position)
		_charge_time = 0.45
		_is_charging = true


func _devourer_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = 2.2
	_shoot_at_player(360, 18, 1.4)


func _calibrator_attack(delta: float) -> void:
	_burst_shot(2.4, 3, 0.18, 340, 8)
	if _special_timer <= 0.0:
		_special_timer = 3.0
		_shoot_at_player(520, 12, 1.6)


func _sanctum_attack() -> void:
	if _attack_timer > 0.0 or not player:
		return
	_attack_timer = 3.2
	var center := player.global_position
	_spawn_bullet(Vector2.LEFT, 260, 8, 1.2, center + Vector2(150, 0))
	_spawn_bullet(Vector2.RIGHT, 260, 8, 1.2, center + Vector2(-150, 0))
	_spawn_bullet(Vector2.UP, 260, 8, 1.2, center + Vector2(0, 150))
	_spawn_bullet(Vector2.DOWN, 260, 8, 1.2, center + Vector2(0, -150))


func _micro_core_suction(delta: float) -> void:
	_suction_time -= delta
	if _suction_time <= 0.0:
		_suction_time = 3.0
	GameManager.suction_active = true
	GameManager.suction_center = global_position
	_periodic_spread(2.0, 4, TAU, 140, 7)


func _refracted_shot() -> void:
	if _attack_timer > 0.0 or not player:
		return
	_attack_timer = 1.8
	var dir := (player.global_position - global_position).normalized().rotated(randf_range(-0.45, 0.45))
	_spawn_bullet(dir, 230, 10)
	await get_tree().create_timer(0.45).timeout
	if is_instance_valid(self) and is_instance_valid(player):
		_shoot_at_player(320, 10)


func _collapse_beacon(delta: float) -> void:
	_suction_time -= delta
	if _suction_time > 0.0:
		GameManager.suction_active = true
		GameManager.suction_center = global_position
		return
	if _attack_timer <= 0.0:
		_attack_timer = 4.0
		_suction_time = 1.4
		_spawn_ring(12, 9, 210)


func _deflection_matrix() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = 2.0
	for i in 8:
		var dir := Vector2.RIGHT.rotated(i * TAU / 8.0 + _phase * 0.3)
		_spawn_bullet(dir, 220, 9)
	_phase += 1


func _inverting_ray(strong: bool) -> void:
	if _attack_timer > 0.0 or not player:
		return
	_attack_timer = 3.0 if strong else 2.2
	_shoot_at_player(420, 8 if not strong else 9, 1.2)
	if global_position.distance_to(player.global_position) < (260 if strong else 180):
		GameManager.controls_inverted = true
		await get_tree().create_timer(1.5 if strong else 1.0).timeout
		GameManager.controls_inverted = false


func _blind_cloud() -> void:
	if _attack_timer > 0.0 or not player:
		return
	_attack_timer = 2.8
	_create_cloud(player.global_position, 90, 1.5)
	if global_position.distance_to(player.global_position) < 100:
		player.take_damage_from_boss(3)


func _misaligned_shot() -> void:
	if _attack_timer > 0.0 or not player:
		return
	_attack_timer = 1.4
	var dir := (player.global_position - global_position).normalized().rotated(randf_range(-0.28, 0.28))
	_spawn_bullet(dir, 270, 9)


func _invert_priest(delta: float) -> void:
	_inverting_ray(true)
	_periodic_spread(2.8, 5, PI / 2.0, 170, 8)


func _horizon_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = 2.6
	var angle := randf_range(-0.8, 0.8)
	for i in 5:
		_spawn_bullet(Vector2.DOWN.rotated(angle + (i - 2) * 0.15), 240, 10)


func _raider_drop() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = 0.7
	_spawn_bullet(Vector2.DOWN.rotated(randf_range(-0.25, 0.25)), 260, 7)


func _blink_beacon() -> void:
	if _attack_timer > 0.0 or not player:
		return
	_attack_timer = 2.0
	global_position = _safe_near_player(180)
	_shoot_at_player(460, 10)


func _assassin_dash(delta: float) -> void:
	_guard_charge(delta)


func _seraph_hunter(delta: float) -> void:
	if _is_charging:
		_guard_charge(delta)
		return
	if _attack_timer <= 0.0 and player:
		global_position = _safe_near_player(230)
		_shoot_at_player(390, 10)
		_phase += 1
		if _phase % 3 == 0:
			_charge_target = _find_reachable_target(player.global_position)
			_charge_time = 0.5
			_is_charging = true
		_attack_timer = 1.0


func _oracle_phantom() -> void:
	if _attack_timer > 0.0 or not player:
		return
	_attack_timer = 2.8
	for i in 3:
		var pos := global_position + Vector2.RIGHT.rotated(i * TAU / 3.0) * 90
		_create_afterimage(pos)
		_spawn_bullet((player.global_position - pos).normalized(), 230, 8, 1.0, pos)
	global_position = _safe_near_player(220)
	_shoot_at_player(260, 14)


func _shoot_at_player(speed: float, dmg: int, scale_mult: float = 1.0) -> void:
	if not player:
		return
	var dir := (player.global_position - global_position).normalized()
	_spawn_bullet(dir, speed, dmg, scale_mult)


func _spawn_bullet(dir: Vector2, speed: float, dmg: int, scale_mult: float = 1.0, spawn_pos: Vector2 = global_position) -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = spawn_pos + dir.normalized() * 28
	bullet.direction = dir.normalized()
	bullet.speed = speed
	bullet.damage = dmg
	bullet.scale = Vector2(scale_mult, scale_mult)
	bullet.z_index = -80
	get_tree().current_scene.add_child(bullet)


func _spawn_ring(count: int, dmg: int, speed: float) -> void:
	for i in count:
		var dir := Vector2.RIGHT.rotated(i * TAU / float(count))
		_spawn_bullet(dir, speed, dmg)


func _clamped_point(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 60, screen_size.x - 60), clampf(p.y, 60, screen_size.y - 60))


func _find_pursuit_target() -> Vector2:
	if not player:
		return global_position
	var candidates: Array[Vector2] = []
	var to_enemy := global_position - player.global_position
	var base_angle := to_enemy.angle() if to_enemy.length() > 1.0 else randf_range(0.0, TAU)
	var inner_radius := maxf(120.0, minf(detection_range * 0.75, detection_range - 80.0))
	for i in range(24):
		var angle := base_angle + float(i) * TAU / 24.0
		candidates.append(_clamped_point(player.global_position + Vector2.RIGHT.rotated(angle) * inner_radius))
	for i in range(16):
		var angle := randf_range(0.0, TAU)
		var dist := randf_range(120.0, maxf(140.0, detection_range - 60.0))
		candidates.append(_clamped_point(player.global_position + Vector2.RIGHT.rotated(angle) * dist))
	candidates.append(_clamped_point(player.global_position + (to_enemy.normalized() if to_enemy.length() > 1.0 else Vector2.RIGHT) * inner_radius))
	var best := _find_reachable_target(player.global_position)
	var best_score := INF
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) > 2.0:
			continue
		if candidate.distance_to(player.global_position) > detection_range * 0.85:
			continue
		if _path_blocked_by_obstacle(candidate, player.global_position):
			continue
		var path_penalty := 100000.0 if _path_blocked_by_obstacle(global_position, candidate) else 0.0
		var score := global_position.distance_to(candidate) + path_penalty
		if score < best_score:
			best_score = score
			best = candidate
	return best


func _find_reachable_target(preferred: Vector2) -> Vector2:
	var candidates: Array[Vector2] = []
	candidates.append(_clamped_point(preferred))
	if player:
		var to_player := player.global_position - global_position
		var base_angle := to_player.angle() if to_player.length() > 1.0 else randf_range(0.0, TAU)
		for i in range(12):
			var angle := base_angle + (float(i) / 12.0) * TAU
			var dist := randf_range(120.0, 420.0)
			candidates.append(_clamped_point(player.global_position + Vector2.RIGHT.rotated(angle) * dist))
	for i in range(8):
		candidates.append(_clamped_point(Vector2(randf_range(80.0, screen_size.x - 80.0), randf_range(80.0, screen_size.y - 80.0))))
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) < 2.0 and not _path_blocked_by_obstacle(global_position, candidate):
			return candidate
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) < 2.0:
			return candidate
	return _push_out_from_obstacles(candidates[0])


func _path_blocked_by_obstacle(from_pos: Vector2, to_pos: Vector2) -> bool:
	var samples := maxi(3, int(from_pos.distance_to(to_pos) / 80.0))
	for i in range(1, samples + 1):
		var p := from_pos.lerp(to_pos, float(i) / float(samples))
		if _push_out_from_obstacles(p).distance_to(p) > 2.0:
			return true
	return false


func _push_out_from_obstacles(world_pos: Vector2) -> Vector2:
	var pushed := world_pos
	for obstacle in _get_blocking_obstacles():
		if not is_instance_valid(obstacle) or not obstacle.visible:
			continue
		if obstacle.has_method("get_push_out_position"):
			pushed = obstacle.get_push_out_position(pushed, _obstacle_radius)
	return pushed


func _get_blocking_obstacles() -> Array[Node]:
	var result: Array[Node] = []
	for group_name in [&"space_rocks", &"isolation_bands", &"space_clutter", &"explore_rewards"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node != self:
				result.append(node)
	return result


func _apply_obstacle_bounce(delta: float) -> bool:
	if _obstacle_bounce_time <= 0.0:
		return false
	_obstacle_bounce_time -= delta
	global_position += _obstacle_bounce_velocity * delta
	_obstacle_bounce_velocity = _obstacle_bounce_velocity.move_toward(Vector2.ZERO, _obstacle_bounce_velocity.length() * 5.0 * delta)
	var pushed := _push_out_from_obstacles(global_position)
	if pushed.distance_to(global_position) > 0.5:
		global_position = pushed
	if _obstacle_bounce_time <= 0.0:
		_obstacle_bounce_velocity = Vector2.ZERO
		source_position = global_position
		_pick_path_target()
		warning_timer = WARNING_DURATION
		state = State.WARNING
	return true


func _resolve_obstacle_contact(before: Vector2, should_bounce: bool) -> bool:
	var pushed := _push_out_from_obstacles(global_position)
	if pushed.distance_to(global_position) <= 0.5:
		_last_safe_position = global_position
		return false
	var impact_dir := (before - global_position).normalized()
	if impact_dir == Vector2.ZERO:
		impact_dir = (pushed - global_position).normalized()
	if impact_dir == Vector2.ZERO:
		impact_dir = Vector2.DOWN
	global_position = pushed
	_is_charging = false
	if should_bounce:
		_obstacle_bounce_velocity = impact_dir * maxf(move_speed * 0.85, 180.0)
		_obstacle_bounce_time = 0.28
	else:
		_obstacle_bounce_velocity = Vector2.ZERO
		_obstacle_bounce_time = 0.0
	source_position = global_position
	_pick_path_target()
	warning_timer = WARNING_DURATION
	state = State.WARNING
	return true


func _smooth_face_direction(direction: Vector2, delta: float, speed: float = -1.0) -> void:
	if direction.length() <= 0.01:
		return
	var actual_speed := turn_speed if speed <= 0.0 else speed
	rotation = lerp_angle(rotation, direction.angle() + PI / 2.0, clampf(actual_speed * delta, 0.0, 1.0))


func _update_idle_facing(delta: float) -> void:
	if not player:
		return
	var direction := player.global_position - global_position
	_smooth_face_direction(direction, delta, turn_speed * 0.55)


func _safe_near_player(radius: float) -> Vector2:
	if not player:
		return global_position
	for i in range(24):
		var angle := randf_range(0.0, TAU)
		var distance := randf_range(radius * 0.75, radius * 1.25)
		var candidate := _clamped_point(player.global_position + Vector2.RIGHT.rotated(angle) * distance)
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) < 2.0 and not _path_blocked_by_obstacle(candidate, player.global_position):
			return candidate
	return _find_reachable_target(player.global_position)


func _create_cloud(pos: Vector2, radius: float, duration: float) -> void:
	var cloud := ColorRect.new()
	cloud.color = Color(0, 0, 0, 0.35)
	cloud.size = Vector2(radius * 2, radius * 2)
	cloud.position = pos - cloud.size * 0.5
	cloud.z_index = 20
	get_tree().current_scene.add_child(cloud)
	var tw := cloud.create_tween()
	tw.tween_property(cloud, "modulate:a", 0.0, duration)
	tw.finished.connect(cloud.queue_free)


func _create_afterimage(pos: Vector2) -> void:
	var img := ColorRect.new()
	img.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.35)
	img.size = body_size
	img.position = pos - body_size * 0.5
	img.z_index = -5
	get_tree().current_scene.add_child(img)
	var tw := img.create_tween()
	tw.tween_property(img, "modulate:a", 0.0, 0.8)
	tw.finished.connect(img.queue_free)


func _update_effects(_delta: float) -> void:
	_update_placeholder_rotation()


func _update_placeholder_rotation() -> void:
	for part in _visual_parts:
		if part:
			part.rotation = -rotation
