extends SceneTree

const SHOP_POPUP_SCENE := preload("res://scenes/ui/world_map/ShopPopup.tscn")
const HANGAR_POPUP_SCENE := preload("res://scenes/ui/world_map/HangarPopup.tscn")
const EQUIPMENT_ARCHIVE_POPUP_SCENE := preload("res://scenes/ui/world_map/EquipmentArchivePopup.tscn")
const EVENT_CHOICE_POPUP_SCENE := preload("res://scenes/ui/world_map/EventChoicePopup.tscn")
const REWARD_CACHE_CHOICE_POPUP_SCENE := preload("res://scenes/ui/world_map/RewardCacheChoicePopup.tscn")
const BOSS_REWARD_POPUP_SCENE := preload("res://scenes/ui/world_map/BossRewardPopup.tscn")
const SPECIAL_BONUS_POPUP_SCENE := preload("res://scenes/ui/world_map/SpecialBonusPopup.tscn")
const ROUTE_DIRECTIVE_POPUP_SCENE := preload("res://scenes/ui/world_map/RouteDirectivePopup.tscn")
const SETTINGS_POPUP_SCENE := preload("res://scenes/ui/main_menu/SettingsPopup.tscn")
const COMMAND_CONSOLE_POPUP_SCENE := preload("res://scenes/ui/explore/CommandConsolePopup.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_manager = root.get_node_or_null("RunManager")
	if run_manager == null:
		push_error("RunManager autoload not found")
		quit(1)
		return
	run_manager.start_new_run()
	_check_shop_popup()
	_check_hangar_popup()
	_check_equipment_archive_popup()
	_check_event_choice_popup()
	_check_reward_cache_choice_popup()
	_check_boss_reward_popup()
	_check_special_bonus_popup()
	_check_route_directive_popup()
	_check_settings_popup()
	_check_command_console_popup()
	print("UI popup scene check passed.")
	quit()


func _check_shop_popup() -> void:
	var popup := SHOP_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup")
	_assert_has_node(popup, "Panel/ItemsScroll/ItemsList")
	_assert_has_node(popup, "Panel/ControlsBar/FamilyFocusOption")
	_assert_has_node(popup, "Panel/ControlsBar/RerollButton")
	_assert_shade_click_closes(popup)


func _check_hangar_popup() -> void:
	var popup := HANGAR_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup")
	_assert_has_node(popup, "Panel/ItemsScroll/ItemsList")
	_assert_has_node(popup, "Panel/TabBar/WeaponTab")
	_assert_has_node(popup, "Panel/TabBar/AuxiliaryTab")
	_assert_has_node(popup, "Panel/CurrentEquipment/CurrentName")
	var equipped_frame := popup.get_node("Panel/CurrentEquipment/EquippedFrame") as Control
	if not equipped_frame.visible:
		push_error("Hangar equipped auxiliary frame should remain visible on the weapon tab.")
	popup.call("_set_active_type", "aux")
	if not equipped_frame.visible:
		push_error("Hangar equipped auxiliary frame should remain visible on the auxiliary tab.")
	var slots := popup.get_node("Panel/CharmBay/CharmSlots") as HBoxContainer
	var run_manager := root.get_node("RunManager")
	if slots.get_child_count() != int(run_manager.compute_capacity):
		push_error("Hangar compute slots should match the live compute capacity.")
	_assert_shade_click_closes(popup)


func _check_equipment_archive_popup() -> void:
	var popup := EQUIPMENT_ARCHIVE_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup")
	_assert_has_node(popup, "Panel/ItemsScroll/ItemsList")
	_assert_has_node(popup, "Panel/FamilyFilterBar/ColossusButton")
	_assert_has_node(popup, "Panel/TypeFilterBar/WeaponButton")
	_assert_has_node(popup, "Panel/SummaryLabel")
	popup.queue_free()


func _check_event_choice_popup() -> void:
	var popup := EVENT_CHOICE_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup", {"tier": 2, "intel_title": "失落航标", "family_bias": "paradise"}, [
		{"choice_id": "a", "title": "接入补给链", "category": "minerals", "preview": "获得矿物"},
		{"choice_id": "b", "title": "静默修复", "category": "heal", "preview": "修复机体"},
		{"choice_id": "c", "title": "密封蓝图", "category": "equipment", "preview": "获得蓝图"},
	])
	_assert_has_node(popup, "Panel/ChoicesScroll/ChoicesList")
	var list := popup.get_node("Panel/ChoicesScroll/ChoicesList")
	if list.get_child_count() != 3:
		push_error("Event choice popup should create 3 choice buttons.")
	popup.queue_free()


func _check_reward_cache_choice_popup() -> void:
	var popup := REWARD_CACHE_CHOICE_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup", {"tier": 2, "reward_title": "天堂弹仓", "cache_family_bias": "paradise"}, [
		{"choice_id": "a", "title": "星髓回收箱", "description": "矿脉优先标定。", "preview": "星髓收益提高。"},
		{"choice_id": "b", "title": "封存蓝图箱", "description": "扫描带宽让给蓝图。", "preview": "装备蓝图检出提高。"},
		{"choice_id": "c", "title": "天堂号同调箱", "description": "锁定天堂号回响。", "preview": "天堂号蓝图更容易出现。"},
	])
	_assert_has_node(popup, "Panel/ChoicesScroll/ChoicesList")
	var list := popup.get_node("Panel/ChoicesScroll/ChoicesList")
	if list.get_child_count() != 3:
		push_error("Reward cache choice popup should create 3 choice buttons.")
	popup.queue_free()


func _check_boss_reward_popup() -> void:
	var popup := BOSS_REWARD_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup", {
		"ok": true,
		"threshold": 5,
		"stage": 1,
		"family_name": "星间巨构",
		"candidate_ids": ["colossus_titan_piston", "impact_servos", "twin_lance"],
	})
	_assert_has_node(popup, "Panel/TitleLabel")
	_assert_has_node(popup, "Panel/BodyLabel")
	_assert_has_node(popup, "Panel/RewardRows/CandidateRow1")
	var text := "%s\n%s" % [
		(popup.get_node("Panel/TitleLabel") as Label).text,
		(popup.get_node("Panel/BodyLabel") as RichTextLabel).text,
	]
	for expected in ["选择执行体缴获", "星间巨构", "三项未入库装备"]:
		if not text.contains(expected):
			push_error("Boss reward popup should include %s. Popup: %s" % [expected, text])
	popup.queue_free()


func _check_special_bonus_popup() -> void:
	var popup := SPECIAL_BONUS_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup", {
		"activated_names": ["冲刺碰撞协议"],
		"beacon_echo_routes": [
			{
				"node_name": "巨构残响带",
				"family_name": "星间巨构",
				"equipment_bonus": 0.08,
				"reward_bonus": 0.10,
			},
		],
	})
	_assert_has_node(popup, "Panel/TitleLabel")
	_assert_has_node(popup, "Panel/BodyLabel")
	_assert_has_node(popup, "Panel/CloseButton")
	popup.queue_free()


func _check_route_directive_popup() -> void:
	var popup := ROUTE_DIRECTIVE_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup", {
		"completed_directives": [
			{
				"title": "清扫前哨航线",
				"description": "方舟航线已经稳定。",
				"reward_text": "星髓矿与算力补给",
			},
		],
		"reward_summary": {"minerals": 33, "compute": 1},
	})
	_assert_has_node(popup, "Panel/TitleLabel")
	_assert_has_node(popup, "Panel/BodyLabel")
	_assert_has_node(popup, "Panel/CloseButton")
	popup.queue_free()


func _check_settings_popup() -> void:
	var popup := SETTINGS_POPUP_SCENE.instantiate()
	root.add_child(popup)
	_assert_has_node(popup, "Panel/CloseButton")
	_assert_shade_click_closes(popup)


func _check_command_console_popup() -> void:
	var popup := COMMAND_CONSOLE_POPUP_SCENE.instantiate()
	root.add_child(popup)
	if popup.call("get_dialog_panel") == null:
		push_error("Command console dialog panel missing.")
	if popup.call("get_dialog_label") == null:
		push_error("Command console dialog label missing.")
	if popup.call("get_input_panel") == null:
		push_error("Command console input panel missing.")
	if popup.call("get_input_edit") == null:
		push_error("Command console input edit missing.")
	popup.queue_free()


func _assert_has_node(parent: Node, path: NodePath) -> void:
	if not parent.has_node(path):
		push_error("Missing popup node: %s in %s" % [path, parent.name])


func _assert_shade_click_closes(popup: Control) -> void:
	var shade := popup.get_node("Shade") as Control
	var panel := popup.get_node("Panel") as Control
	if shade.mouse_filter != Control.MOUSE_FILTER_STOP:
		push_error("Popup shade should receive outside clicks: %s" % popup.name)
	if panel.mouse_filter != Control.MOUSE_FILTER_STOP:
		push_error("Popup panel should stop inside clicks from reaching the shade: %s" % popup.name)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	shade.gui_input.emit(click)
	if not bool(popup.get("_is_closing")):
		push_error("Clicking outside should start the close animation: %s" % popup.name)
