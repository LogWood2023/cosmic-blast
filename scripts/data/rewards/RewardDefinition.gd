class_name RewardDefinition
extends Resource
## Immutable reward card displayed by a regular or boss reward draft.

@export var reward_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var preview_text: String = ""
@export var reward_type: String = ""
@export var family_tag: String = ""
@export var role_tag: String = ""
@export var item_id: String = ""
@export var payload: Dictionary = {}
@export var tags: PackedStringArray = PackedStringArray()
