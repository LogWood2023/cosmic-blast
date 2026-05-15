extends CanvasLayer


func _ready() -> void:
	$StartButton.pressed.connect(_on_start_pressed)
	$BossButton.pressed.connect(_on_boss_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	GameManager.score = 0
	GameManager.player_hp = GameManager.PLAYER_MAX_HP
	GameManager.elapsed = 0.0
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_boss_pressed() -> void:
	GameManager.score = 0
	GameManager.player_hp = GameManager.PLAYER_MAX_HP
	GameManager.elapsed = 0.0
	get_tree().change_scene_to_file("res://scenes/BossSelect.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
