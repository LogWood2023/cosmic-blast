extends Area2D
## 敌人基类 —— 路径预览 / HP / 受击 / 生命周期

enum State { WARNING, MOVING, COOLDOWN, LEAVING }

@export var move_speed: float = 300.0
@export var lifetime: float = 30.0
@export var move_cooldown: float = 10.0
@export var hp: int = 10
@export var damage: int = 5
@export var explosion_scale: float = 0.5

const WARNING_DURATION: float = 2.0    # 移动前 2 秒显示路径

var state: State
var max_hp: int                # 初始 HP 上限
var lifetime_remaining: float
var cooldown_remaining: float
var warning_timer: float = 0.0
var path_target: Vector2             # 计划移动的目标
var source_position: Vector2
var move_elapsed: float = 0.0
var move_duration: float = 0.0
var player: Area2D
var screen_size: Vector2

# 颤动
var is_shaking: bool = false
var shake_elapsed: float = 0.0

# 资源
const EXPLOSION_TEX = preload("res://assets/images/fx/explosion.png")
const DEBRIS_TEX = preload("res://assets/images/fx/debris.png")
const EXPLOSION_SFX = preload("res://assets/audio/explosion.wav")
const HIT_SFX = preload("res://assets/audio/enemy_hit.wav")
const ExplosionScript = preload("res://scripts/Explosion.gd")
const DebrisScript = preload("res://scripts/Debris.gd")
const HealthBarScript = preload("res://scripts/HealthBar.gd")

@onready var sprite: Sprite2D = $Sprite2D
var health_bar: Node2D


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	lifetime_remaining = lifetime
	add_to_group(&"enemies")
	player = get_tree().get_first_node_in_group(&"player")

	# 血条
	health_bar = Node2D.new()
	health_bar.set_script(HealthBarScript)
	health_bar.position = Vector2(0, -40)
	add_child(health_bar)
	health_bar.setup(hp)
	max_hp = hp                          # 记录上限

	# 立刻选目标，进入警告状态
	_pick_path_target()
	source_position = position
	warning_timer = WARNING_DURATION
	state = State.WARNING


func _process(delta: float) -> void:
	lifetime_remaining -= delta
	if lifetime_remaining <= 0.0 and state != State.LEAVING:
		_enter_leaving()

	match state:
		State.WARNING:
			_update_warning(delta)
		State.MOVING:
			_update_movement(delta)
		State.COOLDOWN:
			_update_cooldown(delta)
		State.LEAVING:
			_update_leaving(delta)

	if is_shaking:
		_update_shake(delta)

	_apply_suction(delta)

	queue_redraw()


# ═════════════ 路径预览绘制 ═════════

func _draw() -> void:
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
	var perp = Vector2(-dir.y, dir.x)
	var full_half_w = sprite.texture.get_width() * sprite.scale.x * 0.5

	# 警戒框宽度动画：出现0→满(0.5s)，消失满→2倍(0.5s)
	var wm = WARNING_DURATION - warning_timer   # 已过去的时间
	var half_w = full_half_w
	var alpha_mod = 1.0
	if wm < 0.5:
		# 出现阶段
		half_w = full_half_w * (wm / 0.5)
	elif warning_timer < 0.5:
		# 消失阶段：宽度扩2倍，透明度归零
		var t = 1.0 - warning_timer / 0.5
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


## 透明度渐变曲线：0%→100% 在 5% 处，100%→0% 在 95% 处
func _gradient_alpha(t: float) -> float:
	if t <= 0.05:
		return t / 0.05                         # 0 → 1
	elif t >= 0.95:
		return (1.0 - t) / 0.05                 # 1 → 0
	return 1.0


# ═════════════ 子类覆写：选目标 ═════════════

func _pick_path_target() -> void:
	# 默认：随机位置
	path_target = Vector2(
		randf_range(40, screen_size.x - 40),
		randf_range(screen_size.y * 0.1, screen_size.y * 0.7)
	)


# ═════════════ 状态逻辑 ═════════════

func _update_warning(delta: float) -> void:
	warning_timer -= delta
	if warning_timer <= 0.0:
		_begin_move()
		state = State.MOVING


func _update_movement(delta: float) -> void:
	move_elapsed += delta
	var t = clampf(move_elapsed / move_duration, 0.0, 1.0)
	var eased = smoothstep(0.0, 1.0, t)
	position = source_position.lerp(path_target, eased)

	# 朝向目标
	var dir = (path_target - position).normalized()
	if dir.length() > 0.01:
		rotation = lerp_angle(rotation, dir.angle() - PI / 2.0, 5.0 * delta)

	if t >= 1.0:
		position = path_target
		state = State.COOLDOWN
		cooldown_remaining = move_cooldown * randf_range(0.6, 1.4)
		_on_arrive()   # 子类钩子


func _update_cooldown(delta: float) -> void:
	cooldown_remaining -= delta

	# 冷却结束前 5 秒 → 选新目标，进入警告
	if cooldown_remaining <= WARNING_DURATION and state != State.WARNING:
		_pick_path_target()
		source_position = position
		warning_timer = WARNING_DURATION
		state = State.WARNING
		return

	# 转向玩家
	if player:
		var dir = (player.global_position - global_position).normalized()
		if dir.length() > 0.01:
			rotation = lerp_angle(rotation, dir.angle() - PI / 2.0, 5.0 * delta)


func _update_leaving(delta: float) -> void:
	position.y += move_speed * 2.0 * delta
	if _is_offscreen(200.0):
		queue_free()


func _is_offscreen(margin: float = 200.0) -> bool:
	return (position.x < -margin or position.x > screen_size.x + margin
		or position.y < -margin or position.y > screen_size.y + margin)


func _enter_leaving() -> void:
	state = State.LEAVING


func _apply_suction(delta: float) -> void:
	if not GameManager.suction_active:
		return
	var pull = GameManager.suction_center - global_position
	var dist = pull.length()
	if dist < 1.0:
		return
	var strength = clampf(dist * 0.5, 100.0, 600.0)
	position += pull.normalized() * strength * delta


func _begin_move() -> void:
	source_position = position
	move_elapsed = 0.0
	move_duration = source_position.distance_to(path_target) / move_speed


func _on_arrive() -> void:
	pass   # 子类覆写

# ═════════════ 战斗 ═════════════

func take_damage(amount: int) -> void:
	hp -= amount
	health_bar.take_hit(hp)
	if hp <= 0:
		_die()
	else:
		_play_sfx(HIT_SFX)
		is_shaking = true
		shake_elapsed = 0.0


func _die() -> void:
	GameManager.add_score(100)
	_play_sfx(EXPLOSION_SFX)
	if health_bar:
		health_bar.queue_free()
	_spawn_explosion()
	_spawn_debris()
	queue_free()


func _spawn_explosion() -> void:
	var exp = Sprite2D.new()
	exp.set_script(ExplosionScript)
	exp.texture = EXPLOSION_TEX
	exp.position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	exp.rotation = randf_range(0, TAU)
	exp.scale = Vector2(explosion_scale, explosion_scale)
	exp.z_index = 100
	get_tree().current_scene.add_child(exp)


func _spawn_debris() -> void:
	const QUAD = 512
	for _i in randi_range(6, 10):
		var d = Sprite2D.new()
		d.set_script(DebrisScript)
		d.texture = DEBRIS_TEX
		d.position = global_position
		d.scale = Vector2(randf_range(0.05, 0.10), randf_range(0.05, 0.10))
		d.rotation = randf_range(0, TAU)
		d.region_enabled = true
		d.region_rect = Rect2(randi_range(0,1)*QUAD, randi_range(0,1)*QUAD, QUAD, QUAD)
		var a = randf_range(0, TAU)
		d.velocity = Vector2(cos(a), sin(a)) * randf_range(80, 280)
		d.rotation_speed = randf_range(-10, 10)
		d.z_index = -100
		get_tree().current_scene.add_child(d)


func _update_shake(delta: float) -> void:
	shake_elapsed += delta
	if shake_elapsed >= 0.2:
		sprite.position = Vector2.ZERO; is_shaking = false
	else:
		sprite.position.x = sin(shake_elapsed * 50) * 4
		sprite.position.y = cos(shake_elapsed * 47) * 4


func _play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
