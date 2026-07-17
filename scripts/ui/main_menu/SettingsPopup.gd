extends Control

signal closed
signal save_and_exit_requested
signal save_and_main_menu_requested

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
var _initial_settings: Dictionary = {}
var _draft: Dictionary = {}
var _dirty := false
var _discard_dialog: Control
var _world_map_actions_enabled := false
var _is_closing := false


func configure_for_world_map() -> void:
	_world_map_actions_enabled = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initial_settings = SettingsManager.get_settings_snapshot()
	_draft = SettingsManager.get_settings_snapshot()
	shade.gui_input.connect(_on_shade_gui_input)
	_build_contents()
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)


func _unhandled_input(event: InputEvent) -> void:
	if _binding_action != &"":
		_handle_rebind_input(event)
		return
	if is_instance_valid(_discard_dialog):
		return
	if event.is_action_pressed(&"ui_cancel"):
		_request_close()
		get_viewport().set_input_as_handled()


func _handle_rebind_input(event: InputEvent) -> void:
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
	var kicker := _make_label(GameCopy.text(&"ui.settings.kicker"), 16, Color(1.0, 0.72, 0.30, 1.0))
	title_box.add_child(kicker)
	var title := _make_label("系统设置", 32, Color(0.98, 1.0, 1.0, 1.0))
	title_box.add_child(title)
	var close_button := _make_button("关闭", Vector2(128, 46))
	close_button.pressed.connect(_request_close)
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

	_add_section(content, "音频")
	_add_slider(content, "主音量", "master_volume")
	_add_slider(content, "音乐音量", "music_volume")
	_add_slider(content, "音效音量", "sfx_volume")
	_add_section(content, "显示与辅助功能")
	_add_toggle(content, "全屏显示", "fullscreen")
	_add_resolution(content)
	_add_toggle(content, "垂直同步", "vsync_enabled")
	_add_slider(content, "屏幕震动强度", "screen_shake_strength")
	_add_toggle(content, "低特效模式", "reduced_effects")
	_add_section(content, "控制")
	var controls_note := _make_label("点击按键即可重新绑定；按取消键可放弃本次修改。", 16, Color(0.58, 0.72, 0.82, 1.0))
	content.add_child(controls_note)
	for item in ACTIONS:
		_add_binding(content, item[0], item[1])

	var footer := HBoxContainer.new()
	footer.custom_minimum_size.y = 50
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)
	var note := _make_label("修改仅在点击保存后生效。", 16, Color(0.58, 0.72, 0.82, 1.0))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(note)
	var reset := _make_button("恢复默认", Vector2(148, 46))
	reset.pressed.connect(_reset_draft)
	footer.add_child(reset)
	var save := _make_button("保存并应用", Vector2(164, 46))
	save.pressed.connect(_save_draft)
	footer.add_child(save)
	if _world_map_actions_enabled:
		var save_and_exit := _make_button("保存并退出", Vector2(164, 46))
		save_and_exit.pressed.connect(_save_and_exit)
		footer.add_child(save_and_exit)
		var save_and_main_menu := _make_button("保存并回到主菜单", Vector2(204, 46))
		save_and_main_menu.pressed.connect(_save_and_main_menu)
		footer.add_child(save_and_main_menu)


func _add_section(parent: VBoxContainer, text: String) -> void:
	var label := _make_label(text, 20, SECTION_COLOR)
	label.custom_minimum_size.y = 32
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	parent.add_child(label)


func _add_slider(parent: VBoxContainer, title: String, key: String) -> void:
	var row := _make_row(parent, title)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(420, 34)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(_draft[key])
	row.add_child(slider)
	var value_label := _make_label("%d%%" % roundi(slider.value * 100.0), 16, BODY_COLOR)
	value_label.custom_minimum_size.x = 58
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float) -> void:
		_draft[key] = value
		value_label.text = "%d%%" % roundi(value * 100.0)
		_update_dirty_state()
	)


func _add_toggle(parent: VBoxContainer, title: String, key: String) -> void:
	var row := _make_row(parent, title)
	var toggle := _make_button("开启" if bool(_draft[key]) else "关闭", Vector2(128, 40))
	toggle.toggle_mode = true
	toggle.button_pressed = bool(_draft[key])
	toggle.toggled.connect(func(enabled: bool) -> void:
		toggle.text = "开启" if enabled else "关闭"
		_draft[key] = enabled
		_update_dirty_state()
	)
	row.add_child(toggle)


func _add_resolution(parent: VBoxContainer) -> void:
	var row := _make_row(parent, "窗口分辨率")
	var options := OptionButton.new()
	options.custom_minimum_size = Vector2(260, 40)
	for size in SettingsManager.WINDOW_SIZES:
		options.add_item("%d × %d" % [size.x, size.y])
	options.select(int(_draft["window_size_index"]))
	options.item_selected.connect(func(index: int) -> void:
		_draft["window_size_index"] = index
		_update_dirty_state()
	)
	row.add_child(options)


func _add_binding(parent: VBoxContainer, title: String, action: StringName) -> void:
	var row := _make_row(parent, title)
	var button := _make_button(SettingsManager.format_binding_text(_get_draft_binding(action)), Vector2(420, 40))
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


func _panel_style() -> StyleBoxFlat:
	var style := _button_style(Color(0.027, 0.063, 0.094, 0.98), Color(0.32, 0.91, 1.0, 0.72))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 4
	return style


func _begin_rebind(action: StringName, button: Button) -> void:
	if _binding_action != &"":
		_finish_rebind(false)
	_binding_action = action
	_binding_button = button
	button.text = "请按下新按键…"
	button.grab_focus()


func _finish_rebind(apply: bool, event: InputEvent = null) -> void:
	if _binding_action == &"":
		return
	if apply and event != null:
		var bindings: Dictionary = _draft["bindings"]
		bindings[String(_binding_action)] = [event.duplicate()]
		_draft["bindings"] = bindings
		_update_dirty_state()
	if _binding_button:
		_binding_button.text = SettingsManager.format_binding_text(_get_draft_binding(_binding_action))
	_binding_action = &""
	_binding_button = null


func _get_draft_binding(action: StringName) -> Array:
	var bindings: Dictionary = _draft.get("bindings", {})
	return bindings.get(String(action), [])


func _reset_draft() -> void:
	_finish_rebind(false)
	_draft = SettingsManager.get_default_settings()
	_update_dirty_state()
	_rebuild_contents()


func _save_draft() -> void:
	_finish_rebind(false)
	SettingsManager.apply_settings(_draft, true)
	_initial_settings = SettingsManager.get_settings_snapshot()
	_draft = SettingsManager.get_settings_snapshot()
	_dirty = false
	_close()


func _save_and_exit() -> void:
	_finish_rebind(false)
	SettingsManager.apply_settings(_draft, true)
	_close(func() -> void: save_and_exit_requested.emit())


func _save_and_main_menu() -> void:
	_finish_rebind(false)
	SettingsManager.apply_settings(_draft, true)
	_close(func() -> void: save_and_main_menu_requested.emit())


func _update_dirty_state() -> void:
	_dirty = _settings_signature(_draft) != _settings_signature(_initial_settings)


func _settings_signature(settings: Dictionary) -> String:
	var parts: Array[String] = []
	for key in ["master_volume", "music_volume", "sfx_volume", "fullscreen", "vsync_enabled", "window_size_index", "screen_shake_strength", "reduced_effects"]:
		parts.append("%s=%s" % [key, settings.get(key)])
	var bindings: Dictionary = settings.get("bindings", {})
	for action in SettingsManager.CONTROL_ACTIONS:
		parts.append("%s=%s" % [String(action), SettingsManager.format_binding_text(bindings.get(String(action), []))])
	return "|".join(parts)


func _rebuild_contents() -> void:
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	_build_contents()


func _request_close() -> void:
	_finish_rebind(false)
	if _dirty:
		_show_unsaved_dialog()
		return
	_close()


func _show_unsaved_dialog() -> void:
	if is_instance_valid(_discard_dialog):
		return
	var overlay := Control.new()
	overlay.name = "UnsavedChangesDialog"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_discard_dialog = overlay

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.004, 0.004, 0.008, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(center)
	var dialog := PanelContainer.new()
	dialog.name = "Panel"
	dialog.custom_minimum_size = Vector2(600, 280)
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(dialog)
	call_deferred("_animate_unsaved_dialog_enter", dialog)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	dialog.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	content.add_child(_make_label("未保存的设置", 26, SECTION_COLOR))
	var divider := HSeparator.new()
	divider.modulate = SECTION_COLOR
	content.add_child(divider)
	var message := _make_label("当前修改尚未保存。直接关闭不会应用这些设置。", 18, BODY_COLOR)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(message)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 12)
	content.add_child(buttons)
	var keep_editing := _make_button("继续编辑", Vector2(148, 46))
	keep_editing.pressed.connect(_dismiss_unsaved_dialog)
	buttons.add_child(keep_editing)
	var discard := _make_button("不保存关闭", Vector2(168, 46))
	discard.pressed.connect(_discard_and_close)
	buttons.add_child(discard)
	keep_editing.grab_focus()


func _dismiss_unsaved_dialog() -> void:
	var discard_dialog := _discard_dialog
	_discard_dialog = null
	if is_instance_valid(discard_dialog):
		CombatUiMotion.animate_first_panel_exit(discard_dialog, func() -> void:
			if is_instance_valid(discard_dialog):
				discard_dialog.queue_free()
		)


func _discard_and_close() -> void:
	_dismiss_unsaved_dialog()
	_close()


func _animate_unsaved_dialog_enter(dialog: PanelContainer) -> void:
	if is_instance_valid(dialog):
		CombatUiMotion.animate_panel_enter(dialog)


func _close(on_closed: Callable = Callable()) -> void:
	if _is_closing:
		return
	_is_closing = true
	CombatUiMotion.animate_first_panel_exit(self, func() -> void:
		closed.emit()
		if on_closed.is_valid():
			on_closed.call()
		queue_free()
	)


func _on_shade_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_request_close()
	elif event is InputEventScreenTouch and event.pressed:
		_request_close()
