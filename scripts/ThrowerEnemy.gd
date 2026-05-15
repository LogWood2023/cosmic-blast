extends "res://scripts/BaseEnemy.gd"
## 抛投机 —— 停顿期间向玩家投掷炸弹，飞行后 5s 爆炸

var throw_timer: float = 0.0
var throw_interval: float = 2.0


func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)
	throw_interval = 5.0 * randf_range(0.5, 1.5)


func _update_cooldown(delta: float) -> void:
	super(delta)
	if state == State.COOLDOWN:
		throw_timer -= delta
		if throw_timer <= 0.0:
			_throw_bomb()
			throw_timer = throw_interval * randf_range(0.5, 1.5)


func _throw_bomb() -> void:
	if not player:
		return
	var bomb = preload("res://scenes/Bomb.tscn").instantiate()
	bomb.damage = damage
	bomb.explode_delay = 5.0                       # 5 秒后爆炸
	bomb.explosion_radius = 150.0                  # 与轰炸机一致
	bomb.travel_target = player.global_position    # 飞到玩家位置
	bomb.flight_duration = 0.3
	bomb.position = global_position
	get_tree().current_scene.add_child(bomb)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		hp = 0
		_die()
