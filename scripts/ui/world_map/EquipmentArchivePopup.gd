extends Control

signal closed

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const ITEM_ROW_SCENE := preload("res://scenes/ui/world_map/EquipmentItemRow.tscn")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

const FAMILY_FILTER_OPTIONS: Array[Dictionary] = [
	{"id": "", "label": "全部", "node": "AllButton"},
	{"id": EquipmentCatalogScript.FAMILY_COLOSSUS, "label": "星间巨构", "node": "ColossusButton"},
	{"id": EquipmentCatalogScript.FAMILY_PARADISE, "label": "天堂号", "node": "ParadiseButton"},
	{"id": EquipmentCatalogScript.FAMILY_WARPED, "label": "扭曲星核", "node": "WarpedButton"},
	{"id": EquipmentCatalogScript.FAMILY_HELL_EYE, "label": "地狱之眼", "node": "HellEyeButton"},
	{"id": EquipmentCatalogScript.FAMILY_DIVINE, "label": "神明使者", "node": "DivineButton"},
	{"id": EquipmentCatalogScript.FAMILY_GENERAL, "label": "通用", "node": "GeneralButton"},
]

const TYPE_ALL: String = ""
const TYPE_WEAPON: String = "weapon"
const TYPE_AUX: String = "aux"
const TYPE_FILTER_OPTIONS: Array[Dictionary] = [
	{"id": TYPE_ALL, "label": "全库", "node": "AllButton"},
	{"id": TYPE_WEAPON, "label": "武器", "node": "WeaponButton"},
	{"id": TYPE_AUX, "label": "辅助机", "node": "AuxButton"},
]

@onready var summary_label: Label = $Panel/SummaryLabel
@onready var message_label: Label = $Panel/MessageLabel
@onready var items_list: VBoxContainer = $Panel/ItemsScroll/ItemsList
@onready var close_button: Button = $Panel/CloseButton
@onready var family_filter_bar: HBoxContainer = $Panel/FamilyFilterBar
@onready var type_filter_bar: HBoxContainer = $Panel/TypeFilterBar

var _active_family_filter: String = ""
var _active_type_filter: String = TYPE_ALL


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	close_button.pressed.connect(_on_close_pressed)
	_bind_family_filter_buttons()
	_bind_type_filter_buttons()


func setup() -> void:
	_refresh()


func _refresh() -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	_sync_family_filter_buttons()
	_sync_type_filter_buttons()
	_refresh_summary(run_manager)

	for child in items_list.get_children():
		child.queue_free()

	for item_id in _get_all_equipment_ids():
		if not _item_matches_filters(item_id):
			continue
		var item := EquipmentCatalogScript.get_item(item_id)
		var owned: bool = run_manager.equipment_inventory.has(item_id)
		var row = ITEM_ROW_SCENE.instantiate()
		items_list.add_child(row)
		row.setup(
			item_id,
			String(item.get("name", item_id)),
			EquipmentCatalogScript.get_ui_meta_text(item_id, false, 0),
			String(item.get("description", "")),
			"已入库" if owned else "未入库",
			not owned,
			"[已入库]" if owned else ""
		)
		row.action_pressed.connect(_on_row_pressed)


func _bind_family_filter_buttons() -> void:
	for option in FAMILY_FILTER_OPTIONS:
		var button := family_filter_bar.get_node_or_null(String(option.get("node", ""))) as Button
		if button == null:
			continue
		button.toggle_mode = true
		button.text = String(option.get("label", ""))
		button.pressed.connect(_on_family_filter_pressed.bind(String(option.get("id", ""))))


func _bind_type_filter_buttons() -> void:
	for option in TYPE_FILTER_OPTIONS:
		var button := type_filter_bar.get_node_or_null(String(option.get("node", ""))) as Button
		if button == null:
			continue
		button.toggle_mode = true
		button.text = String(option.get("label", ""))
		button.pressed.connect(_on_type_filter_pressed.bind(String(option.get("id", ""))))


func _sync_family_filter_buttons() -> void:
	for option in FAMILY_FILTER_OPTIONS:
		var button := family_filter_bar.get_node_or_null(String(option.get("node", ""))) as Button
		if button == null:
			continue
		button.set_pressed_no_signal(String(option.get("id", "")) == _active_family_filter)


func _sync_type_filter_buttons() -> void:
	for option in TYPE_FILTER_OPTIONS:
		var button := type_filter_bar.get_node_or_null(String(option.get("node", ""))) as Button
		if button == null:
			continue
		button.set_pressed_no_signal(String(option.get("id", "")) == _active_type_filter)


func _refresh_summary(run_manager: Node) -> void:
	var weapon_count := EquipmentCatalogScript.get_weapon_item_ids().size()
	var auxiliary_count := EquipmentCatalogScript.get_auxiliary_item_ids(true).size()
	var owned_count := 0
	for item_id in _get_all_equipment_ids():
		if run_manager.equipment_inventory.has(item_id):
			owned_count += 1
	summary_label.text = "纹章档案 / 已入库 %d / 武器 %d / 辅助机 %d" % [
		owned_count,
		weapon_count,
		auxiliary_count,
	]
	if not _active_family_filter.is_empty():
		summary_label.text += " / %s" % EquipmentCatalogScript.get_family_display_name(_active_family_filter)
	if not _active_type_filter.is_empty():
		summary_label.text += " / %s" % _type_display_name(_active_type_filter)


func _get_all_equipment_ids() -> Array[String]:
	var ids: Array[String] = []
	for item_id in EquipmentCatalogScript.get_weapon_item_ids():
		ids.append(item_id)
	for item_id in EquipmentCatalogScript.get_auxiliary_item_ids(true):
		ids.append(item_id)
	return ids


func _item_matches_filters(item_id: String) -> bool:
	var item_type := EquipmentCatalogScript.get_type(item_id)
	if not _active_type_filter.is_empty() and item_type != _active_type_filter:
		return false
	if _active_family_filter.is_empty():
		return true
	var family := EquipmentCatalogScript.get_family(item_id)
	return family == _active_family_filter or family == EquipmentCatalogScript.FAMILY_GENERAL


func _type_display_name(type_id: String) -> String:
	match type_id:
		TYPE_WEAPON:
			return "武器"
		TYPE_AUX:
			return "辅助机"
	return "全库"


func _on_family_filter_pressed(family: String) -> void:
	_active_family_filter = family
	_refresh()


func _on_type_filter_pressed(type_id: String) -> void:
	_active_type_filter = type_id
	_refresh()


func _on_row_pressed(item_id: String) -> void:
	message_label.text = "%s 已在方舟档案中归档。" % EquipmentCatalogScript.get_display_name(item_id)


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()


func _get_run_manager() -> Node:
	return get_node_or_null("/root/RunManager")
