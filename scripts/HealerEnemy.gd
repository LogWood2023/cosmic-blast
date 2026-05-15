extends "res://scripts/BaseEnemy.gd"
## 治愈机 —— 不治同类、不治导弹机

const MISSILE_SCRIPT = preload("res://scripts/MissileEnemy.gd")

var heal_target: Area2D = null
var healing: bool = false
var search_timer: float = 0.0
var heal_timer: float = 0.0


func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)
	sprite.scale *= 1.3                       # 在 tscn 基础上放大


func _process(delta: float) -> void:
	lifetime_remaining -= delta
	if lifetime_remaining <= 0.0:
		_die()
		return

	search_timer -= delta
	if search_timer <= 0.0 or not is_instance_valid(heal_target):
		heal_target = _find_wounded_ally()
		search_timer = 0.5

	if not is_instance_valid(heal_target):
		healing = false
		_do_normal_ai(delta)
		return

	var dist = global_position.distance_to(heal_target.global_position)

	if dist > 80:
		healing = false
		heal_timer = 0.0
		var dir = (heal_target.global_position - global_position).normalized()
		position += dir * move_speed * delta
		rotation = dir.angle() - PI / 2.0
	else:
		healing = true
		var dir = (heal_target.global_position - global_position).normalized()
		if dir.length() > 0:
			rotation = lerp_angle(rotation, dir.angle() - PI / 2.0, 5.0 * delta)

		# 每秒治疗 ATK 点 HP，不超过目标上限
		var tgt_max = heal_target.get("max_hp") as int
		var tgt_hp = heal_target.get("hp") as int
		if tgt_hp < tgt_max:
			heal_timer += delta
			if heal_timer >= 1.0:
				heal_timer -= 1.0
				var amount = min(damage, tgt_max - tgt_hp)
				heal_target.take_damage(-amount)

	if is_shaking:
		_update_shake(delta)

	queue_redraw()


func _do_normal_ai(delta: float) -> void:
	healing = false
	super._process(delta)


func _find_wounded_ally() -> Area2D:
	var best: Area2D = null
	var best_dist = INF
	var enemies = get_tree().get_nodes_in_group(&"enemies")
	for e in enemies:
		if e == self or not is_instance_valid(e):
			continue
		# 不治其他治愈机，不治导弹机
		if e.get_script() == get_script() or e.get_script() == MISSILE_SCRIPT:
			continue
		var e_hp: int = e.get("hp") if e.get("hp") != null else 0
		var e_max: int = e.get("max_hp") if e.get("max_hp") != null else 0
		if e_hp <= 0 or e_hp >= e_max:
			continue
		var dist = global_position.distance_to(e.global_position)
		if dist < best_dist:
			best = e
			best_dist = dist
	return best


func _draw() -> void:
	if not healing or not is_instance_valid(heal_target):
		return
	var from = to_local(global_position)
	var to = to_local(heal_target.global_position)
	var t = Time.get_ticks_msec() / 1000.0
	var g = abs(sin(t * 2.0))
	var c = Color(0.2 + g * 0.6, 0.8 + g * 0.2, 0.1 + g * 0.3, 0.6)
	draw_line(from, to, Color(c.r, c.g, c.b, 0.15), 4)
	draw_line(from, to, Color(c.r, c.g, c.b, 0.3), 2)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		hp = 0
		_die()
