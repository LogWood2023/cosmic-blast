extends Node

const MetaProgression := preload("res://scripts/core/MetaProgression.gd")
const META_PREFLIGHT_POPUP_SCENE := preload("res://scenes/ui/main_menu/MetaPreflightPopup.tscn")


func _ready() -> void:
	var meta := MetaProgression.new()
	meta.unlock_calibration("salvage_probe")
	meta.unlock_crisis(2)
	var popup := META_PREFLIGHT_POPUP_SCENE.instantiate()
	popup.configure_for_progression(meta)
	add_child(popup)
	await get_tree().process_frame
	if not popup.apply_selection("salvage_probe", 2):
		_fail("Preflight popup rejected a valid unlocked selection.")
		return
	if meta.selected_calibration_id != "salvage_probe" or meta.selected_crisis_level != 2:
		_fail("Preflight popup did not apply the selected progression state.")
		return
	if popup.apply_selection("overclock_lease", 3):
		_fail("Preflight popup accepted an unavailable selection.")
		return
	meta.select_calibration("resonance_compass")
	if not popup.apply_selection("resonance_compass", 2, "warped") or meta.selected_calibration_family != "warped":
		_fail("Preflight popup did not persist the required resonance family selection.")
		return
	print("Meta preflight check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
