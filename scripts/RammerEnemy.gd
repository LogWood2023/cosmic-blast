extends "res://scripts/BaseEnemy.gd"
## 撞击机 —— 路径必经玩家，碰撞造成伤害


func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)


func _pick_path_target() -> void:
	# 目标 = 玩家位置 + 随机延伸（50~200），且不超出屏幕
	if player:
		var dir = (player.global_position - global_position).normalized()
		var extend = randf_range(50.0, 200.0)
		var raw = player.global_position + dir * extend
		path_target = Vector2(
			clamp(raw.x, 20.0, screen_size.x - 20.0),
			clamp(raw.y, 20.0, screen_size.y - 20.0)
		)
	else:
		path_target = Vector2(randf_range(40, screen_size.x - 40), screen_size.y * 0.5)


func _on_area_entered(area: Area2D) -> void:
	# 撞到玩家造成伤害
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		hp = 0
		_die()
