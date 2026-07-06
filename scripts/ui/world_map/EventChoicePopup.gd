extends Control

signal closed
signal choice_selected(choice_id: String)

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var title_label: Label = $Panel/TitleLabel
@onready var meta_label: Label = $Panel/MetaLabel
@onready var choices_list: VBoxContainer = $Panel/ChoicesScroll/ChoicesList
@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	close_button.pressed.connect(_on_close_pressed)


func setup(node: Dictionary, choices: Array) -> void:
	title_label.text = "事件方案选择"
	meta_label.text = "阶层%d / %s / %s" % [
		int(node.get("tier", 1)),
		String(node.get("intel_title", "未知情报")),
		_family_text(String(node.get("family_bias", ""))),
	]
	for child in choices_list.get_children():
		child.queue_free()
	for choice in choices:
		_add_choice_button(choice)


func _add_choice_button(choice: Dictionary) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, 128.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lines: Array[String] = [
		"%s  [%s]" % [
			String(choice.get("title", "未知方案")),
			String(choice.get("risk_label", "安全")),
		],
		String(choice.get("reward_preview", String(choice.get("preview", "")))),
		String(choice.get("cost_preview", "无直接代价")),
	]
	var tactic_preview := String(choice.get("tactic_preview", ""))
	if not tactic_preview.is_empty():
		lines.append(tactic_preview)
	var contract_preview := String(choice.get("contract_preview", ""))
	if not contract_preview.is_empty():
		lines.append(contract_preview)
	button.text = "\n".join(lines)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(func() -> void:
		choice_selected.emit(String(choice.get("choice_id", "")))
		queue_free()
	)
	choices_list.add_child(button)


func _family_text(family: String) -> String:
	match family:
		"colossus":
			return "星间巨构"
		"paradise":
			return "天堂号"
		"warped":
			return "扭曲星核"
		"hell_eye":
			return "地狱之眼"
		"divine":
			return "神明使者"
	return "通用信号"


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
