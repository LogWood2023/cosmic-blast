class_name EconomyService
extends RefCounted

const SHOP_SLOT_COUNT: int = 12
const REROLL_BASE_COST: int = 18
const REROLL_STAGE_COST: int = 10
const REROLL_STEP_COST: int = 14

func get_salvage_income(stage: int, salvage_ratio: float) -> int:
	var ranges := [Vector2i(55, 75), Vector2i(85, 115), Vector2i(125, 170)]
	var band: Vector2i = ranges[clampi(stage - 1, 0, ranges.size() - 1)]
	return int(round(lerpf(float(band.x), float(band.y), clampf(salvage_ratio, 0.0, 1.0))))

func get_reroll_cost(reroll_count: int, free_rerolls: int = 0, stage: int = 1, crisis_base_bonus: int = 0) -> int:
	if reroll_count < free_rerolls:
		return 0
	var paid_rerolls := maxi(0, reroll_count - free_rerolls)
	return REROLL_BASE_COST + clampi(stage, 1, 3) * REROLL_STAGE_COST + paid_rerolls * REROLL_STEP_COST + maxi(0, crisis_base_bonus)

func create_shop_draft(owned_ids: Array, crisis_level: int, preferred_family: String, seed: int) -> Array[String]:
	return EquipmentCatalog.get_shop_offer_item_ids(owned_ids, crisis_level, preferred_family, SHOP_SLOT_COUNT, seed)

func create_purchase_mutation(item_id: String, minerals: int) -> Dictionary:
	var price := EquipmentCatalog.get_price(item_id)
	return {"accepted": price > 0 and minerals >= price, "item_id": item_id, "minerals_delta": -price, "role": EquipmentCatalog.get_role(item_id)}


func create_purchase_run_mutation(item_id: String, node_id: int, expected_state_version: int) -> RunMutationSet:
	var mutation := RunMutationSet.create("shop:%s:%d" % [item_id, expected_state_version], "economy_service", node_id, expected_state_version)
	mutation.mineral_cost = EquipmentCatalog.get_price(item_id)
	mutation.add_action(&"grant_equipment", {"item_id": item_id})
	mutation.metadata = {"transaction": "purchase", "role": EquipmentCatalog.get_role(item_id)}
	return mutation
