extends Node
## 减速扭曲：作为敌人子节点，抵消目标一部分位移模拟减速（不改敌人代码）
## 每个敌人最多附加一个，重复命中刷新时长

var slow_ratio: float = 0.5
var duration: float = 1.5

var _life: float = 0.0
var _last_pos: Vector2
var _started: bool = false


func setup(ratio: float, dur: float = 1.5) -> void:
	slow_ratio = clampf(ratio, 0.0, 0.85)
	duration = maxf(0.1, dur)


func refresh(dur: float) -> void:
	_life = 0.0
	duration = maxf(duration, dur)


func _process(delta: float) -> void:
	var target := get_parent()
	if not is_instance_valid(target) or not target is Node2D or target.is_queued_for_deletion():
		queue_free()
		return
	_life += delta
	if _life >= duration:
		queue_free()
		return
	var t := target as Node2D
	if not _started:
		_last_pos = t.global_position
		_started = true
		return
	var moved: Vector2 = t.global_position - _last_pos
	t.global_position -= moved * slow_ratio
	_last_pos = t.global_position
