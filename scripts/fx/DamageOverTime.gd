extends Node
## 灼烧 DoT：附着到目标，周期造成伤害，持续到期后自销（天堂号 DoT 弹用）

var target: Node
var damage_per_tick: int = 1
var tick_interval: float = 0.4
var duration: float = 2.5

var _tick_timer: float = 0.0
var _life: float = 0.0


func setup(t: Node, dmg: int, dur: float = 2.5, interval: float = 0.4) -> void:
	target = t
	damage_per_tick = maxi(1, dmg)
	duration = maxf(0.1, dur)
	tick_interval = maxf(0.05, interval)


func _process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		queue_free()
		return
	_life += delta
	if _life >= duration:
		queue_free()
		return
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		if target.has_method("take_damage"):
			target.take_damage(damage_per_tick, self)
