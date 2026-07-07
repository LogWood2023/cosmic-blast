extends Node2D
## 黑洞弹：命中处生成引力奇点，把范围内敌人吸向中心，持续后消散（扭曲星核用）

var pull_strength: float = 640.0
var radius: float = 260.0
var duration: float = 1.2

var _life: float = 0.0


func setup(pos: Vector2, strength: float, r: float, dur: float = 1.2) -> void:
	global_position = pos
	pull_strength = maxf(1.0, strength)
	radius = maxf(1.0, r)
	duration = maxf(0.1, dur)
	z_index = -60


func _process(delta: float) -> void:
	_life += delta
	if _life >= duration:
		queue_free()
		return
	queue_redraw()
	var r2 := radius * radius
	for node in get_tree().get_nodes_in_group(&"enemies"):
		if not is_instance_valid(node) or not node is Node2D or node.is_queued_for_deletion():
			continue
		var to_center: Vector2 = global_position - (node as Node2D).global_position
		var d2 := to_center.length_squared()
		if d2 <= 4.0 or d2 > r2:
			continue
		var d := sqrt(d2)
		var falloff := 1.0 - clampf(d / radius, 0.0, 1.0)
		(node as Node2D).global_position += to_center / d * pull_strength * falloff * delta


func _draw() -> void:
	var a := clampf(1.0 - _life / duration, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius * 0.22, Color(0.55, 0.3, 1.0, 0.35 * a))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0.72, 0.45, 1.0, 0.4 * a), 3.0)
