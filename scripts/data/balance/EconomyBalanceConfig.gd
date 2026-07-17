class_name EconomyBalanceConfig
extends Resource

## Immutable currency and reward budget used by content resolvers.
@export var reward_minerals_range: Vector2i = Vector2i(50, 90)
@export var reward_repair_range: Vector2i = Vector2i(16, 37)
@export var shop_reroll_base_cost: int = 20
@export var shop_reroll_cost_step: int = 10
@export var equipment_drop_chance_range: Vector2 = Vector2(0.15, 0.45)
@export var stage_healing_budgets: Array[Vector2i] = [Vector2i(25, 40), Vector2i(35, 55), Vector2i(45, 70)]
@export var minimum_survival_option_health_percent: float = 0.30


func get_stage_healing_budget(stage: int) -> Vector2i:
	if stage_healing_budgets.is_empty():
		return Vector2i.ZERO
	return stage_healing_budgets[clampi(stage - 1, 0, stage_healing_budgets.size() - 1)]
