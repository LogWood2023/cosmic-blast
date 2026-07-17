class_name RewardPoolData
extends Resource
## Authoring asset for one of the eight launch reward pools.

@export var pool_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var weight: float = 1.0
@export var min_stage: int = 1
@export var reward_types: PackedStringArray = PackedStringArray()
@export var tags: PackedStringArray = PackedStringArray()
@export var balance_payload: Dictionary = {}
