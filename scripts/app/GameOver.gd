extends CanvasLayer
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
## 游戏结束画面

@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var final_score_label: Label = $Panel/Margin/VBox/FinalScoreLabel


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	if not RunManager.last_result_summary.is_empty():
		var summary := RunManager.last_result_summary
		title_label.text = "航程完成" if bool(summary.get("victory", false)) else "机体结构失效"
		final_score_label.text = _format_run_summary(summary)
		return
	final_score_label.text = "最终得分: %d" % GameManager.score


func _format_run_summary(summary: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("得分：%d   危机关注度：%d   已探索：%d" % [
		int(summary.get("score", GameManager.score)),
		int(summary.get("crisis_level", 0)),
		int(summary.get("completed_node_count", 0)),
	])
	lines.append("星髓矿：%d   装备：%d   装配容量：%d" % [
		int(summary.get("minerals", 0)),
		int(summary.get("equipment_count", 0)),
		int(summary.get("compute_capacity", 0)),
	])
	lines.append("已清除首领：%d/%d" % [
		int(summary.get("cleared_boss_count", 0)),
		RunManager.CRISIS_THRESHOLDS.size(),
	])
	var boss_reward := Dictionary(summary.get("last_boss_reward", {}))
	var item_id := String(boss_reward.get("item_id", ""))
	if not item_id.is_empty() and EquipmentCatalogScript.has_item(item_id):
		lines.append("回收装备：%s" % EquipmentCatalogScript.get_display_name(item_id))
	else:
		var threshold := int(boss_reward.get("threshold", 0))
		if threshold > 0:
			lines.append("首领记录：已完成第 %d 阶段" % threshold)
	if bool(summary.get("victory", false)):
		lines.append("方舟核心：本次航程记录已封存。")
	else:
		lines.append("引导之声：回声已保存。整理装配后，仍可再次出航。")
		lines.append("方舟核心：已解锁的档案与局外进度会保留。")
	return "\n".join(lines)


func _on_restart_button_pressed() -> void:
	GameManager.reset_run_state()
	RunManager.start_new_run()
	SceneTransition.change_scene_to_file("res://scenes/app/WorldMap.tscn")


func _on_menu_button_pressed() -> void:
	GameManager.reset_run_state()
	SceneTransition.change_scene_to_file("res://scenes/app/MainMenu.tscn")
