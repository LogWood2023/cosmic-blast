extends Control

signal closed

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")
const SECTION_COLOR := Color(0.32, 0.91, 1.0, 0.95)
const BODY_COLOR := Color(0.79, 0.88, 0.95, 1.0)
const ACTIONS := [
	["向上移动", &"move_up"],
	["向左移动", &"move_left"],
	["向下移动", &"move_down"],
	["向右移动", &"move_right"],
	["开火", &"shoot"],
	["冲刺", &"dash"],
]

@onready var shade: ColorRect = $Shade
@onready var panel: PanelContainer = $CenterContainer/Panel

var _binding_action: StringName = &""
var _binding_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	shade.gui_input.connect(_on_shade_gui_input)
	_build_contents()
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)


func _unhandled_input(event: InputEvent) -> void:
	if _binding_action == &"":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_finish_rebind(false)
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			return
		_finish_rebind(true, event)
	elif event is InputEventMouseButton and event.pressed:
		_finish_rebind(true, event)
	elif event is InputEventJoypadButton and event.pressed:
		_finish_rebind(true, event)
	else:
		return
	get_viewport().set_input_as_handled()


func _build_contents() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 54
	layout.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	var kicker := _make_label("SYSTEM CONFIGURATION", 16, Color(1.0, 0.72, 0.30, 1.0))
	title_box.add_child(kicker)
	var title := _make_label("游戏设置", 32, Color(0.98, 1.0, 1.0, 1.0))
	title_box.add_child(title)
	var close_button := _make_button("关闭", Vector2(128, 46))
	close_button.pressed.connect(_close)
	header.add_child(close_button)

	var divider := HSeparator.new()
	divider.modulate = SECTION_COLOR
	layout.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	_add_section(content, "音效")
	_add_slider(content, "主音量", SettingsManager.master_volume, SettingsManager.set_master_volume)
	_add_slider(content, "音乐音量", SettingsManager.music_volume, SettingsManager.set_music_volume)
	_add_slider(content, "音效音量", SettingsManager.sfx_volume, SettingsManager.set_sfx_volume)
	_add_section(content, "显示与无障碍")
	_add_toggle(content, "全屏显示", SettingsManager.fullscreen, SettingsManager.set_fullscreen)
	_add_resolution(content)
	_add_toggle(content, "垂直同步", SettingsManager.vsync_enabled, SettingsManager.set_vsync_enabled)
	_add_slider(content, "屏幕震动强度", SettingsManager.screen_shake_strength, SettingsManager.set_screen_shake_strength)
	_add_toggle(content, "低特效模式", SettingsManager.reduced_effects, SettingsManager.set_reduced_effects)
	_add_section(content, "操作")
	var controls_note := _make_label("点击按键即可重新绑定；按 Esc 取消绑定。", 16, Color(0.58, 0.72, 0.82, 1.0))
	content.add_child(controls_note)
	for item in ACTIONS:
		_add_binding(content, item[0], item[1])
	_add_toggle(content, "自动开火", SettingsManager.auto_fire, SettingsManager.set_auto_fire)

	var footer := HBoxContainer.new()
	footer.custom_minimum_size.y = 50
	layout.add_child(footer)
	var reset_note := _make_label("改动会自动保存。", 16, Color(0.58, 0.72, 0.82, 1.0))
	reset_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(reset_note)
	var reset := _make_button("恢复默认", Vector2(164, 46))
	reset.pressed.connect(_reset_settings)
	footer.add_child(reset)


func _add_section(parent: VBoxContainer, text: String) -> void:
	var label := _make_label(text, 20, SECTION_COLOR)
	label.custom_minimum_size.y = 32
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	parent.add_child(label)


func _add_slider(parent: VBoxContainer, title: String, value: float, setter: Callable) -> void:
	var row := _make_row(parent, title)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(420, 34)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	row.add_child(slider)
	var value_label := _make_label("%d%%" % roundi(value * 100.0), 16, BODY_COLOR)
	value_label.custom_minimum_size.x = 58
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	slider.value_changed.connect(func(new_value: float) -> void:
		setter.call(new_value)
		value_label.text = "%d%%" % roundi(new_value * 100.0)
	)


func _add_toggle(parent: VBoxContainer, title: String, value: bool, setter: Callable) -> void:
	var row := _make_row(parent, title)
	var toggle := _make_button("开启" if value else "关闭", Vector2(128, 40))
	toggle.toggle_mode = true
	toggle.button_pressed = value
	toggle.toggled.connect(func(enabled: bool) -> void:
		toggle.text = "开启" if enabled else "关闭"
		setter.call(enabled)
	)
	row.add_child(toggle)


func _add_resolution(parent: VBoxContainer) -> void:
	var row := _make_row(parent, "窗口分辨率")
	var options := OptionButton.new()
	options.custom_minimum_size = Vector2(260, 40)
	for size in SettingsManager.WINDOW_SIZES:
		options.add_item("%d × %d" % [size.x, size.y])
	options.select(SettingsManager.window_size_index)
	options.item_selected.connect(SettingsManager.set_window_size_index)
	row.add_child(options)


func _add_binding(parent: VBoxContainer, title: String, action: StringName) -> void:
	var row := _make_row(parent, title)
	var button := _make_button(SettingsManager.get_binding_text(action), Vector2(420, 40))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_begin_rebind.bind(action, button))
	row.add_child(button)


func _make_row(parent: VBoxContainer, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 44
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)
	var label := _make_label(title, 18, BODY_COLOR)
	label.custom_minimum_size.x = 220
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.11, 0.18, 0.24, 0.9), Color(0.32, 0.91, 1.0, 0.54)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.08, 0.28, 0.36, 0.96), SECTION_COLOR))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.24, 0.08, 0.10, 0.96), Color(1.0, 0.31, 0.42, 0.94)))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.08, 0.28, 0.36, 0.96), SECTION_COLOR))
	return button


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style


func _begin_rebind(action: StringName, button: Button) -> void:
	if _binding_action != &"":
		_finish_rebind(false)
	_binding_action = action
	_binding_button = button
	button.text = "请按下新按键…"
	button.grab_focus()


func _finish_rebind(save: bool, event: InputEvent = null) -> void:
	if _binding_action == &"":
		return
	if save and event != null:
		SettingsManager.set_binding(_binding_action, event.duplicate())
		_binding_button.text = SettingsManager.get_binding_text(_binding_action)
	elif _binding_button:
		_binding_button.text = SettingsManager.get_binding_text(_binding_action)
	_binding_action = &""
	_binding_button = null


func _reset_settings() -> void:
	_finish_rebind(false)
	SettingsManager.reset_to_defaults()
	get_tree().reload_current_scene()


func _close() -> void:
	_finish_rebind(false)
	closed.emit()
	queue_free()


func _on_shade_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close()
	elif event is InputEventScreenTouch and event.pressed:
		_close()
