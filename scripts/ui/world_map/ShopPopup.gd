extends Control

signal closed
signal inventory_changed
signal message_requested(message: String)

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const ITEM_ROW_SCENE := preload("res://scenes/ui/world_map/EquipmentItemRow.tscn")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")
const FAMILY_OPTIONS: Array[Dictionary] = [
	{"id": "", "label": "全域随机"},
	{"id": EquipmentCatalogScript.FAMILY_COLOSSUS, "label": "巨构"},
	{"id": EquipmentCatalogScript.FAMILY_PARADISE, "label": "天堂"},
	{"id": EquipmentCatalogScript.FAMILY_WARPED, "label": "星核"},
	{"id": EquipmentCatalogScript.FAMILY_HELL_EYE, "label": "地狱眼"},
	{"id": EquipmentCatalogScript.FAMILY_DIVINE, "label": "神使"},
]

@onready var minerals_label: Label = $Panel/MineralsLabel
@onready var message_label: Label = $Panel/MessageLabel
@onready var items_list: VBoxContainer = $Panel/ItemsScroll/ItemsList
@onready var close_button: Button = $Panel/CloseButton
@onready var shop_state_label: Label = $Panel/ControlsBar/ShopStateLabel
@onready var family_focus_option: OptionButton = $Panel/ControlsBar/FamilyFocusOption
@onready var reroll_button: Button = $Panel/ControlsBar/RerollButton
@onready var shop_guidance_title: Label = $Panel/ShopGuidanceBar/ShopGuidanceTitle
@onready var shop_guidance_detail: Label = $Panel/ShopGuidanceBar/ShopGuidanceDetail


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	_populate_family_focus_options()
	close_button.pressed.connect(_on_close_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)


func setup() -> void:
	_refresh()


func _refresh() -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	minerals_label.text = "星髓矿：%d" % int(run_manager.minerals)
	var reroll_cost := int(run_manager.get_shop_reroll_cost())
	var free_reroll_summary := {}
	if run_manager.has_method("get_free_shop_reroll_summary"):
		free_reroll_summary = run_manager.call("get_free_shop_reroll_summary")
	var preferred_family := String(run_manager.shop_preferred_family)
	_sync_family_focus_option(preferred_family)
	shop_state_label.text = "货单：%s / 重抽 %d 次" % [_family_display_name(preferred_family), int(run_manager.shop_reroll_count)]
	if int(free_reroll_summary.get("remaining", 0)) > 0:
		shop_state_label.text = "%s / 货单券 %d" % [shop_state_label.text, int(free_reroll_summary.get("remaining", 0))]
		reroll_button.text = "免矿重抽"
	else:
		reroll_button.text = "重抽 %d" % reroll_cost
	reroll_button.disabled = int(run_manager.minerals) < reroll_cost
	_refresh_shop_guidance(run_manager)

	for child in items_list.get_children():
		child.queue_free()

	for item_id in run_manager.get_shop_offer_ids():
		var item := EquipmentCatalogScript.get_item(item_id)
		var base_price := EquipmentCatalogScript.get_price(item_id)
		var price := base_price
		if run_manager.has_method("get_effective_shop_price"):
			price = int(run_manager.call("get_effective_shop_price", item_id))
		var owned: bool = run_manager.equipment_inventory.has(item_id)
		var meta_text := EquipmentCatalogScript.get_ui_meta_text(item_id, true, price)
		if price < base_price:
			meta_text = "%s / 原价 %d / 折后 %d 星髓矿" % [meta_text, base_price, price]

		var row = ITEM_ROW_SCENE.instantiate()
		items_list.add_child(row)
		row.setup(
			item_id,
			String(item.get("name", item_id)),
			meta_text,
			String(item.get("description", "")),
			"已拥有" if owned else "购买",
			owned,
			"[已拥有]" if owned else ("[折后]" if price < base_price else "")
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


func _on_reroll_pressed() -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	var result: Dictionary = run_manager.reroll_shop_offers(_get_selected_family_focus())
	var text := String(result.get("message", ""))
	message_label.text = text
	message_requested.emit(text)
	if bool(result.get("ok", false)):
		inventory_changed.emit()
	_refresh()


func _populate_family_focus_options() -> void:
	family_focus_option.clear()
	for option in FAMILY_OPTIONS:
		var index := family_focus_option.get_item_count()
		family_focus_option.add_item(String(option.get("label", "")))
		family_focus_option.set_item_metadata(index, String(option.get("id", "")))


func _sync_family_focus_option(family: String) -> void:
	for index in range(family_focus_option.get_item_count()):
		if String(family_focus_option.get_item_metadata(index)) == family:
			family_focus_option.select(index)
			return
	family_focus_option.select(0)


func _get_selected_family_focus() -> String:
	var selected := family_focus_option.selected
	if selected < 0:
		return ""
	return String(family_focus_option.get_item_metadata(selected))


func _refresh_shop_guidance(run_manager: Node) -> void:
	if not run_manager.has_method("get_shop_guidance"):
		shop_guidance_title.text = "采购校准：等待航图"
		shop_guidance_detail.text = "货单会在方舟完成航向测算后偏移。"
		return
	var guidance: Dictionary = run_manager.call("get_shop_guidance")
	shop_guidance_title.text = String(guidance.get("title", "采购校准：未定航路"))
	shop_guidance_detail.text = "%s %s" % [
		String(guidance.get("summary", "")),
		String(guidance.get("reroll_hint", "")),
	]


func _family_display_name(family: String) -> String:
	for option in FAMILY_OPTIONS:
		if String(option.get("id", "")) == family:
			return String(option.get("label", "全域随机"))
	return "全域随机"


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()


func _get_run_manager() -> Node:
	return get_node_or_null("/root/RunManager")
