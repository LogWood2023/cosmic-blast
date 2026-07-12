extends Node

const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")
const HELL_EYE_SCENE := preload("res://scenes/entities/bosses/HellEye.tscn")
const HELL_EYE_DEATH_DURATION: float = 5.0
const EXPLOSION_SCRIPT := preload("res://scripts/fx/Explosion.gd")
const DEBRIS_SCRIPT := preload("res://scripts/fx/Debris.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_progress_ring_edge_tracking()
	if _failed:
		return
	await _check_overlay_and_death_cleanup()
	if _failed:
		return
	print("Hell-eye visual lifecycle check passed.")
	get_tree().quit(0)


func _check_progress_ring_edge_tracking() -> void:
	var world := Node2D.new()
	add_child(world)
	var camera := Camera2D.new()
	world.add_child(camera)
	var viewport_size := get_viewport().get_visible_rect().size
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(viewport_size.x)
	camera.limit_bottom = int(viewport_size.y)
	camera.global_position = Vector2.ZERO
	camera.zoom = Vector2(1.55, 1.55)
	camera.make_current()
	var player := PLAYER_SCENE.instantiate()
	world.add_child(player)
	player.global_position = Vector2(48.0, 52.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var expected: Vector2 = get_viewport().get_canvas_transform() * player.global_position
	var actual: Vector2 = player.call("_world_to_hell_eye_ui_position", player.global_position)
	var legacy: Vector2 = viewport_size * 0.5 + (player.global_position - camera.global_position) * camera.zoom
	if expected.distance_to(legacy) < 24.0:
		_fail("Hell-eye edge tracking test did not exercise camera limit clamping.")
	elif actual.distance_to(expected) > 0.5:
		_fail("Hell-eye progress ring should use the final canvas transform at camera edges.")
	world.queue_free()
	await get_tree().process_frame


func _check_overlay_and_death_cleanup() -> void:
	var boss := HELL_EYE_SCENE.instantiate()
	add_child(boss)
	await get_tree().process_frame
	boss.call("_skill_4_ensure_overlay")
	var overlay := boss.get("_skill_4_overlay") as CanvasLayer
	var overlay_rect := boss.get("_skill_4_overlay_rect") as ColorRect
	boss.set("_skill_4_overlay_state", 3)
	boss.set("_skill_4_overlay_timer", float(boss.get("skill_4_fade_time")))
	boss.call("_update_skill_4_overlay", 0.1)
	if overlay_rect.visible or overlay_rect.material != null or not overlay.is_queued_for_deletion():
		_fail("Hell-eye inversion overlay must stop rendering before deferred deletion.")
		return
	boss.call("_die")
	boss.set("_death_particles_emitted", 9999)
	boss.call("_death_process", HELL_EYE_DEATH_DURATION + 0.1)
	if boss.visible or not bool(boss.get("won")):
		_fail("Hell-eye body should be fully hidden when its death animation completes.")
		return
	if GameManager.controls_inverted:
		_fail("Hell-eye death should always restore normal controls.")
		return
	for effect_node in get_tree().current_scene.get_children():
		if effect_node.get_script() == EXPLOSION_SCRIPT and effect_node.scale.x > 1.36:
			_fail("Hell-eye final explosion should not cover the whole viewport.")
			return
		if effect_node.get_script() == DEBRIS_SCRIPT and effect_node.scale.x > 0.14:
			_fail("Hell-eye debris should remain shard-sized instead of using source-texture scale.")
			return
	boss.queue_free()
	await get_tree().create_timer(2.1).timeout
	await get_tree().process_frame


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
