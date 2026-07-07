extends Area2D

@export var amount: int = 1
@export var launch_duration: float = 0.22
@export var attract_delay: float = 0.18
@export var attract_speed: float = 860.0
@export var collect_radius: float = 28.0
@export var max_lifetime: float = 7.0
@export var launch_radius_min: float = 30.0
@export var launch_radius_max: float = 92.0
@export var sparkle_color: Color = Color(0.38, 0.96, 1.0, 1.0)
@export var core_color: Color = Color(0.9, 1.0, 1.0, 1.0)
@export var rich_sparkle_color: Color = Color(1.0, 0.86, 0.26, 1.0)
@export var rich_core_color: Color = Color(1.0, 1.0, 0.78, 1.0)
@export var rich_visual_scale: float = 1.24

var rich_mineral: bool = false
var ore_source_id: String = ""
var mineral_label: String = "星髓"
var source_sparkle_color: Color = Color.TRANSPARENT
var source_core_color: Color = Color.TRANSPARENT

var _target: Node2D
var _age: float = 0.0
var _attract_timer: float = 0.0
var _collected: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _start_scale: Vector2 = Vector2.ONE

@onready var core: Polygon2D = $Core
@onready var glow: Polygon2D = $Glow
@onready var amount_label: Label = $AmountLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group(&"mineral_pickups")
	_start_scale = scale
	_attract_timer = attract_delay
	_apply_visuals()
	_launch_pop()


func setup(p_amount: int, target: Node2D, random_launch: bool = true, p_rich_mineral: bool = false, source_profile: Dictionary = {}) -> void:
	amount = maxi(1, p_amount)
	_target = target
	rich_mineral = p_rich_mineral
	set_meta("rich_mineral", rich_mineral)
	_apply_source_profile(source_profile)
	if random_launch:
		_velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(launch_radius_min, launch_radius_max) / maxf(launch_duration, 0.01)
	else:
		_velocity = Vector2.ZERO
	if is_node_ready():
		_apply_visuals()
		_launch_pop()


func _apply_source_profile(source_profile: Dictionary) -> void:
	ore_source_id = String(source_profile.get("id", ore_source_id))
	mineral_label = String(source_profile.get("label", mineral_label)).strip_edges()
	if mineral_label.is_empty():
		mineral_label = "星髓"
	if source_profile.has("sparkle_color"):
		source_sparkle_color = source_profile.get("sparkle_color")
	if source_profile.has("core_color"):
		source_core_color = source_profile.get("core_color")
	if not ore_source_id.is_empty():
		set_meta("ore_source_id", ore_source_id)
	set_meta("mineral_label", mineral_label)


func _process(delta: float) -> void:
	if _collected:
		return
	_age += delta
	if _age >= max_lifetime:
		queue_free()
		return
	if _attract_timer > 0.0:
		_attract_timer -= delta
		global_position += _velocity * delta
		_velocity = _velocity.move_toward(Vector2.ZERO, attract_speed * 0.6 * delta)
		return
	var target := _get_target()
	if target == null:
		global_position += _velocity * delta
		return
	var to_target := target.global_position - global_position
	if to_target.length() <= collect_radius:
		_collect()
		return
	var speed := attract_speed * (1.0 + clampf(float(amount) / 24.0, 0.0, 0.65))
	global_position += to_target.normalized() * minf(speed * delta, to_target.length())


func _get_target() -> Node2D:
	if is_instance_valid(_target):
		return _target
	for node in get_tree().get_nodes_in_group(&"player"):
		if node is Node2D:
			_target = node
			return _target
	return null


## 采矿僚机调用：让附近矿物立即开始吸附（跳过初始延迟）
func trigger_attract() -> void:
	if not _collected:
		_attract_timer = 0.0


func _collect() -> void:
	if _collected:
		return
	_collected = true
	RunManager.record_mineral_collected(amount)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	_spawn_collect_trail()
	_spawn_collect_flash()
	_show_collect_text()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", _start_scale * 1.75, 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(queue_free)


func _show_collect_text() -> void:
	var label := Label.new()
	label.text = "富%s +%d" % [mineral_label, amount] if rich_mineral else "%s +%d" % [mineral_label, amount]
	label.add_to_group(&"mineral_collect_feedback")
	label.modulate = Color(1.0, 0.9, 0.42, 1.0) if rich_mineral else _get_sparkle_color().lightened(0.25)
	label.add_theme_font_size_override("font_size", 24 if rich_mineral else 20)
	label.global_position = global_position + Vector2(-18.0, -42.0)
	get_tree().current_scene.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0.0, -48.0), 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(label.queue_free)


func _spawn_collect_flash() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return
	var flash := Polygon2D.new()
	flash.name = "富%s收集闪光" % mineral_label if rich_mineral else "%s收集闪光" % mineral_label
	flash.add_to_group(&"mineral_collect_feedback")
	flash.global_position = global_position
	flash.z_index = z_index + 1
	flash.color = Color(1.0, 0.83, 0.24, 0.88) if rich_mineral else Color(_get_sparkle_color().r, _get_sparkle_color().g, _get_sparkle_color().b, 0.78)
	flash.polygon = PackedVector2Array([
		Vector2(0.0, -18.0),
		Vector2(5.0, -5.0),
		Vector2(18.0, 0.0),
		Vector2(5.0, 5.0),
		Vector2(0.0, 18.0),
		Vector2(-5.0, 5.0),
		Vector2(-18.0, 0.0),
		Vector2(-5.0, -5.0),
	])
	parent.add_child(flash)
	var tween := flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2.ONE * (2.8 if rich_mineral else 2.2), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(flash.queue_free)


func _spawn_collect_trail() -> void:
	var target := _get_target()
	if target == null:
		return
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return
	var start_position := global_position
	var target_position := target.global_position
	var trail := Line2D.new()
	trail.name = "富%s回收轨迹" % mineral_label if rich_mineral else "%s回收轨迹" % mineral_label
	trail.add_to_group(&"mineral_collect_feedback")
	trail.z_index = z_index + 2
	trail.width = clampf(2.0 + float(amount) * (0.16 if rich_mineral else 0.12), 4.0 if rich_mineral else 3.0, 10.0 if rich_mineral else 8.0)
	trail.default_color = Color(1.0, 0.78, 0.2, 0.95) if rich_mineral else Color(_get_sparkle_color().r, _get_sparkle_color().g, _get_sparkle_color().b, 0.9)
	trail.points = PackedVector2Array([start_position, start_position])
	trail.set_meta("start_position", start_position)
	trail.set_meta("target_position", target_position)
	parent.add_child(trail)
	var spark := Polygon2D.new()
	spark.name = "富%s回收光点" % mineral_label if rich_mineral else "%s回收光点" % mineral_label
	spark.add_to_group(&"mineral_collect_feedback")
	spark.z_index = z_index + 3
	spark.color = Color(1.0, 0.94, 0.56, 1.0) if rich_mineral else _get_core_color()
	spark.polygon = PackedVector2Array([
		Vector2(0.0, -8.0),
		Vector2(8.0, 0.0),
		Vector2(0.0, 8.0),
		Vector2(-8.0, 0.0),
	])
	spark.global_position = start_position
	parent.add_child(spark)
	var tween := trail.create_tween()
	tween.set_parallel(true)
	tween.tween_method(_update_trail_end.bind(trail, start_position, target_position), 0.0, 1.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(spark, "global_position", target_position, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(trail, "modulate:a", 0.0, 0.28).set_delay(0.12)
	tween.tween_property(spark, "modulate:a", 0.0, 0.28).set_delay(0.12)
	tween.chain().tween_callback(trail.queue_free)
	tween.tween_callback(spark.queue_free)


func _update_trail_end(progress: float, trail: Line2D, start_position: Vector2, target_position: Vector2) -> void:
	if not is_instance_valid(trail):
		return
	var end_position := start_position.lerp(target_position, progress)
	var pull_position := start_position.lerp(target_position, clampf(progress - 0.34, 0.0, 1.0))
	trail.points = PackedVector2Array([pull_position, end_position])


func _launch_pop() -> void:
	if not is_inside_tree():
		return
	scale = Vector2.ZERO
	modulate = Color(1.12, 1.04, 0.62, 1.0) if rich_mineral else Color(1.0, 1.0, 1.0, 1.0)
	modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(self, "scale", _start_scale * (rich_visual_scale if rich_mineral else 1.0) * randf_range(0.9, 1.2), launch_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply_visuals() -> void:
	var visual_bonus := rich_visual_scale if rich_mineral else 1.0
	var size := clampf((10.0 + float(amount) * 0.55) * visual_bonus, 12.0, 34.0)
	var points := PackedVector2Array([
		Vector2(0.0, -size),
		Vector2(size * 0.72, -size * 0.18),
		Vector2(size * 0.46, size * 0.82),
		Vector2(-size * 0.46, size * 0.82),
		Vector2(-size * 0.72, -size * 0.18),
	])
	core.polygon = points
	core.color = rich_core_color if rich_mineral else _get_core_color()
	glow.polygon = points
	var glow_source := rich_sparkle_color if rich_mineral else _get_sparkle_color()
	glow.color = Color(glow_source.r, glow_source.g, glow_source.b, 0.4 if rich_mineral else 0.28)
	glow.scale = Vector2.ONE * (2.25 if rich_mineral else 1.8)
	amount_label.text = ("富%d" % amount) if rich_mineral else str(amount)


func _get_sparkle_color() -> Color:
	return source_sparkle_color if source_sparkle_color != Color.TRANSPARENT else sparkle_color


func _get_core_color() -> Color:
	return source_core_color if source_core_color != Color.TRANSPARENT else core_color
