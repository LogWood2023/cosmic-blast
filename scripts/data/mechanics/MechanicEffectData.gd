class_name MechanicEffectData
extends Resource

@export var effect_id: String = ""
@export var trigger: String = ""
@export var action: String = ""
@export var rule_key: String = ""
@export_range(0.0, 1.0, 0.01) var proc_coefficient: float = 1.0
@export_range(0.0, 60.0, 0.1) var cooldown_seconds: float = 0.0
@export_range(0, 60, 1) var max_triggers_per_second: int = 0
@export var inherit_mask: PackedStringArray = ["damage", "direction", "target"]
@export var required_rule_keys: PackedStringArray = []
@export var parameters: Dictionary = {}
