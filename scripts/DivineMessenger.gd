extends Node2D
## 神明使者 —— 水晶/王冠/羽翼 Boss

# ═══════════ 贴图 ═══════════
const CRYSTAL_TEX = preload("res://assets/images/divine_messenger/crystal_cutout.png")
const CROWN_TEX = preload("res://assets/images/divine_messenger/crown_cutout.png")
const WINGS_TEX = preload("res://assets/images/divine_messenger/wings_cutout.png")
const WINGS_OPEN_TEX = preload("res://assets/images/divine_messenger/wings_open_cutout.png")

# ═══════════ 基本属性 ═══════════
@export var max_hp: int = 1000
@export var boss_name: String = "神明使者"
@export var spawn_y_ratio: float = 0.4
var boss_hp: int
var screen_size: Vector2

# ═══════════ 生命周期标志 ═══════════
var active: bool = false
var dying: bool = false

# ═══════════ 主体外观 ═══════════
var crystal_sprite: Sprite2D
var crown_sprite: Sprite2D
var wings_left: Sprite2D
var wings_right: Sprite2D
var _wing_glow_mats: Array[ShaderMaterial] = []
var _point_light_left: Sprite2D
var _point_light_right: Sprite2D
var _wings_open: bool = false
var _crown_phase: float = 0.0
var _crystal_pulse: float = 0.0
var _wings_phase: float = 0.0
var _crystal_speed: float = 1.2
var _crown_speed: float = 1.2
var _wings_speed: float = 1.2
var _wings_shake_phase: float = 0.0

# 展翅动画（当前停用，改用简单切换）
var _is_wing_spread_playing: bool = false
var _spread_timer: float = 0.0
var _spread_phase: int = 0
var _spread_switched: bool = false

# 翅膀配置硬切换测试
var _test_toggle_timer: float = 0.0
var _test_toggle_open: bool = false

# 闭合翅膀状态下的基准位置
var _closed_crystal_pos: Vector2
var _closed_crown_pos: Vector2
var _closed_wl_pivot_pos: Vector2
var _closed_wr_pivot_pos: Vector2

# 张开翅膀状态下的基准位置（切换时记录）
var _open_crystal_pos: Vector2
var _open_crown_pos: Vector2
var _open_wl_pivot_pos: Vector2
var _open_wr_pivot_pos: Vector2

# 阶段2切换瞬间的视觉状态
var _switch_crystal_pos: Vector2
var _switch_crown_pos: Vector2
var _switch_wl_pivot_pos: Vector2
var _switch_wr_pivot_pos: Vector2
var _switch_wl_rot: float
var _switch_wr_rot: float
var _switch_eased_t: float

# 阶段4起始状态
var _p4_crystal_pos: Vector2
var _p4_crown_pos: Vector2
var _p4_wl_pivot_pos: Vector2
var _p4_wr_pivot_pos: Vector2
var _p4_wl_rot: float
var _p4_wr_rot: float

var wing_pivot_left_node: Node2D
var wing_pivot_right_node: Node2D
var wing_pivot_left_sprite: Sprite2D
var wing_pivot_right_sprite: Sprite2D

# ═══════ 水晶/王冠 (始终生效) ═══════
@export var crystal_scale: Vector2 = Vector2(0.5, 0.5)
@export var crystal_pos: Vector2 = Vector2.ZERO
@export var crystal_z_index: int = 50
@export var crown_scale: Vector2 = Vector2(0.35, 0.35)
@export var crown_pos: Vector2 = Vector2(0, -120)
@export var crown_z_index: int = 51
@export var overall_scale: float = 1.0
@export var show_pivot_dots: bool = false
@export_group("Wing Glow (HDR)")
@export var wing_glow_size: float = 0.008
@export var wing_glow_max_brightness: float = 2.0
@export var wing_glow_spread: int = 5
@export_group("Wing Scale Boost")
@export var wing_scale_boost_mult: float = 1.4
@export_group("Wing Spread")
@export var wing_spread_offset: float = 80.0
@export var wing_spread_rise: float = 50.0
@export_group("Point Lights")
@export var point_light_size: float = 600.0
@export var point_light_max_brightness: float = 0.5

# ═══════ 翅膀闭合状态配置 ═══════
@export_group("Wings Closed State")
@export var wings_closed_wings_scale: Vector2 = Vector2(0.5, 0.5)
@export var wings_closed_wings_z_index: int = 48
@export var wings_closed_wings_shake_angle: float = 10.0
@export var wings_closed_wings_shake_speed: float = 2.0
@export var wings_closed_wing_pivot_left_pos: Vector2 = Vector2(-80, 0)
@export var wings_closed_wing_pivot_right_pos: Vector2 = Vector2(80, 0)
@export var wings_closed_wing_left_offset: Vector2 = Vector2(40, 0)
@export var wings_closed_wing_right_offset: Vector2 = Vector2(-40, 0)

# ═══════ 翅膀张开状态配置 ═══════
@export_group("Wings Open State")
@export var wings_open_wings_scale: Vector2 = Vector2(0.5, 0.5)
@export var wings_open_wings_z_index: int = 48
@export var wings_open_wings_shake_angle: float = 10.0
@export var wings_open_wings_shake_speed: float = 2.0
@export var wings_open_wing_pivot_left_pos: Vector2 = Vector2(-80, 0)
@export var wings_open_wing_pivot_right_pos: Vector2 = Vector2(80, 0)
@export var wings_open_wing_left_offset: Vector2 = Vector2(40, 0)
@export var wings_open_wing_right_offset: Vector2 = Vector2(-40, 0)

# ═══════ 运行时翅膀当前值 ═══════
var wings_scale: Vector2 = Vector2(0.5, 0.5)
var wings_z_index: int = 48
var wings_shake_angle: float = 10.0
var wings_shake_speed: float = 2.0
var wing_pivot_left_pos: Vector2 = Vector2(-80, 0)
var wing_pivot_right_pos: Vector2 = Vector2(80, 0)
var wing_left_offset: Vector2 = Vector2(40, 0)
var wing_right_offset: Vector2 = Vector2(-40, 0)
var wings_open: bool = false

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

# ═══════════ 死亡 ═══════════
const DEATH_DURATION: float = 5.0
var death_timer: float = 0.0
var death_explosion_cd: float = 0.0
var death_sfx_cd: float = 0.0
var won: bool = false

# ═══════════ BGM ═══════════
const BOSS_BGM = preload("res://assets/audio/warpedcore_bgm.mp3")
var bgm_player: AudioStreamPlayer

# ═══════════ 资源预加载 ═══════════
const HIT_SFX = preload("res://assets/audio/boss_hit.wav")
const EXPLOSION_SFX = preload("res://assets/audio/explosion.wav")
const WING_GLOW_SHADER = preload("res://shaders/wing_glow.gdshader")
const ROAR_SFX = preload("res://assets/audio/boss_roar.wav")
const EXPLOSION_TEX = preload("res://assets/images/fx/explosion.png")
const DEBRIS_TEX = preload("res://assets/images/fx/debris.png")
const ExplosionScript = preload("res://scripts/Explosion.gd")
const DebrisScript = preload("res://scripts/Debris.gd")

# ═══════════ Tween 管理 ═══════════
var _skill_tweens: Array[Tween] = []


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	boss_hp = max_hp
	_crystal_pulse = randf_range(0.0, TAU)
	_crown_phase = randf_range(0.0, TAU)
	_wings_phase = randf_range(0.0, TAU)
	_crystal_speed = randf_range(1.0, 1.4)
	_crown_speed = randf_range(1.0, 1.4)
	_wings_speed = randf_range(1.0, 1.4)
	scale = Vector2(overall_scale, overall_scale)
	_setup_bgm()
	# 先初始化运行时变量为闭合状态（从 @export 配置读取）
	_init_runtime_wings_from_closed()
	_setup_body()
	active = true
	position = Vector2(screen_size.x * 0.5, screen_size.y * spawn_y_ratio)
	cooldown_remaining = 2.0
	_start_bgm()
	_start_wing_spread_animation()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		scale = Vector2(overall_scale, overall_scale)
		_update_editor_preview()
		return
	if dying:
		_death_process(delta)
		return
	if not active:
		return

	if _is_wing_spread_playing:
		_process_wing_spread_animation(delta)
	else:
		_idle_animation(delta)

	if is_executing:
		return

	cooldown_remaining -= delta
	if cooldown_remaining <= 0.0:
		is_executing = true
		var enemy_count = get_tree().get_nodes_in_group(&"enemies").size()
		var s: int
		if enemy_count > 8:
			s = _pick_random_skill(3)
		elif has_skill_3 and _last_skill != 3 and enemy_count <= 3:
			s = 3
		else:
			s = _pick_random_skill()
		if s != 0:
			await _exec_skill(s)
			_last_skill = s
		cooldown_remaining = skill_cooldown
		is_executing = false


func _update_editor_preview() -> void:
	if not wings_left or not wings_right or not crystal_sprite or not crown_sprite or not wing_pivot_left_node or not wing_pivot_right_node:
		return
	wing_pivot_left_node.position = wings_closed_wing_pivot_left_pos
	wing_pivot_right_node.position = wings_closed_wing_pivot_right_pos
	wing_pivot_left_node.rotation = 0.0
	wing_pivot_right_node.rotation = 0.0
	var wings_tex = WINGS_TEX
	if wings_tex:
		wings_left.texture = wings_tex
		wings_right.texture = wings_tex
		wings_left.region_rect = Rect2(Vector2.ZERO, Vector2(wings_tex.get_size().x / 2.0, wings_tex.get_size().y))
		wings_right.region_rect = Rect2(Vector2(wings_tex.get_size().x / 2.0, 0), Vector2(wings_tex.get_size().x / 2.0, wings_tex.get_size().y))
	wings_left.scale = wings_closed_wings_scale
	wings_left.position = wings_closed_wing_left_offset
	wings_left.z_index = wings_closed_wings_z_index
	wings_right.scale = wings_closed_wings_scale
	wings_right.position = wings_closed_wing_right_offset
	wings_right.z_index = wings_closed_wings_z_index
	crystal_sprite.scale = crystal_scale
	crystal_sprite.position = crystal_pos
	crystal_sprite.z_index = crystal_z_index
	crown_sprite.scale = crown_scale
	crown_sprite.position = crown_pos
	crown_sprite.z_index = crown_z_index
	if wing_pivot_left_sprite:
		wing_pivot_left_sprite.visible = show_pivot_dots
	if wing_pivot_right_sprite:
		wing_pivot_right_sprite.visible = show_pivot_dots


## ── 翅膀配置切换测试 ──

func _test_toggle_cycle(delta: float) -> void:
	_test_toggle_timer += delta
	if _test_toggle_timer >= 5.0:
		_test_toggle_timer = 0.0
		_test_toggle_open = not _test_toggle_open
		if _test_toggle_open:
			apply_wings_open_state()
		else:
			apply_wings_closed_state()
		_sync_all_node_props()
		_set_wings_open(_test_toggle_open)


## ── 展翅动画 ──

func _start_wing_spread_animation() -> void:
	apply_wings_closed_state()
	_set_wings_open(false)
	_sync_all_node_props()
	_snapshot_closed()
	_spread_switched = false
	_spread_timer = 0.0
	_spread_phase = 0
	_is_wing_spread_playing = true


func _process_wing_spread_animation(delta: float) -> void:
	if not _is_wing_spread_playing:
		return
	
	_spread_timer += delta
	
	match _spread_phase:
		0: # 0→0.8s：向下50px缓出，左逆10°右顺10°
			if _spread_timer <= 0.8:
				var t = ease_out(_spread_timer / 0.8)
				_apply_p0(t)
			else:
				_spread_timer = 0.0
				_spread_phase = 1
		1: # 0→0.3s：停顿在峰值
			if _spread_timer <= 0.3:
				_apply_p0(1.0)
			else:
				_spread_timer = 0.0
				_spread_phase = 2
		2: # 0→0.3s：向上100px缓入，左右各反向20°；0.2s时切换张开配置
			var t = ease_in(_spread_timer / 0.3)
			if _spread_timer >= 0.2 and not _spread_switched:
				_spread_switched = true
				_switch_eased_t = t
				_save_switch_visual()
				_snapshot_open()
				apply_wings_open_state()
				_set_wings_open(true)
				_restore_switch_visual()
				_apply_wing_sprite_props()
			_apply_p2(t)
			if _spread_timer >= 0.3:
				_snapshot_p4()
				_spread_timer = 0.0
				_spread_phase = 3
		3: # 0→2s：停顿在最高点
			if _spread_timer <= 2.0:
				_apply_p2(1.0)
			else:
				_spread_timer = 0.0
				_spread_phase = 4
		4: # 0→0.5s：向下50px缓出，左逆10°右顺10°
			if _spread_timer <= 0.5:
				var t = ease_out(_spread_timer / 0.5)
				_apply_p4(t)
			else:
				_spread_timer = 0.0
				_spread_phase = 0
				_restart_wing_spread_animation()

	_apply_wing_glow()
	_apply_wing_scale_boost()
	_apply_wing_spread_offset()
	_apply_point_lights()


func _restart_wing_spread_animation() -> void:
	apply_wings_closed_state()
	_set_wings_open(false)
	_sync_all_node_props()
	_snapshot_closed()
	_spread_switched = false
	_spread_timer = 0.0
	_spread_phase = 0
	for mat in _wing_glow_mats:
		mat.set_shader_parameter("glow_intensity", 0.0)
	if _point_light_left:
		_point_light_left.scale = Vector2.ZERO
		_point_light_left.modulate.a = 0.0
	if _point_light_right:
		_point_light_right.scale = Vector2.ZERO
		_point_light_right.modulate.a = 0.0


func _sync_all_node_props() -> void:
	if crystal_sprite:
		crystal_sprite.position = crystal_pos
		crystal_sprite.scale = crystal_scale
		crystal_sprite.z_index = crystal_z_index
	if crown_sprite:
		crown_sprite.position = crown_pos
		crown_sprite.scale = crown_scale
		crown_sprite.z_index = crown_z_index
	if wing_pivot_left_node:
		wing_pivot_left_node.position = wing_pivot_left_pos
	if wing_pivot_right_node:
		wing_pivot_right_node.position = wing_pivot_right_pos
	if wings_left:
		wings_left.position = wing_left_offset
		wings_left.scale = wings_scale
		wings_left.z_index = wings_z_index
	if wings_right:
		wings_right.position = wing_right_offset
		wings_right.scale = wings_scale
		wings_right.z_index = wings_z_index


func _apply_wing_sprite_props() -> void:
	if wings_left:
		wings_left.scale = wings_scale
		wings_left.position = wing_left_offset
		wings_left.z_index = wings_z_index
	if wings_right:
		wings_right.scale = wings_scale
		wings_right.position = wing_right_offset
		wings_right.z_index = wings_z_index


func _init_runtime_wings_from_closed() -> void:
	wing_pivot_left_pos = wings_closed_wing_pivot_left_pos
	wing_pivot_right_pos = wings_closed_wing_pivot_right_pos
	wings_scale = wings_closed_wings_scale
	wings_z_index = wings_closed_wings_z_index
	wings_shake_angle = wings_closed_wings_shake_angle
	wings_shake_speed = wings_closed_wings_shake_speed
	wing_left_offset = wings_closed_wing_left_offset
	wing_right_offset = wings_closed_wing_right_offset


func _snapshot_closed() -> void:
	_closed_crystal_pos = crystal_pos
	_closed_crown_pos = crown_pos
	_closed_wl_pivot_pos = wing_pivot_left_pos
	_closed_wr_pivot_pos = wing_pivot_right_pos


func _snapshot_open() -> void:
	_open_crystal_pos = crystal_pos
	_open_crown_pos = crown_pos
	_open_wl_pivot_pos = wing_pivot_left_pos
	_open_wr_pivot_pos = wing_pivot_right_pos


func _save_switch_visual() -> void:
	_switch_crystal_pos = crystal_sprite.position
	_switch_crown_pos = crown_sprite.position
	_switch_wl_pivot_pos = wing_pivot_left_node.position
	_switch_wr_pivot_pos = wing_pivot_right_node.position
	_switch_wl_rot = wing_pivot_left_node.rotation
	_switch_wr_rot = wing_pivot_right_node.rotation


func _restore_switch_visual() -> void:
	crystal_sprite.position = _switch_crystal_pos
	crown_sprite.position = _switch_crown_pos
	wing_pivot_left_node.position = _switch_wl_pivot_pos
	wing_pivot_right_node.position = _switch_wr_pivot_pos
	wing_pivot_left_node.rotation = _switch_wl_rot
	wing_pivot_right_node.rotation = _switch_wr_rot


func _snapshot_p4() -> void:
	_p4_crystal_pos = crystal_sprite.position
	_p4_crown_pos = crown_sprite.position
	_p4_wl_pivot_pos = wing_pivot_left_node.position
	_p4_wr_pivot_pos = wing_pivot_right_node.position
	_p4_wl_rot = wing_pivot_left_node.rotation
	_p4_wr_rot = wing_pivot_right_node.rotation


func _apply_p0(t: float) -> void:
	var move_y = 50.0 * t
	crystal_sprite.position = _closed_crystal_pos + Vector2(0, move_y)
	crown_sprite.position = _closed_crown_pos + Vector2(0, move_y)
	wing_pivot_left_node.position = _closed_wl_pivot_pos + Vector2(0, move_y)
	wing_pivot_right_node.position = _closed_wr_pivot_pos + Vector2(0, move_y)
	var rot = deg_to_rad(10.0) * t
	wing_pivot_left_node.rotation = -rot
	wing_pivot_right_node.rotation = rot


func _apply_p2(t: float) -> void:
	var move_y = -100.0 * t
	var base_y = 50.0
	
	if _spread_switched:
		# 切换后：从切换瞬间的视觉位置继续向上
		var switch_t = _switch_eased_t
		var remaining_move = -100.0 * (t - switch_t)
		crystal_sprite.position = _switch_crystal_pos + Vector2(0, remaining_move)
		crown_sprite.position = _switch_crown_pos + Vector2(0, remaining_move)
		wing_pivot_left_node.position = _switch_wl_pivot_pos + Vector2(0, remaining_move)
		wing_pivot_right_node.position = _switch_wr_pivot_pos + Vector2(0, remaining_move)
	else:
		crystal_sprite.position = _closed_crystal_pos + Vector2(0, base_y + move_y)
		crown_sprite.position = _closed_crown_pos + Vector2(0, base_y + move_y)
		wing_pivot_left_node.position = _closed_wl_pivot_pos + Vector2(0, base_y + move_y)
		wing_pivot_right_node.position = _closed_wr_pivot_pos + Vector2(0, base_y + move_y)
	
	# 旋转：从±10°到∓10°，各有20°变化
	var start_rot = deg_to_rad(10.0)
	var delta_rot = deg_to_rad(-20.0) * t
	wing_pivot_left_node.rotation = -start_rot + (-delta_rot)
	wing_pivot_right_node.rotation = start_rot + delta_rot


func _apply_p4(t: float) -> void:
	var move_y = 50.0 * t
	crystal_sprite.position = _p4_crystal_pos + Vector2(0, move_y)
	crown_sprite.position = _p4_crown_pos + Vector2(0, move_y)
	wing_pivot_left_node.position = _p4_wl_pivot_pos + Vector2(0, move_y)
	wing_pivot_right_node.position = _p4_wr_pivot_pos + Vector2(0, move_y)
	
	var start_rot_l = _p4_wl_rot
	var start_rot_r = _p4_wr_rot
	var delta = deg_to_rad(10.0) * t
	wing_pivot_left_node.rotation = start_rot_l - delta
	wing_pivot_right_node.rotation = start_rot_r + delta


func _get_glow_intensity() -> float:
	match _spread_phase:
		0, 1: return 0.0
		2:
			if _spread_timer <= 0.2:
				return 0.0
			return ease_in((_spread_timer - 0.2) / 0.1)
		3: return 1.0
		4: return 1.0 - ease_out(_spread_timer / 0.5)
		_: return 0.0


func _get_scale_boost() -> float:
	match _spread_phase:
		0, 1: return 1.0
		2:
			if _spread_timer <= 0.2:
				return 1.0
			var t = ease_in((_spread_timer - 0.2) / 0.1)
			return lerpf(1.0, wing_scale_boost_mult, t)
		3: return wing_scale_boost_mult
		4: return lerpf(wing_scale_boost_mult, 1.0, ease_out(_spread_timer / 0.5))
		_: return 1.0


func _apply_wing_scale_boost() -> void:
	var boost = _get_scale_boost()
	if wings_left:
		wings_left.scale = wings_scale * Vector2(boost, boost)
	if wings_right:
		wings_right.scale = wings_scale * Vector2(boost, boost)


func _get_spread_t() -> float:
	match _spread_phase:
		0, 1: return 0.0
		2:
			if _spread_timer <= 0.2:
				return 0.0
			return ease_in((_spread_timer - 0.2) / 0.1)
		3: return 1.0
		4: return 1.0 - ease_out(_spread_timer / 0.5)
		_: return 0.0


func _apply_wing_spread_offset() -> void:
	var t = _get_spread_t()
	var spread_x = wing_spread_offset * t
	var rise_y = wing_spread_rise * t
	if wings_left:
		wings_left.position = Vector2(wing_left_offset.x - spread_x, wing_left_offset.y - rise_y)
	if wings_right:
		wings_right.position = Vector2(wing_right_offset.x + spread_x, wing_right_offset.y - rise_y)


func _apply_point_lights() -> void:
	var t = _get_spread_t()
	var tex_size = 256.0
	var target_scale = point_light_size / tex_size
	var alpha = t * point_light_max_brightness
	if _point_light_left:
		_point_light_left.scale = Vector2.ONE * target_scale * t
		_point_light_left.modulate.a = alpha
	if _point_light_right:
		_point_light_right.scale = Vector2.ONE * target_scale * t
		_point_light_right.modulate.a = alpha


var _cached_point_light_tex: Texture2D

func _point_light_tex() -> Texture2D:
	if _cached_point_light_tex:
		return _cached_point_light_tex
	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var cx = size / 2.0
	for y in size:
		for x in size:
			var dx = (x - cx) / cx
			var dy = (y - cx) / cx
			var dist = sqrt(dx * dx + dy * dy)
			var a = clampf(1.0 - dist, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_cached_point_light_tex = ImageTexture.create_from_image(img)
	return _cached_point_light_tex


func _apply_wing_glow() -> void:
	var intensity = _get_glow_intensity() * wing_glow_max_brightness
	for mat in _wing_glow_mats:
		mat.set_shader_parameter("glow_intensity", intensity)


# 缓出函数
func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)


# 缓入函数
func ease_in(t: float) -> float:
	return t * t * t


func _setup_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = BOSS_BGM
	bgm_player.volume_db = -10
	add_child(bgm_player)


func _setup_body() -> void:
	# 左翅膀旋转容器
	wing_pivot_left_node = Node2D.new()
	wing_pivot_left_node.position = wing_pivot_left_pos
	wing_pivot_left_node.name = "LeftPivotNode"
	add_child(wing_pivot_left_node)
	
	# 左翅膀（子节点）
	var wings_tex = WINGS_OPEN_TEX if wings_open else WINGS_TEX
	wings_left = Sprite2D.new()
	wings_left.texture = wings_tex
	wings_left.centered = true
	wings_left.scale = wings_scale
	wings_left.position = wing_left_offset
	wings_left.z_index = wings_z_index
	wings_left.name = "WingsLeft"
	wings_left.region_enabled = true
	if wings_tex:
		wings_left.region_rect = Rect2(Vector2.ZERO, Vector2(wings_tex.get_size().x / 2.0, wings_tex.get_size().y))
	wing_pivot_left_node.add_child(wings_left)
	
	var mat_l = ShaderMaterial.new()
	mat_l.shader = WING_GLOW_SHADER
	mat_l.set_shader_parameter("glow_intensity", 0.0)
	mat_l.set_shader_parameter("glow_size", wing_glow_size)
	mat_l.set_shader_parameter("glow_spread", wing_glow_spread)
	wings_left.material = mat_l
	_wing_glow_mats.append(mat_l)
	
	# 左旋转中心红点（子节点，也放在容器上，位置是 (0,0)）
	wing_pivot_left_sprite = _create_red_dot_sprite()
	wing_pivot_left_sprite.position = Vector2.ZERO
	wing_pivot_left_sprite.z_index = 100
	wing_pivot_left_sprite.name = "LeftPivotDot"
	wing_pivot_left_sprite.visible = show_pivot_dots
	wing_pivot_left_node.add_child(wing_pivot_left_sprite)
	
	_point_light_left = Sprite2D.new()
	_point_light_left.texture = _point_light_tex()
	_point_light_left.centered = true
	_point_light_left.scale = Vector2.ZERO
	_point_light_left.position = Vector2.ZERO
	_point_light_left.z_index = -100
	_point_light_left.modulate = Color.WHITE
	_point_light_left.modulate.a = 0.0
	_point_light_left.name = "PointLightLeft"
	wing_pivot_left_node.add_child(_point_light_left)
	
	# 右翅膀旋转容器
	wing_pivot_right_node = Node2D.new()
	wing_pivot_right_node.position = wing_pivot_right_pos
	wing_pivot_right_node.name = "RightPivotNode"
	add_child(wing_pivot_right_node)
	
	# 右翅膀（子节点）
	wings_right = Sprite2D.new()
	wings_right.texture = wings_tex
	wings_right.centered = true
	wings_right.scale = wings_scale
	wings_right.position = wing_right_offset
	wings_right.z_index = wings_z_index
	wings_right.name = "WingsRight"
	wings_right.region_enabled = true
	if wings_tex:
		wings_right.region_rect = Rect2(Vector2(wings_tex.get_size().x / 2.0, 0), Vector2(wings_tex.get_size().x / 2.0, wings_tex.get_size().y))
	wing_pivot_right_node.add_child(wings_right)
	
	var mat_r = ShaderMaterial.new()
	mat_r.shader = WING_GLOW_SHADER
	mat_r.set_shader_parameter("glow_intensity", 0.0)
	mat_r.set_shader_parameter("glow_size", wing_glow_size)
	mat_r.set_shader_parameter("glow_spread", wing_glow_spread)
	wings_right.material = mat_r
	_wing_glow_mats.append(mat_r)
	
	# 右旋转中心红点
	wing_pivot_right_sprite = _create_red_dot_sprite()
	wing_pivot_right_sprite.position = Vector2.ZERO
	wing_pivot_right_sprite.z_index = 100
	wing_pivot_right_sprite.name = "RightPivotDot"
	wing_pivot_right_sprite.visible = show_pivot_dots
	wing_pivot_right_node.add_child(wing_pivot_right_sprite)
	
	_point_light_right = Sprite2D.new()
	_point_light_right.texture = _point_light_tex()
	_point_light_right.centered = true
	_point_light_right.scale = Vector2.ZERO
	_point_light_right.position = Vector2.ZERO
	_point_light_right.z_index = -100
	_point_light_right.modulate = Color.WHITE
	_point_light_right.modulate.a = 0.0
	_point_light_right.name = "PointLightRight"
	wing_pivot_right_node.add_child(_point_light_right)

	# 水晶 — 主体，z_index 中间
	crystal_sprite = Sprite2D.new()
	crystal_sprite.texture = CRYSTAL_TEX
	crystal_sprite.centered = true
	crystal_sprite.scale = crystal_scale
	crystal_sprite.position = crystal_pos
	crystal_sprite.z_index = crystal_z_index
	crystal_sprite.name = "Crystal"
	add_child(crystal_sprite)

	# 王冠 — 水晶上方1/2处，z_index 最高
	crown_sprite = Sprite2D.new()
	crown_sprite.texture = CROWN_TEX
	crown_sprite.centered = true
	crown_sprite.scale = crown_scale
	crown_sprite.position = crown_pos
	crown_sprite.z_index = crown_z_index
	crown_sprite.name = "Crown"
	add_child(crown_sprite)

	# 碰撞体
	var body_area = Area2D.new()
	body_area.collision_layer = 2
	body_area.collision_mask = 1
	body_area.add_to_group(&"boss")
	body_area.name = "BodyArea"
	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = 100.0
	col.name = "BodyCol"
	body_area.add_child(col)
	body_area.area_entered.connect(_on_body_area_entered)
	add_child(body_area)


func _start_bgm() -> void:
	if GameManager.bgm_player.playing:
		GameManager.bgm_player.stop()
	bgm_player.play.call_deferred()


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


## ── 待机动画 ──

func _idle_animation(delta: float) -> void:
	_crystal_pulse += delta * _crystal_speed
	if crystal_sprite:
		crystal_sprite.position = Vector2(crystal_pos.x, crystal_pos.y + sin(_crystal_pulse) * 8)
		crystal_sprite.scale = crystal_scale
		crystal_sprite.z_index = crystal_z_index
	if crown_sprite:
		_crown_phase += delta * _crown_speed
		crown_sprite.position = Vector2(crown_pos.x, crown_pos.y + sin(_crown_phase) * 8)
		crown_sprite.scale = crown_scale
		crown_sprite.z_index = crown_z_index
	if wings_left and wings_right and wing_pivot_left_node and wing_pivot_right_node:
		_wings_phase += delta * _wings_speed
		var wing_offset = sin(_wings_phase) * 8
		wings_left.position = Vector2(wing_left_offset.x, wing_left_offset.y + wing_offset)
		wings_left.scale = wings_scale
		wings_left.z_index = wings_z_index
		wings_right.position = Vector2(wing_right_offset.x, wing_right_offset.y + wing_offset)
		wings_right.scale = wings_scale
		wings_right.z_index = wings_z_index
		wing_pivot_left_node.position = wing_pivot_left_pos
		wing_pivot_right_node.position = wing_pivot_right_pos
		_wings_shake_phase += delta * wings_shake_speed
		var shake_rad = deg_to_rad(wings_shake_angle)
		var left_wing_rot = sin(_wings_shake_phase) * shake_rad
		var right_wing_rot = sin(_wings_shake_phase + PI) * shake_rad
		wing_pivot_left_node.rotation = left_wing_rot
		wing_pivot_right_node.rotation = right_wing_rot


var _wing_test_timer: float = 0.0
var _wing_test_open: bool = false

func _test_wing_cycle(delta: float) -> void:
	pass


## ── 死亡动画 ──

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
	if crystal_sprite:
		crystal_sprite.modulate = Color(0.35, 0.35, 0.4, 1)
	if crown_sprite:
		crown_sprite.modulate = Color(0.25, 0.2, 0.15, 1)
	if wings_left:
		wings_left.modulate = Color(0.3, 0.3, 0.35, 1)
	if wings_right:
		wings_right.modulate = Color(0.3, 0.3, 0.35, 1)


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
	var parts: Array[Sprite2D] = []
	if crystal_sprite: parts.append(crystal_sprite)
	if crown_sprite: parts.append(crown_sprite)
	if wings_left: parts.append(wings_left)
	if wings_right: parts.append(wings_right)
	if parts.is_empty(): return
	var src = parts[randi() % parts.size()]
	var pos = src.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	_spawn_explosion(pos, 0.6)
	_create_debris(pos, 2.0)


func _spawn_final_explosion() -> void:
	_play_sfx(EXPLOSION_SFX, 0)
	for _i in randi_range(20, 30):
		var pos = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		_spawn_explosion(pos, 1.2)
		_create_debris(pos, 3.0)


func _return_to_menu() -> void:
	await get_tree().create_timer(2.5).timeout
	if get_tree():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _shake_parts() -> void:
	if crystal_sprite:
		crystal_sprite.position = crystal_pos + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	if crown_sprite:
		crown_sprite.position = crown_pos + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	if wings_left:
		wings_left.position = wing_left_offset + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	if wings_right:
		wings_right.position = wing_right_offset + Vector2(randf_range(-10, 10), randf_range(-10, 10))


## ── 伤害系统 ──

func _on_body_area_entered(area: Area2D) -> void:
	if dying:
		return
	if area.is_in_group(&"player"):
		return
	if area.get(&"atk") != null:
		apply_damage(area.atk)
		if is_instance_valid(area):
			area.queue_free()


func apply_damage(amount: int) -> void:
	if dying:
		return
	if is_executing:
		amount = maxi(1, amount / 2)
	boss_hp -= amount
	if boss_hp <= 0:
		boss_hp = 0
		_die()
	else:
		_play_sfx(HIT_SFX, -5)


## ── 技能1：羽翼张开扫射 ──

func _skill_1() -> void:
	if dying: return
	await get_tree().create_timer(2.0).timeout


## ── 翅膀状态管理（张开/闭合） ──

func save_wings_open_state() -> void:
	wings_open_wings_scale = wings_scale
	wings_open_wings_z_index = wings_z_index
	wings_open_wings_shake_angle = wings_shake_angle
	wings_open_wings_shake_speed = wings_shake_speed
	wings_open_wing_pivot_left_pos = wing_pivot_left_pos
	wings_open_wing_pivot_right_pos = wing_pivot_right_pos
	wings_open_wing_left_offset = wing_left_offset
	wings_open_wing_right_offset = wing_right_offset


func save_wings_closed_state() -> void:
	wings_closed_wings_scale = wings_scale
	wings_closed_wings_z_index = wings_z_index
	wings_closed_wings_shake_angle = wings_shake_angle
	wings_closed_wings_shake_speed = wings_shake_speed
	wings_closed_wing_pivot_left_pos = wing_pivot_left_pos
	wings_closed_wing_pivot_right_pos = wing_pivot_right_pos
	wings_closed_wing_left_offset = wing_left_offset
	wings_closed_wing_right_offset = wing_right_offset


func apply_wings_open_state() -> void:
	wings_scale = wings_open_wings_scale
	wings_z_index = wings_open_wings_z_index
	wings_shake_angle = wings_open_wings_shake_angle
	wings_shake_speed = wings_open_wings_shake_speed
	wing_pivot_left_pos = wings_open_wing_pivot_left_pos
	wing_pivot_right_pos = wings_open_wing_pivot_right_pos
	wing_left_offset = wings_open_wing_left_offset
	wing_right_offset = wings_open_wing_right_offset
	_set_wings_open(true)


func apply_wings_closed_state() -> void:
	wings_scale = wings_closed_wings_scale
	wings_z_index = wings_closed_wings_z_index
	wings_shake_angle = wings_closed_wings_shake_angle
	wings_shake_speed = wings_closed_wings_shake_speed
	wing_pivot_left_pos = wings_closed_wing_pivot_left_pos
	wing_pivot_right_pos = wings_closed_wing_pivot_right_pos
	wing_left_offset = wings_closed_wing_left_offset
	wing_right_offset = wings_closed_wing_right_offset
	_set_wings_open(false)


## ── 技能2：王冠光束 ──

func _skill_2() -> void:
	if dying: return
	await get_tree().create_timer(2.0).timeout


## ── 技能3：水晶咆哮+敌机 ──

func _skill_3() -> void:
	if dying: return
	await get_tree().create_timer(2.0).timeout


## ── 技能4：羽翼风暴 ──

func _skill_4() -> void:
	if dying: return
	await get_tree().create_timer(2.0).timeout


## ── 技能5：水晶散射 ──

func _skill_5() -> void:
	if dying: return
	await get_tree().create_timer(2.0).timeout


## ── 技能6：三件套齐射 ──

func _skill_6() -> void:
	if dying: return
	await get_tree().create_timer(2.0).timeout


## ── 红点创建 ──

func _create_red_dot_sprite() -> Sprite2D:
	var dot = Sprite2D.new()
	# 创建一个简单的红色圆点纹理
	var size = Vector2(16, 16)
	var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	for y in range(size.y):
		for x in range(size.x):
			var cx = size.x / 2.0
			var cy = size.y / 2.0
			var dx = x - cx
			var dy = y - cy
			var dist_sq = dx * dx + dy * dy
			var radius_sq = (size.x / 2.0) * (size.y / 2.0)
			if dist_sq <= radius_sq:
				img.set_pixel(x, y, Color(1, 0, 0, 1))
	var tex = ImageTexture.create_from_image(img)
	dot.texture = tex
	dot.centered = true
	dot.scale = Vector2(1, 1)
	return dot


## ── 羽翼状态控制 ──

func _set_wings_open(open: bool) -> void:
	_wings_open = open
	if open:
		if wings_left:
			wings_left.texture = WINGS_OPEN_TEX
			wings_left.region_enabled = true
			if WINGS_OPEN_TEX:
				wings_left.region_rect = Rect2(Vector2.ZERO, Vector2(WINGS_OPEN_TEX.get_size().x / 2.0, WINGS_OPEN_TEX.get_size().y))
		if wings_right:
			wings_right.texture = WINGS_OPEN_TEX
			wings_right.region_enabled = true
			if WINGS_OPEN_TEX:
				wings_right.region_rect = Rect2(Vector2(WINGS_OPEN_TEX.get_size().x / 2.0, 0), Vector2(WINGS_OPEN_TEX.get_size().x / 2.0, WINGS_OPEN_TEX.get_size().y))
	else:
		if wings_left:
			wings_left.texture = WINGS_TEX
			wings_left.region_enabled = true
			if WINGS_TEX:
				wings_left.region_rect = Rect2(Vector2.ZERO, Vector2(WINGS_TEX.get_size().x / 2.0, WINGS_TEX.get_size().y))
		if wings_right:
			wings_right.texture = WINGS_TEX
			wings_right.region_enabled = true
			if WINGS_TEX:
				wings_right.region_rect = Rect2(Vector2(WINGS_TEX.get_size().x / 2.0, 0), Vector2(WINGS_TEX.get_size().x / 2.0, WINGS_TEX.get_size().y))


## ── 工具方法 ──

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
