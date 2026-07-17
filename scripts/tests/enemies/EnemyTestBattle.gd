extends Node2D

const Catalog = preload("res://scripts/entities/designed_enemies/DesignedEnemyCatalog.gd")
const ENEMY_SCENE = preload("res://scenes/entities/designed_enemies/DesignedEnemy.tscn")
const OBSTACLE_SET_SCENE = preload("res://scenes/tests/enemies/EnemyTestObstacleSet.tscn")

@export var enemy_id: String = "ColossusShardArm"

var enemy: Area2D


func _ready() -> void:
	GameManager.reset_run_state()
	_setup_mechanic_background()
	_spawn_obstacle_set()
	_spawn_enemy()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneTransition.change_scene_to_file("res://scenes/tests/enemies/EnemyTestSelect.tscn")


func _spawn_obstacle_set() -> void:
	var obstacle_set := OBSTACLE_SET_SCENE.instantiate()
	add_child(obstacle_set)


func _setup_mechanic_background() -> void:
	var data := Catalog.get_enemy(enemy_id)
	if data.is_empty():
		return
	var panel := ColorRect.new()
	panel.name = "MechanicBackground"
	panel.color = Color(0.02, 0.025, 0.04, 0.68)
	panel.position = Vector2(80, 80)
	panel.size = Vector2(760, 190)
	panel.z_index = -200
	add_child(panel)
	var title := Label.new()
	title.name = "MechanicTitle"
	title.position = Vector2(104, 96)
	title.size = Vector2(720, 44)
	title.text = "%s / %s" % [data.family, data.name]
	title.add_theme_font_size_override("font_size", 30)
	title.z_index = -199
	add_child(title)
	var body := Label.new()
	body.name = "MechanicText"
	body.position = Vector2(104, 148)
	body.size = Vector2(700, 100)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = "机制：%s\nHP：%d    触碰/基础伤害：%d    占位矩形：%d×%d" % [data.mechanic, data.hp, data.damage, int(data.size.x), int(data.size.y)]
	body.add_theme_font_size_override("font_size", 22)
	body.z_index = -199
	add_child(body)


func _spawn_enemy() -> void:
	var data := Catalog.get_enemy(enemy_id)
	if data.is_empty():
		return
	enemy = ENEMY_SCENE.instantiate()
	enemy.behavior = data.behavior
	enemy.enemy_title = data.name
	enemy.hp = data.hp
	enemy.damage = data.damage
	enemy.body_size = data.size
	enemy.body_color = data.color
	enemy.accent_color = data.accent
	enemy.global_position = data.pos
	add_child(enemy)
