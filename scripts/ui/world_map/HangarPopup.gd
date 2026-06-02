extends Control

signal closed
signal inventory_changed
signal message_requested(message: String)

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const ITEM_ROW_SCENE := preload("res://scenes/ui/world_map/EquipmentItemRow.tscn")

@onready var weapon_label: Label = $Panel/WeaponLabel
@onready var aux_label: Label = $Panel/AuxLabel
@onready var compute_label: Label = $Panel/ComputeLabel
@onready var message_label: Label = $Panel/MessageLabel
@onready var items_list: VBoxContainer = $Panel/ItemsScroll/ItemsList
@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)


func setup() -> void:
	_refresh()


func _refresh() -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	weapon_label.text = "当前武器：%s" % EquipmentCatalogScript.get_display_name(run_manager.equipped_weapon)
	aux_label.text = "辅助机：%s" % _equipped_aux_text()
	compute_label.text = "算力：%d/%d" % [run_manager.get_used_compute(), int(run_manager.compute_capacity)]
	for child in items_list.get_children():
		child.queue_free()
	for item_id in run_manager.equipment_inventory:
		var item := EquipmentCatalogScript.get_item(item_id)
		var item_type := EquipmentCatalogScript.get_type(item_id)
		var is_weapon := item_type == EquipmentCatalogScript.TYPE_WEAPON
		var is_equipped_weapon: bool = item_id == run_manager.equipped_weapon
		var is_equipped_aux: bool = run_manager.equipped_auxiliaries.has(item_id)
		var status := ""
		if is_equipped_weapon:
			status = "[已装备]"
		elif is_equipped_aux:
			status = "[已装配]"
		var meta := "武器"
		if item_type == EquipmentCatalogScript.TYPE_AUX:
			meta = "辅助机 / 算力 %d" % EquipmentCatalogScript.get_compute_cost(item_id)
		var action_text := "已装备" if is_equipped_weapon else "装配"
		if not is_weapon and is_equipped_aux:
			action_text = "卸下"
		var row = ITEM_ROW_SCENE.instantiate()
		items_list.add_child(row)
		row.setup(
			item_id,
			String(item.get("name", item_id)),
			meta,
			String(item.get("description", "")),
			action_text,
			is_equipped_weapon,
			status
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


func _equipped_aux_text() -> String:
	var run_manager := _get_run_manager()
	if run_manager == null or run_manager.equipped_auxiliaries.is_empty():
		return "无"
	var names: Array[String] = []
	for item_id in run_manager.equipped_auxiliaries:
		names.append(EquipmentCatalogScript.get_display_name(item_id))
	return "、".join(names)


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()


func _get_run_manager() -> Node:
	return get_node_or_null("/root/RunManager")
