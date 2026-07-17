class_name BalanceRecord
extends Resource

## One immutable row generated from master_balance.tsv.
@export var schema_version: String = ""
@export var domain: String = ""
@export var kind: String = ""
@export var record_id: String = ""
@export var display_name: String = ""
@export var raw_value: String = ""
@export var raw_stage_values: PackedStringArray = PackedStringArray()
@export var unit: String = ""
@export var data_type: String = ""
@export var raw_attributes: String = ""
@export var formula: String = ""
@export var notes: String = ""


func get_typed_value(stage: int = 0, default_value: Variant = null) -> Variant:
	var source := raw_value
	if stage >= 1 and stage <= raw_stage_values.size() and not raw_stage_values[stage - 1].is_empty():
		source = raw_stage_values[stage - 1]
	if source.is_empty():
		return default_value
	match data_type:
		"int":
			return int(source)
		"float":
			return float(source)
		_:
			return source


func to_snapshot() -> Dictionary:
	return {
		"schema_version": schema_version,
		"domain": domain,
		"kind": kind,
		"id": record_id,
		"name": display_name,
		"value": get_typed_value(),
		"stage_values": raw_stage_values.duplicate(),
		"unit": unit,
		"data_type": data_type,
		"raw_attributes": raw_attributes,
		"formula": formula,
		"notes": notes,
	}
