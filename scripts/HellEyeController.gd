extends Node2D

enum Dock { HOME, LEFT, RIGHT, BOTTOM }

# ═══════════ 基本属性 ═══════════
@export var max_hp: int = 1000
@export var boss_name: String = "地狱之眼"
@export var spawn_y_ratio: float = 0.4
var boss_hp: int
var screen_size: Vector2

# ═══════════ 生命周期标志 ═══════════
var active: bool = false
var entering: bool = true
var dying: bool = false

# ═══════════ 主体外观 ═══════════
@export var body_scale_value: float = 1.0
@export var body_collision_radius: float = 150.0
@export var body_touch_dmg: int = 30
@export var pulse_amplitude: float = 0.006
@export var pulse_speed: float = 3.0
var pulse_phase: float = 0.0
var body_sprite: Sprite2D
var _ghost_red: Sprite2D
var _ghost_blue: Sprite2D
var _eff_body_mult: float = 1.0
var _eff_pulse_mult: float = 1.0
var _eff_freq_mult: float = 1.0
var _eff_speed_mult: float = 1.0
var _eff_radius_mult: float = 1.0

# 待机位置
var _home_position: Vector2
var _initial_position: Vector2

# ═══════════ 技能 ═══════════
@export var has_skill_1: bool = true
@export var has_skill_2: bool = true
@export var has_skill_3: bool = true
@export var has_skill_4: bool = true
@export var has_skill_5: bool = true
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
var _last_skill: int = 0

# 测试模式
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

# ═══════════ Tween 管理 ═══════════
var _skill_tweens: Array[Tween] = []

# ═══════════ 警戒框 ═══════════
var _warn_list: Array = []
var _warn_circle: Dictionary = {}
const WARN_DURATION: float = 3.0

## 地狱之眼 —— 特殊 Boss
## 视觉：红色星云 + 眼珠，通过眼形遮罩裁剪显示（shader 裁剪）
## 碰撞箱始终位于眼珠处
## 技能待重做

const HELL_EYE_BGM = preload("res://assets/audio/hell_eye_boss_bgm_2.mp3")

@onready var _nebula_sprite: Sprite2D = null
@onready var _nebula_mat: ShaderMaterial = null
@onready var _eye_mat: ShaderMaterial = null
@onready var _stroke_sprite: Sprite2D = null

@export var mask_scale: Vector2 = Vector2(0.27, 0.27)
@export var mask_rotation_deg: float = 0.0
@export var nebula_scale: Vector2 = Vector2(0.405, 0.405)
@export var nebula_offset: Vector2 = Vector2(0, 0)
@export var eyeball_scale: Vector2 = Vector2(0.27, 0.27)
@export var eyeball_offset: Vector2 = Vector2(0, 0)
@export var mask_stroke_thickness: float = 3.0
@export var mask_stroke_jitter: float = 1.5
@export var mask_stroke_color: Color = Color.BLACK

const MASK_TEX_SIZE: float = 1024.0

var _mask_tex: Texture2D

const EYE_WIDE_DURATION: float = 2.5
const EYE_SQUINT_DURATION: float = 1.8
const EYE_BLINK_DURATION: float = 0.35
const EYE_NORMAL_DURATION: float = 0.6
const EYE_WIDE_Y: float = 2.0
const EYE_SQUINT_Y: float = 0.3
const EYE_BLINK_MIN: float = 0.04
const EYE_SHAKE_STRENGTH: float = 15
const EYEBALL_TRACK_PX: float = 20.0
const EYE_CONTENT_SHRINK: float = 1.4286

enum EyeAction { WIDE, SQUINT, BLINK }
var _eye_action: int = EyeAction.WIDE
var _eye_is_returning: bool = false
var _eye_anim_timer: float = EYE_WIDE_DURATION
var _eye_y_mult: float = 1.0
var _eye_blink_t: float = 0.0
var _breath_t: float = 0.0
var _eyeball_content_mult: float = 1.0

const BREATH_PERIOD: float = 3.0
const BREATH_MIN: float = 0.75
const BREATH_MAX: float = 1.25

# 技能1：眯眼激光
const SKILL_1_WARN_TIME: float = 1.5
const SKILL_1_LASER_TIME: float = 0.3
const SKILL_1_HALF_WIDTH: float = 15.0
const SKILL_1_SCREEN_EXTEND: float = 1200.0
const SKILL_1_LASER_DMG: int = 5
var _skill_1_active: bool = false
var _skill_1_data: Array[Dictionary] = []

# 技能2：瞪眼收缩环
const SKILL_2_RING_COUNT_MIN: int = 3
const SKILL_2_RING_COUNT_MAX: int = 6
const SKILL_2_SHRINK_MIN: float = 2.0
const SKILL_2_SHRINK_MAX: float = 3.0
const SKILL_2_INTERVAL_MIN: float = 0.5
const SKILL_2_INTERVAL_MAX: float = 1.0
const SKILL_2_INIT_RADIUS: float = 800.0
const SKILL_2_INIT_THICKNESS: float = 30.0
var _skill_2_active: bool = false
var _skill_2_data: Array[Dictionary] = []
var _skill_2_cooling: float = 0.0
const SKILL_2_COOLING_DURATION: float = 1.5
var _ring_hit_cd: float = 0.0
const RING_HIT_DAMAGE: int = 10

# 技能3：闭眼传送
var _skill_3_active: bool = false
var _skill_3_opening: bool = false
const SKILL_3_ANIM_SPEED: float = 6.0

var _hit_squinting: float = 0.0
const HIT_SQUINT_DURATION: float = 0.5

# 技能4：瞪眼红幕扭曲
var _skill_4_active: bool = false
var _skill_4_ring_data: Dictionary = {}
var _skill_4_overlay: CanvasLayer = null
var _skill_4_overlay_rect: ColorRect = null
var _skill_4_overlay_mat: ShaderMaterial = null
var _skill_4_overlay_state: int = 0
var _skill_4_overlay_timer: float = 0.0
var _skill_4_overlay_duration: float = 0.0
var _skill_4_cooling: float = 0.0
const SKILL_4_COOLING_DURATION: float = 0.8
var _skill_4_error_labels: Array = []
var _skill_4_error_cooldown: float = 0.0

var _whisper_player: AudioStreamPlayer

# 技能6：瞪眼分身
var _skill_6_active: bool = false
var _skill_6_minis: Array = []
const SKILL_6_MIN_COUNT: int = 15
const SKILL_6_MAX_COUNT: int = 20
const SKILL_6_DUR_MIN: float = 5.0
const SKILL_6_DUR_MAX: float = 8.0
const SKILL_6_MIN_DIST: float = 100.0
const SKILL_6_SPAWN_MARGIN: float = 80.0
const MiniHellEyeScript = preload("res://scripts/MiniHellEye.gd")
@export var skill_4_ring_grow_speed: float = 1000.0
@export var skill_4_overlay_dur_min: float = 8.0
@export var skill_4_overlay_dur_max: float = 12.0
@export var skill_4_fade_time: float = 1.5

var _theme_color: Color = Color(0.85, 0.06, 0.06, 1.0)
var _warn_color: Color = Color(0.85, 0.06, 0.06, 0.7)
var _laser_color: Color = Color(0.7, 0.1, 0.1, 0.8)
var _laser_glow_color: Color = Color(0.3, 0.02, 0.02, 0.24)

var _death_particle_color: Color = Color(0.8, 0.1, 0.1, 1.0)
var _death_particle_timer: float = 0.0
var _death_particle_tex: Texture2D


func _setup_body() -> void:
	_mask_tex = preload("res://assets/images/helleye/mask_alpha.png")
	var nebula_tex = preload("res://assets/images/helleye/nebula_raw.png")
	var eyeball_tex = preload("res://assets/images/helleye/eyeball_cutout.png")
	var clip_shader = preload("res://assets/images/helleye/eye_clip.gdshader")

	# 描边（黑底 mask 贴图层，代码抖动，非 shader 方案）
	_stroke_sprite = Sprite2D.new()
	_stroke_sprite.texture = _mask_tex
	_stroke_sprite.centered = true
	_stroke_sprite.self_modulate = mask_stroke_color
	_stroke_sprite.z_index = -3
	add_child(_stroke_sprite)

	# 红色星云（shader 裁剪）
	_nebula_sprite = Sprite2D.new()
	_nebula_sprite.texture = nebula_tex
	_nebula_sprite.centered = true
	_nebula_sprite.scale = nebula_scale
	_nebula_sprite.position = nebula_offset
	_nebula_sprite.z_index = -2
	_nebula_mat = ShaderMaterial.new()
	_nebula_mat.shader = clip_shader
	_nebula_mat.set_shader_parameter(&"mask_tex", _mask_tex)
	_nebula_sprite.material = _nebula_mat
	add_child(_nebula_sprite)

	# 眼珠（shader 裁剪）
	body_sprite = Sprite2D.new()
	body_sprite.texture = eyeball_tex
	body_sprite.centered = true
	body_sprite.scale = eyeball_scale
	body_sprite.position = eyeball_offset
	body_sprite.z_index = -1
	_eye_mat = ShaderMaterial.new()
	_eye_mat.shader = clip_shader
	_eye_mat.set_shader_parameter(&"mask_tex", _mask_tex)
	body_sprite.material = _eye_mat
	add_child(body_sprite)

	# 碰撞体
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

	_sync_mask_params()


func _setup_orbiters() -> void:
	pass


func _on_body_area_entered(area: Area2D) -> void:
	if entering or dying or _skill_3_active:
		return
	if area.is_in_group(&"player"):
		return
	if area.get(&"atk") != null:
		apply_damage(area.atk)
		if is_instance_valid(area):
			area.queue_free()


func apply_damage(amount: int) -> void:
	if _skill_3_active:
		return
	boss_hp -= amount
	if boss_hp <= 0:
		boss_hp = 0
		_die()
	else:
		_play_sfx(HIT_SFX, -5)
	if boss_hp > 0 and not _skill_1_active and not _skill_2_active and _skill_2_cooling <= 0.0 and not _skill_3_active and not _skill_4_active and _skill_4_cooling <= 0.0 and not _skill_6_active:
		_hit_squinting = HIT_SQUINT_DURATION


func _idle_animation(delta: float) -> void:
	if not entering and not _skill_1_active and not _skill_2_active and _skill_2_cooling <= 0.0 and not _skill_3_active and _hit_squinting <= 0.0 and not _skill_4_active and _skill_4_cooling <= 0.0 and not _skill_6_active:
		_apply_idle_breath(delta)
	if _skill_1_active:
		_eye_y_mult = lerpf(_eye_y_mult, EYE_SQUINT_Y, delta * 8.0)
		_eyeball_content_mult = lerpf(_eyeball_content_mult, 1.0, delta * 8.0)
		_update_skill_1_data(delta)
	elif _skill_2_active:
		_eye_y_mult = lerpf(_eye_y_mult, EYE_WIDE_Y, delta * 8.0)
		_eyeball_content_mult = lerpf(_eyeball_content_mult, EYE_CONTENT_SHRINK, delta * 8.0)
		_update_skill_2_data(delta)
	elif _skill_2_cooling > 0.0:
		_skill_2_cooling -= delta
		var t = clampf(1.0 - _skill_2_cooling / SKILL_2_COOLING_DURATION, 0.0, 1.0)
		var e = t * t * (3.0 - 2.0 * t)
		_eye_y_mult = lerpf(EYE_WIDE_Y, 1.0, e)
		_eyeball_content_mult = lerpf(EYE_CONTENT_SHRINK, 1.0, e)
		_update_skill_2_data(delta)
	elif _skill_3_active:
		var target_y = 1.0 if _skill_3_opening else 0.0
		_eye_y_mult = lerpf(_eye_y_mult, target_y, delta * SKILL_3_ANIM_SPEED)
		_eyeball_content_mult = lerpf(_eyeball_content_mult, 1.0, delta * SKILL_3_ANIM_SPEED)
	elif _hit_squinting > 0.0:
		_hit_squinting -= delta
		var t = 1.0 - _hit_squinting / HIT_SQUINT_DURATION
		var target_y: float
		if t < 0.5:
			target_y = lerpf(1.0, EYE_SQUINT_Y, t * 2.0)
		else:
			target_y = lerpf(EYE_SQUINT_Y, 1.0, (t - 0.5) * 2.0)
		_eye_y_mult = lerpf(_eye_y_mult, target_y, delta * 12.0)
		_eyeball_content_mult = lerpf(_eyeball_content_mult, 1.0, delta * 8.0)
	elif _skill_4_active:
		_eye_y_mult = lerpf(_eye_y_mult, EYE_WIDE_Y, delta * 8.0)
		_eyeball_content_mult = lerpf(_eyeball_content_mult, EYE_CONTENT_SHRINK, delta * 8.0)
	elif _skill_4_cooling > 0.0:
		_skill_4_cooling -= delta
		var t = clampf(1.0 - _skill_4_cooling / SKILL_4_COOLING_DURATION, 0.0, 1.0)
		var e = t * t * (3.0 - 2.0 * t)
		_eye_y_mult = lerpf(EYE_WIDE_Y, 1.0, e)
		_eyeball_content_mult = lerpf(EYE_CONTENT_SHRINK, 1.0, e)
	elif _skill_6_active:
		_eye_y_mult = lerpf(_eye_y_mult, EYE_WIDE_Y, delta * 8.0)
		_eyeball_content_mult = lerpf(_eyeball_content_mult, EYE_CONTENT_SHRINK, delta * 8.0)
		_apply_eyeball_shake()
		_apply_screen_shake(delta)
	elif not entering:
		_process_eye_animation(delta)
	if _skill_4_overlay_state > 0:
		_update_skill_4_overlay(delta)
	if not _skill_1_data.is_empty() and not _skill_1_active:
		_update_skill_1_data(delta)
	if not _skill_2_data.is_empty() and not _skill_2_active and _skill_2_cooling <= 0.0:
		_update_skill_2_data(delta)
	_sync_mask_params()
	_track_player_eyeball()
	_apply_stroke_jitter()
	if is_instance_valid(_stroke_sprite):
		var stroke_alpha = clampf((_eye_y_mult - 0.01) / 0.09, 0.0, 1.0)
		_stroke_sprite.self_modulate = Color(mask_stroke_color.r, mask_stroke_color.g, mask_stroke_color.b, mask_stroke_color.a * stroke_alpha)


func _update_skill_2_data(delta: float) -> void:
	var to_remove: Array = []
	for i in _skill_2_data.size():
		var d = _skill_2_data[i]
		d.timer -= delta
		d.elapsed += delta
		if d.timer <= 0.0:
			to_remove.append(i)
	_ring_hit_cd -= delta
	if _ring_hit_cd <= 0.0:
		var player = get_tree().get_first_node_in_group(&"player")
		if is_instance_valid(player):
			_check_ring_hit_player(player)
	for i in range(to_remove.size() - 1, -1, -1):
		_skill_2_data.remove_at(to_remove[i])
	if not _skill_2_data.is_empty():
		queue_redraw()


func _check_ring_hit_player(player: Node2D) -> void:
	var ppos = player.global_position
	for d in _skill_2_data:
		if d.get("has_hit_player", false):
			continue
		var progress = 1.0 - d.timer / d.total_time
		var radius = SKILL_2_INIT_RADIUS * (1.0 - progress)
		var thickness = SKILL_2_INIT_THICKNESS * (1.0 - progress)
		if thickness < 0.5:
			continue
		var inner_r = radius - thickness * 0.5
		var outer_r = radius + thickness * 0.5
		var dist = ppos.distance_to(d.center)
		var angle_to_player = (ppos - d.center).angle()
		var gap_start = d.gap_angle
		var gap_end = gap_start + deg_to_rad(d.gap_size)
		var pa = fposmod(angle_to_player, TAU)
		var gs = fposmod(gap_start, TAU)
		var ge = fposmod(gap_end, TAU)
		var in_gap = false
		if ge > gs:
			in_gap = pa >= gs and pa <= ge
		else:
			in_gap = pa >= gs or pa <= ge
		if not in_gap and inner_r < 40.0:
			player.take_damage_from_boss(RING_HIT_DAMAGE)
			d.has_hit_player = true
			_ring_hit_cd = 0.3
			return
		if dist >= inner_r and dist <= outer_r:
			if not in_gap:
				player.take_damage_from_boss(RING_HIT_DAMAGE)
				d.has_hit_player = true
				_ring_hit_cd = 0.3
				return


func _update_skill_1_data(delta: float) -> void:
	var to_remove: Array = []
	for i in _skill_1_data.size():
		var d = _skill_1_data[i]
		d.timer -= delta
		if d.phase == 0:
			if d.timer <= 0.0:
				d.phase = 1
				d.timer = SKILL_1_LASER_TIME
		else:
			if d.timer <= 0.0:
				to_remove.append(i)
	for i in range(to_remove.size() - 1, -1, -1):
		_skill_1_data.remove_at(to_remove[i])
	if not _skill_1_data.is_empty():
		_check_skill_1_laser_hit()
		queue_redraw()


func _apply_idle_breath(delta: float) -> void:
	_breath_t += delta / BREATH_PERIOD
	_eye_y_mult = lerpf(BREATH_MIN, BREATH_MAX, (sin(_breath_t * TAU) + 1.0) * 0.5)


func _process_eye_animation(delta: float) -> void:
	_eye_anim_timer -= delta
	if _eye_anim_timer <= 0.0:
		if _eye_is_returning:
			_eye_action = (_eye_action + 1) % 3
			_eye_is_returning = false
			match _eye_action:
				EyeAction.WIDE:
					_eye_anim_timer = EYE_WIDE_DURATION
				EyeAction.SQUINT:
					_eye_anim_timer = EYE_SQUINT_DURATION
				EyeAction.BLINK:
					_eye_anim_timer = EYE_BLINK_DURATION
					_eye_blink_t = 0.0
		else:
			_eye_is_returning = true
			_eye_anim_timer = EYE_NORMAL_DURATION

	if _eye_is_returning:
		_eye_y_mult = lerpf(_eye_y_mult, 1.0, delta * 8.0)
		_eyeball_content_mult = lerpf(_eyeball_content_mult, 1.0, delta * 8.0)
		return

	match _eye_action:
		EyeAction.WIDE:
			_eye_y_mult = lerpf(_eye_y_mult, EYE_WIDE_Y, delta * 8.0)
			_eyeball_content_mult = lerpf(_eyeball_content_mult, 1.0, delta * 8.0)
			_apply_eyeball_shake()
		EyeAction.SQUINT:
			_eye_y_mult = lerpf(_eye_y_mult, EYE_SQUINT_Y, delta * 8.0)
			_eyeball_content_mult = lerpf(_eyeball_content_mult, 1.0, delta * 8.0)
		EyeAction.BLINK:
			_eye_blink_t += delta / EYE_BLINK_DURATION
			if _eye_blink_t < 0.5:
				_eye_y_mult = lerpf(1.0, EYE_BLINK_MIN, _eye_blink_t * 2.0)
			else:
				_eye_y_mult = lerpf(EYE_BLINK_MIN, 1.0, (_eye_blink_t - 0.5) * 2.0)
			_eyeball_content_mult = lerpf(_eyeball_content_mult, 1.0, delta * 8.0)


func _apply_eyeball_shake() -> void:
	if not is_instance_valid(_eye_mat):
		return
	var t = Time.get_ticks_msec() / 1000.0
	var sx = sin(t * 43.0) * cos(t * 37.0) * EYE_SHAKE_STRENGTH / (MASK_TEX_SIZE * eyeball_scale.x)
	var sy = cos(t * 31.0) * sin(t * 41.0) * EYE_SHAKE_STRENGTH / (MASK_TEX_SIZE * eyeball_scale.y)
	var d = _get_player_dir()
	var bx = -d.x * EYEBALL_TRACK_PX / (MASK_TEX_SIZE * eyeball_scale.x)
	var by = -d.y * EYEBALL_TRACK_PX / (MASK_TEX_SIZE * eyeball_scale.y)
	_eye_mat.set_shader_parameter(&"content_offset", Vector2(bx + sx, by + sy))


func _apply_screen_shake(_delta: float) -> void:
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
	cam.offset = Vector2(
		sin(Time.get_ticks_msec() * 0.03) * 8.0,
		cos(Time.get_ticks_msec() * 0.037) * 6.0
	)


func _reset_screen_shake() -> void:
	var cam = get_viewport().get_camera_2d()
	if cam:
		cam.offset = Vector2.ZERO


func _start_entrance() -> void:
	entering = true
	entrance_timer = 0.0
	_eye_y_mult = 0.02
	position = Vector2(screen_size.x * 0.5, screen_size.y * spawn_y_ratio)


func _sync_mask_params() -> void:
	var rot = deg_to_rad(mask_rotation_deg)
	var my = _eye_y_mult
	for mat in [_nebula_mat, _eye_mat]:
		if not is_instance_valid(mat):
			continue
		mat.set_shader_parameter(&"mask_tex", _mask_tex)
		mat.set_shader_parameter(&"mask_rotation", rot)

	if is_instance_valid(_nebula_mat):
		var ns = Vector2(nebula_scale.x / mask_scale.x, nebula_scale.y / (mask_scale.y * my))
		_nebula_mat.set_shader_parameter(&"mask_scale", ns)
		_nebula_mat.set_shader_parameter(&"mask_offset_uv", nebula_offset / (MASK_TEX_SIZE * mask_scale))
		_nebula_mat.set_shader_parameter(&"content_scale", Vector2.ONE)
		_nebula_mat.set_shader_parameter(&"content_offset", Vector2.ZERO)

	if is_instance_valid(_eye_mat):
		var es = Vector2(eyeball_scale.x / mask_scale.x, eyeball_scale.y / (mask_scale.y * my))
		var cs = _eyeball_content_mult
		_eye_mat.set_shader_parameter(&"mask_scale", es)
		_eye_mat.set_shader_parameter(&"mask_offset_uv", eyeball_offset / (MASK_TEX_SIZE * mask_scale))
		_eye_mat.set_shader_parameter(&"content_scale", Vector2(cs, cs))

	if is_instance_valid(_stroke_sprite):
		var th = mask_stroke_thickness / MASK_TEX_SIZE
		_stroke_sprite.rotation = -rot
		_stroke_sprite.scale = Vector2(mask_scale.x + th, mask_scale.y * my + th)
		_stroke_sprite.self_modulate = mask_stroke_color


func _track_player_eyeball() -> void:
	if not is_instance_valid(_eye_mat):
		return
	var d = _get_player_dir()
	var uv_x = -d.x * EYEBALL_TRACK_PX / (MASK_TEX_SIZE * eyeball_scale.x)
	var uv_y = -d.y * EYEBALL_TRACK_PX / (MASK_TEX_SIZE * eyeball_scale.y)
	_eye_mat.set_shader_parameter(&"content_offset", Vector2(uv_x, uv_y))


func _draw() -> void:
	var screen_center = screen_size * 0.5
	for d in _skill_1_data:
		var pos = to_local(d.pos)
		var angle = d.angle
		var dir = Vector2.RIGHT.rotated(angle)
		var perp = Vector2(-dir.y, dir.x)
		if d.phase == 0:
			_draw_skill_1_warn(d, pos, dir, perp)
		else:
			_draw_skill_1_laser(d, pos, dir, perp)
	for d in _skill_2_data:
		_draw_skill_2_ring(d)
	if not _skill_4_ring_data.is_empty():
		_draw_skill_4_ring()


func _draw_skill_1_warn(d: Dictionary, pos: Vector2, dir: Vector2, perp: Vector2) -> void:
	var warn_time = SKILL_1_WARN_TIME
	var gap_half = SKILL_1_HALF_WIDTH * (d.timer / warn_time)
	var alpha = 1.0 - d.timer / warn_time
	if alpha < 0.02:
		return
	var col = _warn_color
	col.a = _warn_color.a * alpha
	var half_len = SKILL_1_SCREEN_EXTEND * 0.5
	var start_pt = pos - dir * half_len
	var end_pt = pos + dir * half_len
	const LINE_WIDTH = 3.0
	for sign in [-1.0, 1.0]:
		var offset = perp * gap_half * sign
		draw_line(start_pt + offset, end_pt + offset, col, LINE_WIDTH)


func _draw_skill_1_laser(d: Dictionary, pos: Vector2, dir: Vector2, perp: Vector2) -> void:
	var total_time = SKILL_1_LASER_TIME
	var elapsed = total_time - d.timer
	var t = clampf(elapsed / total_time, 0.0, 1.0)
	var width = 5.0 * sin(PI * t)
	var half_w = width * 0.5
	if half_w < 0.15:
		return
	var full_len = SKILL_1_SCREEN_EXTEND * 0.5
	var core_len = full_len * 0.75
	var tail_len = full_len - core_len
	var alpha = sin(PI * t) * 0.8
	var col = _laser_color
	col.a = _laser_color.a * (alpha / 0.8)
	var glow_col = _laser_glow_color
	glow_col.a = _laser_glow_color.a * (alpha / 0.8)
	var glow_w = half_w * 3.0
	for i in [1, -1]:
		var start_pos = pos
		var end_pos = pos + dir * core_len * i
		var glow_pts = PackedVector2Array([
			start_pos + perp * glow_w, start_pos - perp * glow_w,
			end_pos - perp * glow_w, end_pos + perp * glow_w,
		])
		draw_colored_polygon(glow_pts, glow_col)
		var core_pts = PackedVector2Array([
			start_pos + perp * half_w, start_pos - perp * half_w,
			end_pos - perp * half_w, end_pos + perp * half_w,
		])
		draw_colored_polygon(core_pts, col)
	const END_SEG = 16
	for i in [1, -1]:
		for j in range(1, END_SEG + 1):
			var t0 = float(j - 1) / END_SEG
			var t1 = float(j) / END_SEG
			var seg_alpha = col.a * pow(1.0 - float(j) / END_SEG, 2.0)
			if seg_alpha < 0.005:
				continue
			var seg_col = col
			seg_col.a = col.a * pow(1.0 - float(j) / END_SEG, 2.0)
			var seg_glow = Color(0.3, 0.02, 0.02, seg_alpha * 0.3)
			var len0 = core_len + t0 * tail_len
			var len1 = core_len + t1 * tail_len
			var p0 = pos + dir * len0 * i
			var p1 = pos + dir * len1 * i
			var pts = PackedVector2Array([
				p0 + perp * half_w, p0 - perp * half_w,
				p1 - perp * half_w, p1 + perp * half_w,
			])
			draw_colored_polygon(pts, seg_col)
			var g_pts = PackedVector2Array([
				p0 + perp * glow_w, p0 - perp * glow_w,
				p1 - perp * glow_w, p1 + perp * glow_w,
			])
			draw_colored_polygon(g_pts, seg_glow)


func _draw_skill_2_ring(d: Dictionary) -> void:
	var progress = 1.0 - d.timer / d.total_time
	var radius = SKILL_2_INIT_RADIUS * (1.0 - progress)
	var thickness = SKILL_2_INIT_THICKNESS * (1.0 - progress)
	if thickness < 0.2:
		return
	var fade_in = clampf(d.elapsed / 0.5, 0.0, 1.0)
	var center = to_local(d.center)
	var gap_angle = d.gap_angle
	var gap_size = deg_to_rad(d.gap_size)
	var col = Color(_theme_color.r, _theme_color.g, _theme_color.b, 0.6 * fade_in)
	var inner_r = radius - thickness * 0.5
	var outer_r = radius + thickness * 0.5
	const ARC_SEGS = 64
	var start_angle = gap_angle + gap_size
	var end_angle = gap_angle + TAU
	var arc_span = end_angle - start_angle
	var seg_angle = arc_span / ARC_SEGS
	for i in ARC_SEGS:
		var a0 = start_angle + seg_angle * i
		var a1 = start_angle + seg_angle * (i + 1)
		var pts = PackedVector2Array([
			center + Vector2(cos(a0) * outer_r, sin(a0) * outer_r),
			center + Vector2(cos(a1) * outer_r, sin(a1) * outer_r),
			center + Vector2(cos(a1) * inner_r, sin(a1) * inner_r),
			center + Vector2(cos(a0) * inner_r, sin(a0) * inner_r),
		])
		draw_colored_polygon(pts, col)


func _get_player_dir() -> Vector2:
	var player = get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return Vector2.ZERO
	var dir = player.global_position - global_position
	if dir.length() < 0.1:
		return Vector2.ZERO
	return dir.normalized()


func _apply_stroke_jitter() -> void:
	if not is_instance_valid(_stroke_sprite):
		return
	var t = Time.get_ticks_msec() / 1000.0

	var jx = sin(t * 11.0) * cos(t * 17.0) * mask_stroke_jitter
	var jy = cos(t * 13.0) * sin(t * 19.0) * mask_stroke_jitter
	_stroke_sprite.offset = Vector2(jx, jy)

	var sx = 1.0 + sin(t * 7.0) * cos(t * 9.0) * 0.08
	var sy = 1.0 + cos(t * 8.0) * sin(t * 11.0) * 0.08
	var my = _eye_y_mult
	var th = mask_stroke_thickness / MASK_TEX_SIZE
	_stroke_sprite.scale = Vector2((mask_scale.x + th) * sx, (mask_scale.y * my + th) * sy)

	var rot = deg_to_rad(mask_rotation_deg)
	var rj = sin(t * 14.0) * cos(t * 10.0) * 0.03
	_stroke_sprite.rotation = -rot + rj


func _start_whisper() -> void:
	if not is_instance_valid(_whisper_player) or _whisper_player.playing:
		return
	_whisper_player.play()


func _stop_whisper() -> void:
	if is_instance_valid(_whisper_player) and _whisper_player.playing:
		_whisper_player.stop()


func _skill_1() -> void:
	if dying:
		return
	_skill_1_active = true
	_start_whisper()
	var skill_duration = randf_range(5.0, 10.0)
	var skill_end = Time.get_ticks_msec() / 1000.0 + skill_duration

	while Time.get_ticks_msec() / 1000.0 < skill_end:
		if dying:
			break
		_spawn_skill_eye_warns(2)
		await get_tree().create_timer(randf_range(0.4, 0.8)).timeout

	_stop_whisper()
	_skill_1_active = false
	_eye_is_returning = true
	_eye_anim_timer = EYE_NORMAL_DURATION


func _skill_6() -> void:
	if dying:
		return
	_skill_6_active = true

	var eye_dur = randf_range(SKILL_6_DUR_MIN, SKILL_6_DUR_MAX)
	var count = randi_range(8, 12)
	var mini_hp = max(1, int(max_hp * 0.02))

	# 预先计算位置
	var positions: Array[Vector2] = []
	var max_attempts = count * 50
	var attempts = 0
	var m = SKILL_6_SPAWN_MARGIN

	while positions.size() < count and attempts < max_attempts:
		attempts += 1
		var candidate = Vector2(
			randf_range(m, screen_size.x - m),
			randf_range(m, screen_size.y - m)
		)
		if candidate.distance_to(global_position) < SKILL_6_MIN_DIST:
			continue
		var valid = true
		for p in positions:
			if candidate.distance_to(p) < SKILL_6_MIN_DIST:
				valid = false
				break
		if valid:
			positions.append(candidate)

	# 瞪眼期间依次生成
	var actual_count = positions.size()
	var interval = eye_dur / float(max(1, actual_count))
	for pos in positions:
		if dying:
			break
		var sc = randf_range(0.2, 0.4)
		var mini = MiniHellEyeScript.spawn(self, pos, sc, mini_hp)
		_skill_6_minis.append(mini)
		await get_tree().create_timer(interval).timeout

	# 如果瞪眼时间还有剩余，等待结束
	var remaining = eye_dur - interval * float(actual_count)
	if remaining > 0.0 and not dying:
		await get_tree().create_timer(remaining).timeout

	if dying:
		_reset_screen_shake()
		return

	_skill_6_active = false
	_reset_screen_shake()


func _skill_2() -> void:
	if dying:
		return
	_skill_2_active = true

	# 等待瞪眼 lerp 完成（~0.6s 后 _eye_y_mult 已接近 EYE_WIDE_Y）
	await get_tree().create_timer(0.6).timeout
	if dying:
		_skill_2_active = false
		return

	var player = get_tree().get_first_node_in_group(&"player")
	var center = player.global_position if is_instance_valid(player) else screen_size * 0.5

	var count = randi_range(SKILL_2_RING_COUNT_MIN, SKILL_2_RING_COUNT_MAX)
	var total_time = randf_range(SKILL_2_SHRINK_MIN, SKILL_2_SHRINK_MAX)
	var interval = randf_range(SKILL_2_INTERVAL_MIN, SKILL_2_INTERVAL_MAX)

	for i in count:
		if dying:
			break
		var gap = randf_range(60.0, 90.0)
		var gap_angle = randf_range(0, TAU)
		_skill_2_data.append({
			"center": center,
			"gap_angle": gap_angle,
			"gap_size": gap,
			"timer": total_time,
			"total_time": total_time,
			"elapsed": 0.0,
			"has_hit_player": false,
		})
		await get_tree().create_timer(interval).timeout

	# 等最后一个环缩到0
	await get_tree().create_timer(total_time).timeout
	if dying:
		_skill_2_active = false
		return

	_skill_2_active = false
	_skill_2_cooling = SKILL_2_COOLING_DURATION


func _skill_3() -> void:
	if dying:
		return
	_skill_3_active = true
	_skill_3_opening = false

	# 等待彻底闭眼（_eye_y_mult < 0.01）
	while _eye_y_mult > 0.02 and not dying:
		await get_tree().create_timer(0.02).timeout
	if dying:
		_skill_3_active = false
		return

	var pause_duration = randf_range(3.0, 5.0)
	var pause_elapsed = 0.0
	var enemy_count = randi_range(8, 12)
	var spawned = 0
	var spawn_interval = pause_duration / float(enemy_count)

	# 预先生成敌机类型列表（轰炸机至多3个，其余随机分配）
	var enemy_types: Array[String] = []
	var bombers_assigned = randi_range(0, min(3, enemy_count))
	for _i in bombers_assigned:
		enemy_types.append("res://scenes/EnemyBomber.tscn")
	while enemy_types.size() < enemy_count:
		var t = "res://scenes/EnemyRammer.tscn" if randf() < 0.5 else "res://scenes/EnemyScatter.tscn"
		enemy_types.append(t)
	enemy_types.shuffle()

	while pause_elapsed < pause_duration and not dying:
		# 第 1s 时传送
		if pause_elapsed >= 1.0 and pause_elapsed - 0.02 < 1.0:
			var margin = 100.0
			position = Vector2(
				randf_range(margin, screen_size.x - margin),
				randf_range(margin, screen_size.y - margin)
			)
			mask_rotation_deg = randf_range(0.0, 360.0)

		# 敌机生成
		while spawned < enemy_count and pause_elapsed >= spawn_interval * spawned:
			_spawn_skill_3_enemy(spawned % 3, enemy_types[spawned])
			spawned += 1

		await get_tree().create_timer(0.02).timeout
		pause_elapsed += 0.02

	# 睁眼
	_skill_3_opening = true
	while _eye_y_mult < 0.98 and not dying:
		await get_tree().create_timer(0.02).timeout
	if dying:
		_skill_3_active = false
		return

	_skill_3_active = false


func _spawn_skill_3_enemy(dir_index: int, type_path: String) -> void:
	var directions = [
		Vector2(0, -1),
		Vector2(-1, 0),
		Vector2(1, 0),
	]
	var dir = directions[dir_index]
	var pos: Vector2
	if dir.y < 0:
		pos = Vector2(randf_range(80, screen_size.x - 80), -200)
	elif dir.x < 0:
		pos = Vector2(-200, randf_range(150, screen_size.y - 100))
	else:
		pos = Vector2(screen_size.x + 200, randf_range(150, screen_size.y - 100))

	var enemy = load(type_path).instantiate()
	enemy.position = pos
	get_tree().current_scene.add_child(enemy)


func _skill_4() -> void:
	if dying:
		return
	_skill_4_active = true

	# 瞪眼到达峰值
	await get_tree().create_timer(0.4).timeout
	if dying:
		_skill_4_active = false
		return

	_skill_4_active = false
	_skill_4_cooling = SKILL_4_COOLING_DURATION

	# 发射圆环
	_skill_4_fire_ring()

	# 创建/刷新全屏红幕
	_skill_4_ensure_overlay()


func _skill_4_fire_ring() -> void:
	_skill_4_ring_data = {
		"radius": 0.0,
		"alpha": 0.0,
		"elapsed": 0.0,
		"phase": 0,
	}
	queue_redraw()
	while _skill_4_ring_data.get("radius", 1001.0) < 1000.0:
		if dying:
			break
		_skill_4_ring_data.elapsed += 0.02
		var elapsed = _skill_4_ring_data.elapsed
		if elapsed < 0.3:
			_skill_4_ring_data.radius = skill_4_ring_grow_speed * elapsed
			_skill_4_ring_data.alpha = elapsed / 0.3
			_skill_4_ring_data.phase = 0
		else:
			_skill_4_ring_data.radius = 300.0 + skill_4_ring_grow_speed * (elapsed - 0.3)
			_skill_4_ring_data.alpha = 1.0 - (elapsed - 0.3) / 0.3
			if _skill_4_ring_data.alpha < 0.0:
				_skill_4_ring_data.alpha = 0.0
			_skill_4_ring_data.phase = 1
		queue_redraw()
		await get_tree().create_timer(0.02).timeout
	_skill_4_ring_data.clear()
	queue_redraw()


func _skill_4_ensure_overlay() -> void:
	_skill_4_overlay_duration = randf_range(skill_4_overlay_dur_min, skill_4_overlay_dur_max)

	if _skill_4_overlay != null:
		_skill_4_overlay_timer = 0.0
		return

	_skill_4_overlay = CanvasLayer.new()
	_skill_4_overlay.layer = 99
	get_tree().current_scene.add_child(_skill_4_overlay)

	_skill_4_overlay_rect = ColorRect.new()
	_skill_4_overlay_rect.color = Color(_theme_color.r * 0.35, _theme_color.g * 0.35, _theme_color.b * 0.35, 0.0)
	_skill_4_overlay_rect.anchor_left = 0.0
	_skill_4_overlay_rect.anchor_right = 1.0
	_skill_4_overlay_rect.anchor_top = 0.0
	_skill_4_overlay_rect.anchor_bottom = 1.0
	_skill_4_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skill_4_overlay.add_child(_skill_4_overlay_rect)

	var distort_shader = load("res://assets/images/helleye/screen_distort.gdshader")
	if distort_shader:
		_skill_4_overlay_mat = ShaderMaterial.new()
		_skill_4_overlay_mat.shader = distort_shader
		_skill_4_overlay_mat.set_shader_parameter(&"strength", 0.0)
		_skill_4_overlay_rect.material = _skill_4_overlay_mat

	GameManager.controls_inverted = true
	_skill_4_overlay_state = 1
	_skill_4_overlay_timer = 0.0


func _update_skill_4_overlay(delta: float) -> void:
	if not is_instance_valid(_skill_4_overlay_rect):
		_skill_4_overlay_state = 0
		return

	match _skill_4_overlay_state:
		1: # fade in
			_skill_4_overlay_timer += delta
			var t = clampf(_skill_4_overlay_timer / skill_4_fade_time, 0.0, 1.0)
			_skill_4_overlay_rect.color = Color(_theme_color.r * 0.35, _theme_color.g * 0.35, _theme_color.b * 0.35, 0.3 * t)
			if _skill_4_overlay_mat:
				_skill_4_overlay_mat.set_shader_parameter(&"strength", t * 3.0)
			if t >= 1.0:
				_skill_4_overlay_state = 2
				_skill_4_overlay_timer = 0.0
		2: # active
			_skill_4_overlay_timer += delta
			_update_error_texts(delta)
			if _skill_4_overlay_timer >= _skill_4_overlay_duration:
				_skill_4_overlay_state = 3
				_skill_4_overlay_timer = 0.0
		3: # fade out
			_skill_4_overlay_timer += delta
			_update_error_texts(delta)
			var t = clampf(1.0 - _skill_4_overlay_timer / skill_4_fade_time, 0.0, 1.0)
			_skill_4_overlay_rect.color = Color(_theme_color.r * 0.35, _theme_color.g * 0.35, _theme_color.b * 0.35, 0.3 * t)
			if _skill_4_overlay_mat:
				_skill_4_overlay_mat.set_shader_parameter(&"strength", t * 3.0)
			if t <= 0.0:
				GameManager.controls_inverted = false
				_cleanup_error_texts()
				_skill_4_overlay.queue_free()
				_skill_4_overlay = null
				_skill_4_overlay_rect = null
				_skill_4_overlay_mat = null
				_skill_4_overlay_state = 0


func _draw_skill_4_ring() -> void:
	if _skill_4_ring_data.is_empty():
		return
	var radius = _skill_4_ring_data.radius
	var alpha = _skill_4_ring_data.alpha
	if alpha < 0.005 or radius < 0.5:
		return
	var center = Vector2.ZERO
	const THICKNESS = 10.0
	var inner_r = radius - THICKNESS * 0.5
	var outer_r = radius + THICKNESS * 0.5
	var col = Color(_theme_color.r, _theme_color.g, _theme_color.b, 0.8 * alpha)
	const ARC_SEGS = 72
	for i in ARC_SEGS:
		var a0 = TAU * float(i) / ARC_SEGS
		var a1 = TAU * float(i + 1) / ARC_SEGS
		var pts = PackedVector2Array([
			center + Vector2(cos(a0) * outer_r, sin(a0) * outer_r),
			center + Vector2(cos(a1) * outer_r, sin(a1) * outer_r),
			center + Vector2(cos(a1) * inner_r, sin(a1) * inner_r),
			center + Vector2(cos(a0) * inner_r, sin(a0) * inner_r),
		])
		draw_colored_polygon(pts, col)


func _update_error_texts(delta: float) -> void:
	_skill_4_error_cooldown -= delta
	if _skill_4_error_cooldown <= 0.0:
		_skill_4_error_cooldown = randf_range(0.15, 0.5)
		_spawn_error_text()

	var to_remove: Array = []
	for i in _skill_4_error_labels.size():
		var lbl: Label = _skill_4_error_labels[i]
		if not is_instance_valid(lbl):
			to_remove.append(i)
			continue
		var age = lbl.get_meta("_age", 0.0) + delta
		lbl.set_meta("_age", age)
		var lifetime: float = lbl.get_meta("_lifetime", 1.0)
		var build_time: float = lifetime * 0.2
		var fade_out_start: float = lifetime * 0.7

		if age < build_time:
			var t = age / build_time
			var chars = clampi(int(t * 5.0) + 1, 1, 5)
			var full = "ERROR"
			lbl.text = full.substr(0, chars)
			lbl.modulate = Color(_theme_color.r, _theme_color.g, _theme_color.b, clampf(t * 2.0, 0.0, 1.0))
		elif age < fade_out_start:
			lbl.text = "ERROR"
			lbl.modulate = Color(_theme_color.r, _theme_color.g, _theme_color.b, 1.0)
		else:
			var t = clampf((age - fade_out_start) / (lifetime - fade_out_start), 0.0, 1.0)
			var chars = clampi(5 - int(t * 4.0), 1, 5)
			var full = "ERROR"
			lbl.text = full.substr(0, chars)
			lbl.modulate = Color(_theme_color.r, _theme_color.g, _theme_color.b, 1.0 - t)
		if age >= lifetime:
			to_remove.append(i)
			lbl.queue_free()
	for i in range(to_remove.size() - 1, -1, -1):
		_skill_4_error_labels.remove_at(to_remove[i])


func _spawn_error_text() -> void:
	if not is_instance_valid(_skill_4_overlay):
		return
	var lbl = Label.new()
	lbl.text = ""
	lbl.add_theme_font_size_override(&"font_size", randi_range(14, 42))
	lbl.modulate = Color(_theme_color.r, _theme_color.g, _theme_color.b, 0.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var screen = get_viewport().get_visible_rect().size
	lbl.position = Vector2(randf_range(20, screen.x - 100), randf_range(20, screen.y - 60))
	lbl.set_meta("_age", 0.0)
	lbl.set_meta("_lifetime", randf_range(0.8, 2.0))
	_skill_4_overlay.add_child(lbl)
	_skill_4_error_labels.append(lbl)


func _cleanup_error_texts() -> void:
	for lbl in _skill_4_error_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_skill_4_error_labels.clear()


func _spawn_skill_eye_warns(count: int) -> void:
	var player = get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return
	var pos = player.global_position
	for _i in range(count):
		var angle = randf_range(0, TAU)
		_skill_1_data.append({
			"pos": pos,
			"angle": angle,
			"timer": SKILL_1_WARN_TIME,
			"phase": 0,
		})


func _skill_5() -> void:
	if dying:
		return
	_skill_1_active = true
	_start_whisper()
	var skill_duration = randf_range(5.0, 10.0)
	var skill_end = Time.get_ticks_msec() / 1000.0 + skill_duration

	while Time.get_ticks_msec() / 1000.0 < skill_end:
		if dying:
			break
		_spawn_skill_eye_warns(3)
		await get_tree().create_timer(randf_range(0.27, 0.53)).timeout

	_stop_whisper()
	_skill_1_active = false
	_eye_is_returning = true
	_eye_anim_timer = EYE_NORMAL_DURATION


func _check_skill_1_laser_hit() -> void:
	var player = get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return
	var ppos = player.global_position
	for d in _skill_1_data:
		if d.phase != 1:
			continue
		var dir = Vector2.RIGHT.rotated(d.angle)
		var to_player = ppos - d.pos
		var proj = to_player.dot(dir)
		var half_len = SKILL_1_SCREEN_EXTEND * 0.5
		if abs(proj) > half_len:
			continue
		var dist = abs(to_player.dot(Vector2(-dir.y, dir.x)))
		if dist > SKILL_1_HALF_WIDTH:
			continue
		player.take_damage_from_boss(SKILL_1_LASER_DMG)


func _entrance_process(delta: float) -> void:
	entrance_timer += delta

	_idle_animation(delta)

	# ── 阶段0 (0~1.5s)：睁眼出现 ──
	if entrance_timer <= 1.5:
		if entrance_timer - delta < 0.5 and entrance_timer >= 0.5:
			_start_bgm()
		var t = clampf(entrance_timer / 1.5, 0.0, 1.0)
		var e = t * t * (3.0 - 2.0 * t)
		_eye_y_mult = lerpf(0.02, 1.0, e)

	# ── 阶段1 (1.8~1.9s)：瞪大眼（0.1s）+ 画面颤动 ──
	elif entrance_timer <= 1.9:
		if entrance_timer - delta < 1.8 and entrance_timer >= 1.8:
			_play_sfx(ROAR_SFX, -5)
		var t_wide = clampf((entrance_timer - 1.8) / 0.1, 0.0, 1.0)
		var ew = t_wide * t_wide
		if entrance_timer >= 1.8:
			_eye_y_mult = lerpf(1.0, EYE_WIDE_Y, ew)
			_eyeball_content_mult = lerpf(1.0, EYE_CONTENT_SHRINK, ew)
			var cam = get_viewport().get_camera_2d()
			if cam:
				cam.offset = Vector2(randf_range(-3, 3), randf_range(-2, 2))

	# ── 瞪眼维持 (1.9~2.5s)：保持瞪大 + 轻微颤动 ──
	elif entrance_timer <= 2.5:
		_eye_y_mult = EYE_WIDE_Y
		_eyeball_content_mult = EYE_CONTENT_SHRINK
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2(randf_range(-3, 3), randf_range(-2, 2))

	# ── 阶段2 (2.5~4.5s)：黑幕2s + 睁大眼 + 画面颤动 ──
	elif entrance_timer <= 4.5:
		if entrance_timer - delta < 2.5 and entrance_timer >= 2.5:
			_start_bgm(4.0)
		_eye_y_mult = EYE_WIDE_Y
		_eyeball_content_mult = EYE_CONTENT_SHRINK
		overlay_rect.color = Color(0, 0, 0, 1)
		overlay_label.modulate = Color(1, 1, 1, 1)
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2(randf_range(-8, 8), randf_range(-5, 5))

	# ── 阶段3 (4.5~5.5s)：黑幕消失 + 睁大眼 + 画面颤动 ──
	elif entrance_timer <= 5.5:
		_eye_y_mult = EYE_WIDE_Y
		_eyeball_content_mult = EYE_CONTENT_SHRINK
		overlay_rect.color = Color(0, 0, 0, 0)
		overlay_label.modulate = Color(1, 1, 1, 0)
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2(randf_range(-8, 8), randf_range(-5, 5))

	# ── 阶段4 (5.5~6.5s)：黑幕消失1s后回归正常，停止颤动 ──
	elif entrance_timer <= 6.5:
		if entrance_timer - delta < 5.5:
			var cam = get_viewport().get_camera_2d()
			if cam: cam.offset = Vector2.ZERO
		var t_norm = clampf((entrance_timer - 5.5) / 1.0, 0.0, 1.0)
		var e = 1.0 - (1.0 - t_norm) * (1.0 - t_norm)
		_eye_y_mult = lerpf(EYE_WIDE_Y, 1.0, e)
		_eyeball_content_mult = lerpf(EYE_CONTENT_SHRINK, 1.0, e)

	# ── 阶段5 (6.5s+)：结束，进入待机 ──
	else:
		_eye_y_mult = 1.0
		_eyeball_content_mult = 1.0
		_breath_t = 0.0
		overlay_layer.queue_free()
		entering = false
		active = true
		_initial_position = position
		_home_position = position
		cooldown_remaining = 2.0


func _start_bgm(seek_to: float = 0.0) -> void:
	if GameManager.bgm_player.playing:
		GameManager.bgm_player.stop()
	bgm_player.play.call_deferred(seek_to)


func _get_death_particle_tex() -> Texture2D:
	if _death_particle_tex == null:
		var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_death_particle_tex = ImageTexture.create_from_image(img)
	return _death_particle_tex


func _die() -> void:
	if dying:
		return
	active = false
	dying = true
	is_executing = false
	death_timer = 0.0
	_death_particle_timer = 0.0
	bgm_player.stop()
	GameManager.bgm_player.play()
	for tw in _skill_tweens:
		if is_instance_valid(tw) and tw.is_valid():
			tw.kill()
	_skill_tweens.clear()
	_warn_list.clear()
	if is_instance_valid(_whisper_player) and _whisper_player.playing:
		_whisper_player.stop()
	_reset_screen_shake()
	_cleanup_error_texts()
	if is_instance_valid(_skill_4_overlay):
		_skill_4_overlay.queue_free()
	_skill_4_overlay = null


func _death_process(delta: float) -> void:
	death_timer += delta
	_death_particle_timer += delta

	if _death_particle_timer >= 0.06:
		_death_particle_timer -= 0.06
		for src in [_stroke_sprite, _nebula_sprite, body_sprite]:
			if not is_instance_valid(src):
				continue
			for _j in range(randi_range(1, 2)):
				var p = Sprite2D.new()
				p.texture = _get_death_particle_tex()
				p.modulate = _death_particle_color
				p.position = src.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
				p.scale = Vector2(randf_range(1.5, 4.0), randf_range(1.5, 4.0))
				p.rotation = randf_range(0, TAU)
				p.z_index = 2000
				get_tree().current_scene.add_child(p)
				var dur = randf_range(0.5, 1.2)
				var tw = get_tree().create_tween().bind_node(p)
				tw.tween_property(p, "modulate:a", 0.0, dur)
				tw.parallel().tween_property(p, "scale", Vector2.ZERO, dur)
				tw.tween_callback(p.queue_free)
				var vel = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(40, 150)
				var tw_move = get_tree().create_tween().bind_node(p)
				tw_move.tween_property(p, "position", p.position + vel, dur)

	_shake_hell_eye_parts()

	if death_timer >= DEATH_DURATION and not won:
		won = true
		_spawn_final_particles()
		queue_free()


func _shake_hell_eye_parts() -> void:
	if is_instance_valid(_stroke_sprite):
		_stroke_sprite.offset = Vector2(randf_range(-12, 12), randf_range(-8, 8))
	if is_instance_valid(_nebula_sprite):
		_nebula_sprite.position = nebula_offset + Vector2(randf_range(-15, 15), randf_range(-10, 10))
	if is_instance_valid(body_sprite):
		body_sprite.position = eyeball_offset + Vector2(randf_range(-15, 15), randf_range(-10, 10))


func _spawn_final_particles() -> void:
	for _i in range(40):
		var p = Sprite2D.new()
		p.texture = _get_death_particle_tex()
		p.modulate = _death_particle_color
		p.position = global_position + Vector2(randf_range(-100, 100), randf_range(-80, 80))
		p.scale = Vector2(randf_range(2, 6), randf_range(2, 6))
		p.rotation = randf_range(0, TAU)
		p.z_index = 2000
		get_tree().current_scene.add_child(p)
		var dur = randf_range(0.6, 1.5)
		var tw = get_tree().create_tween().bind_node(p)
		tw.tween_property(p, "modulate:a", 0.0, dur)
		tw.parallel().tween_property(p, "scale", Vector2.ZERO, dur)
		tw.tween_callback(p.queue_free)
		var vel = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(80, 280)
		var tw_move = get_tree().create_tween().bind_node(p)
		tw_move.tween_property(p, "position", p.position + vel, dur)


# ═══════════ 基础设施方法 ═══════════

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	boss_hp = max_hp
	if boss_name == "扭曲星核":
		boss_name = "地狱之眼"
		has_skill_1 = true
		has_skill_2 = true
		has_skill_3 = true
		has_skill_4 = true
		has_skill_5 = true
		has_skill_6 = true
	mask_rotation_deg = randf_range(0.0, 360.0)
	max_hp = 1000
	boss_hp = max_hp
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = HELL_EYE_BGM
	bgm_player.volume_db = -10
	add_child(bgm_player)
	_setup_body()
	_setup_orbiters()
	_create_entrance_overlay()
	_start_entrance()

	_get_death_particle_tex()
	
	_whisper_player = AudioStreamPlayer.new()
	_whisper_player.stream = ROAR_SFX
	_whisper_player.volume_db = -18
	_whisper_player.pitch_scale = 0.5
	add_child(_whisper_player)


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


func _exec_skill(s: int) -> void:
	match s:
		1: await _skill_1()
		2: await _skill_2()
		3: await _skill_3()
		4: await _skill_4()
		5: await _skill_5()
		6: await _skill_6()


func _make_tween() -> Tween:
	if dying:
		var tw = create_tween()
		tw.kill()
		return tw
	var tw = create_tween()
	_skill_tweens.append(tw)
	return tw


func _play_sfx(audio: AudioStream, vol_db: float = 0.0) -> void:
	if dying:
		return
	var p = AudioStreamPlayer.new()
	p.stream = audio
	p.volume_db = vol_db
	p.bus = &"Master"
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()


func _create_entrance_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100
	add_child(overlay_layer)

	overlay_rect = ColorRect.new()
	overlay_rect.anchor_left = 0.0
	overlay_rect.anchor_right = 1.0
	overlay_rect.anchor_top = 0.0
	overlay_rect.anchor_bottom = 1.0
	overlay_rect.color = Color(0, 0, 0, 0)
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(overlay_rect)

	overlay_label = Label.new()
	overlay_label.text = boss_name
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.anchor_left = 0.0
	overlay_label.anchor_right = 1.0
	overlay_label.anchor_top = 0.0
	overlay_label.anchor_bottom = 1.0
	overlay_label.modulate = Color(1, 1, 1, 0)
	overlay_label.add_theme_font_size_override(&"font_size", 72)
	overlay_layer.add_child(overlay_label)


func _spawn_explosion(pos: Vector2, scale_val: float = 1.0) -> void:
	var exp = Sprite2D.new()
	exp.texture = EXPLOSION_TEX
	exp.hframes = 8
	exp.vframes = 1
	exp.frame = 0
	exp.position = pos
	exp.scale = Vector2(scale_val, scale_val)
	exp.z_index = 200
	exp.set_script(ExplosionScript)
	get_tree().current_scene.add_child(exp)


func _spawn_skill6_explosion(pos: Vector2) -> void:
	_spawn_explosion(pos, 2.5)
	for _i in range(8):
		_spawn_debris(pos, 4.0)


func _create_debris(pos: Vector2, lifetime: float = 2.0) -> void:
	var d = Sprite2D.new()
	d.texture = DEBRIS_TEX
	d.position = pos
	d.scale = Vector2(randf_range(0.5, 2.0), randf_range(0.5, 2.0))
	d.rotation = randf_range(0, TAU)
	d.z_index = 180
	d.set_script(DebrisScript)
	d.lifetime = lifetime
	get_tree().current_scene.add_child(d)


func _spawn_debris(pos: Vector2, scale_val: float = 1.0) -> void:
	_create_debris(pos, 2.0)
