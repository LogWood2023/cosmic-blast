class_name CombatBalanceConfig
extends Resource

## Immutable combat budgets. Keys are intentionally stable contract identifiers.
@export var player_max_hp: int = 100
@export var player_move_speed: float = 300.0
@export var player_base_attack: int = 10
@export var player_base_fire_interval: float = 0.25
@export var damage_values: Dictionary = {
	"dot_min": 1,
	"dot_max": 3,
	"normal": 5,
	"dangerous_min": 8,
	"dangerous_max": 12,
	"heavy_min": 34,
	"heavy_max": 40,
}
@export var enemy_base_hp: int = 240
@export var enemy_stage_multipliers: PackedFloat32Array = PackedFloat32Array([1.0, 2.1, 4.3])
@export var elite_ehp: PackedInt32Array = PackedInt32Array([4800, 9600, 20400])
@export var boss_ehp: PackedInt32Array = PackedInt32Array([5600, 14500, 36000])
@export var dash_charges: int = 2
@export var dash_charge_seconds: float = 1.8
@export var dash_distance: float = 420.0
@export var dash_speed: float = 2400.0
@export var dash_invulnerable_tail: float = 0.05
@export var dash_base_damage_mult: float = 0.75
@export var dash_enemy_hit_radius: float = 52.0
@export var dash_boss_hit_radius: float = 120.0


func get_damage(category: StringName) -> int:
	return int(damage_values.get(String(category), 0))


func get_stage_value(values: PackedInt32Array, stage: int) -> int:
	if values.is_empty():
		return 0
	return values[clampi(stage - 1, 0, values.size() - 1)]
