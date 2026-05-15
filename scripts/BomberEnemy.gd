extends "res://scripts/BaseEnemy.gd"
## 轰炸机 —— 直线穿过玩家飞到屏外，沿途丢炸弹

const BOMB_DROP_SFX = preload("res://assets/audio/bomb_drop.wav")

var bomb_timer: float = 0.0


func _ready() -> void:
	super()
	state = State.COOLDOWN
	sprite.scale *= 1.5                       # 在 tscn 基础上放大


func _pick_path_target() -> void:
	# 从当前位置出发，穿过玩家，到达屏幕外
	if not player:
		path_target = Vector2(randf_range(40, screen_size.x - 40), screen_size.y + 120)
		return

	# 方向：从玩家穿过，继续延伸到屏外
	var dir = (player.global_position - position).normalized()
	path_target = position + dir * 2000.0   # 足够远到屏外


func _update_movement(delta: float) -> void:
	super(delta)
	# 沿途丢炸弹
	bomb_timer -= delta
	if bomb_timer <= 0.0:
		_drop_bomb()
		bomb_timer = 0.1                 # 每 0.1 秒投一枚


func _drop_bomb() -> void:
	_play_sfx(BOMB_DROP_SFX, -10.0)        # 降低音量不刺耳
	var bomb = preload("res://scenes/Bomb.tscn").instantiate()
	bomb.position = global_position
	bomb.damage = damage
	get_tree().current_scene.add_child(bomb)
