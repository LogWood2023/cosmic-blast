class_name EventOptionData
extends Resource
## A single declarative option. Costs and effects are interpreted only by EventResolver.

@export var option_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var preview_text: String = ""
@export var costs: Array[Dictionary] = []
@export var effects: Array[Dictionary] = []
@export_range(0, 6, 1) var duration_nodes: int = 0
@export var ai_tags: PackedStringArray = PackedStringArray()
@export var requires_conditions: Dictionary = {}


func get_stage_amount(entry: Dictionary, stage: int) -> int:
	var amounts: PackedInt32Array = entry.get("amount_by_stage", PackedInt32Array())
	if amounts.is_empty():
		return int(entry.get("amount", 0))
	return amounts[clampi(stage - 1, 0, amounts.size() - 1)]
