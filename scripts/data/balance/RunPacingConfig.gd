class_name RunPacingConfig
extends Resource

## Immutable baseline for formal-run routing and room pressure.
@export var crisis_thresholds: PackedInt32Array = PackedInt32Array([5, 12, 21])
@export var starting_compute_capacity: int = 5
@export var equipment_targets_per_boss: PackedInt32Array = PackedInt32Array([3, 5, 8])
@export var completed_nodes_min: int = 21
@export var battle_nodes_range: Vector2i = Vector2i(8, 9)
@export var event_nodes_range: Vector2i = Vector2i(6, 7)
@export var non_battle_nodes_range: Vector2i = Vector2i(5, 7)
@export var exploration_minutes_range: Vector2 = Vector2(3.0, 5.0)
@export var accelerated_exploration_minutes_range: Vector2 = Vector2(1.5, 3.0)
@export var choice_seconds_range: Vector2i = Vector2i(20, 45)


func get_stage_for_crisis(crisis: int) -> int:
	if crisis < crisis_thresholds[0]:
		return 1
	if crisis < crisis_thresholds[1]:
		return 2
	return 3
