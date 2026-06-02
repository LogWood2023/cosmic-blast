extends CanvasLayer
## 游戏结束画面

@onready var title_label: Label = $TitleLabel
@onready var final_score_label: Label = $FinalScoreLabel


func _ready() -> void:
	if not RunManager.last_result_summary.is_empty():
		var summary := RunManager.last_result_summary
		title_label.text = "航程完成" if bool(summary.get("victory", false)) else "本次回声中断"
		final_score_label.text = "得分: %d  危机: %d  已探索: %d  星髓矿: %d  装备: %d" % [
			int(summary.get("score", GameManager.score)),
			int(summary.get("crisis_level", 0)),
			int(summary.get("completed_node_count", 0)),
			int(summary.get("minerals", 0)),
			int(summary.get("equipment_count", 0)),
		]
		return
	final_score_label.text = "最终得分: %d" % GameManager.score


func _on_restart_pressed() -> void:
	GameManager.reset_run_state()
	RunManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/app/WorldMap.tscn")


func _on_restart_button_pressed() -> void:
	GameManager.reset_run_state()
	RunManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/app/WorldMap.tscn")
