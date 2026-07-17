class_name BalanceTelemetry
extends RefCounted

const OUTPUT_PATH: String = "user://balance_runs.jsonl"
const MAX_OUTPUT_BYTES: int = 10 * 1024 * 1024

var enabled: bool = false
var output_path: String = OUTPUT_PATH
var max_output_bytes: int = MAX_OUTPUT_BYTES
var _events: Array[Dictionary] = []
var _mechanic_stats: Dictionary = {}
var _mechanic_window_started_msec: int = 0
var _mechanic_window_event_count: int = 0

func record(event_name: String, payload: Dictionary = {}) -> void:
	if not enabled:
		return
	_events.append({"event": event_name, "payload": payload.duplicate(true), "time_msec": Time.get_ticks_msec()})

func flush() -> Error:
	if not enabled or _events.is_empty():
		return OK
	var pending_bytes := 0
	for event in _events:
		pending_bytes += JSON.stringify(event).to_utf8_buffer().size() + 1
	if FileAccess.file_exists(output_path):
		var existing := FileAccess.open(output_path, FileAccess.READ)
		if existing != null:
			var should_rotate := existing.get_length() > 0 and existing.get_length() + pending_bytes > max_output_bytes
			existing.close()
			if should_rotate:
				var rotate_error := _rotate_output()
				if rotate_error != OK:
					return rotate_error
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(output_path) else FileAccess.WRITE
	var file := FileAccess.open(output_path, mode)
	if file == null:
		push_error("BalanceTelemetry: unable to open output.")
		return FileAccess.get_open_error()
	file.seek_end()
	for event in _events:
		file.store_line(JSON.stringify(event))
	file.close()
	_events.clear()
	return OK

func snapshot() -> Array[Dictionary]:
	return _events.duplicate(true)


func clear() -> void:
	_events.clear()
	_mechanic_stats.clear()
	_mechanic_window_started_msec = 0
	_mechanic_window_event_count = 0


func record_mechanic_effect(effect_id: String, payload: Dictionary) -> void:
	if not enabled or effect_id.is_empty():
		return
	var now := Time.get_ticks_msec()
	if _mechanic_window_started_msec == 0 or now - _mechanic_window_started_msec >= 1000:
		_mechanic_window_started_msec = now
		_mechanic_window_event_count = 0
	_mechanic_window_event_count += 1
	var stat := Dictionary(_mechanic_stats.get(effect_id, {
		"trigger_count": 0,
		"damage_contribution": 0.0,
		"max_generation": 0,
		"peak_events_per_second": 0,
	}))
	stat["trigger_count"] = int(stat.get("trigger_count", 0)) + 1
	stat["damage_contribution"] = float(stat.get("damage_contribution", 0.0)) + maxf(0.0, float(payload.get("damage", 0.0)))
	stat["max_generation"] = maxi(int(stat.get("max_generation", 0)), int(payload.get("generation", 0)))
	stat["peak_events_per_second"] = maxi(int(stat.get("peak_events_per_second", 0)), _mechanic_window_event_count)
	_mechanic_stats[effect_id] = stat
	record("mechanic_effect", {"effect_id": effect_id, "generation": int(payload.get("generation", 0)), "damage": float(payload.get("damage", 0.0))})


func get_mechanic_statistics() -> Dictionary:
	return _mechanic_stats.duplicate(true)


func _rotate_output() -> Error:
	var source_path := ProjectSettings.globalize_path(output_path)
	var rotated_path := "%s.1" % source_path
	if FileAccess.file_exists("%s.1" % output_path):
		var remove_error := DirAccess.remove_absolute(rotated_path)
		if remove_error != OK:
			push_error("BalanceTelemetry: unable to replace rotated output.")
			return remove_error
	var rename_error := DirAccess.rename_absolute(source_path, rotated_path)
	if rename_error != OK:
		push_error("BalanceTelemetry: unable to rotate output.")
	return rename_error
