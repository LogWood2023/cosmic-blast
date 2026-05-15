extends Area2D
## 玩家 —— HP 制，键盘移动 + 鼠标瞄准射击

@export var speed: float = 300.0
@export var rotation_speed: float = 8.0
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.25
@export var atk: int = 10

var screen_size: Vector2
var fire_cooldown: float = 0.0

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

@onready var sprite: Sprite2D = $Sprite2D

const SHOOT_SOUND = preload("res://assets/audio/shoot.wav")
const HURT_SOUND = preload("res://assets/audio/player_hurt.wav")


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	add_to_group(&"player")
	collision_layer = 1
	collision_mask = 2     # 检测 Boss 组件


func _process(delta: float) -> void:
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
		var t = knockback_elapsed / knockback_duration
		var spd = lerp(knockback_speed, 0.0, t)
		position += knockback_dir * spd * delta
		position.x = clamp(position.x, 0, screen_size.x)
		position.y = clamp(position.y, 0, screen_size.y)
		if t >= 1.0:
			is_knocked_back = false
		return    # 击飞期间无法行动

	# ── 移动 ──
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if GameManager.controls_inverted:
		input_dir = -input_dir
	var total_move = input_dir
	if GameManager.suction_active:
		var pull = GameManager.suction_center - global_position
		if pull.length() > 1.0:
			total_move += pull.normalized() * 0.8
	position += total_move * speed * delta
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

	# ── 朝向 ──
	var is_shooting: bool = Input.is_action_pressed("shoot")
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
	if is_shooting and fire_cooldown <= 0.0:
		_shoot()
		fire_cooldown = fire_rate


func _shoot() -> void:
	var bullet = bullet_scene.instantiate()
	var forward = Vector2(0, -1).rotated(rotation)
	bullet.direction = forward
	bullet.atk = atk
	bullet.position = global_position + 50 * forward
	bullet.rotation = rotation - PI / 2.0    # PNG 朝右，-90° 对齐飞行方向
	bullet.z_index = -80            # 子弹层
	get_tree().current_scene.add_child(bullet)
	_play_sfx(SHOOT_SOUND)


# ══════════════════════════════════════════════
#  受击（由敌方调用）
# ══════════════════════════════════════════════

## 被敌方子弹 / 撞击机 / 炸弹 等攻击时调用
func take_damage_from(area: Area2D) -> void:
	if invincible:
		return

	var dmg: int = area.get("damage") if area.get("damage") != null else 0
	if dmg <= 0:
		return

	_play_sfx(HURT_SOUND)
	GameManager.player_hp -= dmg

	if GameManager.player_hp <= 0:
		GameManager.player_hp = 0
		get_tree().change_scene_to_file.call_deferred("res://scenes/gameover.tscn")
		return

	invincible = true
	invincible_timer = INVINCIBLE_DURATION


## Boss 直接伤害（无 Area2D 来源）
func take_damage_from_boss(dmg: int) -> void:
	if invincible:
		return
	_play_sfx(HURT_SOUND)
	GameManager.player_hp -= dmg
	if GameManager.player_hp <= 0:
		GameManager.player_hp = 0
		get_tree().change_scene_to_file.call_deferred("res://scenes/gameover.tscn")
		return
	invincible = true
	invincible_timer = INVINCIBLE_DURATION


## Boss 碰撞击飞
func take_knockback_damage(dmg: int, spd: float, dur: float, dir: Vector2 = Vector2.DOWN) -> void:
	if is_knocked_back:
		return
	_play_sfx(HURT_SOUND)
	GameManager.player_hp -= dmg
	if GameManager.player_hp <= 0:
		GameManager.player_hp = 0
		get_tree().change_scene_to_file.call_deferred("res://scenes/gameover.tscn")
		return
	is_knocked_back = true
	knockback_speed = spd
	knockback_duration = dur
	knockback_elapsed = 0.0
	knockback_dir = dir
	invincible = true
	invincible_timer = 0.7


# ══════════════════════════════════════════════
#  道具（保留）
# ══════════════════════════════════════════════

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
	sfx.stream = stream
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
