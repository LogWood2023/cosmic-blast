extends Control

const EnemyCatalog := preload("res://scripts/entities/designed_enemies/DesignedEnemyCatalog.gd")

signal closed

var _content: VBoxContainer
var _tab_selector: OptionButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.03, 0.06, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close()
	)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 680)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(_label("方舟档案", 30, Color(0.95, 0.98, 1.0, 1.0)))
	titles.add_child(_label("在这里回看术语解释、敌人打法与已识别记录。", 16, Color(0.62, 0.78, 0.9, 1.0)))
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(120, 42)
	close_button.pressed.connect(_close)
	header.add_child(close_button)
	_tab_selector = OptionButton.new()
	_tab_selector.add_item("术语说明")
	_tab_selector.add_item("敌人档案")
	_tab_selector.item_selected.connect(_refresh)
	layout.add_child(_tab_selector)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)
	_refresh(0)


func _refresh(index: int) -> void:
	for child in _content.get_children():
		child.queue_free()
	if index == 0:
		_add_terms()
	else:
		_add_enemies()


func _add_terms() -> void:
	var terms := [
		["crisis_attention", "危机关注度", "完成节点会提高关注度；到达 5、12、21 时会出现首领并锁定普通航路。"],
		["departure_difficulty", "出航难度", "高阶危机的界面名称；每一等级都会累积一项额外规则。"],
		["equipment_capacity", "装配容量", "决定本次航程还能安装多少装备；每件装备会占用一定容量。"],
		["star_marrow", "星髓矿", "用于购买装备和刷新商品。"],
		["weapon_overload", "武器过载", "持续攻击会积累过载；充满后可进入强化状态。"],
		["family_bonus", "同家族加成", "装配同一家族的辅助装备后获得额外效果。"],
		["shop_preference", "商品偏好", "刷新商品时，更容易出现指定家族的装备。"],
	]
	for term in terms:
		MetaProgressionState.mark_codex_term_viewed(String(term[0]))
		_add_card(String(term[1]), String(term[2]), Color(0.18, 0.78, 1.0, 1.0))


func _add_enemies() -> void:
	for entry in EnemyCatalog.get_all_codex_entries():
		var enemy_id := String(entry.get("id", ""))
		if not MetaProgressionState.unlocked_codex_enemies.has(enemy_id):
			_add_card("未识别敌人", "在探索中首次遭遇后，方舟会写入它的打法与档案。", Color(0.45, 0.58, 0.68, 1.0))
			continue
		var body := "打法：%s\n档案：%s" % [String(entry.get("mechanic", "")), String(entry.get("archive", ""))]
		_add_card("%s · %s" % [String(entry.get("family", "")), String(entry.get("name", ""))], body, Color(1.0, 0.72, 0.3, 1.0))


func _add_card(title: String, body: String, accent: Color) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style(accent))
	_content.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 5)
	card.add_child(inner)
	inner.add_child(_label(title, 20, accent))
	inner.add_child(_label(body, 16, Color(0.9, 0.96, 1.0, 1.0)))


func _label(text: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.09, 0.14, 0.98)
	style.border_color = Color(0.25, 0.88, 1.0, 0.75)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style


func _card_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.16, 0.23, 0.9)
	style.border_color = Color(accent, 0.45)
	style.set_border_width_all(1)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	closed.emit()
	queue_free()
