class_name BeaconData
extends Resource
## Immutable whole-run rule definition. A beacon must declare exactly one rule_key.

@export var beacon_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var family_tag: String = "general"
@export var category: String = "general"
@export var role_tag: String = ""
@export var weight: float = 1.0
@export var risk: int = 0
@export var rule_key: String = ""
@export var rule_parameters: Dictionary = {}
@export var mechanic_hook: String = ""
@export var exclusion_group: String = ""
@export var route_echo: Dictionary = {}


func is_valid_definition() -> bool:
	return not beacon_id.is_empty() and not rule_key.is_empty()
