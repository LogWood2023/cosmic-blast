extends Node2D
## 星间巨构总控 —— 共享 HP / 组件管理 / 呼吸动画

@export var body_tex: Texture2D = preload("res://assets/images/boss/boss_colossus_body_cutout.png")
@export var arm_tex: Texture2D = preload("res://assets/images/boss/boss_colossus_arm_cutout.png")
@export var arm_r_tex: Texture2D = preload("res://assets/images/boss/boss_colossus_arm_r_cutout.png")
const ArmScript = preload("res://scripts/StarColossusArm.gd")
const BodyScript = preload("res://scripts/StarColossusBody.gd")
const BOSS_BGM = preload("res://assets/audio/colossus_bgm.mp3")
const EXPLOSION_TEX = preload("res://assets/images/fx/explosion.png")
const DEBRIS_TEX = preload("res://assets/images/fx/debris.png")
const EXPLOSION_SFX = preload("res://assets/audio/explosion.wav")
const HIT_SFX = preload("res://assets/audio/boss_hit.wav")
const ROAR_SFX = preload("res://assets/audio/boss_roar.wav")
const ExplosionScript = preload("res://scripts/Explosion.gd")
const DebrisScript = preload("res://scripts/Debris.gd")

# 技能开关（子类/编辑器覆写）
@export var has_skill_1: bool = false
@export var has_skill_2: bool = true
@export var has_skill_3: bool = false
@export var has_skill_4: bool = false
@export var has_skill_5: bool = true
@export var has_skill_6: bool = true

@export var max_hp: int = 1000
@export var boss_name: String = "星间巨构"
@export var skill_cooldown: float = 2.0       # 技能冷却（秒）
@export var charge_aimed_dmg: int = 5         # 技能1 瞄准弹
@export var charge_scatter_dmg: int = 5       # 技能1 散射弹
@export var punch_dmg: int = 50               # 技能2/5/6 冲拳
@export var burst_dmg: int = 5                # 技能5/6 爆裂弹
@export var bomb_dmg: int = 30                # 技能4 炸弹
@export var quake_spawn_min: int = 5          # 技能3 敌机最少
@export var quake_spawn_max: int = 10         # 技能3 敌机最多
var boss_hp: int
var active: bool = false
var screen_size: Vector2
var bgm_player: AudioStreamPlayer
var cooldown_remaining: float = 2.0           # 登场后 2s 开始
var is_executing: bool = false
var body_origin: Vector2
var arm_right_origin: Vector2              # 右臂原位
var arm_left_origin: Vector2               # 左臂原位
var skill_index: int = 0
var _last_skill: int = -1                   # AI：上次执行的技能编号
var warn_from: Vector2                      # 蓄力警戒线起点
var warn_to: Vector2                        # 蓄力警戒线终点
var warn_active: bool = false
var warn_timer: float = 0.0
var warn_total: float = 2.5                    # 警戒框总时长
var punch_already_hit: bool = false
var punch_arm: Area2D
var combo_punch_count: int = 0
@export var combo_interval: float = 3.0

# 死亡动画
var dying: bool = false
var death_timer: float = 0.0
var death_explosion_cd: float = 0.0
var death_sfx_cd: float = 0.0                # 爆炸音效节流
var death_body_pos: Vector2
var death_arm_left_pos: Vector2
var death_arm_right_pos: Vector2
var won: bool = false
const DEATH_DURATION: float = 5.0

# 进场动画
var entering: bool = true
enum EntrancePhase { SLIDE_IN, POSE, HOLD, RETURN }
var ent_phase: int = EntrancePhase.SLIDE_IN
var ent_timer: float = 0.0
var ent_total: float = 0.0                # 进场累计时间（不随阶段重置）
var overlay_layer: CanvasLayer
var overlay_rect: ColorRect
var overlay_label: Label

@onready var body: Area2D = $Body
@onready var arm_left: Area2D = $LeftArm
@onready var arm_right: Area2D = $RightArm


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	boss_hp = max_hp
	_setup_bgm()
	_build_parts()
	_start_entrance()


func _setup_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = BOSS_BGM
	bgm_player.volume_db = -10
	add_child(bgm_player)


func _build_parts() -> void:
	# 身体：屏幕上方居中，探出 1/3 区域
	body = Area2D.new()
	body.set_script(BodyScript)
	body.name = "Body"
	body.controller = self
	var body_sprite = Sprite2D.new()
	body_sprite.texture = body_tex
	body_sprite.scale = Vector2(1.05, 1.05)
	body_sprite.centered = true
	body.add_child(body_sprite)
	var body_col = CollisionShape2D.new()
	body_col.shape = RectangleShape2D.new()
	body_col.shape.size = Vector2(750, 450)
	body.add_child(body_col)
	body.position = Vector2(screen_size.x * 0.5, 80)
	body.z_index = 50
	body_origin = body.position              # 记录原位
	add_child(body)

	# 左臂
	arm_left = Area2D.new()
	arm_left.set_script(ArmScript)
	arm_left.name = "LeftArm"
	arm_left.controller = self
	arm_left.side = 0
	var la_sprite = Sprite2D.new()
	la_sprite.texture = arm_tex
	la_sprite.scale = Vector2(-2.8125, 2.8125)
	la_sprite.centered = true
	arm_left.add_child(la_sprite)
	arm_left.rotation = deg_to_rad(45)
	var la_col = CollisionShape2D.new()
	la_col.shape = RectangleShape2D.new()
	la_col.shape.size = Vector2(487.5, 675)
	arm_left.add_child(la_col)
	arm_left.position = Vector2(-500, -400)
	arm_left.z_index = 30
	arm_left_origin = arm_left.position
	add_child(arm_left)

	# 右臂
	arm_right = Area2D.new()
	arm_right.set_script(ArmScript)
	arm_right.name = "RightArm"
	arm_right.controller = self
	arm_right.side = 1
	var ra_sprite = Sprite2D.new()
	ra_sprite.texture = arm_r_tex
	ra_sprite.scale = Vector2(2.8125, 2.8125)
	ra_sprite.centered = true
	arm_right.add_child(ra_sprite)
	arm_right.rotation = deg_to_rad(-45)
	var ra_col = CollisionShape2D.new()
	ra_col.shape = RectangleShape2D.new()
	ra_col.shape.size = Vector2(487.5, 675)
	arm_right.add_child(ra_col)
	arm_right.position = Vector2(screen_size.x + 500, -400)
	arm_right.z_index = 30
	arm_right_origin = arm_right.position
	add_child(arm_right)


func _start_bgm() -> void:
	GameManager.bgm_player.stop()
	bgm_player.play.call_deferred()


func _start_entrance() -> void:
	entering = true
	active = false

	body.is_animating = true
	arm_left.is_animating = true
	arm_right.is_animating = true

	# 移到画面上方之外
	body.position.y = -400
	arm_left.position.y = arm_left_origin.y - 400
	arm_right.position.y = arm_right_origin.y - 400

	ent_phase = EntrancePhase.SLIDE_IN
	ent_timer = 0.0

	_create_entrance_overlay()


func _process(delta: float) -> void:
	if dying:
		_death_process(delta)
		return
	if entering:
		_entrance_process(delta)
		return
	if not active or is_executing:
		return
	cooldown_remaining -= delta
	if cooldown_remaining <= 0.0:
		is_executing = true
		var available: Array[int] = []
		if has_skill_1: available.append(0)
		if has_skill_2: available.append(1)
		if has_skill_3: available.append(2)
		if has_skill_4: available.append(3)
		if has_skill_5: available.append(4)
		if has_skill_6: available.append(5)
		var enemy_count = get_tree().get_nodes_in_group("enemies").size()
		var s: int
		if enemy_count > 8:
			var pool_no_3: Array[int] = []
			for a in available:
				if a != 2:
					pool_no_3.append(a)
			s = pool_no_3[randi() % pool_no_3.size()]
		elif has_skill_3 and _last_skill != 2 and enemy_count <= 3:
			s = 2
		else:
			s = available[randi() % available.size()]
		match s:
			0: await _skill_charge_attack()
			1: await _skill_arm_punch(randf() < 0.5)
			2: await _skill_quake()
			3: await _skill_bomb()
			4: await _skill_burst_punch(randf() < 0.5)
			5: await _skill_combo_burst()
		_last_skill = s
		cooldown_remaining = skill_cooldown
		is_executing = false


## ── 进场动画 ──

func _entrance_process(delta: float) -> void:
	ent_timer += delta
	ent_total += delta

	# 黑屏白字：进场第 1.5s ~ 3.5s（硬切换，防震屏余量）
	if is_instance_valid(overlay_rect):
		if ent_total >= 1.5 and ent_total < 3.5:
			if ent_total - delta < 1.5:
				_start_bgm()                  # 黑屏出现时开始 BGM
			overlay_rect.color = Color(0, 0, 0, 1)
			overlay_label.modulate = Color(1, 1, 1, 1)
		else:
			overlay_rect.color = Color(0, 0, 0, 0)
			overlay_label.modulate = Color(1, 1, 1, 0)

	match ent_phase:
		EntrancePhase.SLIDE_IN:
			var t = clampf(ent_timer / 1.0, 0.0, 1.0)
			var e = 1.0 - (1.0 - t) * (1.0 - t)
			body.position.y = lerpf(-400.0, body_origin.y, e)
			arm_left.position.y = lerpf(arm_left_origin.y - 400, arm_left_origin.y, e)
			arm_right.position.y = lerpf(arm_right_origin.y - 400, arm_right_origin.y, e)
			if ent_timer >= 1.0:
				body.position = body_origin
				arm_left.position = arm_left_origin
				arm_right.position = arm_right_origin
				ent_phase = EntrancePhase.POSE
				ent_timer = 0.0

		EntrancePhase.POSE:
			var t = clampf(ent_timer / 0.3, 0.0, 1.0)
			body.position.y = body_origin.y + lerpf(0.0, 100.0, t)
			arm_left.rotation = deg_to_rad(45.0 + lerpf(0.0, 10.0, t))
			arm_right.rotation = deg_to_rad(-45.0 + lerpf(0.0, -10.0, t))
			if ent_timer >= 0.3:
				ent_phase = EntrancePhase.HOLD
				ent_timer = 0.0
				_play_sfx(ROAR_SFX, -5)

		EntrancePhase.HOLD:
			body.position = body_origin + Vector2(0, 100) + Vector2(randf_range(-8, 8), randf_range(-6, 6))
			arm_left.position = arm_left_origin + Vector2(randf_range(-10, 10), randf_range(-8, 8))
			arm_right.position = arm_right_origin + Vector2(randf_range(-10, 10), randf_range(-8, 8))
			var cam = get_viewport().get_camera_2d()
			if cam:
				cam.offset = Vector2(randf_range(-8, 8), randf_range(-5, 5))

			if ent_timer >= 3.0:
				if cam: cam.offset = Vector2.ZERO
				overlay_layer.queue_free()
				ent_phase = EntrancePhase.RETURN
				ent_timer = 0.0

		EntrancePhase.RETURN:
			# 0.3s 回归原位
			var t = clampf(ent_timer / 0.3, 0.0, 1.0)
			body.position.y = lerpf(body_origin.y + 100.0, body_origin.y, t)
			arm_left.rotation = lerpf(deg_to_rad(55.0), deg_to_rad(45.0), t)
			arm_right.rotation = lerpf(deg_to_rad(-55.0), deg_to_rad(-45.0), t)
			if ent_timer >= 0.3:
				body.position = body_origin
				arm_left.position = arm_left_origin
				arm_right.position = arm_right_origin
				arm_left.rotation = deg_to_rad(45.0)
				arm_right.rotation = deg_to_rad(-45.0)
				body.is_animating = false
				arm_left.is_animating = false
				arm_right.is_animating = false
				entering = false
				active = true
				cooldown_remaining = 2.0


func _create_entrance_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100
	overlay_layer.follow_viewport_enabled = true

	overlay_rect = ColorRect.new()
	overlay_rect.color = Color(0, 0, 0, 0)
	# 铺满屏幕 + 150px 余量，防止相机震动露出边缘
	overlay_rect.anchor_left = 0.0
	overlay_rect.anchor_top = 0.0
	overlay_rect.anchor_right = 1.0
	overlay_rect.anchor_bottom = 1.0
	overlay_rect.offset_left = -150.0
	overlay_rect.offset_top = -150.0
	overlay_rect.offset_right = 150.0
	overlay_rect.offset_bottom = 150.0
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	overlay_label = Label.new()
	overlay_label.text = boss_name
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label.modulate = Color(1, 1, 1, 0)
	overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 字体：使用项目默认字体 + 尺寸覆写
	overlay_label.add_theme_font_size_override(&"font_size", 72)

	overlay_layer.add_child(overlay_rect)
	overlay_layer.add_child(overlay_label)
	add_child(overlay_layer)


## ═══════ 技能 1: 蓄力冲击 + 弹幕 ═══════

func _skill_charge_attack() -> void:

	# 阶段 1: 身体上移 50（先快后慢，0.5s）
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(body, "position", body_origin + Vector2(0, -50), 0.5)
	await tw.finished

	# 蓄力停顿 0.5s
	await get_tree().create_timer(0.5).timeout

	# 阶段 2: 身体下冲 100（匀速，1000 速度 → 0.1s）
	tw = create_tween()
	tw.tween_property(body, "position", body_origin + Vector2(0, 100), 0.1)
	await tw.finished

	# 阶段 3: 随机变体 — 50% 连发瞄准 / 50% 散射
	if randf() < 0.5:
		await _fire_aimed_burst()
	else:
		await _fire_scatter()

	# 阶段 4: 回归原位
	tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(body, "position", body_origin, 0.5)




## ── 变体 A: 连发瞄准（朝玩家）──

func _fire_aimed_burst() -> void:
	for i in randi_range(10, 20):
		if not active:
			break
		_shake_body()
		_spawn_aimed_bullet()
		await get_tree().create_timer(0.15).timeout


func _spawn_aimed_bullet() -> void:
	var bullet = preload("res://scenes/EnemyBullet.tscn").instantiate()
	var dir = Vector2.DOWN
	var player = get_tree().get_first_node_in_group(&"player")
	if player:
		dir = (player.global_position - body.global_position).normalized()
	bullet.direction = dir
	bullet.damage = charge_aimed_dmg
	bullet.speed = 1000
	bullet.position = body.global_position + Vector2(0, 150)
	bullet.rotation = dir.angle()
	bullet.z_index = -80
	bullet.scale = Vector2(1.84 * 4, 1.84 * 4)
	get_tree().current_scene.add_child(bullet)


## ── 变体 B: 散射（正下方，6-12 枚）──

func _fire_scatter() -> void:
	var shots_fired = 0
	while true:
		if not active:
			break
		_shake_body()

		var count = randi_range(6, 12)
		var spread = deg_to_rad(120.0)
		var angle_step = spread / float(count - 1) if count > 1 else 0.0
		var start_angle = PI / 2.0 - spread / 2.0
		for j in count:
			var angle = start_angle + angle_step * j
			var dir = Vector2(cos(angle), sin(angle))
			_spawn_scatter_bullet(dir)

		shots_fired += 1
		if shots_fired >= 3 and randf() < 1.0 / 3.0:
			break
		await get_tree().create_timer(1.0).timeout


func _shake_body() -> void:
	body.position.x = body_origin.x + randf_range(-12, 12)
	await get_tree().create_timer(0.05).timeout
	body.position.x = body_origin.x + randf_range(-12, 12)
	await get_tree().create_timer(0.05).timeout
	body.position.x = body_origin.x


## ═══════ 技能 2: 冲拳（左/右随机）═══════

func _skill_arm_punch(use_left: bool) -> void:
	punch_already_hit = false
	var puncher = arm_left if use_left else arm_right
	punch_arm = puncher                           # 碰撞检测用
	var companion = arm_right if use_left else arm_left
	var punch_origin = arm_left_origin if use_left else arm_right_origin
	var comp_origin = arm_right_origin if use_left else arm_left_origin
	puncher.is_animating = true
	companion.is_animating = true

	# 阶段 1: 蓄力上移
	var punch_sign = 1.0 if use_left else -1.0
	var charge_sign = -1.0 if use_left else 1.0
	var charge_target = punch_origin + Vector2(35 * charge_sign, -35)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(puncher, "position", charge_target, 0.5)
	await tw.finished

	# 蓄力期间：前 1/3 旋转追踪玩家，后 2/3 冻结
	var punch_dir = Vector2(punch_sign, 1).normalized()
	var frozen_dir = punch_dir
	warn_active = true
	warn_total = 2.5
	warn_timer = warn_total

	var shake_end = Time.get_ticks_msec() / 1000.0 + 2.5
	var freeze_after = 2.5 / 3.0
	var shake_elapsed = 0.0
	while Time.get_ticks_msec() / 1000.0 < shake_end:
		if not active:
			return
		puncher.position.x = charge_target.x + randf_range(-8, 8)
		puncher.position.y = charge_target.y + randf_range(-8, 8)
		shake_elapsed += 0.05
		if shake_elapsed < freeze_after:
			var player_dir = _get_player_direction(puncher.global_position)
			if player_dir.length() > 0.01:
				punch_dir = player_dir
				var rot = punch_dir.angle()
				if not use_left:
					rot = rot - PI if rot >= 0.0 else rot + PI
				puncher.rotation = lerp_angle(puncher.rotation, rot, 0.15)
		else:
			if shake_elapsed - 0.05 < freeze_after:
				frozen_dir = punch_dir
		warn_from = puncher.global_position
		warn_to = puncher.position + punch_dir * 2000
		warn_timer -= 0.05
		queue_redraw()
		await get_tree().create_timer(0.05).timeout
	puncher.position = charge_target
	warn_active = false
	queue_redraw()

	# 计算冲拳距离：沿冻结方向到屏幕边缘
	var punch_dist = _calc_punch_dist(puncher.global_position, frozen_dir)
	var punch_target_pos = puncher.position + frozen_dir * punch_dist
	var comp_target = comp_origin + Vector2(50 * punch_sign, -50)

	# 阶段 2: 冲刺 + 碰撞检测
	var tw_comp = create_tween()
	tw_comp.tween_property(companion, "position", comp_target, 50.0 / 200.0)
	tw = create_tween()
	tw.tween_property(puncher, "position", punch_target_pos, punch_dist / 8000.0)
	while tw.is_running():
		if not active:
			return
		_check_punch_hit()
		await get_tree().process_frame
	_check_punch_hit()
	_punch_land_shake()
	await get_tree().create_timer(0.5).timeout
	_check_punch_hit()

	# 阶段 3: 回归原位（位置 + 旋转）
	var puncher_orig_rot = deg_to_rad(45.0) if use_left else deg_to_rad(-45.0)
	tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(puncher, "position", punch_origin, 0.25)
	tw.tween_property(companion, "position", comp_origin, 0.25)
	tw.tween_property(puncher, "rotation", puncher_orig_rot, 0.5)
	await tw.finished

	puncher.base_rotation = puncher_orig_rot
	puncher.sway_phase = 0.0
	puncher.is_animating = false
	companion.is_animating = false



## ═══════ 技能 5: 冲拳 + 爆裂弹 ═══════

func _skill_burst_punch(use_left: bool) -> void:
	punch_already_hit = false
	var puncher = arm_left if use_left else arm_right
	punch_arm = puncher
	var companion = arm_right if use_left else arm_left
	var punch_origin = arm_left_origin if use_left else arm_right_origin
	var comp_origin = arm_right_origin if use_left else arm_left_origin
	puncher.is_animating = true
	companion.is_animating = true

	var punch_sign = 1.0 if use_left else -1.0
	var charge_sign = -1.0 if use_left else 1.0
	var charge_target = punch_origin + Vector2(35 * charge_sign, -35)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(puncher, "position", charge_target, 0.5)
	await tw.finished

	# 蓄力期间：前 1/3 旋转追踪玩家，后 2/3 冻结
	var punch_dir = Vector2(punch_sign, 1).normalized()
	var frozen_dir = punch_dir
	warn_active = true
	warn_total = 2.5
	warn_timer = warn_total

	var shake_end = Time.get_ticks_msec() / 1000.0 + 2.5
	var freeze_after = 2.5 / 3.0
	var shake_elapsed = 0.0
	while Time.get_ticks_msec() / 1000.0 < shake_end:
		if not active:
			return
		puncher.position.x = charge_target.x + randf_range(-8, 8)
		puncher.position.y = charge_target.y + randf_range(-8, 8)
		shake_elapsed += 0.05
		# 前 1/3：旋转手臂追踪玩家
		if shake_elapsed < freeze_after:
			var player_dir = _get_player_direction(puncher.global_position)
			if player_dir.length() > 0.01:
				punch_dir = player_dir
				var rot = punch_dir.angle()
				if not use_left:
					rot = rot - PI if rot >= 0.0 else rot + PI
				puncher.rotation = lerp_angle(puncher.rotation, rot, 0.15)
		# 后 2/3：冻结当前方向
		else:
			if shake_elapsed - 0.05 < freeze_after:
				frozen_dir = punch_dir
		warn_from = puncher.global_position
		warn_to = puncher.position + punch_dir * 2000
		warn_timer -= 0.05
		queue_redraw()
		await get_tree().create_timer(0.05).timeout
	puncher.position = charge_target
	warn_active = false
	queue_redraw()

	# 计算冲拳距离：沿冻结方向到屏幕边缘
	var punch_dist = _calc_punch_dist(puncher.global_position, frozen_dir)
	var punch_target_pos = puncher.position + frozen_dir * punch_dist
	var comp_target = comp_origin + Vector2(50 * punch_sign, -50)

	# 冲刺 + 碰撞 + 爆裂弹
	var tw_comp = create_tween()
	tw_comp.tween_property(companion, "position", comp_target, 50.0 / 200.0)
	tw = create_tween()
	tw.tween_property(puncher, "position", punch_target_pos, punch_dist / 8000.0)
	while tw.is_running():
		if not active:
			return
		_check_punch_hit()
		await get_tree().process_frame
	_check_punch_hit()
	_punch_land_shake()
	var burst_point = puncher.global_position + frozen_dir * _calc_raw_edge_dist(puncher.global_position, frozen_dir)
	_spawn_burst_at(burst_point)
	await get_tree().create_timer(0.5).timeout
	_check_punch_hit()

	# 回归原位（位置 + 旋转）
	var puncher_orig_rot = deg_to_rad(45.0) if use_left else deg_to_rad(-45.0)
	tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(puncher, "position", punch_origin, 0.25)
	tw.tween_property(companion, "position", comp_origin, 0.25)
	tw.tween_property(puncher, "rotation", puncher_orig_rot, 0.5)
	await tw.finished

	puncher.base_rotation = puncher_orig_rot
	puncher.sway_phase = 0.0
	puncher.is_animating = false
	companion.is_animating = false


func _get_player_direction(from_pos: Vector2) -> Vector2:
	var player = get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return Vector2.ZERO
	var d = player.global_position - from_pos
	if d.length() < 0.1:
		return Vector2.ZERO
	return d.normalized()


func _calc_punch_dist(from_global: Vector2, direction: Vector2) -> float:
	var dist = screen_size.length() * 2.0
	if direction.y > 0.001:
		dist = min(dist, (screen_size.y - from_global.y) / direction.y)
	if direction.x < -0.001:
		dist = min(dist, -from_global.x / direction.x)
	elif direction.x > 0.001:
		dist = min(dist, (screen_size.x - from_global.x) / direction.x)
	return max(dist - 500.0, 200.0)


func _calc_raw_edge_dist(from_global: Vector2, direction: Vector2) -> float:
	var dist = screen_size.length() * 2.0
	if direction.y > 0.001:
		dist = min(dist, (screen_size.y - from_global.y) / direction.y)
	if direction.x < -0.001:
		dist = min(dist, -from_global.x / direction.x)
	elif direction.x > 0.001:
		dist = min(dist, (screen_size.x - from_global.x) / direction.x)
	return max(dist, 200.0)


func _spawn_burst_at(center_global: Vector2) -> void:
	var count = randi_range(10, 20)
	var angle_step = TAU / float(count)
	for i in count:
		var dir = Vector2.RIGHT.rotated(angle_step * i)
		var bullet = preload("res://scenes/EnemyBullet.tscn").instantiate()
		bullet.direction = dir
		bullet.damage = burst_dmg
		bullet.speed = 600
		bullet.position = center_global
		bullet.rotation = dir.angle()
		bullet.z_index = -80
		bullet.scale = Vector2(3.6, 3.6)
		get_tree().current_scene.add_child(bullet)


## ═══════ 技能 6: 连拳爆裂弹 ═══════

func _skill_combo_burst() -> void:
	var use_left = randf() < 0.5
	combo_punch_count = 0
	const MIN_PUNCH = 3

	while true:
		var arm = arm_left if use_left else arm_right
		var origin = arm_left_origin if use_left else arm_right_origin
		arm.is_animating = true

		var sign = 1.0 if use_left else -1.0
		var cs = -1.0 if use_left else 1.0
		var charge_target = origin + Vector2(35 * cs, -35)

		var tw = create_tween()
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(arm, "position", charge_target, 0.5)
		await tw.finished

		# 颤抖——逐步加速，最低1.0s
		var base_len = 1.0 if combo_punch_count == 0 else (0.6 if combo_punch_count == 1 else 1.0)
		var shake_len = max(base_len, 1.0)
		var punch_dir = Vector2(sign, 1).normalized()
		var frozen_dir = punch_dir
		warn_active = true
		warn_total = shake_len
		warn_timer = warn_total
		var shake_end = Time.get_ticks_msec() / 1000.0 + shake_len
		var freeze_after = shake_len / 3.0
		var shake_elapsed = 0.0
		while Time.get_ticks_msec() / 1000.0 < shake_end:
			if not active:
				return
			arm.position.x = charge_target.x + randf_range(-8, 8)
			arm.position.y = charge_target.y + randf_range(-8, 8)
			shake_elapsed += 0.05
			if shake_elapsed < freeze_after:
				var player_dir = _get_player_direction(arm.global_position)
				if player_dir.length() > 0.01:
					punch_dir = player_dir
					var rot = punch_dir.angle()
					if not use_left:
						rot = rot - PI if rot >= 0.0 else rot + PI
					arm.rotation = lerp_angle(arm.rotation, rot, 0.15)
			else:
				if shake_elapsed - 0.05 < freeze_after:
					frozen_dir = punch_dir
			warn_from = arm.global_position
			warn_to = arm.position + punch_dir * 2000
			warn_timer -= 0.05
			queue_redraw()
			await get_tree().create_timer(0.05).timeout
		arm.position = charge_target
		warn_active = false
		queue_redraw()

		# 冲拳 + 爆裂
		var punch_dist = _calc_punch_dist(arm.global_position, frozen_dir)
		var punch_target_pos = arm.position + frozen_dir * punch_dist
		tw = create_tween()
		tw.tween_property(arm, "position", punch_target_pos, punch_dist / 8000.0)
		punch_already_hit = false
		punch_arm = arm
		while tw.is_running():
			if not active:
				return
			_check_punch_hit()
			await get_tree().process_frame
		_check_punch_hit()
		_punch_land_shake()
		var burst_point = arm.global_position + frozen_dir * _calc_raw_edge_dist(arm.global_position, frozen_dir)
		_spawn_burst_at(burst_point)
		await get_tree().process_frame
		_check_punch_hit()

		combo_punch_count += 1
		warn_active = false
		queue_redraw()

		# 异步收回（位置 + 旋转）
		var arm_orig_rot = deg_to_rad(45.0) if use_left else deg_to_rad(-45.0)
		tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(arm, "position", origin, 0.25)
		tw.tween_property(arm, "rotation", arm_orig_rot, 0.5)
		tw.tween_callback(func(): 
			if is_instance_valid(arm):
				arm.base_rotation = arm_orig_rot
				arm.sway_phase = 0.0
				arm.is_animating = false
		)

		use_left = not use_left
		if combo_punch_count >= MIN_PUNCH and randf() > 2.0 / 3.0:
			break




func _draw() -> void:
	if not warn_active:
		return
	var from = warn_from
	var to = warn_to
	var dir = (to - from).normalized()
	if dir.length() < 0.01:
		return
	var perp = Vector2(-dir.y, dir.x)
	var full_half_w = 243.75

	# 宽度动画：出现0→满(0.5s)，消失满→2倍+透零(0.5s)
	var elapsed = warn_total - warn_timer
	var half_w = full_half_w
	var fade_alpha = 1.0
	if elapsed < 0.5:
		half_w = full_half_w * (elapsed / 0.5)
	elif warn_timer < 0.5:
		var t = 1.0 - warn_timer / 0.5
		half_w = full_half_w * (1.0 + t)
		fade_alpha = 1.0 - t

	var flash = fmod(Time.get_ticks_msec() / 1000.0, 0.6)
	var is_red = flash < 0.3
	var base_alpha = 0.3
	var col = Color(1, 0.05, 0.05, base_alpha * fade_alpha) if is_red else Color(1, 0.8, 0.05, base_alpha * fade_alpha)
	var length = from.distance_to(to)
	const SEGS = 40
	for i in SEGS:
		var t0 = float(i) / SEGS
		var t1 = float(i + 1) / SEGS
		var a = (t0 + t1) * 0.5
		var alpha_mod = 1.0
		if a >= 0.95:
			alpha_mod = (1.0 - a) / 0.05
		var p_a = from + dir * t0 * length
		var p_b = from + dir * t1 * length
		var pts = PackedVector2Array([
			to_local(p_a + perp * half_w),
			to_local(p_a - perp * half_w),
			to_local(p_b - perp * half_w),
			to_local(p_b + perp * half_w),
		])
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, col.a * alpha_mod))


func _spawn_scatter_bullet(dir: Vector2) -> void:
	var bullet = preload("res://scenes/EnemyBullet.tscn").instantiate()
	bullet.direction = dir
	bullet.damage = charge_scatter_dmg
	bullet.speed = 500
	bullet.position = body.global_position + Vector2(0, 150)
	bullet.rotation = dir.angle()
	bullet.z_index = -80
	bullet.scale = Vector2(1.84 * 2, 1.84 * 2)
	get_tree().current_scene.add_child(bullet)


func apply_damage(amount: int) -> void:
	if entering or dying:
		return
	boss_hp -= amount
	if boss_hp <= 0:
		_die()
	else:
		_play_sfx(HIT_SFX, -5)


func _die() -> void:
	if dying:
		return
	active = false
	dying = true
	death_timer = 0.0
	death_explosion_cd = 0.0
	death_sfx_cd = 0.0
	bgm_player.stop()
	GameManager.bgm_player.play()

	# 冻结呼吸动画，记录死亡姿态起始位置，压暗材质
	if is_instance_valid(body):
		body.is_animating = true
		death_body_pos = body.position
		body.modulate = Color(0.35, 0.35, 0.4, 1)
	if is_instance_valid(arm_left):
		arm_left.is_animating = true
		death_arm_left_pos = arm_left.position
		arm_left.modulate = Color(0.35, 0.35, 0.4, 1)
	if is_instance_valid(arm_right):
		arm_right.is_animating = true
		death_arm_right_pos = arm_right.position
		arm_right.modulate = Color(0.35, 0.35, 0.4, 1)

	# 旋转到死亡姿势（1s，与爆炸颤抖同时进行）
	var tw = create_tween()
	tw.set_parallel(true)
	if is_instance_valid(body):
		tw.tween_property(body, "rotation", body.rotation + deg_to_rad(-15), 1.0)
	if is_instance_valid(arm_left):
		tw.tween_property(arm_left, "rotation", arm_left.rotation + deg_to_rad(10), 1.0)
	if is_instance_valid(arm_right):
		tw.tween_property(arm_right, "rotation", arm_right.rotation + deg_to_rad(-8), 1.0)


## ── 死亡动画：每帧 ──

func _death_process(delta: float) -> void:
	death_timer += delta
	death_explosion_cd -= delta
	death_sfx_cd -= delta

	# 每秒 30-45 次爆炸（原 3 倍）
	if death_explosion_cd <= 0.0:
		_spawn_death_explosion()
		death_explosion_cd = randf_range(1.0 / 45.0, 1.0 / 30.0)
		# 音效节流：每 0.15s 最多一次
		if death_sfx_cd <= 0.0:
			_play_sfx(EXPLOSION_SFX, -8)
			death_sfx_cd = 0.15

	# 剧烈颤抖（基于死亡姿态起始位置，不漂移）
	_shake_parts()

	if death_timer >= DEATH_DURATION and not won:
		won = true
		_spawn_final_explosion()
		queue_free()
		_return_to_menu()


func _return_to_menu() -> void:
	await get_tree().create_timer(2.5).timeout
	if get_tree():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _spawn_death_explosion() -> void:
	# 身体 + 双臂同时发生爆炸
	for part in [body, arm_left, arm_right]:
		if not is_instance_valid(part):
			continue
		var pos: Vector2
		for _retry in 10:
			var offset = Vector2(randf_range(-150, 150), randf_range(-100, 100))
			pos = part.global_position + offset
			if pos.x >= 0 and pos.x <= screen_size.x and pos.y >= 0 and pos.y <= screen_size.y:
				break

		var exp = Sprite2D.new()
		exp.set_script(ExplosionScript)
		exp.texture = EXPLOSION_TEX
		exp.position = pos
		exp.rotation = randf_range(0, TAU)
		exp.scale = Vector2(0.5, 0.5)
		exp.z_index = 100
		get_tree().current_scene.add_child(exp)
		_spawn_debris(pos, randi_range(3, 6))


func _spawn_debris(pos: Vector2, count: int) -> void:
	const QUAD = 512
	for _i in count:
		var d = Sprite2D.new()
		d.set_script(DebrisScript)
		d.texture = DEBRIS_TEX
		d.position = pos
		d.scale = Vector2(randf_range(0.05, 0.08), randf_range(0.05, 0.08))
		d.rotation = randf_range(0, TAU)
		d.region_enabled = true
		d.region_rect = Rect2(randi_range(0, 1) * QUAD, randi_range(0, 1) * QUAD, QUAD, QUAD)
		var a = randf_range(0, TAU)
		d.velocity = Vector2(cos(a), sin(a)) * randf_range(80, 200)
		d.rotation_speed = randf_range(-10, 10)
		d.z_index = -100
		get_tree().current_scene.add_child(d)


func _shake_parts() -> void:
	if is_instance_valid(body):
		body.position = death_body_pos + Vector2(randf_range(-25, 25), randf_range(-20, 20))
	if is_instance_valid(arm_left):
		arm_left.position = death_arm_left_pos + Vector2(randf_range(-35, 35), randf_range(-25, 25))
	if is_instance_valid(arm_right):
		arm_right.position = death_arm_right_pos + Vector2(randf_range(-35, 35), randf_range(-25, 25))
	var cam = get_viewport().get_camera_2d()
	if cam:
		cam.offset = Vector2(randf_range(-15, 15), randf_range(-10, 10))


func _spawn_final_explosion() -> void:
	_play_sfx(EXPLOSION_SFX, 0)

	# 20-30 个爆炸原点，分布在 Boss 身体覆盖区域内
	var origins = randi_range(20, 30)
	for _i in origins:
		var pos = _random_boss_pos()
		var exp = Sprite2D.new()
		exp.set_script(ExplosionScript)
		exp.texture = EXPLOSION_TEX
		exp.position = pos
		exp.rotation = randf_range(0, TAU)
		exp.scale = Vector2(1.2, 1.2)
		exp.z_index = 200
		get_tree().current_scene.add_child(exp)
		# 每个原点正常敌机碎片量（6-10）
		_spawn_debris(pos, randi_range(6, 10))


func _random_boss_pos() -> Vector2:
	# Boss 身体覆盖区域：以身体为中心，含手臂延展范围
	var bx: float = screen_size.x * 0.5
	var by: float = 150.0
	return Vector2(
		randf_range(bx - 300, bx + 300),
		randf_range(by - 250, by + 300)
	)


func _play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)


## ═══════ 技能 3: 地震 ═══════

func _skill_quake() -> void:
	body.is_animating = true
	arm_left.is_animating = true
	arm_right.is_animating = true

	# 阶段 1: 双臂外张 + 身体下压（0.5s）
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(arm_left, "position", arm_left_origin + Vector2(-50, -50), 0.5)
	tw.parallel().tween_property(arm_right, "position", arm_right_origin + Vector2(50, -50), 0.5)
	tw.parallel().tween_property(body, "position", body_origin + Vector2(0, 100), 0.5)
	await tw.finished

	# 阶段 2: 三件套颤动 1s + 屏幕震动 0.5s + 依次生成敌机
	var enemy_count = randi_range(quake_spawn_min, quake_spawn_max)
	var spawn_interval = 1.0 / float(enemy_count)
	var spawn_timer = 0.0
	var spawned = 0
	var shake_end = Time.get_ticks_msec() / 1000.0 + 1.0
	var cam = get_viewport().get_camera_2d()
	var cam_orig = cam.global_position if cam else Vector2.ZERO
	var screen_shake_end = Time.get_ticks_msec() / 1000.0 + 0.5

	while Time.get_ticks_msec() / 1000.0 < shake_end:
		if not active:
			return
		body.position.x = body_origin.x + randf_range(-12, 12)
		arm_left.position = arm_left_origin + Vector2(-50 + randf_range(-8, 8), -50 + randf_range(-8, 8))
		arm_right.position = arm_right_origin + Vector2(50 + randf_range(-8, 8), -50 + randf_range(-8, 8))
		if cam and Time.get_ticks_msec() / 1000.0 < screen_shake_end:
			cam.global_position = cam_orig + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		spawn_timer += 0.025
		while spawned < enemy_count and spawn_timer >= spawn_interval:
			spawn_timer -= spawn_interval
			_spawn_single_quake_enemy()
			spawned += 1
		await get_tree().create_timer(0.025).timeout

	# 阶段 3: 复位（0.5s）
	if cam:
		cam.global_position = cam_orig
	tw = create_tween()
	tw.tween_property(body, "position", body_origin, 0.5)
	tw.parallel().tween_property(arm_left, "position", arm_left_origin, 0.5)
	tw.parallel().tween_property(arm_right, "position", arm_right_origin, 0.5)
	await tw.finished

	body.is_animating = false
	arm_left.is_animating = false
	arm_right.is_animating = false




## ═══════ 技能 4: 炸弹散布 ═══════

func _skill_bomb() -> void:
	body.is_animating = true

	# 阶段 1: 蓄力上移（同技能1）
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(body, "position", body_origin + Vector2(0, -50), 0.5)
	await tw.finished
	await get_tree().create_timer(0.5).timeout

	# 阶段 2: 身体下冲
	tw = create_tween()
	tw.tween_property(body, "position", body_origin + Vector2(0, 100), 0.1)
	await tw.finished

	# 阶段 3: 散布炸弹（8-12枚，均匀排布画面下1/3）
	var count = randi_range(8, 12)
	var variant = randf() < 0.5
	var target_y = screen_size.y * 0.75 + 100
	var step_x = (screen_size.x - 80.0) / float(count - 1) if count > 1 else 0.0
	var body_bottom = body.global_position + Vector2(0, 150)

	for i in count:
		if not active:
			break
		var ty = target_y
		if variant:
			ty = target_y - 300
		var target = Vector2(40.0 + step_x * i, ty)
		var bomb = preload("res://scenes/Bomb.tscn").instantiate()
		bomb.position = body_bottom
		bomb.damage = bomb_dmg
		bomb.explode_delay = 3.0
		bomb.explosion_radius = 156.0
		bomb.travel_target = target
		bomb.flight_duration = 0.3
		get_tree().current_scene.add_child(bomb)
		await get_tree().create_timer(0.1).timeout

	# 阶段 4: 回归原位
	tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(body, "position", body_origin, 0.5)

	body.is_animating = false



func _punch_land_shake() -> void:
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
	var orig = cam.offset
	var tw = create_tween()
	tw.tween_method(_shake_cam_step.bind(cam, orig), 0.0, 1.0, 0.25)
	tw.tween_callback(func(): cam.offset = orig)


func _shake_cam_step(t: float, cam: Camera2D, orig: Vector2) -> void:
	cam.offset = orig + Vector2(sin(t * 35) * 14, cos(t * 30) * 10)


func _check_punch_hit() -> void:
	if punch_already_hit:
		return
	var player = get_tree().get_first_node_in_group(&"player")
	if player and punch_arm and player.global_position.distance_to(punch_arm.global_position) < 250:
		punch_already_hit = true
		player.take_damage_from_boss(punch_dmg)


func _spawn_quake_enemies() -> void:
	var count = randi_range(quake_spawn_min, quake_spawn_max)
	for _i in count:
		_spawn_single_quake_enemy()


func _spawn_single_quake_enemy() -> void:
	var idx = randi() % 2
	var path = "res://scenes/EnemyMissile.tscn" if idx == 0 else "res://scenes/EnemyRammer.tscn"
	var enemy = load(path).instantiate()
	var is_left = randi() % 2 == 0
	var x = -200.0 if is_left else screen_size.x + 200.0
	enemy.position = Vector2(x, randf_range(80, screen_size.y * 0.6))
	get_tree().current_scene.add_child(enemy)
