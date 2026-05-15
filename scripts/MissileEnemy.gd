extends "res://scripts/BaseEnemy.gd"
## 导弹机 —— 永远追玩家，无警示框，每秒扣 2 HP

var decay_timer: float = 0.0


func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)
	state = State.COOLDOWN          # 跳过 WARNING → 不画矩形


func _process(delta: float) -> void:
	# 每秒扣 2 HP
	decay_timer += delta
	if decay_timer >= 0.5:
		decay_timer -= 0.5
		hp -= 1
		if health_bar:
			health_bar.take_hit(hp)
		if hp <= 0:
			_die()
			return

	if not player:
		queue_free()
		return

	var dir = (player.global_position - global_position).normalized()
	position += dir * move_speed * delta
	rotation = dir.angle() - PI / 2.0

	if is_shaking:
		_update_shake(delta)

	if _is_offscreen(300):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		hp = 0
		_die()
