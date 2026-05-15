extends Area2D
## 炸弹 —— 可飞行到目标后倒计时爆炸，红色预警圈

@export var explode_delay: float = 1.0
var damage: int = 10
var explosion_radius: float = 150.0

# 飞行参数（抛投机使用）
var travel_target: Vector2 = Vector2.INF    # 若不设则跳过飞行
var flight_duration: float = 0.3

const EXPLODE_SFX = preload("res://assets/audio/bomb_explode.wav")
var timer: float
var exploded: bool = false
var flying: bool = false
const BASE_SCALE: float = 0.0468            # 匹配 1024px PNG → 16px 视觉 ×3

@onready var sprite: Sprite2D = $Sprite2D
@onready var radius_area: CollisionShape2D = $RadiusArea


func _ready() -> void:
	timer = explode_delay
	sprite.scale = Vector2(BASE_SCALE, BASE_SCALE)
	radius_area.shape.radius = 0

	if travel_target != Vector2.INF:
		_fly_to_target()
	else:
		queue_redraw()


func _fly_to_target() -> void:
	flying = true
	timer += flight_duration                  # 飞行时间不计入爆炸延迟
	var tw = get_tree().create_tween()
	tw.tween_property(self, "position", travel_target, flight_duration)
	tw.tween_callback(_start_countdown)


func _start_countdown() -> void:
	flying = false
	queue_redraw()


func _process(delta: float) -> void:
	if exploded or flying:
		return

	timer -= delta
	var progress = 1.0 - timer / explode_delay
	sprite.scale = Vector2(BASE_SCALE + progress * BASE_SCALE * 0.6, BASE_SCALE + progress * BASE_SCALE * 0.6)
	sprite.modulate = Color(1, 1 - progress * 0.7, 0)

	queue_redraw()

	if timer <= 0.0:
		_explode()


func _draw() -> void:
	if exploded or timer <= 0 or flying:
		return
	var alpha = 0.3 + 0.2 * sin(Time.get_ticks_msec() / 1000.0 * 10.0)
	draw_circle(Vector2.ZERO, explosion_radius, Color(1, 0.05, 0.05, alpha), false, 4)
	draw_circle(Vector2.ZERO, explosion_radius, Color(1, 0.3, 0.3, alpha * 0.5), false, 2)


func _explode() -> void:
	exploded = true
	radius_area.shape.radius = explosion_radius
	sprite.scale = Vector2(BASE_SCALE * 3.0, BASE_SCALE * 3.0)
	sprite.modulate = Color(1, 0.5, 0, 0.8)

	_play_explode_sfx()
	var player = get_tree().get_first_node_in_group(&"player")
	if player and player.global_position.distance_to(global_position) <= explosion_radius:
		player.take_damage_from(self)

	_spawn_explosion_vfx()

	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _spawn_explosion_vfx() -> void:
	const TEX = preload("res://assets/images/fx/explosion.png")
	const SCRIPT = preload("res://scripts/Explosion.gd")
	var exp = Sprite2D.new()
	exp.set_script(SCRIPT)
	exp.texture = TEX
	exp.position = global_position
	var s = explosion_radius * 2.0 / 3388.0 * 6.0
	exp.scale = Vector2(s, s)
	exp.z_index = 100
	get_tree().current_scene.add_child(exp)


func _play_explode_sfx() -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.stream = EXPLODE_SFX
	sfx.volume_db = -12
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
