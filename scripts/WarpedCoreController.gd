extends Node2D
## 扭曲星核 —— 荧光陨石球体 Boss，带环绕小球

# ═══════════ 贴图 ═══════════
@export var body_tex: Texture2D
@export var orbiter_tex: Texture2D
const BOSS_BGM = preload("res://assets/audio/warpedcore_bgm.mp3")

const BODY_TEX_DEFAULT = preload("res://assets/images/warpedcore/warpedcore_body_cutout.png")
const ORBITER_TEX_DEFAULT = preload("res://assets/images/warpedcore/warpedcore_orbiter_cutout.png")

# ═══════════ 基本属性 ═══════════
@export var max_hp: int = 1000
@export var boss_name: String = "扭曲星核"
@export var spawn_y_ratio: float = 0.4               # 进场落位高度（屏幕比例）
var boss_hp: int
var screen_size: Vector2

# ═══════════ 生命周期标志 ═══════════
var active: bool = false
var entering: bool = true
var dying: bool = false

# ═══════════ 环绕小球 ═══════════
@export var orbiter_count: int = 4
@export var orbiter_base_radius: float = 120.0
@export var orbiter_base_speed: float = 1.5          # 弧度/秒
@export var orbiter_scale: float = 0.4
var orbiter_data: Array = []   # [{sprite, radius, speed, phase_offset, z_dir}]

# ═══════════ 主体外观 ═══════════
@export var body_scale_value: float = 1.0            # 主体缩放倍率
@export var body_collision_radius: float = 100.0       # 碰撞半径
@export var body_touch_dmg: int = 30                  # 触碰伤害
@export var orbiter_touch_dmg: int = 5                # 小球触碰伤害
@export var pulse_amplitude: float = 0.006            # 呼吸幅度（2% → 30% = 0.006）
@export var pulse_speed: float = 3.0
var pulse_phase: float = 0.0
var body_sprite: Sprite2D
var _ghost_red: Sprite2D
var _ghost_blue: Sprite2D

# 布朗运动
enum BrownState { PICK_TARGET, DASHING, PAUSING }
@export var brown_max_dist: float = 60.0               # 停留点距基点的最大距离
@export var brown_dash_speed: float = 300.0             # 冲刺速度 px/s
@export var brown_pause_min: float = 0.3                # 最短停顿时间
@export var brown_pause_max: float = 1.0                # 最长停顿时间
var _brown_state: BrownState = BrownState.PICK_TARGET
var _brown_target: Vector2 = Vector2.ZERO
var _brown_start: Vector2 = Vector2.ZERO                # 冲刺起点偏移
var _brown_total_dist: float = 0.0                      # 本次冲刺总距离
var _brown_elapsed: float = 0.0                         # 本次冲刺已用时间
var _brown_pause_timer: float = 0.0
var _home_position: Vector2                           # 进场落位后的基准点
var _initial_position: Vector2                        # 初始进场位置（BOTTOM 停泊位参考）

# 技能中对小球环绕速度的覆写
var _orbiter_speed_override: float = 1.0               # 技能中覆写环绕速度倍率
var _orbiter_radius_override: float = 1.0                # 技能中覆写环绕半径倍率
var _orbiter_trails_active: bool = false                 # 技能2 拖尾激活
var _show_orbit_circles: bool = false                   # 技能2 圆形轨道警戒框
var _orbit_circle_alpha: float = 0.0                     # 警戒圆环淡入淡出
var _orbiter_visual_diameter: float = 0.0               # 小球视觉直径（圆环宽度）
var _suction_active: bool = false                       # 技能4 吸力动画激活
var _suction_particles: Array = []                     # 速度线粒子 [{pos, dir, life, max_life, len}]
var _suction_debris: Array = []                        # 吸力敌机残骸 [{sprite, vel, speed_mult}]
var _suction_debris_cd: float = 0.0                     # 残骸生成冷却

# 技能5 — 十字激光
var _cross_lasers: Array = []                             # [{pos: Vector2, angle: float, progress: float, grow: float}]

# 停泊位
enum Dock { HOME, LEFT, RIGHT, BOTTOM }
var _dock: Dock = Dock.HOME
var _dock_positions: Dictionary = {}

# 警戒框（同天堂号）
var _warn_list: Array = []
var _warn_circle: Dictionary = {}
const WARN_DURATION: float = 3.0

# 进场动画 — 动态倍率
var _eff_body_mult: float = 1.0
var _eff_pulse_mult: float = 1.0
var _eff_freq_mult: float = 1.0
var _eff_speed_mult: float = 1.0
var _eff_radius_mult: float = 1.0

# ═══════════ 技能 ═══════════
@export var has_skill_1: bool = false
@export var has_skill_2: bool = false
@export var has_skill_3: bool = false
@export var has_skill_4: bool = false
@export var has_skill_5: bool = false
@export var has_skill_6: bool = true
@export var skill_cooldown: float = 2.0
@export var skill_1_dmg: int = 5
@export var skill_2_dmg: int = 5
@export var skill_3_dmg: int = 5
@export var skill_4_dmg: int = 5
@export var skill_5_dmg: int = 5
@export var skill_6_dmg: int = 5
var is_executing: bool = false
var cooldown_remaining: float = 0.0
var _last_skill: int = 0                                 # 上次释放的技能编号（0=无）

# 测试模式：按顺序循环 1→2→3→4→5→6
var _test_skill_seq: Array[int] = [1, 2, 3, 4, 5, 6]
var _test_seq_index: int = 0

# ═══════════ 死亡 ═══════════
const DEATH_DURATION: float = 5.0
var death_timer: float = 0.0
var death_explosion_cd: float = 0.0
var death_sfx_cd: float = 0.0
var won: bool = false

# ═══════════ BGM ═══════════
var bgm_player: AudioStreamPlayer

# ═══════════ 进场遮罩 ═══════════
var overlay_layer: CanvasLayer
var overlay_rect: ColorRect
var overlay_label: Label
var entrance_timer: float = 0.0

# ═══════════ 资源预加载 ═══════════
const HIT_SFX = preload("res://assets/audio/boss_hit.wav")
const EXPLOSION_SFX = preload("res://assets/audio/explosion.wav")
const ROAR_SFX = preload("res://assets/audio/boss_roar.wav")
const EXPLOSION_TEX = preload("res://assets/images/fx/explosion.png")
const DEBRIS_TEX = preload("res://assets/images/fx/debris.png")
const ExplosionScript = preload("res://scripts/Explosion.gd")
const DebrisScript = preload("res://scripts/Debris.gd")

# 技能3 — 敌机
const ENEMY_SCENES = [
	preload("res://scenes/EnemyRammer.tscn"),
	preload("res://scenes/EnemyThrower.tscn"),
	preload("res://scenes/EnemySuicide.tscn"),
]

# 技能4 — 吸力敌机材质
const SUCTION_DEBRIS_TEX = [
	preload("res://assets/images/enemy/enemy_rammer_cutout.png"),
	preload("res://assets/images/enemy/enemy_thrower_cutout.png"),
	preload("res://assets/images/enemy/enemy_suicide_cutout.png"),
]

# ═══════════ Tween 管理 ═══════════
var _skill_tweens: Array[Tween] = []


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	boss_hp = max_hp
	if not body_tex:
		body_tex = BODY_TEX_DEFAULT
	if not orbiter_tex:
		orbiter_tex = ORBITER_TEX_DEFAULT
	_setup_docks()
	_setup_body()
	_setup_orbiters()
	_setup_bgm()
	_create_entrance_overlay()
	_start_entrance()


func _setup_docks() -> void:
	_dock_positions = {
		Dock.LEFT: Vector2(screen_size.x * 0.125, screen_size.y * 0.5),
		Dock.RIGHT: Vector2(screen_size.x * 0.875, screen_size.y * 0.5),
	}


func _setup_body() -> void:
	# 碰撞体（玩家触碰弹飞）
	var body_area = Area2D.new()
	body_area.collision_layer = 2
	body_area.collision_mask = 1
	body_area.add_to_group(&"boss")
	body_area.name = "BodyArea"
	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = body_collision_radius
	col.name = "BodyCol"
	body_area.add_child(col)
	body_area.area_entered.connect(_on_body_area_entered)
	add_child(body_area)

	# 红移/蓝移重影（在主体下方）
	_ghost_red = Sprite2D.new()
	_ghost_red.texture = body_tex
	_ghost_red.centered = true
	_ghost_red.modulate = Color(1, 0, 0, 0.5)
	_ghost_red.z_index = 48
	_ghost_red.name = "GhostRed"
	add_child(_ghost_red)

	_ghost_blue = Sprite2D.new()
	_ghost_blue.texture = body_tex
	_ghost_blue.centered = true
	_ghost_blue.modulate = Color(0, 0.4, 1, 0.5)
	_ghost_blue.z_index = 48
	_ghost_blue.name = "GhostBlue"
	add_child(_ghost_blue)

	body_sprite = Sprite2D.new()
	body_sprite.texture = body_tex
	body_sprite.centered = true
	body_sprite.scale = Vector2(body_scale_value, body_scale_value)
	body_sprite.z_index = 50
	body_sprite.name = "BodySprite"
	add_child(body_sprite)


func _setup_orbiters() -> void:
	for i in orbiter_count:
		var orb = Sprite2D.new()
		orb.texture = orbiter_tex
		orb.centered = true
		orb.scale = Vector2(orbiter_scale, orbiter_scale)
		orb.z_index = 30
		orb.name = "Orbiter%d" % (i + 1)
		# 碰撞体：玩家触碰击飞
		var orb_area = Area2D.new()
		orb_area.collision_layer = 2
		orb_area.collision_mask = 1
		orb_area.add_to_group(&"boss")
		orb_area.name = "OrbArea%d" % (i + 1)
		var orb_col = CollisionShape2D.new()
		orb_col.shape = CircleShape2D.new()
		if orbiter_tex:
			orb_col.shape.radius = orbiter_tex.get_size().x * orbiter_scale * 0.6
		else:
			orb_col.shape.radius = 20.0
		orb_col.name = "OrbCol%d" % (i + 1)
		orb_area.add_child(orb_col)
		orb_area.area_entered.connect(_on_orbiter_area_entered)
		add_child(orb_area)
		add_child(orb)
		if i == 0 and orbiter_tex:
			_orbiter_visual_diameter = orbiter_tex.get_size().x * orbiter_scale
		var _r = orbiter_base_radius * (0.7 + randf_range(0.0, 0.6))
		var _a = TAU * float(i) / orbiter_count + randf_range(-0.2, 0.2)
		orbiter_data.append({
			"sprite": orb,
			"area": orb_area,
			"radius": _r,
			"speed": orbiter_base_speed * (0.6 + randf_range(0.0, 0.8)),
			"angle": _a,
			"z_dir": 1.0 if randf() < 0.5 else -1.0,
			"trails": [] as Array[Sprite2D],
		})


func _setup_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = BOSS_BGM
	bgm_player.volume_db = -10
	add_child(bgm_player)


func _start_entrance() -> void:
	entering = true
	entrance_timer = 0.0
	position = Vector2(screen_size.x * 0.5, -100)


func _make_tween() -> Tween:
	if dying:
		var tw = create_tween()
		tw.kill()
		return tw
	var tw = get_tree().create_tween()
	_skill_tweens.append(tw)
	return tw


func _process(delta: float) -> void:
	if dying:
		_death_process(delta)
		return
	if entering:
		_entrance_process(delta)
		return
	if not active:
		return

	_idle_animation(delta)

	if is_executing:
		return

	cooldown_remaining -= delta
	if cooldown_remaining <= 0.0:
		is_executing = true
		# 测试模式：按顺序循环 1→2→3→4→5→6
		var available: Array[int] = []
		if has_skill_1: available.append(1)
		if has_skill_2: available.append(2)
		if has_skill_3: available.append(3)
		if has_skill_4: available.append(4)
		if has_skill_5: available.append(5)
		if has_skill_6: available.append(6)
		var s = 0
		if not available.is_empty():
			s = available[_test_seq_index % available.size()]
			_test_seq_index += 1
		if s != 0:
			await _exec_skill(s)
			_last_skill = s
		cooldown_remaining = skill_cooldown
		is_executing = false


func _pick_random_skill(exclude: int = 0) -> int:
	var available: Array[int] = []
	if has_skill_1: available.append(1)
	if has_skill_2: available.append(2)
	if has_skill_3 and exclude != 3: available.append(3)
	if has_skill_4: available.append(4)
	if has_skill_5: available.append(5)
	if has_skill_6: available.append(6)
	if available.is_empty():
		return 0
	return available[randi() % available.size()]


func _exec_skill(s: int) -> void:
	match s:
		1: await _skill_1()
		2: await _skill_2()
		3: await _skill_3()
		4: await _skill_4()
		5: await _skill_5()
		6: await _skill_6()


## ── 待机动画：主体脉动 + 环绕小球 ──

func _idle_animation(delta: float) -> void:
	# 主体轻微脉动（频率和幅度均可通过进场倍率动态调节）
	pulse_phase += delta * pulse_speed * _eff_freq_mult
	var base = body_scale_value * _eff_body_mult
	var amp = pulse_amplitude * _eff_pulse_mult
	var s = base + sin(pulse_phase) * amp
	body_sprite.scale = Vector2(s, s)

	# 红移/蓝移重影同步
	var ghost_swap = sin(Time.get_ticks_msec() / 1000.0 * 1.2)  # 1.2Hz 正弦摆动
	var ghost_dist = 20.0 + ghost_swap * 15.0                    # 5~35px 摆动
	if _ghost_red:
		_ghost_red.scale = body_sprite.scale
		_ghost_red.position = Vector2(-ghost_dist, 0)
	if _ghost_blue:
		_ghost_blue.scale = body_sprite.scale
		_ghost_blue.position = Vector2(ghost_dist, 0)

	# 环绕小球 — 匀速圆周运动，直接跟随星核
	var orbiter_speed_mult = _eff_speed_mult * _orbiter_speed_override
	for idx in orbiter_data.size():
		var od = orbiter_data[idx]
		if not is_instance_valid(od.sprite):
			continue
		# 拖尾：记录当前位置到拖尾数组中
		if _orbiter_trails_active:
			var prev_pos = od.sprite.position
		od.angle += delta * od.speed * orbiter_speed_mult * od.z_dir
		var r = od.radius * _eff_radius_mult * _orbiter_radius_override
		od.sprite.position = Vector2(cos(od.angle) * r, sin(od.angle) * r)
		# 碰撞体跟随小球
		if is_instance_valid(od.area):
			od.area.position = od.sprite.position
		# 拖尾更新
		if _orbiter_trails_active:
			_update_orbiter_trails(od, delta)

	# 轨道警戒圆需要每帧重绘，淡入淡出
	var target_alpha = 1.0 if _show_orbit_circles else 0.0
	_orbit_circle_alpha = lerpf(_orbit_circle_alpha, target_alpha, 3.0 * delta)
	if abs(_orbit_circle_alpha - target_alpha) > 0.001 or _show_orbit_circles:
		queue_redraw()

	# 吸力动画需要每帧重绘（粒子更新由技能4循环驱动，此处只做重绘）
	if _suction_active:
		queue_redraw()

	# 布朗运动（仅活跃时）
	if active and brown_max_dist > 0:
		match _brown_state:
			BrownState.PICK_TARGET:
				var current_off = position - _home_position
				for _try in 20:
					_brown_target = Vector2(
						randf_range(-brown_max_dist, brown_max_dist),
						randf_range(-brown_max_dist, brown_max_dist)
					)
					if _brown_target.length() > brown_max_dist * 0.3 and _brown_target.distance_to(current_off) > brown_max_dist * 0.5:
						break
				_brown_start = current_off
				_brown_total_dist = _brown_target.distance_to(_brown_start)
				_brown_elapsed = 0.0
				_brown_state = BrownState.DASHING
			BrownState.DASHING:
				var dist = _brown_target.distance_to(_brown_start)
				if dist < 1.0:
					position = _home_position + _brown_target
					_brown_pause_timer = randf_range(brown_pause_min, brown_pause_max)
					_brown_state = BrownState.PAUSING
				else:
					_brown_elapsed += delta
					var dur = dist / brown_dash_speed
					var t = clampf(_brown_elapsed / maxf(dur, 0.001), 0.0, 1.0)
					var e = smoothstep(0.0, 1.0, t)            # ease-in-out：先慢后快再慢
					position = _home_position + _brown_start.lerp(_brown_target, e)
					if t >= 1.0:
						position = _home_position + _brown_target
						_brown_pause_timer = randf_range(brown_pause_min, brown_pause_max)
						_brown_state = BrownState.PAUSING
			BrownState.PAUSING:
				_brown_pause_timer -= delta
				if _brown_pause_timer <= 0.0:
					_brown_state = BrownState.PICK_TARGET


## ── 进场动画 ──

func _entrance_process(delta: float) -> void:
	entrance_timer += delta

	# 小球始终环绕
	_idle_animation(delta)

	# ── 阶段0 (0~1.5s)：从顶部滑入 ──
	if entrance_timer <= 1.5:
		if entrance_timer - delta < 0.5 and entrance_timer >= 0.5:
			_start_bgm()
		var t = clampf(entrance_timer / 1.5, 0.0, 1.0)
		var e = 1.0 - (1.0 - t) * (1.0 - t)
		position.y = lerpf(-100.0, screen_size.y * spawn_y_ratio, e)

	# ── 阶段1 (1.5~1.75s)：0.25s 膨胀到2倍（先慢后快，无呼吸、无震动） ──
	elif entrance_timer <= 1.75:
		if entrance_timer - delta < 1.5 and entrance_timer >= 1.5:
			_play_sfx(ROAR_SFX, -5)                       # 首次咆哮
		var t = clampf((entrance_timer - 1.5) / 0.25, 0.0, 1.0)
		var e = t * t                                     # ease-in quad：先慢后快
		_eff_body_mult = lerpf(1.0, 2.0, e)
		_eff_pulse_mult = 0.0
		_eff_speed_mult = lerpf(1.0, 8.0, e)
		_eff_radius_mult = lerpf(1.0, 1.5, e)

	# ── 阶段2 (1.75~2.25s)：峰值维持+震动开始，呼吸30%幅度+2倍频率 ──
	elif entrance_timer <= 2.25:
		if entrance_timer - delta < 1.75:
			_eff_pulse_mult = 0.3
			_eff_freq_mult = 2.0
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2(randf_range(-8, 8), randf_range(-5, 5))

	# ── 阶段3 (2.25~4.25s)：黑幕2s，峰值维持+震动持续 ──
	elif entrance_timer <= 4.25:
		overlay_rect.color = Color(0, 0, 0, 1)
		overlay_label.modulate = Color(1, 1, 1, 1)
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2(randf_range(-8, 8), randf_range(-5, 5))

	# ── 阶段4 (4.25~5.25s)：黑幕消失，峰值维持+震动持续 ──
	elif entrance_timer <= 5.25:
		overlay_rect.color = Color(0, 0, 0, 0)
		overlay_label.modulate = Color(1, 1, 1, 0)
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2(randf_range(-8, 8), randf_range(-5, 5))

	# ── 阶段5 (5.25~6.25s)：1s 复原（ease-out 先快后慢），停止震动 ──
	elif entrance_timer <= 6.25:
		if entrance_timer - delta < 5.25:
			var cam = get_viewport().get_camera_2d()
			if cam: cam.offset = Vector2.ZERO
		var t = clampf((entrance_timer - 5.25) / 1.0, 0.0, 1.0)
		var e = 1.0 - (1.0 - t) * (1.0 - t)
		_eff_body_mult = lerpf(2.0, 1.0, e)
		_eff_pulse_mult = lerpf(0.3, 1.0, e)
		_eff_freq_mult = lerpf(2.0, 1.0, e)
		_eff_speed_mult = lerpf(8.0, 1.0, e)
		_eff_radius_mult = lerpf(1.5, 1.0, e)

	# ── 阶段6 (6.25s+)：结束，进入待机 ──
	else:
		overlay_layer.queue_free()
		entering = false
		active = true
		_dock = Dock.HOME
		_initial_position = position
		_home_position = position
		cooldown_remaining = 0.5


## ── 技能1：停泊位转移 ──

func _skill_1() -> void:
	if dying:
		is_executing = false
		return

	# 1. 终止布朗运动
	_brown_state = BrownState.PAUSING
	_brown_pause_timer = 99.0

	# 2. 小球环绕速度在 1s 内提升至 6 倍
	var tw = _make_tween()
	tw.tween_method(_set_orbiter_override, 1.0, 6.0, 1.0)
	await tw.finished

	# 3. 锁定目标停泊位（排除 _dock 当前停泊位）
	var all_docks: Array = [Dock.HOME, Dock.LEFT, Dock.RIGHT, Dock.BOTTOM]
	var available_docks: Array = []
	for d in all_docks:
		if d != _dock:
			available_docks.append(d)
	var target_dock = available_docks[randi() % available_docks.size()]

	var target_pos = _get_dock_global(target_dock)

	# 4. 警戒框 3s
	_show_warn(global_position, target_pos)
	var charge_elapsed = 0.0
	while charge_elapsed < WARN_DURATION:
		if dying:
			is_executing = false
			_warn_list.clear()
			queue_redraw()
			return
		var dt = get_process_delta_time()
		charge_elapsed += dt
		for w in _warn_list:
			w.timer -= dt
		_warn_list = _warn_list.filter(func(w): return w.timer > 0)
		queue_redraw()
		await get_tree().process_frame
	_warn_list.clear()
	queue_redraw()

	# 5. 冲刺到目标点：先快后慢，期间小球速度从 6→1 倍
	var origin = position
	var dist = origin.distance_to(target_pos)
	var dur = dist / (brown_dash_speed * 3.0)
	var elapsed = 0.0
	while elapsed < dur:
		if dying:
			is_executing = false
			_orbiter_speed_override = 1.0
			return
		var dt = get_process_delta_time()
		elapsed += dt
		var t = clampf(elapsed / dur, 0.0, 1.0)
		var e = 1.0 - (1.0 - t) * (1.0 - t)              # ease-out：先快后慢
		position = origin.lerp(target_pos, e)
		_orbiter_speed_override = lerpf(6.0, 1.0, t)
		await get_tree().process_frame
	position = target_pos
	_orbiter_speed_override = 1.0

	# 6. 抵达停顿 1s
	_dock = target_dock
	_home_position = position
	await get_tree().create_timer(1.0).timeout
	if dying:
		is_executing = false
		return

	# 7. 恢复布朗运动
	_brown_state = BrownState.PICK_TARGET

## ── 技能3：咆哮 + 召唤敌机 ──

func _skill_3() -> void:
	if dying:
		is_executing = false
		return

	# 1. 冻结布朗运动
	_brown_state = BrownState.PAUSING
	_brown_pause_timer = 99.0

	# 2. 0.25s 膨胀+加速（ease-in，同开场动画）
	var tw = _make_tween()
	tw.set_parallel(true)
	tw.tween_method(_set_eff_body_mult, 1.0, 2.0, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_method(_set_eff_speed_mult, 1.0, 8.0, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_method(_set_eff_radius_mult, 1.0, 1.5, 0.25).set_ease(Tween.EASE_IN)
	_eff_pulse_mult = 0.0                                     # 咆哮期间无呼吸
	await tw.finished

	# 3. 维持峰值 + 全屏震动，持续期间依次召唤敌机（总咆哮 3s）
	var roar_elapsed = 0.25
	var enemy_count = randi_range(5, 10)
	var spawn_timers: Array[float] = []
	for i in enemy_count:
		spawn_timers.append(lerpf(0.0, 3.0 - 0.25, float(i) / maxf(float(enemy_count - 1), 1.0)))
	var spawned = 0
	while roar_elapsed < 3.0:
		if dying:
			_revert_roar(true)
			return
		var dt = get_process_delta_time()
		roar_elapsed += dt
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2(randf_range(-8, 8), randf_range(-5, 5))
		# 按时间表依次召唤
		while spawned < enemy_count and spawn_timers[spawned] <= roar_elapsed - 0.25:
			_spawn_single_roar_enemy()
			spawned += 1
		await get_tree().process_frame
	while spawned < enemy_count:
		_spawn_single_roar_enemy()
		spawned += 1

	# 4. 停止震动 + 0.5s 复原
	var cam = get_viewport().get_camera_2d()
	if cam: cam.offset = Vector2.ZERO

	tw = _make_tween()
	tw.set_parallel(true)
	tw.tween_method(_set_eff_body_mult, 2.0, 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_eff_speed_mult, 8.0, 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_eff_radius_mult, 1.5, 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_eff_pulse_mult", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	await tw.finished

	# 5. 恢复布朗运动
	_brown_state = BrownState.PICK_TARGET


## ── 技能5：十字激光连射 ──

func _skill_5() -> void:
	if dying:
		is_executing = false
		return

	_brown_state = BrownState.PAUSING
	_brown_pause_timer = 99.0

	var total_count = randi_range(20, 30)
	var total_time = randf_range(8.0, 12.0)
	var interval = total_time / float(total_count)

	for i in total_count:
		if dying: return

		var laser_angle = randf_range(0, TAU)
		var max_r = screen_size.length() * 0.3
		var offset = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50.0, max_r)
		var target_global = global_position + offset
		target_global.x = clampf(target_global.x, 50, screen_size.x - 50)
		target_global.y = clampf(target_global.y, 50, screen_size.y - 50)
		var target_local = to_local(target_global)

		# 生成发射球——从星核中心出发
		var orb = Sprite2D.new()
		orb.texture = orbiter_tex
		orb.centered = true
		orb.scale = Vector2(orbiter_scale, orbiter_scale)
		orb.z_index = 35
		orb.position = Vector2.ZERO
		add_child(orb)

		# 异步发射（独立于其他球）
		_launch_orb_async(orb, target_local, target_global, laser_angle)

		# 下一个球的出发间隔
		if i < total_count - 1:
			await get_tree().create_timer(interval).timeout

	# 等待所有激光结束
	while not _cross_lasers.is_empty():
		await get_tree().process_frame
	while not _warn_list.is_empty():
		await get_tree().process_frame

	_brown_state = BrownState.PICK_TARGET


func _launch_orb_async(_orb, target_local: Vector2, target_global: Vector2, laser_angle: float) -> void:
	var orb = _orb
	if dying: return

	# 飞行 0.5s，带旋转（speed 渐增再渐减）
	var tw = _make_tween()
	tw.set_parallel(true)
	tw.tween_property(orb, "position", target_local, 0.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(orb, "rotation", TAU * 2.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

	if dying or not is_instance_valid(orb):
		return

	# 蓄力：旋转逐步变慢，降至 5°/s 时爆炸
	var ang_speed_initial = TAU * 4.0                    # 4 rev/s 起
	var ang_speed_decay = 5.66                           # ln(1440/5) ≈ 5.66，约1s后达 5°/s
	var charge_elapsed = 0.0
	var max_charge = 3.0                                 # 超时兜底
	# 显示十字警戒框
	var diag = screen_size.length() * 0.8
	var ldir1 = Vector2.RIGHT.rotated(laser_angle)
	var ldir2 = Vector2.UP.rotated(laser_angle)
	var warn1 = {"from": to_local(target_global - ldir1 * diag), "to": to_local(target_global + ldir1 * diag), "timer": max_charge, "max_timer": max_charge, "full_half_w": 6.0}
	var warn2 = {"from": to_local(target_global - ldir2 * diag), "to": to_local(target_global + ldir2 * diag), "timer": max_charge, "max_timer": max_charge, "full_half_w": 6.0}
	_warn_list.append(warn1)
	_warn_list.append(warn2)
	queue_redraw()
	while charge_elapsed < max_charge:
		if dying or not is_instance_valid(orb):
			_warn_list.erase(warn1); _warn_list.erase(warn2)
			return
		var dt = get_process_delta_time()
		charge_elapsed += dt
		var cur_ang_speed = ang_speed_initial * exp(-ang_speed_decay * charge_elapsed)
		cur_ang_speed = maxf(cur_ang_speed, deg_to_rad(5.0))
		orb.rotation += cur_ang_speed * dt
		if cur_ang_speed <= deg_to_rad(5.01):
			break                                       # 降至 5°/s，立即爆炸
		warn1.timer -= dt
		warn2.timer -= dt
		queue_redraw()
		await get_tree().process_frame
	_warn_list.erase(warn1)
	_warn_list.erase(warn2)

	if dying or not is_instance_valid(orb):
		return

	# 爆炸瞬间销毁球
	orb.queue_free()

	# 爆炸
	_spawn_explosion_at(target_global, 0.35)

	# 十字激光：0.25s 生长 + 0.25s 宽度收缩消失
	var laser_data = {"pos": target_global, "angle": laser_angle, "progress": 0.0, "grow": 0.0, "hit_player": false}
	_cross_lasers.append(laser_data)
	var laser_elapsed = 0.0
	while laser_elapsed < 0.5:
		if dying:
			_cross_lasers.erase(laser_data)
			return
		var dt = get_process_delta_time()
		laser_elapsed += dt
		if laser_elapsed <= 0.25:
			laser_data.grow = clampf(laser_elapsed / 0.25, 0.0, 1.0)
			laser_data.progress = laser_data.grow
		else:
			laser_data.progress = clampf(1.0 - (laser_elapsed - 0.25) / 0.25, 0.0, 1.0)
		# 检测激光命中玩家
		if not laser_data.hit_player:
			_check_laser_hit_player(laser_data, diag)
		queue_redraw()
		await get_tree().process_frame
	_cross_lasers.erase(laser_data)
	queue_redraw()


func _check_laser_hit_player(laser_data, total_len: float) -> void:
	var player = get_tree().get_first_node_in_group(&"player")
	if not player or not is_instance_valid(player):
		return
	var ppos = to_local(player.global_position)
	var center = to_local(laser_data.pos)
	var len = total_len * laser_data.grow
	var half_w = maxf(0.3, 12.0 * laser_data.progress) * 2.0   # 碰撞半宽稍大于视觉
	var dir1 = Vector2.RIGHT.rotated(laser_data.angle)
	var dir2 = Vector2.UP.rotated(laser_data.angle)
	# 四条臂
	for dir in [dir1, -dir1, dir2, -dir2]:
		var dist_to_line = _point_to_segment_dist(ppos, center, center + dir * len)
		if dist_to_line < half_w:
			laser_data.hit_player = true
			player.take_damage_from_boss(10)
			return


func _point_to_segment_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ap = p - a
	var t = clampf(ap.dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	var closest = a + ab * t
	return p.distance_to(closest)


func _reset_orbiters_positions() -> void:
	for i in orbiter_data.size():
		var od = orbiter_data[i]
		if not is_instance_valid(od.sprite):
			continue
		od.angle = TAU * float(i) / orbiter_data.size()
		var r = od.radius * _eff_radius_mult
		od.sprite.position = Vector2(cos(od.angle) * r, sin(od.angle) * r)
		if is_instance_valid(od.area):
			od.area.position = od.sprite.position


func _spawn_single_roar_enemy() -> void:
	var scene = ENEMY_SCENES[randi() % ENEMY_SCENES.size()]
	var enemy = scene.instantiate()
	var edge = randi() % 3     # 0=上方, 1=左方, 2=右方
	match edge:
		0: enemy.position = Vector2(randf_range(40, screen_size.x - 40), -80)
		1: enemy.position = Vector2(-80, randf_range(80, screen_size.y * 0.6))
		2: enemy.position = Vector2(screen_size.x + 80, randf_range(80, screen_size.y * 0.6))
	get_tree().current_scene.add_child(enemy)


func _revert_roar(instant: bool = false) -> void:
	_eff_body_mult = 1.0
	_eff_speed_mult = 1.0
	_eff_radius_mult = 1.0
	_eff_pulse_mult = 1.0
	_suction_active = false
	GameManager.suction_active = false
	GameManager.suction_center = Vector2.ZERO
	if instant:
		_suction_particles.clear()
		for d in _suction_debris:
			if is_instance_valid(d.sprite):
				d.sprite.queue_free()
		_suction_debris.clear()
		_suction_debris_cd = 0.0
	else:
		# 停止生成新粒子/残骸，已有自然死亡 → 渐变消失
		while not _suction_particles.is_empty() or not _suction_debris.is_empty():
			var dt2 = get_process_delta_time()
			_idle_animation(dt2)
			_update_suction_particles(dt2)
			_update_suction_debris(dt2)
			queue_redraw()
			await get_tree().process_frame
	queue_redraw()
	var cam = get_viewport().get_camera_2d()
	if cam: cam.offset = Vector2.ZERO


func _set_eff_body_mult(v: float) -> void:   _eff_body_mult = v
func _set_eff_speed_mult(v: float) -> void:  _eff_speed_mult = v
func _set_eff_radius_mult(v: float) -> void: _eff_radius_mult = v


## ── 吸力速度线粒子系统 ──

func _update_suction_particles(delta: float) -> void:
	# 移除死亡粒子
	var to_remove: Array = []
	for p in _suction_particles:
		p.life -= delta
		if p.life <= 0.0:
			to_remove.append(p)
		else:
			# 向圆心移动：dir 指向圆心，pos += dir 靠近
			var dist_now = p.pos.length()
			var speed = dist_now / maxf(p.life, 0.01) * 2.1
			p.pos += p.dir * speed * delta
	for p in to_remove:
		_suction_particles.erase(p)
	# 持续生成新粒子（仅在活跃时）
	if _suction_active:
		var spawn_rate = 30.0
		var count = maxi(1, ceili(spawn_rate * delta))
		for _i in count:
			_spawn_suction_particle()


func _spawn_suction_particle() -> void:
	# 随机选择画面四条边之一生成
	var edge = randi() % 4
	var pos: Vector2
	match edge:
		0: pos = Vector2(randf_range(-100, screen_size.x + 100), randf_range(-150, -50))
		1: pos = Vector2(randf_range(-150, -50), randf_range(-100, screen_size.y + 100))
		2: pos = Vector2(randf_range(screen_size.x + 50, screen_size.x + 150), randf_range(-100, screen_size.y + 100))
		3: pos = Vector2(randf_range(-100, screen_size.x + 100), randf_range(screen_size.y + 50, screen_size.y + 150))
	# 转换到星核局部坐标
	pos -= global_position
	var dir = (-pos).normalized()                             # 指向圆心
	var life = randf_range(0.5, 1.2)                         # 寿命
	var length = randf_range(80.0, 200.0)                  # 线长
	_suction_particles.append({
		"pos": pos,
		"dir": dir,
		"life": life,
		"max_life": life,
		"len": length,
	})


## ── 吸力敌机残骸 ──

func _update_suction_debris(delta: float) -> void:
	# 移除已死亡的
	var to_remove: Array = []
	for d in _suction_debris:
		if not is_instance_valid(d.sprite):
			to_remove.append(d)
			continue
		# 向星核中心加速
		var to_boss = global_position - d.sprite.global_position
		var dist = to_boss.length()
		# 碰撞：用星核碰撞半径，且判断是否已越过星核（防高速穿透）
		var prev_to_boss = (global_position - d.old_pos) if d.has("old_pos") else Vector2.ZERO
		var crossed = prev_to_boss.length() > 0.1 and to_boss.dot(prev_to_boss) < 0.0
		if dist < body_collision_radius or crossed:
			_spawn_explosion_at(d.sprite.global_position, 0.6)
			d.sprite.queue_free()
			to_remove.append(d)
			continue
		d.old_pos = d.sprite.global_position
		var accel = to_boss.normalized() * 800.0
		d.vel += accel * delta
		d.vel = d.vel.limit_length(2000.0)
		d.sprite.global_position += d.vel * delta
		# 朝向速度方向
		d.sprite.rotation = d.vel.angle() + PI / 2.0
		# 检查与玩家的碰撞
		var player = get_tree().get_first_node_in_group(&"player")
		if player and is_instance_valid(player):
			var pdist = player.global_position.distance_to(d.sprite.global_position)
			if pdist < 30.0:
				player.take_knockback_damage(20, 800.0, 0.3, (player.global_position - d.sprite.global_position).normalized())
				_spawn_explosion_at(d.sprite.global_position, 0.6)
				d.sprite.queue_free()
				to_remove.append(d)
				continue
	for d in to_remove:
		_suction_debris.erase(d)
	# 持续生成（仅在活跃时，1~2s 一个）
	if _suction_active:
		_suction_debris_cd -= delta
		if _suction_debris_cd <= 0.0:
			_suction_debris_cd = randf_range(1.0, 2.0)
			_spawn_suction_debris()


func _spawn_suction_debris() -> void:
	var tex = SUCTION_DEBRIS_TEX[randi() % SUCTION_DEBRIS_TEX.size()]
	var s = Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.scale = Vector2(0.0625, 0.0625)                     # 同敌机 scale
	s.z_index = 200
	# 随机从画面四边之一生成
	var edge = randi() % 4
	match edge:
		0: s.global_position = Vector2(randf_range(-100, screen_size.x + 100), randf_range(-150, -50))
		1: s.global_position = Vector2(randf_range(-150, -50), randf_range(-100, screen_size.y + 100))
		2: s.global_position = Vector2(randf_range(screen_size.x + 50, screen_size.x + 150), randf_range(-100, screen_size.y + 100))
		3: s.global_position = Vector2(randf_range(-100, screen_size.x + 100), randf_range(screen_size.y + 50, screen_size.y + 150))
	get_tree().current_scene.add_child(s)
	# 初始速度：直线冲向星核
	var dir = (global_position - s.global_position).normalized()
	var init_speed = randf_range(100.0, 300.0)
	_suction_debris.append({
		"sprite": s,
		"vel": dir * init_speed,
		"old_pos": s.global_position,
	})


func _spawn_explosion_at(pos: Vector2, sc: float = 0.6) -> void:
	_play_sfx(EXPLOSION_SFX, -8)
	var exp = Sprite2D.new()
	exp.set_script(ExplosionScript)
	exp.texture = EXPLOSION_TEX
	exp.position = pos
	exp.rotation = randf_range(0, TAU)
	exp.scale = Vector2(sc, sc)
	exp.z_index = 2000
	get_tree().current_scene.add_child(exp)
	_spawn_debris(pos, randi_range(3, 6))


## ── 技能4：强吸力咆哮 ──

func _skill_4() -> void:
	if dying:
		is_executing = false
		return

	# 1. 冻结布朗运动
	_brown_state = BrownState.PAUSING
	_brown_pause_timer = 99.0

	# 2. 0.25s 膨胀+加速（ease-in，同开场动画）
	var tw = _make_tween()
	tw.set_parallel(true)
	tw.tween_method(_set_eff_body_mult, 1.0, 2.0, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_method(_set_eff_speed_mult, 1.0, 8.0, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_method(_set_eff_radius_mult, 1.0, 1.5, 0.25).set_ease(Tween.EASE_IN)
	_eff_pulse_mult = 0.0
	await tw.finished

	# 3. 启用吸力动画 + 全屏震动 + 玩家吸力，维持 10s
	_suction_active = true
	_suction_particles.clear()
	_suction_debris.clear()
	_suction_debris_cd = 0.0
	GameManager.suction_active = true
	var roar_elapsed = 0.0
	while roar_elapsed < 10.0:
		if dying:
			_revert_roar(true)
			return
		var dt = get_process_delta_time()
		roar_elapsed += dt
		# 震动 + 粒子更新 + 残骸更新 + 吸力中心
		GameManager.suction_center = global_position
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2(randf_range(-8, 8), randf_range(-5, 5))
		_update_suction_particles(dt)
		_update_suction_debris(dt)
		queue_redraw()
		await get_tree().process_frame
	GameManager.suction_active = false
	GameManager.suction_center = Vector2.ZERO
	_suction_active = false
	# 停止生成新粒子/残骸，已有粒子自然死亡 → 渐变消失
	while not _suction_particles.is_empty() or not _suction_debris.is_empty():
		var dt2 = get_process_delta_time()
		_idle_animation(dt2)
		_update_suction_particles(dt2)
		_update_suction_debris(dt2)
		queue_redraw()
		await get_tree().process_frame
	queue_redraw()

	# 4. 停止震动 + 0.5s 复原
	var cam = get_viewport().get_camera_2d()
	if cam: cam.offset = Vector2.ZERO

	tw = _make_tween()
	tw.set_parallel(true)
	tw.tween_method(_set_eff_body_mult, 2.0, 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_eff_speed_mult, 8.0, 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_eff_radius_mult, 1.5, 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_eff_pulse_mult", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	await tw.finished

	# 5. 恢复布朗运动
	_brown_state = BrownState.PICK_TARGET



## ── 技能6：连续冲刺 ──

func _skill_6() -> void:
	if dying:
		is_executing = false
		return

	_brown_state = BrownState.PAUSING
	_brown_pause_timer = 99.0

	# 小球加速至 6 倍并全程保持
	_orbiter_speed_override = 6.0

	var total_count = randi_range(8, 12)
	var warn_duration = 2.0

	for i in total_count:
		if dying: return

		# 获取玩家位置，沿 Boss→玩家 方向延伸随机距离
		var player = get_tree().get_first_node_in_group(&"player")
		var dir_to_player := Vector2.RIGHT
		var player_pos := position
		if player and is_instance_valid(player):
			player_pos = player.global_position
			var diff = player_pos - position
			if diff.length() > 1.0:
				dir_to_player = diff.normalized()
		var extension = randf_range(80.0, 350.0)
		var target_global = player_pos + dir_to_player * extension
		target_global.x = clampf(target_global.x, 50, screen_size.x - 50)
		target_global.y = clampf(target_global.y, 50, screen_size.y - 50)

		# 警戒框（蓄力 = 警戒框存在时间，消失后立刻冲刺）
		_show_warn(global_position, target_global, warn_duration)
		var charge_elapsed = 0.0
		while charge_elapsed < warn_duration:
			if dying:
				_orbiter_speed_override = 1.0
				_warn_list.clear()
				queue_redraw()
				return
			var dt = get_process_delta_time()
			charge_elapsed += dt
			for w in _warn_list:
				w.timer -= dt
			_warn_list = _warn_list.filter(func(w): return w.timer > 0)
			queue_redraw()
			await get_tree().process_frame
		_warn_list.clear()
		queue_redraw()

		if dying:
			_orbiter_speed_override = 1.0
			return

		# 冲刺（小球保持 6 倍速不变）
		var origin = position
		var dist = origin.distance_to(target_global)
		var dur = dist / (brown_dash_speed * 3.0)
		var elapsed = 0.0
		while elapsed < dur:
			if dying:
				_orbiter_speed_override = 1.0
				return
			var dt2 = get_process_delta_time()
			elapsed += dt2
			var t = clampf(elapsed / dur, 0.0, 1.0)
			var e = 1.0 - (1.0 - t) * (1.0 - t)
			position = origin.lerp(target_global, e)
			await get_tree().process_frame
		position = target_global
		_home_position = position

		# 警戒框时间递减
		warn_duration = maxf(1.0, warn_duration - 0.5)

	# 完成后触发技能1（警戒框时间继续递减）
	if dying:
		_orbiter_speed_override = 1.0
		return
	await _skill_1_exclude_nearest(warn_duration)

	_orbiter_speed_override = 1.0
	_brown_state = BrownState.PICK_TARGET


func _skill_1_exclude_nearest(warn_duration: float) -> void:
	if dying: return

	_brown_state = BrownState.PAUSING
	_brown_pause_timer = 99.0

	# 小球保持高速
	_orbiter_speed_override = 6.0

	var player = get_tree().get_first_node_in_group(&"player")
	var player_global = player.global_position if (player and is_instance_valid(player)) else position

	var all_docks: Array = [Dock.HOME, Dock.LEFT, Dock.RIGHT, Dock.BOTTOM]
	# 排除离玩家最近的
	var nearest_idx = 0
	var nearest_dist = INF
	for d_idx in all_docks.size():
		var dp = _get_dock_global(all_docks[d_idx])
		var dd = dp.distance_squared_to(player_global)
		if dd < nearest_dist:
			nearest_dist = dd
			nearest_idx = d_idx
	var available: Array = []
	for d_idx in all_docks.size():
		if d_idx != nearest_idx:
			available.append(all_docks[d_idx])

	var target_dock = available[randi() % available.size()]
	if target_dock == _dock:
		available.erase(target_dock)
		if available.is_empty():
			available = [all_docks[(nearest_idx + 1) % all_docks.size()]]
		target_dock = available[randi() % available.size()]
	var target_pos = _get_dock_global(target_dock)

	# 警戒框（时长 = 传入的递减值）
	_show_warn(global_position, target_pos, warn_duration)
	var charge_elapsed = 0.0
	while charge_elapsed < warn_duration:
		if dying:
			_orbiter_speed_override = 1.0
			_warn_list.clear()
			queue_redraw()
			return
		var dt = get_process_delta_time()
		charge_elapsed += dt
		for w in _warn_list:
			w.timer -= dt
		_warn_list = _warn_list.filter(func(w): return w.timer > 0)
		queue_redraw()
		await get_tree().process_frame
	_warn_list.clear()
	queue_redraw()

	if dying:
		_orbiter_speed_override = 1.0
		return

	# 冲刺（小球保持 6 倍速）
	var origin = position
	var dist = origin.distance_to(target_pos)
	var dur = dist / (brown_dash_speed * 3.0)
	var elapsed = 0.0
	while elapsed < dur:
		if dying:
			_orbiter_speed_override = 1.0
			return
		var dt2 = get_process_delta_time()
		elapsed += dt2
		var t = clampf(elapsed / dur, 0.0, 1.0)
		var e = 1.0 - (1.0 - t) * (1.0 - t)
		position = origin.lerp(target_pos, e)
		await get_tree().process_frame
	position = target_pos
	_orbiter_speed_override = 1.0
	_dock = target_dock
	_home_position = position

	await get_tree().create_timer(1.0).timeout


func _skill_placeholder(n: int) -> void:
	if dying:
		is_executing = false
		return
	await get_tree().create_timer(0.5).timeout


## ── 技能2：轨道扩张 ──

func _skill_2() -> void:
	if dying:
		is_executing = false
		return

	# 1. 冻结布朗运动
	_brown_state = BrownState.PAUSING
	_brown_pause_timer = 99.0

	# 2. 启用拖尾和轨道警戒圆
	_orbiter_trails_active = true
	_show_orbit_circles = true
	queue_redraw()

	# 3. 5s 匀速扩张到 3×速度 + 5×半径
	var tw = _make_tween()
	tw.set_parallel(true)
	tw.tween_method(_set_orbiter_override, 1.0, 3.0, 5.0)
	tw.tween_method(_set_orbiter_radius_override, 1.0, 5.0, 5.0)
	await tw.finished

	# 4. 维持 3s
	if dying:
		_cleanup_skill_2()
		return
	await get_tree().create_timer(3.0).timeout

	# 5. 5s 匀速回归
	if dying:
		_cleanup_skill_2()
		return
	tw = _make_tween()
	tw.set_parallel(true)
	tw.tween_method(_set_orbiter_override, 3.0, 1.0, 5.0)
	tw.tween_method(_set_orbiter_radius_override, 5.0, 1.0, 5.0)
	await tw.finished

	# 6. 清理
	_cleanup_skill_2()
	_brown_state = BrownState.PICK_TARGET


func _cleanup_skill_2() -> void:
	_orbiter_trails_active = false
	_show_orbit_circles = false
	_orbiter_speed_override = 1.0
	_orbiter_radius_override = 1.0
	queue_redraw()
	for od in orbiter_data:
		for t in od.trails:
			if is_instance_valid(t):
				t.queue_free()
		od.trails.clear()


func _set_orbiter_radius_override(v: float) -> void:
	_orbiter_radius_override = v


func _update_orbiter_trails(od: Dictionary, delta: float) -> void:
	const TRAIL_COUNT = 6
	const TRAIL_FADE = 0.18                                # 每层透明度
	var pos = od.sprite.position
	var scale = od.sprite.scale
	# 确保有足够的拖尾精灵
	while od.trails.size() < TRAIL_COUNT:
		var t = Sprite2D.new()
		t.texture = od.sprite.texture
		t.centered = true
		t.scale = scale                                  # 初始缩放匹配小球
		t.position = pos                                 # 初始位置匹配小球
		t.z_index = 28
		t.modulate = Color(0.5, 0.3, 1.0, 0.0)             # 紫色调拖尾
		add_child(t)
		od.trails.append(t)
	# 逐层向后退一帧位置，最旧的淡出消失
	for i in range(TRAIL_COUNT - 1, 0, -1):
		var older = od.trails[i - 1]
		var cur = od.trails[i]
		if is_instance_valid(older):
			cur.position = older.position
			cur.scale = older.scale
		cur.modulate.a = maxf(0.0, (TRAIL_COUNT - i) * TRAIL_FADE)
	# 最新一层放在当前位置
	var first = od.trails[0]
	if is_instance_valid(first):
		first.position = pos
		first.scale = scale
		first.modulate.a = TRAIL_COUNT * TRAIL_FADE


## ── 停泊位全局坐标 ──

func _get_dock_global(dk: Dock) -> Vector2:
	match dk:
		Dock.HOME:
			return _initial_position
		Dock.BOTTOM:
			return Vector2(_initial_position.x, screen_size.y - _initial_position.y)
		Dock.LEFT, Dock.RIGHT:
			return _dock_positions[dk]
	return position


func _set_orbiter_override(v: float) -> void:
	_orbiter_speed_override = v


## ── 警戒框 ──

func _show_warn(from: Vector2, to: Vector2, max_time: float = WARN_DURATION, half_w: float = 54.0) -> void:
	_warn_list.append({"from": to_local(from), "to": to_local(to), "timer": max_time, "max_timer": max_time, "full_half_w": half_w})


func _draw() -> void:
	# 技能5 十字激光
	for laser in _cross_lasers:
		var local_pos = to_local(laser.pos)
		var diag = screen_size.length() * 0.8
		var len = diag * laser.grow
		if laser.progress > 0.001:
			var half_w = maxf(0.3, 12.0 * laser.progress)
			var dir1 = Vector2.RIGHT.rotated(laser.angle)
			var dir2 = Vector2.UP.rotated(laser.angle)
			var perp1 = Vector2(-dir1.y, dir1.x)
			var perp2 = Vector2(-dir2.y, dir2.x)
			var col = Color(0.7, 0.2, 1.0, 0.9)
			var glow_col = Color(0.5, 0.1, 0.8, 0.3)
			var glow_w = half_w * 3.0
			_draw_laser_arm(local_pos, dir1, perp1, len, glow_w, glow_col)
			_draw_laser_arm(local_pos, dir1, perp1, len, half_w, col)
			_draw_laser_arm(local_pos, dir2, perp2, len, glow_w, glow_col)
			_draw_laser_arm(local_pos, dir2, perp2, len, half_w, col)

	# 技能4 吸力动画 — 速度线向心涌入（用矩形条绘制，比 draw_line 更可靠）
	if not _suction_particles.is_empty():
		for p in _suction_particles:
			var t = 1.0 - p.life / p.max_life              # 0(刚出生) → 1(即将消失)
			var alpha: float
			if t < 0.15:
				alpha = t / 0.15                            # 淡入
			elif t > 0.7:
				alpha = 1.0 - (t - 0.7) / 0.3              # 淡出
			else:
				alpha = 1.0
			if alpha < 0.02: continue
			var col = Color(1, 1, 1, alpha * 0.4)
			var start = p.pos
			var end = p.pos + p.dir * p.len
			var perp = Vector2(-p.dir.y, p.dir.x) * 2.5    # 半宽 2.5px → 总宽 5px
			var pts = PackedVector2Array([
				start + perp, start - perp,
				end - perp, end + perp,
			])
			draw_colored_polygon(pts, col)

	# 技能2 轨道警戒圆环（淡入淡出，宽度=小球直径，前方90°实心→再90°渐隐）
	if _orbit_circle_alpha > 0.001:
		var flash = fmod(Time.get_ticks_msec() / 1000.0, 0.6) < 0.3
		var base_col = Color(0.3, 0.1, 1.0, 0.4 * _orbit_circle_alpha) if flash else Color(0.6, 0.4, 1.0, 0.4 * _orbit_circle_alpha)
		var half_w = _orbiter_visual_diameter * 0.5
		if half_w < 1.0: half_w = 5.0
		const SEGS = 64
		for od in orbiter_data:
			if not is_instance_valid(od.sprite):
				continue
			var r = od.radius * _eff_radius_mult * _orbiter_radius_override
			if r < half_w: continue
			var outer_r = r + half_w
			var inner_r = r - half_w
			var angle_0 = od.angle                               # 小球当前角度=0°参考
			var z = od.z_dir                                      # 旋转方向
			for i in SEGS:
				var a1 = TAU * float(i) / SEGS
				var a2 = TAU * float(i + 1) / SEGS
				# 段中点角度距小球的角差（沿运动方向）
				var mid = (a1 + a2) * 0.5
				var da = fposmod((mid - angle_0) * z, TAU)       # 0~TAU
				var seg_alpha: float
				if da <= PI * 0.25:
					seg_alpha = base_col.a                         # 0~45° 全量
				elif da <= PI * 0.5:
					seg_alpha = base_col.a * (1.0 - (da - PI * 0.25) / (PI * 0.25))   # 45~90° 渐隐
				elif da >= TAU - deg_to_rad(15.0):
					seg_alpha = base_col.a * (1.0 - (TAU - da) / deg_to_rad(15.0))   # 后方15° 渐隐至0
				else:
					seg_alpha = 0.0                                # 90~345° 完全透明
				if seg_alpha < 0.005: continue
				var col = Color(base_col.r, base_col.g, base_col.b, seg_alpha)
				var pts = PackedVector2Array([
					Vector2(cos(a1) * outer_r, sin(a1) * outer_r),
					Vector2(cos(a2) * outer_r, sin(a2) * outer_r),
					Vector2(cos(a2) * inner_r, sin(a2) * inner_r),
					Vector2(cos(a1) * inner_r, sin(a1) * inner_r),
				])
				draw_colored_polygon(pts, col)

	# 条形警戒框（技能1/5 通用）
	if _warn_list.is_empty():
		return
	for w in _warn_list:
		var from = w.from
		var to = w.to
		var dir = (to - from).normalized()
		if dir.length() < 0.01: continue
		var perp = Vector2(-dir.y, dir.x)
		var max_t = w.get("max_timer", WARN_DURATION)
		var full_half_w = w.get("full_half_w", 54.0)
		var elapsed = max_t - w.timer
		var half_w = full_half_w
		var alpha_mod = 1.0
		if elapsed < 0.3:
			# 淡入：宽度从 0 到目标 + alpha 从 0 到 1
			half_w = full_half_w * (elapsed / 0.3)
			alpha_mod = elapsed / 0.3
		elif w.timer < 0.3:
			# 淡出：宽度扩大 + alpha 降低
			var t2 = 1.0 - w.timer / 0.3
			half_w = full_half_w * (1.0 + t2)
			alpha_mod = 1.0 - t2
		if half_w < 0.5 or alpha_mod < 0.02: continue
		var flash = fmod(Time.get_ticks_msec() / 1000.0, 0.6) < 0.3
		var base_col = Color(1, 0.05, 0.05, 0.3) if flash else Color(1, 0.8, 0.05, 0.3)
		var col = Color(base_col.r, base_col.g, base_col.b, base_col.a * alpha_mod)
		var length = from.distance_to(to)
		const SEGS = 40
		for i in SEGS:
			var t0 = float(i) / SEGS
			var t1 = float(i + 1) / SEGS
			var p_a = from + dir * t0 * length
			var p_b = from + dir * t1 * length
			var pts = PackedVector2Array([
				p_a + perp * half_w, p_a - perp * half_w,
				p_b - perp * half_w, p_b + perp * half_w,
			])
			draw_colored_polygon(pts, col)


func _draw_laser_arm(center: Vector2, dir: Vector2, perp: Vector2, length: float, half_w: float, col: Color) -> void:
	var pts = PackedVector2Array([
		center + dir * length + perp * half_w,
		center + dir * length - perp * half_w,
		center - dir * length - perp * half_w,
		center - dir * length + perp * half_w,
	])
	draw_colored_polygon(pts, col)


## ── 受击 ──

func _on_body_area_entered(area: Area2D) -> void:
	if entering or dying:
		return
	if area.is_in_group(&"player"):
		if area.has_method(&"take_knockback_damage"):
			var dir = (area.global_position - global_position).normalized()
			area.take_knockback_damage(body_touch_dmg, 1000.0, 0.5, dir)
	# 玩家子弹命中（子弹 mask=1 检测不到 layer=2 的 Boss，由 Boss 侧处理）
	elif area.get(&"atk") != null:
		apply_damage(area.atk)
		if is_instance_valid(area):
			area.queue_free()
	# 敌机被吸入碰撞 → 直接爆炸死亡（仅技能4吸力期间）
	elif _suction_active and area.is_in_group(&"enemies") and area.has_method(&"take_damage"):
		area.take_damage(9999)


func _on_orbiter_area_entered(area: Area2D) -> void:
	if entering or dying:
		return
	if area.is_in_group(&"player"):
		if area.has_method(&"take_knockback_damage"):
			var dir = (area.global_position - global_position).normalized()
			area.take_knockback_damage(orbiter_touch_dmg, 1200.0, 0.4, dir)
	# 玩家子弹命中
	elif area.get(&"atk") != null:
		apply_damage(area.atk)
		if is_instance_valid(area):
			area.queue_free()
	# 敌机碰撞轨道小球 → 爆炸死亡（仅技能4吸力期间）
	elif _suction_active and area.is_in_group(&"enemies") and area.has_method(&"take_damage"):
		area.take_damage(9999)


func apply_damage(amount: int) -> void:
	if entering or dying:
		return
	boss_hp -= amount
	if boss_hp <= 0:
		boss_hp = 0
		_die()
	else:
		_play_sfx(HIT_SFX, -5)
		# 受击闪白
		var tw_white = create_tween()
		tw_white.set_parallel(true)
		tw_white.tween_property(body_sprite, "modulate", Color.WHITE, 0.05)
		tw_white.tween_property(body_sprite, "modulate", Color(1, 1, 1, 1), 0.05).set_delay(0.05)
		if _ghost_red:
			tw_white.tween_property(_ghost_red, "modulate", Color.WHITE, 0.05)
			tw_white.tween_property(_ghost_red, "modulate", Color(1, 0.3, 0.3, 1), 0.05).set_delay(0.05)
		if _ghost_blue:
			tw_white.tween_property(_ghost_blue, "modulate", Color.WHITE, 0.05)
			tw_white.tween_property(_ghost_blue, "modulate", Color(0.3, 0.3, 1, 1), 0.05).set_delay(0.05)


## ── 死亡 ──

func _die() -> void:
	if dying:
		return
	active = false
	dying = true
	is_executing = false
	death_timer = 0.0
	death_explosion_cd = 0.0
	death_sfx_cd = 0.0
	bgm_player.stop()
	GameManager.bgm_player.play()

	for tw in _skill_tweens:
		if is_instance_valid(tw) and tw.is_valid():
			tw.kill()
	_skill_tweens.clear()

	_cleanup_skill_2()
	_cross_lasers.clear()
	_warn_list.clear()
	_revert_roar(true)

	body_sprite.modulate = Color(0.35, 0.35, 0.4, 1)
	if _ghost_red:
		_ghost_red.modulate = Color(0.35, 0.35, 0.4, 1)
	if _ghost_blue:
		_ghost_blue.modulate = Color(0.35, 0.35, 0.4, 1)
	for od in orbiter_data:
		if is_instance_valid(od.sprite):
			od.sprite.modulate = Color(0.35, 0.35, 0.4, 1)


func _death_process(delta: float) -> void:
	death_timer += delta
	death_explosion_cd -= delta
	death_sfx_cd -= delta

	if death_explosion_cd <= 0.0:
		_spawn_death_explosion()
		death_explosion_cd = randf_range(1.0 / 45.0, 1.0 / 30.0)
		if death_sfx_cd <= 0.0:
			_play_sfx(EXPLOSION_SFX, -8)
			death_sfx_cd = 0.15

	_shake_parts()

	if death_timer >= DEATH_DURATION and not won:
		won = true
		_spawn_final_explosion()
		queue_free()
		_return_to_menu()


func _spawn_death_explosion() -> void:
	for part in [body_sprite] + orbiter_data.map(func(od): return od.sprite):
		if not is_instance_valid(part):
			continue
		var pos: Vector2 = part.global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
		if pos.x < 0 or pos.x > screen_size.x or pos.y < 0 or pos.y > screen_size.y:
			continue
		var exp = Sprite2D.new()
		exp.set_script(ExplosionScript)
		exp.texture = EXPLOSION_TEX
		exp.position = pos
		exp.rotation = randf_range(0, TAU)
		exp.scale = Vector2(0.5, 0.5)
		exp.z_index = 2000
		get_tree().current_scene.add_child(exp)
		_spawn_debris(pos, randi_range(3, 6), orbiter_tex)


func _shake_parts() -> void:
	body_sprite.position = Vector2(randf_range(-25, 25), randf_range(-20, 20))
	var ghost_dist = 20.0
	if _ghost_red:
		_ghost_red.position = body_sprite.position - Vector2(ghost_dist, 0)
	if _ghost_blue:
		_ghost_blue.position = body_sprite.position + Vector2(ghost_dist, 0)
	for od in orbiter_data:
		if not is_instance_valid(od.sprite):
			continue
		var r = od.radius * _eff_radius_mult * _orbiter_radius_override
		var a = od.angle + randf_range(-0.15, 0.15)
		od.sprite.position = Vector2(cos(a) * r, sin(a) * r) + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		if is_instance_valid(od.area):
			od.area.position = od.sprite.position
	var cam = get_viewport().get_camera_2d()
	if cam:
		cam.offset = Vector2(randf_range(-15, 15), randf_range(-10, 10))


func _spawn_final_explosion() -> void:
	_play_sfx(EXPLOSION_SFX, 0)
	var origins = randi_range(20, 30)
	for _i in origins:
		var pos = Vector2(
			randf_range(position.x - 200, position.x + 200),
			randf_range(position.y - 200, position.y + 200)
		)
		var exp = Sprite2D.new()
		exp.set_script(ExplosionScript)
		exp.texture = EXPLOSION_TEX
		exp.position = pos
		exp.rotation = randf_range(0, TAU)
		exp.scale = Vector2(1.2, 1.2)
		exp.z_index = 2000
		get_tree().current_scene.add_child(exp)
		_spawn_debris(pos, randi_range(6, 10), orbiter_tex)


func _spawn_debris(pos: Vector2, count: int, tex = null) -> void:
	var use_tex = tex if tex else DEBRIS_TEX
	var is_sheet = use_tex == DEBRIS_TEX
	var sc_min = 0.01 if not is_sheet else 0.05
	var sc_max = 0.03 if not is_sheet else 0.08
	const QUAD = 512
	for _i in count:
		var d = Sprite2D.new()
		d.set_script(DebrisScript)
		d.texture = use_tex
		d.position = pos
		d.scale = Vector2(randf_range(sc_min, sc_max), randf_range(sc_min, sc_max))
		d.rotation = randf_range(0, TAU)
		if is_sheet:
			d.region_enabled = true
			d.region_rect = Rect2(randi_range(0, 1) * QUAD, randi_range(0, 1) * QUAD, QUAD, QUAD)
		var a = randf_range(0, TAU)
		d.velocity = Vector2(cos(a), sin(a)) * randf_range(80, 200)
		d.rotation_speed = randf_range(-10, 10)
		d.z_index = 2000
		get_tree().current_scene.add_child(d)


func _return_to_menu() -> void:
	await get_tree().create_timer(2.5).timeout
	if get_tree():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


## ── 进场黑幕 ──

func _create_entrance_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100
	overlay_layer.follow_viewport_enabled = true
	overlay_rect = ColorRect.new()
	overlay_rect.color = Color(0, 0, 0, 0)
	overlay_rect.anchor_left = 0.0; overlay_rect.anchor_top = 0.0
	overlay_rect.anchor_right = 1.0; overlay_rect.anchor_bottom = 1.0
	overlay_rect.offset_left = -150; overlay_rect.offset_top = -150
	overlay_rect.offset_right = 150; overlay_rect.offset_bottom = 150
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_label = Label.new()
	overlay_label.text = boss_name
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label.modulate = Color(1, 1, 1, 0)
	overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_label.add_theme_font_size_override(&"font_size", 72)
	overlay_layer.add_child(overlay_rect)
	overlay_layer.add_child(overlay_label)
	add_child(overlay_layer)


func _start_bgm() -> void:
	if GameManager.bgm_player.playing:
		GameManager.bgm_player.stop()
	bgm_player.play.call_deferred()


## ── 音效工具 ──

func _play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
