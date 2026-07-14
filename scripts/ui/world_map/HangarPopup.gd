extends Control

signal closed
signal inventory_changed
signal message_requested(message: String)

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const ITEM_ROW_SCENE := preload("res://scenes/ui/world_map/EquipmentItemRow.tscn")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var weapon_tab: Button = $Panel/TabBar/WeaponTab
@onready var auxiliary_tab: Button = $Panel/TabBar/AuxiliaryTab
@onready var shade: ColorRect = $Shade
@onready var current_icon: TextureRect = $Panel/CurrentEquipment/CurrentIconFrame/CurrentIcon
@onready var current_name: Label = $Panel/CurrentEquipment/CurrentName
@onready var current_effect: RichTextLabel = $Panel/CurrentEquipment/CurrentEffect
@onready var equipped_frame: Panel = $Panel/CurrentEquipment/EquippedFrame
@onready var equipped_list: VBoxContainer = $Panel/CurrentEquipment/EquippedFrame/EquippedScroll/EquippedList
@onready var items_list: VBoxContainer = $Panel/ItemsScroll/ItemsList
@onready var charm_bay_label: Label = $Panel/CharmBay/CharmBayLabel
@onready var charm_slots: HBoxContainer = $Panel/CharmBay/CharmSlots
@onready var message_label: Label = $Panel/MessageLabel
@onready var close_button: Button = $Panel/CloseButton

var _active_type: String = EquipmentCatalogScript.TYPE_WEAPON
var _is_closing := false


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	shade.gui_input.connect(_on_shade_gui_input)
	weapon_tab.pressed.connect(_set_active_type.bind(EquipmentCatalogScript.TYPE_WEAPON))
	auxiliary_tab.pressed.connect(_set_active_type.bind(EquipmentCatalogScript.TYPE_AUX))
	close_button.pressed.connect(_on_close_pressed)


func setup() -> void:
	_refresh()


func _set_active_type(item_type: String) -> void:
	_active_type = item_type
	_refresh()


func _refresh() -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	weapon_tab.set_pressed_no_signal(_active_type == EquipmentCatalogScript.TYPE_WEAPON)
	auxiliary_tab.set_pressed_no_signal(_active_type == EquipmentCatalogScript.TYPE_AUX)
	# 左侧始终是完整装配区；标签只筛选右侧库存，不改变左侧内容。
	var current_id := String(run_manager.equipped_weapon)
	if current_id.is_empty():
		current_icon.texture = null
		current_name.text = "未装配武器"
		current_effect.text = "武器\n当前无实际效果\n从右侧选择已拥有的武器。"
	else:
		var current := EquipmentCatalogScript.get_item(current_id)
		var icon_path := String(current.get("icon", ""))
		current_icon.texture = load(icon_path) as Texture2D if not icon_path.is_empty() and ResourceLoader.exists(icon_path) else null
		current_name.text = String(current.get("name", current_id))
		current_effect.text = "%s\n%s\n%s" % [
			"武器",
			EquipmentCatalogScript.get_effect_summary_text(current_id),
			String(current.get("description", "")),
		]
	_refresh_equipped_list(run_manager)
	_refresh_compute_slots(run_manager)
	for child in items_list.get_children():
		child.queue_free()
	var available_count := 0
	for item_id in run_manager.equipment_inventory:
		if EquipmentCatalogScript.get_type(item_id) != _active_type:
			continue
		if item_id == run_manager.equipped_weapon or run_manager.equipped_auxiliaries.has(item_id):
			continue
		_add_item_row(item_id)
		available_count += 1
	if available_count == 0:
		var empty_label := Label.new()
		empty_label.text = "没有可装配的%s。" % ("武器" if _active_type == EquipmentCatalogScript.TYPE_WEAPON else "辅助机")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 22)
		items_list.add_child(empty_label)


func _refresh_equipped_list(run_manager: Node) -> void:
	for child in equipped_list.get_children():
		equipped_list.remove_child(child)
		child.queue_free()
	equipped_frame.visible = true
	var equipped_ids: Array[String] = []
	for item_id in run_manager.equipped_auxiliaries:
		equipped_ids.append(String(item_id))
	var equipped_count := 0
	for item_id in equipped_ids:
		if item_id.is_empty():
			continue
		_add_equipped_row(item_id)
		equipped_count += 1
	if equipped_count == 0:
		var empty_label := Label.new()
		empty_label.text = "当前没有已装配的辅助机。"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 20)
		equipped_list.add_child(empty_label)


func _refresh_compute_slots(run_manager: Node) -> void:
	var used := int(run_manager.get_used_compute())
	var capacity := int(run_manager.compute_capacity)
	charm_bay_label.text = "算力占用 %d / %d" % [used, capacity]
	for child in charm_slots.get_children():
		charm_slots.remove_child(child)
		child.queue_free()
	for index in range(capacity):
		var is_used := index < used
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(42.0, 34.0)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.tooltip_text = "算力 %d/%d · %s" % [index + 1, capacity, "已占用" if is_used else "可用"]
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.04, 0.43, 0.54, 0.96) if is_used else Color(0.015, 0.04, 0.065, 0.9)
		style.border_color = Color(0.32, 0.91, 1.0, 0.95) if is_used else Color(0.24, 0.42, 0.5, 0.72)
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		slot.add_theme_stylebox_override("panel", style)
		var index_label := Label.new()
		index_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		index_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		index_label.text = str(index + 1)
		index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		index_label.add_theme_font_size_override("font_size", 16)
		index_label.add_theme_color_override("font_color", Color(0.94, 1.0, 1.0, 1.0) if is_used else Color(0.48, 0.62, 0.7, 0.9))
		slot.add_child(index_label)
		charm_slots.add_child(slot)


func _add_item_row(item_id: String) -> void:
	var item := EquipmentCatalogScript.get_item(item_id)
	var row = ITEM_ROW_SCENE.instantiate()
	row.custom_minimum_size = Vector2(0.0, 158.0)
	items_list.add_child(row)
	row.setup(
		item_id,
		String(item.get("name", item_id)),
		EquipmentCatalogScript.get_ui_meta_text(item_id, false, 0),
		String(item.get("description", "")),
		"装配",
		false
	)
	row.action_pressed.connect(_on_equip_item)


func _add_equipped_row(item_id: String) -> void:
	var item := EquipmentCatalogScript.get_item(item_id)
	var row = ITEM_ROW_SCENE.instantiate()
	row.custom_minimum_size = Vector2(0.0, 158.0)
	equipped_list.add_child(row)
	row.setup(
		item_id,
		String(item.get("name", item_id)),
		EquipmentCatalogScript.get_ui_meta_text(item_id, false, 0),
		String(item.get("description", "")),
		"卸下",
		false,
		"[已装配]"
	)
	row.action_pressed.connect(_on_equip_item)


func _on_equip_item(item_id: String) -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	var result: Dictionary = run_manager.equip_or_toggle(item_id)
	var text := String(result.get("message", ""))
	message_label.text = text
	message_requested.emit(text)
	if bool(result.get("ok", false)):
		inventory_changed.emit()
		_refresh()


func _on_close_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	CombatUiMotion.animate_first_panel_exit(self, func() -> void:
		closed.emit()
		queue_free()
	)


func _on_shade_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_close_pressed()
	elif event is InputEventScreenTouch and event.pressed:
		_on_close_pressed()


func _get_run_manager() -> Node:
	return get_node_or_null("/root/RunManager")
