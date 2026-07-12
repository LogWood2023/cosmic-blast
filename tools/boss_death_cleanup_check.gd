extends Node

const BOSS_CASES: Array[Dictionary] = [
	{"name": "StarColossus", "scene": preload("res://scenes/entities/bosses/StarColossus.tscn")},
	{"name": "Paradise", "scene": preload("res://scenes/entities/bosses/Paradise.tscn")},
	{"name": "WarpedCore", "scene": preload("res://scenes/entities/bosses/WarpedCore.tscn")},
	{"name": "DivineMessenger", "scene": preload("res://scenes/entities/bosses/DivineMessenger.tscn")},
]

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var camera := Camera2D.new()
	camera.position = get_viewport().get_visible_rect().size * 0.5
	add_child(camera)
	camera.make_current()
	for boss_case in BOSS_CASES:
		await _check_boss(String(boss_case["name"]), boss_case["scene"] as PackedScene)
		if _failed:
			return
	await get_tree().create_timer(1.7).timeout
	print("Boss death cleanup check passed.")
	get_tree().quit(0)


func _check_boss(case_name: String, scene: PackedScene) -> void:
	var boss := scene.instantiate()
	add_child(boss)
	await get_tree().process_frame
	boss.call("_die")
	await get_tree().physics_frame
	for area_node in boss.find_children("*", "Area2D", true, false):
		var area := area_node as Area2D
		if area.monitoring or area.monitorable or area.collision_layer != 0 or area.collision_mask != 0:
			_fail("%s should disable every hit area as soon as death starts." % case_name)
			return
	boss.call("_death_process", 10.0)
	if boss.visible or boss.is_processing():
		_fail("%s should hide and stop processing after its final death burst." % case_name)
		return
	if not bool(boss.get("won")):
		_fail("%s should mark the death sequence complete exactly once." % case_name)
		return
	var active_camera := get_viewport().get_camera_2d()
	if active_camera and active_camera.offset != Vector2.ZERO:
		_fail("%s should restore the camera offset after its final death burst." % case_name)
		return
	boss.queue_free()
	await get_tree().process_frame


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
