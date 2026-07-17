class_name MetaProgression
extends Node
## Versioned, horizontal-only preflight progression. No permanent stat upgrades live here.

const BalanceServiceScript := preload("res://scripts/core/BalanceService.gd")

const SAVE_VERSION: int = 2
const SAVE_PATH: String = "user://meta_progression.json"
const CALIBRATION_IDS: PackedStringArray = ["wide_scan", "procurement_voucher", "resonance_compass", "emergency_bulkhead", "overclock_lease", "frenzy_preheat", "salvage_probe", "chaos_seed"]
const INITIAL_CALIBRATION_IDS: PackedStringArray = ["wide_scan", "procurement_voucher", "resonance_compass"]
const FAMILY_IDS: PackedStringArray = ["colossus", "paradise", "warped", "hell_eye", "divine"]
const CALIBRATION_PATHS: Dictionary = {
	"wide_scan": "res://data/calibrations/wide_scan.tres",
	"procurement_voucher": "res://data/calibrations/procurement_voucher.tres",
	"resonance_compass": "res://data/calibrations/resonance_compass.tres",
	"emergency_bulkhead": "res://data/calibrations/emergency_bulkhead.tres",
	"overclock_lease": "res://data/calibrations/overclock_lease.tres",
	"frenzy_preheat": "res://data/calibrations/frenzy_preheat.tres",
	"salvage_probe": "res://data/calibrations/salvage_probe.tres",
	"chaos_seed": "res://data/calibrations/chaos_seed.tres",
}
const LEGACY_CALIBRATION_IDS: Dictionary = {
	"route_memory": "wide_scan",
	"beacon_compass": "resonance_compass",
	"crisis_lens": "procurement_voucher",
}

var selected_calibration_id: String = ""
var selected_calibration_family: String = ""
var unlocked_calibrations: Dictionary = {}
var unlocked_crisis_level: int = 0
var selected_crisis_level: int = 0
var highest_cleared_crisis_level: int = -1


func _init() -> void:
	_ensure_initial_unlocks()


func _ready() -> void:
	load_from_disk()


func get_calibration_data(calibration_id: String) -> CalibrationData:
	var path := String(CALIBRATION_PATHS.get(calibration_id, ""))
	var loaded := load(path) as CalibrationData if not path.is_empty() else null
	if loaded == null:
		return null
	var calibration := loaded.duplicate(true) as CalibrationData
	var record := BalanceServiceScript.get_record_snapshot("calibration", calibration_id)
	if not record.is_empty():
		calibration.display_name = String(record.get("name", calibration.display_name))
		calibration.effects = BalanceServiceScript.get_calibration_effects(calibration_id)
		calibration.unlock_condition = String(Dictionary(record.attributes).get("payload", {}).get("unlock", calibration.unlock_condition))
	return calibration


func get_selected_calibration_snapshot() -> Dictionary:
	if selected_calibration_id.is_empty():
		return {}
	var calibration := get_calibration_data(selected_calibration_id)
	if calibration == null:
		return {}
	return {
		"id": calibration.calibration_id,
		"display_name": calibration.display_name,
		"family": selected_calibration_family,
		"effects": calibration.effects.duplicate(true),
	}


func select_calibration(calibration_id: String) -> bool:
	if not CALIBRATION_IDS.has(calibration_id) or not unlocked_calibrations.has(calibration_id):
		return false
	selected_calibration_id = calibration_id
	if calibration_id != "resonance_compass":
		selected_calibration_family = ""
	return true


func select_calibration_family(family_id: String) -> bool:
	if selected_calibration_id != "resonance_compass" or not FAMILY_IDS.has(family_id):
		return false
	selected_calibration_family = family_id
	return true


func clear_calibration_selection() -> void:
	selected_calibration_id = ""
	selected_calibration_family = ""


func unlock_calibration(calibration_id: String) -> bool:
	if not CALIBRATION_IDS.has(calibration_id):
		return false
	var was_unlocked := unlocked_calibrations.has(calibration_id)
	unlocked_calibrations[calibration_id] = true
	return not was_unlocked


func record_boss_reached(stage: int) -> bool:
	if stage >= 3:
		return unlock_calibration("frenzy_preheat")
	if stage >= 2:
		return unlock_calibration("emergency_bulkhead")
	return false


func record_boss_defeated(stage: int) -> bool:
	if stage >= 2:
		return unlock_calibration("salvage_probe")
	if stage >= 1:
		return unlock_calibration("overclock_lease")
	return false


func record_run_victory(cleared_crisis_level: int) -> bool:
	var changed := unlock_calibration("chaos_seed")
	highest_cleared_crisis_level = maxi(highest_cleared_crisis_level, clampi(cleared_crisis_level, 0, 10))
	if cleared_crisis_level == unlocked_crisis_level and unlocked_crisis_level < 10:
		unlock_crisis(unlocked_crisis_level + 1)
		changed = true
	return changed


func unlock_crisis(level: int) -> void:
	unlocked_crisis_level = maxi(unlocked_crisis_level, clampi(level, 0, 10))


func select_crisis(level: int) -> bool:
	if level < 0 or level > unlocked_crisis_level:
		return false
	selected_crisis_level = level
	return true


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"selected_calibration_id": selected_calibration_id,
		"selected_calibration_family": selected_calibration_family,
		"unlocked_calibrations": unlocked_calibrations.duplicate(true),
		"unlocked_crisis_level": unlocked_crisis_level,
		"selected_crisis_level": selected_crisis_level,
		"highest_cleared_crisis_level": highest_cleared_crisis_level,
	}


func load_dict(data: Dictionary) -> void:
	selected_calibration_id = _migrate_calibration_id(String(data.get("selected_calibration_id", "")))
	selected_calibration_family = String(data.get("selected_calibration_family", ""))
	unlocked_calibrations.clear()
	for raw_id in Dictionary(data.get("unlocked_calibrations", {})).keys():
		var calibration_id := _migrate_calibration_id(String(raw_id))
		if CALIBRATION_IDS.has(calibration_id):
			unlocked_calibrations[calibration_id] = true
	_ensure_initial_unlocks()
	if not unlocked_calibrations.has(selected_calibration_id):
		clear_calibration_selection()
	elif selected_calibration_id == "resonance_compass" and not FAMILY_IDS.has(selected_calibration_family):
		selected_calibration_family = ""
	elif selected_calibration_id != "resonance_compass":
		selected_calibration_family = ""
	unlocked_crisis_level = clampi(int(data.get("unlocked_crisis_level", 0)), 0, 10)
	selected_crisis_level = clampi(int(data.get("selected_crisis_level", 0)), 0, unlocked_crisis_level)
	highest_cleared_crisis_level = clampi(int(data.get("highest_cleared_crisis_level", -1)), -1, 10)


func save_to_disk() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dict()))
	file.close()
	return true


func load_from_disk() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		_ensure_initial_unlocks()
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		_reset_to_defaults()
		return false
	load_dict(parser.data)
	return true


func _migrate_calibration_id(calibration_id: String) -> String:
	return String(LEGACY_CALIBRATION_IDS.get(calibration_id, calibration_id))


func _ensure_initial_unlocks() -> void:
	for calibration_id in INITIAL_CALIBRATION_IDS:
		unlocked_calibrations[calibration_id] = true


func _reset_to_defaults() -> void:
	clear_calibration_selection()
	unlocked_calibrations.clear()
	unlocked_crisis_level = 0
	selected_crisis_level = 0
	highest_cleared_crisis_level = -1
	_ensure_initial_unlocks()
