extends "res://scripts/BaseEnemy.gd"
## 连射机 —— 停顿期间向玩家射击，2/3 概率连射

var shoot_timer: float = 0.0
var shoot_interval: float = 2.0
var chain_count: int = 0
const MAX_CHAIN: int = 10


func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)
	shoot_interval = 2.0 * randf_range(0.5, 1.5)


func _update_cooldown(delta: float) -> void:
	super(delta)
	if state == State.COOLDOWN:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			chain_count = 0
			_fire_bullet()
			shoot_timer = shoot_interval * randf_range(0.5, 1.5)


func _fire_bullet() -> void:
	if not player:
		return
	var dir = (player.global_position - global_position).normalized()
	var bullet = preload("res://scenes/EnemyBullet.tscn").instantiate()
	bullet.direction = dir
	bullet.damage = damage
	bullet.position = global_position + dir * 30
	bullet.rotation = dir.angle()
	bullet.speed = 250
	bullet.z_index = -80
	bullet.scale = Vector2(2, 2)
	get_tree().current_scene.add_child(bullet)

	# 2/3 概率连射
	chain_count += 1
	if chain_count < MAX_CHAIN and randf() < 2.0 / 3.0:
		await get_tree().create_timer(0.1).timeout
		_fire_bullet()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		hp = 0
		_die()
