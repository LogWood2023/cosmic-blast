class_name EventDefinition
extends Resource
## Immutable event authoring asset. Runtime state always remains in RunContentContext.

@export var event_id: String = ""
@export var title: String = ""
@export_multiline var narrative: String = ""
@export_range(1, 3, 1) var min_stage: int = 1
@export_range(1, 3, 1) var max_stage: int = 3
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
@export var category: String = "safe"
@export var family_tag: String = ""
@export var theme_tags: PackedStringArray = PackedStringArray()
@export var is_unique: bool = true
@export var prerequisites: Dictionary = {}
@export var options: Array[EventOptionData] = []
@export var balance_payload: Dictionary = {}


func supports_stage(stage: int) -> bool:
	return stage >= min_stage and stage <= max_stage
