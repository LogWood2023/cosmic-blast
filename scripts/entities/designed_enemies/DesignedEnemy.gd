extends "res://scripts/entities/enemies/BaseEnemy.gd"

const BULLET_SCENE = preload("res://scenes/entities/projectiles/EnemyBullet.tscn")
const DESIGNED_ENEMY_SCENE_PATH := "res://scenes/entities/designed_enemies/DesignedEnemy.tscn"
const DesignedEnemyCatalog = preload("res://scripts/entities/designed_enemies/DesignedEnemyCatalog.gd")
const ALERT_ARROW_SCRIPT = preload("res://scripts/entities/designed_enemies/AlertArrowVisual.gd")
const CALIBRATOR_SHOT_SOUND = preload("res://assets/audio/shoot.wav")
const HORIZON_PHANTOM_DISTORT_SHADER = preload("res://assets/shaders/horizon_phantom_distort.gdshader")

static var _behavior_texture_cache: Dictionary = {}
static var _behavior_texture_thread_requests: Dictionary = {}
static var _designed_enemy_scene: PackedScene
static var _core_devourer_gravity_claw_pool: Array[Node2D] = []
static var _horizon_phantom_material: ShaderMaterial
static var _divine_oracle_phantom_material: ShaderMaterial

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
@export var detection_range: float = 1600.0
@export var turn_speed: float = 6.0
@export var pursuit_timeout: float = 30.0

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
var _shield_energy: int = 0
var _visual_parts: Array[ColorRect] = []
var _visual_behavior: int = -1
var _visual_waiting_for_texture: bool = false
var _active_effects: Array[Dictionary] = []
var _last_safe_position: Vector2 = Vector2.ZERO
var _blocking_obstacles_cache: Array[Node] = []
var _blocking_obstacles_cache_time: float = -9999.0
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
var _gravity_claw_charge_target: Vector2 = Vector2.ZERO
var _gravity_claw_is_retreating: bool = false
var _gravity_claw_is_fast_charging: bool = false
var _gravity_claw_retreat_start: Vector2 = Vector2.ZERO
var _gravity_claw_retreat_target: Vector2 = Vector2.ZERO
var _gravity_claw_retreat_elapsed: float = 0.0
var _gravity_claw_grappled_player: Area2D
var _gravity_claw_grapple_offset: Vector2 = Vector2.ZERO
var _gravity_claw_grapple_inertia_velocity: Vector2 = Vector2.ZERO
var _gravity_claw_recovery_timer: float = 0.0
var _gravity_claw_knock_velocity: Vector2 = Vector2.ZERO
var _gravity_claw_impact_damage: int = 0
var _gravity_claw_dot_damage_per_second: float = 0.0
var _gravity_claw_core_launch_active: bool = false
var _gravity_claw_core_summoned: bool = false
var _gravity_claw_core_owner: Node
var _gravity_claw_core_decay_accumulator: float = 0.0
var _is_pursuing_player: bool = false
var _pursuit_target: Vector2 = Vector2.ZERO
var _pursuit_repath_timer: float = 0.0
var _clear_line_stability: float = 0.0
var _ai_alert: bool = false
var _pursuit_elapsed: float = 0.0
var _idle_origin: Vector2 = Vector2.ZERO
var _idle_origin_set: bool = false
var _idle_patrol_target: Vector2 = Vector2.ZERO
var _idle_patrol_pause: float = 0.0
var _alert_notice_active: bool = false
var _alert_notice_timer: float = 0.0
var _alert_notice_node: Node2D
var _alert_arrow_node: Node2D
var _shield_bee_shield_time: float = 0.0
var _shield_bee_target: Vector2 = Vector2.ZERO
var _shield_bee_repath_timer: float = 0.0
var _shield_bee_path: Array[Vector2] = []
var _shield_bee_path_index: int = 0
var _shield_bee_path_avoid_player: bool = false
var _shield_bee_last_progress_position: Vector2 = Vector2.ZERO
var _shield_bee_stuck_timer: float = 0.0
var _shield_bee_repath_failures: int = 0
var _core_devourer_claw_timer: float = 0.0
var _core_devourer_counter_claw_timer: float = 0.0
var _core_devourer_claw_warnings: Array[Dictionary] = []
var _core_devourer_pool_prewarm_requested: bool = false
var _core_devourer_pool_prewarm_timer: float = 0.0
var _calibrator_shot_timer: float = 0.0
var _calibrator_warning_timer: float = 0.0
var _calibrator_locked_dir: Vector2 = Vector2.ZERO
var _calibrator_recoil_velocity: Vector2 = Vector2.ZERO
var _calibrator_dodge_side: float = 1.0
var _calibrator_ray_timer: float = 0.0
var _calibrator_ray_points: PackedVector2Array = PackedVector2Array()
var _sanctum_spin_speed: float = 0.0
var _sanctum_spin_active: bool = false
var _sanctum_spin_fire_timer: float = 0.0
var _warped_spin_speed: float = 0.0
var _warped_lightning_phase: float = 0.0
var _hell_eye_black_line_phase: float = 0.0
var _hell_eye_blind_latched: bool = false
var _hell_eye_inverted_moth_phantom: Sprite2D
var _hell_eye_inverted_moth_phantom_offset: Vector2 = Vector2.ZERO
var _hell_eye_horizon_phantoms: Array[Sprite2D] = []
var _hell_eye_horizon_phantom_data: Array[Dictionary] = []
var _hell_eye_horizon_warning_locked: bool = false
var _hell_eye_horizon_return_active: bool = false
var _hell_eye_horizon_return_elapsed: float = 0.0
var _hell_eye_horizon_visual_texture: Texture2D
var _hell_eye_horizon_visual_centered: bool = true
var _hell_eye_horizon_visual_region_enabled: bool = false
var _hell_eye_horizon_visual_region_rect: Rect2 = Rect2()
var _hell_eye_horizon_visual_scale: Vector2 = Vector2.ONE
var _hell_eye_horizon_visual_modulate: Color = Color.TRANSPARENT
var _hell_eye_horizon_visual_z_index: int = 0
var _divine_raider_side_shot_distance: float = 0.0
var _divine_raider_side_shot_next: float = 0.0
var _divine_teleport_phase: int = 0
var _divine_teleport_mode: int = 0
var _divine_teleport_timer: float = 0.0
var _divine_teleport_target: Vector2 = Vector2.ZERO
var _divine_teleport_warning_remaining: float = -1.0
var _divine_teleport_material: ShaderMaterial
var _divine_sprite_original_material: Material
var _divine_sprite_original_modulate: Color = Color.WHITE
var _divine_oracle_spawn_timer: float = 0.0
var _divine_oracle_phantom_data: Array[Dictionary] = []
var _divine_oracle_frame_side_shots: int = 0
var _explore_patrol_enabled: bool = false
var _explore_patrol_points: PackedVector2Array = PackedVector2Array()
var _explore_patrol_offset: Vector2 = Vector2.ZERO
var _explore_patrol_index: int = 1
var _explore_patrol_room_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var _explore_patrol_despawn_margin: float = 900.0
var _explore_room_idle_enabled: bool = false
var _explore_pool_enabled: bool = false
var _explore_pool_active: bool = false
# 每次回收进池递增，供 await 型延时技能识别"本体已被复用"
var _explore_pool_generation: int = 0
var _explore_pool_releasing: bool = false
var _explore_pool_owner: Node
var _explore_pool_key: int = -1
var _explore_room_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var _explore_alert_probe_timer: float = 0.0
var _explore_pursuit_probe_timer: float = 0.0
var _explore_render_active: bool = true
var _explore_combat_target: Vector2 = Vector2.ZERO
var _explore_combat_target_timer: float = 0.0
var _detection_los_timer: float = 0.0
var _detection_los_blocked: bool = false
var _fast_los_timer: float = 0.0
var _fast_los_clear: bool = true
var _pursuit_path_check_timer: float = 0.0
var _pursuit_target_blocked: bool = false
var _positioning_visibility_timer: float = 0.0

const SHIELD_BEE_SHIELD_DURATION: float = 0.5
const SHIELD_BEE_SHIELD_ALPHA: float = 0.5
const SHIELD_BEE_TARGET_DISTANCE: float = 500.0
const SHIELD_BEE_REPATH_INTERVAL: float = 2.25
const SHIELD_BEE_REPATH_DEFER_RETRY: float = 0.45
const PARADISE_FORMATION_DISTANCE_MULT: float = 0.6
const PARADISE_FORMATION_RANDOM_ATTEMPTS: int = 12
const PARADISE_FORMATION_RANDOM_OFFSET_MIN: float = 80.0
const PARADISE_FORMATION_RANDOM_OFFSET_MAX: float = 240.0
const PARADISE_FORMATION_ENEMY_CLEARANCE: float = 44.0
const PARADISE_FORMATION_AIM_TURN_SPEED: float = 14.0
const PARADISE_FORMATION_AIM_TOLERANCE: float = 0.08
const POSITIONING_PLAYER_TANGENT_FRONT_DOT: float = 0.55
const POSITIONING_PLAYER_TANGENT_EXTRA_CLEARANCE: float = 58.0
const POSITIONING_PLAYER_TANGENT_MIN_RADIUS: float = 160.0
const PARADISE_PATROL_BULLET_SPEED: float = 560.0
const PARADISE_ARC_SCATTER_BULLET_SPEED: float = 380.0
const PARADISE_RAIL_CHAIN_BULLET_SPEED: float = 640.0
const PARADISE_CALIBRATOR_DISTANCE_MULT: float = 0.8
const PARADISE_SANCTUM_DISTANCE_MULT: float = 0.3
const CALIBRATOR_WARNING_DURATION: float = 1.0
const CALIBRATOR_SHOT_MIN_INTERVAL: float = 5.0
const CALIBRATOR_SHOT_MAX_INTERVAL: float = 10.0
const CALIBRATOR_BULLET_SPEED: float = PARADISE_PATROL_BULLET_SPEED * 5.0
const CALIBRATOR_BULLET_DAMAGE: int = 30
const CALIBRATOR_RECOIL_SPEED: float = 180.0
const CALIBRATOR_RECOIL_DECAY: float = 7.0
const CALIBRATOR_RAY_UPDATE_INTERVAL: float = 0.18
const CALIBRATOR_RAY_LENGTH_MULT: float = 1.6
const SANCTUM_SPIN_ENTER_DISTANCE_MULT: float = 0.6
const SANCTUM_SPIN_EXIT_DISTANCE_MULT: float = 0.8
const SANCTUM_SPIN_MAX_SPEED: float = TAU
const SANCTUM_SPIN_ACCEL_TIME: float = 1.0
const SANCTUM_SPIN_DECEL_TIME: float = 1.2
const SANCTUM_SPIN_FIRE_INTERVAL: float = 0.2
const SANCTUM_SPIN_BULLET_SPEED: float = 520.0
const SANCTUM_SPIN_BULLET_DAMAGE: int = 8
const SANCTUM_SPIN_BULLET_SCALE: float = 1.2
const OBSTACLE_PATH_CELL_SIZE: float = 120.0
const OBSTACLE_PATH_MAX_EXPANSIONS: int = 10
const OBSTACLE_PATH_REACHED_DISTANCE: float = 24.0
const OBSTACLE_PATH_STUCK_DISTANCE: float = 2.0
const OBSTACLE_PATH_STUCK_TIME: float = 1.1
const OBSTACLE_PUSH_RESOLVE_ITERATIONS: int = 2
const OBSTACLE_PATH_FRAME_SLICE_USEC: int = 1800
const OBSTACLE_CACHE_INTERVAL: float = 0.8
const OBSTACLE_QUERY_EXTRA_MARGIN: float = 180.0
const EXPLORE_COMBAT_TARGET_INTERVAL: float = 0.55
const EXPLORE_COMBAT_STOP_DISTANCE: float = 320.0
const EXPLORE_COMBAT_RETREAT_DISTANCE: float = 190.0
const EXPLORE_LOS_SAMPLE_DISTANCE: float = 260.0
const IDLE_PATROL_RADIUS: float = 120.0
const IDLE_PATROL_SPEED_MULT: float = 0.56
const IDLE_PATROL_REACHED_DISTANCE: float = 12.0
const EXPLORE_ALERT_PROBE_INTERVAL: float = 0.35
const EXPLORE_PURSUIT_PROBE_INTERVAL: float = 0.25
const EXPLORE_ALERT_PROBE_JITTER: float = 0.2
const DETECTION_LOS_CHECK_INTERVAL: float = 0.28
const FAST_LOS_CHECK_INTERVAL: float = 0.22
const PURSUIT_PATH_CHECK_INTERVAL: float = 0.45
const POSITIONING_VISIBILITY_CHECK_INTERVAL: float = 1.8
const ALERT_NOTICE_DURATION: float = 0.72
const ALERT_ARROW_TRAVEL_DURATION: float = 0.28
const ALERT_ARROW_HOLD_DURATION: float = 0.5
const ALERT_ARROW_FADE_DURATION: float = 0.18
const GRAVITY_CLAW_RETREAT_DISTANCE: float = 50.0
const GRAVITY_CLAW_RETREAT_DURATION: float = 0.35
const GRAVITY_CLAW_CHARGE_SPEED_MULT: float = 5.0
const GRAVITY_CLAW_GRAPPLE_INERTIA_DIVISOR: float = 8.0
const COLOSSUS_GUARD_PLAYER_KNOCKBACK_SPEED_MULT: float = 1.35
const COLOSSUS_GUARD_PLAYER_KNOCKBACK_DURATION: float = 0.42
const COLOSSUS_GUARD_SELF_BOUNCE_DURATION: float = 0.24
const COLOSSUS_GUARD_SELF_BOUNCE_SPEED_MULT: float = 0.7
const CORE_DEVOURER_CLAW_SPEED: float = 500.0
const CORE_DEVOURER_CLAW_DOT_DAMAGE_PER_SECOND: float = 1.0
const CORE_DEVOURER_CLAW_WARNING_DURATION: float = 1.0
const CORE_DEVOURER_CLAW_WARNING_LENGTH: float = 620.0
const CORE_DEVOURER_CLAW_HP_DECAY_PER_SECOND: float = 10.0
const CORE_DEVOURER_CLAW_OVERLOAD_COUNT: int = 5
const CORE_DEVOURER_CLAW_OVERLOAD_HP_DECAY_PER_SECOND: float = 20.0
const CORE_DEVOURER_MAX_GRAVITY_CLAWS_PER_OWNER: int = 5
const CORE_DEVOURER_MAX_PENDING_CLAW_WARNINGS: int = 2
const CORE_DEVOURER_COUNTER_CLAW_MIN_INTERVAL: float = 0.45
const CORE_DEVOURER_GRAVITY_CLAW_POOL_PREWARM: int = 5
const CORE_DEVOURER_GRAVITY_CLAW_POOL_LIMIT: int = 8
const CORE_DEVOURER_GRAVITY_CLAW_TARGET_OVERSHOOT: float = 260.0
const CORE_DEVOURER_GRAVITY_CLAW_POOL_PREWARM_INTERVAL: float = 0.08
const DESIGNED_ENEMY_SPRITE_ROTATION_OFFSET: float = PI
const WARPED_IDLE_SPIN_SPEED: float = PI
const WARPED_ALERT_SPIN_SPEED: float = TAU
const WARPED_SPIN_ACCEL: float = PI
const WARPED_FRONT_DISTANCE_MULT: float = 0.45
const WARPED_BACK_DISTANCE_MULT: float = 0.25
const WARPED_FORCE_FIELD_RANGE_MULT: float = 0.85
const WARPED_FORCE_FIELD_ACCEL: float = 1200.0
const WARPED_LIGHTNING_RANGE_MULT: float = 0.3
const WARPED_LIGHTNING_DAMAGE_PER_SECOND: float = 2.0
const WARPED_LIGHTNING_SLOW_MULT: float = 0.5
const WARPED_LIGHTNING_SLOW_REFRESH: float = 0.16
const WARPED_REFLECT_BOUNCES: int = 5
const WARPED_REFRACTION_BULLET_SPEED: float = 560.0
const WARPED_COLLAPSE_SHOTGUN_MIN_ARC: float = PI * 40.0 / 180.0
const WARPED_COLLAPSE_SHOTGUN_MAX_ARC: float = PI * 90.0 / 180.0
const WARPED_COLLAPSE_SHOTGUN_MIN_COUNT: int = 8
const WARPED_COLLAPSE_SHOTGUN_MAX_COUNT: int = 10
const HELLEYE_INVERTED_MOTH_ALPHA: float = 0.1
const HELLEYE_INVERTED_MOTH_DAMAGE_MULT: float = 0.7
const HELLEYE_BLIND_LINK_RANGE_MULT: float = 0.3
const HELLEYE_BLIND_LINK_DAMAGE_PER_SECOND: float = 3.0
const HELLEYE_MISALIGN_LINK_RANGE_MULT: float = 0.7
const HELLEYE_HORIZON_DAMAGE_MULT: float = 1.5
const HELLEYE_HORIZON_PLAYER_KNOCKBACK_DURATION: float = 0.5
const HELLEYE_HORIZON_PLAYER_KNOCKBACK_SPEED_MULT: float = 1.15
const HELLEYE_HORIZON_SELF_BOUNCE_DURATION: float = 0.2
const HELLEYE_HORIZON_SELF_BOUNCE_SPEED_MULT: float = 0.55
const HELLEYE_HORIZON_PHANTOM_COUNT: int = 11
const HELLEYE_HORIZON_PHANTOM_ANGLE_STEP: float = PI / 6.0
const HELLEYE_HORIZON_PHANTOM_RETREAT_DISTANCE: float = 50.0
const HELLEYE_HORIZON_PHANTOM_CHARGE_OVERSHOOT: float = 260.0
const HELLEYE_HORIZON_PHANTOM_RETURN_DURATION: float = 0.55
const DIVINE_TELEPORT_NONE: int = 0
const DIVINE_TELEPORT_BLINK: int = 1
const DIVINE_TELEPORT_ASSASSIN: int = 2
const DIVINE_TELEPORT_SERAPH_RETARGET: int = 3
const DIVINE_TELEPORT_FADE_OUT: int = 1
const DIVINE_TELEPORT_FADE_IN: int = 2
const DIVINE_TELEPORT_FADE_DURATION: float = 0.3
const DIVINE_ASSASSIN_WARNING_DURATION: float = 1.0
const DIVINE_BLINK_DISTANCE_MULT: float = 0.7
const DIVINE_ASSASSIN_DISTANCE_MULT: float = 0.7
const DIVINE_SERAPH_PLAYER_KNOCKBACK_DURATION: float = 0.5
const DIVINE_SERAPH_PLAYER_KNOCKBACK_SPEED_MULT: float = 1.2
const DIVINE_SERAPH_SELF_BOUNCE_DURATION: float = 0.2
const DIVINE_SERAPH_SELF_BOUNCE_SPEED_MULT: float = 0.55
const DIVINE_RAIDER_SIDE_SHOT_MIN_DISTANCE: float = 100.0
const DIVINE_RAIDER_SIDE_SHOT_MAX_DISTANCE: float = 160.0
const DIVINE_RAIDER_SIDE_SHOT_DAMAGE: int = 8
const DIVINE_WING_RAIDER_DAMAGE: int = 6
const DIVINE_WING_RAIDER_BODY_SIZE: Vector2 = Vector2(100, 64)
const DIVINE_ORACLE_DISTANCE_MULT: float = 0.7
const DIVINE_ORACLE_PHANTOM_MIN_INTERVAL: float = 0.5
const DIVINE_ORACLE_PHANTOM_MAX_INTERVAL: float = 1.0
const DIVINE_ORACLE_PHANTOM_WARNING_DURATION: float = WARNING_DURATION
const DIVINE_ORACLE_PHANTOM_FADE_DURATION: float = 0.35
const DIVINE_ORACLE_PHANTOM_CHARGE_OVERSHOOT: float = 260.0
const DIVINE_ORACLE_PHANTOM_MIN_CHARGE_DISTANCE: float = 520.0
const DIVINE_ORACLE_PHANTOM_MIN_CHARGE_DURATION: float = 0.45
const DIVINE_ORACLE_PHANTOM_MAX_ACTIVE: int = 2
const DIVINE_ORACLE_PHANTOM_MAX_SIDE_SHOT_PAIRS_PER_FRAME: int = 2
const DIVINE_ORACLE_PHANTOM_MAX_SIDE_SHOT_CATCHUP_DISTANCE: float = 220.0
const DIVINE_TELEPORT_SHADER_CODE := "shader_type canvas_item;\nuniform float fade_alpha = 1.0;\nuniform float white_amount = 1.0;\nvoid fragment() {\n\tvec4 color = texture(TEXTURE, UV);\n\tcolor.rgb = mix(color.rgb, vec3(1.0), white_amount);\n\tcolor.a *= fade_alpha;\n\tCOLOR = color * COLOR;\n}"


func _ready() -> void:
	_apply_behavior_defaults()
	if _explore_pool_enabled and not _explore_pool_active:
		max_hp = hp
		_apply_collision_shape_size()
		_ready_explore_pool_item()
		return
	_ensure_behavior_visuals(true)
	if _explore_patrol_enabled:
		_ready_explore_patrol_enemy()
		return
	if _explore_room_idle_enabled:
		_ready_explore_room_idle_enemy()
		return
	super()
	_obstacle_radius = maxf(body_size.x, body_size.y) * 0.55
	_last_safe_position = global_position
	_idle_origin = global_position
	_idle_origin_set = true
	area_entered.connect(_on_area_entered)
	_enter_idle_ai(true)
	_update_placeholder_rotation()


func _ready_explore_pool_item() -> void:
	screen_size = get_viewport().get_visible_rect().size
	lifetime = 999999.0
	lifetime_remaining = 999999.0
	player = get_tree().get_first_node_in_group(&"player")
	var HealthBarScript = preload("res://scripts/ui/HealthBar.gd")
	health_bar = Node2D.new()
	health_bar.set_script(HealthBarScript)
	health_bar.position = Vector2(0, -40)
	add_child(health_bar)
	health_bar.setup(hp)
	health_bar.visible = false
	max_hp = hp
	_obstacle_radius = maxf(body_size.x, body_size.y) * 0.55
	_last_safe_position = global_position
	_idle_origin = global_position
	_idle_origin_set = true
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	remove_from_group(&"enemies")
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	monitoring = false
	monitorable = false
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node:
		shape_node.disabled = true


func _ready_explore_patrol_enemy() -> void:
	screen_size = _explore_patrol_room_bounds.size if _explore_patrol_room_bounds.size != Vector2.ZERO else get_viewport().get_visible_rect().size
	lifetime = 999999.0
	lifetime_remaining = 999999.0
	add_to_group(&"enemies")
	player = get_tree().get_first_node_in_group(&"player")
	var HealthBarScript = preload("res://scripts/ui/HealthBar.gd")
	health_bar = Node2D.new()
	health_bar.set_script(HealthBarScript)
	health_bar.position = Vector2(0, -40)
	add_child(health_bar)
	health_bar.setup(hp)
	max_hp = hp
	_obstacle_radius = maxf(body_size.x, body_size.y) * 0.55
	_last_safe_position = global_position
	_idle_origin = global_position
	_idle_origin_set = true
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	_enter_idle_ai(true)
	_update_placeholder_rotation()


func _ready_explore_room_idle_enemy() -> void:
	screen_size = _explore_room_bounds.size if _explore_room_bounds.size != Vector2.ZERO else get_viewport().get_visible_rect().size
	lifetime = 999999.0
	lifetime_remaining = 999999.0
	add_to_group(&"enemies")
	player = get_tree().get_first_node_in_group(&"player")
	var HealthBarScript = preload("res://scripts/ui/HealthBar.gd")
	health_bar = Node2D.new()
	health_bar.set_script(HealthBarScript)
	health_bar.position = Vector2(0, -40)
	add_child(health_bar)
	health_bar.setup(hp)
	max_hp = hp
	_obstacle_radius = maxf(body_size.x, body_size.y) * 0.55
	_last_safe_position = global_position
	_idle_origin = global_position
	_idle_origin_set = true
	source_position = global_position
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	_enter_idle_ai(true)
	_update_placeholder_rotation()


func _draw() -> void:
	if _uses_default_warning_draw():
		super()
	_draw_custom_warning_box()
	_draw_core_devourer_claw_warning()
	_draw_calibrator_aim_ray()
	_draw_warped_lightning()
	_draw_hell_eye_black_link()
	_draw_horizon_phantom_warnings()
	_draw_divine_oracle_phantom_warnings()
	if not _uses_shield_bee_style_shield() or _shield_bee_shield_time <= 0.0:
		return
	var t := clampf(_shield_bee_shield_time / SHIELD_BEE_SHIELD_DURATION, 0.0, 1.0)
	var alpha := SHIELD_BEE_SHIELD_ALPHA * t
	var radius := maxf(body_size.x, body_size.y) * 0.72
	var fill := Color(accent_color.r, accent_color.g, accent_color.b, alpha * 0.28)
	var edge := Color(0.85, 0.95, 1.0, alpha)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, edge, 4.0, true)


func _draw_custom_warning_box() -> void:
	if _uses_default_warning_draw():
		return
	if state != State.WARNING:
		return
	if not sprite or not sprite.texture:
		return
	var flash = fmod(Time.get_ticks_msec() / 1000.0, 0.6)
	var is_red = flash < 0.3
	var base_alpha: float = 0.3
	var c = Color(1, 0.05, 0.05) if is_red else Color(1, 0.8, 0.05)
	var from = global_position
	var to = path_target
	var dir = (to - from).normalized()
	if dir.length() <= 0.01:
		return
	var perp = Vector2(-dir.y, dir.x)
	var full_half_w = sprite.texture.get_width() * sprite.scale.x * 0.5
	var warning_duration := _get_warning_duration()
	var wm = warning_duration - warning_timer
	var half_w = full_half_w
	var alpha_mod = 1.0
	if wm < 0.5:
		half_w = full_half_w * clampf(wm / 0.5, 0.0, 1.0)
	elif warning_timer < 0.5:
		var t = 1.0 - clampf(warning_timer / 0.5, 0.0, 1.0)
		half_w = full_half_w * (1.0 + t)
		alpha_mod = 1.0 - t
	const SEGS = 60
	var length = from.distance_to(to)
	for i in SEGS:
		var t0 = float(i) / SEGS
		var t1 = float(i + 1) / SEGS
		var alpha = _gradient_alpha(t0) * 0.5 + _gradient_alpha(t1) * 0.5
		var p_a = from + dir * t0 * length
		var p_b = from + dir * t1 * length
		var pts = PackedVector2Array([
			to_local(p_a + perp * half_w),
			to_local(p_a - perp * half_w),
			to_local(p_b - perp * half_w),
			to_local(p_b + perp * half_w),
		])
		draw_colored_polygon(pts, Color(c.r, c.g, c.b, base_alpha * alpha * alpha_mod))


func setup_explore_patrol(points: PackedVector2Array, path_offset: Vector2, room_bounds: Rect2, despawn_margin: float, spawn_position: Vector2 = Vector2.INF) -> void:
	_explore_patrol_enabled = true
	_explore_room_idle_enabled = false
	_explore_patrol_points = points.duplicate()
	_explore_patrol_offset = path_offset
	_explore_patrol_room_bounds = room_bounds
	_explore_patrol_despawn_margin = despawn_margin
	screen_size = room_bounds.size
	_explore_patrol_index = 1
	_explore_alert_probe_timer = randf_range(0.0, EXPLORE_ALERT_PROBE_INTERVAL + EXPLORE_ALERT_PROBE_JITTER)
	_explore_pursuit_probe_timer = randf_range(0.0, EXPLORE_PURSUIT_PROBE_INTERVAL + EXPLORE_ALERT_PROBE_JITTER)
	_detection_los_timer = randf_range(0.0, DETECTION_LOS_CHECK_INTERVAL)
	_fast_los_timer = randf_range(0.0, FAST_LOS_CHECK_INTERVAL)
	_pursuit_path_check_timer = randf_range(0.0, PURSUIT_PATH_CHECK_INTERVAL)
	_positioning_visibility_timer = randf_range(0.0, POSITIONING_VISIBILITY_CHECK_INTERVAL)
	lifetime = 999999.0
	lifetime_remaining = 999999.0
	if _explore_patrol_points.size() > 1:
		global_position = spawn_position if spawn_position != Vector2.INF else _explore_patrol_points[0] + _explore_patrol_offset
		_idle_origin = global_position
		_idle_origin_set = true
		source_position = global_position
	if is_node_ready():
		_enter_idle_ai(true)


func setup_explore_room_idle(room_bounds: Rect2) -> void:
	_explore_room_idle_enabled = true
	_explore_patrol_enabled = false
	_explore_room_bounds = room_bounds
	screen_size = room_bounds.size
	lifetime = 999999.0
	lifetime_remaining = 999999.0
	_detection_los_timer = randf_range(0.0, DETECTION_LOS_CHECK_INTERVAL)
	_fast_los_timer = randf_range(0.0, FAST_LOS_CHECK_INTERVAL)
	_pursuit_path_check_timer = randf_range(0.0, PURSUIT_PATH_CHECK_INTERVAL)
	_positioning_visibility_timer = randf_range(0.0, POSITIONING_VISIBILITY_CHECK_INTERVAL)
	_idle_origin = global_position
	_idle_origin_set = true
	source_position = global_position
	if is_node_ready():
		_enter_idle_ai(true)


func setup_explore_pool(owner: Node, pool_key: int) -> void:
	_explore_pool_enabled = true
	_explore_pool_owner = owner
	_explore_pool_key = pool_key
	_explore_pool_active = false
	set_meta(&"explore_pooled_enemy", true)


func reset_explore_pooled_patrol_enemy(new_behavior: int, points: PackedVector2Array, path_offset: Vector2, room_bounds: Rect2, despawn_margin: float, spawn_position: Vector2) -> void:
	var behavior_changed := int(behavior) != int(new_behavior)
	behavior = new_behavior
	_explore_pool_active = true
	_explore_pool_enabled = true
	if not is_in_group(&"enemies"):
		add_to_group(&"enemies")
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_process(true)
	set_physics_process(true)
	monitoring = true
	monitorable = true
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node:
		shape_node.disabled = false
	_clear_runtime_visual_effects_for_pool()
	_reset_common_runtime_state_for_pool()
	_apply_behavior_defaults()
	max_hp = hp
	_ensure_behavior_visuals(behavior_changed or _visual_behavior != int(behavior))
	if health_bar:
		health_bar.setup(hp)
		health_bar.visible = false
	setup_explore_patrol(points, path_offset, room_bounds, despawn_margin, spawn_position)
	if is_node_ready():
		_enter_idle_ai(true)


func reset_explore_pooled_idle_enemy(new_behavior: int, room_bounds: Rect2, spawn_position: Vector2) -> void:
	var behavior_changed := int(behavior) != int(new_behavior)
	behavior = new_behavior
	_explore_pool_active = true
	_explore_pool_enabled = true
	if not is_in_group(&"enemies"):
		add_to_group(&"enemies")
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_process(true)
	set_physics_process(true)
	monitoring = true
	monitorable = true
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node:
		shape_node.disabled = false
	_clear_runtime_visual_effects_for_pool()
	_reset_common_runtime_state_for_pool()
	_apply_behavior_defaults()
	max_hp = hp
	_ensure_behavior_visuals(behavior_changed or _visual_behavior != int(behavior))
	global_position = spawn_position
	if health_bar:
		health_bar.setup(hp)
		health_bar.visible = true
	setup_explore_room_idle(room_bounds)
	if is_node_ready():
		_enter_idle_ai(true)


func release_explore_pool_item() -> void:
	_release_explore_pooled_enemy()


func _reset_common_runtime_state_for_pool() -> void:
	hp = 1
	max_hp = 1
	damage = 1
	move_speed = 300.0
	move_cooldown = 10.0
	explosion_scale = 0.5
	lifetime = 999999.0
	lifetime_remaining = 999999.0
	_attack_timer = 0.0
	_special_timer = 0.0
	_burst_left = 0
	_burst_gap = 0.0
	_shield_energy = 0
	_last_safe_position = global_position
	_blocking_obstacles_cache.clear()
	_blocking_obstacles_cache_time = -9999.0
	_obstacle_bounce_velocity = Vector2.ZERO
	_obstacle_bounce_time = 0.0
	_shard_retreat_start = Vector2.ZERO
	_shard_retreat_target = Vector2.ZERO
	_shard_retreat_elapsed = 0.0
	_shard_retreat_duration = 0.35
	_shard_charge_target = Vector2.ZERO
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	_gravity_claw_charge_target = Vector2.ZERO
	_gravity_claw_is_retreating = false
	_gravity_claw_is_fast_charging = false
	_gravity_claw_retreat_start = Vector2.ZERO
	_gravity_claw_retreat_target = Vector2.ZERO
	_gravity_claw_retreat_elapsed = 0.0
	_gravity_claw_grappled_player = null
	_gravity_claw_grapple_offset = Vector2.ZERO
	_gravity_claw_grapple_inertia_velocity = Vector2.ZERO
	_gravity_claw_recovery_timer = 0.0
	_gravity_claw_knock_velocity = Vector2.ZERO
	_gravity_claw_impact_damage = 0
	_gravity_claw_dot_damage_per_second = 0.0
	_gravity_claw_core_launch_active = false
	_gravity_claw_core_summoned = false
	_gravity_claw_core_owner = null
	_gravity_claw_core_decay_accumulator = 0.0
	_is_pursuing_player = false
	_pursuit_target = Vector2.ZERO
	_pursuit_repath_timer = 0.0
	_clear_line_stability = 0.0
	_ai_alert = false
	_pursuit_elapsed = 0.0
	_idle_origin = global_position
	_idle_origin_set = true
	_idle_patrol_target = Vector2.ZERO
	_idle_patrol_pause = 0.0
	_alert_notice_active = false
	_shield_bee_shield_time = 0.0
	_shield_bee_target = Vector2.ZERO
	_shield_bee_repath_timer = 0.0
	_shield_bee_path.clear()
	_shield_bee_path_index = 0
	_shield_bee_path_avoid_player = false
	_shield_bee_last_progress_position = global_position
	_shield_bee_stuck_timer = 0.0
	_shield_bee_repath_failures = 0
	_core_devourer_claw_timer = 0.0
	_core_devourer_counter_claw_timer = 0.0
	_core_devourer_claw_warnings.clear()
	_core_devourer_pool_prewarm_requested = false
	_core_devourer_pool_prewarm_timer = 0.0
	_calibrator_shot_timer = 0.0
	_calibrator_warning_timer = 0.0
	_calibrator_locked_dir = Vector2.ZERO
	_calibrator_recoil_velocity = Vector2.ZERO
	_calibrator_dodge_side = 1.0
	_calibrator_ray_timer = 0.0
	_calibrator_ray_points = PackedVector2Array()
	_sanctum_spin_speed = 0.0
	_sanctum_spin_active = false
	_sanctum_spin_fire_timer = 0.0
	_warped_spin_speed = 0.0
	_warped_lightning_phase = 0.0
	_hell_eye_black_line_phase = 0.0
	_hell_eye_blind_latched = false
	_divine_raider_side_shot_distance = 0.0
	_divine_raider_side_shot_next = 0.0
	_divine_teleport_phase = 0
	_divine_teleport_mode = 0
	_divine_teleport_timer = 0.0
	_divine_teleport_target = Vector2.ZERO
	_divine_teleport_warning_remaining = -1.0
	_divine_sprite_original_material = null
	_divine_sprite_original_modulate = Color.WHITE
	_divine_oracle_spawn_timer = 0.0
	_divine_oracle_frame_side_shots = 0
	_explore_pool_releasing = false
	_explore_patrol_enabled = false
	_explore_patrol_points = PackedVector2Array()
	_explore_patrol_offset = Vector2.ZERO
	_explore_patrol_index = 1
	_explore_patrol_room_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)
	_explore_patrol_despawn_margin = 900.0
	_explore_room_idle_enabled = false
	_explore_room_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)
	_explore_alert_probe_timer = 0.0
	_explore_pursuit_probe_timer = 0.0
	_explore_render_active = true
	_explore_combat_target = Vector2.ZERO
	_explore_combat_target_timer = 0.0
	_detection_los_timer = 0.0
	_detection_los_blocked = false
	_fast_los_timer = 0.0
	_fast_los_clear = true
	_pursuit_path_check_timer = 0.0
	_pursuit_target_blocked = false
	_positioning_visibility_timer = 0.0
	knockback_velocity = Vector2.ZERO
	knockback_duration = 0.0
	is_shaking = false
	shake_elapsed = 0.0
	state = State.COOLDOWN
	cooldown_remaining = 0.0
	warning_timer = 0.0
	path_target = global_position
	source_position = global_position
	move_elapsed = 0.0
	move_duration = 0.0
	player = get_tree().get_first_node_in_group(&"player") if get_tree() else null


func _clear_runtime_visual_effects_for_pool() -> void:
	if is_instance_valid(_alert_notice_node):
		_alert_notice_node.queue_free()
	if is_instance_valid(_alert_arrow_node):
		_alert_arrow_node.queue_free()
	_alert_notice_node = null
	_alert_arrow_node = null
	_cancel_divine_teleport()
	_release_hell_eye_player_effects()
	_clear_hell_eye_visuals()
	_clear_divine_oracle_phantoms()
	_clear_gravity_claw_core_payload()


func _release_explore_pooled_enemy() -> void:
	if not _explore_pool_enabled or not _explore_pool_active:
		return
	_explore_pool_generation += 1
	_clear_runtime_visual_effects_for_pool()
	if behavior == Behavior.WARPED_MICRO_CORE or behavior == Behavior.WARPED_COLLAPSE_BEACON:
		GameManager.suction_active = false
		GameManager.suction_center = Vector2.ZERO
	if behavior == Behavior.HELLEYE_INVERTED_MOTH or behavior == Behavior.HELLEYE_INVERT_PRIEST:
		GameManager.controls_inverted = false
	if behavior == Behavior.COLOSSUS_CORE_DEVOURER and not _has_other_active_core_devourer():
		_clear_core_devourer_gravity_claw_pool()
	_explore_pool_active = false
	_ai_alert = false
	_is_pursuing_player = false
	_explore_patrol_enabled = false
	_explore_room_idle_enabled = false
	remove_from_group(&"enemies")
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	monitoring = false
	monitorable = false
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node:
		shape_node.disabled = true
	if health_bar:
		health_bar.visible = false
	if is_instance_valid(_explore_pool_owner) and _explore_pool_owner.has_method("release_pooled_patrol_enemy"):
		_explore_pool_releasing = true
		_explore_pool_owner.call("release_pooled_patrol_enemy", self, _explore_pool_key)
		_explore_pool_releasing = false
	else:
		queue_free()


func _process(delta: float) -> void:
	_try_apply_pending_behavior_texture()
	if _explore_patrol_enabled:
		lifetime_remaining = 999999.0
		if not _explore_render_active:
			_update_explore_patrol(delta)
			if _is_outside_explore_despawn_bounds():
				_despawn_explore_patrol_enemy()
			return
	super(delta)
	if _explore_patrol_enabled and _is_outside_explore_despawn_bounds():
		_despawn_explore_patrol_enemy()


func _despawn_explore_patrol_enemy() -> void:
	if _explore_pool_enabled and _explore_pool_active:
		_release_explore_pooled_enemy()
	else:
		queue_free()


func set_explore_render_active(active: bool) -> void:
	if _explore_render_active == active:
		return
	_explore_render_active = active
	visible = active
	if _explore_room_idle_enabled and not _explore_patrol_enabled:
		set_process(active)
		return
	if active and _explore_patrol_enabled:
		var pushed := _push_out_from_obstacles(global_position)
		if pushed.distance_to(global_position) > 0.5:
			global_position = pushed
			source_position = global_position
			_enter_explore_patrol_from_nearest_point()
	if not active and _explore_patrol_enabled:
		if _ai_alert or _is_pursuing_player or _alert_notice_active:
			_enter_idle_ai(true)
			_enter_explore_patrol_from_nearest_point()
		if is_instance_valid(_alert_notice_node):
			_alert_notice_node.queue_free()
		if is_instance_valid(_alert_arrow_node):
			_alert_arrow_node.queue_free()


func _draw_core_devourer_claw_warning() -> void:
	if behavior != Behavior.COLOSSUS_CORE_DEVOURER or _core_devourer_claw_warnings.is_empty():
		return
	for warning in _core_devourer_claw_warnings:
		var remaining := float(warning.get("time", 0.0))
		if remaining <= 0.0:
			continue
		var dir := warning.get("direction", Vector2.DOWN) as Vector2
		dir = dir.normalized()
		if dir.length() <= 0.01:
			dir = Vector2.DOWN
		var from := global_position
		var to := _clamped_point(from + dir * CORE_DEVOURER_CLAW_WARNING_LENGTH)
		var perp := Vector2(-dir.y, dir.x)
		var elapsed := CORE_DEVOURER_CLAW_WARNING_DURATION - remaining
		var grow_t := clampf(elapsed / 0.18, 0.0, 1.0)
		var fade_t := clampf(remaining / 0.25, 0.0, 1.0)
		var half_w := maxf(body_size.x * 0.38, 32.0) * smoothstep(0.0, 1.0, grow_t)
		var alpha_mod := minf(1.0, fade_t)
		var flash := fmod(Time.get_ticks_msec() / 1000.0, 0.28)
		var c := Color(1.0, 0.05, 0.04, 0.34 * alpha_mod) if flash < 0.14 else Color(1.0, 0.74, 0.1, 0.28 * alpha_mod)
		var segments := 32
		var length := from.distance_to(to)
		for i in range(segments):
			var t0 := float(i) / float(segments)
			var t1 := float(i + 1) / float(segments)
			var a0 := _gradient_alpha(t0)
			var a1 := _gradient_alpha(t1)
			var p_a := from + dir * length * t0
			var p_b := from + dir * length * t1
			var pts := PackedVector2Array([
				to_local(p_a + perp * half_w),
				to_local(p_a - perp * half_w),
				to_local(p_b - perp * half_w),
				to_local(p_b + perp * half_w),
			])
			draw_colored_polygon(pts, Color(c.r, c.g, c.b, c.a * (a0 + a1) * 0.5))


func _draw_horizon_phantom_warnings() -> void:
	if behavior != Behavior.HELLEYE_HORIZON_DEFLECTOR or state != State.WARNING:
		return
	if _hell_eye_horizon_phantom_data.is_empty():
		return
	var flash := fmod(Time.get_ticks_msec() / 1000.0, 0.6)
	var is_red := flash < 0.3
	var base_alpha := 0.3
	var c := Color(1, 0.05, 0.05) if is_red else Color(1, 0.8, 0.05)
	var warning_duration := _get_warning_duration()
	var elapsed := warning_duration - warning_timer
	var half_w := body_size.x * 0.5
	var alpha_mod := 1.0
	if elapsed < 0.5:
		half_w *= elapsed / 0.5
	elif warning_timer < 0.5:
		var fade_t := 1.0 - warning_timer / 0.5
		half_w *= 1.0 + fade_t
		alpha_mod = 1.0 - fade_t
	const SEGS := 60
	for data in _hell_eye_horizon_phantom_data:
		var from := data.get("warning_from", Vector2.ZERO) as Vector2
		var to := data.get("warning_to", from) as Vector2
		var delta := to - from
		var length := delta.length()
		if length <= 1.0:
			continue
		var dir := delta / length
		var perp := Vector2(-dir.y, dir.x)
		for i in range(SEGS):
			var t0 := float(i) / float(SEGS)
			var t1 := float(i + 1) / float(SEGS)
			var alpha := _gradient_alpha(t0) * 0.5 + _gradient_alpha(t1) * 0.5
			var p_a := from + dir * t0 * length
			var p_b := from + dir * t1 * length
			var pts := PackedVector2Array([
				to_local(p_a + perp * half_w),
				to_local(p_a - perp * half_w),
				to_local(p_b - perp * half_w),
				to_local(p_b + perp * half_w),
			])
			draw_colored_polygon(pts, Color(c.r, c.g, c.b, base_alpha * alpha * alpha_mod))


func _draw_divine_oracle_phantom_warnings() -> void:
	if behavior != Behavior.DIVINE_ORACLE_PHANTOM:
		return
	if _divine_oracle_phantom_data.is_empty():
		return
	var flash := fmod(Time.get_ticks_msec() / 1000.0, 0.6)
	var is_red := flash < 0.3
	var c := Color(1, 0.05, 0.05) if is_red else Color(1, 0.8, 0.05)
	var base_alpha := 0.3
	const SEGS := 60
	for data in _divine_oracle_phantom_data:
		if String(data.get("phase", "")) != "warning":
			continue
		var remaining := float(data.get("timer", 0.0))
		var elapsed := DIVINE_ORACLE_PHANTOM_WARNING_DURATION - remaining
		var half_w := DIVINE_WING_RAIDER_BODY_SIZE.x * 0.5
		var alpha_mod := 1.0
		if elapsed < 0.5:
			half_w *= clampf(elapsed / 0.5, 0.0, 1.0)
		elif remaining < 0.5:
			var fade_t := 1.0 - clampf(remaining / 0.5, 0.0, 1.0)
			half_w *= 1.0 + fade_t
			alpha_mod = 1.0 - fade_t
		var from := data.get("warning_from", Vector2.ZERO) as Vector2
		var to := data.get("warning_to", from) as Vector2
		var delta := to - from
		var length := delta.length()
		if length <= 1.0:
			continue
		var dir := delta / length
		var perp := Vector2(-dir.y, dir.x)
		for i in range(SEGS):
			var t0 := float(i) / float(SEGS)
			var t1 := float(i + 1) / float(SEGS)
			var alpha := _gradient_alpha(t0) * 0.5 + _gradient_alpha(t1) * 0.5
			var p_a := from + dir * t0 * length
			var p_b := from + dir * t1 * length
			var pts := PackedVector2Array([
				to_local(p_a + perp * half_w),
				to_local(p_a - perp * half_w),
				to_local(p_b - perp * half_w),
				to_local(p_b + perp * half_w),
			])
			draw_colored_polygon(pts, Color(c.r, c.g, c.b, base_alpha * alpha * alpha_mod))


func _draw_calibrator_aim_ray() -> void:
	if behavior != Behavior.PARADISE_CALIBRATOR or not _ai_alert or not player:
		return
	if _calibrator_ray_points.size() < 2:
		return
	var start := _calibrator_ray_points[0]
	var end := _calibrator_ray_points[1]
	var dir := end - start
	if dir.length() <= 1.0:
		return
	var flashing := _calibrator_warning_timer > 0.0
	var flash := fmod(Time.get_ticks_msec() / 1000.0, 0.16)
	var color := Color(1.0, 0.04, 0.02, 0.55)
	if flashing and flash < 0.08:
		color = Color(1.0, 0.9, 0.04, 0.74)
	elif flashing:
		color = Color(1.0, 0.04, 0.02, 0.74)
	draw_line(to_local(start), to_local(end), color, 4.0 if not flashing else 7.0, true)


func _draw_warped_lightning() -> void:
	if not _uses_warped_lightning() or not _is_warped_lightning_active():
		return
	var start := Vector2.ZERO
	var end := to_local(player.global_position)
	var delta := end - start
	var length := delta.length()
	if length <= 1.0:
		return
	var dir := delta / length
	var perp := dir.orthogonal()
	var points := PackedVector2Array()
	var segments := 14
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var base := start.lerp(end, t)
		var falloff := clampf(1.0 - absf(t - 0.5) * 1.6, 0.2, 1.0)
		var jitter := sin(_warped_lightning_phase * 18.0 + float(i) * 1.83) * length * 0.045
		jitter += cos(_warped_lightning_phase * 11.0 + float(i) * 2.37) * length * 0.025
		points.append(base + perp * jitter * falloff)
	draw_polyline(points, Color(0.55, 0.12, 1.0, 0.22), 12.0, true)
	draw_polyline(points, Color(0.72, 0.26, 1.0, 0.55), 5.0, true)
	draw_polyline(points, Color(1.0, 0.86, 1.0, 0.88), 1.8, true)


func _draw_hell_eye_black_link() -> void:
	if not _is_hell_eye_black_link_active():
		return
	var start := Vector2.ZERO
	var end := to_local(player.global_position)
	var delta := end - start
	var length := delta.length()
	if length <= 1.0:
		return
	var dir := delta / length
	var perp := dir.orthogonal()
	var points := PackedVector2Array()
	var segments := 14
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var base := start.lerp(end, t)
		var falloff := clampf(1.0 - absf(t - 0.5) * 1.65, 0.18, 1.0)
		var jitter := sin(_hell_eye_black_line_phase * 17.0 + float(i) * 2.11) * length * 0.025
		jitter += cos(_hell_eye_black_line_phase * 9.0 + float(i) * 1.53) * length * 0.018
		points.append(base + perp * jitter * falloff)
	draw_polyline(points, Color(0.0, 0.0, 0.0, 0.24), 14.0, true)
	draw_polyline(points, Color(0.0, 0.0, 0.0, 0.68), 6.0, true)
	draw_polyline(points, Color(0.36, 0.36, 0.40, 0.72), 1.7, true)


func _exit_tree() -> void:
	if _explore_pool_releasing:
		return
	# 钩爪池是全类共享的 static，只在最后一只核心吞噬者退场时清理，
	# 否则一只死亡会摧毁其他吞噬者预热好的池
	if behavior == Behavior.COLOSSUS_CORE_DEVOURER and not _has_other_active_core_devourer():
		_clear_core_devourer_gravity_claw_pool()
	if _gravity_claw_core_summoned:
		_release_gravity_claw_grapple_if_needed()
	if is_instance_valid(_alert_notice_node):
		_alert_notice_node.queue_free()
	if is_instance_valid(_alert_arrow_node):
		_alert_arrow_node.queue_free()
	_cancel_divine_teleport()
	_release_hell_eye_player_effects()
	_clear_hell_eye_visuals()
	_clear_divine_oracle_phantoms()
	if behavior == Behavior.WARPED_MICRO_CORE or behavior == Behavior.WARPED_COLLAPSE_BEACON:
		GameManager.suction_active = false
		GameManager.suction_center = Vector2.ZERO
	if behavior == Behavior.HELLEYE_INVERTED_MOTH or behavior == Behavior.HELLEYE_INVERT_PRIEST:
		GameManager.controls_inverted = false


func _die() -> void:
	if _gravity_claw_core_summoned and get_meta(&"core_devourer_pool_item", false):
		GameManager.add_score(100)
		_deactivate_core_devourer_gravity_claw()
		return
	# 奖励箱替换精英与巡逻精英使用不同的生成方式，但都会经过这里。
	RunManager.record_route_directive_elite_kill(int(behavior))
	if _explore_pool_enabled and _explore_pool_active:
		GameManager.add_score(100)
		GameManager.on_enemy_killed()
		_play_sfx(EXPLOSION_SFX)
		_spawn_explosion()
		_spawn_debris()
		_release_explore_pooled_enemy()
		return
	super()


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
		sprite_proxy.visible = true
		sprite_proxy.scale = Vector2(body_size.x / texture.get_width(), body_size.y / texture.get_height())
		sprite_proxy.modulate = Color.WHITE
		_visual_waiting_for_texture = false
	else:
		sprite_proxy.texture = null
		sprite_proxy.visible = false
		sprite_proxy.modulate = Color.WHITE
		_visual_waiting_for_texture = true
	sprite_proxy.centered = true
	sprite_proxy.rotation = DESIGNED_ENEMY_SPRITE_ROTATION_OFFSET
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


func _ensure_behavior_visuals(force: bool = false) -> void:
	if not force and _visual_behavior == int(behavior):
		_apply_collision_shape_size()
		return
	_clear_placeholder_visual_parts()
	_build_placeholder_visuals()
	_visual_behavior = int(behavior)


func _clear_placeholder_visual_parts() -> void:
	for part in _visual_parts:
		if is_instance_valid(part):
			if part.get_parent() == self:
				remove_child(part)
			part.queue_free()
	_visual_parts.clear()
	_visual_waiting_for_texture = false
	var stray_body := get_node_or_null("PlaceholderBody") as ColorRect
	if is_instance_valid(stray_body):
		if stray_body.get_parent() == self:
			remove_child(stray_body)
		stray_body.queue_free()


func _apply_collision_shape_size() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is RectangleShape2D:
		shape_node.shape.size = body_size


func reset_core_devourer_gravity_claw_from_pool() -> void:
	behavior = Behavior.COLOSSUS_GRAVITY_CLAW
	enemy_title = "引力钩爪"
	body_size = Vector2(76, 96)
	body_color = Color(0.4, 0.36, 0.45, 1)
	accent_color = Color(0.95, 0.28, 0.2, 1)
	hp = 32
	max_hp = hp
	damage = 10
	move_speed = 330
	move_cooldown = 3.0
	lifetime = 120.0
	lifetime_remaining = lifetime
	explosion_scale = clampf(body_size.length() / 90.0, 0.45, 0.9)
	_ai_alert = true
	_is_pursuing_player = false
	_pursuit_elapsed = 0.0
	_pursuit_repath_timer = 0.0
	_clear_line_stability = 0.0
	_attack_timer = 999.0
	_special_timer = 999.0
	_burst_left = 0
	_burst_gap = 0.0
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	_gravity_claw_charge_target = Vector2.ZERO
	_gravity_claw_is_retreating = false
	_gravity_claw_is_fast_charging = false
	_gravity_claw_retreat_start = Vector2.ZERO
	_gravity_claw_retreat_target = Vector2.ZERO
	_gravity_claw_retreat_elapsed = 0.0
	_gravity_claw_grappled_player = null
	_gravity_claw_grapple_offset = Vector2.ZERO
	_gravity_claw_grapple_inertia_velocity = Vector2.ZERO
	_gravity_claw_recovery_timer = 0.0
	_gravity_claw_knock_velocity = Vector2.ZERO
	_gravity_claw_impact_damage = 0
	_gravity_claw_dot_damage_per_second = 0.0
	_gravity_claw_core_launch_active = false
	_gravity_claw_core_summoned = false
	_gravity_claw_core_owner = null
	_gravity_claw_core_decay_accumulator = 0.0
	_obstacle_bounce_velocity = Vector2.ZERO
	_obstacle_bounce_time = 0.0
	knockback_velocity = Vector2.ZERO
	knockback_duration = 0.0
	is_shaking = false
	shake_elapsed = 0.0
	state = State.COOLDOWN
	cooldown_remaining = 0.0
	move_elapsed = 0.0
	move_duration = 0.0
	source_position = global_position
	path_target = global_position
	player = get_tree().get_first_node_in_group(&"player") if get_tree() else null
	_obstacle_radius = maxf(body_size.x, body_size.y) * 0.55
	_last_safe_position = global_position
	_ensure_behavior_visuals(true)
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node:
		shape_node.disabled = false
	monitoring = true
	monitorable = true
	if health_bar:
		health_bar.setup(hp)
		health_bar.visible = false


func _add_part(center: Vector2, size: Vector2, color: Color) -> void:
	var part := ColorRect.new()
	part.color = color
	part.size = size
	part.position = center - size * 0.5
	add_child(part)
	_visual_parts.append(part)


func _load_behavior_texture() -> Texture2D:
	if DisplayServer.get_name() == "headless":
		return null
	var index := int(behavior)
	if _explore_pool_enabled or _explore_patrol_enabled or _explore_room_idle_enabled:
		return poll_behavior_texture(index)
	return get_behavior_texture(index)


func _try_apply_pending_behavior_texture() -> void:
	if not _visual_waiting_for_texture:
		return
	if DisplayServer.get_name() == "headless":
		return
	var texture := poll_behavior_texture(int(behavior))
	if not texture:
		return
	var sprite_proxy := get_node_or_null("Sprite2D") as Sprite2D
	if not sprite_proxy:
		return
	sprite_proxy.texture = texture
	sprite_proxy.visible = true
	sprite_proxy.scale = Vector2(body_size.x / texture.get_width(), body_size.y / texture.get_height())
	sprite_proxy.modulate = Color.WHITE
	_clear_placeholder_visual_parts()
	_visual_waiting_for_texture = false


static func get_behavior_texture(index: int) -> Texture2D:
	if index < 0 or index >= ENEMY_TEXTURE_PATHS.size():
		return null
	if _behavior_texture_cache.has(index):
		return _behavior_texture_cache[index] as Texture2D
	var texture = load(ENEMY_TEXTURE_PATHS[index])
	if texture is Texture2D:
		_behavior_texture_cache[index] = texture
		_behavior_texture_thread_requests.erase(index)
	return texture as Texture2D


static func request_behavior_texture(index: int) -> void:
	if index < 0 or index >= ENEMY_TEXTURE_PATHS.size():
		return
	if _behavior_texture_cache.has(index) or _behavior_texture_thread_requests.has(index):
		return
	var path := ENEMY_TEXTURE_PATHS[index]
	var err := ResourceLoader.load_threaded_request(path, "Texture2D")
	if err == OK:
		_behavior_texture_thread_requests[index] = path
	else:
		var texture = load(path)
		if texture is Texture2D:
			_behavior_texture_cache[index] = texture


static func poll_behavior_texture(index: int) -> Texture2D:
	if index < 0 or index >= ENEMY_TEXTURE_PATHS.size():
		return null
	if _behavior_texture_cache.has(index):
		return _behavior_texture_cache[index] as Texture2D
	if not _behavior_texture_thread_requests.has(index):
		request_behavior_texture(index)
		return null
	var path := String(_behavior_texture_thread_requests[index])
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var resource := ResourceLoader.load_threaded_get(path)
		_behavior_texture_thread_requests.erase(index)
		if resource is Texture2D:
			_behavior_texture_cache[index] = resource
			return resource as Texture2D
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_behavior_texture_thread_requests.erase(index)
	return null


static func preload_behavior_textures(behaviors: Array[int]) -> void:
	for behavior_index in behaviors:
		request_behavior_texture(behavior_index)


static func flush_pending_behavior_texture_requests() -> void:
	var pending_paths: Array[String] = []
	for key in _behavior_texture_thread_requests.keys():
		var path := String(_behavior_texture_thread_requests[key])
		if not pending_paths.has(path):
			pending_paths.append(path)
	for path in pending_paths:
		var status := ResourceLoader.load_threaded_get_status(path)
		while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			OS.delay_msec(1)
			status = ResourceLoader.load_threaded_get_status(path)
		if status != ResourceLoader.THREAD_LOAD_LOADED:
			continue
		var resource := ResourceLoader.load_threaded_get(path)
		if resource is Texture2D:
			var index := ENEMY_TEXTURE_PATHS.find(path)
			if index >= 0:
				_behavior_texture_cache[index] = resource
	_behavior_texture_thread_requests.clear()


static func release_static_runtime_resources() -> void:
	flush_pending_behavior_texture_requests()
	_behavior_texture_cache.clear()
	_designed_enemy_scene = null
	_horizon_phantom_material = null
	_divine_oracle_phantom_material = null
	for claw in _core_devourer_gravity_claw_pool:
		if is_instance_valid(claw):
			claw.queue_free()
	_core_devourer_gravity_claw_pool.clear()


static func _get_designed_enemy_scene() -> PackedScene:
	if _designed_enemy_scene == null:
		_designed_enemy_scene = load(DESIGNED_ENEMY_SCENE_PATH) as PackedScene
	return _designed_enemy_scene


func _get_effect_parent() -> Node:
	var owner := _explore_pool_owner
	if is_instance_valid(owner):
		var effect_root := owner.get_node_or_null("EnemyEffects")
		if effect_root:
			return effect_root
	if get_tree() and get_tree().current_scene:
		var scene_effect_root := get_tree().current_scene.get_node_or_null("EnemyEffects")
		if scene_effect_root:
			return scene_effect_root
		return get_tree().current_scene
	var parent := get_parent()
	if parent:
		var scene_parent := parent
		while scene_parent:
			var effect_root := scene_parent.get_node_or_null("EnemyEffects")
			if effect_root:
				return effect_root
			scene_parent = scene_parent.get_parent()
		return parent
	return self


func _apply_behavior_defaults() -> void:
	_apply_catalog_defaults()
	match behavior:
		Behavior.COLOSSUS_SHARD_ARM:
			hp = 30; damage = 12; move_speed = 520; move_cooldown = 2.5
		Behavior.COLOSSUS_SHIELD_BEE:
			hp = 42; damage = 8; move_speed = 250; move_cooldown = 3.0
		Behavior.COLOSSUS_GRAVITY_CLAW:
			hp = 32; damage = 10; move_speed = 330; move_cooldown = 3.0
		Behavior.COLOSSUS_GUARD:
			hp = 1150; damage = 14; move_speed = 520; move_cooldown = 2.5; body_size = Vector2(232, 208)
		Behavior.COLOSSUS_CORE_DEVOURER:
			hp = 1250; damage = 15; move_speed = 210; move_cooldown = 3.0; body_size = Vector2(224, 224)
		Behavior.PARADISE_PATROL:
			hp = 24; damage = 8; move_speed = 260; move_cooldown = 2.5
		Behavior.PARADISE_ARC_SCATTER:
			hp = 28; damage = 7; move_speed = 220; move_cooldown = 3.0
		Behavior.PARADISE_RAIL_CHAIN:
			hp = 34; damage = 6; move_speed = 260; move_cooldown = 2.8
		Behavior.PARADISE_CALIBRATOR:
			hp = 1050; damage = 10; move_speed = 520; move_cooldown = 3.2; body_size = Vector2(216, 184)
		Behavior.PARADISE_SANCTUM_SUPPRESSOR:
			hp = 1250; damage = 10; move_speed = 220; move_cooldown = 4.0; body_size = Vector2(224, 200)
		Behavior.WARPED_MICRO_CORE:
			hp = 34; damage = 12; move_speed = 200; move_cooldown = 3.0
		Behavior.WARPED_REFRACTION_SHOOTER:
			hp = 28; damage = 10; move_speed = 250; move_cooldown = 2.8
		Behavior.WARPED_ORBIT_DISRUPTOR:
			hp = 38; damage = 8; move_speed = 240; move_cooldown = 3.0
		Behavior.WARPED_COLLAPSE_BEACON:
			hp = 1200; damage = 14; move_speed = 190; move_cooldown = 4.5; body_size = Vector2(224, 224)
		Behavior.WARPED_DEFLECTION_MATRIX:
			hp = 1150; damage = 12; move_speed = 230; move_cooldown = 3.5; body_size = Vector2(216, 216)
		Behavior.HELLEYE_INVERTED_MOTH:
			hp = 24; damage = int(12.0 * HELLEYE_INVERTED_MOTH_DAMAGE_MULT); move_speed = 520; move_cooldown = 2.5
		Behavior.HELLEYE_BLIND_MOTH:
			hp = 24; damage = 10; move_speed = 360; move_cooldown = 2.0
		Behavior.HELLEYE_MISALIGNED_GAZER:
			hp = 30; damage = 9; move_speed = 230; move_cooldown = 2.8
		Behavior.HELLEYE_INVERT_PRIEST:
			hp = 1200; damage = 14; move_speed = 210; move_cooldown = 4.0; body_size = Vector2(216, 232)
		Behavior.HELLEYE_HORIZON_DEFLECTOR:
			hp = 1350; damage = int(12.0 * HELLEYE_HORIZON_DAMAGE_MULT); move_speed = 520; move_cooldown = 2.5; body_size = Vector2(224, 216)
		Behavior.DIVINE_WING_RAIDER:
			hp = 24; damage = DIVINE_WING_RAIDER_DAMAGE; move_speed = 620; move_cooldown = 2.0
		Behavior.DIVINE_BLINK_BEACON:
			hp = 30; damage = 8; move_speed = 260; move_cooldown = 2.5
		Behavior.DIVINE_BROKEN_WING_ASSASSIN:
			hp = 32; damage = 14; move_speed = 520; move_cooldown = 2.5
		Behavior.DIVINE_SERAPH_HUNTER:
			hp = 1150; damage = 16; move_speed = 480; move_cooldown = 3.0; body_size = Vector2(224, 208)
		Behavior.DIVINE_ORACLE_PHANTOM:
			hp = 1300; damage = 12; move_speed = 300; move_cooldown = 3.5; body_size = Vector2(216, 224)
	lifetime = 120.0
	explosion_scale = clampf(body_size.length() / 90.0, 0.45, 0.9)


func _apply_catalog_defaults() -> void:
	for data in DesignedEnemyCatalog.ENEMIES:
		if int(data.get("behavior", -1)) != int(behavior):
			continue
		enemy_title = String(data.get("name", enemy_title))
		hp = int(data.get("hp", hp))
		damage = int(data.get("damage", damage))
		var catalog_size = data.get("size", body_size)
		if catalog_size is Vector2:
			body_size = catalog_size
		var catalog_color = data.get("color", body_color)
		if catalog_color is Color:
			body_color = catalog_color
		var catalog_accent = data.get("accent", accent_color)
		if catalog_accent is Color:
			accent_color = catalog_accent
		return


func _pick_path_target() -> void:
	if not player:
		path_target = _find_reachable_target(Vector2(randf_range(120, 1800), randf_range(120, 900)))
		return
	match behavior:
		Behavior.COLOSSUS_SHARD_ARM:
			_prepare_shard_charge_path()
		Behavior.HELLEYE_INVERTED_MOTH:
			_prepare_shard_charge_path()
		Behavior.HELLEYE_HORIZON_DEFLECTOR:
			_prepare_shard_charge_path()
		Behavior.COLOSSUS_GUARD:
			_prepare_shard_charge_path()
		Behavior.COLOSSUS_GRAVITY_CLAW:
			_prepare_gravity_claw_charge_path()
		Behavior.DIVINE_WING_RAIDER:
			_prepare_shard_charge_path()
		Behavior.HELLEYE_BLIND_MOTH:
			path_target = _find_reachable_target(player.global_position + Vector2(randf_range(-260, 260), randf_range(-180, 180)))
		Behavior.DIVINE_BROKEN_WING_ASSASSIN, Behavior.DIVINE_SERAPH_HUNTER:
			_prepare_shard_charge_path()
		_:
			path_target = _find_reachable_target(Vector2(randf_range(140, screen_size.x - 140), randf_range(120, screen_size.y * 0.72)))


func _update_warning(delta: float) -> void:
	if _update_divine_teleport(delta):
		_update_effects(delta)
		return
	warning_timer -= delta
	if warning_timer <= 0.0:
		_begin_move()
		state = State.MOVING
	_update_effects(delta)


func _update_cooldown(delta: float) -> void:
	if _update_divine_teleport(delta):
		_update_effects(delta)
		return
	if _update_alert_notice(delta):
		return
	if not _ai_alert:
		if _should_begin_alert_notice(delta):
			_begin_alert_notice()
		else:
			_update_idle_patrol(delta)
		_update_effects(delta)
		return
	if _should_drop_alert():
		_enter_idle_ai()
		_update_idle_patrol(delta)
		_update_effects(delta)
		return
	if _uses_shield_bee_positioning_ai():
		_update_shield_bee(delta)
		return
	if behavior == Behavior.COLOSSUS_GRAVITY_CLAW and _update_gravity_claw_lock_state(delta):
		return
	if _update_detection_pursuit(delta):
		return
	var before := global_position
	if _apply_obstacle_bounce(delta):
		_update_effects(delta)
		return
	if behavior == Behavior.DIVINE_BROKEN_WING_ASSASSIN or behavior == Behavior.DIVINE_SERAPH_HUNTER:
		cooldown_remaining -= delta
		_update_divine_assassin_cooldown_positioning(delta)
		if cooldown_remaining <= _get_warning_duration():
			_begin_divine_teleport(DIVINE_TELEPORT_ASSASSIN)
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
		Behavior.COLOSSUS_GRAVITY_CLAW:
			_update_gravity_claw_attack(delta)
		Behavior.COLOSSUS_CORE_DEVOURER:
			_devourer_attack()
		Behavior.PARADISE_PATROL:
			_periodic_shot(1.2, PARADISE_PATROL_BULLET_SPEED, damage)
		Behavior.PARADISE_ARC_SCATTER:
			_periodic_spread(1.7, 7, PI / 2.8, PARADISE_ARC_SCATTER_BULLET_SPEED, damage)
		Behavior.PARADISE_RAIL_CHAIN:
			_burst_shot(2.0, 3, 0.16, PARADISE_RAIL_CHAIN_BULLET_SPEED, damage)
		Behavior.PARADISE_CALIBRATOR:
			_calibrator_attack(delta)
		Behavior.PARADISE_SANCTUM_SUPPRESSOR:
			_sanctum_attack()
		_:
			# WARPED/HELLEYE/DIVINE 系的攻击已迁移到各自的占位/幻影系统，冷却期无额外动作
			pass


func _update_movement(delta: float) -> void:
	if _update_divine_teleport(delta):
		_update_effects(delta)
		return
	if not _ai_alert:
		state = State.COOLDOWN
		_update_idle_patrol(delta)
		_update_effects(delta)
		return
	if _should_drop_alert():
		_enter_idle_ai()
		_update_idle_patrol(delta)
		_update_effects(delta)
		return
	if _uses_shield_bee_positioning_ai():
		_update_shield_bee(delta)
		return
	if _update_detection_pursuit(delta):
		return
	if _uses_shard_charge_ai():
		_update_shard_charge(delta)
		return
	if behavior == Behavior.COLOSSUS_GRAVITY_CLAW:
		_update_gravity_claw_charge(delta)
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
		if behavior == Behavior.COLOSSUS_GRAVITY_CLAW:
			_try_gravity_claw_grapple(area)
			return
		if behavior == Behavior.COLOSSUS_GUARD and _shard_is_fast_charging:
			_handle_guard_charge_player_collision(area)
			return
		if behavior == Behavior.HELLEYE_HORIZON_DEFLECTOR and _shard_is_fast_charging:
			_handle_horizon_charge_player_collision(area)
			return
		if behavior == Behavior.DIVINE_SERAPH_HUNTER and _shard_is_fast_charging:
			_handle_divine_seraph_charge_player_collision(area)
			return
		handle_player_collision(area)


func _update_knockback(delta: float) -> void:
	if not _uses_shield_bee_positioning_ai():
		super(delta)
		return
	position += knockback_velocity * delta
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_velocity.length() * 4.0 * delta)
	knockback_duration -= delta
	if knockback_duration <= 0.0:
		knockback_duration = 0.0
		knockback_velocity = Vector2.ZERO
		_resume_positioning_ai_after_interrupt()


func _update_detection_pursuit(delta: float) -> bool:
	if state == State.WARNING or state == State.MOVING:
		return false
	if not player or detection_range <= 0.0:
		_enter_idle_ai()
		return false
	var distance_sq := global_position.distance_squared_to(player.global_position)
	var drop_distance := detection_range * 1.2
	var notice_distance := detection_range * 0.8
	var pursue_distance := detection_range * 1.5
	if _is_pursuing_player:
		_pursuit_elapsed += delta
	if distance_sq > drop_distance * drop_distance or (_is_pursuing_player and _pursuit_elapsed >= pursuit_timeout):
		_enter_idle_ai()
		return true
	var distance := sqrt(distance_sq)
	var blocked_from_player := _is_detection_line_blocked(delta)
	if distance <= notice_distance and not blocked_from_player:
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
	if distance <= pursue_distance or (_ai_alert and blocked_from_player):
		_enter_pursuit_ai()
		_update_pursuit_movement(delta)
		return true
	_enter_idle_ai()
	return true


func _should_begin_alert_notice(delta: float = 0.0) -> bool:
	if _alert_notice_active or not player or detection_range <= 0.0:
		return false
	var alert_distance = detection_range * 0.8
	if global_position.distance_squared_to(player.global_position) > alert_distance * alert_distance:
		return false
	if _explore_patrol_enabled:
		_explore_alert_probe_timer -= delta
		if _explore_alert_probe_timer > 0.0:
			return false
		_explore_alert_probe_timer = EXPLORE_ALERT_PROBE_INTERVAL + randf_range(0.0, EXPLORE_ALERT_PROBE_JITTER)
	var distance := global_position.distance_to(player.global_position)
	if distance > alert_distance:
		return false
	return not _is_detection_line_blocked(delta)


func _should_drop_alert() -> bool:
	if state == State.WARNING or state == State.MOVING:
		return false
	if behavior == Behavior.HELLEYE_BLIND_MOTH and _hell_eye_blind_latched and player:
		return false
	if not player or detection_range <= 0.0:
		return true
	return global_position.distance_to(player.global_position) > detection_range * 1.2


func _is_detection_line_blocked(delta: float) -> bool:
	if not player:
		return true
	_detection_los_timer -= delta
	if _detection_los_timer <= 0.0:
		_detection_los_timer = DETECTION_LOS_CHECK_INTERVAL + randf_range(0.0, DETECTION_LOS_CHECK_INTERVAL * 0.35)
		_detection_los_blocked = _path_blocked_by_obstacle(global_position, player.global_position)
	return _detection_los_blocked


func _begin_alert_notice() -> void:
	_alert_notice_active = true
	_alert_notice_timer = ALERT_NOTICE_DURATION
	_ai_alert = false
	_is_pursuing_player = false
	state = State.COOLDOWN
	cooldown_remaining = move_cooldown
	_show_overhead_notice("!", Color(1.0, 0.08, 0.04))
	_show_alert_arrow_to_player()


func _update_alert_notice(delta: float) -> bool:
	if not _alert_notice_active:
		return false
	_alert_notice_timer -= delta
	_update_idle_patrol(delta)
	_update_alert_notice_position()
	if _alert_notice_timer <= 0.0:
		_alert_notice_active = false
		_enter_alert_ai()
	return true


func _show_overhead_notice(text: String, color: Color) -> void:
	if is_instance_valid(_alert_notice_node):
		_alert_notice_node.queue_free()
	var anchor := Node2D.new()
	anchor.z_index = 120
	var notice_parent := _get_effect_parent()
	notice_parent.add_child(anchor)
	_alert_notice_node = anchor
	_update_alert_notice_position()

	var label := Label.new()
	label.text = text
	label.modulate = Color(color.r, color.g, color.b, 0.0)
	label.add_theme_font_size_override("font_size", 46)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(44, 52)
	label.position = Vector2(-22, -body_size.y * 0.68 - 52)
	label.scale = Vector2(0.55, 0.55)
	label.z_index = 0
	anchor.add_child(label)
	var base_y := label.position.y
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.tween_property(label, "scale", Vector2(1.28, 1.28), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", base_y - 18.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.tween_property(label, "position:y", base_y - 4.0, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.12)
	tween.chain()
	tween.tween_property(label, "modulate:a", 0.0, 0.36)
	tween.tween_property(label, "position:y", base_y - 28.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(anchor.queue_free)


func _show_alert_arrow_to_player() -> void:
	if not player or not player is Node2D:
		return
	if is_instance_valid(_alert_arrow_node):
		_alert_arrow_node.queue_free()
	var arrow := Node2D.new()
	arrow.name = "AlertArrowToPlayer"
	arrow.set_script(ALERT_ARROW_SCRIPT)
	var notice_parent := _get_effect_parent()
	notice_parent.add_child(arrow)
	_alert_arrow_node = arrow
	var enemy_radius := maxf(body_size.x, body_size.y) * 0.55
	var player_radius := _get_player_visual_radius()
	arrow.call("setup", self, player as Node2D, enemy_radius, player_radius, Color(1.0, 0.18, 0.04, 0.3), ALERT_ARROW_TRAVEL_DURATION, ALERT_ARROW_HOLD_DURATION, ALERT_ARROW_FADE_DURATION)


func _update_alert_notice_position() -> void:
	if not is_instance_valid(_alert_notice_node):
		return
	_alert_notice_node.global_position = global_position
	_alert_notice_node.global_rotation = 0.0


func _update_idle_patrol(delta: float) -> void:
	if _explore_patrol_enabled:
		_update_explore_patrol(delta)
		return
	if not _idle_origin_set:
		_idle_origin = global_position
		_idle_origin_set = true
	if _apply_obstacle_bounce(delta):
		return
	if _idle_patrol_pause > 0.0:
		_idle_patrol_pause -= delta
		return
	if _idle_patrol_target == Vector2.ZERO or global_position.distance_to(_idle_patrol_target) <= IDLE_PATROL_REACHED_DISTANCE:
		_idle_patrol_target = _pick_idle_patrol_target()
		_idle_patrol_pause = randf_range(0.12, 0.35)
		return
	var to_target := _idle_patrol_target - global_position
	if to_target.length() <= IDLE_PATROL_REACHED_DISTANCE:
		_idle_patrol_target = Vector2.ZERO
		return
	var move_dir := to_target.normalized()
	var before := global_position
	var next_pos := global_position + move_dir * move_speed * IDLE_PATROL_SPEED_MULT * delta
	var pushed := _push_out_from_obstacles(next_pos)
	if pushed.distance_to(next_pos) > 0.5:
		global_position = pushed
		_idle_patrol_target = _pick_idle_patrol_target()
	else:
		global_position = pushed
		_last_safe_position = global_position
	_smooth_face_direction(global_position - before, delta, turn_speed * 0.45)


func _pick_idle_patrol_target() -> Vector2:
	var angles := [randf_range(0.0, TAU), 0.0, PI * 0.5, PI, PI * 1.5]
	for angle in angles:
		var distance := randf_range(IDLE_PATROL_RADIUS * 0.35, IDLE_PATROL_RADIUS)
		var candidate := _clamped_point(_idle_origin + Vector2.RIGHT.rotated(angle) * distance)
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) <= 2.0 and not _path_blocked_by_obstacle(global_position, candidate):
			return candidate
	return _push_out_from_obstacles(_clamped_point(_idle_origin))


func _update_explore_patrol(delta: float) -> void:
	if _explore_patrol_points.size() < 2:
		return
	if _explore_patrol_index >= _explore_patrol_points.size():
		_move_explore_patrol_beyond_end(delta)
		return
	var target = _explore_patrol_points[_explore_patrol_index] + _explore_patrol_offset
	var to_target = target - global_position
	if to_target.length() <= IDLE_PATROL_REACHED_DISTANCE:
		_explore_patrol_index += 1
		return
	var move_dir = to_target.normalized()
	var before = global_position
	var next_pos = global_position + move_dir * move_speed * IDLE_PATROL_SPEED_MULT * delta
	var pushed = _push_out_from_obstacles(next_pos)
	if pushed.distance_to(next_pos) > 0.5:
		global_position = pushed
		_enter_explore_patrol_from_nearest_point()
	else:
		global_position = pushed
		_last_safe_position = global_position
	source_position = global_position
	_smooth_face_direction(global_position - before, delta, turn_speed * 0.45)


func _move_explore_patrol_beyond_end(delta: float) -> void:
	var last_index = _explore_patrol_points.size() - 1
	var prev = _explore_patrol_points[maxi(0, last_index - 1)]
	var last = _explore_patrol_points[last_index]
	var dir = (last - prev).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var before = global_position
	var next_pos = global_position + dir * move_speed * IDLE_PATROL_SPEED_MULT * delta
	var pushed = _push_out_from_obstacles(next_pos)
	global_position = pushed
	source_position = global_position
	_smooth_face_direction(global_position - before, delta, turn_speed * 0.45)


func _enter_explore_patrol_from_nearest_point() -> void:
	if _explore_patrol_points.size() < 2:
		return
	var best_index = 1
	var best_distance = INF
	for i in range(1, _explore_patrol_points.size()):
		var distance = global_position.distance_to(_explore_patrol_points[i] + _explore_patrol_offset)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	_explore_patrol_index = best_index



func _is_outside_explore_despawn_bounds() -> bool:
	if _explore_patrol_room_bounds.size == Vector2.ZERO:
		return false
	var expanded = _explore_patrol_room_bounds.grow(_explore_patrol_despawn_margin)
	return not expanded.has_point(global_position)


func _enter_idle_ai(force: bool = false) -> void:
	if not force and (state == State.WARNING or state == State.MOVING):
		return
	var should_show_lost_notice := not force and (_ai_alert or _is_pursuing_player or _alert_notice_active)
	_ai_alert = false
	_alert_notice_active = false
	_is_pursuing_player = false
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	_release_hell_eye_player_effects()
	_clear_hell_eye_visuals()
	_hell_eye_blind_latched = false
	_gravity_claw_is_retreating = false
	_gravity_claw_is_fast_charging = false
	_gravity_claw_recovery_timer = 0.0
	_gravity_claw_knock_velocity = Vector2.ZERO
	_pursuit_target = Vector2.ZERO
	_pursuit_repath_timer = 0.0
	_clear_line_stability = 0.0
	_pursuit_elapsed = 0.0
	_idle_patrol_target = Vector2.ZERO
	_idle_patrol_pause = randf_range(0.1, 0.35)
	if _explore_patrol_enabled and not force:
		_enter_explore_patrol_from_nearest_point()
	_calibrator_shot_timer = 0.0
	_calibrator_warning_timer = 0.0
	_calibrator_locked_dir = Vector2.ZERO
	_calibrator_recoil_velocity = Vector2.ZERO
	_calibrator_dodge_side = 1.0 if randf() < 0.5 else -1.0
	_calibrator_ray_timer = 0.0
	_calibrator_ray_points = PackedVector2Array()
	_sanctum_spin_speed = 0.0
	_sanctum_spin_active = false
	_sanctum_spin_fire_timer = 0.0
	_cancel_divine_teleport()
	_clear_divine_oracle_phantoms()
	state = State.COOLDOWN
	cooldown_remaining = move_cooldown
	source_position = global_position
	if should_show_lost_notice:
		_show_overhead_notice("?", Color(0.35, 0.78, 1.0))
	queue_redraw()


func _enter_alert_ai() -> void:
	_ai_alert = true
	_alert_notice_active = false
	_is_pursuing_player = false
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	_gravity_claw_is_retreating = false
	_gravity_claw_is_fast_charging = false
	_pursuit_target = Vector2.ZERO
	_pursuit_repath_timer = 0.0
	_clear_line_stability = 0.0
	_pursuit_elapsed = 0.0
	_cancel_divine_teleport()
	source_position = global_position
	if _uses_shield_bee_positioning_ai():
		state = State.COOLDOWN
		cooldown_remaining = move_cooldown
		if behavior == Behavior.COLOSSUS_CORE_DEVOURER:
			_core_devourer_claw_timer = randf_range(3.0, 8.0)
			_request_core_devourer_gravity_claw_pool_prewarm()
		if behavior == Behavior.DIVINE_ORACLE_PHANTOM:
			_divine_oracle_spawn_timer = randf_range(DIVINE_ORACLE_PHANTOM_MIN_INTERVAL, DIVINE_ORACLE_PHANTOM_MAX_INTERVAL)
		_shield_bee_target = _find_shield_bee_target()
		_shield_bee_path = [global_position, _shield_bee_target]
		_shield_bee_path_index = 1
		_shield_bee_path_avoid_player = _should_avoid_player_for_positioning_target(_shield_bee_target)
		_shield_bee_repath_timer = _shield_bee_repath_retry_delay()
		queue_redraw()
		return
	if behavior == Behavior.DIVINE_BROKEN_WING_ASSASSIN or behavior == Behavior.DIVINE_SERAPH_HUNTER:
		state = State.COOLDOWN
		cooldown_remaining = move_cooldown
		_begin_divine_teleport(DIVINE_TELEPORT_ASSASSIN)
		queue_redraw()
		return
	_pick_path_target()
	warning_timer = _get_warning_duration()
	state = State.WARNING
	queue_redraw()


func _enter_pursuit_ai() -> void:
	_ai_alert = true
	_is_pursuing_player = true
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	_gravity_claw_is_retreating = false
	_gravity_claw_is_fast_charging = false
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
	_pursuit_path_check_timer -= delta
	if _pursuit_target == Vector2.ZERO or _pursuit_path_check_timer <= 0.0:
		_pursuit_target_blocked = _pursuit_target != Vector2.ZERO and _path_blocked_by_obstacle(global_position, _pursuit_target)
		_pursuit_path_check_timer = PURSUIT_PATH_CHECK_INTERVAL + randf_range(0.0, PURSUIT_PATH_CHECK_INTERVAL * 0.35)
	if _pursuit_target == Vector2.ZERO or _pursuit_repath_timer <= 0.0 or _pursuit_target_blocked:
		_pursuit_target = _find_pursuit_target()
		_pursuit_repath_timer = 0.45
		_pursuit_target_blocked = false
		_pursuit_path_check_timer = PURSUIT_PATH_CHECK_INTERVAL + randf_range(0.0, PURSUIT_PATH_CHECK_INTERVAL * 0.35)
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



func _find_explore_light_combat_target() -> Vector2:
	if not player:
		return global_position
	var to_enemy = global_position - player.global_position
	var distance = to_enemy.length()
	var away = to_enemy.normalized() if distance > 1.0 else Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	var target_distance = clampf(detection_range * 0.55, EXPLORE_COMBAT_STOP_DISTANCE, 760.0)
	if distance < EXPLORE_COMBAT_RETREAT_DISTANCE:
		return _clamped_point(player.global_position + away * target_distance)
	if distance > target_distance * 1.25:
		return _clamped_point(player.global_position + away * target_distance)
	var tangent = away.orthogonal()
	if randf() < 0.5:
		tangent = -tangent
	return _clamped_point(global_position + tangent * randf_range(120.0, 260.0))


func _move_toward_explore_combat_target(delta: float) -> void:
	var to_target = _explore_combat_target - global_position
	if to_target.length() <= 10.0:
		return
	var move_dir = to_target.normalized()
	var next_pos = _clamped_point(global_position + move_dir * move_speed * delta)
	var pushed = _push_out_from_obstacles(next_pos)
	if pushed.distance_to(next_pos) > 0.5:
		global_position = pushed
		_explore_combat_target = _find_explore_light_combat_target()
		_explore_combat_target_timer = EXPLORE_COMBAT_TARGET_INTERVAL + randf_range(0.0, 0.2)
	else:
		global_position = pushed
		_last_safe_position = global_position
	source_position = global_position
	path_target = _explore_combat_target
	_smooth_face_direction(move_dir, delta, turn_speed)


func _update_explore_light_combat_attack(delta: float) -> void:
	if not player:
		return
	var to_player = player.global_position - global_position
	if to_player.length() <= 0.01:
		return
	_smooth_face_direction(to_player, delta, turn_speed)
	if not _has_fast_line_to_player():
		return
	match behavior:
		Behavior.PARADISE_ARC_SCATTER:
			_periodic_spread(move_cooldown, 5, PI / 2.8, PARADISE_ARC_SCATTER_BULLET_SPEED, damage)
		Behavior.PARADISE_RAIL_CHAIN:
			_burst_shot(move_cooldown, 3, 0.16, PARADISE_RAIL_CHAIN_BULLET_SPEED, damage)
		Behavior.WARPED_REFRACTION_SHOOTER:
			if _attack_timer <= 0.0:
				_attack_timer = move_cooldown
				_spawn_reflect_bullet(to_player.normalized(), WARPED_REFRACTION_BULLET_SPEED, damage)
		Behavior.WARPED_COLLAPSE_BEACON:
			if _attack_timer <= 0.0:
				_attack_timer = move_cooldown
				_fire_warped_collapse_shotgun()
		_:
			_periodic_shot(move_cooldown, PARADISE_PATROL_BULLET_SPEED, damage)


func _has_fast_line_to_player() -> bool:
	if not player:
		return false
	_fast_los_timer -= get_process_delta_time()
	if _fast_los_timer <= 0.0:
		_fast_los_timer = FAST_LOS_CHECK_INTERVAL + randf_range(0.0, FAST_LOS_CHECK_INTERVAL * 0.35)
		_fast_los_clear = not _path_blocked_by_obstacle(global_position, player.global_position, EXPLORE_LOS_SAMPLE_DISTANCE)
	return _fast_los_clear


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
	_reset_divine_raider_side_shots()
	if behavior == Behavior.HELLEYE_HORIZON_DEFLECTOR:
		_prepare_horizon_phantom_charge_paths()


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
		if behavior == Behavior.HELLEYE_HORIZON_DEFLECTOR:
			_update_horizon_phantom_retreat(retreat_t)
		state = State.WARNING
		if behavior == Behavior.HELLEYE_INVERTED_MOTH:
			_update_inverted_moth_phantom()
		elif behavior == Behavior.HELLEYE_HORIZON_DEFLECTOR:
			_update_horizon_phantoms()
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
		if behavior == Behavior.COLOSSUS_GUARD:
			_activate_shield_bee_style_shield()
		if behavior == Behavior.HELLEYE_INVERTED_MOTH:
			_update_inverted_moth_phantom()
		elif behavior == Behavior.HELLEYE_HORIZON_DEFLECTOR:
			_update_horizon_phantoms()
		state = State.MOVING
		move_elapsed += delta
		var t := clampf(move_elapsed / move_duration, 0.0, 1.0)
		var eased_t := 1.0 - pow(1.0 - t, 3.0)
		global_position = source_position.lerp(path_target, eased_t)
		if behavior == Behavior.DIVINE_WING_RAIDER:
			_update_divine_raider_side_shots(before, global_position)
		if behavior == Behavior.HELLEYE_HORIZON_DEFLECTOR:
			_update_horizon_phantom_charge(eased_t)
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
			if behavior == Behavior.HELLEYE_INVERTED_MOTH:
				_clear_inverted_moth_phantom()
			elif behavior == Behavior.HELLEYE_HORIZON_DEFLECTOR:
				_begin_horizon_phantom_return()
		_update_effects(delta)


func _begin_move() -> void:
	if behavior == Behavior.COLOSSUS_SHIELD_BEE:
		state = State.COOLDOWN
		cooldown_remaining = move_cooldown
		return
	if _uses_shard_charge_ai():
		move_elapsed = 0.0
		move_duration = _shard_retreat_duration + maxf(global_position.distance_to(_shard_charge_target) / (move_speed * 5.0), 0.05)
		return
	if behavior == Behavior.COLOSSUS_GRAVITY_CLAW:
		move_elapsed = 0.0
		move_duration = GRAVITY_CLAW_RETREAT_DURATION + maxf(global_position.distance_to(_gravity_claw_charge_target) / (move_speed * GRAVITY_CLAW_CHARGE_SPEED_MULT), 0.05)
		return
	super()


func take_damage(amount: int, source: Node = null) -> void:
	if _gravity_claw_core_summoned and get_meta(&"core_devourer_pool_item", false) and not _ai_alert:
		return
	if amount <= 0:
		super(amount, source)
		return
	var was_alive := hp > 0
	var should_shield_bee_counter := false
	var shield_bee_counter_damage := amount
	var is_player_bullet_damage := _is_player_bullet_damage_source(source)
	var should_divine_blink := was_alive and behavior == Behavior.DIVINE_BLINK_BEACON
	var should_divine_seraph_retarget := was_alive and behavior == Behavior.DIVINE_SERAPH_HUNTER and not _shard_is_fast_charging
	if behavior == Behavior.COLOSSUS_CORE_DEVOURER:
		var shield_active := _shield_bee_shield_time > 0.0
		var should_core_counter := is_player_bullet_damage
		amount = ceili(amount * 0.5) if shield_active else amount
		_activate_shield_bee_style_shield()
		super(amount, source)
		if should_core_counter and hp > 0 and not is_queued_for_deletion():
			_core_devourer_fire_gravity_claw(shield_bee_counter_damage, true)
		return
	if _uses_shield_bee_style_shield():
		var shield_active := _shield_bee_shield_time > 0.0 or (behavior == Behavior.COLOSSUS_GUARD and _shard_is_fast_charging)
		should_shield_bee_counter = shield_active and is_player_bullet_damage
		if behavior == Behavior.COLOSSUS_GUARD and _shard_is_fast_charging:
			_activate_shield_bee_style_shield()
			if should_shield_bee_counter and hp > 0 and not is_queued_for_deletion():
				_shield_bee_counter_shot(shield_bee_counter_damage)
			return
		amount = ceili(amount * 0.5) if shield_active else amount
		_activate_shield_bee_style_shield()
	super(amount, source)
	if _uses_shield_bee_style_shield() and should_shield_bee_counter and hp > 0 and not is_queued_for_deletion():
		_shield_bee_counter_shot(shield_bee_counter_damage)
	if should_divine_blink and hp > 0 and not is_queued_for_deletion():
		_begin_divine_teleport(DIVINE_TELEPORT_BLINK)
	if should_divine_seraph_retarget and hp > 0 and not is_queued_for_deletion():
		_begin_divine_teleport(DIVINE_TELEPORT_SERAPH_RETARGET)
	if was_alive and behavior == Behavior.WARPED_MICRO_CORE and hp <= 0:
		_spawn_warped_micro_core_death_ring()


func _uses_shield_bee_style_shield() -> bool:
	return behavior == Behavior.COLOSSUS_SHIELD_BEE or behavior == Behavior.COLOSSUS_GUARD or behavior == Behavior.COLOSSUS_CORE_DEVOURER


func _uses_shield_bee_positioning_ai() -> bool:
	return behavior == Behavior.COLOSSUS_SHIELD_BEE or behavior == Behavior.COLOSSUS_CORE_DEVOURER or _uses_paradise_formation_shooter() or _uses_warped_positioning_ai() or _uses_hell_eye_positioning_ai() or behavior == Behavior.DIVINE_ORACLE_PHANTOM


func _uses_paradise_formation_shooter() -> bool:
	return behavior == Behavior.PARADISE_PATROL or behavior == Behavior.PARADISE_ARC_SCATTER or behavior == Behavior.PARADISE_RAIL_CHAIN or behavior == Behavior.PARADISE_CALIBRATOR or behavior == Behavior.PARADISE_SANCTUM_SUPPRESSOR or behavior == Behavior.WARPED_REFRACTION_SHOOTER or behavior == Behavior.WARPED_COLLAPSE_BEACON or behavior == Behavior.DIVINE_BLINK_BEACON



func _locks_rotation_for_positioning_ai() -> bool:
	return behavior == Behavior.PARADISE_SANCTUM_SUPPRESSOR or _uses_warped_spin()


func _uses_warped_positioning_ai() -> bool:
	return behavior == Behavior.WARPED_MICRO_CORE or behavior == Behavior.WARPED_ORBIT_DISRUPTOR or behavior == Behavior.WARPED_DEFLECTION_MATRIX


func _uses_hell_eye_positioning_ai() -> bool:
	return behavior == Behavior.HELLEYE_BLIND_MOTH or behavior == Behavior.HELLEYE_MISALIGNED_GAZER or behavior == Behavior.HELLEYE_INVERT_PRIEST


func _uses_warped_spin() -> bool:
	return behavior == Behavior.WARPED_MICRO_CORE or behavior == Behavior.WARPED_ORBIT_DISRUPTOR or behavior == Behavior.WARPED_COLLAPSE_BEACON or behavior == Behavior.WARPED_DEFLECTION_MATRIX


func _uses_shard_charge_ai() -> bool:
	return behavior == Behavior.COLOSSUS_SHARD_ARM or behavior == Behavior.COLOSSUS_GUARD or behavior == Behavior.HELLEYE_INVERTED_MOTH or behavior == Behavior.HELLEYE_HORIZON_DEFLECTOR or behavior == Behavior.DIVINE_WING_RAIDER or behavior == Behavior.DIVINE_BROKEN_WING_ASSASSIN or behavior == Behavior.DIVINE_SERAPH_HUNTER


func _uses_warped_attract_field() -> bool:
	return behavior == Behavior.WARPED_MICRO_CORE


func _uses_warped_repulse_field() -> bool:
	return behavior == Behavior.WARPED_DEFLECTION_MATRIX


func _uses_warped_lightning() -> bool:
	return behavior == Behavior.WARPED_ORBIT_DISRUPTOR or behavior == Behavior.WARPED_DEFLECTION_MATRIX


func _activate_shield_bee_style_shield() -> void:
	_shield_bee_shield_time = SHIELD_BEE_SHIELD_DURATION
	queue_redraw()


func _is_player_bullet_damage_source(source: Node) -> bool:
	if not is_instance_valid(source):
		return false
	return source.has_method("is_player_bullet") and bool(source.call("is_player_bullet"))


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



func _shield_bee_counter_shot(dmg: int) -> void:
	if not player or dmg <= 0:
		return
	var dir := player.global_position - global_position
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	_spawn_bullet(dir.normalized(), 500.0, dmg)


func _core_devourer_fire_gravity_claw(x: int, from_counter: bool = false) -> void:
	if from_counter:
		if _core_devourer_counter_claw_timer > 0.0:
			return
		if not _core_devourer_can_queue_gravity_claw():
			return
		_core_devourer_counter_claw_timer = CORE_DEVOURER_COUNTER_CLAW_MIN_INTERVAL
	_core_devourer_begin_gravity_claw_warning(x)


func _core_devourer_begin_gravity_claw_warning(x: int) -> void:
	if not player or x <= 0:
		return
	if not _core_devourer_can_queue_gravity_claw():
		return
	var dir := player.global_position - global_position
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	_core_devourer_claw_warnings.append({
		"time": CORE_DEVOURER_CLAW_WARNING_DURATION,
		"damage": x,
		"direction": dir.normalized(),
	})
	queue_redraw()


func _core_devourer_spawn_gravity_claw(x: int, dir: Vector2) -> void:
	if x <= 0:
		return
	if _get_core_devourer_owned_gravity_claw_count() >= CORE_DEVOURER_MAX_GRAVITY_CLAWS_PER_OWNER:
		return
	dir = dir.normalized()
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	var claw := _acquire_core_devourer_gravity_claw()
	if not claw:
		return
	claw.global_position = global_position + dir.normalized() * maxf(body_size.x * 0.45, 44.0)
	claw.z_index = z_index - 1
	claw.set_meta(&"core_devourer_owner", self)
	if claw.has_method("launch_as_core_devourer_gravity_claw"):
		claw.call("launch_as_core_devourer_gravity_claw", global_position + dir * CORE_DEVOURER_CLAW_WARNING_LENGTH, x, CORE_DEVOURER_CLAW_DOT_DAMAGE_PER_SECOND, self)


func _request_core_devourer_gravity_claw_pool_prewarm() -> void:
	if behavior != Behavior.COLOSSUS_CORE_DEVOURER:
		return
	if _core_devourer_gravity_claw_pool.size() >= CORE_DEVOURER_GRAVITY_CLAW_POOL_PREWARM:
		return
	_core_devourer_pool_prewarm_requested = true
	_core_devourer_pool_prewarm_timer = 0.0


func _update_core_devourer_gravity_claw_pool_prewarm(delta: float) -> void:
	if not _core_devourer_pool_prewarm_requested:
		return
	if _core_devourer_gravity_claw_pool.size() >= CORE_DEVOURER_GRAVITY_CLAW_POOL_PREWARM:
		_core_devourer_pool_prewarm_requested = false
		return
	_core_devourer_pool_prewarm_timer -= delta
	if _core_devourer_pool_prewarm_timer > 0.0:
		return
	var parent := _get_effect_parent()
	var claw := _create_core_devourer_gravity_claw_pool_item()
	if not claw:
		_core_devourer_pool_prewarm_requested = false
		return
	parent.add_child(claw)
	_release_core_devourer_gravity_claw_to_pool(claw)
	_core_devourer_pool_prewarm_timer = CORE_DEVOURER_GRAVITY_CLAW_POOL_PREWARM_INTERVAL
	if _core_devourer_gravity_claw_pool.size() >= CORE_DEVOURER_GRAVITY_CLAW_POOL_PREWARM:
		_core_devourer_pool_prewarm_requested = false


func _acquire_core_devourer_gravity_claw() -> Node2D:
	var claw: Node2D = null
	while not _core_devourer_gravity_claw_pool.is_empty():
		claw = _core_devourer_gravity_claw_pool.pop_back()
		if is_instance_valid(claw) and not claw.is_queued_for_deletion():
			break
		claw = null
	if claw == null:
		claw = _create_core_devourer_gravity_claw_pool_item()
		if claw == null:
			return null
	var parent := _get_effect_parent()
	if claw.get_parent() != parent:
		if claw.get_parent():
			claw.get_parent().remove_child(claw)
		parent.add_child(claw)
	_prepare_core_devourer_gravity_claw_for_reuse(claw)
	return claw


func _create_core_devourer_gravity_claw_pool_item() -> Node2D:
	var claw_scene := _get_designed_enemy_scene()
	if not claw_scene:
		return null
	var claw := claw_scene.instantiate() as Node2D
	if not claw:
		return null
	claw.set(&"behavior", Behavior.COLOSSUS_GRAVITY_CLAW)
	claw.set(&"enemy_title", "引力钩爪")
	claw.set(&"body_size", Vector2(76, 96))
	claw.set(&"body_color", Color(0.4, 0.36, 0.45, 1))
	claw.set(&"accent_color", Color(0.95, 0.28, 0.2, 1))
	claw.set_meta(&"core_devourer_pool_item", true)
	return claw


func _prepare_core_devourer_gravity_claw_for_reuse(claw: Node2D) -> void:
	claw.show()
	claw.visible = true
	claw.process_mode = Node.PROCESS_MODE_INHERIT
	claw.set_physics_process(true)
	claw.set_process(true)
	if claw.has_method("reset_core_devourer_gravity_claw_from_pool"):
		claw.call("reset_core_devourer_gravity_claw_from_pool")
	claw.add_to_group(&"enemies")
	claw.add_to_group(&"core_devourer_gravity_claws")


static func _release_core_devourer_gravity_claw_to_pool(claw: Node2D) -> void:
	if not is_instance_valid(claw):
		return
	if _core_devourer_gravity_claw_pool.has(claw):
		return
	claw.remove_from_group(&"enemies")
	claw.remove_from_group(&"core_devourer_gravity_claws")
	claw.remove_meta(&"core_devourer_owner")
	claw.hide()
	claw.visible = false
	claw.process_mode = Node.PROCESS_MODE_DISABLED
	if _core_devourer_gravity_claw_pool.size() >= CORE_DEVOURER_GRAVITY_CLAW_POOL_LIMIT:
		claw.queue_free()
		return
	_core_devourer_gravity_claw_pool.append(claw)


func _has_other_active_core_devourer() -> bool:
	if not is_inside_tree():
		return false
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if node == self or not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var other_behavior = node.get("behavior")
		if other_behavior != null and int(other_behavior) == Behavior.COLOSSUS_CORE_DEVOURER:
			return true
	return false


static func _clear_core_devourer_gravity_claw_pool() -> void:
	for claw in _core_devourer_gravity_claw_pool:
		if is_instance_valid(claw):
			claw.queue_free()
	_core_devourer_gravity_claw_pool.clear()


func _core_devourer_can_queue_gravity_claw() -> bool:
	if behavior != Behavior.COLOSSUS_CORE_DEVOURER:
		return true
	if _core_devourer_claw_warnings.size() >= CORE_DEVOURER_MAX_PENDING_CLAW_WARNINGS:
		return false
	return _get_core_devourer_owned_gravity_claw_count() + _core_devourer_claw_warnings.size() < CORE_DEVOURER_MAX_GRAVITY_CLAWS_PER_OWNER


func _get_core_devourer_owned_gravity_claw_count() -> int:
	if not get_tree():
		return 0
	var count := 0
	for claw in get_tree().get_nodes_in_group(&"core_devourer_gravity_claws"):
		if not is_instance_valid(claw) or claw == self:
			continue
		if claw.get_meta(&"core_devourer_owner", null) == self or claw.get(&"_gravity_claw_core_owner") == self:
			count += 1
	return count


func _update_shield_bee(delta: float) -> void:
	_ai_alert = player != null
	_is_pursuing_player = false
	state = State.COOLDOWN
	cooldown_remaining = move_cooldown
	if _uses_paradise_formation_shooter():
		_attack_timer = maxf(_attack_timer - delta, 0.0)
		_special_timer = maxf(_special_timer - delta, 0.0)
	elif _uses_warped_positioning_ai() or _uses_hell_eye_positioning_ai():
		_attack_timer = maxf(_attack_timer - delta, 0.0)
		_special_timer = maxf(_special_timer - delta, 0.0)
	else:
		_attack_timer = 999.0
		_special_timer = 999.0
	_obstacle_bounce_time = 0.0
	_obstacle_bounce_velocity = Vector2.ZERO
	if behavior == Behavior.COLOSSUS_SHIELD_BEE:
		_shield_bee_shield_time = maxf(_shield_bee_shield_time - delta, 0.0)
	if behavior == Behavior.COLOSSUS_CORE_DEVOURER:
		_update_core_devourer_gravity_claw_pool_prewarm(delta)
		_core_devourer_counter_claw_timer = maxf(_core_devourer_counter_claw_timer - delta, 0.0)
		_update_core_devourer_claw_warnings(delta)
		if _core_devourer_claw_warnings.is_empty():
			_core_devourer_claw_timer = maxf(_core_devourer_claw_timer - delta, 0.0)
	if not player:
		_update_idle_facing(delta)
		_update_effects(delta)
		return
	if _uses_hell_eye_positioning_ai():
		_release_inactive_hell_eye_link()
	if behavior == Behavior.PARADISE_CALIBRATOR:
		_update_calibrator_recoil(delta)
	if behavior == Behavior.COLOSSUS_CORE_DEVOURER and _core_devourer_claw_warnings.is_empty() and _core_devourer_claw_timer <= 0.0:
		_core_devourer_fire_gravity_claw(damage)
		_core_devourer_claw_timer = randf_range(3.0, 8.0)
	if behavior == Behavior.DIVINE_ORACLE_PHANTOM:
		_update_divine_oracle_phantoms(delta)
	_shield_bee_repath_timer -= delta
	if _shield_bee_target == Vector2.ZERO or _shield_bee_repath_timer <= 0.0:
		if GameManager.should_defer_work("DesignedEnemy.repath_shield_bee"):
			_shield_bee_repath_timer = _shield_bee_repath_retry_delay()
			_update_effects(delta)
			return
		_repath_shield_bee(true)

	_update_positioning_path_visibility(delta)
	var waypoint := _shield_bee_next_waypoint()
	var to_waypoint := waypoint - global_position
	if to_waypoint.length() > 6.0:
		var move_dir := to_waypoint.normalized()
		var step := minf(move_speed * delta, to_waypoint.length())
		global_position += move_dir * step
		var pushed := _push_out_from_obstacles(global_position)
		if pushed.distance_to(global_position) > 0.5:
			global_position = pushed
			_last_safe_position = pushed
			_shield_bee_repath_timer = 0.0
			state = State.COOLDOWN
		elif _shield_bee_path_index < _shield_bee_path.size() and global_position.distance_to(waypoint) <= OBSTACLE_PATH_REACHED_DISTANCE:
			_shield_bee_path_index += 1
		_update_shield_bee_path_progress(delta)
		if behavior != Behavior.COLOSSUS_CORE_DEVOURER and not _locks_rotation_for_positioning_ai():
			_smooth_face_direction(move_dir, delta, turn_speed)
		elif behavior == Behavior.DIVINE_ORACLE_PHANTOM:
			_smooth_face_direction(player.global_position - global_position, delta, turn_speed * 0.7)
	else:
		if _shield_bee_path_index < _shield_bee_path.size():
			_shield_bee_path_index += 1
		_update_shield_bee_path_progress(delta)
		if behavior != Behavior.COLOSSUS_CORE_DEVOURER and not _locks_rotation_for_positioning_ai():
			_smooth_face_direction(player.global_position - global_position, delta, turn_speed * 0.7)
		elif behavior == Behavior.DIVINE_ORACLE_PHANTOM:
			_smooth_face_direction(player.global_position - global_position, delta, turn_speed * 0.7)
	source_position = global_position
	path_target = _shield_bee_target
	if _uses_paradise_formation_shooter():
		_update_paradise_formation_attack(delta)
	if _uses_warped_positioning_ai():
		_update_warped_positioning_attack(delta)
	if _uses_hell_eye_positioning_ai():
		_update_hell_eye_positioning_attack(delta)
	_update_effects(delta)
	queue_redraw()


func _update_core_devourer_claw_warnings(delta: float) -> void:
	if _core_devourer_claw_warnings.is_empty():
		return
	var active: Array[Dictionary] = []
	for warning in _core_devourer_claw_warnings:
		var remaining := float(warning.get("time", 0.0)) - delta
		if remaining <= 0.0:
			_core_devourer_spawn_gravity_claw(int(warning.get("damage", 0)), warning.get("direction", Vector2.DOWN) as Vector2)
			continue
		warning["time"] = remaining
		active.append(warning)
	_core_devourer_claw_warnings = active
	queue_redraw()


func _repath_shield_bee(force_new_target: bool = false) -> void:
	if GameManager.should_defer_work("DesignedEnemy.repath_shield_bee_start"):
		_shield_bee_repath_timer = _shield_bee_repath_retry_delay()
		return
	if force_new_target or _shield_bee_target == Vector2.ZERO:
		_shield_bee_target = _find_shield_bee_target()
	_shield_bee_path_avoid_player = _should_avoid_player_for_positioning_target(_shield_bee_target)
	var next_path := _build_positioning_path(global_position, _shield_bee_target, _shield_bee_path_avoid_player)
	if next_path.is_empty():
		_shield_bee_repath_timer = _shield_bee_repath_retry_delay()
		return
	if next_path.size() <= 1 or next_path[next_path.size() - 1].distance_to(global_position) <= OBSTACLE_PATH_REACHED_DISTANCE:
		var escape_point := _find_obstacle_path_escape_point(global_position, _shield_bee_target)
		if escape_point.distance_to(global_position) > OBSTACLE_PATH_REACHED_DISTANCE:
			next_path = [global_position, escape_point]
	_shield_bee_path = next_path
	_shield_bee_path_index = 0
	_shield_bee_repath_timer = SHIELD_BEE_REPATH_INTERVAL + randf_range(0.0, SHIELD_BEE_REPATH_INTERVAL * 0.35)
	_shield_bee_repath_failures = 0
	_shield_bee_last_progress_position = global_position
	_shield_bee_stuck_timer = 0.0


func _shield_bee_repath_retry_delay() -> float:
	_shield_bee_repath_failures = mini(_shield_bee_repath_failures + 1, 5)
	return SHIELD_BEE_REPATH_DEFER_RETRY * float(_shield_bee_repath_failures) + randf_range(0.0, 0.18)


func _update_positioning_path_visibility(delta: float) -> void:
	_positioning_visibility_timer -= delta
	if _positioning_visibility_timer > 0.0:
		return
	_positioning_visibility_timer = POSITIONING_VISIBILITY_CHECK_INTERVAL + randf_range(0.0, POSITIONING_VISIBILITY_CHECK_INTERVAL * 0.35)
	if GameManager.should_defer_work("DesignedEnemy.positioning_visibility"):
		return
	if _shield_bee_target == Vector2.ZERO:
		return
	if _shield_bee_path_index >= _shield_bee_path.size() - 1:
		return
	if not _has_clear_obstacle_path(global_position, _shield_bee_target):
		return
	if _shield_bee_path_avoid_player and _segment_near_player(global_position, _shield_bee_target):
		return
	_shield_bee_path = [global_position, _shield_bee_target]
	_shield_bee_path_index = 1


func _update_shield_bee_path_progress(delta: float) -> void:
	if _shield_bee_last_progress_position == Vector2.ZERO:
		_shield_bee_last_progress_position = global_position
		return
	if global_position.distance_to(_shield_bee_last_progress_position) <= OBSTACLE_PATH_STUCK_DISTANCE:
		_shield_bee_stuck_timer += delta
	else:
		_shield_bee_last_progress_position = global_position
		_shield_bee_stuck_timer = 0.0
	if _shield_bee_stuck_timer >= OBSTACLE_PATH_STUCK_TIME:
		_shield_bee_repath_timer = 0.0


func _resume_positioning_ai_after_interrupt() -> void:
	source_position = global_position
	warning_timer = 0.0
	state = State.COOLDOWN
	cooldown_remaining = move_cooldown
	if _ai_alert and player:
		_is_pursuing_player = false
		_shield_bee_repath_timer = 0.0
	else:
		_idle_patrol_target = Vector2.ZERO
	queue_redraw()


func _find_shield_bee_target() -> Vector2:
	if not player:
		return global_position
	if _uses_paradise_formation_shooter():
		return _find_paradise_formation_target()
	if behavior == Behavior.DIVINE_ORACLE_PHANTOM:
		return _find_divine_oracle_target()
	if _uses_warped_positioning_ai() or _uses_hell_eye_positioning_ai():
		return _find_warped_positioning_target()
	var aim_dir := _get_player_aim_direction()
	var desired := _clamped_point(player.global_position + aim_dir * SHIELD_BEE_TARGET_DISTANCE)
	var distances := [SHIELD_BEE_TARGET_DISTANCE, 430.0, 360.0, 300.0, 240.0, 180.0, 130.0]
	var candidates: Array[Vector2] = []
	for distance in distances:
		candidates.append(_clamped_point(player.global_position + aim_dir * distance))
	for side in [-1.0, 1.0]:
		var side_dir := aim_dir.rotated(side * PI * 0.16)
		for distance in [420.0, 320.0, 240.0]:
			candidates.append(_clamped_point(player.global_position + side_dir * distance))
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) > 2.0:
			continue
		if _path_blocked_by_obstacle(player.global_position, candidate):
			continue
		return candidate
	var fallback := _clamped_point(desired)
	for distance in distances:
		var candidate := _push_out_from_obstacles(_clamped_point(player.global_position + aim_dir * distance))
		if candidate.distance_to(player.global_position) >= 90.0:
			fallback = candidate
			break
	return fallback


func _find_divine_assassin_back_positioning_target() -> Vector2:
	if not player:
		return global_position
	var aim_dir := _get_player_aim_direction()
	var dir := -aim_dir
	var distance := maxf(120.0, detection_range * PARADISE_FORMATION_DISTANCE_MULT)
	var base := _clamped_point(player.global_position + dir * distance)
	var tangent := Vector2(-dir.y, dir.x)
	var candidates: Array[Vector2] = [base]
	for offset in [-180.0, 180.0, -300.0, 300.0]:
		candidates.append(_clamped_point(base + tangent * offset))
	for i in range(PARADISE_FORMATION_RANDOM_ATTEMPTS):
		var random_offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(PARADISE_FORMATION_RANDOM_OFFSET_MIN, PARADISE_FORMATION_RANDOM_OFFSET_MAX)
		candidates.append(_clamped_point(base + random_offset))
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) > 2.0:
			continue
		if _path_blocked_by_obstacle(player.global_position, pushed):
			continue
		if _is_formation_target_occupied(pushed):
			continue
		return pushed
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) <= 2.0 and not _is_formation_target_occupied(pushed):
			return pushed
	return _push_out_from_obstacles(base)


func _update_divine_assassin_cooldown_positioning(delta: float) -> void:
	if not player:
		return
	_shield_bee_repath_timer -= delta
	if _shield_bee_target == Vector2.ZERO or _shield_bee_repath_timer <= 0.0:
		if GameManager.should_defer_work("DesignedEnemy.divine_assassin_repath"):
			_shield_bee_repath_timer = _shield_bee_repath_retry_delay()
			return
		_shield_bee_target = _find_divine_assassin_back_positioning_target()
		_shield_bee_path_avoid_player = true
		var next_path := _build_positioning_path(global_position, _shield_bee_target, _shield_bee_path_avoid_player)
		if next_path.is_empty():
			_shield_bee_repath_timer = _shield_bee_repath_retry_delay()
			return
		_shield_bee_path = next_path
		_shield_bee_path_index = 0
		_shield_bee_repath_timer = SHIELD_BEE_REPATH_INTERVAL + randf_range(0.0, SHIELD_BEE_REPATH_INTERVAL * 0.35)
		_shield_bee_repath_failures = 0
		_shield_bee_last_progress_position = global_position
		_shield_bee_stuck_timer = 0.0
	_shield_bee_path_index = _advance_visible_obstacle_path_waypoint(_shield_bee_path, _shield_bee_path_index, global_position, _shield_bee_path_avoid_player)
	if _shield_bee_path_index < _shield_bee_path.size() - 1 and _has_clear_obstacle_path(global_position, _shield_bee_target) and (not _shield_bee_path_avoid_player or not _segment_near_player(global_position, _shield_bee_target)):
		_shield_bee_path = [global_position, _shield_bee_target]
		_shield_bee_path_index = 1
	var waypoint := _shield_bee_next_waypoint()
	var to_waypoint := waypoint - global_position
	if to_waypoint.length() > 6.0:
		var move_dir := to_waypoint.normalized()
		var step := minf(move_speed * delta, to_waypoint.length())
		global_position += move_dir * step
		var pushed := _push_out_from_obstacles(global_position)
		if pushed.distance_to(global_position) > 0.5:
			global_position = pushed
			_shield_bee_target = Vector2.ZERO
		elif _shield_bee_path_index < _shield_bee_path.size() and global_position.distance_to(waypoint) <= OBSTACLE_PATH_REACHED_DISTANCE:
			_shield_bee_path_index += 1
		_update_shield_bee_path_progress(delta)
		_smooth_face_direction(move_dir, delta, turn_speed)
	else:
		if _shield_bee_path_index < _shield_bee_path.size():
			_shield_bee_path_index += 1
		_update_shield_bee_path_progress(delta)
		_smooth_face_direction(player.global_position - global_position, delta, turn_speed * 0.7)
	source_position = global_position
	path_target = _shield_bee_target


func _find_paradise_formation_target() -> Vector2:
	if behavior == Behavior.PARADISE_CALIBRATOR:
		return _find_calibrator_formation_target()
	var formation_dir := _get_paradise_formation_direction()
	var distance := maxf(120.0, detection_range * _get_paradise_formation_distance_mult())
	var base := _clamped_point(player.global_position + formation_dir * distance)
	var tangent := Vector2(-formation_dir.y, formation_dir.x)
	var candidates: Array[Vector2] = [base]
	for offset in [-180.0, 180.0, -300.0, 300.0]:
		candidates.append(_clamped_point(base + tangent * offset))
	for i in range(PARADISE_FORMATION_RANDOM_ATTEMPTS):
		var random_offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(PARADISE_FORMATION_RANDOM_OFFSET_MIN, PARADISE_FORMATION_RANDOM_OFFSET_MAX)
		candidates.append(_clamped_point(base + random_offset))
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) > 2.0:
			continue
		if _path_blocked_by_obstacle(player.global_position, pushed):
			continue
		if _is_formation_target_occupied(pushed):
			continue
		return pushed
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) > 2.0:
			continue
		if _is_formation_target_occupied(pushed):
			continue
		return pushed
	return _push_out_from_obstacles(base)


func _find_warped_positioning_target() -> Vector2:
	var aim_dir := _get_player_aim_direction()
	var use_front := behavior == Behavior.WARPED_MICRO_CORE
	var distance_mult := WARPED_FRONT_DISTANCE_MULT if use_front else WARPED_BACK_DISTANCE_MULT
	var dir := aim_dir if use_front else -aim_dir
	var distance := maxf(120.0, detection_range * distance_mult)
	var base := _clamped_point(player.global_position + dir * distance)
	var tangent := Vector2(-dir.y, dir.x)
	var candidates: Array[Vector2] = [base]
	for offset in [-160.0, 160.0, -280.0, 280.0]:
		candidates.append(_clamped_point(base + tangent * offset))
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) > 2.0:
			continue
		if _path_blocked_by_obstacle(player.global_position, pushed):
			continue
		if _is_formation_target_occupied(pushed):
			continue
		return pushed
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) <= 2.0 and not _is_formation_target_occupied(pushed):
			return pushed
	return _push_out_from_obstacles(base)


func _find_calibrator_formation_target() -> Vector2:
	var distance := maxf(120.0, detection_range * PARADISE_CALIBRATOR_DISTANCE_MULT)
	var from_player := global_position - player.global_position
	if from_player.length() <= 1.0:
		from_player = -_get_player_aim_direction()
	var radial := from_player.normalized()
	var aim_dir := _get_player_aim_direction()
	var aim_to_enemy := aim_dir.dot(radial) > 0.82
	var tangent := Vector2(-radial.y, radial.x)
	if aim_to_enemy:
		var side_a := _clamped_point(player.global_position + (radial + tangent * 0.55 * _calibrator_dodge_side).normalized() * distance)
		var side_b := _clamped_point(player.global_position + (radial - tangent * 0.55 * _calibrator_dodge_side).normalized() * distance)
		var score_a := side_a.distance_to(global_position)
		var score_b := side_b.distance_to(global_position)
		_calibrator_dodge_side = _calibrator_dodge_side if score_a >= score_b else -_calibrator_dodge_side
	var preferred_radial := (radial + tangent * (0.75 * _calibrator_dodge_side if aim_to_enemy else 0.0)).normalized()
	var candidates: Array[Vector2] = []
	for side in [0.0, 0.35, -0.35, 0.7, -0.7, 1.1, -1.1]:
		candidates.append(_clamped_point(player.global_position + preferred_radial.rotated(side) * distance))
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) > 2.0:
			continue
		if _path_blocked_by_obstacle(player.global_position, pushed):
			continue
		if _is_formation_target_occupied(pushed):
			continue
		return pushed
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) > 2.0:
			continue
		if _is_formation_target_occupied(pushed):
			continue
		return pushed
	return _push_out_from_obstacles(_clamped_point(player.global_position + preferred_radial * distance))


func _get_paradise_formation_direction() -> Vector2:
	var aim_dir := _get_player_aim_direction()
	match behavior:
		Behavior.PARADISE_PATROL:
			return aim_dir.rotated(PI * 0.5).normalized()
		Behavior.WARPED_REFRACTION_SHOOTER, Behavior.WARPED_COLLAPSE_BEACON:
			return aim_dir.rotated(PI * 0.5).normalized()
		Behavior.DIVINE_BLINK_BEACON:
			return aim_dir.rotated(PI * 0.5).normalized()
		Behavior.PARADISE_ARC_SCATTER:
			return aim_dir.rotated(-PI * 0.5).normalized()
		Behavior.PARADISE_RAIL_CHAIN:
			return -aim_dir
		Behavior.PARADISE_CALIBRATOR:
			return -aim_dir
		Behavior.PARADISE_SANCTUM_SUPPRESSOR:
			var to_enemy := global_position - player.global_position
			if to_enemy.length() > 0.01:
				return to_enemy.normalized()
			return aim_dir.rotated(PI * 0.5).normalized()
	return aim_dir


func _get_paradise_formation_distance_mult() -> float:
	match behavior:
		Behavior.PARADISE_CALIBRATOR:
			return PARADISE_CALIBRATOR_DISTANCE_MULT
		Behavior.PARADISE_SANCTUM_SUPPRESSOR:
			return PARADISE_SANCTUM_DISTANCE_MULT
		Behavior.WARPED_REFRACTION_SHOOTER, Behavior.WARPED_COLLAPSE_BEACON:
			return PARADISE_FORMATION_DISTANCE_MULT
		Behavior.DIVINE_BLINK_BEACON:
			return PARADISE_FORMATION_DISTANCE_MULT
	return PARADISE_FORMATION_DISTANCE_MULT


func _is_formation_target_occupied(candidate: Vector2) -> bool:
	var own_radius := get_formation_avoidance_radius()
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if node == self or not is_instance_valid(node) or node.is_queued_for_deletion() or not node is Node2D:
			continue
		var other := node as Node2D
		var clearance := own_radius + PARADISE_FORMATION_ENEMY_CLEARANCE
		if node.has_method("get_formation_avoidance_radius"):
			clearance = own_radius + float(node.call("get_formation_avoidance_radius")) + 18.0
		if other.global_position.distance_to(candidate) < clearance:
			return true
	return false


func get_formation_avoidance_radius() -> float:
	return maxf(body_size.x, body_size.y) * 0.55


func _update_calibrator_recoil(delta: float) -> void:
	if _calibrator_recoil_velocity == Vector2.ZERO:
		return
	global_position += _calibrator_recoil_velocity * delta
	global_position = _push_out_from_obstacles(_clamped_point(global_position))
	_calibrator_recoil_velocity = _calibrator_recoil_velocity.move_toward(Vector2.ZERO, maxf(_calibrator_recoil_velocity.length(), 1.0) * CALIBRATOR_RECOIL_DECAY * delta)


func _update_warped_spin(delta: float) -> void:
	if not _uses_warped_spin():
		return
	var target := WARPED_ALERT_SPIN_SPEED if _ai_alert else WARPED_IDLE_SPIN_SPEED
	_warped_spin_speed = move_toward(_warped_spin_speed, target, WARPED_SPIN_ACCEL * delta)
	rotation += _warped_spin_speed * delta


func _update_warped_fields(delta: float) -> void:
	if _uses_warped_attract_field():
		_apply_warped_projectile_field(delta, true)
	elif _uses_warped_repulse_field():
		_apply_warped_projectile_field(delta, false)
	if _uses_warped_lightning():
		_update_warped_lightning(delta)


func _apply_warped_projectile_field(delta: float, attract: bool) -> void:
	var radius := detection_range * WARPED_FORCE_FIELD_RANGE_MULT
	for projectile in get_tree().get_nodes_in_group(&"force_field_projectiles"):
		if not is_instance_valid(projectile) or projectile.is_queued_for_deletion() or not projectile is Node2D:
			continue
		var p := projectile as Node2D
		var to_center := global_position - p.global_position
		var distance := to_center.length()
		if distance <= 1.0 or distance > radius:
			continue
		var strength := WARPED_FORCE_FIELD_ACCEL * (1.0 - distance / radius)
		var accel := to_center.normalized() * strength
		if not attract:
			accel = -accel
		if projectile.has_method("apply_force_field"):
			projectile.call("apply_force_field", accel, delta)


func _update_warped_lightning(delta: float) -> void:
	_warped_lightning_phase += delta
	if not _is_warped_lightning_active():
		queue_redraw()
		return
	if player.has_method("apply_slow"):
		player.call("apply_slow", WARPED_LIGHTNING_SLOW_MULT, WARPED_LIGHTNING_SLOW_REFRESH)
	if player.has_method("apply_direct_damage_over_time"):
		player.call("apply_direct_damage_over_time", WARPED_LIGHTNING_DAMAGE_PER_SECOND, delta)
	if player.has_method("apply_warped_lightning_effect"):
		player.call("apply_warped_lightning_effect", WARPED_LIGHTNING_SLOW_REFRESH)
	queue_redraw()


func _is_warped_lightning_active() -> bool:
	return _ai_alert and player and global_position.distance_to(player.global_position) <= detection_range * WARPED_LIGHTNING_RANGE_MULT


func _update_warped_positioning_attack(delta: float) -> void:
	_update_warped_fields(delta)
	match behavior:
		Behavior.WARPED_MICRO_CORE:
			return
		Behavior.WARPED_ORBIT_DISRUPTOR:
			return
		Behavior.WARPED_DEFLECTION_MATRIX:
			return


func _find_divine_oracle_target() -> Vector2:
	var aim_dir := _get_player_aim_direction()
	var dir := -aim_dir
	var distance := maxf(120.0, detection_range * DIVINE_ORACLE_DISTANCE_MULT)
	var base := _clamped_point(player.global_position + dir * distance)
	var tangent := Vector2(-dir.y, dir.x)
	var candidates: Array[Vector2] = [base]
	for offset in [-180.0, 180.0, -300.0, 300.0]:
		candidates.append(_clamped_point(base + tangent * offset))
	for i in range(PARADISE_FORMATION_RANDOM_ATTEMPTS):
		candidates.append(_clamped_point(base + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(100.0, 260.0)))
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) > 2.0:
			continue
		if _path_blocked_by_obstacle(player.global_position, pushed):
			continue
		if _is_formation_target_occupied(pushed):
			continue
		return pushed
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) <= 2.0 and not _is_formation_target_occupied(pushed):
			return pushed
	return _push_out_from_obstacles(base)


func _update_divine_blink_beacon_attack(delta: float) -> void:
	if _attack_timer > 0.0:
		return
	if not _has_fast_line_to_player():
		return
	var to_player := player.global_position - global_position
	if to_player.length() <= 0.01:
		return
	_smooth_face_direction(to_player, delta, PARADISE_FORMATION_AIM_TURN_SPEED)
	if not _is_facing_direction(to_player, PARADISE_FORMATION_AIM_TOLERANCE):
		return
	_periodic_shot(move_cooldown, PARADISE_PATROL_BULLET_SPEED, damage)


func _update_hell_eye_positioning_attack(delta: float) -> void:
	_hell_eye_black_line_phase += delta
	match behavior:
		Behavior.HELLEYE_BLIND_MOTH:
			_update_hell_eye_blind_moth(delta)
		Behavior.HELLEYE_MISALIGNED_GAZER:
			_update_hell_eye_misalignment_link(delta, false)
		Behavior.HELLEYE_INVERT_PRIEST:
			_update_hell_eye_misalignment_link(delta, true)
	queue_redraw()


func _release_hell_eye_player_effects() -> void:
	if not player or not is_instance_valid(player):
		return
	if player.has_method("release_hell_eye_blind_link"):
		player.call("release_hell_eye_blind_link", self)
	if player.has_method("release_hell_eye_misalignment_link"):
		player.call("release_hell_eye_misalignment_link", self)


func _release_inactive_hell_eye_link() -> void:
	if not player or not is_instance_valid(player):
		return
	if behavior == Behavior.HELLEYE_MISALIGNED_GAZER or behavior == Behavior.HELLEYE_INVERT_PRIEST:
		if not _is_hell_eye_misalignment_line_active() and player.has_method("release_hell_eye_misalignment_link"):
			player.call("release_hell_eye_misalignment_link", self)


func _clear_hell_eye_visuals() -> void:
	_clear_inverted_moth_phantom()
	_clear_horizon_phantoms()


func _clear_inverted_moth_phantom() -> void:
	if is_instance_valid(_hell_eye_inverted_moth_phantom):
		_hell_eye_inverted_moth_phantom.queue_free()
	_hell_eye_inverted_moth_phantom = null
	_hell_eye_inverted_moth_phantom_offset = Vector2.ZERO
	var own_sprite := get_node_or_null("Sprite2D") as Sprite2D
	if own_sprite:
		own_sprite.modulate.a = 1.0


func _update_inverted_moth_phantom() -> void:
	if not _ai_alert or not player:
		_clear_inverted_moth_phantom()
		return
	var own_sprite := get_node_or_null("Sprite2D") as Sprite2D
	if not own_sprite or not own_sprite.texture:
		return
	own_sprite.modulate.a = HELLEYE_INVERTED_MOTH_ALPHA
	if not is_instance_valid(_hell_eye_inverted_moth_phantom):
		_hell_eye_inverted_moth_phantom = Sprite2D.new()
		_hell_eye_inverted_moth_phantom.name = "HellEyeInvertedMothPhantom"
		_hell_eye_inverted_moth_phantom.texture = own_sprite.texture
		_hell_eye_inverted_moth_phantom.centered = own_sprite.centered
		_hell_eye_inverted_moth_phantom.region_enabled = own_sprite.region_enabled
		_hell_eye_inverted_moth_phantom.region_rect = own_sprite.region_rect
		_hell_eye_inverted_moth_phantom.scale = own_sprite.scale
		_hell_eye_inverted_moth_phantom.modulate = Color(1.0, 1.0, 1.0, 0.78)
		_hell_eye_inverted_moth_phantom.z_index = z_index - 1
		_get_effect_parent().add_child(_hell_eye_inverted_moth_phantom)
		_hell_eye_inverted_moth_phantom_offset = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(30.0, 50.0)
	_hell_eye_inverted_moth_phantom.global_position = global_position + _hell_eye_inverted_moth_phantom_offset
	var face_dir := player.global_position - _hell_eye_inverted_moth_phantom.global_position
	if face_dir.length() > 0.01:
		_hell_eye_inverted_moth_phantom.global_rotation = face_dir.angle() + PI / 2.0


func _clear_horizon_phantoms() -> void:
	for phantom in _hell_eye_horizon_phantoms:
		if is_instance_valid(phantom):
			phantom.queue_free()
	_hell_eye_horizon_phantoms.clear()
	_hell_eye_horizon_phantom_data.clear()
	_hell_eye_horizon_warning_locked = false
	_hell_eye_horizon_return_active = false
	_hell_eye_horizon_return_elapsed = 0.0
	_hell_eye_horizon_visual_texture = null
	_hell_eye_horizon_visual_modulate = Color.TRANSPARENT


func _prepare_horizon_phantom_charge_paths() -> void:
	_hell_eye_horizon_phantom_data.clear()
	_hell_eye_horizon_warning_locked = true
	_hell_eye_horizon_return_active = false
	_hell_eye_horizon_return_elapsed = 0.0
	if not player:
		return
	var locked_player_position := player.global_position
	var relative := global_position - player.global_position
	if relative.length() <= 0.01:
		relative = Vector2.RIGHT * maxf(body_size.x, body_size.y)
	for i in range(HELLEYE_HORIZON_PHANTOM_COUNT):
		var desired_start := locked_player_position + relative.rotated(float(i + 1) * HELLEYE_HORIZON_PHANTOM_ANGLE_STEP)
		var start := _get_existing_horizon_phantom_position(i, desired_start)
		var charge_dir := locked_player_position - start
		if charge_dir.length() <= 0.01:
			charge_dir = -relative
		if charge_dir.length() <= 0.01:
			charge_dir = Vector2.DOWN
		charge_dir = charge_dir.normalized()
		var distance_to_lock := start.distance_to(locked_player_position)
		var target := _clamped_point(locked_player_position + charge_dir * maxf(distance_to_lock + HELLEYE_HORIZON_PHANTOM_CHARGE_OVERSHOOT, HELLEYE_HORIZON_PHANTOM_CHARGE_OVERSHOOT))
		var retreat := _push_out_from_obstacles(_clamped_point(start - charge_dir * HELLEYE_HORIZON_PHANTOM_RETREAT_DISTANCE))
		_hell_eye_horizon_phantom_data.append({
			"position": start,
			"warning_from": start,
			"warning_to": target,
			"retreat_start": start,
			"retreat_target": retreat,
			"charge_start": retreat,
			"charge_target": target,
			"locked_player_position": locked_player_position,
			"hit_player": false,
		})


func _get_existing_horizon_phantom_position(index: int, fallback: Vector2) -> Vector2:
	if index >= 0 and index < _hell_eye_horizon_phantoms.size():
		var phantom := _hell_eye_horizon_phantoms[index]
		if is_instance_valid(phantom):
			return phantom.global_position
	if index >= 0 and index < _hell_eye_horizon_phantom_data.size():
		var data := _hell_eye_horizon_phantom_data[index]
		var stored_position := data.get("position", Vector2.INF) as Vector2
		if stored_position != Vector2.INF:
			return stored_position
	return fallback


func _update_horizon_phantoms() -> void:
	if not _ai_alert or not player:
		_clear_horizon_phantoms()
		return
	var own_sprite := get_node_or_null("Sprite2D") as Sprite2D
	if not own_sprite or not own_sprite.texture:
		return
	if _hell_eye_horizon_warning_locked and _hell_eye_horizon_phantom_data.is_empty():
		_prepare_horizon_phantom_charge_paths()
	var visuals_need_update := false
	while _hell_eye_horizon_phantoms.size() > HELLEYE_HORIZON_PHANTOM_COUNT:
		var extra: Sprite2D = _hell_eye_horizon_phantoms.pop_back()
		if is_instance_valid(extra):
			extra.queue_free()
		visuals_need_update = true
	while _hell_eye_horizon_phantoms.size() < HELLEYE_HORIZON_PHANTOM_COUNT:
		var phantom := Sprite2D.new()
		phantom.name = "HellEyeHorizonPhantom"
		phantom.texture = own_sprite.texture
		phantom.centered = own_sprite.centered
		phantom.region_enabled = own_sprite.region_enabled
		phantom.region_rect = own_sprite.region_rect
		phantom.scale = own_sprite.scale
		phantom.modulate = _get_horizon_phantom_modulate(own_sprite)
		phantom.z_index = own_sprite.z_index
		phantom.material = _create_horizon_phantom_material()
		_get_effect_parent().add_child(phantom)
		_hell_eye_horizon_phantoms.append(phantom)
		visuals_need_update = true
	if not visuals_need_update and _horizon_phantom_visuals_need_update(own_sprite):
		visuals_need_update = true
	if visuals_need_update:
		_update_horizon_phantom_visuals(own_sprite)
	var relative := global_position - player.global_position
	if relative.length() <= 0.01:
		relative = Vector2.RIGHT * maxf(body_size.x, body_size.y)
	if _hell_eye_horizon_return_active:
		_update_horizon_phantom_return(get_process_delta_time(), relative)
	for i in range(_hell_eye_horizon_phantoms.size()):
		var phantom := _hell_eye_horizon_phantoms[i]
		if not is_instance_valid(phantom):
			continue
		if phantom.material == null:
			phantom.material = _create_horizon_phantom_material()
		phantom.rotation = own_sprite.rotation
		phantom.global_position = _get_horizon_phantom_position(i, relative)
		var face_target := _get_horizon_phantom_face_target(i)
		var face_dir := face_target - phantom.global_position
		if face_dir.length() > 0.01:
			phantom.global_rotation = face_dir.angle() + PI / 2.0 + own_sprite.rotation


func _create_horizon_phantom_material() -> ShaderMaterial:
	if _horizon_phantom_material == null:
		_horizon_phantom_material = ShaderMaterial.new()
		_horizon_phantom_material.shader = HORIZON_PHANTOM_DISTORT_SHADER
		_horizon_phantom_material.set_shader_parameter("strength", 0.018)
		_horizon_phantom_material.set_shader_parameter("wave_scale", 22.0)
		_horizon_phantom_material.set_shader_parameter("wave_speed", 4.8)
		_horizon_phantom_material.set_shader_parameter("tint_amount", 0.18)
	return _horizon_phantom_material


func _update_horizon_phantom_visuals(own_sprite: Sprite2D) -> void:
	var modulate := _get_horizon_phantom_modulate(own_sprite)
	for phantom in _hell_eye_horizon_phantoms:
		if not is_instance_valid(phantom):
			continue
		phantom.texture = own_sprite.texture
		phantom.centered = own_sprite.centered
		phantom.region_enabled = own_sprite.region_enabled
		phantom.region_rect = own_sprite.region_rect
		phantom.scale = own_sprite.scale
		phantom.modulate = modulate
		phantom.z_index = own_sprite.z_index
		if phantom.material == null:
			phantom.material = _create_horizon_phantom_material()
	_store_horizon_phantom_visual_state(own_sprite)


func _horizon_phantom_visuals_need_update(own_sprite: Sprite2D) -> bool:
	var modulate := _get_horizon_phantom_modulate(own_sprite)
	return (
		_hell_eye_horizon_visual_texture != own_sprite.texture
		or _hell_eye_horizon_visual_centered != own_sprite.centered
		or _hell_eye_horizon_visual_region_enabled != own_sprite.region_enabled
		or _hell_eye_horizon_visual_region_rect != own_sprite.region_rect
		or _hell_eye_horizon_visual_scale != own_sprite.scale
		or _hell_eye_horizon_visual_modulate != modulate
		or _hell_eye_horizon_visual_z_index != own_sprite.z_index
	)


func _store_horizon_phantom_visual_state(own_sprite: Sprite2D) -> void:
	_hell_eye_horizon_visual_texture = own_sprite.texture
	_hell_eye_horizon_visual_centered = own_sprite.centered
	_hell_eye_horizon_visual_region_enabled = own_sprite.region_enabled
	_hell_eye_horizon_visual_region_rect = own_sprite.region_rect
	_hell_eye_horizon_visual_scale = own_sprite.scale
	_hell_eye_horizon_visual_modulate = _get_horizon_phantom_modulate(own_sprite)
	_hell_eye_horizon_visual_z_index = own_sprite.z_index


func _get_horizon_phantom_modulate(own_sprite: Sprite2D) -> Color:
	var color := own_sprite.modulate
	color.a *= 0.8
	return color


func _get_horizon_phantom_position(index: int, relative: Vector2) -> Vector2:
	if index >= 0 and index < _hell_eye_horizon_phantom_data.size():
		var data := _hell_eye_horizon_phantom_data[index]
		var stored_position := data.get("position", Vector2.INF) as Vector2
		if stored_position != Vector2.INF:
			return stored_position
	return player.global_position + relative.rotated(float(index + 1) * HELLEYE_HORIZON_PHANTOM_ANGLE_STEP)


func _get_horizon_phantom_face_target(index: int) -> Vector2:
	if index >= 0 and index < _hell_eye_horizon_phantom_data.size():
		var data := _hell_eye_horizon_phantom_data[index]
		return data.get("locked_player_position", player.global_position) as Vector2
	return player.global_position


func _update_horizon_phantom_retreat(retreat_t: float) -> void:
	if behavior != Behavior.HELLEYE_HORIZON_DEFLECTOR:
		return
	var eased_t := smoothstep(0.0, 1.0, retreat_t)
	for i in range(_hell_eye_horizon_phantom_data.size()):
		var data := _hell_eye_horizon_phantom_data[i]
		var start := data.get("retreat_start", Vector2.ZERO) as Vector2
		var target := data.get("retreat_target", start) as Vector2
		data["position"] = start.lerp(target, eased_t)
		_hell_eye_horizon_phantom_data[i] = data


func _update_horizon_phantom_charge(eased_t: float) -> void:
	if behavior != Behavior.HELLEYE_HORIZON_DEFLECTOR:
		return
	for i in range(_hell_eye_horizon_phantom_data.size()):
		var data := _hell_eye_horizon_phantom_data[i]
		var start := data.get("charge_start", data.get("position", Vector2.ZERO)) as Vector2
		var target := data.get("charge_target", start) as Vector2
		var pos := start.lerp(target, eased_t)
		data["position"] = pos
		_check_horizon_phantom_player_hit(data, pos)
		_hell_eye_horizon_phantom_data[i] = data


func _begin_horizon_phantom_return() -> void:
	if behavior != Behavior.HELLEYE_HORIZON_DEFLECTOR:
		return
	if not player or _hell_eye_horizon_phantom_data.is_empty():
		_clear_horizon_phantoms()
		return
	_hell_eye_horizon_warning_locked = false
	_hell_eye_horizon_return_active = true
	_hell_eye_horizon_return_elapsed = 0.0
	var relative := global_position - player.global_position
	if relative.length() <= 0.01:
		relative = Vector2.RIGHT * maxf(body_size.x, body_size.y)
	for i in range(_hell_eye_horizon_phantom_data.size()):
		var data := _hell_eye_horizon_phantom_data[i]
		var current_position := data.get("position", player.global_position) as Vector2
		data["return_start"] = current_position
		data["return_target"] = player.global_position + relative.rotated(float(i + 1) * HELLEYE_HORIZON_PHANTOM_ANGLE_STEP)
		_hell_eye_horizon_phantom_data[i] = data


func _update_horizon_phantom_return(delta: float, relative: Vector2) -> void:
	if not _hell_eye_horizon_return_active:
		return
	_hell_eye_horizon_return_elapsed += delta
	var t := clampf(_hell_eye_horizon_return_elapsed / HELLEYE_HORIZON_PHANTOM_RETURN_DURATION, 0.0, 1.0)
	var eased_t := 1.0 - pow(1.0 - t, 3.0)
	for i in range(_hell_eye_horizon_phantom_data.size()):
		var data := _hell_eye_horizon_phantom_data[i]
		var start := data.get("return_start", data.get("position", player.global_position)) as Vector2
		var target := player.global_position + relative.rotated(float(i + 1) * HELLEYE_HORIZON_PHANTOM_ANGLE_STEP)
		data["return_target"] = target
		data["position"] = start.lerp(target, eased_t)
		_hell_eye_horizon_phantom_data[i] = data
	if t >= 1.0:
		_hell_eye_horizon_return_active = false
		_hell_eye_horizon_return_elapsed = 0.0
		_hell_eye_horizon_phantom_data.clear()


func _check_horizon_phantom_player_hit(data: Dictionary, phantom_position: Vector2) -> void:
	if bool(data.get("hit_player", false)):
		return
	if not player or not is_instance_valid(player):
		return
	var player_radius := _get_player_visual_radius()
	var half := body_size * 0.5
	var delta := player.global_position - phantom_position
	if absf(delta.x) > half.x + player_radius or absf(delta.y) > half.y + player_radius:
		return
	if player.has_method("take_damage_from"):
		player.call("take_damage_from", self)
	data["hit_player"] = true


func _reset_divine_raider_side_shots() -> void:
	_divine_raider_side_shot_distance = 0.0
	_divine_raider_side_shot_next = randf_range(DIVINE_RAIDER_SIDE_SHOT_MIN_DISTANCE, DIVINE_RAIDER_SIDE_SHOT_MAX_DISTANCE)


func _update_divine_raider_side_shots(previous_position: Vector2, current_position: Vector2) -> void:
	var traveled := previous_position.distance_to(current_position)
	if traveled <= 0.0:
		return
	_divine_raider_side_shot_distance += traveled
	while _divine_raider_side_shot_distance >= _divine_raider_side_shot_next:
		_divine_raider_side_shot_distance -= _divine_raider_side_shot_next
		_divine_raider_side_shot_next = randf_range(DIVINE_RAIDER_SIDE_SHOT_MIN_DISTANCE, DIVINE_RAIDER_SIDE_SHOT_MAX_DISTANCE)
		_fire_divine_raider_side_shots()


func _fire_divine_raider_side_shots() -> void:
	var forward := _get_guard_charge_velocity().normalized()
	if forward.length() <= 0.01:
		forward = Vector2(0, -1).rotated(rotation)
	var left := forward.rotated(-PI * 0.5).normalized()
	var right := forward.rotated(PI * 0.5).normalized()
	_spawn_bullet(left, PARADISE_PATROL_BULLET_SPEED, DIVINE_RAIDER_SIDE_SHOT_DAMAGE)
	_spawn_bullet(right, PARADISE_PATROL_BULLET_SPEED, DIVINE_RAIDER_SIDE_SHOT_DAMAGE)


func _begin_divine_teleport(mode: int) -> void:
	if not player or _divine_teleport_phase != DIVINE_TELEPORT_NONE:
		return
	_divine_teleport_mode = mode
	_divine_teleport_phase = DIVINE_TELEPORT_FADE_OUT
	_divine_teleport_timer = 0.0
	_divine_teleport_warning_remaining = -1.0
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	if mode == DIVINE_TELEPORT_SERAPH_RETARGET and state == State.WARNING:
		_divine_teleport_warning_remaining = maxf(warning_timer, 0.0)
	_divine_teleport_target = _find_divine_teleport_target(mode)
	_apply_divine_teleport_visual(0.0)
	state = State.COOLDOWN
	cooldown_remaining = move_cooldown
	source_position = global_position
	path_target = global_position
	_obstacle_bounce_time = 0.0
	_obstacle_bounce_velocity = Vector2.ZERO
	queue_redraw()


func _update_divine_teleport(delta: float) -> bool:
	if _divine_teleport_phase == DIVINE_TELEPORT_NONE:
		return false
	_divine_teleport_timer += delta
	var t := clampf(_divine_teleport_timer / DIVINE_TELEPORT_FADE_DURATION, 0.0, 1.0)
	if _divine_teleport_phase == DIVINE_TELEPORT_FADE_OUT:
		_apply_divine_teleport_visual(t)
		if t >= 1.0:
			global_position = _divine_teleport_target
			source_position = global_position
			path_target = global_position
			_divine_teleport_timer = 0.0
			_divine_teleport_phase = DIVINE_TELEPORT_FADE_IN
			_apply_divine_teleport_visual(1.0)
		return true
	if _divine_teleport_phase == DIVINE_TELEPORT_FADE_IN:
		_apply_divine_teleport_visual(1.0 - t)
		if t >= 1.0:
			_finish_divine_teleport()
		return true
	return false


func _finish_divine_teleport() -> void:
	_restore_divine_teleport_visual()
	var mode := _divine_teleport_mode
	var preserved_warning := _divine_teleport_warning_remaining
	_divine_teleport_phase = DIVINE_TELEPORT_NONE
	_divine_teleport_mode = DIVINE_TELEPORT_NONE
	_divine_teleport_timer = 0.0
	_divine_teleport_warning_remaining = -1.0
	if not _ai_alert or not player:
		state = State.COOLDOWN
		cooldown_remaining = move_cooldown
		return
	if mode == DIVINE_TELEPORT_BLINK:
		state = State.COOLDOWN
		cooldown_remaining = minf(cooldown_remaining, 0.25)
		_shield_bee_repath_timer = 0.0
		return
	_prepare_shard_charge_path()
	source_position = global_position
	if mode == DIVINE_TELEPORT_SERAPH_RETARGET and preserved_warning >= 0.0:
		warning_timer = maxf(preserved_warning - DIVINE_TELEPORT_FADE_DURATION * 2.0, 0.0)
	else:
		warning_timer = _get_warning_duration()
	if warning_timer <= 0.0:
		_begin_move()
		state = State.MOVING
	else:
		state = State.WARNING
	queue_redraw()


func _cancel_divine_teleport() -> void:
	if _divine_teleport_phase == DIVINE_TELEPORT_NONE:
		return
	_restore_divine_teleport_visual()
	_divine_teleport_phase = DIVINE_TELEPORT_NONE
	_divine_teleport_mode = DIVINE_TELEPORT_NONE
	_divine_teleport_timer = 0.0
	_divine_teleport_warning_remaining = -1.0


func _apply_divine_teleport_visual(progress: float) -> void:
	var own_sprite := get_node_or_null("Sprite2D") as Sprite2D
	if not own_sprite:
		return
	if _divine_teleport_material == null:
		_divine_sprite_original_material = own_sprite.material
		_divine_sprite_original_modulate = own_sprite.modulate
		var shader := Shader.new()
		shader.code = DIVINE_TELEPORT_SHADER_CODE
		_divine_teleport_material = ShaderMaterial.new()
		_divine_teleport_material.shader = shader
		own_sprite.material = _divine_teleport_material
	var white_amount := sin(clampf(progress, 0.0, 1.0) * PI)
	_divine_teleport_material.set_shader_parameter("fade_alpha", clampf(1.0 - progress, 0.0, 1.0))
	_divine_teleport_material.set_shader_parameter("white_amount", white_amount)


func _restore_divine_teleport_visual() -> void:
	var own_sprite := get_node_or_null("Sprite2D") as Sprite2D
	if own_sprite:
		own_sprite.material = _divine_sprite_original_material
		own_sprite.modulate = _divine_sprite_original_modulate
	_divine_teleport_material = null


func _find_divine_teleport_target(mode: int) -> Vector2:
	if mode == DIVINE_TELEPORT_BLINK or mode == DIVINE_TELEPORT_SERAPH_RETARGET:
		return _find_divine_blink_target()
	return _find_divine_assassin_attack_position()


func _find_divine_blink_target() -> Vector2:
	if not player:
		return global_position
	var aim_dir := _get_player_aim_direction()
	var dir := -aim_dir
	var radius := maxf(120.0, detection_range * DIVINE_BLINK_DISTANCE_MULT)
	var base_angle := dir.angle()
	var candidates: Array[Vector2] = []
	for i in range(10):
		var angle := base_angle + randf_range(-0.45, 0.45)
		var dist := randf_range(radius * 0.82, radius)
		candidates.append(_clamped_point(player.global_position + Vector2.RIGHT.rotated(angle) * dist))
	var tangent := Vector2(-dir.y, dir.x)
	for offset in [-240.0, 240.0, -360.0, 360.0, -520.0, 520.0]:
		candidates.append(_clamped_point(player.global_position + dir * radius + tangent * offset))
	return _best_divine_teleport_candidate(candidates, true)


func _find_divine_assassin_attack_position() -> Vector2:
	if not player:
		return global_position
	var radius := maxf(140.0, detection_range * DIVINE_ASSASSIN_DISTANCE_MULT)
	var to_enemy := global_position - player.global_position
	var base_angle := to_enemy.angle() if to_enemy.length() > 1.0 else randf_range(0.0, TAU)
	var candidates: Array[Vector2] = []
	for i in range(24):
		var angle := base_angle + float(i) * TAU / 24.0 + randf_range(-0.08, 0.08)
		candidates.append(_clamped_point(player.global_position + Vector2.RIGHT.rotated(angle) * randf_range(radius * 0.55, radius)))
	for i in range(16):
		candidates.append(_clamped_point(player.global_position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(150.0, radius)))
	var best := _best_divine_teleport_candidate(candidates, true)
	if best != global_position:
		return best
	var closer_candidates: Array[Vector2] = []
	for distance_mult in [0.45, 0.32, 0.22]:
		for i in range(16):
			var angle := base_angle + float(i) * TAU / 16.0
			closer_candidates.append(_clamped_point(player.global_position + Vector2.RIGHT.rotated(angle) * radius * distance_mult))
	best = _best_divine_teleport_candidate(closer_candidates, true)
	if best != global_position:
		return best
	return _best_divine_teleport_candidate(candidates, false)


func _best_divine_teleport_candidate(candidates: Array[Vector2], require_clear_line_to_player: bool) -> Vector2:
	var tangent_fallback := global_position
	for candidate in candidates:
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) > 2.0:
			tangent_fallback = pushed
			continue
		if require_clear_line_to_player and _path_blocked_by_obstacle(pushed, player.global_position):
			tangent_fallback = pushed
			continue
		if _is_formation_target_occupied(pushed):
			tangent_fallback = pushed
			continue
		return pushed
	if tangent_fallback != global_position:
		return _push_out_from_obstacles(_clamped_point(tangent_fallback))
	return _push_out_from_obstacles(_clamped_point(global_position))


func _get_warning_duration() -> float:
	if behavior == Behavior.DIVINE_BROKEN_WING_ASSASSIN or behavior == Behavior.DIVINE_SERAPH_HUNTER:
		return DIVINE_ASSASSIN_WARNING_DURATION
	return WARNING_DURATION


func _uses_default_warning_draw() -> bool:
	return not (behavior == Behavior.DIVINE_BROKEN_WING_ASSASSIN or behavior == Behavior.DIVINE_SERAPH_HUNTER)


func _update_hell_eye_blind_moth(delta: float) -> void:
	if not player:
		return
	if _hell_eye_blind_latched or global_position.distance_to(player.global_position) <= detection_range * HELLEYE_BLIND_LINK_RANGE_MULT:
		_hell_eye_blind_latched = true
		if player.has_method("apply_hell_eye_blind_link"):
			player.call("apply_hell_eye_blind_link", self, HELLEYE_BLIND_LINK_DAMAGE_PER_SECOND, delta)


func _update_hell_eye_misalignment_link(delta: float, priest: bool) -> void:
	if not player:
		return
	if not _is_hell_eye_misalignment_line_active():
		return
	var upgrade := false
	if priest and player.has_method("is_hell_eye_disturbed"):
		upgrade = bool(player.call("is_hell_eye_disturbed"))
	if player.has_method("refresh_hell_eye_misalignment_link"):
		player.call("refresh_hell_eye_misalignment_link", self, delta, upgrade)


func _is_hell_eye_black_link_active() -> bool:
	if not _ai_alert or not player:
		return false
	if behavior == Behavior.HELLEYE_BLIND_MOTH:
		return _hell_eye_blind_latched or global_position.distance_to(player.global_position) <= detection_range * HELLEYE_BLIND_LINK_RANGE_MULT
	if behavior == Behavior.HELLEYE_MISALIGNED_GAZER or behavior == Behavior.HELLEYE_INVERT_PRIEST:
		return _is_hell_eye_misalignment_line_active()
	return false


func _is_hell_eye_misalignment_line_active() -> bool:
	return _ai_alert and player and global_position.distance_to(player.global_position) <= detection_range * HELLEYE_MISALIGN_LINK_RANGE_MULT and _has_clear_obstacle_path(global_position, player.global_position)


func _spawn_warped_micro_core_death_ring() -> void:
	_spawn_ring(randi_range(8, 12), damage, 300.0)


func _update_calibrator_sniper(delta: float) -> void:
	var to_player := player.global_position - global_position
	if to_player.length() > 0.01:
		_smooth_face_direction(to_player, delta, PARADISE_FORMATION_AIM_TURN_SPEED)
	_update_calibrator_ray_cache(delta)
	if _calibrator_shot_timer <= 0.0 and _calibrator_warning_timer <= 0.0:
		_calibrator_shot_timer = randf_range(CALIBRATOR_SHOT_MIN_INTERVAL, CALIBRATOR_SHOT_MAX_INTERVAL)
	_calibrator_shot_timer = maxf(_calibrator_shot_timer - delta, 0.0)
	if _calibrator_warning_timer > 0.0:
		if to_player.length() > 0.01:
			_calibrator_locked_dir = to_player.normalized()
		_calibrator_warning_timer = maxf(_calibrator_warning_timer - delta, 0.0)
		if _calibrator_warning_timer <= 0.0:
			_fire_calibrator_sniper()
			_calibrator_shot_timer = randf_range(CALIBRATOR_SHOT_MIN_INTERVAL, CALIBRATOR_SHOT_MAX_INTERVAL)
		queue_redraw()
		return
	if _calibrator_shot_timer <= CALIBRATOR_WARNING_DURATION:
		_calibrator_warning_timer = CALIBRATOR_WARNING_DURATION
		_calibrator_locked_dir = player.global_position - global_position
		if _calibrator_locked_dir.length() <= 0.01:
			_calibrator_locked_dir = Vector2.DOWN
		_calibrator_locked_dir = _calibrator_locked_dir.normalized()
	queue_redraw()


func _update_calibrator_ray_cache(delta: float) -> void:
	_calibrator_ray_timer -= delta
	if _calibrator_ray_timer > 0.0 and _calibrator_ray_points.size() >= 2 and _calibrator_warning_timer <= 0.0:
		return
	_calibrator_ray_timer = CALIBRATOR_RAY_UPDATE_INTERVAL
	var ray := _get_calibrator_ray()
	_calibrator_ray_points = PackedVector2Array()
	if ray.size() >= 2:
		_calibrator_ray_points.append(ray[0])
		_calibrator_ray_points.append(ray[1])


func _fire_calibrator_sniper() -> void:
	var dir := _calibrator_locked_dir
	if dir.length() <= 0.01 and player:
		dir = player.global_position - global_position
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	dir = dir.normalized()
	_spawn_bullet(dir, CALIBRATOR_BULLET_SPEED, CALIBRATOR_BULLET_DAMAGE, 1.35)
	_play_sfx(CALIBRATOR_SHOT_SOUND, -2.0)
	_calibrator_recoil_velocity = -dir * CALIBRATOR_RECOIL_SPEED
	_calibrator_locked_dir = Vector2.ZERO
	queue_redraw()


func _get_calibrator_ray() -> Array[Vector2]:
	if not player:
		return []
	var dir := player.global_position - global_position
	if dir.length() <= 0.01:
		return []
	dir = dir.normalized()
	var start := global_position + dir * maxf(body_size.x, body_size.y) * 0.12
	var end := start + dir * maxf(screen_size.x, screen_size.y) * CALIBRATOR_RAY_LENGTH_MULT
	return [start, end]


func _update_sanctum_spin_attack(delta: float) -> void:
	var distance := global_position.distance_to(player.global_position)
	if _sanctum_spin_active:
		if distance > detection_range * SANCTUM_SPIN_EXIT_DISTANCE_MULT:
			_sanctum_spin_active = false
	else:
		if distance <= detection_range * SANCTUM_SPIN_ENTER_DISTANCE_MULT:
			_sanctum_spin_active = true
	if _sanctum_spin_active:
		_sanctum_spin_speed = minf(_sanctum_spin_speed + SANCTUM_SPIN_MAX_SPEED / SANCTUM_SPIN_ACCEL_TIME * delta, SANCTUM_SPIN_MAX_SPEED)
	else:
		_sanctum_spin_speed = maxf(_sanctum_spin_speed - SANCTUM_SPIN_MAX_SPEED / SANCTUM_SPIN_DECEL_TIME * delta, 0.0)
	if _sanctum_spin_speed > 0.0:
		rotation += _sanctum_spin_speed * delta
	if _sanctum_spin_speed >= SANCTUM_SPIN_MAX_SPEED * 0.995:
		_sanctum_spin_fire_timer -= delta
		while _sanctum_spin_fire_timer <= 0.0:
			_fire_sanctum_cross_burst()
			_sanctum_spin_fire_timer += SANCTUM_SPIN_FIRE_INTERVAL
	else:
		_sanctum_spin_fire_timer = SANCTUM_SPIN_FIRE_INTERVAL


func _fire_sanctum_cross_burst() -> void:
	_spawn_bullet(Vector2.LEFT.rotated(rotation), SANCTUM_SPIN_BULLET_SPEED, SANCTUM_SPIN_BULLET_DAMAGE, SANCTUM_SPIN_BULLET_SCALE)
	_spawn_bullet(Vector2.RIGHT.rotated(rotation), SANCTUM_SPIN_BULLET_SPEED, SANCTUM_SPIN_BULLET_DAMAGE, SANCTUM_SPIN_BULLET_SCALE)
	_spawn_bullet(Vector2.UP.rotated(rotation), SANCTUM_SPIN_BULLET_SPEED, SANCTUM_SPIN_BULLET_DAMAGE, SANCTUM_SPIN_BULLET_SCALE)
	_spawn_bullet(Vector2.DOWN.rotated(rotation), SANCTUM_SPIN_BULLET_SPEED, SANCTUM_SPIN_BULLET_DAMAGE, SANCTUM_SPIN_BULLET_SCALE)


func _update_warped_refraction_shooter(delta: float) -> void:
	if _attack_timer > 0.0:
		return
	if not _has_fast_line_to_player():
		return
	var to_player := player.global_position - global_position
	if to_player.length() <= 0.01:
		return
	_smooth_face_direction(to_player, delta, PARADISE_FORMATION_AIM_TURN_SPEED)
	if not _is_facing_direction(to_player, PARADISE_FORMATION_AIM_TOLERANCE):
		return
	_attack_timer = move_cooldown
	_spawn_reflect_bullet(to_player.normalized(), WARPED_REFRACTION_BULLET_SPEED, damage)


func _update_warped_collapse_beacon(delta: float) -> void:
	if _attack_timer > 0.0:
		return
	if not _has_fast_line_to_player():
		return
	var to_player := player.global_position - global_position
	if to_player.length() <= 0.01:
		return
	_attack_timer = move_cooldown
	_fire_warped_collapse_shotgun()
	if randf() < 0.5:
		_fire_warped_collapse_followup()


func _fire_warped_collapse_followup() -> void:
	var generation := _explore_pool_generation
	await get_tree().create_timer(0.5).timeout
	# await 期间本体可能被回收进池并复用为其他敌人，必须校验行为与池代际未变
	if not is_instance_valid(self) or behavior != Behavior.WARPED_COLLAPSE_BEACON:
		return
	if _explore_pool_generation != generation:
		return
	if _ai_alert and player:
		_fire_warped_collapse_shotgun()


func _fire_warped_collapse_shotgun() -> void:
	if not player:
		return
	var base := (player.global_position - global_position).angle()
	var count := randi_range(WARPED_COLLAPSE_SHOTGUN_MIN_COUNT, WARPED_COLLAPSE_SHOTGUN_MAX_COUNT)
	var arc := randf_range(WARPED_COLLAPSE_SHOTGUN_MIN_ARC, WARPED_COLLAPSE_SHOTGUN_MAX_ARC)
	for i in count:
		var t := 0.0 if count == 1 else float(i) / float(count - 1)
		var dir := Vector2.RIGHT.rotated(base - arc * 0.5 + arc * t)
		_spawn_reflect_bullet(dir, WARPED_REFRACTION_BULLET_SPEED, damage)


func _update_paradise_formation_attack(delta: float) -> void:
	if not player:
		return
	if behavior == Behavior.DIVINE_BLINK_BEACON:
		_update_divine_blink_beacon_attack(delta)
		return
	if behavior == Behavior.WARPED_REFRACTION_SHOOTER:
		_update_warped_refraction_shooter(delta)
		return
	if behavior == Behavior.WARPED_COLLAPSE_BEACON:
		_update_warped_collapse_beacon(delta)
		return
	match behavior:
		Behavior.PARADISE_CALIBRATOR:
			_update_calibrator_sniper(delta)
			return
		Behavior.PARADISE_SANCTUM_SUPPRESSOR:
			_update_sanctum_spin_attack(delta)
			return
	var burst_pending := behavior == Behavior.PARADISE_RAIL_CHAIN and _burst_left > 0
	if not burst_pending and _attack_timer > 0.0:
		return
	if not _has_fast_line_to_player():
		return
	var to_player := player.global_position - global_position
	if to_player.length() <= 0.01:
		return
	_smooth_face_direction(to_player, delta, PARADISE_FORMATION_AIM_TURN_SPEED)
	if not _is_facing_direction(to_player, PARADISE_FORMATION_AIM_TOLERANCE):
		return
	if burst_pending:
		_burst_shot(move_cooldown, 3, 0.16, PARADISE_RAIL_CHAIN_BULLET_SPEED, damage)
		return
	match behavior:
		Behavior.PARADISE_PATROL:
			_periodic_shot(move_cooldown, PARADISE_PATROL_BULLET_SPEED, damage)
		Behavior.PARADISE_ARC_SCATTER:
			_periodic_spread(move_cooldown, 7, PI / 2.8, PARADISE_ARC_SCATTER_BULLET_SPEED, damage)
		Behavior.PARADISE_RAIL_CHAIN:
			_burst_shot(move_cooldown, 3, 0.16, PARADISE_RAIL_CHAIN_BULLET_SPEED, damage)


func _update_divine_oracle_phantoms(delta: float) -> void:
	_prune_divine_oracle_phantoms()
	if not _ai_alert or not player:
		_clear_divine_oracle_phantoms()
		return
	_divine_oracle_frame_side_shots = 0
	_divine_oracle_spawn_timer -= delta
	if _divine_oracle_spawn_timer <= 0.0:
		if _divine_oracle_phantom_data.size() < DIVINE_ORACLE_PHANTOM_MAX_ACTIVE:
			_spawn_divine_oracle_phantom_raider()
		_divine_oracle_spawn_timer = randf_range(DIVINE_ORACLE_PHANTOM_MIN_INTERVAL, DIVINE_ORACLE_PHANTOM_MAX_INTERVAL)
	for i in range(_divine_oracle_phantom_data.size()):
		var data := _divine_oracle_phantom_data[i]
		data = _update_divine_oracle_phantom_data(data, delta)
		_divine_oracle_phantom_data[i] = data
	_prune_divine_oracle_phantoms()
	queue_redraw()


func _spawn_divine_oracle_phantom_raider() -> void:
	var own_sprite := get_node_or_null("Sprite2D") as Sprite2D
	if not own_sprite or not own_sprite.texture or not player:
		return
	var phantom_texture := get_behavior_texture(int(Behavior.DIVINE_WING_RAIDER))
	if phantom_texture == null:
		phantom_texture = own_sprite.texture
	if phantom_texture == null:
		return
	var start := _find_divine_oracle_phantom_start()
	var to_player := player.global_position - start
	if to_player.length() <= 0.01:
		to_player = Vector2.DOWN
	var charge_dir := to_player.normalized()
	var target := start + charge_dir * maxf(start.distance_to(player.global_position) + DIVINE_ORACLE_PHANTOM_CHARGE_OVERSHOOT, DIVINE_ORACLE_PHANTOM_MIN_CHARGE_DISTANCE)
	var sprite_node := Sprite2D.new()
	sprite_node.name = "DivineOracleWingRaiderPhantom"
	sprite_node.texture = phantom_texture
	sprite_node.centered = true
	sprite_node.scale = Vector2(DIVINE_WING_RAIDER_BODY_SIZE.x / phantom_texture.get_width(), DIVINE_WING_RAIDER_BODY_SIZE.y / phantom_texture.get_height())
	sprite_node.rotation = DESIGNED_ENEMY_SPRITE_ROTATION_OFFSET
	sprite_node.modulate = Color(0.55, 0.82, 1.25, 0.8)
	sprite_node.z_index = z_index - 1
	sprite_node.material = _create_divine_oracle_phantom_material()
	_get_effect_parent().add_child(sprite_node)
	sprite_node.global_position = start
	sprite_node.global_rotation = charge_dir.angle() + PI / 2.0 + DESIGNED_ENEMY_SPRITE_ROTATION_OFFSET
	_divine_oracle_phantom_data.append({
		"sprite": sprite_node,
		"phase": "warning",
		"timer": DIVINE_ORACLE_PHANTOM_WARNING_DURATION,
		"position": start,
		"warning_from": start,
		"warning_to": target,
		"charge_start": start,
		"charge_target": target,
		"charge_dir": charge_dir,
		"move_duration": maxf(start.distance_to(target) / (620.0 * 5.0), DIVINE_ORACLE_PHANTOM_MIN_CHARGE_DURATION),
		"move_elapsed": 0.0,
		"side_distance": 0.0,
		"side_next": randf_range(DIVINE_RAIDER_SIDE_SHOT_MIN_DISTANCE, DIVINE_RAIDER_SIDE_SHOT_MAX_DISTANCE),
		"hit_player": false,
	})


func _find_divine_oracle_phantom_start() -> Vector2:
	var radius := maxf(140.0, detection_range * DIVINE_ORACLE_DISTANCE_MULT)
	var center := player.global_position
	for i in range(24):
		var angle := randf_range(0.0, TAU)
		var candidate := _clamped_point(center + Vector2.RIGHT.rotated(angle) * randf_range(radius * 0.45, radius))
		var pushed := _push_out_from_obstacles(candidate)
		if pushed.distance_to(candidate) < 2.0 and not _path_blocked_by_obstacle(candidate, center):
			return candidate
	return _clamped_point(center + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * radius)


func _create_divine_oracle_phantom_material() -> ShaderMaterial:
	if _divine_oracle_phantom_material == null:
		_divine_oracle_phantom_material = ShaderMaterial.new()
		_divine_oracle_phantom_material.shader = HORIZON_PHANTOM_DISTORT_SHADER
		_divine_oracle_phantom_material.set_shader_parameter("strength", 0.014)
		_divine_oracle_phantom_material.set_shader_parameter("wave_scale", 22.0)
		_divine_oracle_phantom_material.set_shader_parameter("wave_speed", 4.8)
		_divine_oracle_phantom_material.set_shader_parameter("tint", Color(0.35, 0.72, 1.0, 1.0))
		_divine_oracle_phantom_material.set_shader_parameter("tint_amount", 0.28)
	return _divine_oracle_phantom_material


func _update_divine_oracle_phantom_data(data: Dictionary, delta: float) -> Dictionary:
	var sprite_node := data.get("sprite") as Sprite2D
	if not is_instance_valid(sprite_node):
		data["dead"] = true
		return data
	var phase := String(data.get("phase", "warning"))
	var position := data.get("position", sprite_node.global_position) as Vector2
	if phase == "warning":
		var remaining := float(data.get("timer", 0.0)) - delta
		data["timer"] = remaining
		if remaining <= 0.0:
			data["phase"] = "charge"
			data["move_elapsed"] = 0.0
			sprite_node.modulate.a = 0.8
		_update_divine_oracle_phantom_sprite(data)
		return data
	if phase == "charge":
		var previous := position
		var move_elapsed := float(data.get("move_elapsed", 0.0)) + delta
		var duration := maxf(float(data.get("move_duration", 0.05)), 0.05)
		var t := clampf(move_elapsed / duration, 0.0, 1.0)
		var eased_t := 1.0 - pow(1.0 - t, 3.0)
		var start := data.get("charge_start", position) as Vector2
		var target := data.get("charge_target", position) as Vector2
		position = start.lerp(target, eased_t)
		data["move_elapsed"] = move_elapsed
		data["position"] = position
		_update_divine_oracle_phantom_side_shots(data, previous, position)
		_check_divine_oracle_phantom_player_hit(data, position)
		_update_divine_oracle_phantom_sprite(data)
		if t >= 1.0:
			data["phase"] = "fade"
			data["timer"] = DIVINE_ORACLE_PHANTOM_FADE_DURATION
		return data
	if phase == "fade":
		var remaining := float(data.get("timer", 0.0)) - delta
		data["timer"] = remaining
		var alpha := clampf(remaining / DIVINE_ORACLE_PHANTOM_FADE_DURATION, 0.0, 1.0)
		sprite_node.modulate.a = 0.8 * alpha
		if remaining <= 0.0:
			sprite_node.queue_free()
			data["dead"] = true
		return data
	return data


func _update_divine_oracle_phantom_sprite(data: Dictionary) -> void:
	var sprite_node := data.get("sprite") as Sprite2D
	if not is_instance_valid(sprite_node):
		return
	var position := data.get("position", sprite_node.global_position) as Vector2
	var face_dir := data.get("charge_dir", Vector2.DOWN) as Vector2
	sprite_node.global_position = position
	if face_dir.length() <= 0.01 and player:
		face_dir = player.global_position - position
	if face_dir.length() > 0.01:
		sprite_node.global_rotation = face_dir.angle() + PI / 2.0 + DESIGNED_ENEMY_SPRITE_ROTATION_OFFSET


func _update_divine_oracle_phantom_side_shots(data: Dictionary, previous: Vector2, current: Vector2) -> void:
	var traveled := minf(previous.distance_to(current), DIVINE_ORACLE_PHANTOM_MAX_SIDE_SHOT_CATCHUP_DISTANCE)
	if traveled <= 0.0:
		return
	var side_distance := float(data.get("side_distance", 0.0)) + traveled
	var side_next := float(data.get("side_next", DIVINE_RAIDER_SIDE_SHOT_MIN_DISTANCE))
	var emitted_pairs := 0
	while side_distance >= side_next and _divine_oracle_frame_side_shots < DIVINE_ORACLE_PHANTOM_MAX_SIDE_SHOT_PAIRS_PER_FRAME:
		side_distance -= side_next
		side_next = randf_range(DIVINE_RAIDER_SIDE_SHOT_MIN_DISTANCE, DIVINE_RAIDER_SIDE_SHOT_MAX_DISTANCE)
		var forward := data.get("charge_dir", Vector2.DOWN) as Vector2
		if forward.length() <= 0.01:
			forward = (current - previous).normalized()
		if forward.length() <= 0.01:
			forward = Vector2.DOWN
		_spawn_bullet(forward.rotated(-PI * 0.5).normalized(), PARADISE_PATROL_BULLET_SPEED, DIVINE_RAIDER_SIDE_SHOT_DAMAGE, 1.0, current)
		_spawn_bullet(forward.rotated(PI * 0.5).normalized(), PARADISE_PATROL_BULLET_SPEED, DIVINE_RAIDER_SIDE_SHOT_DAMAGE, 1.0, current)
		emitted_pairs += 1
		_divine_oracle_frame_side_shots += 1
	if emitted_pairs == 0 and side_distance > side_next * 2.0:
		side_distance = side_next
	data["side_distance"] = side_distance
	data["side_next"] = side_next


func _check_divine_oracle_phantom_player_hit(data: Dictionary, phantom_position: Vector2) -> void:
	if bool(data.get("hit_player", false)):
		return
	if not player or not is_instance_valid(player):
		return
	var player_radius := _get_player_visual_radius()
	var half := DIVINE_WING_RAIDER_BODY_SIZE * 0.5
	var delta := player.global_position - phantom_position
	if absf(delta.x) > half.x + player_radius or absf(delta.y) > half.y + player_radius:
		return
	if player.has_method("take_damage_from_boss"):
		player.call("take_damage_from_boss", DIVINE_WING_RAIDER_DAMAGE)
	data["hit_player"] = true


func _prune_divine_oracle_phantoms() -> void:
	var active: Array[Dictionary] = []
	for data in _divine_oracle_phantom_data:
		if bool(data.get("dead", false)):
			continue
		var sprite_node := data.get("sprite") as Sprite2D
		if not is_instance_valid(sprite_node):
			continue
		active.append(data)
	_divine_oracle_phantom_data = active


func _clear_divine_oracle_phantoms() -> void:
	for data in _divine_oracle_phantom_data:
		var sprite_node := data.get("sprite") as Sprite2D
		if is_instance_valid(sprite_node):
			sprite_node.queue_free()
	_divine_oracle_phantom_data.clear()
	_divine_oracle_spawn_timer = 0.0


func _shield_bee_next_waypoint() -> Vector2:
	if _shield_bee_path.is_empty():
		return _shield_bee_target if _shield_bee_target != Vector2.ZERO else global_position
	_shield_bee_path_index = clampi(_shield_bee_path_index, 0, _shield_bee_path.size() - 1)
	if global_position.distance_to(_shield_bee_path[_shield_bee_path_index]) <= OBSTACLE_PATH_REACHED_DISTANCE and _shield_bee_path_index < _shield_bee_path.size() - 1:
		_shield_bee_path_index += 1
	return _shield_bee_path[_shield_bee_path_index]


func _should_avoid_player_for_positioning_target(target: Vector2) -> bool:
	if not player:
		return false
	if behavior == Behavior.COLOSSUS_SHIELD_BEE or behavior == Behavior.COLOSSUS_CORE_DEVOURER or behavior == Behavior.WARPED_MICRO_CORE:
		return false
	var to_target := target - player.global_position
	if to_target.length() <= 1.0:
		return true
	return to_target.normalized().dot(_get_player_aim_direction()) <= POSITIONING_PLAYER_TANGENT_FRONT_DOT


func _build_positioning_path(from_pos: Vector2, target: Vector2, avoid_player: bool) -> Array[Vector2]:
	var base := _build_obstacle_path(from_pos, target)
	if base.is_empty():
		return []
	if not avoid_player or not player:
		return base
	if not _path_near_player(base):
		return base
	if _explore_patrol_enabled or _explore_room_idle_enabled:
		return base
	var tangent_path := _build_player_tangent_path(from_pos, target)
	if tangent_path.size() >= 2 and _score_positioning_path(tangent_path, target) < _score_positioning_path(base, target):
		return tangent_path
	return base


func _build_player_tangent_path(from_pos: Vector2, target: Vector2) -> Array[Vector2]:
	if not player:
		return []
	var center := player.global_position
	var from_dir := from_pos - center
	if from_dir.length() <= 1.0:
		from_dir = (from_pos - target).normalized()
	if from_dir.length() <= 0.01:
		from_dir = -_get_player_aim_direction()
	var target_dir := target - center
	if target_dir.length() <= 1.0:
		target_dir = -_get_player_aim_direction()
	from_dir = from_dir.normalized()
	target_dir = target_dir.normalized()
	var route_radius := _positioning_player_avoid_radius() * 1.35
	var best_path: Array[Vector2] = []
	var best_score := INF
	for side in [-1.0, 1.0]:
		var waypoints := _build_player_tangent_waypoints(center, from_dir, target_dir, route_radius, side)
		var path := _build_path_through_positioning_waypoints(from_pos, waypoints, target)
		if path.size() < 2:
			continue
		var score := _score_positioning_path(path, target)
		if score < best_score:
			best_score = score
			best_path = path
	return best_path


func _build_player_tangent_waypoints(center: Vector2, from_dir: Vector2, target_dir: Vector2, radius: float, side: float) -> Array[Vector2]:
	var from_angle := from_dir.angle()
	var target_angle := target_dir.angle()
	var delta := wrapf(target_angle - from_angle, -PI, PI)
	if side > 0.0 and delta < 0.0:
		delta += TAU
	elif side < 0.0 and delta > 0.0:
		delta -= TAU
	var steps := clampi(int(ceil(absf(delta) / (PI * 0.32))), 1, 8)
	var waypoints: Array[Vector2] = []
	for i in range(0, steps + 1):
		var ratio := float(i) / float(steps)
		var raw := center + Vector2.RIGHT.rotated(from_angle + delta * ratio) * radius
		var point := _push_out_from_obstacles(_clamped_point(raw))
		if point.distance_to(center) < _positioning_player_avoid_radius() * 0.85:
			continue
		if waypoints.is_empty() or waypoints[waypoints.size() - 1].distance_to(point) > OBSTACLE_PATH_REACHED_DISTANCE:
			waypoints.append(point)
	return waypoints


func _build_path_through_positioning_waypoints(from_pos: Vector2, waypoints: Array[Vector2], target: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var current := from_pos
	for waypoint in waypoints:
		var segment := _build_obstacle_path(current, waypoint)
		if segment.is_empty():
			return []
		_append_positioning_path_segment(result, segment)
		if result.is_empty():
			return []
		current = result[result.size() - 1]
	var final_segment := _build_obstacle_path(current, target)
	if final_segment.is_empty():
		return []
	_append_positioning_path_segment(result, final_segment)
	return result


func _append_positioning_path_segment(result: Array[Vector2], segment: Array[Vector2]) -> void:
	for point in segment:
		if result.is_empty() or result[result.size() - 1].distance_to(point) > 1.0:
			result.append(point)


func _score_positioning_path(path: Array[Vector2], target: Vector2) -> float:
	if path.size() < 2:
		return INF
	var score := path[path.size() - 1].distance_to(target) * 20.0
	var radius := _positioning_player_avoid_radius()
	for i in range(path.size() - 1):
		var a := path[i]
		var b := path[i + 1]
		score += a.distance_to(b)
		if not _has_clear_obstacle_path(a, b):
			score += 100000.0
		var clearance := _distance_point_to_segment(player.global_position, a, b)
		if clearance < radius:
			score += 120000.0 + (radius - clearance) * 1200.0
	return score


func _path_near_player(path: Array[Vector2]) -> bool:
	if not player:
		return false
	if path.size() < 2:
		return false
	for i in range(path.size() - 1):
		if _segment_near_player(path[i], path[i + 1]):
			return true
	return false


func _segment_near_player(a: Vector2, b: Vector2) -> bool:
	if not player:
		return false
	return _distance_point_to_segment(player.global_position, a, b) <= _positioning_player_avoid_radius()


func _positioning_player_avoid_radius() -> float:
	return maxf(_get_player_visual_radius() + _obstacle_radius + POSITIONING_PLAYER_TANGENT_EXTRA_CLEARANCE, POSITIONING_PLAYER_TANGENT_MIN_RADIUS)


func _distance_point_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() <= 0.001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _build_obstacle_path(from_pos: Vector2, to_pos: Vector2, cell: float = OBSTACLE_PATH_CELL_SIZE) -> Array[Vector2]:
	var start := _push_out_from_obstacles(_clamped_point(from_pos))
	var goal := _push_out_from_obstacles(_clamped_point(to_pos))
	if _has_clear_obstacle_path(start, goal):
		return [start, goal]
	if not GameManager.try_consume_expensive_pathfinding_slot("DesignedEnemy.build_obstacle_path"):
		return []
	var slice_start_usec := Time.get_ticks_usec()

	var cols := maxi(2, int(ceil(screen_size.x / cell)) + 1)
	var rows := maxi(2, int(ceil(screen_size.y / cell)) + 1)
	var start_cell := _obstacle_path_cell_for_point(start, cols, rows, cell)
	var goal_cell := _obstacle_path_cell_for_point(goal, cols, rows, cell)
	start_cell = _nearest_obstacle_path_walkable_cell(start_cell, cols, rows, cell)
	goal_cell = _nearest_obstacle_path_walkable_cell(goal_cell, cols, rows, cell)

	var open: Array[Vector2i] = [start_cell]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start_cell: 0.0}
	var closed: Dictionary = {}
	var best_reachable := start_cell
	var best_goal_distance := _obstacle_path_point_for_cell(start_cell, cell).distance_to(goal)
	var expansions := 0

	while not open.is_empty():
		if expansions >= OBSTACLE_PATH_MAX_EXPANSIONS or Time.get_ticks_usec() - slice_start_usec >= OBSTACLE_PATH_FRAME_SLICE_USEC:
			break
		if GameManager.should_defer_work("DesignedEnemy.build_obstacle_path_loop"):
			break
		expansions += 1
		var current_index := _best_obstacle_path_cell_index(open, g_score, goal_cell, cell)
		var current := open[current_index]
		open.remove_at(current_index)
		var current_goal_distance := _obstacle_path_point_for_cell(current, cell).distance_to(goal)
		if current_goal_distance < best_goal_distance:
			best_goal_distance = current_goal_distance
			best_reachable = current
		if current == goal_cell:
			return _smooth_obstacle_path(_reconstruct_obstacle_path(came_from, current, cell, goal))
		closed[current] = true
		for neighbor in _obstacle_path_neighbors(current, cols, rows):
			if closed.has(neighbor):
				continue
			if not _is_obstacle_path_cell_walkable(neighbor, cell):
				continue
			var current_pos := _obstacle_path_point_for_cell(current, cell)
			var neighbor_pos := _obstacle_path_point_for_cell(neighbor, cell)
			if not _has_clear_obstacle_path(current_pos, neighbor_pos):
				continue
			var step_cost := current_pos.distance_to(neighbor_pos)
			var tentative := float(g_score.get(current, INF)) + step_cost
			if tentative >= float(g_score.get(neighbor, INF)):
				continue
			came_from[neighbor] = current
			g_score[neighbor] = tentative
			if not open.has(neighbor):
				open.append(neighbor)
	if best_reachable == start_cell:
		return []
	var fallback_goal := _obstacle_path_point_for_cell(best_reachable, cell)
	var fallback_path := _smooth_obstacle_path(_reconstruct_obstacle_path(came_from, best_reachable, cell, fallback_goal))
	if fallback_path.size() >= 2:
		return fallback_path
	return []


func _obstacle_path_cell_for_point(point: Vector2, cols: int, rows: int, cell: float) -> Vector2i:
	return Vector2i(clampi(int(round(point.x / cell)), 0, cols - 1), clampi(int(round(point.y / cell)), 0, rows - 1))


func _obstacle_path_point_for_cell(cell_pos: Vector2i, cell: float) -> Vector2:
	return _clamped_point(Vector2(float(cell_pos.x) * cell, float(cell_pos.y) * cell))


func _nearest_obstacle_path_walkable_cell(cell_pos: Vector2i, cols: int, rows: int, cell: float) -> Vector2i:
	if _is_obstacle_path_cell_walkable(cell_pos, cell):
		return cell_pos
	for radius in range(1, 6):
		for y in range(cell_pos.y - radius, cell_pos.y + radius + 1):
			for x in range(cell_pos.x - radius, cell_pos.x + radius + 1):
				var candidate := Vector2i(clampi(x, 0, cols - 1), clampi(y, 0, rows - 1))
				if _is_obstacle_path_cell_walkable(candidate, cell):
					return candidate
	return cell_pos


func _is_obstacle_path_cell_walkable(cell_pos: Vector2i, cell: float) -> bool:
	var point := _obstacle_path_point_for_cell(cell_pos, cell)
	return _push_out_from_obstacles(point, 1).distance_to(point) <= 2.0


func _obstacle_path_neighbors(cell_pos: Vector2i, cols: int, rows: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(-1, 2):
		for x in range(-1, 2):
			if x == 0 and y == 0:
				continue
			var nx := cell_pos.x + x
			var ny := cell_pos.y + y
			if nx >= 0 and nx < cols and ny >= 0 and ny < rows:
				result.append(Vector2i(nx, ny))
	return result


func _best_obstacle_path_cell_index(open: Array[Vector2i], g_score: Dictionary, goal: Vector2i, cell: float) -> int:
	var best_index := 0
	var best_score := INF
	for i in range(open.size()):
		var cell_pos := open[i]
		var heuristic := Vector2(float(cell_pos.x), float(cell_pos.y)).distance_to(Vector2(float(goal.x), float(goal.y))) * cell
		var score := float(g_score.get(cell_pos, INF)) + heuristic
		if score < best_score:
			best_score = score
			best_index = i
	return best_index


func _reconstruct_obstacle_path(came_from: Dictionary, current: Vector2i, cell: float, goal: Vector2) -> Array[Vector2]:
	var cells: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		cells.push_front(current)
	var points: Array[Vector2] = []
	for cell_pos in cells:
		points.append(_obstacle_path_point_for_cell(cell_pos, cell))
	if points.is_empty() or points[points.size() - 1].distance_to(goal) > 8.0:
		points.append(goal)
	return points


func _smooth_obstacle_path(path: Array[Vector2]) -> Array[Vector2]:
	if path.size() <= 2:
		return path
	var smoothed: Array[Vector2] = [path[0]]
	var anchor := 0
	while anchor < path.size() - 1:
		var next := path.size() - 1
		while next > anchor + 1 and not _has_clear_obstacle_path(path[anchor], path[next]):
			next -= 1
		smoothed.append(path[next])
		anchor = next
	return smoothed


func _advance_visible_obstacle_path_waypoint(path: Array[Vector2], current_index: int, from_pos: Vector2, avoid_player: bool = false) -> int:
	if path.is_empty():
		return 0
	var index := clampi(current_index, 0, path.size() - 1)
	while index < path.size() - 1 and from_pos.distance_to(path[index]) <= OBSTACLE_PATH_REACHED_DISTANCE:
		index += 1
	var farthest_visible := index
	for i in range(path.size() - 1, index, -1):
		if avoid_player and _segment_near_player(from_pos, path[i]):
			continue
		if _has_clear_obstacle_path(from_pos, path[i]):
			farthest_visible = i
			break
	return farthest_visible


func _find_obstacle_path_escape_point(from_pos: Vector2, goal: Vector2, distance: float = OBSTACLE_PATH_CELL_SIZE) -> Vector2:
	var to_goal := goal - from_pos
	var base_angle := to_goal.angle() if to_goal.length() > 1.0 else 0.0
	var best := from_pos
	var best_score := from_pos.distance_to(goal)
	var angle_offsets := [0.0, PI * 0.25, -PI * 0.25, PI * 0.5, -PI * 0.5, PI * 0.75, -PI * 0.75, PI]
	for angle_offset in angle_offsets:
		var candidate := _push_out_from_obstacles(_clamped_point(from_pos + Vector2.RIGHT.rotated(base_angle + angle_offset) * distance))
		if candidate.distance_to(from_pos) <= OBSTACLE_PATH_REACHED_DISTANCE:
			continue
		if not _has_clear_obstacle_path(from_pos, candidate):
			continue
		var score := candidate.distance_to(goal)
		if score < best_score:
			best_score = score
			best = candidate
	return best


func _has_clear_obstacle_path(from_pos: Vector2, to_pos: Vector2) -> bool:
	return not _path_blocked_by_obstacle(from_pos, to_pos)


func _get_player_aim_direction() -> Vector2:
	if not player:
		return Vector2.DOWN
	var dir := Vector2(0, -1).rotated(player.rotation)
	if dir.length() > 0.01:
		return dir.normalized()
	var fallback := global_position - player.global_position
	if fallback.length() > 0.01:
		return fallback.normalized()
	return Vector2.DOWN



func _prepare_gravity_claw_charge_path() -> void:
	if not player:
		_gravity_claw_charge_target = _find_reachable_target(global_position + Vector2.DOWN * 220.0)
		path_target = _gravity_claw_charge_target
		return
	var charge_dir := (player.global_position - global_position).normalized()
	if charge_dir.length() <= 0.01:
		charge_dir = Vector2.DOWN
	_gravity_claw_charge_target = _find_reachable_target(player.global_position + charge_dir * 260.0)
	var retreat_dir := -charge_dir
	_gravity_claw_retreat_start = global_position
	_gravity_claw_retreat_target = _push_out_from_obstacles(_clamped_point(global_position + retreat_dir * GRAVITY_CLAW_RETREAT_DISTANCE))
	_gravity_claw_retreat_elapsed = 0.0
	_gravity_claw_is_retreating = false
	_gravity_claw_is_fast_charging = false
	path_target = _gravity_claw_charge_target


func launch_as_core_devourer_gravity_claw(target_position: Vector2, impact_damage: int, dot_damage_per_second: float, owner: Node = null) -> void:
	behavior = Behavior.COLOSSUS_GRAVITY_CLAW
	player = get_tree().get_first_node_in_group(&"player")
	_ai_alert = true
	_alert_notice_active = false
	_is_pursuing_player = false
	_pursuit_elapsed = 0.0
	_pursuit_repath_timer = 0.0
	_gravity_claw_impact_damage = maxi(0, impact_damage)
	_gravity_claw_dot_damage_per_second = maxf(0.0, dot_damage_per_second)
	_gravity_claw_core_launch_active = true
	_gravity_claw_core_summoned = true
	_gravity_claw_core_owner = owner
	_gravity_claw_core_decay_accumulator = 0.0
	_gravity_claw_grappled_player = null
	_gravity_claw_grapple_offset = Vector2.ZERO
	_gravity_claw_grapple_inertia_velocity = Vector2.ZERO
	_gravity_claw_recovery_timer = 0.0
	_gravity_claw_knock_velocity = Vector2.ZERO
	_gravity_claw_is_retreating = false
	_gravity_claw_is_fast_charging = true
	var charge_dir := target_position - global_position
	if charge_dir.length() <= 0.01 and player:
		charge_dir = player.global_position - global_position
	if charge_dir.length() <= 0.01:
		charge_dir = Vector2.DOWN
	_gravity_claw_charge_target = _find_core_summoned_gravity_claw_target(target_position, charge_dir)
	source_position = global_position
	path_target = _gravity_claw_charge_target
	move_elapsed = 0.0
	move_duration = maxf(source_position.distance_to(path_target) / (move_speed * GRAVITY_CLAW_CHARGE_SPEED_MULT), 0.05)
	state = State.MOVING
	cooldown_remaining = 0.0
	_attack_timer = 999.0
	_special_timer = 999.0
	add_to_group(&"core_devourer_gravity_claws")
	if owner:
		set_meta(&"core_devourer_owner", owner)
	_smooth_face_direction(path_target - global_position, get_process_delta_time(), 999.0)
	queue_redraw()


func _find_core_summoned_gravity_claw_target(target_position: Vector2, charge_dir: Vector2) -> Vector2:
	var dir := charge_dir.normalized()
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	var candidate := _clamped_point(target_position + dir * CORE_DEVOURER_GRAVITY_CLAW_TARGET_OVERSHOOT)
	return _push_out_from_obstacles(candidate)


func _update_gravity_claw_attack(delta: float) -> void:
	if _attack_timer > 0.0:
		return
	_pick_path_target()
	source_position = global_position
	warning_timer = WARNING_DURATION
	state = State.WARNING


func _update_gravity_claw_lock_state(delta: float) -> bool:
	_update_core_summoned_gravity_claw_decay(delta)
	if is_queued_for_deletion():
		return true
	if _gravity_claw_recovery_timer > 0.0:
		_update_gravity_claw_recovery(delta)
		return true
	if _gravity_claw_grappled_player and is_instance_valid(_gravity_claw_grappled_player):
		_update_gravity_claw_grapple()
		return true
	return false


func _update_gravity_claw_charge(delta: float) -> void:
	_update_core_summoned_gravity_claw_decay(delta)
	if is_queued_for_deletion():
		return
	if _gravity_claw_recovery_timer > 0.0:
		_update_gravity_claw_recovery(delta)
		return
	if _gravity_claw_grappled_player and is_instance_valid(_gravity_claw_grappled_player):
		_update_gravity_claw_grapple()
		return
	var before := global_position
	if _apply_obstacle_bounce(delta):
		_update_effects(delta)
		return
	if not _gravity_claw_is_retreating and not _gravity_claw_is_fast_charging:
		_gravity_claw_is_retreating = true
		_gravity_claw_retreat_elapsed = 0.0
		_gravity_claw_retreat_start = global_position
		path_target = _gravity_claw_charge_target
	if _gravity_claw_is_retreating:
		_gravity_claw_retreat_elapsed += delta
		var retreat_t := clampf(_gravity_claw_retreat_elapsed / GRAVITY_CLAW_RETREAT_DURATION, 0.0, 1.0)
		global_position = _gravity_claw_retreat_start.lerp(_gravity_claw_retreat_target, smoothstep(0.0, 1.0, retreat_t))
		state = State.WARNING
		var hit_obstacle := _resolve_obstacle_contact(before, false)
		state = State.WARNING
		if hit_obstacle:
			_gravity_claw_is_retreating = false
			_update_effects(delta)
			return
		_smooth_face_direction(_gravity_claw_charge_target - global_position, delta, 8.0)
		if retreat_t >= 1.0:
			_gravity_claw_is_retreating = false
			_gravity_claw_is_fast_charging = true
			source_position = global_position
			path_target = _gravity_claw_charge_target
			move_elapsed = 0.0
			move_duration = maxf(source_position.distance_to(path_target) / (move_speed * GRAVITY_CLAW_CHARGE_SPEED_MULT), 0.05)
		_update_effects(delta)
		return
	if _gravity_claw_is_fast_charging:
		state = State.MOVING
		move_elapsed += delta
		var t := clampf(move_elapsed / move_duration, 0.0, 1.0)
		var eased_t := 1.0 - pow(1.0 - t, 3.0)
		global_position = source_position.lerp(path_target, eased_t)
		if _resolve_obstacle_contact(before, true):
			_gravity_claw_is_fast_charging = false
			if _gravity_claw_core_launch_active:
				_clear_gravity_claw_core_payload()
			_attack_timer = 1.0
			_update_effects(delta)
			return
		_smooth_face_direction(path_target - global_position, delta, 12.0)
		if t >= 1.0:
			global_position = path_target
			_gravity_claw_is_fast_charging = false
			if _gravity_claw_core_launch_active:
				_clear_gravity_claw_core_payload()
			if _gravity_claw_core_summoned:
				_deactivate_core_devourer_gravity_claw()
				return
			state = State.COOLDOWN
			cooldown_remaining = 0.2
			_attack_timer = 0.6
		_update_effects(delta)


func _try_gravity_claw_grapple(target_player: Area2D) -> void:
	if _gravity_claw_recovery_timer > 0.0:
		return
	if _gravity_claw_grappled_player and is_instance_valid(_gravity_claw_grappled_player):
		return
	if not target_player.has_method("begin_gravity_claw_grapple"):
		return
	_gravity_claw_grapple_inertia_velocity = _get_gravity_claw_charge_velocity() / GRAVITY_CLAW_GRAPPLE_INERTIA_DIVISOR
	if target_player.begin_gravity_claw_grapple(self):
		_gravity_claw_grappled_player = target_player
		_gravity_claw_grapple_offset = global_position - target_player.global_position
		_gravity_claw_is_retreating = false
		_gravity_claw_is_fast_charging = false
		_obstacle_bounce_time = 0.0
		_obstacle_bounce_velocity = Vector2.ZERO
		state = State.COOLDOWN
		_attack_timer = 999.0
		cooldown_remaining = move_cooldown
		_update_gravity_claw_grapple()
	else:
		_gravity_claw_grapple_inertia_velocity = Vector2.ZERO


func _update_gravity_claw_grapple() -> void:
	if not is_instance_valid(_gravity_claw_grappled_player):
		_gravity_claw_grappled_player = null
		_start_gravity_claw_recovery()
		return
	global_position = _gravity_claw_grappled_player.global_position + _gravity_claw_grapple_offset
	source_position = global_position
	path_target = global_position
	_update_effects(get_process_delta_time())


func release_gravity_claw_grapple() -> void:
	_release_gravity_claw_grapple_if_needed()
	_start_gravity_claw_recovery()


func get_gravity_claw_grapple_inertia_velocity() -> Vector2:
	return _gravity_claw_grapple_inertia_velocity


func get_gravity_claw_impact_damage() -> int:
	return _gravity_claw_impact_damage


func get_gravity_claw_dot_damage_per_second() -> float:
	return _gravity_claw_dot_damage_per_second


func _get_gravity_claw_charge_velocity() -> Vector2:
	var dir := path_target - source_position
	if dir.length() <= 0.01:
		dir = path_target - global_position
	if dir.length() <= 0.01:
		dir = Vector2(0, -1).rotated(rotation)
	return dir.normalized() * move_speed * GRAVITY_CLAW_CHARGE_SPEED_MULT


func _release_gravity_claw_grapple_if_needed() -> void:
	if _gravity_claw_grappled_player and is_instance_valid(_gravity_claw_grappled_player) and _gravity_claw_grappled_player.has_method("end_gravity_claw_grapple"):
		_gravity_claw_grappled_player.end_gravity_claw_grapple(self)
	_gravity_claw_grappled_player = null
	_gravity_claw_grapple_offset = Vector2.ZERO
	_gravity_claw_grapple_inertia_velocity = Vector2.ZERO


func _update_core_summoned_gravity_claw_decay(delta: float) -> void:
	if not _gravity_claw_core_summoned or hp <= 0:
		return
	var decay_per_second := CORE_DEVOURER_CLAW_HP_DECAY_PER_SECOND
	if _get_core_owner_gravity_claw_count() > CORE_DEVOURER_CLAW_OVERLOAD_COUNT:
		decay_per_second = CORE_DEVOURER_CLAW_OVERLOAD_HP_DECAY_PER_SECOND
	_gravity_claw_core_decay_accumulator += decay_per_second * delta
	var whole_damage := int(floor(_gravity_claw_core_decay_accumulator))
	if whole_damage <= 0:
		return
	_gravity_claw_core_decay_accumulator -= whole_damage
	_apply_core_summoned_gravity_claw_decay_damage(whole_damage)


func _apply_core_summoned_gravity_claw_decay_damage(amount: int) -> void:
	if amount <= 0 or hp <= 0:
		return
	hp -= amount
	if health_bar:
		health_bar.take_hit(hp)
	if hp <= 0:
		_release_gravity_claw_grapple_if_needed()
		_deactivate_core_devourer_gravity_claw()


func _get_core_owner_gravity_claw_count() -> int:
	if not is_instance_valid(_gravity_claw_core_owner):
		return 1
	var count := 0
	for claw in get_tree().get_nodes_in_group(&"core_devourer_gravity_claws"):
		if not is_instance_valid(claw) or claw.is_queued_for_deletion():
			continue
		if claw.get(&"_gravity_claw_core_owner") == _gravity_claw_core_owner:
			count += 1
	return count


func _handle_guard_charge_player_collision(target_player: Area2D) -> void:
	var charge_velocity := _get_guard_charge_velocity()
	var dir := charge_velocity.normalized()
	if dir.length() <= 0.01:
		dir = (target_player.global_position - global_position).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	if target_player.has_method("take_knockback_damage"):
		var knockback_speed := maxf(charge_velocity.length() * COLOSSUS_GUARD_PLAYER_KNOCKBACK_SPEED_MULT, 700.0)
		target_player.take_knockback_damage(damage, knockback_speed, COLOSSUS_GUARD_PLAYER_KNOCKBACK_DURATION, dir)
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	_obstacle_bounce_velocity = -dir * maxf(move_speed * COLOSSUS_GUARD_SELF_BOUNCE_SPEED_MULT, 260.0)
	_obstacle_bounce_time = COLOSSUS_GUARD_SELF_BOUNCE_DURATION
	state = State.COOLDOWN
	cooldown_remaining = 0.35
	source_position = global_position
	path_target = global_position
	_activate_shield_bee_style_shield()


func _handle_horizon_charge_player_collision(target_player: Area2D) -> void:
	var charge_velocity := _get_guard_charge_velocity()
	var dir := charge_velocity.normalized()
	if dir.length() <= 0.01:
		dir = (target_player.global_position - global_position).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	if target_player.has_method("take_knockback_damage"):
		var knockback_speed := maxf(charge_velocity.length() * HELLEYE_HORIZON_PLAYER_KNOCKBACK_SPEED_MULT, 760.0)
		target_player.take_knockback_damage(damage, knockback_speed, HELLEYE_HORIZON_PLAYER_KNOCKBACK_DURATION, dir)
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	_obstacle_bounce_velocity = -dir * maxf(move_speed * HELLEYE_HORIZON_SELF_BOUNCE_SPEED_MULT, 240.0)
	_obstacle_bounce_time = HELLEYE_HORIZON_SELF_BOUNCE_DURATION
	state = State.COOLDOWN
	cooldown_remaining = 0.35
	source_position = global_position
	path_target = global_position
	_begin_horizon_phantom_return()


func _handle_divine_seraph_charge_player_collision(target_player: Area2D) -> void:
	var charge_velocity := _get_guard_charge_velocity()
	var dir := charge_velocity.normalized()
	if dir.length() <= 0.01:
		dir = (target_player.global_position - global_position).normalized()
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	if target_player.has_method("take_knockback_damage"):
		var knockback_speed := maxf(charge_velocity.length() * DIVINE_SERAPH_PLAYER_KNOCKBACK_SPEED_MULT, 760.0)
		target_player.take_knockback_damage(damage, knockback_speed, DIVINE_SERAPH_PLAYER_KNOCKBACK_DURATION, dir)
	_shard_is_retreating = false
	_shard_is_fast_charging = false
	_obstacle_bounce_velocity = -dir * maxf(move_speed * DIVINE_SERAPH_SELF_BOUNCE_SPEED_MULT, 240.0)
	_obstacle_bounce_time = DIVINE_SERAPH_SELF_BOUNCE_DURATION
	state = State.COOLDOWN
	cooldown_remaining = 0.35
	source_position = global_position
	path_target = global_position


func _get_guard_charge_velocity() -> Vector2:
	var dir := path_target - source_position
	if dir.length() <= 0.01:
		dir = path_target - global_position
	if dir.length() <= 0.01:
		dir = Vector2(0, -1).rotated(rotation)
	return dir.normalized() * move_speed * 5.0


func _start_gravity_claw_recovery() -> void:
	_gravity_claw_is_retreating = false
	_gravity_claw_is_fast_charging = false
	_gravity_claw_grapple_offset = Vector2.ZERO
	_gravity_claw_grapple_inertia_velocity = Vector2.ZERO
	_clear_gravity_claw_core_payload()
	_gravity_claw_recovery_timer = randf_range(3.0, 5.0)
	_gravity_claw_knock_velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(520.0, 760.0)
	state = State.COOLDOWN
	cooldown_remaining = move_cooldown
	_attack_timer = _gravity_claw_recovery_timer
	_special_timer = _gravity_claw_recovery_timer


func _update_gravity_claw_recovery(delta: float) -> void:
	_gravity_claw_recovery_timer -= delta
	global_position += _gravity_claw_knock_velocity * delta
	_gravity_claw_knock_velocity = _gravity_claw_knock_velocity.move_toward(Vector2.ZERO, _gravity_claw_knock_velocity.length() * 2.6 * delta)
	global_position = _push_out_from_obstacles(_clamped_point(global_position))
	source_position = global_position
	_smooth_face_direction(_gravity_claw_knock_velocity, delta, turn_speed)
	_update_effects(delta)
	if _gravity_claw_recovery_timer <= 0.0:
		_gravity_claw_recovery_timer = 0.0
		_gravity_claw_knock_velocity = Vector2.ZERO
		_attack_timer = 0.0
		cooldown_remaining = 0.2


func _clear_gravity_claw_core_payload() -> void:
	_gravity_claw_impact_damage = 0
	_gravity_claw_dot_damage_per_second = 0.0
	_gravity_claw_core_launch_active = false


func _deactivate_core_devourer_gravity_claw() -> void:
	_release_gravity_claw_grapple_if_needed()
	_clear_gravity_claw_core_payload()
	_gravity_claw_core_summoned = false
	_gravity_claw_core_owner = null
	_gravity_claw_core_decay_accumulator = 0.0
	_gravity_claw_is_retreating = false
	_gravity_claw_is_fast_charging = false
	_gravity_claw_recovery_timer = 0.0
	_gravity_claw_knock_velocity = Vector2.ZERO
	_ai_alert = false
	_is_pursuing_player = false
	hp = maxi(hp, 1)
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node:
		shape_node.disabled = true
	monitoring = false
	monitorable = false
	if health_bar:
		health_bar.visible = false
	if get_meta(&"core_devourer_pool_item", false):
		_release_core_devourer_gravity_claw_to_pool(self)
	else:
		queue_free()



func _devourer_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = randf_range(3.0, 8.0)
	_core_devourer_fire_gravity_claw(damage)


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
	_apply_enemy_bullet_world_bounds(bullet)
	get_tree().current_scene.add_child(bullet)


func _spawn_reflect_bullet(dir: Vector2, speed: float, dmg: int, scale_mult: float = 1.0, spawn_pos: Vector2 = global_position) -> void:
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = spawn_pos + dir.normalized() * 28
	bullet.direction = dir.normalized()
	bullet.speed = speed
	bullet.damage = dmg
	bullet.scale = Vector2(scale_mult, scale_mult)
	bullet.z_index = -80
	if bullet.get("reflect_bounces_left") != null:
		bullet.reflect_bounces_left = WARPED_REFLECT_BOUNCES
	_apply_enemy_bullet_world_bounds(bullet)
	get_tree().current_scene.add_child(bullet)


func _apply_enemy_bullet_world_bounds(bullet: Node) -> void:
	if not _explore_patrol_enabled and not _explore_room_idle_enabled:
		return
	var bounds := _explore_patrol_room_bounds if _explore_patrol_enabled else _explore_room_bounds
	if bounds.size == Vector2.ZERO:
		bounds = Rect2(Vector2.ZERO, screen_size)
	bullet.set(&"world_bounds", bounds)


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


func _path_blocked_by_obstacle(from_pos: Vector2, to_pos: Vector2, sample_distance: float = 80.0) -> bool:
	var samples := maxi(2, int(from_pos.distance_to(to_pos) / maxf(40.0, sample_distance)))
	var obstacles := _get_blocking_obstacles_for_segment(from_pos, to_pos)
	if obstacles.is_empty():
		return false
	for i in range(1, samples + 1):
		var p := from_pos.lerp(to_pos, float(i) / float(samples))
		if _push_out_from_obstacles_with_list(p, obstacles, 1).distance_to(p) > 2.0:
			return true
	return false


func _push_out_from_obstacles(world_pos: Vector2, max_iterations: int = OBSTACLE_PUSH_RESOLVE_ITERATIONS) -> Vector2:
	return _push_out_from_obstacles_with_list(world_pos, _get_blocking_obstacles(), max_iterations)


func _push_out_from_obstacles_with_list(world_pos: Vector2, obstacles: Array[Node], max_iterations: int = OBSTACLE_PUSH_RESOLVE_ITERATIONS) -> Vector2:
	var pushed := world_pos
	for _i in range(maxi(1, max_iterations)):
		var before := pushed
		for obstacle in obstacles:
			if not is_instance_valid(obstacle) or obstacle.is_queued_for_deletion():
				continue
			if not _obstacle_near_point(obstacle, pushed):
				continue
			if obstacle.has_method("get_push_out_position"):
				pushed = obstacle.get_push_out_position(pushed, _obstacle_radius)
		if pushed.distance_to(before) <= 0.25:
			break
	return pushed


func _get_blocking_obstacles() -> Array[Node]:
	var now := Time.get_ticks_msec() * 0.001
	if now - _blocking_obstacles_cache_time < OBSTACLE_CACHE_INTERVAL:
		return _blocking_obstacles_cache
	_blocking_obstacles_cache_time = now
	var result: Array[Node] = []
	for group_name in [&"space_rocks", &"isolation_bands", &"space_clutter", &"explore_rewards"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node != self:
				result.append(node)
	_blocking_obstacles_cache = result
	return result


func _get_blocking_obstacles_for_segment(from_pos: Vector2, to_pos: Vector2) -> Array[Node]:
	var result: Array[Node] = []
	for obstacle in _get_blocking_obstacles():
		if not is_instance_valid(obstacle) or obstacle.is_queued_for_deletion():
			continue
		if _obstacle_near_segment(obstacle, from_pos, to_pos):
			result.append(obstacle)
	return result


func _obstacle_near_point(obstacle: Node, point: Vector2) -> bool:
	var margin := _obstacle_radius + OBSTACLE_QUERY_EXTRA_MARGIN
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


func _obstacle_near_segment(obstacle: Node, from_pos: Vector2, to_pos: Vector2) -> bool:
	var margin := _obstacle_radius + OBSTACLE_QUERY_EXTRA_MARGIN
	if obstacle.has_method("get_collision_query_radius"):
		var center := _obstacle_query_center(obstacle)
		var radius := float(obstacle.call("get_collision_query_radius")) + margin
		return _distance_point_to_segment(center, from_pos, to_pos) <= radius
	if obstacle.has_method("get_map_start") and obstacle.has_method("get_map_end"):
		var start: Vector2 = obstacle.call("get_map_start")
		var end: Vector2 = obstacle.call("get_map_end")
		var width := margin
		if obstacle.has_method("get_map_width"):
			width += float(obstacle.call("get_map_width")) * 0.5
		return _segments_close_enough(from_pos, to_pos, start, end, width)
	var fallback_center := _obstacle_query_center(obstacle)
	return _distance_point_to_segment(fallback_center, from_pos, to_pos) <= margin


func _segments_close_enough(a: Vector2, b: Vector2, c: Vector2, d: Vector2, max_distance: float) -> bool:
	if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
		return true
	var best := minf(
		minf(_distance_point_to_segment(a, c, d), _distance_point_to_segment(b, c, d)),
		minf(_distance_point_to_segment(c, a, b), _distance_point_to_segment(d, a, b))
	)
	return best <= max_distance


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
		if _uses_shield_bee_positioning_ai():
			_resume_positioning_ai_after_interrupt()
		else:
			_restart_after_obstacle_contact()
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
	if should_bounce:
		_obstacle_bounce_velocity = impact_dir * maxf(move_speed * 0.85, 180.0)
		_obstacle_bounce_time = 0.28
	else:
		_obstacle_bounce_velocity = Vector2.ZERO
		_obstacle_bounce_time = 0.0
	source_position = global_position
	if _uses_shield_bee_positioning_ai():
		_resume_positioning_ai_after_interrupt()
	else:
		_restart_after_obstacle_contact()
	return true


func _restart_after_obstacle_contact() -> void:
	if behavior == Behavior.DIVINE_BROKEN_WING_ASSASSIN or behavior == Behavior.DIVINE_SERAPH_HUNTER:
		state = State.COOLDOWN
		cooldown_remaining = move_cooldown
		_begin_divine_teleport(DIVINE_TELEPORT_ASSASSIN)
		return
	_pick_path_target()
	warning_timer = _get_warning_duration()
	state = State.WARNING


func _smooth_face_direction(direction: Vector2, delta: float, speed: float = -1.0) -> void:
	if behavior == Behavior.COLOSSUS_CORE_DEVOURER:
		rotation = 0.0
		return
	if direction.length() <= 0.01:
		return
	var actual_speed := turn_speed if speed <= 0.0 else speed
	rotation = lerp_angle(rotation, direction.angle() + PI / 2.0, clampf(actual_speed * delta, 0.0, 1.0))


func _is_facing_direction(direction: Vector2, tolerance: float) -> bool:
	if direction.length() <= 0.01:
		return true
	var target_angle := direction.angle() + PI / 2.0
	var diff := absf(wrapf(rotation - target_angle + PI, 0.0, TAU) - PI)
	return diff <= tolerance


func _get_player_visual_radius() -> float:
	if not player:
		return 32.0
	var radius = player.get(&"collision_radius")
	if radius != null:
		return maxf(18.0, float(radius))
	return 32.0


func _update_idle_facing(delta: float) -> void:
	if not player:
		return
	var direction := player.global_position - global_position
	_smooth_face_direction(direction, delta, turn_speed * 0.55)





func _update_effects(_delta: float) -> void:
	_update_warped_spin(_delta)
	if _uses_shield_bee_style_shield() and behavior != Behavior.COLOSSUS_SHIELD_BEE:
		_shield_bee_shield_time = maxf(_shield_bee_shield_time - _delta, 0.0)
	if behavior == Behavior.HELLEYE_INVERTED_MOTH:
		if _ai_alert:
			_update_inverted_moth_phantom()
		else:
			_clear_inverted_moth_phantom()
	elif behavior == Behavior.HELLEYE_HORIZON_DEFLECTOR:
		if _ai_alert:
			_update_horizon_phantoms()
		else:
			_clear_horizon_phantoms()
	_update_placeholder_rotation()


func _update_placeholder_rotation() -> void:
	if behavior == Behavior.COLOSSUS_CORE_DEVOURER:
		rotation = 0.0
		return
	for part in _visual_parts:
		if part:
			part.rotation = -rotation
