extends Node


const DESIGNED_ENEMY_SCENE := preload("res://scenes/entities/designed_enemies/DesignedEnemy.tscn")
const DesignedEnemyScript := preload("res://scripts/entities/designed_enemies/DesignedEnemy.gd")

var _failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DesignedEnemyScript.release_static_runtime_resources()
	var enemy := DESIGNED_ENEMY_SCENE.instantiate()
	add_child(enemy)
	enemy.set("behavior", -1)
	enemy.call("_ensure_behavior_visuals", true)
	await get_tree().process_frame
	var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		_fail("Designed enemy should always expose Sprite2D.")
		return
	if sprite.texture == null and sprite.visible:
		_fail("Designed enemy placeholder Sprite2D must be hidden while texture is still pending.")
		return
	if enemy.get_node_or_null("PlaceholderBody") == null and sprite.texture == null:
		_fail("Designed enemy should show ColorRect placeholder while texture is pending.")
		return
	enemy.queue_free()
	while is_instance_valid(enemy):
		await get_tree().process_frame
	DesignedEnemyScript.release_static_runtime_resources()
	print("Designed enemy placeholder texture check passed.")
	get_tree().quit(0)


func release_pooled_patrol_enemy(enemy: Node2D, _behavior: int) -> void:
	if is_instance_valid(enemy):
		enemy.queue_free()


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
