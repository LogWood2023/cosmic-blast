extends Control

signal closed
signal choice_selected(choice_id: String)

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var title_label: Label = $Panel/TitleLabel
@onready var meta_label: Label = $Panel/MetaLabel
@onready var story_label: RichTextLabel = $Panel/StoryLabel
@onready var choices_list: VBoxContainer = $Panel/ChoicesScroll/ChoicesList
@onready var close_button: Button = $Panel/CloseButton

var _choice_buttons: Array[Button] = []
var _is_closing := false


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	close_button.pressed.connect(_on_close_pressed)


func setup(node: Dictionary, choices: Array) -> void:
	title_label.text = String(node.get("reward_title", "遗失补给")).strip_edges()
	if title_label.text.is_empty():
		title_label.text = "遗失补给"
	meta_label.text = "第 %d 阶层 · 奖励事件 · 仅可选择一项" % int(node.get("tier", 1))
	story_label.text = String(node.get("reward_description", "一艘损毁的转运船漂浮在航道边缘。你只能带走其中一份完好的补给。"))
	for child in choices_list.get_children():
		child.queue_free()
	_choice_buttons.clear()
	close_button.text = "暂不领取"
	for choice in choices:
		_add_choice_button(Dictionary(choice))
	if not _choice_buttons.is_empty():
		_choice_buttons.front().grab_focus()


func _add_choice_button(choice: Dictionary) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, 108.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _make_choice_style(Color(0.49, 0.35, 0.10, 0.92), Color(0.98, 0.76, 0.27, 0.82)))
	button.add_theme_stylebox_override("hover", _make_choice_style(Color(0.66, 0.48, 0.14, 0.98), Color(1.0, 0.92, 0.62, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_choice_style(Color(0.32, 0.22, 0.06, 1.0), Color(0.95, 0.74, 0.28, 1.0)))
	button.pressed.connect(func() -> void:
		for choice_button in _choice_buttons:
			choice_button.disabled = true
		choice_selected.emit(String(choice.get("choice_id", "")))
	)
	var choice_title := Label.new()
	choice_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	choice_title.offset_left = 26.0
	choice_title.offset_top = 14.0
	choice_title.offset_right = -26.0
	choice_title.offset_bottom = 47.0
	choice_title.add_theme_color_override("font_color", Color(1.0, 0.89, 0.48, 1.0))
	choice_title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.01, 0.92))
	choice_title.add_theme_constant_override("outline_size", 2)
	choice_title.add_theme_font_size_override("font_size", 24)
	choice_title.text = String(choice.get("title", "未知补给"))
	button.add_child(choice_title)
	var choice_description := Label.new()
	choice_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_description.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	choice_description.offset_left = 26.0
	choice_description.offset_top = -52.0
	choice_description.offset_right = -26.0
	choice_description.offset_bottom = -14.0
	choice_description.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))
	choice_description.add_theme_font_size_override("font_size", 18)
	choice_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_description.text = String(choice.get("preview", choice.get("description", "补给正在等待确认。")))
	button.add_child(choice_description)
	choices_list.add_child(button)
	_choice_buttons.append(button)


func _make_choice_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func show_result(result: Dictionary) -> void:
	title_label.text = "补给已入库"
	meta_label.text = "奖励事件完成 · 航图路径已更新"
	story_label.text = String(result.get("message", "方舟已完成本次补给回收。"))
	for child in choices_list.get_children():
		child.queue_free()
	_choice_buttons.clear()
	var result_label := RichTextLabel.new()
	result_label.custom_minimum_size = Vector2(0.0, 200.0)
	result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_label.bbcode_enabled = true
	result_label.fit_content = false
	result_label.scroll_active = true
	result_label.add_theme_font_size_override("normal_font_size", 22)
	var lines: Array[String] = []
	if int(result.get("minerals_added", 0)) > 0:
		lines.append("星髓矿 +%d" % int(result.get("minerals_added", 0)))
	if int(result.get("healed", 0)) > 0:
		lines.append("结构修复 +%d" % int(result.get("healed", 0)))
	var equipment_name := String(result.get("equipment_name", ""))
	if not equipment_name.is_empty():
		lines.append("获得装备：%s" % equipment_name)
	if lines.is_empty():
		lines.append("补给回收完毕。")
	result_label.text = "\n\n".join(lines)
	choices_list.add_child(result_label)
	close_button.text = "继续航行"
	close_button.grab_focus()


func _on_close_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	CombatUiMotion.animate_first_panel_exit(self, func() -> void:
		closed.emit()
		queue_free()
	)
