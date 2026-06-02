extends SceneTree

const SHOP_POPUP_SCENE := preload("res://scenes/ui/world_map/ShopPopup.tscn")
const HANGAR_POPUP_SCENE := preload("res://scenes/ui/world_map/HangarPopup.tscn")
const EVENT_RESULT_POPUP_SCENE := preload("res://scenes/ui/world_map/EventResultPopup.tscn")
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
	_check_event_popup()
	_check_settings_popup()
	_check_command_console_popup()
	print("UI popup scene check passed.")
	quit()


func _check_shop_popup() -> void:
	var popup := SHOP_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup")
	_assert_has_node(popup, "Panel/ItemsScroll/ItemsList")
	popup.queue_free()


func _check_hangar_popup() -> void:
	var popup := HANGAR_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup")
	_assert_has_node(popup, "Panel/ItemsScroll/ItemsList")
	popup.queue_free()


func _check_event_popup() -> void:
	var popup := EVENT_RESULT_POPUP_SCENE.instantiate()
	root.add_child(popup)
	popup.call("setup", {"ok": true, "message": "测试事件。"})
	_assert_has_node(popup, "Panel/BodyLabel")
	popup.queue_free()


func _check_settings_popup() -> void:
	var popup := SETTINGS_POPUP_SCENE.instantiate()
	root.add_child(popup)
	_assert_has_node(popup, "Panel/CloseButton")
	popup.queue_free()


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
