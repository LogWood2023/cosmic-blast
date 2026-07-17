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
const EconomyService := preload("res://scripts/core/EconomyService.gd")

@onready var minerals_label: Label = $Panel/ControlsBar/MineralsLabel
@onready var shade: ColorRect = $Shade
@onready var message_label: Label = $Panel/MessageLabel
@onready var items_list: Container = $Panel/ItemsScroll/ItemsList
@onready var close_button: Button = $Panel/CloseButton
@onready var family_focus_option: OptionButton = $Panel/ControlsBar/FamilyFocusOption
@onready var reroll_button: Button = $Panel/ControlsBar/RerollButton

var _is_closing := false


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	_populate_family_focus_options()
	shade.gui_input.connect(_on_shade_gui_input)
	close_button.pressed.connect(_on_close_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)


func setup() -> void:
	_refresh()


func _refresh() -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	minerals_label.text = "✦  %d" % int(run_manager.minerals)
	var reroll_cost := int(run_manager.get_shop_reroll_cost())
	var free_reroll_summary := {}
	if run_manager.has_method("get_free_shop_reroll_summary"):
		free_reroll_summary = run_manager.call("get_free_shop_reroll_summary")
	var preferred_family := String(run_manager.shop_preferred_family)
	_sync_family_focus_option(preferred_family)
	if int(free_reroll_summary.get("remaining", 0)) > 0:
		reroll_button.text = "免费刷新商品"
	else:
		reroll_button.text = "刷新商品 %d" % reroll_cost
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
		var can_purchase: bool = not owned and int(run_manager.minerals) >= price
		_add_offer_card(item_id, item, price, base_price, owned, can_purchase)


func _add_offer_card(item_id: String, item: Dictionary, price: int, base_price: int, owned: bool, can_purchase: bool) -> void:
	var price_text := "✦ %d" % price
	if price < base_price:
		price_text = "✦ %d  原价 %d" % [price, base_price]
	var row = ITEM_ROW_SCENE.instantiate()
	row.custom_minimum_size = Vector2(0.0, 188.0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_list.add_child(row)
	row.setup(
		item_id,
		String(item.get("name", item_id)),
		"",
		String(item.get("description", "")),
		"",
		not can_purchase,
		""
	)
	var status_text := price_text
	if owned:
		status_text = "已拥有"
	elif not can_purchase:
		status_text = "矿石不足 · %s" % price_text
	row.set_card_action_only(true, status_text)
	# 商品卡片的价格需要比通用状态文案更醒目：15px × 1.5，四舍五入为 23px。
	row.set_context_font_size(23)
	row.action_pressed.connect(_on_buy_item)


func _on_buy_item(item_id: String) -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	var economy := EconomyService.new()
	var context = run_manager.get_run_content_context()
	var mutation := economy.create_purchase_run_mutation(item_id, -1, context.get_state_version())
	var result: Dictionary = run_manager.commit_mutation(mutation)
	if bool(result.get("ok", false)):
		result["message"] = "已将 %s 收入装备库。" % EquipmentCatalog.get_display_name(item_id)
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
		family_focus_option.tooltip_text = "选择货单的流派倾向。"
		return
	var guidance: Dictionary = run_manager.call("get_shop_guidance")
	var guidance_text := "%s\n%s %s" % [
		String(guidance.get("title", "采购校准")),
		String(guidance.get("summary", "")),
		String(guidance.get("reroll_hint", "")),
	]
	family_focus_option.tooltip_text = guidance_text.strip_edges()
	reroll_button.tooltip_text = guidance_text.strip_edges()


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
