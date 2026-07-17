class_name EventResolver
extends RefCounted
## Converts immutable event assets into choice views and mutations. No RunManager reference is held.

const LEAVE_OPTION_ID: String = "leave"


func make_choice_views(definition: EventDefinition, context: RunContentContext) -> Array[Dictionary]:
	var stage := _stage_for_context(context)
	var views: Array[Dictionary] = []
	for option in definition.options:
		var eligible := _option_conditions_met(option, context)
		var affordable := _can_afford(option, context, stage)
		var disabled_reason := ""
		if not eligible:
			disabled_reason = "当前航程条件不足。"
		elif not affordable:
			disabled_reason = "资源不足。"
		views.append({
			"choice_id": "%s:%s" % [definition.event_id, option.option_id],
			"event_id": definition.event_id,
			"event_title": definition.title,
			"narrative": definition.narrative,
			"title": option.title,
			"description": option.description,
			"flavor_text": option.description,
			"preview": option.preview_text,
			"cost_preview": _cost_preview(option, stage, context),
			"effect_preview": _effect_preview(definition, option, stage, context),
			"risk": _risk_for_category(definition.category),
			"disabled_reason": disabled_reason,
			"tags": option.ai_tags,
			"category": definition.category,
		})
	views.append({
		"choice_id": "%s:%s" % [definition.event_id, LEAVE_OPTION_ID],
		"event_id": definition.event_id,
		"event_title": definition.title,
		"narrative": definition.narrative,
		"title": "离开",
		"description": "保持当前航程，不发生任何变化。",
		"flavor_text": "保持当前航程，不发生任何变化。",
		"preview": "不支付费用，也不获得收益。",
		"cost_preview": "无",
		"effect_preview": "无",
		"risk": 0,
		"disabled_reason": "",
		"tags": PackedStringArray(["safe", "leave"]),
		"category": "leave",
	})
	return views


func resolve(definition: EventDefinition, option_id: String, context: RunContentContext) -> RunMutationSet:
	var mutation := RunMutationSet.create(
		"event:%s:%s:%d" % [definition.event_id, option_id, context.get_state_version()],
		definition.event_id,
		int(context.to_dictionary().get("current_node_id", -1)),
		context.get_state_version()
	)
	mutation.metadata = {"event_id": definition.event_id, "event_category": definition.category}
	if option_id == LEAVE_OPTION_ID:
		mutation.add_action(&"grant_minerals", {"amount": 0})
		return mutation
	var selected := _find_option(definition, option_id)
	if selected == null:
		return null
	var stage := _stage_for_context(context)
	if not _option_conditions_met(selected, context) or not _can_afford(selected, context, stage):
		return null
	for cost in selected.costs:
		match String(cost.get("kind", "")):
			"minerals": mutation.mineral_cost += _cost_amount(selected, cost, stage, context)
			"hp": mutation.hp_cost += _cost_amount(selected, cost, stage, context)
	for effect in selected.effects:
		var action := String(effect.get("action", ""))
		var payload := Dictionary(effect.get("payload", {})).duplicate(true)
		if effect.has("amount_by_stage"):
			payload["amount"] = _effect_amount(definition, selected, effect, stage, context)
		if action == "add_event_contract":
			payload["id"] = String(payload.get("id", definition.event_id))
			payload["remaining_nodes"] = maxi(1, selected.duration_nodes)
		mutation.add_action(StringName(action), payload)
	return mutation


func get_contract_snapshot(definition: EventDefinition, option_id: String, context: RunContentContext) -> Dictionary:
	var option := _find_option(definition, option_id)
	if option == null or option.duration_nodes <= 0:
		return {}
	return {"event_id": definition.event_id, "option_id": option_id, "remaining_nodes": option.duration_nodes, "state_version": context.get_state_version()}


func _find_option(definition: EventDefinition, option_id: String) -> EventOptionData:
	for option in definition.options:
		if option.option_id == option_id:
			return option
	return null


func _stage_for_context(context: RunContentContext) -> int:
	var crisis := int(context.to_dictionary().get("crisis_level", 0))
	return 1 if crisis < 5 else (2 if crisis < 12 else 3)


func _option_conditions_met(option: EventOptionData, context: RunContentContext) -> bool:
	var required_hp := int(option.requires_conditions.get("minimum_hp", 0))
	if context.get_player_hp() < required_hp:
		return false
	return true


func _can_afford(option: EventOptionData, context: RunContentContext, stage: int) -> bool:
	var minerals := context.get_minerals()
	var hp := context.get_player_hp()
	for cost in option.costs:
		var amount := _cost_amount(option, cost, stage, context)
		match String(cost.get("kind", "")):
			"minerals": minerals -= amount
			"hp": hp -= amount
	return minerals >= 0 and hp > 0


func _cost_preview(option: EventOptionData, stage: int, context: RunContentContext) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for cost in option.costs:
		var amount := _cost_amount(option, cost, stage, context)
		match String(cost.get("kind", "")):
			"minerals": parts.append("支付 %d 星髓矿" % amount)
			"hp": parts.append("失去 %d 生命" % amount)
	return "无费用" if parts.is_empty() else "，".join(parts)


func _effect_preview(definition: EventDefinition, option: EventOptionData, stage: int, context: RunContentContext) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for effect in option.effects:
		var amount := _effect_amount(definition, option, effect, stage, context)
		match String(effect.get("action", "")):
			"grant_minerals": parts.append("获得 %d 星髓矿" % amount)
			"heal": parts.append("恢复 %d 生命" % amount)
			"grant_compute": parts.append("获得 %d 算力" % amount)
			"add_crisis": parts.append("危机 +%d" % amount)
			"add_event_contract": parts.append("签订 %d 节点协议" % option.duration_nodes)
	return "获得航程情报" if parts.is_empty() else "，".join(parts)


func _risk_for_category(category: String) -> int:
	return 0 if category == "safe" else (2 if category in ["gamble", "bridge"] else 1)


func _cost_amount(option: EventOptionData, cost: Dictionary, stage: int, context: RunContentContext) -> int:
	var amount := option.get_stage_amount(cost, stage)
	var event_modifiers := _event_modifiers(context)
	match String(cost.get("kind", "")):
		"minerals": return int(ceil(float(amount) * float(event_modifiers.get("mineral_cost_mult", 1.0))))
		"hp": return int(ceil(float(amount) * float(event_modifiers.get("hp_cost_mult", 1.0))))
	return amount


func _effect_amount(definition: EventDefinition, option: EventOptionData, effect: Dictionary, stage: int, context: RunContentContext) -> int:
	var amount := option.get_stage_amount(effect, stage)
	if String(effect.get("action", "")) == "grant_minerals" and _risk_for_category(definition.category) >= 2:
		amount = int(round(float(amount) * float(_event_modifiers(context).get("high_risk_reward_mult", 1.0))))
	return amount


func _event_modifiers(context: RunContentContext) -> Dictionary:
	var active_rules := context.get_active_rule_snapshot()
	var advanced := Dictionary(active_rules.get("advanced_crisis", {}))
	return Dictionary(advanced.get("event", {}))
