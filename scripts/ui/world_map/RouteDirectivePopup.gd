extends Control

signal closed

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var title_label: Label = $Panel/TitleLabel
@onready var body_label: RichTextLabel = $Panel/BodyLabel
@onready var close_button: Button = $Panel/CloseButton

var _is_closing := false


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	close_button.pressed.connect(_on_close_pressed)


func setup(summary: Dictionary) -> void:
	title_label.text = "航路指令完成"
	var completed: Array = summary.get("completed_directives", [])
	var new_directives: Array = summary.get("new_directives", [])
	var reward_summary: Dictionary = summary.get("reward_summary", {})
	var route_momentum: Dictionary = summary.get("route_momentum", {})
	var lines: Array[String] = []
	if completed.is_empty():
		lines.append("[b]方舟航线已更新。[/b]")
	else:
		lines.append("[b]方舟核心确认新的航路成果。[/b]")
		lines.append("")
		for raw_directive in completed:
			var directive := Dictionary(raw_directive)
			var title := String(directive.get("title", "航路指令"))
			var description := String(directive.get("description", "航线目标已完成。"))
			var reward_text := String(directive.get("reward_text", "方舟补给"))
			lines.append("• %s" % title)
			lines.append(description)
			lines.append("回收：%s" % reward_text)
			var directive_reward_lines := _make_reward_lines(Dictionary(directive.get("reward_result", {})))
			if not directive_reward_lines.is_empty():
				lines.append("入库：%s" % " / ".join(directive_reward_lines))
	var reward_lines := _make_reward_lines(reward_summary)
	if not reward_lines.is_empty():
		lines.append("")
		lines.append("[b]入库补给：[/b]%s" % " / ".join(reward_lines))
	if not route_momentum.is_empty():
		lines.append("")
		lines.append("[b]航路动能：[/b]%s" % _make_route_momentum_line(route_momentum))
	if not new_directives.is_empty():
		lines.append("")
		lines.append("[b]新航路指令：[/b]")
		for raw_directive in new_directives:
			var directive := Dictionary(raw_directive)
			var title := String(directive.get("title", "航路指令"))
			var progress_text := String(directive.get("progress_text", "进度 0/1"))
			var reward_text := String(directive.get("reward_text", "方舟补给"))
			lines.append("• %s（%s）：%s" % [title, progress_text, reward_text])
	body_label.text = "\n".join(lines)


func _make_reward_lines(reward_summary: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var minerals := int(reward_summary.get("minerals", 0))
	var compute := int(reward_summary.get("compute", 0))
	var equipment: Array = reward_summary.get("equipment", [])
	var equipment_names: Array = reward_summary.get("equipment_names", [])
	var shop_focus_text := String(reward_summary.get("shop_focus_text", ""))
	var equipment_chance_text := String(reward_summary.get("equipment_chance_text", ""))
	if minerals > 0:
		lines.append("星髓矿 +%d" % minerals)
	if compute > 0:
		lines.append("算力容量 +%d" % compute)
	if not equipment_names.is_empty():
		lines.append("蓝图：%s" % "、".join(_string_array(equipment_names)))
	elif not equipment.is_empty():
		lines.append("蓝图 +%d" % equipment.size())
	if equipment_chance_text.is_empty() and float(reward_summary.get("equipment_chance_bonus", 0.0)) > 0.0:
		equipment_chance_text = "装备检出 +%d%%" % int(round(float(reward_summary.get("equipment_chance_bonus", 0.0)) * 100.0))
	if not equipment_chance_text.is_empty():
		lines.append(equipment_chance_text)
	if not shop_focus_text.is_empty():
		lines.append(shop_focus_text)
	return lines


func _make_route_momentum_line(route_momentum: Dictionary) -> String:
	var activation_text := String(route_momentum.get("activation_text", "")).strip_edges()
	if not activation_text.is_empty():
		return activation_text
	var remaining := int(route_momentum.get("remaining_nodes", 0))
	var effects := String(route_momentum.get("effects_text", "回收效率提高"))
	return "已点燃，接下来 %d 个完成节点内，%s。" % [remaining, effects]


func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		var text := String(value).strip_edges()
		if not text.is_empty():
			result.append(text)
	return result


func _on_close_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	CombatUiMotion.animate_first_panel_exit(self, func() -> void:
		closed.emit()
		queue_free()
	)
