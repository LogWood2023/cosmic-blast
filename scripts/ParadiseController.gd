extends Node2D
## 天堂号总控 —— 巨型飞机 Boss（俯视角），3 停泊位，4 旋转机炮

@export var body_tex: Texture2D
@export var cannon_tex: Texture2D
const BOSS_BGM = preload("res://assets/audio/paradise_bgm.mp3")

enum Dock { TOP, LEFT, RIGHT }

@export_enum("TOP", "LEFT", "RIGHT") var dock: int = 0
@export var max_hp: int = 1200
@export var boss_name: String = "天堂号"
@export var body_scale: Vector2 = Vector2(1, 1)
@export var body_offset: Vector2 = Vector2(0, -280)   # 机身相对旋转中心
@export var pivot_offset: Vector2 = Vector2(0, 0)     # 旋转中心相对停泊位
@export var world_offset: Vector2 = Vector2(0, 0)     # 整体在游戏中的绝对偏移
@export var cannon_0_pos: Vector2 = Vector2(-320, 100)
@export var cannon_1_pos: Vector2 = Vector2(-110, 80)
@export var cannon_2_pos: Vector2 = Vector2(110, 80)
@export var cannon_3_pos: Vector2 = Vector2(320, 100)
@export var cannon_scale: Vector2 = Vector2(0.45, 0.45)
@export var show_pivot: bool = true
@export var sway_amplitude: float = 30.0        # 待机摆动幅度（px）
@export var sway_speed: float = 1.5             # 待机摆动速度
var sway_phase: float = 0.0                       # 左右摆动相位
var sway_phase_2: float = 0.0                     # 前后摆动相位
var boss_hp: int
var active: bool = false
var screen_size: Vector2

# 进场
var entering: bool = true
var entrance_timer: float = 0.0
var dock_pos: Vector2
var cannon_targets: Array[Vector2] = []     # 机炮记录位置
var bgm_player: AudioStreamPlayer
var overlay_layer: CanvasLayer
var overlay_rect: ColorRect
var overlay_label: Label

# 死亡
var dying: bool = false
var death_timer: float = 0.0
const DEATH_DURATION: float = 5.0
var death_explosion_cd: float = 0.0
var death_sfx_cd: float = 0.0
var won: bool = false

# 激光射线
var lasers: Array[Line2D] = []
var lasers_stable: bool = false

# 机炮
var cannons: Array[Area2D] = []
const CANNON_COUNT: int = 4
const CANNON_BASE_CD: float = 8.0
const CANNON_RANDOM_CD: float = 4.0
var cannon_cooldowns: Array[float] = []
const EnemyBulletScene = preload("res://scenes/EnemyBullet.tscn")
const ExplosionScript = preload("res://scripts/Explosion.gd")
const DebrisScript = preload("res://scripts/Debris.gd")
const EXPLOSION_TEX = preload("res://assets/images/fx/explosion.png")
const DEBRIS_TEX = preload("res://assets/images/fx/debris.png")
const EXPLOSION_SFX = preload("res://assets/audio/explosion.wav")
const HIT_SFX = preload("res://assets/audio/boss_hit.wav")
const CANNON_MOVE_SFX = preload("res://assets/audio/cannon_move.wav")
const LASER_ZAP_SFX = preload("res://assets/audio/laser_zap.wav")

# 技能开关（子类/编辑器覆写）
@export var has_skill_1: bool = true
@export var has_skill_2: bool = true
@export var has_skill_3: bool = true
@export var has_skill_4: bool = true
@export var has_skill_5: bool = true
@export var has_skill_6: bool = true
@export var skill_cooldown: float = 2.0

# 伤害值（可在检查器中调整）
@export var cannon_bullet_dmg: int = 5
@export var skill_1_bullet_dmg: int = 5
@export var skill_2_bullet_dmg: int = 5
@export var skill_4_laser_dmg: int = 20
@export var skill_5_bullet_dmg: int = 5
@export var skill_6_bullet_dmg: int = 5
@export var skill_6_explosion_dmg: int = 50

# 技能状态
var is_executing: bool = false
var cooldown_remaining: float = 0.0
var _last_skill: int = -1

# 技能3 信号环绘制节点
var ring_drawer: Node2D

# 技能2/5 警戒框
var warn_list: Array = []   # [{from, to, timer}]
var warn_circle: Dictionary = {}  # {pos, timer, radius}
const WARN_DURATION: float = 3.0

# Tween 追踪（死亡时批量 kill）
var _skill_tweens: Array[Tween] = []

@onready var body_sprite: Sprite2D = $BodySprite


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	boss_hp = max_hp
	if not body_tex:
		body_tex = preload("res://assets/images/paradise/paradise_body_v4_cutout.png")
	if not cannon_tex:
		cannon_tex = preload("res://assets/images/paradise/paradise_cannon_v2_cutout.png")
	body_sprite.texture = body_tex
	body_sprite.scale = body_scale
	body_sprite.position = body_offset
	body_sprite.z_index = 60
	_setup_bgm()
	_setup_dock()
	_build_cannons()
	_create_pivot_dot()
	_create_ring_drawer()
	_create_entrance_overlay()
	_start_entrance()


func _setup_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = BOSS_BGM
	bgm_player.volume_db = -10
	add_child(bgm_player)


func _setup_dock() -> void:
	match dock:
		Dock.TOP:
			dock_pos = Vector2(screen_size.x * 0.5, 120)
			rotation_degrees = 0
		Dock.LEFT:
			dock_pos = Vector2(120, screen_size.y * 0.5)
			rotation_degrees = -90
		Dock.RIGHT:
			dock_pos = Vector2(screen_size.x - 120, screen_size.y * 0.5)
			rotation_degrees = 90
	position = dock_pos + pivot_offset + world_offset


func _create_pivot_dot() -> void:
	var dot = ColorRect.new()
	dot.color = Color(1, 0, 0, 1)
	dot.size = Vector2(8, 8)
	dot.position = Vector2(-4, -4)   # 居中
	dot.z_index = 999
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.name = "PivotDot"
	add_child(dot)
	if not show_pivot:
		dot.visible = false


func _create_ring_drawer() -> void:
	ring_drawer = Node2D.new()
	ring_drawer.set_script(preload("res://scripts/RingDrawer.gd"))
	ring_drawer.name = "RingDrawer"
	ring_drawer.z_index = 500
	add_child(ring_drawer)


func _build_cannons() -> void:
	var offsets = [cannon_0_pos, cannon_1_pos, cannon_2_pos, cannon_3_pos]
	cannon_targets = [] as Array[Vector2]
	cannon_targets.assign(offsets)
	for i in CANNON_COUNT:
		var c = Area2D.new()
		c.set_script(preload("res://scripts/ParadiseCannon.gd"))
		c.name = "Cannon%d" % (i + 1)
		var s = Sprite2D.new()
		s.texture = cannon_tex
		s.scale = cannon_scale
		s.centered = true
		c.add_child(s)
		var col = CollisionShape2D.new()
		col.shape = CircleShape2D.new()
		col.shape.radius = 40
		c.add_child(col)
		c.position = offsets[i] + Vector2(0, -200)   # 初始上移200
		c.z_index = 45
		add_child(c)
		cannons.append(c)
	_create_lasers()


func _make_tween() -> Tween:
	if dying:
		var tw = create_tween()
		tw.kill()
		return tw
	var tw = get_tree().create_tween()
	_skill_tweens.append(tw)
	return tw


func _create_lasers() -> void:
	for i in CANNON_COUNT:
		var l = Line2D.new()
		l.width = 3.0
		l.default_color = Color(1, 0.1, 0.1, 0.5)
		l.z_index = -10                   # 低于玩家和炮塔
		l.visible = false
		l.name = "Laser%d" % (i + 1)
		add_child(l)
		lasers.append(l)


func _start_entrance() -> void:
	entering = true
	entrance_timer = 0.0
	_start_bgm()                         # 天堂号 BGM 提前播放
	# 机身初始在屏幕外
	match dock:
		Dock.TOP:
			position.y = -300
		Dock.LEFT:
			position.x = -300
		Dock.RIGHT:
			position.x = screen_size.x + 300


func _process(delta: float) -> void:
	if dying:
		_death_process(delta)
		return
	if entering:
		_entrance_process(delta)
		return
	if not active:
		return
	# 激光始终追踪（即使技能执行中）
	if lasers_stable:
		for l in lasers:
			_update_laser_line(l)
	if is_executing:
		return
	# 待机摆动
	sway_phase += delta * sway_speed * 0.5
	sway_phase_2 += delta * sway_speed * (1.0 / 3.0)
	var sway_x = sin(sway_phase) * sway_amplitude
	var sway_y = sin(sway_phase_2) * sway_amplitude * 0.25
	position = dock_pos + pivot_offset + world_offset + transform.x * sway_x + transform.y * sway_y
	# 机炮射击冷却
	for i in cannons.size():
		cannon_cooldowns[i] -= delta
		if cannon_cooldowns[i] <= 0.0:
			_fire_cannon(i)
			cannon_cooldowns[i] = CANNON_BASE_CD - randf_range(0.0, CANNON_RANDOM_CD)
	# 技能冷却 + 随机选择（从已启用的技能池中抽选）
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
		if not available.is_empty():
			var s: int
			var enemy_count = get_tree().get_nodes_in_group("enemies").size()
			if enemy_count > 8:
				var pool_no_3: Array[int] = []
				for a in available:
					if a != 3:
						pool_no_3.append(a)
				s = pool_no_3[randi() % pool_no_3.size()]
			elif has_skill_3 and _last_skill != 3 and enemy_count <= 3:
				s = 3
			else:
				s = available[randi() % available.size()]
			match s:
				1: await _skill_1()
				2: await _skill_2()
				3: await _skill_3()
				4: await _skill_4()
				5: await _skill_5()
				6: await _skill_6()
			_last_skill = s
		cooldown_remaining = skill_cooldown
		is_executing = false


func _fire_cannon(idx: int) -> void:
	if dying:
		return
	if idx >= cannons.size():
		return
	var cannon = cannons[idx]
	if not is_instance_valid(cannon):
		return
	var bullet = EnemyBulletScene.instantiate()
	bullet.position = cannon.global_position
	bullet.direction = Vector2.RIGHT.rotated(cannon.global_rotation)
	bullet.damage = cannon_bullet_dmg
	bullet.speed = 500
	bullet.z_index = -80
	bullet.scale = Vector2(1.84 * 2, 1.84 * 2)
	bullet.rotation = bullet.direction.angle()
	get_tree().current_scene.add_child(bullet)


func _skill_1() -> void:
	if dying:
		is_executing = false
		return
	is_executing = true

	# 阶段1：炮塔 y+30 (0.3s)
	_play_sfx(CANNON_MOVE_SFX, -8)
	var tw = _make_tween()
	tw.set_parallel(true)
	for i in cannons.size():
		var target = cannon_targets[i] + Vector2(0, 30)
		tw.tween_property(cannons[i], "position", target, 0.3)
	await tw.finished

	# 阶段2：射线变粗2倍 + 透明度30%，闪烁两下 (0.3s)
	var hold_time = randf_range(5.0, 10.0)
	var flash_end = Time.get_ticks_msec() / 1000.0 + 0.3
	while Time.get_ticks_msec() / 1000.0 < flash_end:
		var f = fmod(Time.get_ticks_msec() / 1000.0, 0.15) < 0.075
		for l in lasers:
			l.width = 6.0
			l.default_color = Color(1, 0.1, 0.1, 0.3)
			l.visible = f
		await get_tree().process_frame
	for l in lasers:
		l.visible = true

	# 阶段3：维持 + 炮塔1/20冷却射击 + 30°偏移 + y+30 + 缩小子弹
	var temp_cd: Array[float] = []
	for _i in cannons.size():
		temp_cd.append(0.0)
	var hold_elapsed = 0.0
	while hold_elapsed < hold_time:
		if dying: break
		var dt = get_process_delta_time()
		hold_elapsed += dt
		for i in cannons.size():
			temp_cd[i] -= dt
			if temp_cd[i] <= 0.0:
				var cannon = cannons[i]
				var bullet = EnemyBulletScene.instantiate()
				bullet.position = cannon.global_position + Vector2(0, 30)
				var base_angle = cannon.global_rotation
				var spread = deg_to_rad(randf_range(-30.0, 30.0))
				bullet.direction = Vector2.RIGHT.rotated(base_angle + spread)
				bullet.damage = skill_1_bullet_dmg
				bullet.speed = 500
				bullet.z_index = -80
				bullet.scale = Vector2(1.84, 1.84)
				bullet.rotation = bullet.direction.angle()
				get_tree().current_scene.add_child(bullet)
				temp_cd[i] = (CANNON_BASE_CD - randf_range(0.0, CANNON_RANDOM_CD)) / 20.0
		await get_tree().process_frame

	# 阶段4：射线回归原状 (0.3s)
	for l in lasers:
		l.width = 3.0
		l.default_color = Color(1, 0.1, 0.1, 0.5)
	await get_tree().create_timer(0.3).timeout

	# 阶段5：炮塔回归原位 (0.3s)
	tw = _make_tween()
	tw.set_parallel(true)
	for i in cannons.size():
		tw.tween_property(cannons[i], "position", cannon_targets[i], 0.3)
	await tw.finished

	is_executing = false


func _skill_2() -> void:
	if dying:
		is_executing = false
		return
	is_executing = true

	# 随机选一个炮塔
	var idx = randi() % cannons.size()
	var cannon = cannons[idx]
	var laser = lasers[idx] if idx < lasers.size() else null
	var origin = cannon.position
	var start_rot = cannon.rotation

	# 关闭该炮塔的射线并暂停追踪
	if laser: laser.visible = false
	cannon.tracking = false

	# 显示飞行路径警戒框
	var target_y = screen_size.y - 60
	_show_warn(cannon.position, Vector2(cannon.position.x, target_y))
	await _await_warns()

	# 飞出：先快后慢到底部，持续旋转 + 每0.3s射击
	var distance = abs(target_y - cannon.position.y)
	var flight_time = maxf(distance / 600.0, 1.0)
	var rot_speed = randf_range(360.0, 480.0)    # 度/秒
	var total_rot = rot_speed * flight_time
	var tw = _make_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(cannon, "position:y", target_y, flight_time)
	tw.tween_property(cannon, "rotation", start_rot + deg_to_rad(total_rot), flight_time)
	var fire_cd = 0.0
	while tw.is_running():
		if dying: break
		fire_cd -= get_process_delta_time()
		if fire_cd <= 0.0:
			_spawn_skill2_bullet(cannon, skill_2_bullet_dmg)
			fire_cd = 0.05
		await get_tree().process_frame
	# 兜底一发
	_spawn_skill2_bullet(cannon, skill_2_bullet_dmg)

	# 飞回原位，继续同向旋转 + 射击
	tw = _make_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_property(cannon, "position", origin, flight_time)
	var current_rot = cannon.rotation
	tw.tween_property(cannon, "rotation", current_rot + deg_to_rad(rot_speed * flight_time), flight_time)
	fire_cd = 0.0
	while tw.is_running():
		if dying: break
		fire_cd -= get_process_delta_time()
		if fire_cd <= 0.0:
			_spawn_skill2_bullet(cannon, skill_2_bullet_dmg)
			fire_cd = 0.05
		await get_tree().process_frame
	cannon.tracking = true                 # 恢复追踪

	# 射线闪烁重启
	if laser:
		var flash_end = Time.get_ticks_msec() / 1000.0 + 0.3
		while Time.get_ticks_msec() / 1000.0 < flash_end:
			laser.visible = fmod(Time.get_ticks_msec() / 1000.0, 0.1) < 0.05
			await get_tree().process_frame
		laser.visible = true

	is_executing = false


func _skill_5() -> void:
	if dying:
		is_executing = false
		return
	is_executing = true
	var count = 2 if randf() < 0.5 else 3
	var indices: Array[int] = []
	while indices.size() < count:
		var idx = randi() % cannons.size()
		if not indices.has(idx):
			indices.append(idx)

	# 阶段1：所有炮塔同时显示警戒框
	for idx in indices:
		var c = cannons[idx]
		var target_y = screen_size.y - 60
		_show_warn(c.position, Vector2(c.position.x, target_y))
	await _await_warns()

	# 阶段2：所有炮塔同时飞出
	await _skill5_fly_parallel(indices)

	is_executing = false


func _skill5_fly_parallel(indices: Array[int]) -> void:
	# 关闭射线
	for idx in indices:
		if idx < lasers.size(): lasers[idx].visible = false
		cannons[idx].tracking = false

	# 飞出
	var flight_data: Array = []
	for idx in indices:
		var cannon = cannons[idx]
		var origin = cannon.position
		var start_rot = cannon.rotation
		var target_y = screen_size.y - 60
		var distance = abs(target_y - cannon.position.y)
		var flight_time = maxf(distance / 600.0, 1.0)
		var rot_speed = randf_range(360.0, 480.0)
		var total_rot = rot_speed * flight_time
		var tw = _make_tween()
		tw.set_parallel(true)
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(cannon, "position:y", target_y, flight_time)
		tw.tween_property(cannon, "rotation", start_rot + deg_to_rad(total_rot), flight_time)
		flight_data.append({
			"idx": idx, "cannon": cannon, "origin": origin, "start_rot": start_rot,
			"rot_speed": rot_speed, "flight_time": flight_time, "tw": tw,
			"fire_cd": 0.0, "phase": "out",
		})

	var all_done = false
	while not all_done:
		if dying: break
		all_done = true
		for fd in flight_data:
			if fd.tw.is_running():
				all_done = false
				fd.fire_cd -= get_process_delta_time()
				if fd.fire_cd <= 0.0:
					_spawn_skill2_bullet(fd.cannon, skill_5_bullet_dmg)
					fd.fire_cd = 0.05
		await get_tree().process_frame
	for fd in flight_data:
		_spawn_skill2_bullet(fd.cannon, skill_5_bullet_dmg)

	# 飞回
	for fd in flight_data:
		var cannon = fd.cannon
		var origin = fd.origin
		var flight_time = fd.flight_time
		var rot_speed = fd.rot_speed
		var tw2 = _make_tween()
		tw2.set_parallel(true)
		tw2.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tw2.tween_property(cannon, "position", origin, flight_time)
		var cr = cannon.rotation
		tw2.tween_property(cannon, "rotation", cr + deg_to_rad(rot_speed * flight_time), flight_time)
		fd.tw = tw2
		fd.fire_cd = 0.0
		fd.phase = "back"

	all_done = false
	while not all_done:
		if dying: break
		all_done = true
		for fd in flight_data:
			if fd.tw.is_running():
				all_done = false
				fd.fire_cd -= get_process_delta_time()
				if fd.fire_cd <= 0.0:
					_spawn_skill2_bullet(fd.cannon, skill_5_bullet_dmg)
					fd.fire_cd = 0.05
		await get_tree().process_frame

	# 恢复
	for idx in indices:
		cannons[idx].tracking = true
		var laser = lasers[idx] if idx < lasers.size() else null
		if laser:
			var flash_end = Time.get_ticks_msec() / 1000.0 + 0.3
			while Time.get_ticks_msec() / 1000.0 < flash_end:
				laser.visible = fmod(Time.get_ticks_msec() / 1000.0, 0.1) < 0.05
				await get_tree().process_frame
			laser.visible = true


func _skill_6() -> void:
	if dying:
		is_executing = false
		return
	is_executing = true

	# 随机一个炮塔
	var idx = randi() % cannons.size()
	var cannon = cannons[idx]
	var laser = lasers[idx] if idx < lasers.size() else null
	var origin = cannon.position
	var orig_scale = cannon.get_child(0).scale if cannon.get_child_count() > 0 else Vector2.ONE

	# 关闭射线、追踪和碰撞（防止蓄力时触碰炮塔本体受击）
	if laser: laser.visible = false
	cannon.tracking = false
	var saved_layer = cannon.collision_layer
	var saved_mask = cannon.collision_mask
	cannon.collision_layer = 0
	cannon.collision_mask = 0
	cannon.monitoring = false

	# 飞到屏幕中央（先快后慢，用全局坐标避开旋转轴影响）
	var cannon_global = cannon.global_position
	var center_global: Vector2
	match dock:
		Dock.TOP:    center_global = Vector2(cannon_global.x, screen_size.y * 0.5)
		Dock.LEFT:   center_global = Vector2(screen_size.x * 0.5, cannon_global.y)
		Dock.RIGHT:  center_global = Vector2(screen_size.x * 0.5, cannon_global.y)
	var center_pos = to_local(center_global)
	var tw = _make_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(cannon, "position", center_pos, 1.2)
	await tw.finished

	# 其他炮塔进入技能1模式：y+30 + 激光加粗 + 20x射速 + 30°扩散
	var other_cannons: Array = []
	var other_origins: Array = []
	var other_cds: Array[float] = []
	for i in cannons.size():
		if i != idx:
			other_cannons.append(cannons[i])
			other_origins.append(cannons[i].position)
			other_cds.append(0.0)
	var tw2 = _make_tween()
	tw2.set_parallel(true)
	for c in other_cannons:
		tw2.tween_property(c, "position:y", c.position.y + 30, 0.3)
	for i in lasers.size():
		if i != idx:
			lasers[i].width = 6.0
			lasers[i].default_color = Color(1, 0.1, 0.1, 0.3)
	await tw2.finished

	# 蓄力5s：红/白渐变闪烁加速 + 变大(max 110%) + 圆形警戒框(400范围)
	warn_circle = {"pos": cannon.position, "timer": 5.0, "radius": 400.0}
	var sprite = cannon.get_child(0) if cannon.get_child_count() > 0 else null
	var charge_timer = 5.0
	var charge_elapsed = 0.0
	while charge_timer > 0.0:
		if dying: break
		var dt = get_process_delta_time()
		charge_timer -= dt
		charge_elapsed += dt
		warn_circle.pos = cannon.position
		warn_circle.timer = charge_timer
		var progress = 1.0 - charge_timer / 5.0
		if sprite:
			sprite.scale = orig_scale * (1.0 + progress * 0.1)
			var flicker_speed = lerpf(4.0, 10.0, progress * progress)
			var flicker = (sin(charge_elapsed * flicker_speed * TAU) + 1.0) * 0.5
			sprite.modulate = Color(1, lerpf(1.0, 0.15, flicker), lerpf(1.0, 0.15, flicker), 1)
		# 其他炮塔技能1模式射击
		for j in other_cannons.size():
			other_cds[j] -= dt
			if other_cds[j] <= 0.0:
				var oc = other_cannons[j]
				var bullet = EnemyBulletScene.instantiate()
				bullet.position = oc.global_position + Vector2(0, 30)
				var base_angle = oc.global_rotation
				var spread = deg_to_rad(randf_range(-30.0, 30.0))
				bullet.direction = Vector2.RIGHT.rotated(base_angle + spread)
				bullet.damage = skill_1_bullet_dmg
				bullet.speed = 500
				bullet.z_index = -80
				bullet.scale = Vector2(1.84, 1.84)
				bullet.rotation = bullet.direction.angle()
				get_tree().current_scene.add_child(bullet)
				other_cds[j] = (CANNON_BASE_CD - randf_range(0.0, CANNON_RANDOM_CD)) / 20.0
		queue_redraw()
		await get_tree().process_frame
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)
	warn_circle.clear()

	# 其他炮塔恢复：激光 + 位置归位
	for j in other_cannons.size():
		var tw_r = _make_tween()
		tw_r.tween_property(other_cannons[j], "position", other_origins[j], 0.3)
	for i in lasers.size():
		if i != idx:
			lasers[i].width = 3.0
			lasers[i].default_color = Color(1, 0.1, 0.1, 0.5)

	# 爆炸：子弹 + 特效 + 伤害，360° 全方位散射
	var bullet_count = randi_range(12, 15)
	var angle_step = TAU / bullet_count
	for i in bullet_count:
		var dir = Vector2.RIGHT.rotated(angle_step * i)
		var bullet = EnemyBulletScene.instantiate()
		bullet.position = cannon.global_position
		bullet.direction = dir
		bullet.damage = skill_6_bullet_dmg
		bullet.speed = 500
		bullet.z_index = -80
		bullet.scale = Vector2(1.84, 1.84)
		bullet.rotation = dir.angle()
		get_tree().current_scene.add_child(bullet)
	_spawn_skill6_explosion(cannon.global_position)
	var player = get_tree().get_first_node_in_group(&"player")
	if player and player.global_position.distance_to(cannon.global_position) < 400:
		if player.has_method(&"take_damage_from_boss"):
			player.take_damage_from_boss(
				skill_6_explosion_dmg)

	# 重置炮塔外观
	if sprite:
		sprite.scale = orig_scale
		sprite.modulate = Color(1, 1, 1, 1)

	# 瞬移到天堂号后方（屏幕外，用全局坐标避开旋转轴影响）
	var origin_global = to_global(origin)
	var behind_global: Vector2
	match dock:
		Dock.TOP:    behind_global = Vector2(origin_global.x, -200)
		Dock.LEFT:   behind_global = Vector2(-200, origin_global.y)
		Dock.RIGHT:  behind_global = Vector2(screen_size.x + 200, origin_global.y)
	cannon.position = to_local(behind_global)

	# 2s 滑回原位
	tw = _make_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(cannon, "position", origin, 2.0)
	await tw.finished

	cannon.tracking = true
	cannon.monitoring = true
	cannon.collision_layer = saved_layer
	cannon.collision_mask = saved_mask
	if laser:
		var flash_end = Time.get_ticks_msec() / 1000.0 + 0.3
		while Time.get_ticks_msec() / 1000.0 < flash_end:
			laser.visible = fmod(Time.get_ticks_msec() / 1000.0, 0.1) < 0.05
			await get_tree().process_frame
		laser.visible = true

	is_executing = false


func _spawn_skill6_explosion(pos: Vector2) -> void:
	# 爆炸特效
	var exp = Sprite2D.new()
	exp.set_script(ExplosionScript)
	exp.texture = EXPLOSION_TEX
	exp.position = pos
	exp.rotation = randf_range(0, TAU)
	exp.scale = Vector2(1.5, 1.5)
	exp.z_index = 1000
	get_tree().current_scene.add_child(exp)
	# 碎片（与敌机死亡相同）
	const QUAD = 512
	for _i in randi_range(8, 12):
		var d = Sprite2D.new()
		d.set_script(DebrisScript)
		d.texture = DEBRIS_TEX
		d.position = pos
		d.scale = Vector2(randf_range(0.05, 0.12), randf_range(0.05, 0.12))
		d.rotation = randf_range(0, TAU)
		d.region_enabled = true
		d.region_rect = Rect2(randi_range(0, 1) * QUAD, randi_range(0, 1) * QUAD, QUAD, QUAD)
		var a = randf_range(0, TAU)
		d.velocity = Vector2(cos(a), sin(a)) * randf_range(80, 280)
		d.rotation_speed = randf_range(-10, 10)
		d.z_index = 200
		get_tree().current_scene.add_child(d)
	# 音效
	_play_sfx(EXPLOSION_SFX, -5)


func _skill_4() -> void:
	if dying:
		is_executing = false
		return
	is_executing = true

	# 阶段1：所有炮塔 y+30 + 音效
	_play_sfx(CANNON_MOVE_SFX, -8)
	var tw = _make_tween()
	tw.set_parallel(true)
	for i in cannons.size():
		var target = cannon_targets[i] + Vector2(0, 30)
		tw.tween_property(cannons[i], "position", target, 0.3)
	await tw.finished

	# 阶段2：停止追踪，锁定初始角度 -90°
	for c in cannons:
		if is_instance_valid(c):
			c.tracking = false
	tw = _make_tween()
	tw.set_parallel(true)
	for c in cannons:
		if is_instance_valid(c):
			tw.tween_property(c, "rotation", deg_to_rad(135.0), 0.3)
	await tw.finished

	# 阶段3：激光变粗3倍
	for l in lasers:
		l.width = 9.0
		l.default_color = Color(1, 0.2, 0.1, 0.8)
	await get_tree().create_timer(0.3).timeout

	# 阶段4：逆时针旋转90°（10s）+ 激光紊乱
	var base_w = 9.0
	tw = _make_tween()
	tw.set_parallel(true)
	for c in cannons:
		if is_instance_valid(c):
			tw.tween_property(c, "rotation", deg_to_rad(45.0), 10.0)
	var flicker_cd = 0.0
	var flickering = false
	var hit_cd = 0.0
	while tw.is_running():
		if dying: break
		var dt = get_process_delta_time()
		hit_cd -= dt
		if flickering:
			flicker_cd -= dt
			if flicker_cd <= 0.0:
				for l in lasers: l.width = base_w
				flickering = false
		else:
			flicker_cd -= dt
			if flicker_cd <= 0.0:
				for l in lasers: l.width = base_w * 1.3
				flicker_cd = 0.1
				flickering = true
				_play_sfx(LASER_ZAP_SFX, -20)
		# 加粗期间检测玩家触碰
		if flickering and hit_cd <= 0.0:
			if _check_laser_hit():
				_apply_laser_damage()
				hit_cd = 0.3
		await get_tree().process_frame
	for l in lasers: l.width = base_w

	# 阶段5：激光闪烁两下后关闭
	var flash_end = Time.get_ticks_msec() / 1000.0 + 0.4
	while Time.get_ticks_msec() / 1000.0 < flash_end:
		var f = fmod(Time.get_ticks_msec() / 1000.0, 0.2) < 0.1
		for l in lasers:
			l.visible = f
		await get_tree().process_frame
	for l in lasers:
		l.visible = false

	# 阶段6：炮塔归位
	tw = _make_tween()
	tw.set_parallel(true)
	for i in cannons.size():
		tw.tween_property(cannons[i], "position", cannon_targets[i], 0.3)
	await tw.finished

	# 阶段7：恢复追踪，激光闪烁重启
	for c in cannons:
		if is_instance_valid(c):
			c.tracking = true
	for l in lasers:
		l.width = 3.0
		l.default_color = Color(1, 0.1, 0.1, 0.5)
	flash_end = Time.get_ticks_msec() / 1000.0 + 0.3
	while Time.get_ticks_msec() / 1000.0 < flash_end:
		var f = fmod(Time.get_ticks_msec() / 1000.0, 0.1) < 0.05
		for l in lasers:
			l.visible = f
		await get_tree().process_frame
	for l in lasers:
		l.visible = true

	is_executing = false


func _spawn_skill3_enemies(avoid_dock: int) -> void:
	var enemy_scenes = [
		"res://scenes/EnemyShooter.tscn",
		"res://scenes/EnemyScatter.tscn",
		"res://scenes/EnemyChain.tscn",
		"res://scenes/EnemyHealer.tscn",
	]
	# 新Boss不在的两个方向
	var dirs: Array[int] = []
	for d in [Dock.TOP, Dock.LEFT, Dock.RIGHT]:
		if d != dock:
			dirs.append(d)
	var count = randi_range(3, 6)
	for _i in count:
		var scene_path = enemy_scenes[randi() % enemy_scenes.size()]
		var enemy = load(scene_path).instantiate()
		var dir = dirs[randi() % dirs.size()]
		match dir:
			Dock.TOP:
				enemy.position = Vector2(randf_range(40, screen_size.x - 40), -60)
			Dock.LEFT:
				enemy.position = Vector2(-60, randf_range(80, screen_size.y * 0.6))
			Dock.RIGHT:
				enemy.position = Vector2(screen_size.x + 60, randf_range(80, screen_size.y * 0.6))
		get_tree().current_scene.add_child(enemy)


func _check_laser_hit() -> bool:
	var player = get_tree().get_first_node_in_group(&"player")
	if not player:
		return false
	for l in lasers:
		if not l.visible or l.points.size() < 2:
			continue
		var p0 = l.to_global(l.points[0])
		var p1 = l.to_global(l.points[1])
		var d = _point_to_segment_dist(player.global_position, p0, p1)
		if d < 20.0:
			return true
	return false


func _point_to_segment_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ap = p - a
	var t = clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
	return (a + ab * t).distance_to(p)


func _apply_laser_damage() -> void:
	var player = get_tree().get_first_node_in_group(&"player")
	if player and player.has_method(&"take_damage_from_boss"):
		player.take_damage_from_boss(skill_4_laser_dmg)


func _spawn_skill2_bullet(cannon: Area2D, dmg: int) -> void:
	if dying:
		return
	var bullet = EnemyBulletScene.instantiate()
	bullet.position = cannon.global_position + Vector2(0, 30)
	bullet.direction = Vector2.RIGHT.rotated(cannon.rotation)
	bullet.damage = dmg
	bullet.speed = 500
	bullet.z_index = -80
	bullet.scale = Vector2(1.84, 1.84)
	bullet.rotation = bullet.direction.angle()
	get_tree().current_scene.add_child(bullet)


func _skill_3() -> void:
	if dying:
		is_executing = false
		return
	is_executing = true
	for c in cannons:
		if is_instance_valid(c): c.tracking = true

	# 阶段1：机头放出3个扩散白环（2s）
	var nose_local = body_offset + Vector2(0, 200 * abs(body_scale.y) + 250)
	ring_drawer.rings.clear()
	var stagger = 0.6
	var ring_dur = 1.2
	for i in 3:
		ring_drawer.rings.append({
			"elapsed": -i * stagger,
			"start_delay": i * stagger,
			"duration": ring_dur,
			"max_r": 150.0 + i * 60,
			"pos": nose_local,
		})
	var phase_timer = 0.0
	var ring_end = (3 - 1) * stagger + ring_dur   # 环结束 ~1.8s
	while phase_timer < ring_end:
		var dt = get_process_delta_time()
		phase_timer += dt
		for r in ring_drawer.rings:
			if phase_timer >= r.start_delay:
				r.elapsed += dt
		ring_drawer.queue_redraw()
		await get_tree().process_frame
	ring_drawer.rings.clear()
	ring_drawer.queue_redraw()
	# 待机至 3s
	await get_tree().create_timer(3.0 - ring_end).timeout

	# 阶段2：关闭射线 → 飞出 → 换位 → 滑入 → 射线闪烁重启
	for l in lasers:
		l.visible = false

	var exit_target: Vector2
	match dock:
		Dock.TOP:    exit_target = Vector2(position.x, -400)
		Dock.LEFT:   exit_target = Vector2(-400, position.y)
		Dock.RIGHT:  exit_target = Vector2(screen_size.x + 400, position.y)
	var tw = _make_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position", exit_target, 1.2)
	await tw.finished

	var old_dock = dock
	while dock == old_dock:
		dock = randi() % 3
	_setup_dock()
	for i in cannons.size():
		cannons[i].position = cannon_targets[i]
	match dock:
		Dock.TOP:    position.y = -400
		Dock.LEFT:   position.x = -400
		Dock.RIGHT:  position.x = screen_size.x + 400

	# 从另外两个方向生成敌机
	_spawn_skill3_enemies(old_dock)

	tw = _make_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", dock_pos + pivot_offset + world_offset, 2.4)
	await tw.finished
	position = dock_pos + pivot_offset + world_offset
	sway_phase = 0.0
	sway_phase_2 = 0.0

	# 射线闪烁重启
	var flash_end = Time.get_ticks_msec() / 1000.0 + 0.3
	while Time.get_ticks_msec() / 1000.0 < flash_end:
		var f = fmod(Time.get_ticks_msec() / 1000.0, 0.1) < 0.05
		for l in lasers:
			l.visible = f
		await get_tree().process_frame
	for l in lasers:
		l.visible = true

	is_executing = false


func _draw() -> void:
	# 条形警戒框
	var full_half_w = 54.0
	for w in warn_list:
		var from = w.from
		var to = w.to
		var dir = (to - from).normalized()
		if dir.length() < 0.01: continue
		var perp = Vector2(-dir.y, dir.x)
		var elapsed = WARN_DURATION - w.timer
		var half_w = full_half_w
		var alpha_mod = 1.0
		if elapsed < 0.5:
			half_w = full_half_w * (elapsed / 0.5)
		elif w.timer < 0.5:
			var t = 1.0 - w.timer / 0.5
			half_w = full_half_w * (1.0 + t)
			alpha_mod = 1.0 - t
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
	# 圆形警戒框
	if not warn_circle.is_empty():
		var elapsed = 5.0 - warn_circle.timer
		var r = warn_circle.radius
		var alpha_mod = 1.0
		if elapsed < 0.5:
			r = warn_circle.radius * (elapsed / 0.5)
		elif warn_circle.timer < 0.5:
			var t = 1.0 - warn_circle.timer / 0.5
			r = warn_circle.radius * (1.0 + t)
			alpha_mod = 1.0 - t
		var flash = fmod(Time.get_ticks_msec() / 1000.0, 0.6) < 0.3
		var col = Color(1, 0.05, 0.05, 0.25 * alpha_mod) if flash else Color(1, 0.8, 0.05, 0.25 * alpha_mod)
		draw_circle(warn_circle.pos, r, col)


func _show_warn(from: Vector2, to: Vector2) -> void:
	warn_list.append({"from": from, "to": to, "timer": WARN_DURATION})


func _await_warns() -> void:
	while not warn_list.is_empty():
		var dt = get_process_delta_time()
		for w in warn_list:
			w.timer -= dt
		warn_list = warn_list.filter(func(w): return w.timer > 0)
		queue_redraw()
		await get_tree().process_frame
	queue_redraw()


func _play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)


func _entrance_process(delta: float) -> void:
	entrance_timer += delta

	# 阶段 0 (0-1s)：机身从 -300 滑入
	if entrance_timer <= 1.0:
		var t = clampf(entrance_timer / 1.0, 0.0, 1.0)
		var e = 1.0 - (1.0 - t) * (1.0 - t)
		match dock:
			Dock.TOP:
				position.y = lerpf(-300.0, dock_pos.y + pivot_offset.y + world_offset.y, e)
			Dock.LEFT:
				position.x = lerpf(-300.0, dock_pos.x + pivot_offset.x + world_offset.x, e)
			Dock.RIGHT:
				position.x = lerpf(screen_size.x + 300.0, dock_pos.x + pivot_offset.x + world_offset.x, e)
		if entrance_timer >= 1.0:
			position = dock_pos + pivot_offset + world_offset

	# 阶段 1 (1-2s)：机炮从 -200 滑入
	elif entrance_timer <= 2.0:
		var t = clampf((entrance_timer - 1.0) / 1.0, 0.0, 1.0)
		var e = 1.0 - (1.0 - t) * (1.0 - t)
		for i in cannons.size():
			var target = cannon_targets[i]
			cannons[i].position.y = lerpf(target.y - 200.0, target.y, e)
		if entrance_timer >= 2.0:
			for i in cannons.size():
				cannons[i].position = cannon_targets[i]

	# 阶段 2 (2-2.5s)：停顿
	elif entrance_timer < 2.5:
		pass

	# 阶段 3 (2.5-2.8s)：激光闪烁射出
	elif entrance_timer < 2.8:
		_activate_lasers()
		var flash = fmod(entrance_timer, 0.1) < 0.05
		for l in lasers:
			l.visible = flash
			_update_laser_line(l)

	# 阶段 4 (2.8-3.3s)：激光稳定
	elif entrance_timer < 3.3:
		for l in lasers:
			l.visible = true
			_update_laser_line(l)
		if not lasers_stable:
			lasers_stable = true
			for l in lasers:
				l.default_color = Color(1, 0.1, 0.1, 0.5)

	# 阶段 5 (3.3-5.3s)：黑幕白字
	elif entrance_timer < 5.3:
		for l in lasers:
			_update_laser_line(l)
		overlay_rect.color = Color(0, 0, 0, 1)
		overlay_label.modulate = Color(1, 1, 1, 1)

	# 阶段 6 (5.3s+)：结束
	else:
		overlay_rect.color = Color(0, 0, 0, 0)
		overlay_label.modulate = Color(1, 1, 1, 0)
		overlay_layer.queue_free()
		entering = false
		active = true
		cooldown_remaining = 0.0       # 立即触发第一次技能
		# 初始化炮塔冷却
		cannon_cooldowns.clear()
		for _i in CANNON_COUNT:
			cannon_cooldowns.append((CANNON_BASE_CD - randf_range(0.0, CANNON_RANDOM_CD)) * 0.5)


func _activate_lasers() -> void:
	for i in lasers.size():
		if not lasers[i].visible:
			lasers[i].visible = true


func _update_laser_line(l: Line2D) -> void:
	var idx = lasers.find(l)
	if idx < 0 or idx >= cannons.size():
		return
	var cannon = cannons[idx]
	if not is_instance_valid(cannon):
		return
	var start = l.to_local(cannon.global_position)
	var world_dir = Vector2.RIGHT.rotated(cannon.global_rotation)
	var extend = Vector2(screen_size.x * 2, screen_size.y * 2).length()
	var world_end = cannon.global_position + world_dir * extend
	l.points = PackedVector2Array([start, l.to_local(world_end)])


func _start_bgm() -> void:
	if GameManager.bgm_player.playing:
		GameManager.bgm_player.stop()
	bgm_player.play.call_deferred()


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


func apply_damage(amount: int) -> void:
	if entering or dying:
		return
	boss_hp -= amount
	if boss_hp <= 0:
		boss_hp = 0
		_die()
	else:
		_play_sfx(HIT_SFX, -5)


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

	# 强制终止所有技能 Tween
	for tw in _skill_tweens:
		if is_instance_valid(tw) and tw.is_valid():
			tw.kill()
	_skill_tweens.clear()

	# 压暗材质
	body_sprite.modulate = Color(0.35, 0.35, 0.4, 1)
	for c in cannons:
		if is_instance_valid(c):
			c.modulate = Color(0.35, 0.35, 0.4, 1)
			c.tracking = false
			c.set_process(false)           # 停止机炮自主旋转
			c.monitoring = false           # 关闭碰撞检测
			c.collision_layer = 0
			c.collision_mask = 0

	# 激光关闭
	for l in lasers:
		l.visible = false


func _death_process(delta: float) -> void:
	death_timer += delta
	death_explosion_cd -= delta
	death_sfx_cd -= delta

	# 每秒 30-45 次爆炸
	if death_explosion_cd <= 0.0:
		_spawn_death_explosion()
		death_explosion_cd = randf_range(1.0 / 45.0, 1.0 / 30.0)
		if death_sfx_cd <= 0.0:
			_play_sfx(EXPLOSION_SFX, -8)
			death_sfx_cd = 0.15

	# 剧烈颤抖
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
	var parts: Array = [body_sprite]
	for c in cannons:
		if is_instance_valid(c):
			parts.append(c)
	for part in parts:
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
		exp.z_index = 1000
		get_tree().current_scene.add_child(exp)
		_spawn_debris(pos, randi_range(3, 6))


func _shake_parts() -> void:
	body_sprite.position = Vector2(
		body_offset.x + randf_range(-25, 25),
		body_offset.y + randf_range(-20, 20)
	)
	for c in cannons:
		if is_instance_valid(c):
			var idx = cannons.find(c)
			if idx >= 0 and idx < cannon_targets.size():
				c.position = cannon_targets[idx] + Vector2(randf_range(-35, 35), randf_range(-25, 25))
	var cam = get_viewport().get_camera_2d()
	if cam:
		cam.offset = Vector2(randf_range(-15, 15), randf_range(-10, 10))


func _spawn_final_explosion() -> void:
	_play_sfx(EXPLOSION_SFX, 0)
	var origins = randi_range(20, 30)
	var bx = position.x
	var by = position.y
	for _i in origins:
		var pos = Vector2(
			randf_range(bx - 300, bx + 300),
			randf_range(by - 250, by + 300)
		)
		var exp = Sprite2D.new()
		exp.set_script(ExplosionScript)
		exp.texture = EXPLOSION_TEX
		exp.position = pos
		exp.rotation = randf_range(0, TAU)
		exp.scale = Vector2(1.2, 1.2)
		exp.z_index = 1000
		get_tree().current_scene.add_child(exp)
		_spawn_debris(pos, randi_range(6, 10))


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
		d.z_index = 1000
		get_tree().current_scene.add_child(d)
