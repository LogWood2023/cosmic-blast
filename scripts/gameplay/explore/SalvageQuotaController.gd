class_name SalvageQuotaController
extends Node

signal salvage_progress_changed(collected_value: int, total_value: int, ratio: float)
signal evacuation_unlocked

const EVACUATION_RATIO: float = 0.65
const GUIDANCE_RATIO: float = 0.50

var total_value: int = 0
var collected_value: int = 0
var evacuation_is_unlocked: bool = false


func register_value(value: int) -> void:
	if value > 0:
		total_value += value


func collect_value(value: int) -> void:
	if value <= 0:
		return
	collected_value = mini(total_value, collected_value + value)
	var ratio := get_progress_ratio()
	salvage_progress_changed.emit(collected_value, total_value, ratio)
	if ratio >= EVACUATION_RATIO and not evacuation_is_unlocked:
		evacuation_is_unlocked = true
		evacuation_unlocked.emit()


func get_progress_ratio() -> float:
	return float(collected_value) / float(total_value) if total_value > 0 else 0.0


func should_show_evacuation_guidance() -> bool:
	return get_progress_ratio() >= GUIDANCE_RATIO


func get_summary() -> Dictionary:
	return {"total_value": total_value, "collected_value": collected_value, "salvage_ratio": get_progress_ratio(), "evacuation_unlocked": evacuation_is_unlocked}
