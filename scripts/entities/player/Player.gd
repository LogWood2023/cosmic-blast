extends Area2D
## 玩家 —— HP 制，键盘移动 + 鼠标瞄准射击

@export var speed: float = 300.0
@export var rotation_speed: float = 8.0
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.25
@export var atk: int = 10
@export var movement_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
@export var blocked_by_space_rocks: bool = false

const SUPPORT_DRONE_SCENE := preload("res://scenes/entities/support/SupportDrone.tscn")

var screen_size: Vector2
var fire_cooldown: float = 0.0
var current_velocity: Vector2 = Vector2.ZERO
var collision_radius: float = 27.0
var _run_bullet_count: int = 1
var _run_spread_degrees: float = 0.0
var _run_bullet_speed_mult: float = 1.0
var _run_bullet_split_count: int = 0
var _run_bullet_split_spread_degrees: float = 0.0
var _run_bullet_split_damage_mult: float = 0.0
var _run_bullet_chain: int = 0
var _run_bullet_pierce: int = 0
var _run_bullet_dot_damage_mult: float = 0.0
var _run_bullet_charge: float = 0.0
var _run_bullet_ring_count: int = 0
var _charge_time: float = 0.0
var _run_bullet_blackhole: float = 0.0
var _run_bullet_slow: float = 0.0
var _run_bullet_phase: int = 0
var _run_bullet_mark_bonus: float = 0.0
var _run_damage_taken_mult: float = 1.0
var _run_homing_strength: float = 0.0
var _run_homing_range: float = 0.0
var _run_gravity_pull_strength: float = 0.0
var _run_gravity_pull_radius: float = 0.0
var _run_dash_distance_mult: float = 1.0
var _run_dash_speed_mult: float = 1.0
var _run_dash_damage_mult: float = 1.0
var _run_dash_aftershock_radius: float = 0.0
var _run_dash_aftershock_damage_mult: float = 0.0
var _run_dash_chain: int = 0
var _run_dash_trail_damage_mult: float = 0.0
var _run_dash_rebound_bonus: float = 0.0
var _run_dash_mining: float = 0.0
var _run_dash_shield_duration: float = 0.0
var _dash_chain_left: int = 0
var _dash_rebound_stacks: int = 0
var _dash_trail_timer: float = 0.0
var _run_drone_slots: int = 0
var _drone_loadout: Array = []
var _speed_slow_mult: float = 1.0
var _speed_slow_timer: float = 0.0
var _external_damage_accumulator: float = 0.0
var _blocking_obstacles_cache: Array[Node] = []
var _blocking_obstacles_cache_time: float = -9999.0
var _dash_active: bool = false
var _dash_velocity: Vector2 = Vector2.ZERO
var _dash_remaining_distance: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_afterimage_timer: float = 0.0
var _dash_hit_targets: Array[Node] = []
var _dash_distance_traveled: float = 0.0
var _pre_dash_collision_layer: int = 0
var _pre_dash_collision_mask: int = 0
var _pre_dash_monitoring: bool = true
var _pre_dash_monitorable: bool = true
var _last_input_dir: Vector2 = Vector2.UP

const OBSTACLE_CACHE_INTERVAL: float = 0.45
const OBSTACLE_QUERY_EXTRA_MARGIN: float = 180.0
const DASH_DISTANCE: float = 420.0
const DASH_SPEED: float = 2400.0
const DASH_COOLDOWN: float = 0.28
const DASH_STEP_DISTANCE: float = 44.0
const DASH_START_CLEARANCE_DISTANCE: float = 64.0
const DASH_OBSTACLE_EXTRA_MARGIN: float = 8.0
const DASH_REFLECT_DAMAGE_MULT: int = 3
const DASH_AFTERIMAGE_INTERVAL: float = 0.035
const DASH_AFTERIMAGE_LIFETIME: float = 0.22
const DASH_ENEMY_HIT_RADIUS: float = 52.0
const DASH_BOSS_HIT_RADIUS: float = 120.0
const DASH_CHAIN_RANGE: float = 720.0   # 智能导向：转向下一敌人的搜索范围
const DASH_TRAIL_RADIUS: float = 96.0   # 能量尾迹：沿途伤害半径
const CHARGE_MAX_TIME: float = 1.2      # 按住蓄力：满蓄所需时长

# 无敌帧
var invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 1.0

# 击飞状态
var is_knocked_back: bool = false
var knockback_speed: float = 0.0
var knockback_dir: Vector2 = Vector2.DOWN
var knockback_elapsed: float = 0.0
var knockback_duration: float = 0.0
var gravity_claw_grappled: bool = false
var _gravity_claw_enemy: Node
var _gravity_claw_enemies: Array[Node] = []
var _grapple_escape_progress: float = 0.0
var _grapple_last_input: int = 0
var _grapple_icon: Sprite2D
var _grapple_icon_anim_time: float = 0.0
var _grapple_icon_frame: int = 0
var _grapple_shake_timer: float = 0.0
var _grapple_camera_tap_shake_timer: float = 0.0
var _grapple_inertia_velocity: Vector2 = Vector2.ZERO
var _grapple_ui_layer: CanvasLayer
var _grapple_bar_bg: ColorRect
var _grapple_bar_fill: ColorRect
var _grapple_camera: Camera2D
var _grapple_camera_original_position: Vector2 = Vector2.ZERO
var _grapple_camera_original_zoom: Vector2 = Vector2.ONE
var _grapple_camera_focus_blend: float = 0.0
var _grapple_camera_follow_position: Vector2 = Vector2.ZERO
var _grapple_camera_has_original: bool = false
var _grapple_camera_returning: bool = false
var _grapple_camera_return_elapsed: float = 0.0
var _grapple_camera_return_start_position: Vector2 = Vector2.ZERO
var _grapple_camera_return_start_zoom: Vector2 = Vector2.ONE
var _grapple_glitch_layer: CanvasLayer
var _grapple_glitch_rect: ColorRect
var _grapple_glitch_material: ShaderMaterial
var _grapple_damage_accumulator: float = 0.0
var _warped_lightning_effect_timer: float = 0.0
var _warped_lightning_camera: Camera2D
var _warped_lightning_camera_original_position: Vector2 = Vector2.ZERO
var _warped_lightning_camera_original_zoom: Vector2 = Vector2.ONE
var _warped_lightning_camera_focus_blend: float = 0.0
var _warped_lightning_camera_follow_position: Vector2 = Vector2.ZERO
var _warped_lightning_camera_has_original: bool = false
var _warped_lightning_camera_returning: bool = false
var _warped_lightning_camera_return_elapsed: float = 0.0
var _warped_lightning_camera_return_start_position: Vector2 = Vector2.ZERO
var _warped_lightning_camera_return_start_zoom: Vector2 = Vector2.ONE
var _warped_lightning_glitch_layer: CanvasLayer
var _warped_lightning_glitch_rect: ColorRect
var _warped_lightning_glitch_material: ShaderMaterial
var _hell_eye_blind_source_dps: Dictionary = {}
var _hell_eye_blind_source_timers: Dictionary = {}
var _hell_eye_blind_damage_accumulator: float = 0.0
var _hell_eye_misalignment_source_timers: Dictionary = {}
var _hell_eye_misalignment_progress: float = 0.0
var _hell_eye_misalignment_disturbed: bool = false
var _hell_eye_inverted: bool = false
var _hell_eye_effect_layer: CanvasLayer
var _hell_eye_effect_rect: ColorRect
var _hell_eye_effect_material: ShaderMaterial
var _hell_eye_ui_layer: CanvasLayer
var _hell_eye_progress_ring: Node2D
var _hell_eye_camera: Camera2D
var _hell_eye_camera_original_position: Vector2 = Vector2.ZERO
var _hell_eye_camera_original_zoom: Vector2 = Vector2.ONE
var _hell_eye_camera_focus_blend: float = 0.0
var _hell_eye_camera_follow_position: Vector2 = Vector2.ZERO
var _hell_eye_camera_has_original: bool = false
var _hell_eye_camera_returning: bool = false
var _hell_eye_camera_return_elapsed: float = 0.0
var _hell_eye_camera_return_start_position: Vector2 = Vector2.ZERO
var _hell_eye_camera_return_start_zoom: Vector2 = Vector2.ONE

const GRAVITY_CLAW_ESCAPE_PROGRESS_MAX: float = 100.0
const GRAVITY_CLAW_ESCAPE_PROGRESS_PER_ALTERNATION: float = 10.0
const GRAVITY_CLAW_ESCAPE_PROGRESS_DECAY_PER_SECOND: float = 2.0
const GRAPPLE_BAR_SIZE: Vector2 = Vector2(10, 56)
const GRAPPLE_ICON_TEXTURE = preload("res://assets/images/ui/gravity_claw_joystick_cutout.png")
const GRAPPLE_ICON_FRAMES: int = 5
const GRAPPLE_ICON_FPS: float = 30.0
const GRAPPLE_ICON_DISPLAY_WIDTH: float = 40.6
const GRAPPLE_SHAKE_AMPLITUDE: float = 24.0
const GRAPPLE_SHAKE_DURATION: float = 0.18
const GRAPPLE_CAMERA_DURATION: float = 0.45
const GRAPPLE_CAMERA_ZOOM_MULT: float = 2.0
const GRAPPLE_CAMERA_SHAKE_AMPLITUDE: float = 18.0
const GRAPPLE_CAMERA_TAP_SHAKE_AMPLITUDE: float = 34.0
const GRAPPLE_CAMERA_FOLLOW_LAG_SPEED: float = 7.0
const GRAPPLE_GLITCH_STRENGTH: float = 0.5
const GRAPPLE_UI_LAYER: int = 95
const GRAPPLE_INERTIA_FALLBACK_SPEED: float = 260.0
const GRAPPLE_GLITCH_SHADER = preload("res://assets/shaders/gravity_claw_glitch.gdshader")
const WARPED_LIGHTNING_EFFECT_REFRESH: float = 0.24
const WARPED_LIGHTNING_CAMERA_DURATION: float = 0.28
const WARPED_LIGHTNING_CAMERA_ZOOM_MULT: float = 1.55
const WARPED_LIGHTNING_CAMERA_SHAKE_AMPLITUDE: float = 8.0
const WARPED_LIGHTNING_CAMERA_FOLLOW_LAG_SPEED: float = 9.0
const WARPED_LIGHTNING_GLITCH_STRENGTH: float = 0.34
const WARPED_LIGHTNING_GLITCH_TINT: Vector3 = Vector3(0.50, 0.10, 1.0)
const WARPED_LIGHTNING_GLITCH_TEAR: Vector3 = Vector3(0.45, 0.04, 1.0)
const HELL_EYE_SCREEN_EFFECT_SHADER = preload("res://assets/shaders/hell_eye_screen_effect.gdshader")
const HELL_EYE_PROGRESS_RING_SCRIPT = preload("res://scripts/ui/HellEyeProgressRing.gd")
const HELL_EYE_LINK_REFRESH: float = 0.18
const HELL_EYE_CAMERA_DURATION: float = 0.45
const HELL_EYE_CAMERA_ZOOM_MULT: float = 1.55
const HELL_EYE_CAMERA_FOLLOW_LAG_SPEED: float = 8.0
const HELL_EYE_PROGRESS_FILL_PER_SECOND: float = 0.2
const HELL_EYE_PROGRESS_DECAY_PER_SECOND: float = 0.1
const HELL_EYE_INVERTED_DECAY_MULT: float = 2.0
const HELL_EYE_SHOOT_OFFSET_RADIUS: float = 500.0
const HELL_EYE_SCREEN_LAYER: int = 89
const HELL_EYE_UI_LAYER: int = 96
const GRAPPLE_ICON_FRAME_RECTS: Array[Rect2] = [
	Rect2(3, 335, 214, 357),
	Rect2(205, 335, 213, 357),
	Rect2(406, 335, 212, 357),
	Rect2(606, 335, 213, 357),
	Rect2(807, 335, 214, 357),
]

@onready var sprite: Sprite2D = $Sprite2D

const SHOOT_SOUND = preload("res://assets/audio/shoot.wav")
const HURT_SOUND = preload("res://assets/audio/player_hurt.wav")


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	if movement_bounds.size == Vector2.ZERO:
		movement_bounds = Rect2(Vector2.ZERO, screen_size)
	_apply_run_equipment()
	var shape_node: CollisionShape2D = $CollisionShape2D
	if shape_node and shape_node.shape is CapsuleShape2D:
		collision_radius = shape_node.shape.height * 0.5
	add_to_group(&"player")
	collision_layer = 1
	collision_mask = 6     # 检测 Boss 组件 (2) + ExploreReward (4)


func _process(delta: float) -> void:
	_update_external_slow(delta)
	_update_hell_eye_effects(delta)
	_update_gravity_claw_camera(delta)
	_update_warped_lightning_visual(delta)
	_update_gravity_claw_shake(delta)
	_update_dash_cooldown(delta)

	# ── 无敌计时 ──
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			invincible = false
			sprite.modulate.a = 1.0
		else:
			sprite.modulate.a = 0.3 if fmod(invincible_timer, 0.2) < 0.1 else 1.0

	# ── 击飞 ──
	if is_knocked_back:
		knockback_elapsed += delta
		var t = clampf(knockback_elapsed / maxf(knockback_duration, 0.001), 0.0, 1.0)
		var spd = lerp(knockback_speed, 0.0, t)
		current_velocity = knockback_dir * spd
		_move_with_space_rock_block(knockback_dir * spd * delta)
		_clamp_to_movement_bounds()
		if t >= 1.0:
			is_knocked_back = false
			current_velocity = Vector2.ZERO
		return    # 击飞期间无法行动

	if gravity_claw_grappled:
		_update_gravity_claw_grapple(delta)
		return

	if GameManager.command_console_open:
		current_velocity = Vector2.ZERO
		return

	if _dash_active:
		_update_dash(delta)
		return

	# ── 移动 ──
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if GameManager.controls_inverted:
		input_dir = -input_dir
	if input_dir.length() > 0.01:
		_last_input_dir = input_dir.normalized()
	if Input.is_action_just_pressed("dash") and not _is_mouse_over_map():
		_start_dash(input_dir)
		if _dash_active:
			return
	var total_move = input_dir
	if GameManager.suction_active:
		var pull = GameManager.suction_center - global_position
		if pull.length() > 1.0:
			total_move += pull.normalized() * 0.8
	var effective_speed := speed * _speed_slow_mult
	current_velocity = total_move * effective_speed
	_move_with_space_rock_block(total_move * effective_speed * delta)
	_clamp_to_movement_bounds()

	# ── 朝向 ──
	var is_shooting: bool = (Input.is_action_pressed("shoot") or SettingsManager.auto_fire) and not _is_mouse_over_map()
	var target_angle: float
	if is_shooting:
		var mp = get_global_mouse_position()
		var diff = mp - global_position
		target_angle = diff.angle() + PI / 2.0 if diff.length() > 10.0 else rotation
	elif input_dir != Vector2.ZERO:
		target_angle = input_dir.angle() + PI / 2.0
	else:
		target_angle = rotation
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

	# ── 射击 ──
	fire_cooldown -= delta
	if _run_bullet_charge > 0.0:
		# 蓄力模式：按住蓄力，松开爆发一大轮
		if is_shooting and not _dash_active:
			_charge_time = minf(_charge_time + delta, CHARGE_MAX_TIME)
		elif _charge_time > 0.0:
			_release_charge_burst()
			_charge_time = 0.0
	elif is_shooting and not _dash_active and fire_cooldown <= 0.0:
		_shoot()
		fire_cooldown = _get_effective_fire_rate()


func _shoot() -> void:
	if not bullet_scene:
		return
	var forward := _get_current_shoot_direction()
	var count = maxi(1, _run_bullet_count)
	var spread_rad = deg_to_rad(_run_spread_degrees)
	for i in range(count):
		var offset := 0.0
		if count > 1:
			offset = lerpf(-spread_rad * 0.5, spread_rad * 0.5, float(i) / float(count - 1))
		_spawn_player_bullet(forward.rotated(offset))
	# 环射：向环绕方向额外补弹，形成全向火力网
	for r in range(_run_bullet_ring_count):
		var ring_angle := TAU * float(r + 1) / float(_run_bullet_ring_count + 1)
		_spawn_player_bullet(forward.rotated(ring_angle))
	_play_sfx(SHOOT_SOUND)


func _release_charge_burst() -> void:
	if not bullet_scene:
		return
	var ratio := clampf(_charge_time / CHARGE_MAX_TIME, 0.0, 1.0)
	var burst := maxi(1, int(round(ratio * _run_bullet_charge)))
	var forward := _get_current_shoot_direction()
	var spread := deg_to_rad(28.0 + _run_spread_degrees)
	for i in range(burst):
		var off := 0.0
		if burst > 1:
			off = lerpf(-spread * 0.5, spread * 0.5, float(i) / float(burst - 1))
		_spawn_player_bullet(forward.rotated(off))
	_play_sfx(SHOOT_SOUND)
	fire_cooldown = _get_effective_fire_rate()


func _spawn_player_bullet(direction: Vector2) -> void:
	var bullet = bullet_scene.instantiate()
	var forward := direction.normalized()
	bullet.direction = forward
	bullet.atk = maxi(1, int(round(float(atk) * GameManager.get_outgoing_damage_multiplier())))
	if bullet.get("speed") != null:
		bullet.speed = float(bullet.speed) * _run_bullet_speed_mult
	if bullet.get("split_count") != null:
		bullet.split_count = _run_bullet_split_count
	if bullet.get("split_spread_degrees") != null:
		bullet.split_spread_degrees = _run_bullet_split_spread_degrees
	if bullet.get("split_damage_mult") != null:
		bullet.split_damage_mult = _run_bullet_split_damage_mult
	if bullet.get("pierce_left") != null:
		bullet.pierce_left = _run_bullet_pierce
	if bullet.get("chain_left") != null:
		bullet.chain_left = _run_bullet_chain
	if bullet.get("dot_damage_mult") != null:
		bullet.dot_damage_mult = _run_bullet_dot_damage_mult
	if bullet.get("blackhole_strength") != null:
		bullet.blackhole_strength = _run_bullet_blackhole
	if bullet.get("slow_ratio") != null:
		bullet.slow_ratio = _run_bullet_slow
	if bullet.get("phase_left") != null:
		bullet.phase_left = _run_bullet_phase
	if bullet.get("mark_bonus") != null:
		bullet.mark_bonus = _run_bullet_mark_bonus
	if bullet.get("homing_strength") != null:
		bullet.homing_strength = _run_homing_strength
	if bullet.get("homing_range") != null:
		bullet.homing_range = _run_homing_range
	if bullet.get("gravity_pull_strength") != null:
		bullet.gravity_pull_strength = _run_gravity_pull_strength
	if bullet.get("gravity_pull_radius") != null:
		bullet.gravity_pull_radius = _run_gravity_pull_radius
	if movement_bounds.size != screen_size:
		bullet.world_bounds = movement_bounds
	bullet.position = global_position + 50 * forward
	bullet.rotation = forward.angle()
	bullet.z_index = -80            # 子弹层
	get_tree().current_scene.add_child(bullet)


func _apply_run_equipment() -> void:
	if not RunManager.is_formal_run_active():
		return
	var stats := RunManager.get_player_stats()
	atk += int(stats.get("atk_bonus", 0))
	fire_rate = maxf(0.06, fire_rate * float(stats.get("fire_rate_mult", 1.0)))
	speed *= float(stats.get("speed_mult", 1.0))
	_run_bullet_count = maxi(1, int(stats.get("bullet_count", 1)))
	_run_spread_degrees = maxf(0.0, float(stats.get("spread_degrees", 0.0)))
	_run_bullet_speed_mult = maxf(0.1, float(stats.get("bullet_speed_mult", 1.0)))
	_run_bullet_split_count = maxi(0, int(stats.get("bullet_split_count", 0)))
	_run_bullet_split_spread_degrees = maxf(0.0, float(stats.get("bullet_split_spread_degrees", 0.0)))
	_run_bullet_split_damage_mult = maxf(0.0, float(stats.get("bullet_split_damage_mult", 0.0)))
	_run_bullet_chain = maxi(0, int(stats.get("bullet_chain", 0)))
	_run_bullet_pierce = maxi(0, int(stats.get("bullet_pierce", 0)))
	_run_bullet_dot_damage_mult = maxf(0.0, float(stats.get("bullet_dot_damage_mult", 0.0)))
	_run_bullet_charge = maxf(0.0, float(stats.get("bullet_charge", 0.0)))
	_run_bullet_ring_count = maxi(0, int(stats.get("bullet_ring_count", 0)))
	_run_bullet_blackhole = maxf(0.0, float(stats.get("bullet_blackhole", 0.0)))
	_run_bullet_slow = maxf(0.0, float(stats.get("bullet_slow", 0.0)))
	_run_bullet_phase = maxi(0, int(stats.get("bullet_phase", 0)))
	_run_bullet_mark_bonus = maxf(0.0, float(stats.get("bullet_mark_bonus", 0.0)))
	_run_damage_taken_mult = clampf(float(stats.get("damage_taken_mult", 1.0)), 0.3, 1.0)
	GameManager.kill_lifesteal = maxf(0.0, float(stats.get("kill_lifesteal", 0.0)))
	GameManager.reveal_map = maxf(0.0, float(stats.get("reveal_map", 0.0)))
	_run_homing_strength = maxf(0.0, float(stats.get("homing_strength", 0.0)))
	_run_homing_range = maxf(0.0, float(stats.get("homing_range", 0.0)))
	_run_gravity_pull_strength = maxf(0.0, float(stats.get("gravity_pull_strength", 0.0)))
	_run_gravity_pull_radius = maxf(0.0, float(stats.get("gravity_pull_radius", 0.0)))
	_run_dash_distance_mult = maxf(0.1, float(stats.get("dash_distance_mult", 1.0)))
	_run_dash_speed_mult = maxf(0.1, float(stats.get("dash_speed_mult", 1.0)))
	_run_dash_damage_mult = maxf(0.0, float(stats.get("dash_damage_mult", 1.0)))
	_run_dash_aftershock_radius = maxf(0.0, float(stats.get("dash_aftershock_radius", 0.0)))
	_run_dash_aftershock_damage_mult = maxf(0.0, float(stats.get("dash_aftershock_damage_mult", 0.0)))
	_run_dash_chain = maxi(0, int(stats.get("dash_chain", 0)))
	_run_dash_trail_damage_mult = maxf(0.0, float(stats.get("dash_trail_damage_mult", 0.0)))
	_run_dash_rebound_bonus = maxf(0.0, float(stats.get("dash_rebound_bonus", 0.0)))
	_run_dash_mining = maxf(0.0, float(stats.get("dash_mining", 0.0)))
	_run_dash_shield_duration = maxf(0.0, float(stats.get("dash_shield_duration", 0.0)))
	_run_drone_slots = maxi(0, int(stats.get("drone_slots", 0)))
	_drone_loadout = RunManager.get_drone_loadout()
	_ensure_support_drones()


func _get_current_shoot_direction() -> Vector2:
	if _hell_eye_misalignment_disturbed:
		var random_offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, HELL_EYE_SHOOT_OFFSET_RADIUS)
		var target := get_global_mouse_position() + random_offset
		var diff := target - global_position
		if diff.length() > 1.0:
			return diff.normalized()
	var forward := Vector2(0, -1).rotated(rotation)
	return forward.normalized() if forward.length() > 0.01 else Vector2.UP


# ══════════════════════════════════════════════
#  受击（由敌方调用）
# ══════════════════════════════════════════════

var _death_triggered: bool = false


## HP 归零的统一出口；防止 DoT/钩爪等多来源伤害同帧重复结算和重复切场景
func _check_player_death() -> bool:
	if GameManager.player_hp > 0:
		return false
	GameManager.player_hp = 0
	if _death_triggered:
		return true
	_death_triggered = true
	if RunManager.is_formal_run_active():
		RunManager.finish_run(false)
	get_tree().change_scene_to_file.call_deferred("res://scenes/app/gameover.tscn")
	return true


## 被敌方子弹 / 撞击机 / 炸弹 等攻击时调用
func take_damage_from(area: Area2D) -> void:
	if invincible or _dash_active:
		return

	var dmg: int = area.get("damage") if area.get("damage") != null else 0
	if dmg <= 0:
		return
	dmg = _apply_player_damage_taken(dmg)

	_play_sfx(HURT_SOUND)
	GameManager.add_frenzy(dmg)
	GameManager.player_hp -= dmg

	if _check_player_death():
		return

	HitFlashFx.flash(sprite)
	CameraFeedback.player_hurt_feedback()
	invincible = true
	invincible_timer = INVINCIBLE_DURATION


## Boss 直接伤害（无 Area2D 来源）
func take_damage_from_boss(dmg: int) -> void:
	if invincible or _dash_active:
		return
	dmg = _apply_player_damage_taken(dmg)
	_play_sfx(HURT_SOUND)
	GameManager.add_frenzy(dmg)
	GameManager.player_hp -= dmg
	if _check_player_death():
		return
	HitFlashFx.flash(sprite)
	CameraFeedback.player_hurt_feedback()
	invincible = true
	invincible_timer = INVINCIBLE_DURATION


func apply_slow(mult: float, duration: float) -> void:
	_speed_slow_mult = minf(_speed_slow_mult, clampf(mult, 0.1, 1.0))
	_speed_slow_timer = maxf(_speed_slow_timer, duration)


func apply_direct_damage_over_time(damage_per_second: float, delta: float) -> void:
	if _dash_active:
		return
	if damage_per_second <= 0.0:
		return
	_external_damage_accumulator += damage_per_second * delta
	var whole_damage := int(floor(_external_damage_accumulator))
	if whole_damage <= 0:
		return
	_external_damage_accumulator -= whole_damage
	_apply_external_direct_damage(whole_damage)


func apply_warped_lightning_effect(duration: float = WARPED_LIGHTNING_EFFECT_REFRESH) -> void:
	if gravity_claw_grappled:
		return
	_warped_lightning_effect_timer = maxf(_warped_lightning_effect_timer, duration)
	if not _warped_lightning_camera_has_original:
		_begin_warped_lightning_camera_focus()
	_ensure_warped_lightning_glitch_overlay()


func apply_hell_eye_blind_link(source: Node, damage_per_second: float, _delta: float) -> void:
	if not is_instance_valid(source):
		return
	_hell_eye_blind_source_dps[source] = maxf(0.0, damage_per_second)
	# 与错位链接同款的刷新超时：敌人停止调用后链接自动过期，不再永久挂 DoT
	_hell_eye_blind_source_timers[source] = HELL_EYE_LINK_REFRESH


func release_hell_eye_blind_link(source: Node) -> void:
	_hell_eye_blind_source_dps.erase(source)
	_hell_eye_blind_source_timers.erase(source)


func refresh_hell_eye_misalignment_link(source: Node, _delta: float, upgrade_to_inverted: bool = false) -> void:
	if not is_instance_valid(source):
		return
	_hell_eye_misalignment_source_timers[source] = HELL_EYE_LINK_REFRESH
	if upgrade_to_inverted and _hell_eye_misalignment_disturbed:
		_hell_eye_inverted = true


func release_hell_eye_misalignment_link(source: Node) -> void:
	_hell_eye_misalignment_source_timers.erase(source)


func is_hell_eye_disturbed() -> bool:
	return _hell_eye_misalignment_disturbed


func _update_external_slow(delta: float) -> void:
	if _speed_slow_timer <= 0.0:
		_speed_slow_mult = 1.0
		return
	_speed_slow_timer = maxf(_speed_slow_timer - delta, 0.0)
	if _speed_slow_timer <= 0.0:
		_speed_slow_mult = 1.0


func _update_hell_eye_effects(delta: float) -> void:
	_prune_hell_eye_sources(delta)
	var has_blind := not _hell_eye_blind_source_dps.is_empty()
	var has_misalignment_line := not _hell_eye_misalignment_source_timers.is_empty()
	if has_blind:
		_apply_hell_eye_blind_damage(delta)
	if has_misalignment_line:
		_hell_eye_misalignment_progress = minf(1.0, _hell_eye_misalignment_progress + HELL_EYE_PROGRESS_FILL_PER_SECOND * delta)
		if _hell_eye_misalignment_progress >= 1.0:
			_hell_eye_misalignment_disturbed = true
	elif _hell_eye_misalignment_progress > 0.0:
		var decay := HELL_EYE_PROGRESS_DECAY_PER_SECOND * (HELL_EYE_INVERTED_DECAY_MULT if _hell_eye_inverted else 1.0)
		_hell_eye_misalignment_progress = maxf(0.0, _hell_eye_misalignment_progress - decay * delta)
		if _hell_eye_misalignment_progress <= 0.0:
			_hell_eye_misalignment_disturbed = false
			_hell_eye_inverted = false
	var show_progress := _hell_eye_misalignment_progress > 0.0
	var needs_camera_effect := has_blind or _hell_eye_misalignment_disturbed or _hell_eye_inverted
	var needs_overlay := has_blind or needs_camera_effect
	if gravity_claw_grappled:
		needs_camera_effect = false
		needs_overlay = false
	if needs_camera_effect:
		if _warped_lightning_effect_timer > 0.0:
			_cancel_warped_lightning_visual()
		_update_hell_eye_camera(delta)
	else:
		_update_hell_eye_camera_restore(delta)
	if needs_overlay:
		_update_hell_eye_screen_overlay(has_blind)
	else:
		_clear_hell_eye_screen_overlay()
	if show_progress:
		_update_hell_eye_progress_ui()
	else:
		_clear_hell_eye_progress_ui()


func _prune_hell_eye_sources(delta: float) -> void:
	var blind_expired: Array = []
	for source in _hell_eye_blind_source_dps.keys():
		if not is_instance_valid(source):
			blind_expired.append(source)
			continue
		var blind_remaining := float(_hell_eye_blind_source_timers.get(source, HELL_EYE_LINK_REFRESH)) - delta
		if blind_remaining <= 0.0:
			blind_expired.append(source)
		else:
			_hell_eye_blind_source_timers[source] = blind_remaining
	for source in blind_expired:
		_hell_eye_blind_source_dps.erase(source)
		_hell_eye_blind_source_timers.erase(source)
	var expired: Array[Node] = []
	for source in _hell_eye_misalignment_source_timers.keys():
		if not is_instance_valid(source):
			expired.append(source)
			continue
		var remaining := float(_hell_eye_misalignment_source_timers[source]) - delta
		if remaining <= 0.0:
			expired.append(source)
		else:
			_hell_eye_misalignment_source_timers[source] = remaining
	for source in expired:
		_hell_eye_misalignment_source_timers.erase(source)


func _apply_hell_eye_blind_damage(delta: float) -> void:
	var damage_per_second := 0.0
	for source in _hell_eye_blind_source_dps.keys():
		damage_per_second += maxf(0.0, float(_hell_eye_blind_source_dps[source]))
	if damage_per_second <= 0.0:
		return
	_hell_eye_blind_damage_accumulator += damage_per_second * delta
	var whole_damage := int(floor(_hell_eye_blind_damage_accumulator))
	if whole_damage <= 0:
		return
	_hell_eye_blind_damage_accumulator -= whole_damage
	_apply_external_direct_damage(whole_damage)


func _apply_external_direct_damage(dmg: int) -> void:
	if dmg <= 0 or _dash_active:
		return
	dmg = _apply_player_damage_taken(dmg)
	_play_sfx(HURT_SOUND)
	GameManager.add_frenzy(dmg)
	GameManager.player_hp -= dmg
	if _check_player_death():
		return


## Boss 碰撞击飞
func take_knockback_damage(dmg: int, spd: float, dur: float, dir: Vector2 = Vector2.DOWN) -> void:
	if _dash_active:
		return
	if gravity_claw_grappled:
		return
	if is_knocked_back:
		return
	dmg = _apply_player_damage_taken(dmg)
	_play_sfx(HURT_SOUND)
	GameManager.add_frenzy(dmg)
	GameManager.player_hp -= dmg
	if _check_player_death():
		return
	HitFlashFx.flash(sprite)
	CameraFeedback.player_hurt_feedback()
	is_knocked_back = true
	knockback_speed = spd
	knockback_duration = maxf(dur, 0.001)
	knockback_elapsed = 0.0
	knockback_dir = dir
	invincible = true
	invincible_timer = 0.7


# ══════════════════════════════════════════════
#  道具（保留）
# ══════════════════════════════════════════════

func begin_gravity_claw_grapple(enemy: Node) -> bool:
	if not is_instance_valid(enemy):
		return false
	var was_grappled := gravity_claw_grappled
	_add_gravity_claw_enemy(enemy)
	var impact_damage := _get_gravity_claw_impact_damage(enemy)
	if impact_damage > 0:
		_apply_gravity_claw_damage(impact_damage, true)
	if not was_grappled:
		gravity_claw_grappled = true
		_grapple_escape_progress = 0.0
		_grapple_last_input = 0
		_grapple_icon_anim_time = 0.0
		_grapple_icon_frame = 0
		_grapple_shake_timer = 0.0
		_grapple_camera_tap_shake_timer = 0.0
		_grapple_damage_accumulator = 0.0
		_grapple_inertia_velocity = _get_gravity_claw_inertia_velocity(enemy)
	else:
		var added_inertia := _get_gravity_claw_inertia_velocity(enemy)
		if _grapple_inertia_velocity == Vector2.ZERO:
			_grapple_inertia_velocity = added_inertia
	is_knocked_back = false
	knockback_elapsed = 0.0
	knockback_duration = 0.0
	current_velocity = Vector2.ZERO
	if not was_grappled:
		_cancel_warped_lightning_visual()
		_begin_grapple_camera_focus()
	_ensure_grapple_glitch_overlay()
	_ensure_grapple_ui()
	_update_grapple_ui()
	return true


func end_gravity_claw_grapple(enemy: Node = null) -> void:
	if enemy != null:
		_gravity_claw_enemies.erase(enemy)
		if not _gravity_claw_enemies.is_empty():
			_gravity_claw_enemy = _gravity_claw_enemies[0]
			_recalculate_grapple_inertia()
			_update_grapple_ui()
			return
	_gravity_claw_enemies.clear()
	_grapple_damage_accumulator = 0.0
	_grapple_inertia_velocity = Vector2.ZERO
	if not gravity_claw_grappled:
		return
	gravity_claw_grappled = false
	_gravity_claw_enemy = null
	_grapple_escape_progress = 0.0
	_grapple_last_input = 0
	_grapple_icon_anim_time = 0.0
	_grapple_icon_frame = 0
	_grapple_shake_timer = 0.0
	_grapple_camera_tap_shake_timer = 0.0
	current_velocity = Vector2.ZERO
	_begin_grapple_camera_restore()
	_clear_grapple_glitch_overlay()
	_clear_grapple_ui()


func _update_gravity_claw_grapple(delta: float) -> void:
	current_velocity = Vector2.ZERO
	_prune_gravity_claw_enemies()
	if _gravity_claw_enemies.is_empty():
		end_gravity_claw_grapple()
		return
	_update_grapple_icon_animation(delta)
	_apply_grapple_inertia(delta)
	_apply_grapple_damage_over_time(delta)
	_grapple_escape_progress = maxf(0.0, _grapple_escape_progress - GRAVITY_CLAW_ESCAPE_PROGRESS_DECAY_PER_SECOND * _get_grapple_stack_count() * delta)
	var input_side := 0
	if Input.is_action_just_pressed("move_left"):
		input_side = -1
	elif Input.is_action_just_pressed("move_right"):
		input_side = 1
	if input_side != 0 and input_side != _grapple_last_input:
		_grapple_last_input = input_side
		var required_progress := _get_grapple_required_progress()
		_grapple_escape_progress = minf(required_progress, _grapple_escape_progress + GRAVITY_CLAW_ESCAPE_PROGRESS_PER_ALTERNATION)
		_grapple_shake_timer = GRAPPLE_SHAKE_DURATION
		_grapple_camera_tap_shake_timer = GRAPPLE_SHAKE_DURATION
		sprite.position = Vector2(randf_range(-GRAPPLE_SHAKE_AMPLITUDE, GRAPPLE_SHAKE_AMPLITUDE), randf_range(-GRAPPLE_SHAKE_AMPLITUDE, GRAPPLE_SHAKE_AMPLITUDE))
		_update_grapple_ui()
		if _grapple_escape_progress >= required_progress:
			for grapple_enemy in _gravity_claw_enemies.duplicate():
				if is_instance_valid(grapple_enemy) and grapple_enemy.has_method("release_gravity_claw_grapple"):
					grapple_enemy.release_gravity_claw_grapple()
			end_gravity_claw_grapple()
			return
	_update_grapple_ui()


func _ensure_grapple_ui() -> void:
	if not is_instance_valid(_grapple_ui_layer):
		_grapple_ui_layer = CanvasLayer.new()
		_grapple_ui_layer.name = "GravityClawEscapeUILayer"
		_grapple_ui_layer.layer = GRAPPLE_UI_LAYER
		get_tree().current_scene.add_child(_grapple_ui_layer)
	if not is_instance_valid(_grapple_icon):
		_grapple_icon = Sprite2D.new()
		_grapple_icon.name = "GravityClawJoystickIcon"
		_grapple_icon.texture = GRAPPLE_ICON_TEXTURE
		_grapple_icon.centered = true
		_grapple_icon.region_enabled = true
		_grapple_icon.z_index = 200
		_set_grapple_icon_frame(0)
		var frame_size := _get_grapple_icon_frame_rect(0).size
		if frame_size.x > 0.0:
			var icon_scale := GRAPPLE_ICON_DISPLAY_WIDTH / frame_size.x
			_grapple_icon.scale = Vector2.ONE * icon_scale
		_grapple_ui_layer.add_child(_grapple_icon)
	if not is_instance_valid(_grapple_bar_bg):
		_grapple_bar_bg = ColorRect.new()
		_grapple_bar_bg.name = "GravityClawEscapeBarBg"
		_grapple_bar_bg.color = Color(0.05, 0.05, 0.05, 0.75)
		_grapple_bar_bg.size = GRAPPLE_BAR_SIZE
		_grapple_bar_bg.z_index = 200
		_grapple_ui_layer.add_child(_grapple_bar_bg)
	if not is_instance_valid(_grapple_bar_fill):
		_grapple_bar_fill = ColorRect.new()
		_grapple_bar_fill.name = "GravityClawEscapeBarFill"
		_grapple_bar_fill.color = Color(0.95, 0.18, 0.08, 0.95)
		_grapple_bar_fill.z_index = 201
		_grapple_ui_layer.add_child(_grapple_bar_fill)


func _update_grapple_ui() -> void:
	_ensure_grapple_ui()
	var player_screen_pos := _world_to_grapple_ui_position(global_position)
	var icon_pos := player_screen_pos + Vector2(0.0, -collision_radius - 62)
	_grapple_icon.position = icon_pos
	var bar_pos := player_screen_pos + Vector2(collision_radius + 20, -GRAPPLE_BAR_SIZE.y * 0.5)
	_grapple_bar_bg.position = bar_pos
	var progress := clampf(_grapple_escape_progress / _get_grapple_required_progress(), 0.0, 1.0)
	var fill_h := GRAPPLE_BAR_SIZE.y * progress
	_grapple_bar_fill.size = Vector2(GRAPPLE_BAR_SIZE.x, fill_h)
	_grapple_bar_fill.position = bar_pos + Vector2(0.0, GRAPPLE_BAR_SIZE.y - fill_h)


func _update_grapple_icon_animation(delta: float) -> void:
	_grapple_icon_anim_time += delta
	var frame := int(floor(_grapple_icon_anim_time * GRAPPLE_ICON_FPS)) % GRAPPLE_ICON_FRAMES
	if frame != _grapple_icon_frame:
		_set_grapple_icon_frame(frame)


func _set_grapple_icon_frame(frame: int) -> void:
	_grapple_icon_frame = wrapi(frame, 0, GRAPPLE_ICON_FRAMES)
	if not is_instance_valid(_grapple_icon):
		return
	_grapple_icon.region_rect = _get_grapple_icon_frame_rect(_grapple_icon_frame)


func _get_grapple_icon_frame_rect(frame: int) -> Rect2:
	return GRAPPLE_ICON_FRAME_RECTS[wrapi(frame, 0, GRAPPLE_ICON_FRAMES)]


func _world_to_grapple_ui_position(world_pos: Vector2) -> Vector2:
	var viewport := get_viewport()
	var camera := viewport.get_camera_2d()
	if not camera:
		return world_pos
	var viewport_size := viewport.get_visible_rect().size
	var camera_center := camera.global_position
	if gravity_claw_grappled and is_instance_valid(_grapple_camera) and camera == _grapple_camera:
		camera_center = _grapple_camera_follow_position
	return viewport_size * 0.5 + (world_pos - camera_center) * camera.zoom


func _begin_grapple_camera_focus() -> void:
	var camera := _get_grapple_camera()
	if not camera:
		return
	_grapple_camera = camera
	_grapple_camera_original_position = camera.global_position
	_grapple_camera_original_zoom = camera.zoom
	_grapple_camera_focus_blend = 0.0
	_grapple_camera_follow_position = camera.global_position
	_grapple_camera_has_original = true
	_grapple_camera_returning = false
	_grapple_camera_return_elapsed = 0.0
	camera.make_current()


func _begin_grapple_camera_restore() -> void:
	if not _grapple_camera_has_original or not is_instance_valid(_grapple_camera):
		_grapple_camera_has_original = false
		_grapple_camera_returning = false
		return
	_grapple_camera_returning = true
	_grapple_camera_return_elapsed = 0.0
	_grapple_camera_return_start_position = _grapple_camera.global_position
	_grapple_camera_return_start_zoom = _grapple_camera.zoom


func _begin_hell_eye_camera_focus() -> void:
	var camera := _get_grapple_camera()
	if not camera:
		return
	_hell_eye_camera = camera
	_hell_eye_camera_original_position = camera.global_position
	_hell_eye_camera_original_zoom = camera.zoom
	_hell_eye_camera_focus_blend = 0.0
	_hell_eye_camera_follow_position = camera.global_position
	_hell_eye_camera_has_original = true
	_hell_eye_camera_returning = false
	_hell_eye_camera_return_elapsed = 0.0
	camera.make_current()


func _begin_hell_eye_camera_restore() -> void:
	if not _hell_eye_camera_has_original or not is_instance_valid(_hell_eye_camera):
		_hell_eye_camera_has_original = false
		_hell_eye_camera_returning = false
		return
	if _hell_eye_camera_returning:
		return
	_hell_eye_camera_returning = true
	_hell_eye_camera_return_elapsed = 0.0
	_hell_eye_camera_return_start_position = _hell_eye_camera.global_position
	_hell_eye_camera_return_start_zoom = _hell_eye_camera.zoom


func _update_hell_eye_camera(delta: float) -> void:
	if not is_instance_valid(_hell_eye_camera):
		_begin_hell_eye_camera_focus()
	if not is_instance_valid(_hell_eye_camera):
		return
	_hell_eye_camera_focus_blend = minf(_hell_eye_camera_focus_blend + delta / HELL_EYE_CAMERA_DURATION, 1.0)
	var eased := smoothstep(0.0, 1.0, _hell_eye_camera_focus_blend)
	var target_zoom := _hell_eye_camera_original_zoom.lerp(_hell_eye_camera_original_zoom * HELL_EYE_CAMERA_ZOOM_MULT, eased)
	var desired_center := _hell_eye_camera_original_position.lerp(global_position, eased)
	_hell_eye_camera_follow_position = _hell_eye_camera_follow_position.lerp(desired_center, clampf(HELL_EYE_CAMERA_FOLLOW_LAG_SPEED * delta, 0.0, 1.0))
	_hell_eye_camera_follow_position = _clamp_camera_center_to_bounds(_hell_eye_camera_follow_position, target_zoom)
	_hell_eye_camera.global_position = _hell_eye_camera_follow_position
	_hell_eye_camera.zoom = target_zoom


func _update_hell_eye_camera_restore(delta: float) -> void:
	if not _hell_eye_camera_has_original:
		return
	_begin_hell_eye_camera_restore()
	if not _hell_eye_camera_returning:
		return
	if not is_instance_valid(_hell_eye_camera):
		_hell_eye_camera_returning = false
		_hell_eye_camera_has_original = false
		return
	_hell_eye_camera_return_elapsed += delta
	var t := clampf(_hell_eye_camera_return_elapsed / HELL_EYE_CAMERA_DURATION, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, t)
	var target_zoom := _hell_eye_camera_return_start_zoom.lerp(_hell_eye_camera_original_zoom, eased)
	var target_position := _hell_eye_camera_return_start_position.lerp(_hell_eye_camera_original_position, eased)
	_hell_eye_camera.global_position = _clamp_camera_center_to_bounds(target_position, target_zoom)
	_hell_eye_camera.zoom = target_zoom
	if t >= 1.0:
		_hell_eye_camera.global_position = _hell_eye_camera_original_position
		_hell_eye_camera.zoom = _hell_eye_camera_original_zoom
		_hell_eye_camera_returning = false
		_hell_eye_camera_has_original = false
		_hell_eye_camera = null


func _update_gravity_claw_camera(delta: float) -> void:
	if gravity_claw_grappled:
		_cancel_hell_eye_visuals()
		_cancel_warped_lightning_visual()
		if not is_instance_valid(_grapple_camera):
			_begin_grapple_camera_focus()
		if not is_instance_valid(_grapple_camera):
			return
		_grapple_camera_focus_blend = minf(_grapple_camera_focus_blend + delta / GRAPPLE_CAMERA_DURATION, 1.0)
		var eased := smoothstep(0.0, 1.0, _grapple_camera_focus_blend)
		var target_zoom := _grapple_camera_original_zoom.lerp(_grapple_camera_original_zoom * GRAPPLE_CAMERA_ZOOM_MULT, eased)
		var desired_center := _grapple_camera_original_position.lerp(global_position, eased)
		_grapple_camera_follow_position = _grapple_camera_follow_position.lerp(desired_center, clampf(GRAPPLE_CAMERA_FOLLOW_LAG_SPEED * delta, 0.0, 1.0))
		_grapple_camera_follow_position = _clamp_camera_center_to_bounds(_grapple_camera_follow_position, target_zoom)
		var shake := Vector2(randf_range(-GRAPPLE_CAMERA_SHAKE_AMPLITUDE, GRAPPLE_CAMERA_SHAKE_AMPLITUDE), randf_range(-GRAPPLE_CAMERA_SHAKE_AMPLITUDE, GRAPPLE_CAMERA_SHAKE_AMPLITUDE))
		if _grapple_camera_tap_shake_timer > 0.0:
			_grapple_camera_tap_shake_timer = maxf(0.0, _grapple_camera_tap_shake_timer - delta)
			var tap_t := _grapple_camera_tap_shake_timer / GRAPPLE_SHAKE_DURATION
			shake += Vector2(randf_range(-GRAPPLE_CAMERA_TAP_SHAKE_AMPLITUDE, GRAPPLE_CAMERA_TAP_SHAKE_AMPLITUDE), randf_range(-GRAPPLE_CAMERA_TAP_SHAKE_AMPLITUDE, GRAPPLE_CAMERA_TAP_SHAKE_AMPLITUDE)) * tap_t
		_grapple_camera.global_position = _clamp_camera_center_to_bounds(_grapple_camera_follow_position + shake, target_zoom)
		_grapple_camera.zoom = target_zoom
		return
	if _grapple_camera_returning:
		if not is_instance_valid(_grapple_camera):
			_grapple_camera_returning = false
			_grapple_camera_has_original = false
			return
		_grapple_camera_return_elapsed += delta
		var t := clampf(_grapple_camera_return_elapsed / GRAPPLE_CAMERA_DURATION, 0.0, 1.0)
		var eased := smoothstep(0.0, 1.0, t)
		var target_zoom := _grapple_camera_return_start_zoom.lerp(_grapple_camera_original_zoom, eased)
		var target_position := _grapple_camera_return_start_position.lerp(_grapple_camera_original_position, eased)
		_grapple_camera.global_position = _clamp_camera_center_to_bounds(target_position, target_zoom)
		_grapple_camera.zoom = target_zoom
		if t >= 1.0:
			_grapple_camera.global_position = _grapple_camera_original_position
			_grapple_camera.zoom = _grapple_camera_original_zoom
			_grapple_camera_returning = false
			_grapple_camera_has_original = false
			_grapple_camera = null


func _begin_warped_lightning_camera_focus() -> void:
	var camera := _get_grapple_camera()
	if not camera:
		return
	_warped_lightning_camera = camera
	_warped_lightning_camera_original_position = camera.global_position
	_warped_lightning_camera_original_zoom = camera.zoom
	_warped_lightning_camera_focus_blend = 0.0
	_warped_lightning_camera_follow_position = camera.global_position
	_warped_lightning_camera_has_original = true
	_warped_lightning_camera_returning = false
	_warped_lightning_camera_return_elapsed = 0.0
	camera.make_current()


func _begin_warped_lightning_camera_restore() -> void:
	if not _warped_lightning_camera_has_original or not is_instance_valid(_warped_lightning_camera):
		_warped_lightning_camera_has_original = false
		_warped_lightning_camera_returning = false
		return
	_warped_lightning_camera_returning = true
	_warped_lightning_camera_return_elapsed = 0.0
	_warped_lightning_camera_return_start_position = _warped_lightning_camera.global_position
	_warped_lightning_camera_return_start_zoom = _warped_lightning_camera.zoom


func _update_warped_lightning_visual(delta: float) -> void:
	if gravity_claw_grappled:
		_cancel_warped_lightning_visual()
		return
	if _warped_lightning_effect_timer > 0.0:
		_warped_lightning_effect_timer = maxf(_warped_lightning_effect_timer - delta, 0.0)
		if not is_instance_valid(_warped_lightning_camera):
			_begin_warped_lightning_camera_focus()
		if is_instance_valid(_warped_lightning_camera):
			_warped_lightning_camera_focus_blend = minf(_warped_lightning_camera_focus_blend + delta / WARPED_LIGHTNING_CAMERA_DURATION, 1.0)
			var eased := smoothstep(0.0, 1.0, _warped_lightning_camera_focus_blend)
			var target_zoom := _warped_lightning_camera_original_zoom.lerp(_warped_lightning_camera_original_zoom * WARPED_LIGHTNING_CAMERA_ZOOM_MULT, eased)
			var desired_center := _warped_lightning_camera_original_position.lerp(global_position, eased)
			_warped_lightning_camera_follow_position = _warped_lightning_camera_follow_position.lerp(desired_center, clampf(WARPED_LIGHTNING_CAMERA_FOLLOW_LAG_SPEED * delta, 0.0, 1.0))
			_warped_lightning_camera_follow_position = _clamp_camera_center_to_bounds(_warped_lightning_camera_follow_position, target_zoom)
			var shake_strength := WARPED_LIGHTNING_CAMERA_SHAKE_AMPLITUDE * (0.65 + 0.35 * eased)
			var shake := Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
			_warped_lightning_camera.global_position = _clamp_camera_center_to_bounds(_warped_lightning_camera_follow_position + shake, target_zoom)
			_warped_lightning_camera.zoom = target_zoom
		_ensure_warped_lightning_glitch_overlay()
		if _warped_lightning_effect_timer <= 0.0:
			_begin_warped_lightning_camera_restore()
			_clear_warped_lightning_glitch_overlay()
		return
	if _warped_lightning_camera_returning:
		if not is_instance_valid(_warped_lightning_camera):
			_warped_lightning_camera_returning = false
			_warped_lightning_camera_has_original = false
			return
		_warped_lightning_camera_return_elapsed += delta
		var t := clampf(_warped_lightning_camera_return_elapsed / WARPED_LIGHTNING_CAMERA_DURATION, 0.0, 1.0)
		var eased := smoothstep(0.0, 1.0, t)
		var target_zoom := _warped_lightning_camera_return_start_zoom.lerp(_warped_lightning_camera_original_zoom, eased)
		var target_position := _warped_lightning_camera_return_start_position.lerp(_warped_lightning_camera_original_position, eased)
		_warped_lightning_camera.global_position = _clamp_camera_center_to_bounds(target_position, target_zoom)
		_warped_lightning_camera.zoom = target_zoom
		if t >= 1.0:
			_warped_lightning_camera.global_position = _warped_lightning_camera_original_position
			_warped_lightning_camera.zoom = _warped_lightning_camera_original_zoom
			_warped_lightning_camera_returning = false
			_warped_lightning_camera_has_original = false
			_warped_lightning_camera = null


func _ensure_warped_lightning_glitch_overlay() -> void:
	if is_instance_valid(_warped_lightning_glitch_layer) and is_instance_valid(_warped_lightning_glitch_rect):
		return
	_warped_lightning_glitch_layer = CanvasLayer.new()
	_warped_lightning_glitch_layer.name = "WarpedLightningGlitchLayer"
	_warped_lightning_glitch_layer.layer = 88
	_warped_lightning_glitch_rect = ColorRect.new()
	_warped_lightning_glitch_rect.name = "WarpedLightningGlitchOverlay"
	_warped_lightning_glitch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warped_lightning_glitch_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_warped_lightning_glitch_rect.color = Color.TRANSPARENT
	_warped_lightning_glitch_material = ShaderMaterial.new()
	_warped_lightning_glitch_material.shader = GRAPPLE_GLITCH_SHADER
	_warped_lightning_glitch_material.set_shader_parameter("strength", WARPED_LIGHTNING_GLITCH_STRENGTH)
	_warped_lightning_glitch_material.set_shader_parameter("red_tint", 0.58)
	_warped_lightning_glitch_material.set_shader_parameter("channel_offset", 0.0045)
	_warped_lightning_glitch_material.set_shader_parameter("tear_strength", 0.010)
	_warped_lightning_glitch_material.set_shader_parameter("scanline_strength", 0.12)
	_warped_lightning_glitch_material.set_shader_parameter("tint_color", WARPED_LIGHTNING_GLITCH_TINT)
	_warped_lightning_glitch_material.set_shader_parameter("tear_boost_color", WARPED_LIGHTNING_GLITCH_TEAR)
	_warped_lightning_glitch_rect.material = _warped_lightning_glitch_material
	_warped_lightning_glitch_layer.add_child(_warped_lightning_glitch_rect)
	get_tree().current_scene.add_child(_warped_lightning_glitch_layer)


func _clear_warped_lightning_glitch_overlay() -> void:
	if is_instance_valid(_warped_lightning_glitch_layer):
		_warped_lightning_glitch_layer.queue_free()
	_warped_lightning_glitch_layer = null
	_warped_lightning_glitch_rect = null
	_warped_lightning_glitch_material = null


func _cancel_warped_lightning_visual() -> void:
	if _warped_lightning_camera_has_original and is_instance_valid(_warped_lightning_camera):
		_warped_lightning_camera.global_position = _warped_lightning_camera_original_position
		_warped_lightning_camera.zoom = _warped_lightning_camera_original_zoom
	_warped_lightning_effect_timer = 0.0
	_warped_lightning_camera_returning = false
	_warped_lightning_camera_has_original = false
	_warped_lightning_camera = null
	_clear_warped_lightning_glitch_overlay()


func _update_hell_eye_screen_overlay(has_blind: bool) -> void:
	_ensure_hell_eye_screen_overlay()
	if not is_instance_valid(_hell_eye_effect_material):
		return
	var vignette := 1.76 if has_blind else 0.44
	var vignette_spread := 2.0 if has_blind else 1.0
	if _hell_eye_misalignment_disturbed:
		vignette = maxf(vignette, 0.58)
	var glitch := 0.0
	var tint := 0.0
	if _hell_eye_misalignment_disturbed:
		glitch = 0.24
		tint = 0.12
	if _hell_eye_inverted:
		glitch = 0.32
		tint = 0.18
	_hell_eye_effect_material.set_shader_parameter("vignette_strength", vignette)
	_hell_eye_effect_material.set_shader_parameter("vignette_spread", vignette_spread)
	_hell_eye_effect_material.set_shader_parameter("glitch_strength", glitch)
	_hell_eye_effect_material.set_shader_parameter("tint_strength", tint)
	_hell_eye_effect_material.set_shader_parameter("flip_vertical", _hell_eye_inverted)


func _ensure_hell_eye_screen_overlay() -> void:
	if is_instance_valid(_hell_eye_effect_layer) and is_instance_valid(_hell_eye_effect_rect):
		return
	_hell_eye_effect_layer = CanvasLayer.new()
	_hell_eye_effect_layer.name = "HellEyeScreenEffectLayer"
	_hell_eye_effect_layer.layer = HELL_EYE_SCREEN_LAYER
	_hell_eye_effect_rect = ColorRect.new()
	_hell_eye_effect_rect.name = "HellEyeScreenEffectOverlay"
	_hell_eye_effect_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hell_eye_effect_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hell_eye_effect_rect.color = Color.TRANSPARENT
	_hell_eye_effect_material = ShaderMaterial.new()
	_hell_eye_effect_material.shader = HELL_EYE_SCREEN_EFFECT_SHADER
	_hell_eye_effect_rect.material = _hell_eye_effect_material
	_hell_eye_effect_layer.add_child(_hell_eye_effect_rect)
	get_tree().current_scene.add_child(_hell_eye_effect_layer)


func _clear_hell_eye_screen_overlay() -> void:
	if is_instance_valid(_hell_eye_effect_rect):
		# Screen-reading shaders ignore the ColorRect alpha in their fragment output.
		# Hide and detach the material before deferred deletion to avoid one stale frame.
		_hell_eye_effect_rect.visible = false
		_hell_eye_effect_rect.material = null
	if is_instance_valid(_hell_eye_effect_layer):
		_hell_eye_effect_layer.visible = false
		_hell_eye_effect_layer.queue_free()
	_hell_eye_effect_layer = null
	_hell_eye_effect_rect = null
	_hell_eye_effect_material = null


func _update_hell_eye_progress_ui() -> void:
	if _hell_eye_misalignment_progress <= 0.0:
		_clear_hell_eye_progress_ui()
		return
	_ensure_hell_eye_progress_ui()
	if not is_instance_valid(_hell_eye_progress_ring):
		return
	_hell_eye_progress_ring.global_position = _world_to_hell_eye_ui_position(global_position)
	_hell_eye_progress_ring.call("set_progress", _hell_eye_misalignment_progress)


func _ensure_hell_eye_progress_ui() -> void:
	if not is_instance_valid(_hell_eye_ui_layer):
		_hell_eye_ui_layer = CanvasLayer.new()
		_hell_eye_ui_layer.name = "HellEyeUILayer"
		_hell_eye_ui_layer.layer = HELL_EYE_UI_LAYER
		get_tree().current_scene.add_child(_hell_eye_ui_layer)
	if not is_instance_valid(_hell_eye_progress_ring):
		_hell_eye_progress_ring = Node2D.new()
		_hell_eye_progress_ring.name = "HellEyeProgressRing"
		_hell_eye_progress_ring.set_script(HELL_EYE_PROGRESS_RING_SCRIPT)
		_hell_eye_ui_layer.add_child(_hell_eye_progress_ring)


func _clear_hell_eye_progress_ui() -> void:
	if is_instance_valid(_hell_eye_ui_layer):
		_hell_eye_ui_layer.queue_free()
	_hell_eye_ui_layer = null
	_hell_eye_progress_ring = null


func _world_to_hell_eye_ui_position(world_pos: Vector2) -> Vector2:
	var viewport := get_viewport()
	# Use Godot's final world-to-viewport transform. This includes Camera2D limits,
	# zoom, offset, shake and edge clamping, which the previous hand formula missed.
	return viewport.get_canvas_transform() * world_pos


func _cancel_hell_eye_visuals() -> void:
	if _hell_eye_camera_has_original and is_instance_valid(_hell_eye_camera):
		_hell_eye_camera.global_position = _hell_eye_camera_original_position
		_hell_eye_camera.zoom = _hell_eye_camera_original_zoom
	_hell_eye_camera_returning = false
	_hell_eye_camera_has_original = false
	_hell_eye_camera = null
	_clear_hell_eye_screen_overlay()
	_clear_hell_eye_progress_ui()


func _update_gravity_claw_shake(delta: float) -> void:
	if gravity_claw_grappled and _grapple_shake_timer > 0.0:
		_grapple_shake_timer = maxf(0.0, _grapple_shake_timer - delta)
		sprite.position = Vector2(randf_range(-GRAPPLE_SHAKE_AMPLITUDE, GRAPPLE_SHAKE_AMPLITUDE), randf_range(-GRAPPLE_SHAKE_AMPLITUDE, GRAPPLE_SHAKE_AMPLITUDE))
	elif sprite.position != Vector2.ZERO:
		sprite.position = Vector2.ZERO


func _apply_grapple_inertia(delta: float) -> void:
	if _grapple_inertia_velocity == Vector2.ZERO:
		return
	var move_delta := _grapple_inertia_velocity * delta
	if blocked_by_space_rocks:
		_move_with_space_rock_block(move_delta)
	else:
		global_position += move_delta
	_clamp_to_movement_bounds()


func _get_gravity_claw_inertia_velocity(enemy: Node) -> Vector2:
	if not is_instance_valid(enemy):
		return Vector2.ZERO
	if enemy.has_method("get_gravity_claw_grapple_inertia_velocity"):
		var velocity = enemy.get_gravity_claw_grapple_inertia_velocity()
		if velocity is Vector2 and velocity.length() > 1.0:
			return velocity
	if enemy is Node2D:
		var dir := global_position - (enemy as Node2D).global_position
		if dir.length() > 0.01:
			return dir.normalized() * GRAPPLE_INERTIA_FALLBACK_SPEED
	return Vector2.ZERO


func _add_gravity_claw_enemy(enemy: Node) -> void:
	_prune_gravity_claw_enemies()
	if not _gravity_claw_enemies.has(enemy):
		_gravity_claw_enemies.append(enemy)
	_gravity_claw_enemy = _gravity_claw_enemies[0]


func _prune_gravity_claw_enemies() -> void:
	var alive: Array[Node] = []
	for grapple_enemy in _gravity_claw_enemies:
		if is_instance_valid(grapple_enemy):
			alive.append(grapple_enemy)
	_gravity_claw_enemies = alive
	_gravity_claw_enemy = _gravity_claw_enemies[0] if not _gravity_claw_enemies.is_empty() else null


func _get_grapple_stack_count() -> int:
	_prune_gravity_claw_enemies()
	return maxi(1, _gravity_claw_enemies.size())


func _get_grapple_required_progress() -> float:
	return GRAVITY_CLAW_ESCAPE_PROGRESS_MAX * float(_get_grapple_stack_count())


func _recalculate_grapple_inertia() -> void:
	_grapple_inertia_velocity = Vector2.ZERO
	for grapple_enemy in _gravity_claw_enemies:
		var velocity := _get_gravity_claw_inertia_velocity(grapple_enemy)
		if velocity.length() > _grapple_inertia_velocity.length():
			_grapple_inertia_velocity = velocity


func _get_gravity_claw_impact_damage(enemy: Node) -> int:
	if is_instance_valid(enemy) and enemy.has_method("get_gravity_claw_impact_damage"):
		return maxi(0, int(enemy.call("get_gravity_claw_impact_damage")))
	return 0


func _get_gravity_claw_dot_damage_per_second() -> float:
	var total := 0.0
	for grapple_enemy in _gravity_claw_enemies:
		if is_instance_valid(grapple_enemy) and grapple_enemy.has_method("get_gravity_claw_dot_damage_per_second"):
			total += maxf(0.0, float(grapple_enemy.call("get_gravity_claw_dot_damage_per_second")))
	return total


func _apply_grapple_damage_over_time(delta: float) -> void:
	var damage_per_second := _get_gravity_claw_dot_damage_per_second()
	if damage_per_second <= 0.0:
		return
	_grapple_damage_accumulator += damage_per_second * delta
	var whole_damage := int(floor(_grapple_damage_accumulator))
	if whole_damage <= 0:
		return
	_grapple_damage_accumulator -= whole_damage
	_apply_gravity_claw_damage(whole_damage, true)


func _apply_gravity_claw_damage(dmg: int, bypass_invincible: bool = false) -> void:
	if dmg <= 0 or _dash_active:
		return
	if invincible and not bypass_invincible:
		return
	dmg = _apply_player_damage_taken(dmg)
	_play_sfx(HURT_SOUND)
	GameManager.add_frenzy(dmg)
	GameManager.player_hp -= dmg
	if _check_player_death():
		return
	if not bypass_invincible:
		invincible = true
		invincible_timer = INVINCIBLE_DURATION


func _get_grapple_camera() -> Camera2D:
	var camera := get_viewport().get_camera_2d()
	if camera:
		return camera
	var scene := get_tree().current_scene
	if not scene:
		return null
	return _find_camera_2d(scene)


func has_active_camera_effect() -> bool:
	return gravity_claw_grappled \
		or _grapple_camera_returning \
		or _warped_lightning_effect_timer > 0.0 \
		or _warped_lightning_camera_returning \
		or _hell_eye_camera_has_original \
		or _hell_eye_camera_returning


func _find_camera_2d(node: Node) -> Camera2D:
	if node is Camera2D:
		return node as Camera2D
	for child in node.get_children():
		var found := _find_camera_2d(child)
		if found:
			return found
	return null


func _ensure_grapple_glitch_overlay() -> void:
	if is_instance_valid(_grapple_glitch_layer) and is_instance_valid(_grapple_glitch_rect):
		return
	_grapple_glitch_layer = CanvasLayer.new()
	_grapple_glitch_layer.name = "GravityClawGlitchLayer"
	_grapple_glitch_layer.layer = 90
	_grapple_glitch_rect = ColorRect.new()
	_grapple_glitch_rect.name = "GravityClawGlitchOverlay"
	_grapple_glitch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grapple_glitch_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grapple_glitch_rect.color = Color.TRANSPARENT
	_grapple_glitch_material = ShaderMaterial.new()
	_grapple_glitch_material.shader = GRAPPLE_GLITCH_SHADER
	_grapple_glitch_material.set_shader_parameter("strength", GRAPPLE_GLITCH_STRENGTH)
	_grapple_glitch_rect.material = _grapple_glitch_material
	_grapple_glitch_layer.add_child(_grapple_glitch_rect)
	get_tree().current_scene.add_child(_grapple_glitch_layer)


func _clear_grapple_glitch_overlay() -> void:
	if is_instance_valid(_grapple_glitch_layer):
		_grapple_glitch_layer.queue_free()
	_grapple_glitch_layer = null
	_grapple_glitch_rect = null
	_grapple_glitch_material = null


func _clear_grapple_ui() -> void:
	if is_instance_valid(_grapple_ui_layer):
		_grapple_ui_layer.queue_free()
	_grapple_icon = null
	_grapple_bar_bg = null
	_grapple_bar_fill = null
	_grapple_ui_layer = null


func _exit_tree() -> void:
	_clear_grapple_glitch_overlay()
	_clear_warped_lightning_glitch_overlay()
	_clear_hell_eye_screen_overlay()
	_clear_hell_eye_progress_ui()
	_clear_grapple_ui()


func apply_powerup_firerate() -> void:
	fire_rate = max(0.08, fire_rate - 0.05)

func apply_powerup_atk() -> void:
	atk += 1

func apply_powerup_heal() -> void:
	GameManager.player_hp = min(GameManager.PLAYER_MAX_HP, GameManager.player_hp + 20)

func apply_powerup_shield() -> void:
	invincible = true
	invincible_timer = 5.0


func _play_sfx(stream: AudioStream) -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.bus = &"SFX"
	sfx.stream = stream
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)


func _get_effective_fire_rate() -> float:
	return maxf(0.03, fire_rate * GameManager.get_fire_rate_multiplier())


func _apply_player_damage_taken(dmg: int) -> int:
	# 装甲晶格：受击减伤
	var reduced := int(round(float(dmg) * _run_damage_taken_mult))
	return GameManager.get_incoming_damage_after_frenzy(maxi(1, reduced))


func _update_dash_cooldown(delta: float) -> void:
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer = maxf(0.0, _dash_cooldown_timer - delta)


func _start_dash(input_dir: Vector2) -> void:
	if _dash_active or _dash_cooldown_timer > 0.0:
		return
	var dir := input_dir.normalized()
	if dir == Vector2.ZERO:
		# 无移动输入时向机头反方向后撤闪避（旋转后的单位向量恒非零，无需再兜底）
		dir = -Vector2(0, -1).rotated(rotation).normalized()
	_dash_active = true
	_dash_velocity = dir.normalized() * DASH_SPEED * _run_dash_speed_mult
	_dash_remaining_distance = DASH_DISTANCE * _run_dash_distance_mult
	_dash_distance_traveled = 0.0
	_dash_cooldown_timer = DASH_COOLDOWN
	_dash_afterimage_timer = 0.0
	_dash_hit_targets.clear()
	_dash_chain_left = _run_dash_chain
	_dash_rebound_stacks = 0
	_dash_trail_timer = 0.0
	_pre_dash_collision_layer = collision_layer
	_pre_dash_collision_mask = collision_mask
	_pre_dash_monitoring = monitoring
	_pre_dash_monitorable = monitorable
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	invincible = true
	invincible_timer = maxf(invincible_timer, _dash_remaining_distance / maxf(_dash_velocity.length(), 1.0) + 0.05)
	current_velocity = _dash_velocity
	_spawn_dash_afterimage()


func _update_dash(delta: float) -> void:
	var distance := minf(_dash_velocity.length() * delta, _dash_remaining_distance)
	if distance <= 0.0:
		_end_dash()
		return
	var reflected := false
	var travel_left := distance
	while travel_left > 0.0 and _dash_remaining_distance > 0.0:
		var step := minf(DASH_STEP_DISTANCE, travel_left)
		var move_delta := _dash_velocity.normalized() * step
		reflected = _dash_move_and_reflect(move_delta) or reflected
		_dash_remaining_distance -= step
		_dash_distance_traveled += step
		travel_left -= step
	# 能量尾迹：冲刺途中对沿途敌人持续造成伤害
	if _run_dash_trail_damage_mult > 0.0:
		_dash_trail_timer -= delta
		if _dash_trail_timer <= 0.0:
			_dash_trail_timer = 0.06
			_apply_dash_trail_damage()
	_dash_afterimage_timer -= delta
	if _dash_afterimage_timer <= 0.0:
		_spawn_dash_afterimage()
		_dash_afterimage_timer = DASH_AFTERIMAGE_INTERVAL
	current_velocity = _dash_velocity
	rotation = lerp_angle(rotation, _dash_velocity.angle() + PI / 2.0, rotation_speed * delta)
	if reflected:
		_spawn_dash_afterimage()
	if _dash_remaining_distance <= 0.0:
		_end_dash()


func _end_dash() -> void:
	_dash_active = false
	current_velocity = Vector2.ZERO
	_dash_hit_targets.clear()
	collision_layer = _pre_dash_collision_layer
	collision_mask = _pre_dash_collision_mask
	monitoring = _pre_dash_monitoring
	monitorable = _pre_dash_monitorable


func _dash_move_and_reflect(delta_pos: Vector2) -> bool:
	var start_pos := global_position
	var end_pos := global_position + delta_pos
	# 撞到敌人
	var enemy_hit := _get_dash_enemy_hit(start_pos, end_pos)
	if enemy_hit != null:
		_apply_dash_impact_damage(enemy_hit)
		# 智能导向：撞到后自动转向下一个敌人继续冲，形成连锁
		if _dash_chain_left > 0:
			var next := _find_dash_chain_target(enemy_hit)
			if next != null:
				_dash_chain_left -= 1
				global_position = start_pos
				var to_next := _get_node_world_position(next) - start_pos
				if to_next.length() > 1.0:
					_dash_velocity = to_next.normalized() * DASH_SPEED * _run_dash_speed_mult
					_dash_remaining_distance = maxf(_dash_remaining_distance, DASH_DISTANCE * 0.5 * _run_dash_distance_mult)
					return true
		global_position = start_pos
		_dash_reflect_off(enemy_hit)
		return true
	# 撞到障碍
	var obstacle_hit := _get_dash_obstacle_hit(start_pos, end_pos)
	if obstacle_hit != null:
		# 破障采矿：可破坏物直接撞碎穿过（它自身触发掉矿），不反弹
		if _run_dash_mining > 0.0 and _try_dash_break_obstacle(obstacle_hit):
			global_position = end_pos
			return false
		global_position = start_pos
		_dash_reflect_off(obstacle_hit)
		return true
	global_position = end_pos
	_clamp_to_movement_bounds()
	if global_position.distance_squared_to(end_pos) > 1.0:
		var normal := Vector2.ZERO
		if global_position.x <= movement_bounds.position.x or global_position.x >= movement_bounds.position.x + movement_bounds.size.x:
			normal.x = -signf(_dash_velocity.x)
		if global_position.y <= movement_bounds.position.y or global_position.y >= movement_bounds.position.y + movement_bounds.size.y:
			normal.y = -signf(_dash_velocity.y)
		if normal != Vector2.ZERO:
			_dash_velocity = _dash_velocity.bounce(normal.normalized()).normalized() * DASH_SPEED * _run_dash_speed_mult
			_dash_remaining_distance *= 0.72
			_dash_rebound_stacks += 1
			return true
	return false


func _get_dash_enemy_hit(start_point: Vector2, end_point: Vector2) -> Node:
	var best: Node = null
	var best_dist := INF
	for group_name in [&"enemies", &"boss", &"defense_turrets"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(node) or node == self or node.is_queued_for_deletion():
				continue
			if node is CanvasItem and not (node as CanvasItem).visible:
				continue
			var radius := DASH_ENEMY_HIT_RADIUS
			if group_name == &"boss":
				radius = DASH_BOSS_HIT_RADIUS
			var center := _get_node_world_position(node)
			var hit_radius := radius + collision_radius
			var start_dist := center.distance_to(start_point)
			var end_dist := center.distance_to(end_point)
			if _dash_is_entering_overlap(start_dist, end_dist, hit_radius) and end_dist < best_dist:
				best = node
				best_dist = end_dist
	return best


func _get_dash_obstacle_hit(start_point: Vector2, end_point: Vector2) -> Node:
	if _dash_distance_traveled < DASH_START_CLEARANCE_DISTANCE:
		return null
	for obstacle in _get_blocking_obstacles():
		if not is_instance_valid(obstacle) or obstacle.is_queued_for_deletion():
			continue
		if obstacle is CanvasItem and not (obstacle as CanvasItem).visible:
			continue
		var start_depth := _dash_obstacle_overlap_depth(obstacle, start_point)
		var end_depth := _dash_obstacle_overlap_depth(obstacle, end_point)
		if _dash_is_entering_overlap_depth(start_depth, end_depth):
			return obstacle
	return null


func _dash_obstacle_contains_point(obstacle: Node, point: Vector2) -> bool:
	return _dash_obstacle_overlap_depth(obstacle, point) > 0.0


func _dash_obstacle_overlap_depth(obstacle: Node, point: Vector2) -> float:
	var margin := collision_radius + DASH_OBSTACLE_EXTRA_MARGIN
	if obstacle.has_method("get_collision_query_radius"):
		var center := _obstacle_query_center(obstacle)
		var radius := float(obstacle.call("get_collision_query_radius")) + margin
		return radius - center.distance_to(point)
	if obstacle.has_method("get_map_start") and obstacle.has_method("get_map_end"):
		var start: Vector2 = obstacle.call("get_map_start")
		var end: Vector2 = obstacle.call("get_map_end")
		var width := margin
		if obstacle.has_method("get_map_width"):
			width += float(obstacle.call("get_map_width")) * 0.5
		return width - _distance_point_to_segment(point, start, end)
	var fallback_center := _obstacle_query_center(obstacle)
	return margin - fallback_center.distance_to(point)


func _dash_is_entering_overlap(start_dist: float, end_dist: float, hit_radius: float) -> bool:
	if end_dist > hit_radius:
		return false
	if start_dist > hit_radius:
		return true
	return end_dist < start_dist - 0.5


func _dash_is_entering_overlap_depth(start_depth: float, end_depth: float) -> bool:
	if end_depth <= 0.0:
		return false
	if start_depth <= 0.0:
		return true
	return end_depth > start_depth + 0.5


func _apply_dash_impact_damage(target: Node) -> void:
	if _dash_hit_targets.has(target):
		return
	# 折返强化：每次反弹提升本次撞击伤害
	var mult := _run_dash_damage_mult * (1.0 + _run_dash_rebound_bonus * float(_dash_rebound_stacks))
	var amount := maxi(1, int(round(float(atk * DASH_REFLECT_DAMAGE_MULT) * mult)))
	_dash_hit_targets.append(target)
	_apply_damage_to_dash_target(target, amount)
	_apply_dash_aftershock(target, amount)
	# 撞击护盾：命中敌人后获得短暂无敌
	if _run_dash_shield_duration > 0.0:
		invincible = true
		invincible_timer = maxf(invincible_timer, _run_dash_shield_duration)


func _dash_reflect_off(hit_node: Node) -> void:
	var hit_normal := (global_position - _get_node_world_position(hit_node)).normalized()
	if hit_normal == Vector2.ZERO:
		hit_normal = -_dash_velocity.normalized()
	_dash_velocity = _dash_velocity.bounce(hit_normal).normalized() * DASH_SPEED * _run_dash_speed_mult
	_dash_remaining_distance *= 0.72
	_dash_rebound_stacks += 1


func _find_dash_chain_target(exclude: Node) -> Node:
	var best: Node = null
	var best_dist := DASH_CHAIN_RANGE
	for group_name in [&"enemies", &"boss", &"defense_turrets"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(node) or node == self or node == exclude or node.is_queued_for_deletion():
				continue
			if _dash_hit_targets.has(node):
				continue
			if node is CanvasItem and not (node as CanvasItem).visible:
				continue
			var d := global_position.distance_to(_get_node_world_position(node))
			if d < best_dist:
				best_dist = d
				best = node
	return best


func _try_dash_break_obstacle(obstacle: Node) -> bool:
	if obstacle == null or not is_instance_valid(obstacle):
		return false
	if obstacle.is_in_group(&"space_clutter") or obstacle.is_in_group(&"explore_rewards"):
		if obstacle.has_method("take_damage"):
			obstacle.take_damage(9999)
			return true
	return false


func _apply_dash_trail_damage() -> void:
	var dmg := maxi(1, int(round(float(atk) * _run_dash_trail_damage_mult)))
	for group_name in [&"enemies", &"boss", &"defense_turrets"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(node) or node == self or node.is_queued_for_deletion():
				continue
			if node is CanvasItem and not (node as CanvasItem).visible:
				continue
			if global_position.distance_to(_get_node_world_position(node)) <= DASH_TRAIL_RADIUS:
				_apply_damage_to_dash_target(node, dmg)


func _apply_damage_to_dash_target(target: Node, amount: int) -> void:
	if target.has_method("take_damage"):
		target.call("take_damage", amount, self)
	elif target.has_method("take_boss_damage"):
		target.call("take_boss_damage", amount)
	elif target.has_method("apply_damage"):
		target.call("apply_damage", amount)


func _apply_dash_aftershock(source_target: Node, impact_amount: int) -> void:
	if _run_dash_aftershock_radius <= 0.0 or _run_dash_aftershock_damage_mult <= 0.0:
		return
	var center := _get_node_world_position(source_target)
	var amount := maxi(1, int(round(float(impact_amount) * _run_dash_aftershock_damage_mult)))
	for group_name in [&"enemies", &"boss", &"defense_turrets"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(node) or node == source_target or node == self or node.is_queued_for_deletion():
				continue
			if node is CanvasItem and not (node as CanvasItem).visible:
				continue
			if center.distance_to(_get_node_world_position(node)) > _run_dash_aftershock_radius:
				continue
			_apply_damage_to_dash_target(node, amount)


func _ensure_support_drones() -> void:
	# 清除本机现有僚机后按装载清单重建（每件贡献自己类型的僚机，可混合）
	for node in get_tree().get_nodes_in_group(&"player_support_drones"):
		if is_instance_valid(node) and node.get_meta(&"owner_player", null) == self:
			node.queue_free()
	if _drone_loadout.is_empty() or not is_inside_tree():
		return
	var count := _drone_loadout.size()
	for i in range(count):
		var drone = SUPPORT_DRONE_SCENE.instantiate()
		drone.set_meta(&"owner_player", self)
		if drone.has_method("setup"):
			drone.call("setup", self, i, count, _drone_loadout[i])
		drone.global_position = global_position + Vector2(42.0, 0.0).rotated(TAU * float(i) / maxf(float(count), 1.0))
		add_child(drone)


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


func _spawn_dash_afterimage() -> void:
	if not is_instance_valid(sprite) or sprite.texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.global_position = sprite.global_position
	ghost.global_rotation = sprite.global_rotation
	ghost.global_scale = sprite.global_scale
	ghost.modulate = Color(0.35, 0.85, 1.0, 0.42)
	ghost.z_index = sprite.z_index - 1
	get_tree().current_scene.add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, DASH_AFTERIMAGE_LIFETIME)
	tween.tween_callback(ghost.queue_free)


func _is_mouse_over_map() -> bool:
	for map in get_tree().get_nodes_in_group(&"map_ui"):
		if map.visible and map.get_global_rect().has_point(get_viewport().get_mouse_position()):
			return true
	return false


func _clamp_to_movement_bounds() -> void:
	position.x = clamp(position.x, movement_bounds.position.x, movement_bounds.position.x + movement_bounds.size.x)
	position.y = clamp(position.y, movement_bounds.position.y, movement_bounds.position.y + movement_bounds.size.y)


func _clamp_camera_center_to_bounds(center: Vector2, zoom: Vector2) -> Vector2:
	var bounds := movement_bounds
	if bounds.size == Vector2.ZERO:
		bounds = Rect2(Vector2.ZERO, screen_size)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return center
	var viewport_size := get_viewport().get_visible_rect().size
	var safe_zoom := Vector2(maxf(absf(zoom.x), 0.001), maxf(absf(zoom.y), 0.001))
	var half_view := Vector2(viewport_size.x / safe_zoom.x, viewport_size.y / safe_zoom.y) * 0.5
	var min_center := bounds.position + half_view
	var max_center := bounds.position + bounds.size - half_view
	var clamped := center
	if min_center.x > max_center.x:
		clamped.x = bounds.position.x + bounds.size.x * 0.5
	else:
		clamped.x = clampf(center.x, min_center.x, max_center.x)
	if min_center.y > max_center.y:
		clamped.y = bounds.position.y + bounds.size.y * 0.5
	else:
		clamped.y = clampf(center.y, min_center.y, max_center.y)
	return clamped


func _move_with_space_rock_block(delta_pos: Vector2) -> void:
	if not blocked_by_space_rocks or delta_pos == Vector2.ZERO:
		position += delta_pos
		return
	var next_pos = position + delta_pos
	for obstacle in _get_blocking_obstacles():
		if not is_instance_valid(obstacle) or obstacle.is_queued_for_deletion():
			continue
		if obstacle is CanvasItem and not (obstacle as CanvasItem).visible:
			continue
		if not _obstacle_near_point(obstacle, next_pos):
			continue
		if obstacle.has_method(&"get_push_out_position"):
			next_pos = obstacle.get_push_out_position(next_pos, collision_radius)
	position = next_pos


func _get_blocking_obstacles() -> Array[Node]:
	var now := Time.get_ticks_msec() * 0.001
	if now - _blocking_obstacles_cache_time < OBSTACLE_CACHE_INTERVAL:
		return _blocking_obstacles_cache
	_blocking_obstacles_cache_time = now
	var result: Array[Node] = []
	for group_name in [&"space_rocks", &"explore_rewards", &"space_clutter", &"isolation_bands"]:
		for node in get_tree().get_nodes_in_group(group_name):
			result.append(node)
	_blocking_obstacles_cache = result
	return result


func _obstacle_near_point(obstacle: Node, point: Vector2) -> bool:
	var margin := collision_radius + OBSTACLE_QUERY_EXTRA_MARGIN
	if obstacle.has_method("get_collision_query_radius"):
		var center := _obstacle_query_center(obstacle)
		var radius := float(obstacle.call("get_collision_query_radius")) + margin
		return center.distance_squared_to(point) <= radius * radius
	if obstacle.has_method("get_map_start") and obstacle.has_method("get_map_end"):
		var start: Vector2 = obstacle.call("get_map_start")
		var end: Vector2 = obstacle.call("get_map_end")
		var width := margin
		if obstacle.has_method("get_map_width"):
			width += float(obstacle.call("get_map_width")) * 0.5
		return _distance_point_to_segment(point, start, end) <= width
	var fallback_center := _obstacle_query_center(obstacle)
	return fallback_center.distance_squared_to(point) <= margin * margin


func _obstacle_query_center(obstacle: Node) -> Vector2:
	if obstacle.has_method("get_base_position"):
		var pos = obstacle.call("get_base_position")
		if pos is Vector2:
			return pos
	if obstacle.has_method("get_map_position"):
		var pos = obstacle.call("get_map_position")
		if pos is Vector2:
			return pos
	if obstacle is Node2D:
		return (obstacle as Node2D).global_position
	return global_position


func _distance_point_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() <= 0.001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
