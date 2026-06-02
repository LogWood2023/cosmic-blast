extends Control

signal closed
signal inventory_changed
signal message_requested(message: String)

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const ITEM_ROW_SCENE := preload("res://scenes/ui/world_map/EquipmentItemRow.tscn")

@onready var minerals_label: Label = $Panel/MineralsLabel
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
	minerals_label.text = "星髓矿：%d" % int(run_manager.minerals)
	for child in items_list.get_children():
		child.queue_free()
	for item_id in EquipmentCatalogScript.get_shop_item_ids():
		var item := EquipmentCatalogScript.get_item(item_id)
		var item_type := EquipmentCatalogScript.get_type(item_id)
		var price := int(item.get("price", 0))
		var owned: bool = run_manager.equipment_inventory.has(item_id)
		var type_text := "武器"
		if item_type == EquipmentCatalogScript.TYPE_AUX:
			type_text = "辅助机 / 算力 %d" % EquipmentCatalogScript.get_compute_cost(item_id)
		var row = ITEM_ROW_SCENE.instantiate()
		items_list.add_child(row)
		row.setup(
			item_id,
			String(item.get("name", item_id)),
			"%s / %d 星髓矿" % [type_text, price],
			String(item.get("description", "")),
			"已拥有" if owned else "购买",
			owned,
			"[已拥有]" if owned else ""
		)
		row.action_pressed.connect(_on_buy_item)


func _on_buy_item(item_id: String) -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	var result: Dictionary = run_manager.buy_equipment(item_id)
	var text := String(result.get("message", ""))
	message_label.text = text
	message_requested.emit(text)
	if bool(result.get("ok", false)):
		inventory_changed.emit()
	_refresh()


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()


func _get_run_manager() -> Node:
	return get_node_or_null("/root/RunManager")
