extends Node
const MetaProgression := preload("res://scripts/core/MetaProgression.gd")
func _ready() -> void:
	var meta := MetaProgression.new()
	for calibration_id in MetaProgression.INITIAL_CALIBRATION_IDS:
		if not meta.unlocked_calibrations.has(calibration_id) or meta.get_calibration_data(calibration_id) == null:
			_fail("Initial calibration definitions must be unlocked and loadable.")
			return
	if not meta.unlock_calibration("salvage_probe") or not meta.select_calibration("salvage_probe"):
		_fail("Non-initial calibration unlock/selection failed.")
		return
	meta.load_dict({"selected_calibration_id": "route_memory", "unlocked_calibrations": {"route_memory": true}, "unlocked_crisis_level": 0})
	if meta.selected_calibration_id != "wide_scan":
		_fail("Legacy calibration IDs must migrate safely.")
		return
	if not meta.record_run_victory(0) or meta.unlocked_crisis_level != 1:
		_fail("Crisis progression must unlock exactly one tier after clearing the selected highest tier.")
		return
	if meta.record_run_victory(0) or meta.unlocked_crisis_level != 1:
		_fail("Clearing a non-highest crisis must not unlock extra tiers.")
		return
	var path := MetaProgression.SAVE_PATH
	var had_existing_save := FileAccess.file_exists(path)
	var original_contents := ""
	if had_existing_save:
		var original_file := FileAccess.open(path, FileAccess.READ)
		original_contents = original_file.get_as_text() if original_file != null else ""
		if original_file != null:
			original_file.close()
	var corrupt_file := FileAccess.open(path, FileAccess.WRITE)
	corrupt_file.store_string("not valid json")
	corrupt_file.close()
	var recovered := MetaProgression.new()
	if recovered.load_from_disk() or not recovered.unlocked_calibrations.has("wide_scan"):
		_restore_save(path, had_existing_save, original_contents)
		_fail("Corrupt meta saves must fall back to initial calibration state.")
		return
	_restore_save(path, had_existing_save, original_contents)
	print("Meta progression check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)


func _restore_save(path: String, had_existing_save: bool, contents: String) -> void:
	if had_existing_save:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(contents)
		file.close()
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
