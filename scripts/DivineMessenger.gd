extends Node2D
## 神明使者 —— 水晶/王冠/羽翼 Boss

# ═══════════ 贴图 ═══════════
const CRYSTAL_TEX = preload("res://assets/images/divine_messenger/crystal_cutout.png")
const CROWN_TEX = preload("res://assets/images/divine_messenger/crown_cutout.png")
const WINGS_TEX = preload("res://assets/images/divine_messenger/wings_cutout.png")

# ═══════════ 基本属性 ═══════════
@export var max_hp: int = 1000
@export var boss_name: String = "神明使者"
@export var spawn_y_ratio: float = 0.4
var boss_hp: int
var screen_size: Vector2

# ═══════════ 生命周期标志 ═══════════
var active: bool = false
var entering: bool = true
var dying: bool = false

# ═══════════ 主体外观 ═══════════
var crystal_sprite: Sprite2D
var crown_sprite: Sprite2D
var wings_left: Sprite2D
var wings_right: Sprite2D
var _wings_open: bool = false
var _crown_phase: float = 0.0
var _crystal_pulse: float = 0.0

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


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	boss_hp = max_hp
	_setup_bgm()
	_setup_body()
	_create_entrance_overlay()
	_start_entrance()


func _setup_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = BOSS_BGM
	bgm_player.volume_db = -10
	add_child(bgm_player)


func _setup_body() -> void:
	# 羽翼 — 闭合状态，z_index 最低（被水晶遮挡）
	wings_left = Sprite2D.new()
	wings_left.texture = WINGS_TEX
	wings_left.centered = true
	wings_left.scale = Vector2(0.5, 0.5)
	wings_left.position = Vector2(-40, 20)
	wings_left.z_index = 48
	wings_left.name = "WingsLeft"
	add_child(wings_left)

	wings_right = Sprite2D.new()
	wings_right.texture = WINGS_TEX
	wings_right.centered = true
	wings_right.scale = Vector2(-0.5, 0.5)
	wings_right.position = Vector2(40, 20)
	wings_right.z_index = 48
	wings_right.name = "WingsRight"
	add_child(wings_right)

	# 水晶 — 主体，z_index 中间
	crystal_sprite = Sprite2D.new()
	crystal_sprite.texture = CRYSTAL_TEX
	crystal_sprite.centered = true
	crystal_sprite.scale = Vector2(0.5, 0.5)
	crystal_sprite.z_index = 50
	crystal_sprite.name = "Crystal"
	add_child(crystal_sprite)

	# 王冠 — 水晶上方1/2处，z_index 最高
	crown_sprite = Sprite2D.new()
	crown_sprite.texture = CROWN_TEX
	crown_sprite.centered = true
	crown_sprite.scale = Vector2(0.35, 0.35)
	crown_sprite.position = Vector2(0, -120)
	crown_sprite.z_index = 51
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


func _start_entrance() -> void:
	entering = true
	entrance_timer = 0.0
	position = Vector2(screen_size.x * 0.5, screen_size.y * spawn_y_ratio)
	overlay_rect.color = Color(0, 0, 0, 1)
	overlay_label.modulate = Color(1, 1, 1, 1)


func _start_bgm() -> void:
	if GameManager.bgm_player.playing:
		GameManager.bgm_player.stop()
	bgm_player.play.call_deferred()


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
	if crystal_sprite:
		_crystal_pulse += delta * 2.5
		var s = 0.5 + sin(_crystal_pulse) * 0.02
		crystal_sprite.scale = Vector2(s, s)
	if crown_sprite:
		_crown_phase += delta * 1.2
		crown_sprite.position.y = -120 + sin(_crown_phase) * 8


## ── 进场动画 ──

func _entrance_process(delta: float) -> void:
	entrance_timer += delta
	_idle_animation(delta)

	const E1 = 2.0
	const E2 = 3.0
	const E3 = 5.0

	if entrance_timer <= E1:
		if entrance_timer - delta < 1.0 and entrance_timer >= 1.0:
			_start_bgm()
		var t = clampf(entrance_timer / E1, 0.0, 1.0)
		overlay_rect.color = Color(0, 0, 0, lerpf(1.0, 0.0, t))
		overlay_label.modulate = Color(1, 1, 1, lerpf(1.0, 0.0, t))

	elif entrance_timer <= E2:
		overlay_rect.color = Color(0, 0, 0, 0)
		overlay_label.modulate = Color(1, 1, 1, 0)
		if entrance_timer - delta < E1:
			_play_sfx(ROAR_SFX, -5)

	elif entrance_timer <= E3:
		overlay_rect.color = Color(0, 0, 0, 1)
		overlay_label.modulate = Color(1, 1, 1, 1)

	else:
		overlay_layer.queue_free()
		entering = false
		active = true
		cooldown_remaining = 2.0


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
		crystal_sprite.position = Vector2(randf_range(-15, 15), randf_range(-15, 15))
	if crown_sprite:
		crown_sprite.position = Vector2(randf_range(-15, 15), -120 + randf_range(-15, 15))
	if wings_left:
		wings_left.position = Vector2(-40 + randf_range(-10, 10), 20 + randf_range(-10, 10))
	if wings_right:
		wings_right.position = Vector2(40 + randf_range(-10, 10), 20 + randf_range(-10, 10))


## ── 伤害系统 ──

func _on_body_area_entered(area: Area2D) -> void:
	if entering or dying:
		return
	if area.is_in_group(&"player"):
		return
	if area.get(&"atk") != null:
		apply_damage(area.atk)
		if is_instance_valid(area):
			area.queue_free()


func apply_damage(amount: int) -> void:
	if entering or dying:
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
	_set_wings_open(true)
	await get_tree().create_timer(2.0).timeout
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


## ── 羽翼状态控制 ──

func _set_wings_open(open: bool) -> void:
	_wings_open = open
	if open:
		if wings_left:
			var tw = _make_tween()
			tw.tween_property(wings_left, "position:x", -140, 0.5).set_ease(Tween.EASE_OUT)
			tw.tween_property(wings_left, "rotation", deg_to_rad(-30), 0.5).set_ease(Tween.EASE_OUT)
		if wings_right:
			var tw = _make_tween()
			tw.tween_property(wings_right, "position:x", 140, 0.5).set_ease(Tween.EASE_OUT)
			tw.tween_property(wings_right, "rotation", deg_to_rad(30), 0.5).set_ease(Tween.EASE_OUT)
	else:
		if wings_left:
			var tw = _make_tween()
			tw.tween_property(wings_left, "position", Vector2(-40, 20), 0.5).set_ease(Tween.EASE_OUT)
			tw.tween_property(wings_left, "rotation", 0, 0.5).set_ease(Tween.EASE_OUT)
		if wings_right:
			var tw = _make_tween()
			tw.tween_property(wings_right, "position", Vector2(40, 20), 0.5).set_ease(Tween.EASE_OUT)
			tw.tween_property(wings_right, "rotation", 0, 0.5).set_ease(Tween.EASE_OUT)


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
