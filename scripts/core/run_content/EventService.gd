class_name EventService
extends RefCounted
## Loads event assets and applies deterministic eligibility/variety rules.

const EVENT_DIRECTORY: String = "res://data/events"
const BalanceServiceScript := preload("res://scripts/core/BalanceService.gd")
const LEGACY_ID_MIGRATIONS: Dictionary = {
	"procurement_discount": "procurement_future",
	"procurement_reroll_voucher": "procurement_future",
	"ore_vault": "quantum_crate",
	"sealed_armory": "sealed_weapon_cache",
}

var _resolver: EventResolver = EventResolver.new()
var _definitions: Array[EventDefinition] = []
var _by_id: Dictionary = {}


func _init() -> void:
	_load_definitions()


func get_definitions() -> Array[EventDefinition]:
	return _definitions.duplicate()


func get_definition(event_id: String) -> EventDefinition:
	var resolved_id := String(LEGACY_ID_MIGRATIONS.get(event_id, event_id))
	return _by_id.get(resolved_id, null) as EventDefinition


func prepare_choices(node_id: int, context: RunContentContext, seed: int, choice_count: int = 3) -> Array[Dictionary]:
	var node := context.get_node(node_id)
	if node.is_empty() or bool(node.get("completed", false)):
		return []
	var candidates := get_candidate_definitions(context, node)
	if candidates.is_empty():
		return []
	var selected := _select_varied_candidates(candidates, context, seed, choice_count)
	var views: Array[Dictionary] = []
	for definition in selected:
		views.append_array(_resolver.make_choice_views(definition, context))
	return views


func resolve_choice(node_id: int, choice_id: String, context: RunContentContext) -> RunMutationSet:
	var parts := choice_id.split(":", false, 1)
	if parts.size() != 2 or context.get_node(node_id).is_empty():
		return null
	var definition := get_definition(parts[0])
	if definition == null or not get_candidate_definitions(context, context.get_node(node_id)).has(definition):
		return null
	var mutation := _resolver.resolve(definition, parts[1], context)
	if mutation != null:
		mutation.node_id = node_id
	return mutation


func get_candidate_definitions(context: RunContentContext, node: Dictionary) -> Array[EventDefinition]:
	var snapshot := context.to_dictionary()
	var stage := 1 if int(snapshot.get("crisis_level", 0)) < 5 else (2 if int(snapshot.get("crisis_level", 0)) < 12 else 3)
	var active_rules := context.get_active_rule_snapshot()
	var seen: Array = active_rules.get("seen_event_ids", [])
	var candidates: Array[EventDefinition] = []
	for definition in _definitions:
		if not definition.supports_stage(stage):
			continue
		if definition.is_unique and seen.has(definition.event_id):
			continue
		if not _definition_conditions_met(definition, snapshot, node):
			continue
		candidates.append(definition)
	return candidates


func _load_definitions() -> void:
	var directory := DirAccess.open(EVENT_DIRECTORY)
	if directory == null:
		push_error("EventService: event directory is unavailable: %s" % EVENT_DIRECTORY)
		return
	for filename in directory.get_files():
		if not filename.ends_with(".tres"):
			continue
		var definition := load("%s/%s" % [EVENT_DIRECTORY, filename]) as EventDefinition
		if definition == null or definition.event_id.is_empty() or definition.options.size() < 2:
			push_error("EventService: invalid event resource %s" % filename)
			continue
		_apply_master_balance(definition)
		_definitions.append(definition)
		_by_id[definition.event_id] = definition
	_definitions.sort_custom(func(a: EventDefinition, b: EventDefinition) -> bool: return a.event_id < b.event_id)


func _apply_master_balance(definition: EventDefinition) -> void:
	var record := BalanceServiceScript.get_record_snapshot("event", definition.event_id)
	if record.is_empty():
		return
	var attributes: Dictionary = record.attributes
	var payload := Dictionary(attributes.get("payload", {}))
	definition.balance_payload = payload.duplicate(true)
	definition.title = String(record.get("name", definition.title))
	definition.weight = float(attributes.get("weight", definition.weight))
	definition.family_tag = String(attributes.get("family", definition.family_tag))
	var risk := int(attributes.get("risk", 0))
	definition.category = "safe" if risk <= 0 else ("gamble" if risk >= 2 else ("bridge" if String(attributes.get("role", "")) == "bridge" else "risk"))
	definition.is_unique = bool(payload.get("unique", definition.is_unique))
	if payload.has("requires"):
		definition.prerequisites["required_families"] = Array(payload.requires)
	var duration := int(attributes.get("duration_nodes", 0))
	if duration > 0 and not definition.options.is_empty():
		definition.options[0].duration_nodes = duration
	for option_index in mini(2, definition.options.size()):
		var prefix := "a." if option_index == 0 else "b."
		for payload_key_variant in payload:
			var payload_key := String(payload_key_variant)
			if payload_key.begins_with(prefix):
				_apply_option_amount(definition.options[option_index], payload_key.trim_prefix(prefix), payload[payload_key_variant])


func _apply_option_amount(option: EventOptionData, key: String, value: Variant) -> void:
	var cost_kind := "hp" if key == "hp_loss" else ("minerals" if key in ["mineral_cost", "prepay", "stake"] else "")
	if not cost_kind.is_empty():
		for cost in option.costs:
			if String(cost.get("kind", "")) == cost_kind:
				_set_amount(cost, value)
				return
	var action := ""
	match key:
		"minerals": action = "grant_minerals"
		"heal": action = "heal"
		"compute": action = "grant_compute"
		"crisis": action = "add_crisis"
	if not action.is_empty():
		for effect in option.effects:
			if String(effect.get("action", "")) == action:
				_set_amount(effect, value)
				return
	for effect in option.effects:
		if String(effect.get("action", "")) == "add_event_contract":
			var contract_payload := Dictionary(effect.get("payload", {}))
			contract_payload[key] = value
			effect["payload"] = contract_payload
			return


func _set_amount(entry: Dictionary, value: Variant) -> void:
	if value is PackedInt32Array:
		entry["amount_by_stage"] = value
		entry.erase("amount")
	else:
		entry["amount"] = int(value)
		entry.erase("amount_by_stage")


func _definition_conditions_met(definition: EventDefinition, snapshot: Dictionary, node: Dictionary) -> bool:
	if bool(definition.prerequisites.get("requires_equipment", false)) and Array(snapshot.get("equipment_inventory", [])).size() < 2:
		return false
	var required_families: Array = definition.prerequisites.get("required_families", [])
	if not required_families.is_empty():
		var families: Array = Dictionary(snapshot.get("active_rules", {})).get("family_tags", snapshot.get("family_tags", []))
		for family in required_families:
			if not families.has(family):
				return false
	if bool(node.get("completed", false)):
		return false
	return true


func _select_varied_candidates(candidates: Array[EventDefinition], context: RunContentContext, seed: int, count: int) -> Array[EventDefinition]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pool := candidates.duplicate()
	var selected: Array[EventDefinition] = []
	var recent_families: Array = context.get_active_rule_snapshot().get("recent_event_families", [])
	if int(context.to_dictionary().get("completed_node_count", 0)) < 4:
		var safe_pool: Array[EventDefinition] = []
		for definition in pool:
			if definition.category == "safe":
				safe_pool.append(definition)
		var safe_choice := _take_weighted(safe_pool, rng)
		if safe_choice != null:
			selected.append(safe_choice)
			pool.erase(safe_choice)
	while selected.size() < count:
		var eligible_pool: Array[EventDefinition] = []
		for definition in pool:
			if not definition.family_tag.is_empty() and recent_families.size() >= 2 and recent_families[-1] == definition.family_tag and recent_families[-2] == definition.family_tag:
				continue
			eligible_pool.append(definition)
		var choice := _take_weighted(eligible_pool, rng)
		if choice == null:
			break
		selected.append(choice)
		pool.erase(choice)
	return selected


func _take_weighted(pool: Array[EventDefinition], rng: RandomNumberGenerator) -> EventDefinition:
	if pool.is_empty():
		return null
	var total_weight: float = 0.0
	for definition in pool:
		total_weight += maxf(0.0, definition.weight)
	if total_weight <= 0.0:
		return pool[rng.randi_range(0, pool.size() - 1)]
	var roll := rng.randf_range(0.0, total_weight)
	for definition in pool:
		roll -= maxf(0.0, definition.weight)
		if roll <= 0.0:
			return definition
	return pool.back()
