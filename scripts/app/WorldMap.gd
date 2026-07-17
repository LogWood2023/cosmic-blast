extends Control

const SHOP_POPUP_SCENE := preload("res://scenes/ui/world_map/ShopPopup.tscn")
const HANGAR_POPUP_SCENE := preload("res://scenes/ui/world_map/HangarPopup.tscn")
const EVENT_CHOICE_POPUP_SCENE := preload("res://scenes/ui/world_map/EventChoicePopup.tscn")
const REWARD_CACHE_CHOICE_POPUP_SCENE := preload("res://scenes/ui/world_map/RewardCacheChoicePopup.tscn")
const BOSS_REWARD_POPUP_SCENE := preload("res://scenes/ui/world_map/BossRewardPopup.tscn")
const SPECIAL_BONUS_POPUP_SCENE := preload("res://scenes/ui/world_map/SpecialBonusPopup.tscn")
const SETTINGS_POPUP_SCENE := preload("res://scenes/ui/main_menu/SettingsPopup.tscn")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")
const NODE_INTRO_TAG_FONT_SIZE := 40

var _selected_node_id: int = RunManager.CENTER_ID
var _message: String = ""
var _active_popup: Control
var _pending_event_node_id: int = -1
var _pending_event_seed: int = -1
var _pending_reward_node_id: int = -1
var _pending_reward_seed: int = -1
var _pending_boss_reward_popup_summary: Dictionary = {}
var _pending_special_bonus_popup_summary: Dictionary = {}
var _startup_popup_queue: Array[Callable] = []

@onready var crisis_segments: HBoxContainer = $TopBar/CrisisSegments
@onready var crisis_warning_tape: Control = $CrisisWarningMask/CrisisWarningTape
@onready var crisis_alert_overlay: Control = $CrisisAlertOverlay
@onready var map_viewport: Control = $MapViewport
@onready var details_panel: Panel = $DetailsPanel
@onready var details_title: Label = $DetailsPanel/DetailsTitle
@onready var details_body: RichTextLabel = $DetailsPanel/DetailsBody
@onready var route_directive_rows: Array[HBoxContainer] = [
	$DetailsPanel/RouteDirectivePanel/Row1,
	$DetailsPanel/RouteDirectivePanel/Row2,
	$DetailsPanel/RouteDirectivePanel/Row3,
]
@onready var action_button: Button = $DetailsPanel/ActionButton
@onready var shop_button: Button = $ShopButton
@onready var hangar_button: Button = $HangarButton
@onready var message_label: Label = $MessageLabel
@onready var settings_button: Button = $SettingsButton


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	if not RunManager.is_formal_run_active():
		RunManager.start_new_run()
	var alert_intro_family: String = ""
	if RunManager.has_method("consume_crisis_alert_intro") and RunManager.call("consume_crisis_alert_intro"):
		alert_intro_family = String(RunManager.call("get_alert_boss_family"))
	# 回到世界地图即为一个干净的存档点，写盘保存本局进度
	RunManager.save_run()
	_consume_node_completion_feedback()
	action_button.pressed.connect(_on_enter_pressed)
	shop_button.pressed.connect(_show_shop)
	hangar_button.pressed.connect(_show_hangar)
	settings_button.pressed.connect(_show_settings)
	map_viewport.connect("node_selected", _on_map_node_selected)
	map_viewport.call("reset_view")
	_refresh_all()
	if not alert_intro_family.is_empty():
		call_deferred("_play_crisis_alert_intro", alert_intro_family)
	# 入场弹窗排队依次展示；此前三个同帧打开会互相 queue_free，玩家只看到最后一个
	if not _pending_special_bonus_popup_summary.is_empty():
		_startup_popup_queue.append(_show_pending_special_bonus_popup)
	# BossVictoryTransition keeps its cover up and owns the reward picker until a
	# choice is made. Other entries (such as a resumed save) still use the map UI.
	if not BossVictoryTransition.is_waiting_for_boss_reward():
		if not _pending_boss_reward_popup_summary.is_empty():
			_startup_popup_queue.append(_show_pending_boss_reward_popup)
		elif RunManager.has_method("get_pending_boss_reward_summary"):
			_pending_boss_reward_popup_summary = Dictionary(RunManager.get_pending_boss_reward_summary())
			if not _pending_boss_reward_popup_summary.is_empty():
				_startup_popup_queue.append(_show_pending_boss_reward_popup)
	if not _startup_popup_queue.is_empty() and not BossVictoryTransition.is_waiting_for_boss_reward():
		call_deferred("_show_next_startup_popup")


func _play_crisis_alert_intro(family: String) -> void:
	if crisis_alert_overlay.has_method("play_alert"):
		crisis_alert_overlay.call("play_alert", family)


func _consume_node_completion_feedback() -> void:
	var messages: Array[String] = []
	# 危机播报优先（docs/lore/02）：探索归来若危机变化，先亮播报再报结算。
	if RunManager.has_method("consume_crisis_broadcast"):
		var crisis_broadcast := String(RunManager.call("consume_crisis_broadcast"))
		if not crisis_broadcast.is_empty():
			messages.append(crisis_broadcast)
	var node_feedback := _consume_explore_completion_feedback()
	if not node_feedback.is_empty():
		messages.append(node_feedback)
	var boss_feedback := _consume_boss_completion_feedback()
	if not boss_feedback.is_empty():
		messages.append(boss_feedback)
	if not messages.is_empty():
		_message = "\n".join(messages)


func _consume_explore_completion_feedback() -> String:
	if not RunManager.has_method("consume_last_node_completion_summary"):
		return ""
	var summary := Dictionary(RunManager.call("consume_last_node_completion_summary"))
	if summary.is_empty() or not bool(summary.get("ok", false)):
		return ""
	var lines: Array[String] = []
	var minerals_committed := int(summary.get("minerals_committed", 0))
	if minerals_committed > 0:
		lines.append("回收星髓矿 +%d" % minerals_committed)
	var activated_specials: Array = summary.get("activated_specials", [])
	var activated_names: Array[String] = []
	if not activated_specials.is_empty():
		if RunManager.has_method("get_special_bonus_display_names"):
			activated_names = RunManager.call("get_special_bonus_display_names", activated_specials)
		else:
			for bonus_id in activated_specials:
				activated_names.append(String(bonus_id))
		if not activated_names.is_empty():
			lines.append("新增信标：%s" % "、".join(activated_names))
	var beacon_echo_feedback := _make_beacon_echo_feedback(summary)
	if not beacon_echo_feedback.is_empty():
		lines.append(beacon_echo_feedback)
	if not activated_names.is_empty():
		_pending_special_bonus_popup_summary = {
			"activated_names": activated_names,
			"beacon_echo_routes": Array(summary.get("beacon_echo_routes", [])).duplicate(true),
		}
	var contract_feedback := _make_contract_completion_feedback(summary)
	if not contract_feedback.is_empty():
		lines.append(contract_feedback)
	var expired_feedback := _make_expired_contract_feedback(summary)
	if not expired_feedback.is_empty():
		lines.append(expired_feedback)
	if lines.is_empty():
		return ""
	return "撤离结算完成。%s。" % "；".join(lines)


func _consume_boss_completion_feedback() -> String:
	if not RunManager.has_method("consume_last_boss_completion_summary"):
		return ""
	var summary := Dictionary(RunManager.call("consume_last_boss_completion_summary"))
	if summary.is_empty() or not bool(summary.get("ok", false)):
		return ""
	if not BossVictoryTransition.is_waiting_for_boss_reward():
		_pending_boss_reward_popup_summary = summary.duplicate(true)
	return _make_boss_completion_feedback(summary)


func _make_boss_completion_feedback(summary: Dictionary) -> String:
	var family_name := String(summary.get("family_name", "")).strip_edges()
	if family_name.is_empty():
		family_name = _family_display_name(String(summary.get("family", "")))
	var lines: Array[String] = []
	if family_name.is_empty():
		lines.append("执行体肃清：危机残响已封存")
	else:
		lines.append("执行体肃清：%s残响已封存" % family_name)
	var item_name := String(summary.get("item_name", "")).strip_edges()
	if not item_name.is_empty():
		lines.append("缴获纹章：%s" % item_name)
	var aftershock_text := String(summary.get("boss_aftershock_text", "")).strip_edges()
	if not aftershock_text.is_empty():
		lines.append(aftershock_text)
	var shop_focus_text := String(summary.get("shop_focus_text", "")).strip_edges()
	if not shop_focus_text.is_empty():
		lines.append(shop_focus_text)
	return "%s。" % "；".join(lines)


func _make_beacon_echo_feedback(summary: Dictionary) -> String:
	var echo_routes: Array = summary.get("beacon_echo_routes", [])
	if echo_routes.is_empty():
		return ""
	var parts: Array[String] = []
	for raw_route in echo_routes:
		var route := Dictionary(raw_route)
		var node_name := String(route.get("node_name", "")).strip_edges()
		if node_name.is_empty():
			continue
		var family_name := String(route.get("family_name", "")).strip_edges()
		var equipment_bonus := float(route.get("equipment_bonus", 0.0))
		var reward_bonus := float(route.get("reward_bonus", 0.0))
		var effects: Array[String] = []
		if not family_name.is_empty():
			effects.append(family_name)
		if equipment_bonus > 0.0:
			effects.append("装备检出 +%d%%" % int(round(equipment_bonus * 100.0)))
		if reward_bonus > 0.0:
			effects.append("矿物倍率 +%.2f" % reward_bonus)
		if effects.is_empty():
			parts.append(node_name)
		else:
			parts.append("%s（%s）" % [node_name, "、".join(effects)])
	if parts.is_empty():
		return ""
	return "回响航线：%s" % "，".join(parts)


func _make_contract_completion_feedback(summary: Dictionary) -> String:
	var applied: Array = summary.get("event_contracts_applied", [])
	if applied.is_empty():
		return ""
	var parts: Array[String] = []
	for raw_contract in applied:
		var contract := Dictionary(raw_contract)
		var title := String(contract.get("title", "")).strip_edges()
		if title.is_empty():
			continue
		var effects: Array[String] = []
		var minerals_added := int(contract.get("minerals_added", 0))
		if minerals_added > 0:
			effects.append("矿物 +%d" % minerals_added)
		var crisis_added := int(contract.get("crisis_added", 0))
		if crisis_added > 0:
			effects.append("危机 +%d" % crisis_added)
		if effects.is_empty():
			continue
		parts.append("%s（%s）" % [title, "、".join(effects)])
	if parts.is_empty():
		return ""
	return "契约回响：%s" % "，".join(parts)


func _make_route_momentum_feedback(summary: Dictionary) -> String:
	var applied := Dictionary(summary.get("route_momentum_applied", {}))
	var activated := Dictionary(summary.get("route_momentum_activated", {}))
	var expired := Dictionary(summary.get("expired_route_momentum", {}))
	var parts: Array[String] = []
	var minerals_added := int(applied.get("minerals_added", 0))
	if minerals_added > 0:
		parts.append("本次回收 +%d" % minerals_added)
	var activation_text := String(activated.get("activation_text", "")).strip_edges()
	if activation_text.is_empty() and not activated.is_empty():
		var remaining := int(activated.get("remaining_nodes", 0))
		var effects := String(activated.get("effects_text", "回收效率提高"))
		activation_text = "已点燃，剩余 %d 节点，%s" % [remaining, effects]
	if not activation_text.is_empty():
		parts.append(activation_text)
	if not expired.is_empty() and activated.is_empty():
		parts.append("余波已收束")
	if parts.is_empty():
		return ""
	return "航路动能：%s" % "，".join(parts)


func _make_route_directive_completion_feedback(summary: Dictionary) -> String:
	var completed_directives: Array = summary.get("completed_route_directives", [])
	var new_directives: Array = summary.get("new_route_directives", [])
	var route_momentum := Dictionary(summary.get("route_momentum_activated", {}))
	if completed_directives.is_empty() and new_directives.is_empty() and route_momentum.is_empty():
		return ""
	var names: Array[String] = []
	for raw_directive in completed_directives:
		var directive := Dictionary(raw_directive)
		var title := String(directive.get("title", "")).strip_edges()
		if not title.is_empty():
			names.append(title)
	if names.is_empty():
		return "航路指令已更新：方舟补发了新的航路目标。"
	var suffix := ""
	if not new_directives.is_empty():
		suffix = "，新的航路目标已入列"
	if not route_momentum.is_empty():
		suffix += "，航路动能已点燃"
	return "航路指令完成：%s%s" % ["、".join(names), suffix]


func _make_expired_contract_feedback(summary: Dictionary) -> String:
	var expired_contracts: Array = summary.get("expired_event_contracts", [])
	if expired_contracts.is_empty():
		return ""
	var names: Array[String] = []
	for raw_contract in expired_contracts:
		var contract := Dictionary(raw_contract)
		var title := String(contract.get("title", "")).strip_edges()
		if not title.is_empty() and not names.has(title):
			names.append(title)
	if names.is_empty():
		var expired_count := int(summary.get("expired_event_contract_count", 0))
		return "契约到期：%d 项" % expired_count if expired_count > 0 else ""
	return "契约到期：%s" % "、".join(names)


func _on_map_node_selected(node_id: int) -> void:
	if is_instance_valid(_active_popup):
		return
	_selected_node_id = node_id
	_message = ""
	_refresh_all()


func _refresh_all() -> void:
	_refresh_top_bar()
	_refresh_details()
	_refresh_route_directives()
	message_label.text = _message
	map_viewport.call("refresh_map", _selected_node_id)


func _refresh_route_directives() -> void:
	var summaries: Array = RunManager.get_route_directive_summaries()
	for index in range(route_directive_rows.size()):
		var row := route_directive_rows[index]
		var task_label := row.get_node("Task") as Label
		var reward_label := row.get_node("Reward") as Label
		if index >= summaries.size():
			row.visible = false
			continue
		var summary := Dictionary(summaries[index])
		row.visible = true
		task_label.text = String(summary.get("description", "击毁精英敌机"))
		reward_label.text = str(int(summary.get("reward_minerals", 0)))


func _refresh_top_bar() -> void:
	_refresh_crisis_segments()


func _refresh_crisis_segments() -> void:
	var thresholds: Array[int] = RunManager.CRISIS_THRESHOLDS
	var previous_threshold := 0
	for threshold in thresholds:
		var alert_is_pending := RunManager.crisis_level == threshold and not RunManager.cleared_crisis_thresholds.has(threshold)
		if RunManager.crisis_level < threshold or alert_is_pending:
			var span: int = maxi(1, threshold - previous_threshold)
			var filled_segments := clampi(RunManager.crisis_level - previous_threshold, 0, span)
			_update_crisis_segments(span, filled_segments, alert_is_pending)
			_set_crisis_warning_active(RunManager.is_alert_active())
			return
		previous_threshold = threshold
	_update_crisis_segments(1, 1, true)
	_set_crisis_warning_active(RunManager.is_alert_active())


func _set_crisis_warning_active(is_active: bool) -> void:
	if crisis_warning_tape.has_method("set_alert_active"):
		crisis_warning_tape.call("set_alert_active", is_active)


func _update_crisis_segments(segment_count: int, filled_segments: int, alert_is_pending: bool) -> void:
	if crisis_segments.get_child_count() != segment_count:
		for child in crisis_segments.get_children():
			crisis_segments.remove_child(child)
			child.queue_free()
		for _index in segment_count:
			var segment := Panel.new()
			segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
			crisis_segments.add_child(segment)
	for index in segment_count:
		var segment := crisis_segments.get_child(index) as Panel
		segment.add_theme_stylebox_override("panel", _make_crisis_segment_style(index < filled_segments, alert_is_pending))


func _make_crisis_segment_style(is_filled: bool, alert_is_pending: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	if is_filled:
		style.bg_color = Color(1.0, 0.12, 0.12, 0.98) if alert_is_pending else Color(0.84, 0.07, 0.11, 0.96)
		style.border_color = Color(1.0, 0.68, 0.48, 1.0)
		style.shadow_color = Color(1.0, 0.03, 0.05, 0.36)
		style.shadow_size = 5
	else:
		style.bg_color = Color(0.075, 0.012, 0.025, 0.96)
		style.border_color = Color(0.55, 0.12, 0.14, 0.72)
	return style


func _get_active_special_bonus_count() -> int:
	if RunManager.has_method("get_active_special_bonus_summaries"):
		return RunManager.get_active_special_bonus_summaries().size()
	return RunManager.active_special_bonus_ids.size()


func _get_active_special_beacon_resonance_count() -> int:
	if RunManager.has_method("get_active_special_beacon_resonance_summaries"):
		return RunManager.get_active_special_beacon_resonance_summaries().size()
	return 0


func _get_active_event_contract_count() -> int:
	if RunManager.has_method("get_active_event_contract_summaries"):
		return RunManager.get_active_event_contract_summaries().size()
	if RunManager.has_method("get_active_event_contracts"):
		return RunManager.get_active_event_contracts().size()
	return 0


func _get_active_route_directive_count() -> int:
	if not RunManager.has_method("get_route_directive_summaries"):
		return 0
	var count := 0
	for raw_summary in RunManager.get_route_directive_summaries():
		if not bool(Dictionary(raw_summary).get("completed", false)):
			count += 1
	return count


func _get_active_route_momentum() -> Dictionary:
	if not RunManager.has_method("get_active_route_momentum_summary"):
		return {}
	return Dictionary(RunManager.call("get_active_route_momentum_summary"))


func _get_active_run_condition_count() -> int:
	if not RunManager.has_method("get_active_run_condition_summaries"):
		return 0
	return RunManager.get_active_run_condition_summaries().size()


func _refresh_details() -> void:
	var node := RunManager.get_map_node(_selected_node_id)
	if node.is_empty():
		return
	var node_type := String(node.get("type", ""))
	details_title.text = String(node.get("name", "未知节点"))
	var lines: Array[String] = [
		"[font_size=%d][color=#52e8ff][b][i]%s[/i][/b][/color][/font_size]" % [NODE_INTRO_TAG_FONT_SIZE, _node_intro_type_name(node_type)],
		"",
		_node_flavor_text(node, node_type),
	]
	var is_base := _selected_node_id == RunManager.CENTER_ID
	if is_base and RunManager.is_alert_active() and RunManager.has_method("get_alert_boss_preview"):
		var boss_preview: Dictionary = Dictionary(RunManager.call("get_alert_boss_preview"))
		if not boss_preview.is_empty():
			var boss_name: String = String(boss_preview.get("name", "未知执行体"))
			details_title.text = "危机警报 // %s" % boss_name
			lines.append("")
			lines.append("[color=#ff4f6a][b]执行体锁定：%s[/b][/color]" % boss_name)
			lines.append(String(boss_preview.get("test_text", "测试通告：未知执行体正在接近。")))
	details_body.text = "\n".join(lines)
	action_button.visible = true
	action_button.disabled = false
	if is_base:
		action_button.text = "进入执行体战斗"
		action_button.visible = RunManager.is_alert_active()
		action_button.disabled = not RunManager.is_alert_active()
	elif node_type == RunManager.NODE_SPECIAL:
		action_button.visible = false
	else:
		action_button.text = "进入节点"
		action_button.disabled = not RunManager.is_node_accessible(_selected_node_id)


func _node_intro_type_name(node_type: String) -> String:
	match node_type:
		RunManager.NODE_BATTLE:
			return "战斗"
		RunManager.NODE_REWARD:
			return "奖励事件"
		RunManager.NODE_EVENT:
			return "事件"
		RunManager.NODE_SPECIAL:
			return "特殊信标"
		RunManager.NODE_BASE:
			return "方舟核心"
	return "未知"


func _node_flavor_text(node: Dictionary, node_type: String) -> String:
	match node_type:
		RunManager.NODE_BATTLE:
			return String(node.get("battle_description", "敌方巡逻信号活跃。"))
		RunManager.NODE_REWARD:
			return String(node.get("reward_description", "发现一批可立即回收的遗失补给。"))
		RunManager.NODE_EVENT:
			return String(node.get("intel_description", "异常信号等待处置。"))
		RunManager.NODE_SPECIAL:
			return String(node.get("bonus_description", "接入后提供整局加成。"))
		RunManager.NODE_BASE:
			return "方舟核心维系未明星域中的航线与补给。"
	return "尚未识别的空间残片。"


func _append_route_plan_lines(lines: Array[String], node: Dictionary) -> void:
	var plan: Dictionary = node.get("route_plan", {})
	if plan.is_empty():
		return
	var title := String(plan.get("title", "航路预案"))
	var summary := String(plan.get("summary", "方舟已完成该节点的航路测算。"))
	var family_name := String(plan.get("family_name", "通用"))
	var reward_hint := String(plan.get("reward_hint", "回收收益稳定。"))
	var equipment_hint := String(plan.get("equipment_hint", "装备信号稳定。"))
	var ore_source_hint := String(plan.get("ore_source_hint", "矿源：星髓矿脉，回收队会优先标记附近晶体反应。"))
	var tactic_hint := String(plan.get("tactic_hint", "通用回路，优先补齐武器、机动和回收余量。"))
	lines.append("[b]航路预案：[/b]%s" % title)
	lines.append("流派：%s。%s" % [family_name, summary])
	lines.append("推荐战法：%s" % tactic_hint)
	lines.append("回收：%s" % reward_hint)
	lines.append("矿源：%s" % ore_source_hint.trim_prefix("矿源："))
	lines.append("装备：%s" % equipment_hint)


func _append_ore_source_room_effect_lines(lines: Array[String], node: Dictionary) -> void:
	var effect_text := String(node.get("ore_source_room_effect_text", "")).strip_edges()
	if effect_text.is_empty():
		return
	lines.append("[b]矿区回声：[/b]%s" % effect_text)


func _append_opportunity_lines(lines: Array[String], node: Dictionary) -> void:
	var opportunity := Dictionary(node.get("opportunity", {}))
	if opportunity.is_empty():
		return
	var title := String(opportunity.get("title", "航行机会")).strip_edges()
	var description := String(opportunity.get("description", "")).strip_edges()
	var effects_text := String(opportunity.get("effects_text", "")).strip_edges()
	var tags: Array = opportunity.get("tags", [])
	var tag_text := ""
	if not tags.is_empty():
		tag_text = "  [color=#52e8ff]%s[/color]" % " / ".join(tags)
	lines.append("[b]航行机会：[/b]%s%s" % [title, tag_text])
	if not description.is_empty():
		lines.append(description)
	if not effects_text.is_empty():
		lines.append("· %s" % effects_text)


func _append_beacon_echo_lines(lines: Array[String], node: Dictionary) -> void:
	var echo: Dictionary = node.get("beacon_echo", {})
	if echo.is_empty():
		return
	var bonus_name := String(echo.get("bonus_name", "方舟信标协议"))
	var family_name := String(echo.get("family_name", _family_display_name(String(echo.get("family_bias", "")))))
	var equipment_bonus := float(echo.get("equipment_bonus", 0.0))
	var reward_bonus := float(echo.get("reward_bonus", 0.0))
	lines.append("[b]信标回响：[/b]%s" % bonus_name)
	lines.append("方舟航图已被%s染色，邻近航线更容易检出同调纹章。" % family_name)
	var effects: Array[String] = []
	if equipment_bonus > 0.0:
		effects.append("装备检出 +%d%%" % int(round(equipment_bonus * 100.0)))
	if reward_bonus > 0.0:
		effects.append("矿物倍率 +%.2f" % reward_bonus)
	if not effects.is_empty():
		lines.append("· %s" % " / ".join(effects))


func _append_reward_cache_calibration_lines(lines: Array[String], node: Dictionary) -> void:
	var calibration: Dictionary = node.get("reward_cache_route_calibration", {})
	if calibration.is_empty():
		return
	var family_name := String(calibration.get("family_name", _family_display_name(String(calibration.get("family_bias", "")))))
	var focus_text := String(calibration.get("shop_focus_text", "货单导向")).strip_edges()
	var calibration_text := String(calibration.get("calibration_text", "")).strip_edges()
	lines.append("[b]缓存校准：[/b]%s" % family_name)
	if calibration_text.is_empty():
		lines.append("%s已沿相邻航线同步，%s正在接管方舟货单。" % [family_name, focus_text])
	else:
		lines.append(calibration_text)
	var effects: Array[String] = []
	var equipment_bonus := float(calibration.get("equipment_bonus", 0.0))
	var reward_bonus := float(calibration.get("reward_bonus", 0.0))
	if equipment_bonus > 0.0:
		effects.append("装备检出 +%d%%" % int(round(equipment_bonus * 100.0)))
	if reward_bonus > 0.0:
		effects.append("矿物倍率 +%.2f" % reward_bonus)
	if not effects.is_empty():
		lines.append("· %s / %s" % [focus_text, " / ".join(effects)])


func _append_boss_aftershock_lines(lines: Array[String], node: Dictionary) -> void:
	var aftershock: Dictionary = node.get("boss_aftershock", {})
	if aftershock.is_empty():
		return
	var family_name := String(aftershock.get("family_name", _family_display_name(String(aftershock.get("family_bias", "")))))
	var focus_text := String(aftershock.get("shop_focus_text", "货单导向")).strip_edges()
	var aftershock_text := String(aftershock.get("aftershock_text", "")).strip_edges()
	lines.append("[b]执行体余波：[/b]%s" % family_name)
	if aftershock_text.is_empty():
		lines.append("%s残响压入航图，%s正在改写下一段货单。" % [family_name, focus_text])
	else:
		lines.append(aftershock_text)
	var effects: Array[String] = []
	var equipment_bonus := float(aftershock.get("equipment_bonus", 0.0))
	var reward_bonus := float(aftershock.get("reward_bonus", 0.0))
	if equipment_bonus > 0.0:
		effects.append("装备检出 +%d%%" % int(round(equipment_bonus * 100.0)))
	if reward_bonus > 0.0:
		effects.append("矿物倍率 +%.2f" % reward_bonus)
	if not effects.is_empty():
		lines.append("· %s / %s" % [focus_text, " / ".join(effects)])


func _append_run_condition_lines(lines: Array[String], node: Dictionary) -> void:
	var conditions: Array = node.get("run_conditions", [])
	if conditions.is_empty():
		return
	lines.append("[b]航域态势：[/b]")
	for raw_condition in conditions:
		var condition := Dictionary(raw_condition)
		var title := String(condition.get("title", "未知态势"))
		var description := String(condition.get("description", "航域参数已改写。"))
		var effects_text := String(condition.get("effects_text", ""))
		lines.append("· %s" % title)
		if effects_text.is_empty():
			lines.append(description)
		else:
			lines.append("%s（%s）" % [description, effects_text])


func _append_modifier_lines(lines: Array[String], node: Dictionary) -> void:
	var modifiers: Array = node.get("modifiers", [])
	if modifiers.is_empty():
		return
	lines.append("[b]航域扰动：[/b]")
	for raw_modifier in modifiers:
		var modifier := Dictionary(raw_modifier)
		var title := String(modifier.get("title", "未知扰动"))
		var description := String(modifier.get("description", "航域数据异常。"))
		var tags: Array = modifier.get("tags", [])
		var tag_text := ""
		if not tags.is_empty():
			tag_text = "  [color=#52e8ff]%s[/color]" % " / ".join(tags)
		lines.append("· %s%s" % [title, tag_text])
		lines.append(description)


func _append_active_event_contract_lines(lines: Array[String]) -> void:
	if not RunManager.has_method("get_active_event_contract_summaries"):
		return
	var summaries: Array = RunManager.get_active_event_contract_summaries()
	if summaries.is_empty():
		return
	lines.append("")
	lines.append("[b]航路契约：[/b]")
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		var title := String(summary.get("title", "航路契约"))
		var remaining := int(summary.get("remaining_nodes", 0))
		var family_name := String(summary.get("family_name", "通用航路"))
		var effects_text := String(summary.get("effects_text", "航路参数已改写"))
		var description := String(summary.get("description", ""))
		lines.append("• %s（%s，剩余 %d 节点）：%s" % [title, family_name, remaining, effects_text])
		if not description.is_empty():
			lines.append(description)


func _append_active_route_momentum_lines(lines: Array[String]) -> void:
	var summary := _get_active_route_momentum()
	if summary.is_empty():
		return
	lines.append("")
	lines.append("[b]航路动能：[/b]")
	var remaining := int(summary.get("remaining_nodes", 0))
	var effects_text := String(summary.get("effects_text", "回收效率提高"))
	lines.append("• 余波仍在推进，剩余 %d 个完成节点：%s" % [remaining, effects_text])


func _append_active_special_bonus_lines(lines: Array[String]) -> void:
	if not RunManager.has_method("get_active_special_bonus_summaries"):
		return
	var summaries: Array = RunManager.call("get_active_special_bonus_summaries")
	if summaries.is_empty():
		lines.append("")
		lines.append("[color=#7f8ca8]已接入协议：暂无。[/color]")
		return
	lines.append("")
	lines.append("[b]已接入协议：[/b]")
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		var name := String(summary.get("name", "未知协议"))
		var effects_text := String(summary.get("effects_text", "方舟协议已接入"))
		lines.append("• %s：%s" % [name, effects_text])


func _append_active_special_beacon_resonance_lines(lines: Array[String]) -> void:
	if not RunManager.has_method("get_active_special_beacon_resonance_summaries"):
		return
	var summaries: Array = RunManager.call("get_active_special_beacon_resonance_summaries")
	if summaries.is_empty():
		return
	lines.append("")
	lines.append("[b]信标共鸣：[/b]")
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		var name := String(summary.get("name", "信标共鸣"))
		var effects_text := String(summary.get("effects_text", "方舟协议正在共振"))
		lines.append("• %s：%s" % [name, effects_text])


func _append_route_directive_lines(lines: Array[String]) -> void:
	if not RunManager.has_method("get_route_directive_summaries"):
		return
	var summaries: Array = RunManager.get_route_directive_summaries()
	if summaries.is_empty():
		return
	lines.append("")
	lines.append("[b]航路指令：[/b]")
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		var title := String(summary.get("title", "航路指令"))
		var progress := String(summary.get("progress_text", "进度 0/1"))
		var reward := String(summary.get("reward_text", "方舟补给"))
		var state := "已完成" if bool(summary.get("completed", false)) else progress
		lines.append("• %s（%s）：%s" % [title, state, reward])


func _node_description(node_type: String) -> String:
	match node_type:
		RunManager.NODE_BATTLE:
			return "五席遗留军团巡逻区。进入后需要寻找资源并撤离。"
		RunManager.NODE_EVENT:
			return "旧时代记录或异常协议。选择一个处置方案后，航路会立刻封存。"
		RunManager.NODE_REWARD:
			return "遗失补给事件。选择一项补给后，航路会立刻封存。"
		RunManager.NODE_SPECIAL:
			return "航路增益信标。打通相邻连线后，会为本局提供持续加成。"
	return "尚未识别的空间残片。"


func _family_display_name(family: String) -> String:
	match family:
		"colossus":
			return "星间巨构 / 冲刺碰撞流"
		"paradise":
			return "天堂号 / 火力覆盖流"
		"warped":
			return "扭曲星核 / 引力流"
		"hell_eye":
			return "地狱之眼 / 狂热流"
		"divine":
			return "神明使者 / 无人机流"
	return "通用"


func _on_enter_pressed() -> void:
	if _selected_node_id == RunManager.CENTER_ID:
		if not RunManager.begin_crisis_boss():
			_message = "当前没有危机警报。"
			_refresh_all()
			return
		get_tree().change_scene_to_file(RunManager.pending_boss_scene)
		return
	var node := RunManager.get_map_node(_selected_node_id)
	var node_type := String(node.get("type", RunManager.NODE_BATTLE))
	if node_type == RunManager.NODE_EVENT:
		_show_event_choices(_selected_node_id)
		return
	if node_type == RunManager.NODE_REWARD:
		_show_reward_event_choices(_selected_node_id)
		return
	if RunManager.start_explore_node(_selected_node_id):
		get_tree().change_scene_to_file(RunManager.EXPLORE_ROOM_SCENE)
	else:
		_message = "节点暂不可进入。"
		_refresh_all()


func _show_shop() -> void:
	var popup := _open_popup(SHOP_POPUP_SCENE)
	popup.connect("message_requested", _set_message)
	popup.connect("inventory_changed", _refresh_all)
	popup.call("setup")


func _show_hangar() -> void:
	var popup := _open_popup(HANGAR_POPUP_SCENE)
	popup.connect("message_requested", _set_hangar_message)
	popup.connect("inventory_changed", _refresh_all)
	popup.call("setup")


func _set_hangar_message(message: String) -> void:
	if message.begins_with("已装配辅助机："):
		_set_message("")
		return
	_set_message(message)


func _show_pending_boss_reward_popup() -> void:
	if _pending_boss_reward_popup_summary.is_empty():
		return
	var popup_summary := _pending_boss_reward_popup_summary.duplicate(true)
	_pending_boss_reward_popup_summary.clear()
	var popup := _open_popup(BOSS_REWARD_POPUP_SCENE)
	popup.connect("reward_selected", _on_boss_reward_selected)
	popup.call("setup", popup_summary)


func _show_pending_special_bonus_popup() -> void:
	if _pending_special_bonus_popup_summary.is_empty():
		return
	var popup_summary := _pending_special_bonus_popup_summary.duplicate(true)
	_pending_special_bonus_popup_summary.clear()
	var popup := _open_popup(SPECIAL_BONUS_POPUP_SCENE)
	popup.call("setup", popup_summary)


func _show_pending_route_directive_popup() -> void:
	pass


func _show_event_choices(node_id: int) -> void:
	_pending_event_node_id = node_id
	_pending_event_seed = Time.get_ticks_msec()
	var choices := RunManager.prepare_choices(node_id, RunManager.get_run_content_context(), _pending_event_seed)
	if choices.is_empty():
		_message = "事件方案生成失败。"
		_refresh_all()
		return
	var popup := _open_popup(EVENT_CHOICE_POPUP_SCENE)
	popup.connect("choice_selected", _on_event_choice_selected)
	popup.call("setup", RunManager.get_map_node(node_id), choices)


func _show_reward_event_choices(node_id: int) -> void:
	_pending_reward_node_id = node_id
	_pending_reward_seed = Time.get_ticks_msec()
	var choices := RunManager.prepare_choices(node_id, RunManager.get_run_content_context(), _pending_reward_seed)
	if choices.is_empty():
		_message = "奖励事件读取失败。"
		_refresh_all()
		return
	var popup := _open_popup(REWARD_CACHE_CHOICE_POPUP_SCENE)
	popup.connect("choice_selected", _on_reward_cache_choice_selected)
	popup.call("setup", RunManager.get_map_node(node_id), choices)


func _on_reward_cache_choice_selected(choice_id: String) -> void:
	if _pending_reward_node_id <= 0:
		return
	var mutation := RunManager.resolve_choice(_pending_reward_node_id, choice_id, RunManager.get_run_content_context(), _pending_reward_seed)
	var result := RunManager.commit_mutation(mutation)
	_pending_reward_node_id = -1
	_pending_reward_seed = -1
	if bool(result.get("ok", false)):
		_message = String(result.get("message", "奖励已领取。"))
		_refresh_all()
		if is_instance_valid(_active_popup) and _active_popup.has_method("show_result"):
			_active_popup.call("show_result", result)
		return
	_message = String(result.get("message", "奖励事件暂不可完成。"))
	_refresh_all()


func _on_event_choice_selected(choice_id: String) -> void:
	if _pending_event_node_id <= 0:
		return
	var mutation := RunManager.resolve_choice(_pending_event_node_id, choice_id, RunManager.get_run_content_context(), _pending_event_seed)
	var result := RunManager.commit_mutation(mutation)
	_pending_event_node_id = -1
	_pending_event_seed = -1
	_message = String(result.get("message", "事件已完成。"))
	_refresh_all()
	if is_instance_valid(_active_popup) and _active_popup.has_method("show_result"):
		_active_popup.call("show_result", result)


func _on_boss_reward_selected(item_id: String) -> void:
	var result := RunManager.claim_boss_reward(item_id)
	if not bool(result.get("ok", false)):
		_set_message(String(result.get("message", "奖励领取失败。")))
		return
	_set_message("已收入机库：%s。" % String(result.get("item_name", "未知装备")))
	if is_instance_valid(_active_popup) and _active_popup.has_method("finish_selection"):
		_active_popup.call("finish_selection")
		await get_tree().create_timer(0.3, true).timeout
	if bool(result.get("is_final", false)):
		RunManager.finish_run(true)
		get_tree().change_scene_to_file(RunManager.GAME_OVER_SCENE)
		return
	RunManager.save_run()
	_refresh_all()


func on_boss_reward_claimed(result: Dictionary) -> void:
	_set_message("已收入机库：%s。" % String(result.get("item_name", "未知装备")))
	_refresh_all()
	if not _startup_popup_queue.is_empty():
		call_deferred("_show_next_startup_popup")


func _show_next_startup_popup() -> void:
	if _startup_popup_queue.is_empty() or is_instance_valid(_active_popup):
		return
	var show_popup: Callable = _startup_popup_queue.pop_front()
	show_popup.call()


func _open_popup(scene: PackedScene) -> Control:
	if is_instance_valid(_active_popup):
		_active_popup.queue_free()
	_active_popup = scene.instantiate() as Control
	add_child(_active_popup)
	if _active_popup.has_signal("closed"):
		_active_popup.connect("closed", _on_popup_closed.bind(_active_popup))
	else:
		push_warning("弹窗 %s 缺少 closed 信号，关闭后无法回收" % _active_popup.name)
	return _active_popup


func _on_popup_closed(popup: Control) -> void:
	if _active_popup == popup:
		_active_popup = null
	_refresh_all()
	if not _startup_popup_queue.is_empty():
		call_deferred("_show_next_startup_popup")


func _set_message(message: String) -> void:
	_message = message
	message_label.text = _message


func _show_settings() -> void:
	if is_instance_valid(_active_popup):
		_active_popup.queue_free()
	_active_popup = SETTINGS_POPUP_SCENE.instantiate() as Control
	_active_popup.call("configure_for_world_map")
	add_child(_active_popup)
	_active_popup.connect("closed", _on_popup_closed.bind(_active_popup))
	_active_popup.connect("save_and_exit_requested", _on_settings_save_and_exit)
	_active_popup.connect("save_and_main_menu_requested", _on_settings_save_and_main_menu)


func _on_settings_save_and_exit() -> void:
	RunManager.save_run()
	get_tree().quit()


func _on_settings_save_and_main_menu() -> void:
	RunManager.save_run()
	get_tree().change_scene_to_file("res://scenes/app/MainMenu.tscn")
