extends CanvasLayer
## 游戏结束画面

@onready var final_score_label: Label = $FinalScoreLabel


func _ready() -> void:
	final_score_label.text = "最终得分: %d" % GameManager.score


func _on_restart_pressed() -> void:
	GameManager.score = 0
	GameManager.player_hp = GameManager.PLAYER_MAX_HP
	GameManager.elapsed = 0.0
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_restart_button_pressed() -> void:
	GameManager.score = 0
	GameManager.player_hp = GameManager.PLAYER_MAX_HP
	GameManager.elapsed = 0.0
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
