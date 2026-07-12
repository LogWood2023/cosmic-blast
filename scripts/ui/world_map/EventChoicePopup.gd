extends Control

signal closed
signal choice_selected(choice_id: String)

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var title_label: Label = $Panel/TitleLabel
@onready var meta_label: Label = $Panel/MetaLabel
@onready var choices_list: VBoxContainer = $Panel/ChoicesScroll/ChoicesList
@onready var close_button: Button = $Panel/CloseButton
@onready var event_background: TextureRect = $EventBackground

var _choice_buttons: Array[Button] = []


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
	_choice_buttons.clear()
	close_button.text = "暂不处理"
	for choice in choices:
		_add_choice_button(choice)


func _add_choice_button(choice: Dictionary) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, 128.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lines: Array[String] = [
		String(choice.get("title", "未知方案")),
		String(choice.get("flavor_text", "信号内容模糊，只有靠近后才能确认回应。")),
	]
	button.text = "\n".join(lines)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(func() -> void:
		for choice_button in _choice_buttons:
			choice_button.disabled = true
		choice_selected.emit(String(choice.get("choice_id", "")))
	)
	choices_list.add_child(button)
	_choice_buttons.append(button)
	button.mouse_entered.connect(_set_event_background.bind(String(choice.get("background_path", ""))))
	if _choice_buttons.size() == 1:
		_set_event_background(String(choice.get("background_path", "")))


func _set_event_background(background_path: String) -> void:
	if background_path.is_empty() or not ResourceLoader.exists(background_path):
		return
	event_background.texture = load(background_path) as Texture2D


func show_result(result: Dictionary) -> void:
	title_label.text = "事件结算"
	meta_label.text = "事件已写入航图记录"
	for child in choices_list.get_children():
		child.queue_free()
	_choice_buttons.clear()
	var result_label := RichTextLabel.new()
	result_label.custom_minimum_size = Vector2(0.0, 320.0)
	result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_label.bbcode_enabled = true
	result_label.fit_content = false
	result_label.scroll_active = true
	result_label.add_theme_font_size_override("normal_font_size", 22)
	result_label.text = _make_result_text(result)
	choices_list.add_child(result_label)
	close_button.text = "确认"


func _make_result_text(result: Dictionary) -> String:
	var lines: Array[String] = []
	var message := String(result.get("message", "事件处理完成。")).strip_edges()
	if not message.is_empty():
		lines.append("[color=#9feeff]%s[/color]" % message)
	var minerals := int(result.get("minerals_added", 0))
	if minerals > 0:
		lines.append("星髓矿 +%d" % minerals)
	var healed := int(result.get("healed", 0))
	if healed > 0:
		lines.append("结构修复 +%d" % healed)
	var hp_loss := int(result.get("hp_loss", 0))
	if hp_loss > 0:
		lines.append("结构损失 -%d" % hp_loss)
	var equipment_name := String(result.get("equipment_name", "")).strip_edges()
	if not equipment_name.is_empty():
		lines.append("获得装备：%s" % equipment_name)
	var contract_title := String(result.get("contract_title", "")).strip_edges()
	if not contract_title.is_empty():
		lines.append("已生效航路契约：%s" % contract_title)
	if lines.size() <= 1:
		lines.append("方舟已同步本次事件的后续影响。")
	return "\n\n".join(lines)


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
