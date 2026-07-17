class_name AdvancedCrisisData
extends Resource
## One immutable, cumulative advanced-crisis rule layer.

@export_range(1, 10) var level: int
@export var crisis_id: String
@export var display_name: String
@export_multiline var description: String
@export var modifiers: Dictionary = {}
