extends "res://scripts/BaseEnemy.gd"
## 射击机 —— 停顿期间向玩家射击

var shoot_timer: float = 0.0
var shoot_interval: float = 1.0


func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)
	shoot_interval = 2.0 * randf_range(0.5, 1.5)   # 基准 2s


func _update_cooldown(delta: float) -> void:
	super(delta)

	# 只在纯冷却状态（非 WARNING）射击
	if state == State.COOLDOWN:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			_shoot_at_player()
			shoot_timer = shoot_interval * randf_range(0.5, 1.5)


func _shoot_at_player() -> void:
	if not player:
		return

	# 朝向限制：飞机必须大致对着玩家才射击（±45°）
	var dir = (player.global_position - global_position).normalized()
	var forward = Vector2(0, 1).rotated(rotation)
	if abs(forward.angle_to(dir)) > PI / 4.0:
		return

	var bullet = preload("res://scenes/EnemyBullet.tscn").instantiate()
	bullet.direction = dir
	bullet.damage = damage
	bullet.position = global_position + dir * 30
	bullet.rotation = dir.angle()
	bullet.speed = 250
	bullet.z_index = -80
	bullet.scale = Vector2(2, 2)           # 2 倍大
	get_tree().current_scene.add_child(bullet)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		hp = 0
		_die()
