class_name EconomyBalanceConfig
extends Resource

## Immutable currency and reward budget used by content resolvers.
@export var reward_minerals_range: Vector2i = Vector2i(50, 90)
@export var reward_repair_range: Vector2i = Vector2i(16, 37)
@export var shop_reroll_base_cost: int = 20
@export var shop_reroll_cost_step: int = 10
@export var shop_reroll_repeat_step: int = 14
@export var shop_offer_count: int = 12
@export var shop_general_slots: int = 5
@export var shop_family_slots: int = 3
@export var shop_build_slots: int = 2
@export var shop_survival_slots: int = 1
@export var shop_wildcard_slots: int = 1
@export var equipment_drop_chance_range: Vector2 = Vector2(0.15, 0.45)
@export var equipment_drop_chances: PackedFloat32Array = PackedFloat32Array([0.28, 0.36, 0.48])
@export var equipment_drop_chance_cap: float = 0.85
@export var equipment_dry_nodes: int = 3
@export var starter_dry_drafts: int = 4
@export var amplifier_dry_drafts: int = 4
@export var stage_healing_budgets: Array[Vector2i] = [Vector2i(25, 40), Vector2i(35, 55), Vector2i(45, 70)]
@export var minimum_survival_option_health_percent: float = 0.30


func get_stage_healing_budget(stage: int) -> Vector2i:
	if stage_healing_budgets.is_empty():
		return Vector2i.ZERO
	return stage_healing_budgets[clampi(stage - 1, 0, stage_healing_budgets.size() - 1)]
