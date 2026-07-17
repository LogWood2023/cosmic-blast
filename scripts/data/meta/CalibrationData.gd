class_name CalibrationData
extends Resource
## Immutable definition for one preflight calibration. Meta saves only the ID.

@export var calibration_id: String
@export var display_name: String
@export_multiline var description: String
@export var unlock_condition: String
@export var effects: Dictionary = {}
