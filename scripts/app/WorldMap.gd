extends Control

const SHOP_POPUP_SCENE := preload("res://scenes/ui/world_map/ShopPopup.tscn")
const HANGAR_POPUP_SCENE := preload("res://scenes/ui/world_map/HangarPopup.tscn")
const EQUIPMENT_ARCHIVE_POPUP_SCENE := preload("res://scenes/ui/world_map/EquipmentArchivePopup.tscn")
const EVENT_CHOICE_POPUP_SCENE := preload("res://scenes/ui/world_map/EventChoicePopup.tscn")
const EVENT_RESULT_POPUP_SCENE := preload("res://scenes/ui/world_map/EventResultPopup.tscn")
const REWARD_CACHE_CHOICE_POPUP_SCENE := preload("res://scenes/ui/world_map/RewardCacheChoicePopup.tscn")
const BOSS_REWARD_POPUP_SCENE := preload("res://scenes/ui/world_map/BossRewardPopup.tscn")
const SPECIAL_BONUS_POPUP_SCENE := preload("res://scenes/ui/world_map/SpecialBonusPopup.tscn")
const ROUTE_DIRECTIVE_POPUP_SCENE := preload("res://scenes/ui/world_map/RouteDirectivePopup.tscn")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

const NODE_RADIUS: float = 24.0
const CENTER_RADIUS: float = 38.0
const NODE_COLOR_LOCKED: Color = Color(0.12, 0.16, 0.24, 1.0)
const NODE_COLOR_READY: Color = Color(0.20, 0.78, 1.0, 1.0)
const NODE_COLOR_DONE: Color = Color(0.22, 0.86, 0.48, 1.0)
const NODE_COLOR_BASE: Color = Color(1.0, 0.78, 0.24, 1.0)
const NODE_COLOR_ALERT: Color = Color(1.0, 0.18, 0.12, 1.0)
const NODE_COLOR_SPECIAL_READY: Color = Color(0.72, 0.38, 1.0, 1.0)
const NODE_COLOR_SPECIAL_ACTIVE: Color = Color(0.22, 1.0, 0.82, 1.0)
const MAP_LINE_COLOR: Color = Color(0.24, 0.42, 0.76, 0.62)

var _selected_node_id: int = RunManager.CENTER_ID
var _message: String = ""
var _active_popup: Control
var _pending_event_node_id: int = -1
var _pending_event_seed: int = -1
var _pending_reward_node_id: int = -1
var _pending_reward_seed: int = -1
var _pending_boss_reward_popup_summary: Dictionary = {}
var _pending_special_bonus_popup_summary: Dictionary = {}
var _pending_route_directive_popup_summary: Dictionary = {}
var _startup_popup_queue: Array[Callable] = []

@onready var title_label: Label = $TopBar/TitleLabel
@onready var stats_label: Label = $TopBar/StatsLabel
@onready var details_panel: Panel = $DetailsPanel
@onready var details_title: Label = $DetailsPanel/DetailsTitle
@onready var details_body: RichTextLabel = $DetailsPanel/DetailsBody
@onready var enter_button: Button = $DetailsPanel/EnterButton
@onready var shop_button: Button = $DetailsPanel/ShopButton
@onready var hangar_button: Button = $DetailsPanel/HangarButton
@onready var archive_button: Button = $DetailsPanel/ArchiveButton
@onready var message_label: Label = $MessageLabel
@onready var back_button: Button = $BackButton


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	if not RunManager.is_formal_run_active():
		RunManager.start_new_run()
	# 回到世界地图即为一个干净的存档点，写盘保存本局进度
	RunManager.save_run()
	_consume_node_completion_feedback()
	enter_button.pressed.connect(_on_enter_pressed)
	shop_button.pressed.connect(_show_shop)
	hangar_button.pressed.connect(_show_hangar)
	archive_button.pressed.connect(_show_equipment_archive)
	back_button.pressed.connect(_on_back_pressed)
	_refresh_all()
	# 入场弹窗排队依次展示；此前三个同帧打开会互相 queue_free，玩家只看到最后一个
	if not _pending_special_bonus_popup_summary.is_empty():
		_startup_popup_queue.append(_show_pending_special_bonus_popup)
	if not _pending_route_directive_popup_summary.is_empty():
		_startup_popup_queue.append(_show_pending_route_directive_popup)
	if not _pending_boss_reward_popup_summary.is_empty():
		_startup_popup_queue.append(_show_pending_boss_reward_popup)
	if not _startup_popup_queue.is_empty():
		call_deferred("_show_next_startup_popup")


func _consume_node_completion_feedback() -> void:
	var messages: Array[String] = []
	var node_feedback := _consume_explore_completion_feedback()
	if not node_feedback.is_empty():
		messages.append(node_feedback)
	var boss_feedback := _consume_boss_completion_feedback()
	if not boss_feedback.is_empty():
		messages.append(boss_feedback)
	if not messages.is_empty():
		_message = " ".join(messages)


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
	var route_momentum_feedback := _make_route_momentum_feedback(summary)
	if not route_momentum_feedback.is_empty():
		lines.append(route_momentum_feedback)
	var route_directive_feedback := _make_route_directive_completion_feedback(summary)
	if not route_directive_feedback.is_empty():
		lines.append(route_directive_feedback)
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
	_pending_route_directive_popup_summary = {
		"completed_directives": completed_directives.duplicate(true),
		"new_directives": new_directives.duplicate(true),
		"reward_summary": Dictionary(summary.get("route_directive_rewards", {})).duplicate(true),
		"route_momentum": route_momentum.duplicate(true),
	}
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


func _gui_input(event: InputEvent) -> void:
	if is_instance_valid(_active_popup):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var node_id := _node_at_position(event.position)
		if node_id >= 0:
			_selected_node_id = node_id
			_message = ""
			_refresh_all()
			accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.018, 0.04, 1.0), true)
	_draw_links()
	_draw_nodes()


func _draw_links() -> void:
	var drawn := {}
	for node in RunManager.map_nodes:
		var from_id := int(node.get("id", -1))
		var from_pos: Vector2 = node.get("position", Vector2.ZERO)
		for linked_id in node.get("links", []):
			var to_id := int(linked_id)
			var key := "%d_%d" % [mini(from_id, to_id), maxi(from_id, to_id)]
			if drawn.has(key):
				continue
			drawn[key] = true
			var linked_node := RunManager.get_map_node(to_id)
			var to_pos: Vector2 = linked_node.get("position", Vector2.ZERO)
			draw_line(from_pos, to_pos, MAP_LINE_COLOR, 3.0, true)


func _draw_nodes() -> void:
	for node in RunManager.map_nodes:
		var id := int(node.get("id", -1))
		var pos: Vector2 = node.get("position", Vector2.ZERO)
		var is_base := id == RunManager.CENTER_ID
		var radius := CENTER_RADIUS if is_base else NODE_RADIUS
		if String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			radius = NODE_RADIUS + 5.0
		var color := _get_node_color(id)
		if id == _selected_node_id:
			draw_circle(pos, radius + 9.0, Color(1.0, 1.0, 1.0, 0.22))
			draw_arc(pos, radius + 12.0, 0.0, TAU, 72, Color.WHITE, 2.0, true)
		draw_circle(pos, radius, color)
		draw_circle(pos, radius, Color(1.0, 1.0, 1.0, 0.30), false, 2.0, true)
		var label := "核" if is_base else _node_short_type(String(node.get("type", "")))
		var font := get_theme_default_font()
		var font_size := 22
		var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, pos - label_size * 0.5 + Vector2(0.0, label_size.y * 0.75), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


func _get_node_color(node_id: int) -> Color:
	if node_id == RunManager.CENTER_ID:
		return NODE_COLOR_ALERT if RunManager.is_alert_active() else NODE_COLOR_BASE
	var node := RunManager.get_map_node(node_id)
	if String(node.get("type", "")) == RunManager.NODE_SPECIAL:
		return NODE_COLOR_SPECIAL_ACTIVE if RunManager.is_special_bonus_active(node_id) else NODE_COLOR_SPECIAL_READY
	if RunManager.is_node_completed(node_id):
		return NODE_COLOR_DONE
	if RunManager.is_node_accessible(node_id):
		return NODE_COLOR_READY
	if RunManager.is_alert_active():
		return Color(0.26, 0.10, 0.11, 1.0)
	return NODE_COLOR_LOCKED


func _node_short_type(node_type: String) -> String:
	match node_type:
		RunManager.NODE_BATTLE:
			return "战"
		RunManager.NODE_EVENT:
			return "事"
		RunManager.NODE_REWARD:
			return "奖"
		RunManager.NODE_SPECIAL:
			return "信"
	return "?"


func _node_at_position(pos: Vector2) -> int:
	for node in RunManager.map_nodes:
		var id := int(node.get("id", -1))
		var center: Vector2 = node.get("position", Vector2.ZERO)
		var radius := CENTER_RADIUS if id == RunManager.CENTER_ID else NODE_RADIUS
		if String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			radius = NODE_RADIUS + 5.0
		if center.distance_to(pos) <= radius + 10.0:
			return id
	return -1


func _refresh_all() -> void:
	_refresh_top_bar()
	_refresh_details()
	message_label.text = _message
	queue_redraw()


func _refresh_top_bar() -> void:
	title_label.text = "方舟核心航图"
	var stat_parts: Array[String] = []
	stat_parts.append("危机 %d" % RunManager.crisis_level)
	stat_parts.append("算力 %d/%d" % [RunManager.get_used_compute(), RunManager.compute_capacity])
	stat_parts.append("星髓矿 %d" % RunManager.minerals)
	stat_parts.append("已探索 %d" % RunManager.completed_node_count)
	var active_protocol_count := _get_active_special_bonus_count()
	if active_protocol_count > 0:
		stat_parts.append("接入协议 %d" % active_protocol_count)
	var active_beacon_resonance_count := _get_active_special_beacon_resonance_count()
	if active_beacon_resonance_count > 0:
		stat_parts.append("信标共鸣 %d" % active_beacon_resonance_count)
	var active_contract_count := _get_active_event_contract_count()
	if active_contract_count > 0:
		stat_parts.append("航路契约 %d" % active_contract_count)
	var route_momentum := _get_active_route_momentum()
	if not route_momentum.is_empty():
		stat_parts.append("航路动能 %d" % int(route_momentum.get("remaining_nodes", 0)))
	var active_directive_count := _get_active_route_directive_count()
	if active_directive_count > 0:
		stat_parts.append("航路指令 %d" % active_directive_count)
	var run_condition_count := _get_active_run_condition_count()
	if run_condition_count > 0:
		stat_parts.append("航域态势 %d" % run_condition_count)
	stats_label.text = "  ".join(stat_parts)


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
	var lines: Array[String] = []
	lines.append("[b]类型：[/b]%s" % RunManager.get_node_type_name(node_type))
	lines.append("[b]状态：[/b]%s" % RunManager.get_node_state_text(_selected_node_id))
	lines.append("[b]危机等级：[/b]%d" % RunManager.crisis_level)
	lines.append("[b]算力：[/b]%d/%d" % [RunManager.get_used_compute(), RunManager.compute_capacity])
	_append_active_event_contract_lines(lines)
	_append_active_route_momentum_lines(lines)
	if node_type == RunManager.NODE_SPECIAL:
		lines.append("")
		lines.append(String(node.get("bonus_description", "接入后提供整局加成。")))
		lines.append("[b]接入方式：[/b]探索任一相邻节点后自动接入。")
		if RunManager.is_special_bonus_active(_selected_node_id):
			lines.append("[color=#39ffc8]状态：增益已生效。[/color]")
		elif RunManager.is_node_accessible(_selected_node_id):
			lines.append("[color=#a966ff]状态：连线已打通，等待同步。[/color]")
		else:
			lines.append("[color=#7f8ca8]状态：尚未与已探索航路相连。[/color]")
	elif RunManager.is_alert_active():
		lines.append("")
		lines.append("[color=#ff5b4a]警报锁定：五席执行体正在逼近，只能访问方舟核心。[/color]")
	elif _selected_node_id == RunManager.CENTER_ID:
		lines.append("")
		lines.append("方舟核心可进行商店购买、机库装配，也会在危机警报时开启执行体战斗。")
		_append_route_directive_lines(lines)
		_append_active_special_bonus_lines(lines)
		_append_active_special_beacon_resonance_lines(lines)
	else:
		lines.append("")
		var family_bias := RunManager.get_node_family_bias(_selected_node_id)
		var intel_title := String(node.get("intel_title", ""))
		var intel_description := String(node.get("intel_description", ""))
		var tier := int(node.get("tier", 1))
		var risk := int(node.get("risk_level", 1))
		var reward_mult := float(node.get("reward_mult", 1.0))
		var equipment_chance := float(node.get("equipment_drop_chance", 0.0))
		lines.append("[b]航图层级：[/b]第%d层   [b]风险：[/b]%d   [b]矿物倍率：[/b]%.2f倍" % [tier, risk, reward_mult])
		lines.append("[b]装备检出：[/b]%d%%" % int(round(equipment_chance * 100.0)))
		if node_type == RunManager.NODE_REWARD:
			var reward_title := String(node.get("reward_title", "奖励缓存"))
			var reward_description := String(node.get("reward_description", "高价值资源缓存。"))
			var cache_family := String(node.get("cache_family_bias", ""))
			lines.append("[b]奖励主题：[/b]%s" % reward_title)
			if not cache_family.is_empty():
				lines.append("[b]装备缓存倾向：[/b]%s" % _family_display_name(cache_family))
			lines.append(reward_description)
		elif node_type == RunManager.NODE_BATTLE:
			var battle_title := String(node.get("battle_title", "战斗态势"))
			var battle_description := String(node.get("battle_description", "敌方巡逻信号活跃。"))
			var battle_threat := int(node.get("battle_threat", risk))
			lines.append("[b]战斗态势：[/b]%s   [b]威胁：[/b]%d" % [battle_title, battle_threat])
			lines.append(battle_description)
		if not family_bias.is_empty():
			lines.append("[b]流派倾向：[/b]%s" % _family_display_name(family_bias))
		_append_route_plan_lines(lines, node)
		_append_ore_source_room_effect_lines(lines, node)
		_append_opportunity_lines(lines, node)
		_append_run_condition_lines(lines, node)
		_append_beacon_echo_lines(lines, node)
		_append_reward_cache_calibration_lines(lines, node)
		_append_boss_aftershock_lines(lines, node)
		_append_modifier_lines(lines, node)
		if not intel_title.is_empty():
			lines.append("[b]作战情报：[/b]%s" % intel_title)
		if not intel_description.is_empty():
			lines.append(intel_description)
		lines.append("")
		lines.append(_node_description(node_type))
	details_body.text = "\n".join(lines)
	var is_base := _selected_node_id == RunManager.CENTER_ID
	enter_button.visible = true
	enter_button.disabled = false
	shop_button.visible = is_base
	hangar_button.visible = is_base
	archive_button.visible = is_base
	if is_base:
		enter_button.text = "迎战危机" if RunManager.is_alert_active() else "等待警报"
		enter_button.disabled = not RunManager.is_alert_active()
	elif node_type == RunManager.NODE_SPECIAL:
		enter_button.text = "自动接入"
		enter_button.disabled = true
	else:
		enter_button.text = "进入节点"
		enter_button.disabled = not RunManager.is_node_accessible(_selected_node_id)


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
			return "资源缓存区。敌人和陷阱更少，宝箱与矿脉更多。"
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
		_show_reward_cache_choices(_selected_node_id)
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
	popup.connect("message_requested", _set_message)
	popup.connect("inventory_changed", _refresh_all)
	popup.call("setup")


func _show_equipment_archive() -> void:
	var popup := _open_popup(EQUIPMENT_ARCHIVE_POPUP_SCENE)
	popup.call("setup")


func _show_event_result(result: Dictionary) -> void:
	var popup := _open_popup(EVENT_RESULT_POPUP_SCENE)
	popup.call("setup", result)


func _show_pending_boss_reward_popup() -> void:
	if _pending_boss_reward_popup_summary.is_empty():
		return
	var popup_summary := _pending_boss_reward_popup_summary.duplicate(true)
	_pending_boss_reward_popup_summary.clear()
	var popup := _open_popup(BOSS_REWARD_POPUP_SCENE)
	popup.call("setup", popup_summary)


func _show_pending_special_bonus_popup() -> void:
	if _pending_special_bonus_popup_summary.is_empty():
		return
	var popup_summary := _pending_special_bonus_popup_summary.duplicate(true)
	_pending_special_bonus_popup_summary.clear()
	var popup := _open_popup(SPECIAL_BONUS_POPUP_SCENE)
	popup.call("setup", popup_summary)


func _show_pending_route_directive_popup() -> void:
	if _pending_route_directive_popup_summary.is_empty():
		return
	var popup_summary := _pending_route_directive_popup_summary.duplicate(true)
	_pending_route_directive_popup_summary.clear()
	var popup := _open_popup(ROUTE_DIRECTIVE_POPUP_SCENE)
	popup.call("setup", popup_summary)


func _show_event_choices(node_id: int) -> void:
	_pending_event_node_id = node_id
	_pending_event_seed = Time.get_ticks_msec()
	var choices := RunManager.prepare_event_choices(node_id, _pending_event_seed)
	if choices.is_empty():
		_message = "事件方案生成失败。"
		_refresh_all()
		return
	var popup := _open_popup(EVENT_CHOICE_POPUP_SCENE)
	popup.connect("choice_selected", _on_event_choice_selected)
	popup.call("setup", RunManager.get_map_node(node_id), choices)


func _show_reward_cache_choices(node_id: int) -> void:
	_pending_reward_node_id = node_id
	_pending_reward_seed = Time.get_ticks_msec()
	var choices := RunManager.prepare_reward_cache_choices(node_id, _pending_reward_seed)
	if choices.is_empty():
		_message = "奖励缓存读取失败。"
		_refresh_all()
		return
	var popup := _open_popup(REWARD_CACHE_CHOICE_POPUP_SCENE)
	popup.connect("choice_selected", _on_reward_cache_choice_selected)
	popup.call("setup", RunManager.get_map_node(node_id), choices)


func _on_reward_cache_choice_selected(choice_id: String) -> void:
	if _pending_reward_node_id <= 0:
		return
	var result := RunManager.start_reward_cache_choice(_pending_reward_node_id, choice_id, _pending_reward_seed)
	_pending_reward_node_id = -1
	_pending_reward_seed = -1
	if bool(result.get("ok", false)):
		get_tree().change_scene_to_file(RunManager.EXPLORE_ROOM_SCENE)
		return
	_message = String(result.get("message", "奖励缓存暂不可进入。"))
	_refresh_all()


func _on_event_choice_selected(choice_id: String) -> void:
	if _pending_event_node_id <= 0:
		return
	var result := RunManager.resolve_event_choice(_pending_event_node_id, choice_id, _pending_event_seed)
	_pending_event_node_id = -1
	_pending_event_seed = -1
	_message = String(result.get("message", "事件已完成。"))
	_refresh_all()
	_show_event_result(result)


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


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/app/MainMenu.tscn")
