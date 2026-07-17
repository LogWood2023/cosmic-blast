class_name RunContentFacade
extends RefCounted
## Stateless facade. Legacy behavior enters only through injected adapters owned by RunManager.

var _prepare_legacy: Callable
var _resolve_legacy: Callable
var _event_service := EventService.new()
var _reward_service := RewardService.new()
var _beacon_service := BeaconService.new()


func set_legacy_adapters(prepare_adapter: Callable, resolve_adapter: Callable) -> void:
	_prepare_legacy = prepare_adapter
	_resolve_legacy = resolve_adapter


func prepare_choices(node_id: int, context: RunContentContext, seed: int) -> Array[Dictionary]:
	var node := context.get_node(node_id)
	if node.is_empty():
		return []
	var node_type := String(node.get("type", node.get("node_type", "")))
	if node_type == "event":
		return _event_service.prepare_choices(node_id, context, seed)
	if node_type == "reward":
		return _reward_service.prepare_choices(node_id, context, seed)
	if node_type == "beacon":
		return _beacon_service.prepare_choices(node_id, context, seed, MechanicRuntime.SUPPORTED_TRIGGERS)
	if _prepare_legacy.is_null():
		return []
	var raw_choices: Array = _prepare_legacy.call(node_id, seed)
	var choices: Array[Dictionary] = []
	for raw_choice in raw_choices:
		var choice := Dictionary(raw_choice).duplicate(true)
		choice["choice_id"] = String(choice.get("choice_id", choice.get("id", "")))
		choice["title"] = String(choice.get("title", ""))
		choice["description"] = String(choice.get("description", ""))
		choice["preview"] = String(choice.get("preview", ""))
		choice["risk"] = int(choice.get("risk_level", 0))
		choice["disabled_reason"] = String(choice.get("disabled_reason", ""))
		choice["tags"] = Array(choice.get("tags", []))
		choices.append(choice)
	return choices


func resolve_choice(node_id: int, choice_id: String, context: RunContentContext, seed: int) -> RunMutationSet:
	var node := context.get_node(node_id)
	var node_type := String(node.get("type", node.get("node_type", "")))
	if node_type == "event":
		return _event_service.resolve_choice(node_id, choice_id, context)
	if node_type == "reward":
		return _reward_service.resolve_choice(node_id, choice_id, context)
	if node_type == "beacon":
		return _beacon_service.resolve_choice(node_id, choice_id, context)
	if _resolve_legacy.is_null():
		return null
	return _resolve_legacy.call(node_id, choice_id, context.get_state_version(), seed) as RunMutationSet


func validate_mutation(context: RunContentContext, mutation: RunMutationSet, allowed_actions: PackedStringArray) -> PackedStringArray:
	if mutation == null:
		return PackedStringArray([RunMutationSet.ERROR_INVALID])
	return mutation.validate(context, allowed_actions)


func get_active_rule_snapshot(context: RunContentContext) -> Dictionary:
	return context.get_active_rule_snapshot()
