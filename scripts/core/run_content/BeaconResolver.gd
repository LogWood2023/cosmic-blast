class_name BeaconResolver
extends RefCounted
## Produces an immutable activation request; no gameplay node or RunManager is referenced.


func make_choice_view(beacon: BeaconData, active_rule_keys: Array) -> Dictionary:
	var disabled := active_rule_keys.has(beacon.rule_key)
	return {
		"choice_id": beacon.beacon_id,
		"title": beacon.title,
		"description": beacon.description,
		"preview": "规则：%s" % beacon.rule_key,
		"rule_key": beacon.rule_key,
		"family_tag": beacon.family_tag,
		"disabled_reason": "同类规则已激活。" if disabled else "",
		"tags": PackedStringArray([beacon.category, beacon.family_tag]),
	}


func resolve_activation(beacon: BeaconData, context: RunContentContext, node_id: int) -> RunMutationSet:
	var mutation := RunMutationSet.create("beacon:%s:%d" % [beacon.beacon_id, context.get_state_version()], "beacon_service", node_id, context.get_state_version())
	mutation.metadata = {"beacon_id": beacon.beacon_id, "rule_key": beacon.rule_key, "route_echo": beacon.route_echo.duplicate(true)}
	mutation.add_action(&"add_event_contract", {"id": "beacon:%s" % beacon.beacon_id, "effect_type": "activate_rule", "rule_key": beacon.rule_key, "parameters": beacon.rule_parameters.duplicate(true), "remaining_nodes": 999})
	return mutation
