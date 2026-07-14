extends Node

const SETTINGS_POPUP_SCENE := preload("res://scenes/ui/main_menu/SettingsPopup.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var original := SettingsManager.get_settings_snapshot()
	var popup := SETTINGS_POPUP_SCENE.instantiate()
	add_child(popup)
	await get_tree().process_frame

	popup._draft["auto_fire"] = not bool(original["auto_fire"])
	popup._update_dirty_state()
	if SettingsManager.auto_fire != bool(original["auto_fire"]):
		_fail("Editing a draft setting must not apply it immediately.", original)
		return

	popup._request_close()
	if popup.is_queued_for_deletion() or not popup.has_node("UnsavedChangesDialog"):
		_fail("Closing dirty settings must show the unsaved-changes dialog.", original)
		return

	popup._dismiss_unsaved_dialog()
	popup._save_draft()
	if SettingsManager.auto_fire != bool(popup._draft["auto_fire"]):
		_fail("Saving settings must apply the draft.", original)
		return
	if not popup.is_queued_for_deletion():
		_fail("Saving settings must close the popup.", original)
		return

	var map_popup := SETTINGS_POPUP_SCENE.instantiate()
	map_popup.configure_for_world_map()
	add_child(map_popup)
	await get_tree().process_frame
	if not _has_button(map_popup, "保存并退出") or not _has_button(map_popup, "保存并回到主菜单"):
		_fail("World map settings must include both save navigation actions.", original)
		return
	var exit_requested := [false]
	map_popup.save_and_exit_requested.connect(func() -> void: exit_requested[0] = true)
	map_popup._save_and_exit()
	if not exit_requested[0] or not map_popup.is_queued_for_deletion():
		_fail("Save and exit must save, emit its action, and close the popup.", original)
		return

	var menu_popup := SETTINGS_POPUP_SCENE.instantiate()
	menu_popup.configure_for_world_map()
	add_child(menu_popup)
	await get_tree().process_frame
	var main_menu_requested := [false]
	menu_popup.save_and_main_menu_requested.connect(func() -> void: main_menu_requested[0] = true)
	menu_popup._save_and_main_menu()
	if not main_menu_requested[0] or not menu_popup.is_queued_for_deletion():
		_fail("Save and main menu must save, emit its action, and close the popup.", original)
		return

	SettingsManager.apply_settings(original)
	print("Settings popup check passed.")
	get_tree().quit(0)


func _fail(message: String, original: Dictionary) -> void:
	SettingsManager.apply_settings(original)
	push_error("Settings popup check failed: " + message)
	get_tree().quit(1)


func _has_button(popup: Control, text: String) -> bool:
	for child in popup.find_children("*", "Button", true, false):
		if (child as Button).text == text:
			return true
	return false
