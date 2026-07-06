extends Control

signal closed

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var title_label: Label = $Panel/TitleLabel
@onready var body_label: RichTextLabel = $Panel/BodyLabel
@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	close_button.pressed.connect(_on_close_pressed)


func setup(result: Dictionary) -> void:
	var run_manager := _get_run_manager()
	var ok := bool(result.get("ok", false))
	title_label.text = String(result.get("event_title", "事件结算")) if ok else "事件中断"
	var lines: Array[String] = []
	if ok:
		var category := String(result.get("event_category", ""))
		var node_tier := int(result.get("node_tier", 0))
		if not category.is_empty():
			lines.append("[b]事件类别：[/b]%s" % _category_text(category))
		if node_tier > 0:
			lines.append("[b]航图层级：[/b]T%d" % node_tier)
		var risk_label := String(result.get("risk_label", ""))
		if not risk_label.is_empty():
			lines.append("[b]风险等级：[/b]%s" % risk_label)
		var tactic_preview := String(result.get("tactic_preview", ""))
		if not tactic_preview.is_empty():
			lines.append("[b]战法回响：[/b]%s" % tactic_preview)
		lines.append("")
	lines.append(String(result.get("message", "")))
	if ok:
		_append_reward_lines(lines, result)
	if ok and run_manager != null:
		lines.append("")
		lines.append("[b]节点已探索[/b]")
		lines.append("危机等级：%d" % int(run_manager.crisis_level))
		lines.append("算力容量：%d" % int(run_manager.compute_capacity))
		lines.append("星髓矿：%d" % int(run_manager.minerals))
	body_label.text = "\n".join(lines)


func _append_reward_lines(lines: Array[String], result: Dictionary) -> void:
	var rewards: Array[String] = []
	var minerals := int(result.get("minerals_gained", 0))
	var heal := int(result.get("heal_gained", 0))
	var compute := int(result.get("compute_gained", 0))
	var equipment_id := String(result.get("equipment_id", ""))
	var special_bonus_id := String(result.get("special_bonus_id", ""))
	var hp_lost := int(result.get("hp_lost", 0))
	var minerals_spent := int(result.get("minerals_spent", 0))
	var crisis_added := int(result.get("crisis_added", 0))
	if minerals > 0:
		rewards.append("星髓矿 +%d" % minerals)
	if heal > 0:
		rewards.append("生命 +%d" % heal)
	if compute > 0:
		rewards.append("算力容量 +%d" % compute)
	if not equipment_id.is_empty():
		rewards.append("装备蓝图：%s" % equipment_id)
	if not special_bonus_id.is_empty():
		var special_name := special_bonus_id
		var run_manager := _get_run_manager()
		if run_manager != null and run_manager.has_method("get_special_bonus_display_name"):
			special_name = String(run_manager.call("get_special_bonus_display_name", special_bonus_id))
		rewards.append("增益同步：%s" % special_name)
	if rewards.is_empty():
		pass
	else:
		lines.append("")
		lines.append("[b]获得：[/b]%s" % " / ".join(rewards))
	var costs: Array[String] = []
	if hp_lost > 0:
		costs.append("生命 -%d" % hp_lost)
	if minerals_spent > 0:
		costs.append("星髓矿 -%d" % minerals_spent)
	if crisis_added > 0:
		costs.append("危机 +%d" % crisis_added)
	if not costs.is_empty():
		lines.append("[b]代价：[/b]%s" % " / ".join(costs))
	var contract_title := String(result.get("contract_title", ""))
	if not contract_title.is_empty():
		var remaining_nodes := int(result.get("contract_remaining_nodes", 0))
		var contract_description := String(result.get("contract_description", ""))
		lines.append("")
		lines.append("[b]临时契约：[/b]%s（剩余 %d 节点）" % [contract_title, remaining_nodes])
		if not contract_description.is_empty():
			lines.append(contract_description)


func _category_text(category: String) -> String:
	match category:
		"minerals":
			return "资源回收"
		"heal":
			return "机体修复"
		"equipment":
			return "装备蓝图"
		"compute":
			return "算力扩容"
		"special":
			return "信标同步"
		"mixed":
			return "混合收益"
	return category


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()


func _get_run_manager() -> Node:
	return get_node_or_null("/root/RunManager")
