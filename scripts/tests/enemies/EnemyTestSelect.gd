extends CanvasLayer

const Catalog = preload("res://scripts/entities/designed_enemies/DesignedEnemyCatalog.gd")


func _ready() -> void:
	_build_buttons()
	$BackButton.pressed.connect(_on_back_pressed)


func _build_buttons() -> void:
	var list := $ScrollContainer/VBoxContainer
	for child in list.get_children():
		child.queue_free()
	var current_family := ""
	for data in Catalog.ENEMIES:
		if data.family != current_family:
			current_family = data.family
			var label := Label.new()
			label.text = current_family
			label.add_theme_font_size_override("font_size", 28)
			list.add_child(label)
		var btn := Button.new()
		btn.text = "%s - %s" % [data.family, data.name]
		btn.custom_minimum_size = Vector2(520, 44)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_enemy_selected.bind(data.id))
		list.add_child(btn)


func _on_enemy_selected(enemy_id: String) -> void:
	var scene_path := "res://scenes/tests/enemies/EnemyTest_%s.tscn" % enemy_id
	GameManager.reset_run_state()
	SceneTransition.change_scene_to_file(scene_path)


func _on_back_pressed() -> void:
	SceneTransition.change_scene_to_file("res://scenes/app/MainMenu.tscn")
