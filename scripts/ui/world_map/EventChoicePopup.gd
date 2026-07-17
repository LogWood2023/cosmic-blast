extends Control

signal closed
signal choice_selected(choice_id: String)

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var title_label: Label = $Panel/TitleLabel
@onready var meta_label: Label = $Panel/MetaLabel
@onready var story_label: RichTextLabel = $Panel/StoryLabel
@onready var choices_list: VBoxContainer = $Panel/ChoicesScroll/ChoicesList
@onready var close_button: Button = $Panel/CloseButton
@onready var event_background: TextureRect = $EventBackground

var _choice_buttons: Array[Button] = []
var _is_closing := false


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	close_button.pressed.connect(_on_close_pressed)


func setup(node: Dictionary, choices: Array) -> void:
	title_label.text = String(node.get("intel_title", "异常信号")).strip_edges()
	if not choices.is_empty():
		title_label.text = String(Dictionary(choices[0]).get("event_title", title_label.text)).strip_edges()
	if title_label.text.is_empty():
		title_label.text = "异常信号"
	meta_label.text = "第 %d 阶层 · %s · %s" % [
		int(node.get("tier", 1)),
		_family_text(String(node.get("family_bias", ""))),
		"选择一项回应",
	]
	story_label.text = String(node.get("intel_description", "方舟捕获到一段无法归档的深空回声。它似乎正在等待你给出回应。")).strip_edges()
	if not choices.is_empty():
		story_label.text = String(Dictionary(choices[0]).get("narrative", story_label.text)).strip_edges()
	if story_label.text.is_empty():
		story_label.text = "方舟捕获到一段无法归档的深空回声。它似乎正在等待你给出回应。"
	for child in choices_list.get_children():
		child.queue_free()
	_choice_buttons.clear()
	close_button.text = "暂不回应"
	for choice in choices:
		_add_choice_button(Dictionary(choice))
	if not _choice_buttons.is_empty():
		_choice_buttons.front().grab_focus()


func _add_choice_button(choice: Dictionary) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, 108.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.disabled = not String(choice.get("disabled_reason", "")).is_empty()
	button.tooltip_text = String(choice.get("disabled_reason", ""))
	button.add_theme_stylebox_override("normal", _make_choice_style(Color(0.10, 0.49, 0.53, 0.90), Color(0.42, 0.93, 0.93, 0.78)))
	button.add_theme_stylebox_override("hover", _make_choice_style(Color(0.15, 0.64, 0.66, 0.96), Color(0.74, 1.0, 0.96, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_choice_style(Color(0.07, 0.35, 0.39, 0.98), Color(0.90, 0.73, 0.28, 1.0)))
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
	choice_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38, 1.0))
	choice_title.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.07, 0.9))
	choice_title.add_theme_constant_override("outline_size", 2)
	choice_title.add_theme_font_size_override("font_size", 24)
	choice_title.text = String(choice.get("title", "未知回应"))
	button.add_child(choice_title)
	var choice_description := Label.new()
	choice_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_description.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	choice_description.offset_left = 26.0
	choice_description.offset_top = -52.0
	choice_description.offset_right = -26.0
	choice_description.offset_bottom = -14.0
	choice_description.add_theme_color_override("font_color", Color(0.91, 0.97, 0.97, 1.0))
	choice_description.add_theme_font_size_override("font_size", 18)
	choice_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_description.text = String(choice.get("flavor_text", "信号内容模糊，只有靠近后才能确认回应。"))
	button.add_child(choice_description)
	choices_list.add_child(button)
	_choice_buttons.append(button)
	button.mouse_entered.connect(_set_event_background.bind(String(choice.get("background_path", ""))))
	if _choice_buttons.size() == 1:
		_set_event_background(String(choice.get("background_path", "")))


func _make_choice_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	return style


func _set_event_background(background_path: String) -> void:
	if background_path.is_empty() or not ResourceLoader.exists(background_path):
		return
	event_background.texture = load(background_path) as Texture2D


func show_result(result: Dictionary) -> void:
	title_label.text = "事件结算"
	meta_label.text = "本次回应已写入航图记录"
	story_label.text = String(result.get("message", "信号已归档，方舟正在同步后续影响。"))
	for child in choices_list.get_children():
		child.queue_free()
	_choice_buttons.clear()
	var result_label := RichTextLabel.new()
	result_label.custom_minimum_size = Vector2(0.0, 240.0)
	result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_label.bbcode_enabled = true
	result_label.fit_content = false
	result_label.scroll_active = true
	result_label.add_theme_font_size_override("normal_font_size", 22)
	result_label.text = _make_result_text(result)
	choices_list.add_child(result_label)
	close_button.text = "继续航行"
	close_button.grab_focus()


func _make_result_text(result: Dictionary) -> String:
	var lines: Array[String] = []
	var minerals := int(result.get("minerals_added", result.get("minerals_gained", 0)))
	if minerals > 0:
		lines.append("星髓矿 +%d" % minerals)
	var healed := int(result.get("healed", result.get("heal_gained", 0)))
	if healed > 0:
		lines.append("结构修复 +%d" % healed)
	var hp_loss := int(result.get("hp_loss", result.get("hp_lost", 0)))
	if hp_loss > 0:
		lines.append("结构损失 -%d" % hp_loss)
	var equipment_name := String(result.get("equipment_name", "")).strip_edges()
	if equipment_name.is_empty() and not String(result.get("equipment_id", "")).is_empty():
		equipment_name = String(result.get("equipment_id", ""))
	if not equipment_name.is_empty():
		lines.append("获得装备：%s" % equipment_name)
	var contract_title := String(result.get("contract_title", "")).strip_edges()
	if not contract_title.is_empty():
		lines.append("已生效航路契约：%s" % contract_title)
	if lines.is_empty():
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
	return "未分类回声"


func _on_close_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	CombatUiMotion.animate_first_panel_exit(self, func() -> void:
		closed.emit()
		queue_free()
	)
