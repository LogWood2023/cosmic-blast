extends Node


const DESIGNED_ENEMY_SCENE := preload("res://scenes/entities/designed_enemies/DesignedEnemy.tscn")
const DesignedEnemyScript := preload("res://scripts/entities/designed_enemies/DesignedEnemy.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var enemy := DESIGNED_ENEMY_SCENE.instantiate()
	enemy.behavior = DesignedEnemyScript.Behavior.COLOSSUS_CORE_DEVOURER
	add_child(enemy)
	await get_tree().process_frame

	enemy.call("_request_core_devourer_gravity_claw_pool_prewarm")
	enemy.call("_update_core_devourer_gravity_claw_pool_prewarm", 1.0)
	await get_tree().process_frame

	var effect_parent := get_tree().current_scene if get_tree().current_scene else self
	if _find_core_devourer_pool_items(effect_parent).is_empty():
		_fail("Core devourer pool prewarm should create a pooled claw under the scene.")
		return

	enemy.call("_clear_core_devourer_gravity_claw_pool")
	for _i in range(8):
		await get_tree().process_frame
	if not _find_core_devourer_pool_items(effect_parent).is_empty():
		_fail("Core devourer pool clear helper should free pooled claws.")
		return

	enemy.call("_request_core_devourer_gravity_claw_pool_prewarm")
	enemy.call("_update_core_devourer_gravity_claw_pool_prewarm", 1.0)
	await get_tree().process_frame

	remove_child(enemy)
	enemy.queue_free()
	for _i in range(8):
		await get_tree().process_frame

	var remaining_pool_items := _find_core_devourer_pool_items(effect_parent)
	if not remaining_pool_items.is_empty():
		var states: Array[String] = []
		for item in remaining_pool_items:
			states.append("%s queued=%s parent=%s" % [
				item.name,
				str(item.is_queued_for_deletion()),
				item.get_parent().name if item.get_parent() else "<none>",
			])
		_fail("Core devourer pool items should be freed when the owner leaves the scene. Remaining: %s" % ", ".join(states))
		return

	print("Core devourer pool cleanup check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)


func _find_core_devourer_pool_items(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	if root.get_meta(&"core_devourer_pool_item", false):
		result.append(root)
	for child in root.get_children():
		result.append_array(_find_core_devourer_pool_items(child))
	return result
