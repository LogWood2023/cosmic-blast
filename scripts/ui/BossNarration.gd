class_name BossNarration
extends RefCounted

static func show(owner: Node, boss_name: String, phase: StringName) -> void:
	if not is_instance_valid(owner):
		return
	var marker := "boss_narration_%s" % phase
	if owner.has_meta(marker):
		return
	owner.set_meta(marker, true)
	var layer := CanvasLayer.new()
	layer.layer = 96
	layer.name = "BossNarration_%s" % phase
	owner.add_child(layer)
	var label := Label.new()
	label.text = "%s\n%s" % [boss_name, _line_for(phase)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.offset_left = -390.0
	label.offset_top = 108.0
	label.offset_right = 390.0
	label.offset_bottom = 186.0
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.08, 1.0))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(label)
	var tween := owner.create_tween()
	tween.tween_interval(2.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(layer.queue_free)


static func _line_for(phase: StringName) -> String:
	match phase:
		&"intro": return "首领已锁定。先确认攻击范围，再寻找安全航线。"
		&"half": return "结构过半：首领正在调整攻击模式。"
		&"defeat": return "信号正在消散。方舟已记录本次交战数据。"
	return "方舟正在整理战斗记录。"
