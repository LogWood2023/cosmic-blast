extends "res://scripts/BaseEnemy.gd"
## 自爆机 —— 冷却极长不移动，死亡/到期时 16 方向爆弹


func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)


## 到期不飞离——原地自爆
func _enter_leaving() -> void:
	state = State.LEAVING
	_spawn_explosion()
	_spawn_debris()
	queue_free()


func _die() -> void:
	GameManager.add_score(100)
	_play_sfx(preload("res://assets/audio/explosion.wav"))
	_explode_bullets()                    # 被玩家击杀才爆弹
	if health_bar:
		health_bar.queue_free()
	_spawn_explosion()
	_spawn_debris()
	queue_free()


func _explode_bullets() -> void:
	for i in 16:
		var angle = TAU * float(i) / 16.0
		var dir = Vector2(cos(angle), sin(angle))
		var bullet = preload("res://scenes/EnemyBullet.tscn").instantiate()
		bullet.direction = dir
		bullet.damage = damage
		bullet.position = global_position + dir * 10
		bullet.rotation = angle
		bullet.speed = 500
		bullet.z_index = -80
		bullet.scale = Vector2(2, 2)
		get_tree().current_scene.add_child(bullet)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		hp = 0
		_die()
