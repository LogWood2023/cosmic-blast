extends "res://scripts/BaseEnemy.gd"
## 散射机 —— 停顿期间 5 发散弹

var shoot_timer: float = 0.0
var shoot_interval: float = 2.0


func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)
	shoot_interval = 2.0 * randf_range(0.5, 1.5)


func _update_cooldown(delta: float) -> void:
	super(delta)
	if state == State.COOLDOWN:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			_shoot_scatter()
			shoot_timer = shoot_interval * randf_range(0.5, 1.5)


func _shoot_scatter() -> void:
	if not player:
		return
	var base_dir = (player.global_position - global_position).normalized()
	var angles = [0, -30, 30, -60, 60]
	for deg in angles:
		_spawn_bullet(base_dir.rotated(deg_to_rad(deg)))


func _spawn_bullet(dir: Vector2) -> void:
	var bullet = preload("res://scenes/EnemyBullet.tscn").instantiate()
	bullet.direction = dir
	bullet.damage = damage
	bullet.position = global_position + dir * 30
	bullet.rotation = dir.angle()
	bullet.speed = 250
	bullet.z_index = -80
	bullet.scale = Vector2(2, 2)
	get_tree().current_scene.add_child(bullet)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		hp = 0
		_die()
