extends Node2D
## 敌人生成器 —— 三方向屏外生成

@export var enemy_scenes: Array[PackedScene] = []
@export var max_enemies: int = 10
@export var spawn_interval: float = 2.0
var paused: bool = false                     # Boss 在场时暂停

var screen_size: Vector2
var spawn_timer: float = 0.0
const SPAWN_MARGIN: float = 150.0   # 生成距离屏幕边缘的余量


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	add_to_group(&"spawner")


func _process(delta: float) -> void:
	if paused:
		return
	spawn_timer -= delta

	var active = get_tree().get_nodes_in_group(&"enemies").size()
	if active >= max_enemies:
		return

	if spawn_timer <= 0.0 and not enemy_scenes.is_empty():
		_spawn_enemy()
		var d = GameManager.difficulty()
		spawn_timer = lerpf(spawn_interval, spawn_interval * 0.4, d)


func _spawn_enemy() -> void:
	var idx = randi_range(0, enemy_scenes.size() - 1)
	var enemy = enemy_scenes[idx].instantiate()

	# 三方向随机：上/左/右 的屏幕外
	var side = randi_range(0, 2)
	match side:
		0:  # 上方
			enemy.position.x = randf_range(SPAWN_MARGIN, screen_size.x - SPAWN_MARGIN)
			enemy.position.y = -SPAWN_MARGIN
		1:  # 左侧
			enemy.position.x = -SPAWN_MARGIN
			enemy.position.y = randf_range(SPAWN_MARGIN, screen_size.y * 0.7)
		2:  # 右侧
			enemy.position.x = screen_size.x + SPAWN_MARGIN
			enemy.position.y = randf_range(SPAWN_MARGIN, screen_size.y * 0.7)

	var scene = get_tree().current_scene
	scene.add_child(enemy)
