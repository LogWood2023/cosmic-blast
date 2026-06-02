extends Control

const SHOP_POPUP_SCENE := preload("res://scenes/ui/world_map/ShopPopup.tscn")
const HANGAR_POPUP_SCENE := preload("res://scenes/ui/world_map/HangarPopup.tscn")
const EVENT_RESULT_POPUP_SCENE := preload("res://scenes/ui/world_map/EventResultPopup.tscn")

const NODE_RADIUS: float = 24.0
const CENTER_RADIUS: float = 38.0
const NODE_COLOR_LOCKED: Color = Color(0.12, 0.16, 0.24, 1.0)
const NODE_COLOR_READY: Color = Color(0.20, 0.78, 1.0, 1.0)
const NODE_COLOR_DONE: Color = Color(0.22, 0.86, 0.48, 1.0)
const NODE_COLOR_BASE: Color = Color(1.0, 0.78, 0.24, 1.0)
const NODE_COLOR_ALERT: Color = Color(1.0, 0.18, 0.12, 1.0)
const MAP_LINE_COLOR: Color = Color(0.24, 0.42, 0.76, 0.62)

var _selected_node_id: int = RunManager.CENTER_ID
var _message: String = ""
var _active_popup: Control

@onready var title_label: Label = $TopBar/TitleLabel
@onready var stats_label: Label = $TopBar/StatsLabel
@onready var details_panel: Panel = $DetailsPanel
@onready var details_title: Label = $DetailsPanel/DetailsTitle
@onready var details_body: RichTextLabel = $DetailsPanel/DetailsBody
@onready var enter_button: Button = $DetailsPanel/EnterButton
@onready var shop_button: Button = $DetailsPanel/ShopButton
@onready var hangar_button: Button = $DetailsPanel/HangarButton
@onready var message_label: Label = $MessageLabel
@onready var back_button: Button = $BackButton


func _ready() -> void:
	if not RunManager.is_formal_run_active():
		RunManager.start_new_run()
	enter_button.pressed.connect(_on_enter_pressed)
	shop_button.pressed.connect(_show_shop)
	hangar_button.pressed.connect(_show_hangar)
	back_button.pressed.connect(_on_back_pressed)
	_refresh_all()


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
	return "?"


func _node_at_position(pos: Vector2) -> int:
	for node in RunManager.map_nodes:
		var id := int(node.get("id", -1))
		var center: Vector2 = node.get("position", Vector2.ZERO)
		var radius := CENTER_RADIUS if id == RunManager.CENTER_ID else NODE_RADIUS
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
	stats_label.text = "危机 %d  算力 %d/%d  星髓矿 %d  已探索 %d" % [
		RunManager.crisis_level,
		RunManager.get_used_compute(),
		RunManager.compute_capacity,
		RunManager.minerals,
		RunManager.completed_node_count,
	]


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
	if RunManager.is_alert_active():
		lines.append("")
		lines.append("[color=#ff5b4a]警报锁定：五席执行体正在逼近，只能访问方舟核心。[/color]")
	elif _selected_node_id == RunManager.CENTER_ID:
		lines.append("")
		lines.append("方舟核心可进行商店购买、机库装配，也会在危机警报时开启 Boss 战。")
	else:
		lines.append("")
		lines.append(_node_description(node_type))
	details_body.text = "\n".join(lines)
	var is_base := _selected_node_id == RunManager.CENTER_ID
	enter_button.visible = true
	enter_button.disabled = false
	shop_button.visible = is_base
	hangar_button.visible = is_base
	if is_base:
		enter_button.text = "迎战危机" if RunManager.is_alert_active() else "等待警报"
		enter_button.disabled = not RunManager.is_alert_active()
	else:
		enter_button.text = "进入节点"
		enter_button.disabled = not RunManager.is_node_accessible(_selected_node_id)


func _node_description(node_type: String) -> String:
	match node_type:
		RunManager.NODE_BATTLE:
			return "五席遗留军团巡逻区。进入后需要寻找资源并撤离。"
		RunManager.NODE_EVENT:
			return "旧时代记录或异常协议。首版会直接结算一次事件。"
		RunManager.NODE_REWARD:
			return "资源缓存区。敌人和陷阱更少，宝箱与矿脉更多。"
	return "尚未识别的空间残片。"


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
		var result := RunManager.resolve_event_node(_selected_node_id)
		_message = String(result.get("message", "事件已完成。"))
		_refresh_all()
		_show_event_result(result)
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


func _show_event_result(result: Dictionary) -> void:
	var popup := _open_popup(EVENT_RESULT_POPUP_SCENE)
	popup.call("setup", result)


func _open_popup(scene: PackedScene) -> Control:
	if is_instance_valid(_active_popup):
		_active_popup.queue_free()
	_active_popup = scene.instantiate() as Control
	add_child(_active_popup)
	_active_popup.connect("closed", _on_popup_closed.bind(_active_popup))
	return _active_popup


func _on_popup_closed(popup: Control) -> void:
	if _active_popup == popup:
		_active_popup = null
	_refresh_all()


func _set_message(message: String) -> void:
	_message = message
	message_label.text = _message


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/app/MainMenu.tscn")
