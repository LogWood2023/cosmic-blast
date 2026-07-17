class_name RewardResolver
extends RefCounted
## Converts reward cards to declarative mutations. It never owns inventory or RunManager state.


func make_choice_view(definition: RewardDefinition) -> Dictionary:
	return {
		"choice_id": definition.reward_id,
		"title": definition.title,
		"description": definition.description,
		"preview": definition.preview_text,
		"reward_type": definition.reward_type,
		"family_tag": definition.family_tag,
		"role_tag": definition.role_tag,
		"item_id": definition.item_id,
		"tags": definition.tags,
		"disabled_reason": "",
	}


func resolve(definition: RewardDefinition, context: RunContentContext, node_id: int) -> RunMutationSet:
	var mutation := RunMutationSet.create(
		"reward:%s:%d" % [definition.reward_id, context.get_state_version()],
		"reward_service",
		node_id,
		context.get_state_version()
	)
	mutation.metadata = {"reward_id": definition.reward_id, "reward_type": definition.reward_type}
	match definition.reward_type:
		"equipment":
			mutation.add_action(&"grant_equipment", {"item_id": definition.item_id})
		"minerals":
			mutation.add_action(&"grant_minerals", {"amount": int(definition.payload.get("amount", 0))})
		"heal":
			mutation.add_action(&"heal", {"amount": int(definition.payload.get("amount", 0))})
		"compute":
			mutation.add_action(&"grant_compute", {"amount": int(definition.payload.get("amount", 0))})
		"maintenance":
			mutation.add_action(&"grant_compute", {"amount": 2})
			mutation.add_action(&"heal", {"amount": int(definition.payload.get("heal", 25))})
			mutation.add_action(&"add_event_contract", {"id": "boss_maintenance_equipment_weight", "remaining_nodes": 2, "effect_type": "equipment_weight"})
		_:
			return null
	return mutation
