extends Control

signal evacuate_pressed

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var evacuate_button: Button = $Panel/EvacuateButton
@onready var title_label: Label = $Panel/Title
@onready var subtitle_label: Label = $Panel/Subtitle
@onready var summary_label: RichTextLabel = $Panel/Summary

var _is_closing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	evacuate_button.pressed.connect(_on_evacuate_pressed)


func setup(summary: Dictionary) -> void:
	title_label.text = "撤离结算"
	subtitle_label.text = "战利品数据已完成核验，请确认本次入库结果。"
	evacuate_button.text = "确认并继续"
	var lines: Array[String] = []
	if not bool(summary.get("ok", false)):
		lines.append("[color=#ffb84d]结算记录异常，方舟将保留当前航程状态。[/color]")
	else:
		var minerals := int(summary.get("minerals_committed", 0))
		lines.append("[b]回收星髓矿[/b]  +%d" % minerals)
		var equipment_names := _to_string_array(summary.get("equipment_names", []))
		if equipment_names.is_empty():
			lines.append("[b]装备蓝图[/b]  无新增")
		else:
			lines.append("[b]装备蓝图[/b]  %s" % "、".join(equipment_names))
		var crisis_added := int(summary.get("base_crisis_added", 0)) + int(summary.get("event_contract_crisis_added", 0))
		lines.append("[b]危机变化[/b]  +%d" % crisis_added)
		var applied_contracts: Array = summary.get("event_contracts_applied", [])
		if not applied_contracts.is_empty():
			var contract_names: Array[String] = []
			for raw_contract in applied_contracts:
				var contract_name := String(Dictionary(raw_contract).get("title", "")).strip_edges()
				if not contract_name.is_empty() and not contract_names.has(contract_name):
					contract_names.append(contract_name)
			if not contract_names.is_empty():
				lines.append("[b]契约回响[/b]  %s" % "、".join(contract_names))
		var expired_count := int(summary.get("expired_event_contract_count", 0))
		if expired_count > 0:
			lines.append("[b]到期契约[/b]  %d 项" % expired_count)
	summary_label.text = "\n".join(lines)


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			var text := String(item).strip_edges()
			if not text.is_empty():
				result.append(text)
	return result


func _on_evacuate_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	evacuate_button.disabled = true
	CombatUiMotion.animate_first_panel_exit(self, func() -> void:
		evacuate_pressed.emit()
	)
