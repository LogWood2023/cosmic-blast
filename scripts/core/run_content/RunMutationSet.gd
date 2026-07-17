class_name RunMutationSet
extends RefCounted
## A declarative, all-or-nothing change request submitted to RunManager.

const ERROR_INVALID: String = "invalid_mutation"
const ERROR_STALE: String = "stale_state_version"
const ERROR_DUPLICATE: String = "duplicate_commit"
const ERROR_INSUFFICIENT_MINERALS: String = "insufficient_minerals"
const ERROR_INSUFFICIENT_HP: String = "insufficient_hp"
const ERROR_UNKNOWN_ACTION: String = "unknown_action"

var mutation_id: String
var source_id: String
var node_id: int
var expected_state_version: int
var mineral_cost: int = 0
var hp_cost: int = 0
var actions: Array[Dictionary] = []
var metadata: Dictionary = {}


static func create(id: String, source: String, node: int, state_version: int) -> RunMutationSet:
	var mutation := RunMutationSet.new()
	mutation.mutation_id = id
	mutation.source_id = source
	mutation.node_id = node
	mutation.expected_state_version = state_version
	return mutation


func add_action(action: StringName, payload: Dictionary = {}) -> RunMutationSet:
	actions.append({"action": String(action), "payload": payload.duplicate(true)})
	return self


func validate(context: RunContentContext, allowed_actions: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	if mutation_id.strip_edges().is_empty() or source_id.strip_edges().is_empty():
		errors.append(ERROR_INVALID)
	if actions.is_empty() and String(metadata.get("legacy_kind", "")).is_empty():
		errors.append(ERROR_INVALID)
	if expected_state_version != context.get_state_version():
		errors.append(ERROR_STALE)
	if mineral_cost < 0 or hp_cost < 0:
		errors.append(ERROR_INVALID)
	if mineral_cost > context.get_minerals():
		errors.append(ERROR_INSUFFICIENT_MINERALS)
	if hp_cost >= context.get_player_hp():
		errors.append(ERROR_INSUFFICIENT_HP)
	for entry in actions:
		if not allowed_actions.has(String(entry.get("action", ""))):
			errors.append(ERROR_UNKNOWN_ACTION)
	return errors
