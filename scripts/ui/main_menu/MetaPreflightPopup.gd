class_name MetaPreflightPopup
extends Control

signal closed
signal launch_requested

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")
const SECTION_COLOR := Color(0.32, 0.91, 1.0, 0.95)
const BODY_COLOR := Color(0.79, 0.88, 0.95, 1.0)
const MUTED_COLOR := Color(0.58, 0.72, 0.82, 1.0)
const PANEL_GUTTER := Vector2(96.0, 72.0)
const PANEL_MAX_SIZE := Vector2(1120.0, 760.0)
const COMPACT_LAYOUT_WIDTH := 980.0
const CALIBRATION_NAMES := {
	"wide_scan": "宽域扫描",
	"procurement_voucher": "采购凭证",
	"resonance_compass": "共振罗盘",
	"emergency_bulkhead": "应急隔舱",
	"overclock_lease": "超频租约",
	"frenzy_preheat": "过载预热",
	"salvage_probe": "打捞探针",
	"chaos_seed": "混沌种子",
}
const FAMILY_NAMES := {
	"colossus": "星间巨构",
	"paradise": "天堂号",
	"warped": "扭曲星核",
	"hell_eye": "地狱之眼",
	"divine": "神明使者",
}

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
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_refresh_panel_size()
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


func _on_viewport_size_changed() -> void:
	var was_compact := panel.custom_minimum_size.x < COMPACT_LAYOUT_WIDTH
	_refresh_panel_size()
	var is_compact := panel.custom_minimum_size.x < COMPACT_LAYOUT_WIDTH
	if was_compact != is_compact:
		_rebuild_contents()


func _refresh_panel_size() -> void:
	var available_size := get_viewport().get_visible_rect().size - PANEL_GUTTER
	panel.custom_minimum_size = available_size.max(Vector2.ONE).min(PANEL_MAX_SIZE)


func _build_contents() -> void:
	var margin := MarginContainer.new()
	margin.name = "PreflightMargin"
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "MainLayout"
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 58
	layout.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_box.add_child(_make_label(GameCopy.text(&"ui.preflight.kicker"), 16, Color(1.0, 0.72, 0.30, 1.0)))
	title_box.add_child(_make_label("出航预设", 32, Color(0.98, 1.0, 1.0, 1.0)))
	var close_button := _make_button("关闭", Vector2(128, 46))
	close_button.pressed.connect(_request_close)
	header.add_child(close_button)

	var divider := HSeparator.new()
	divider.modulate = SECTION_COLOR
	layout.add_child(divider)
	var guidance := _make_label("选择一项出航预设与出航难度。右侧详情会显示本次出航实际生效的效果。", 16, BODY_COLOR)
	guidance.name = "Guidance"
	layout.add_child(guidance)

	var content_area: Container = VBoxContainer.new() if _is_compact_layout() else HBoxContainer.new()
	content_area.name = "ContentArea"
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 16)
	layout.add_child(content_area)

	var selection_scroll := ScrollContainer.new()
	selection_scroll.name = "SelectionScroll"
	selection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	selection_scroll.add_theme_constant_override("scrollbar_h_separation", 10)
	selection_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selection_scroll.custom_minimum_size = Vector2(360, 0) if not _is_compact_layout() else Vector2(0, 248)
	content_area.add_child(selection_scroll)

	var selection_scroll_margin := MarginContainer.new()
	selection_scroll_margin.name = "SelectionScrollMargin"
	selection_scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_scroll_margin.add_theme_constant_override("margin_right", 18)
	selection_scroll.add_child(selection_scroll_margin)

	var selection_content := VBoxContainer.new()
	selection_content.name = "SelectionContent"
	selection_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_content.add_theme_constant_override("separation", 12)
	selection_scroll_margin.add_child(selection_content)
	_build_selection_contents(selection_content)

	var details_scroll := ScrollContainer.new()
	details_scroll.name = "DetailsScroll"
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_scroll.custom_minimum_size = Vector2(330, 0) if not _is_compact_layout() else Vector2(0, 236)
	content_area.add_child(details_scroll)
	_build_details_contents(details_scroll)

	var footer_divider := HSeparator.new()
	footer_divider.modulate = Color(SECTION_COLOR, 0.7)
	layout.add_child(footer_divider)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)
	var launch_button := _make_button("确认出航", Vector2(188, 50))
	launch_button.pressed.connect(_request_launch)
	footer.add_child(launch_button)
	launch_button.grab_focus()


func _build_selection_contents(parent: VBoxContainer) -> void:
	_add_section(parent, "出航预设")
	var calibration_grid := GridContainer.new()
	calibration_grid.name = "CalibrationGrid"
	calibration_grid.columns = 1
	calibration_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calibration_grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(calibration_grid)
	_add_calibration_button(calibration_grid, "", "不装配预设", true)
	for calibration_id in MetaProgression.CALIBRATION_IDS:
		_add_calibration_button(calibration_grid, calibration_id, String(CALIBRATION_NAMES.get(calibration_id, calibration_id)), progression.unlocked_calibrations.has(calibration_id))

	if _selected_calibration_id == "resonance_compass":
		_add_section(parent, "共振家族")
		var family_grid := GridContainer.new()
		family_grid.name = "FamilyGrid"
		family_grid.columns = 2
		family_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		family_grid.add_theme_constant_override("h_separation", 8)
		family_grid.add_theme_constant_override("v_separation", 8)
		parent.add_child(family_grid)
		for family_id in MetaProgression.FAMILY_IDS:
			var family_button := _make_button(String(FAMILY_NAMES.get(family_id, family_id)), Vector2(0, 42))
			CombatUiMotion.set_button_scale_enabled(family_button, false)
			family_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			family_button.toggle_mode = true
			family_button.button_pressed = family_id == _selected_calibration_family
			family_button.pressed.connect(_select_calibration_family.bind(family_id))
			family_grid.add_child(family_button)

	_add_section(parent, "出航难度")
	var crisis_grid := GridContainer.new()
	crisis_grid.name = "CrisisGrid"
	crisis_grid.columns = 4
	crisis_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crisis_grid.add_theme_constant_override("h_separation", 8)
	crisis_grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(crisis_grid)
	for level in range(progression.unlocked_crisis_level + 1):
		var crisis_button := _make_button("等级 %d" % level, Vector2(0, 42))
		CombatUiMotion.set_button_scale_enabled(crisis_button, false)
		crisis_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		crisis_button.toggle_mode = true
		crisis_button.button_pressed = level == _selected_crisis_level
		crisis_button.tooltip_text = "以出航难度 %d 出航" % level
		crisis_button.pressed.connect(_select_crisis.bind(level))
		crisis_grid.add_child(crisis_button)
	if progression.unlocked_crisis_level == 0:
		parent.add_child(_make_label("完成出航可逐步解锁更高出航难度。", 15, MUTED_COLOR))


func _build_details_contents(parent: ScrollContainer) -> void:
	var details_card := PanelContainer.new()
	details_card.name = "DetailsCard"
	details_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_card.add_theme_stylebox_override("panel", _detail_panel_style())
	parent.add_child(details_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	details_card.add_child(margin)

	var details := VBoxContainer.new()
	details.name = "DetailsContent"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 10)
	margin.add_child(details)
	_add_section(details, "当前预设详情")

	var selected_name := _make_label("未装配预设", 24, Color(0.98, 1.0, 1.0, 1.0))
	selected_name.name = "SelectedName"
	details.add_child(selected_name)
	var selection_status := _make_label("本次出航不会套用额外的预设效果。", 15, MUTED_COLOR)
	selection_status.name = "SelectionStatus"
	details.add_child(selection_status)

	if _selected_calibration_id.is_empty():
		_add_section(details, "出航难度")
		details.add_child(_make_label("当前选择：等级 %d" % _selected_crisis_level, 17, BODY_COLOR))
		return

	var calibration := progression.get_calibration_data(_selected_calibration_id)
	if calibration == null:
		selected_name.text = String(CALIBRATION_NAMES.get(_selected_calibration_id, _selected_calibration_id))
		selection_status.text = "预设数据暂时无法读取。"
		return

	selected_name.text = calibration.display_name if not calibration.display_name.is_empty() else String(CALIBRATION_NAMES.get(_selected_calibration_id, _selected_calibration_id))
	selection_status.text = "已选择，将在确认出航时套用。"
	if not calibration.description.is_empty():
		_add_section(details, "预设说明")
		details.add_child(_make_label(calibration.description, 16, BODY_COLOR))

	if _selected_calibration_id == "resonance_compass":
		_add_section(details, "共振家族")
		var target_text := "尚未指定；请从左侧选择一个敌方家族。"
		if not _selected_calibration_family.is_empty():
			target_text = "当前锁定：%s" % String(FAMILY_NAMES.get(_selected_calibration_family, _selected_calibration_family))
		details.add_child(_make_label(target_text, 16, BODY_COLOR if not _selected_calibration_family.is_empty() else Color(1.0, 0.72, 0.30, 1.0)))

	_add_section(details, "生效内容")
	var effect_list := VBoxContainer.new()
	effect_list.name = "EffectList"
	effect_list.add_theme_constant_override("separation", 6)
	details.add_child(effect_list)
	for effect_text in _describe_effects(calibration.effects):
		effect_list.add_child(_make_effect_row(effect_text))

	_add_section(details, "出航难度")
	details.add_child(_make_label("当前选择：等级 %d" % _selected_crisis_level, 17, BODY_COLOR))


func _describe_effects(effects: Dictionary) -> Array[String]:
	var descriptions: Array[String] = []
	if effects.has("map_intel_layers"):
		descriptions.append("航线情报显示 +%d 层" % int(effects["map_intel_layers"]))
	if effects.has("free_shop_rerolls"):
		descriptions.append("免费刷新商品 +%d 次" % int(effects["free_shop_rerolls"]))
	if effects.has("family_weight_mult"):
		descriptions.append("指定家族出现权重 ×%.1f" % float(effects["family_weight_mult"]))
	if effects.has("family_weight_draws"):
		descriptions.append("指定家族权重强化持续 %d 次抽取" % int(effects["family_weight_draws"]))
	if effects.has("general_weight_mult"):
		descriptions.append("通用敌人出现权重 ×%.1f" % float(effects["general_weight_mult"]))
	if effects.has("emergency_heal_threshold"):
		descriptions.append("生命首次降至 %d 时触发应急修复" % int(effects["emergency_heal_threshold"]))
	if effects.has("emergency_heal_amount"):
		descriptions.append("应急修复恢复 %d 点生命" % int(effects["emergency_heal_amount"]))
	if effects.has("invulnerable_seconds"):
		descriptions.append("触发后获得 %.1f 秒无敌" % float(effects["invulnerable_seconds"]))
	if effects.has("starting_mineral_debt"):
		descriptions.append("起始矿物债务 +%d" % int(effects["starting_mineral_debt"]))
	if effects.has("starting_compute_bonus"):
		descriptions.append("起始装配容量 +%d" % int(effects["starting_compute_bonus"]))
	if effects.has("shop_price_mult"):
		descriptions.append("商店价格 %+d%%" % roundi((float(effects["shop_price_mult"]) - 1.0) * 100.0))
	if effects.has("starting_heat"):
		descriptions.append("开局过载值 +%d" % int(effects["starting_heat"]))
	if effects.has("heat_cap_bonus"):
		descriptions.append("过载上限额外 +%d" % int(effects["heat_cap_bonus"]))
	if effects.has("healing_mult"):
		descriptions.append("治疗效果 %+d%%" % roundi((float(effects["healing_mult"]) - 1.0) * 100.0))
	if effects.has("mineral_mult"):
		descriptions.append("矿物收益 %+d%%" % roundi((float(effects["mineral_mult"]) - 1.0) * 100.0))
	if effects.has("patrol_enemy_cap_bonus"):
		descriptions.append("巡逻敌人数量上限 +%d" % int(effects["patrol_enemy_cap_bonus"]))
	if bool(effects.get("mark_high_value_targets", false)):
		descriptions.append("标记高价值目标")
	if bool(effects.get("grant_random_common_auxiliary", false)):
		descriptions.append("开局随机获得 1 件普通辅助装备")
	if bool(effects.get("uses_compute", false)):
		descriptions.append("该辅助装备会占用装配容量")
	if bool(effects.get("disable_stage_one_family_focus", false)):
		descriptions.append("第一阶段不再锁定敌方家族")
	if descriptions.is_empty():
		descriptions.append("该预设暂无可展示的数值效果。")
	return descriptions


func _make_effect_row(text: String) -> Label:
	var row := _make_label("• " + text, 16, BODY_COLOR)
	row.add_theme_stylebox_override("normal", _effect_row_style())
	row.add_theme_constant_override("outline_size", 0)
	return row


func _add_section(parent: VBoxContainer, text: String) -> void:
	var label := _make_label(text, 18, SECTION_COLOR)
	label.custom_minimum_size.y = 28
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	parent.add_child(label)


func _add_calibration_button(parent: GridContainer, calibration_id: String, label: String, unlocked: bool) -> void:
	var button := _make_button(label, Vector2(0, 46))
	CombatUiMotion.set_button_scale_enabled(button, false)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.toggle_mode = true
	button.button_pressed = calibration_id == _selected_calibration_id
	button.disabled = not unlocked
	button.tooltip_text = "点击选择此预设" if unlocked else "尚未解锁"
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
	CombatUiMotion.bind_tree(self)


func _is_compact_layout() -> bool:
	return panel.custom_minimum_size.x < COMPACT_LAYOUT_WIDTH


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_button(text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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


func _detail_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.11, 0.16, 0.92)
	style.border_color = Color(0.32, 0.91, 1.0, 0.46)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _effect_row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.20, 0.28, 0.54)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
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
