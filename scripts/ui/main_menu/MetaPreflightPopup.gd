class_name MetaPreflightPopup
extends Control

signal closed
signal launch_requested

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")
const SECTION_COLOR := Color(0.32, 0.91, 1.0, 0.95)
const BODY_COLOR := Color(0.79, 0.88, 0.95, 1.0)
const CALIBRATION_NAMES := {
	"wide_scan": "宽域扫描",
	"procurement_voucher": "采购凭证",
	"resonance_compass": "共振罗盘",
	"emergency_bulkhead": "应急隔舱",
	"overclock_lease": "超频租约",
	"frenzy_preheat": "狂热预热",
	"salvage_probe": "打捞探针",
	"chaos_seed": "混沌种子",
}
const FAMILY_NAMES := {"colossus": "星间巨构", "paradise": "天堂号", "warped": "扭曲星核", "hell_eye": "地狱之眼", "divine": "神明使者"}

@onready var shade: ColorRect = $Shade
@onready var panel: PanelContainer = $CenterContainer/Panel

var progression: MetaProgression
var persist_selections := true
var _selected_calibration_id := ""
var _selected_calibration_family := ""
var _selected_crisis_level := 0
var _is_closing := false


func configure_for_progression(state: MetaProgression, should_persist: bool = false) -> void:
	progression = state
	persist_selections = should_persist


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if progression == null:
		progression = MetaProgressionState
	_selected_calibration_id = progression.selected_calibration_id
	_selected_calibration_family = progression.selected_calibration_family
	_selected_crisis_level = progression.selected_crisis_level
	shade.gui_input.connect(_on_shade_gui_input)
	_build_contents()
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)


func apply_selection(calibration_id: String, crisis_level: int, family_id: String = "") -> bool:
	if crisis_level < 0 or crisis_level > progression.unlocked_crisis_level:
		return false
	if calibration_id == "resonance_compass" and not MetaProgression.FAMILY_IDS.has(family_id):
		return false
	if calibration_id != "" and not progression.select_calibration(calibration_id):
		return false
	if calibration_id == "":
		progression.clear_calibration_selection()
	if calibration_id == "resonance_compass" and not progression.select_calibration_family(family_id):
		return false
	progression.select_crisis(crisis_level)
	_selected_calibration_id = progression.selected_calibration_id
	_selected_calibration_family = progression.selected_calibration_family
	_selected_crisis_level = progression.selected_crisis_level
	if persist_selections:
		progression.save_to_disk()
	return true


func _build_contents() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 58
	layout.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_box.add_child(_make_label("PREFLIGHT CONFIGURATION", 16, Color(1.0, 0.72, 0.30, 1.0)))
	title_box.add_child(_make_label("出航预设", 32, Color(0.98, 1.0, 1.0, 1.0)))
	var close_button := _make_button("返回", Vector2(128, 46))
	close_button.pressed.connect(_request_close)
	header.add_child(close_button)

	var divider := HSeparator.new()
	divider.modulate = SECTION_COLOR
	layout.add_child(divider)
	layout.add_child(_make_label("选择已解锁的校准协议，并设定本次航程的危机等级。未解锁项目会保留为只读状态。", 17, BODY_COLOR))

	_add_section(layout, "校准协议")
	var calibration_grid := GridContainer.new()
	calibration_grid.columns = 2
	calibration_grid.add_theme_constant_override("h_separation", 12)
	calibration_grid.add_theme_constant_override("v_separation", 10)
	layout.add_child(calibration_grid)
	_add_calibration_button(calibration_grid, "", "不使用校准", true)
	for calibration_id in MetaProgression.CALIBRATION_IDS:
		_add_calibration_button(calibration_grid, calibration_id, String(CALIBRATION_NAMES.get(calibration_id, calibration_id)), progression.unlocked_calibrations.has(calibration_id))
	if _selected_calibration_id == "resonance_compass":
		_add_section(layout, "共振家族")
		var family_row := HBoxContainer.new()
		family_row.add_theme_constant_override("separation", 10)
		layout.add_child(family_row)
		for family_id in MetaProgression.FAMILY_IDS:
			var family_button := _make_button(String(FAMILY_NAMES.get(family_id, family_id)), Vector2(148, 42))
			family_button.toggle_mode = true
			family_button.button_pressed = family_id == _selected_calibration_family
			family_button.pressed.connect(_select_calibration_family.bind(family_id))
			family_row.add_child(family_button)

	_add_section(layout, "危机等级")
	var crisis_row := HBoxContainer.new()
	crisis_row.add_theme_constant_override("separation", 10)
	layout.add_child(crisis_row)
	for level in range(progression.unlocked_crisis_level + 1):
		var crisis_button := _make_button("%d" % level, Vector2(64, 42))
		crisis_button.toggle_mode = true
		crisis_button.button_pressed = level == _selected_crisis_level
		crisis_button.tooltip_text = "危机等级 %d" % level
		crisis_button.pressed.connect(_select_crisis.bind(level))
		crisis_row.add_child(crisis_button)
	if progression.unlocked_crisis_level == 0:
		crisis_row.add_child(_make_label("完成首领战以解锁更高危机等级。", 16, Color(0.58, 0.72, 0.82, 1.0)))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)
	var launch_button := _make_button("确认并开始", Vector2(188, 50))
	launch_button.pressed.connect(_request_launch)
	footer.add_child(launch_button)
	launch_button.grab_focus()


func _add_section(parent: VBoxContainer, text: String) -> void:
	var label := _make_label(text, 20, SECTION_COLOR)
	label.custom_minimum_size.y = 32
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	parent.add_child(label)


func _add_calibration_button(parent: GridContainer, calibration_id: String, label: String, unlocked: bool) -> void:
	var button := _make_button(label, Vector2(420, 46))
	button.toggle_mode = true
	button.button_pressed = calibration_id == _selected_calibration_id
	button.disabled = not unlocked
	button.tooltip_text = "已解锁" if unlocked else "尚未解锁"
	button.pressed.connect(_select_calibration.bind(calibration_id))
	parent.add_child(button)


func _select_calibration(calibration_id: String) -> void:
	_selected_calibration_id = calibration_id
	if calibration_id != "resonance_compass":
		_selected_calibration_family = ""
	_rebuild_contents()


func _select_calibration_family(family_id: String) -> void:
	_selected_calibration_family = family_id
	_rebuild_contents()


func _select_crisis(level: int) -> void:
	_selected_crisis_level = level
	_rebuild_contents()


func _request_launch() -> void:
	if not apply_selection(_selected_calibration_id, _selected_crisis_level, _selected_calibration_family):
		push_warning("Unable to apply selected meta progression options.")
		return
	_close(func() -> void: launch_requested.emit())


func _rebuild_contents() -> void:
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	_build_contents()


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_button(text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_ALL
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


func _request_close() -> void:
	_close()


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
