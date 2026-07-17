extends Node

const BalanceService := preload("res://scripts/core/BalanceService.gd")

var _failed: bool = false
func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_balance_contract()
	_check_context_and_mutation_contract()
	_check_legacy_choice_bridge()
	if not _failed:
		print("Run content contract check passed.")
		get_tree().quit(0)


func _check_balance_contract() -> void:
	_assert(BalanceService.get_stage_for_crisis(0) == 1, "Crisis 0 should be stage 1.")
	_assert(BalanceService.get_stage_for_crisis(5) == 2, "Crisis 5 should be stage 2.")
	_assert(BalanceService.get_stage_for_crisis(12) == 3, "Crisis 12 should be stage 3.")
	_assert(BalanceService.get_damage(&"normal") == 5, "Normal damage budget should be 5.")
	_assert(BalanceService.get_elite_ehp(3) == 20400, "Stage 3 elite EHP should be 20400.")
	_assert(BalanceService.get_boss_ehp(2) == 14500, "Stage 2 boss EHP should be 14500.")


func _check_context_and_mutation_contract() -> void:
	GameManager.player_hp = GameManager.PLAYER_MAX_HP
	RunManager.start_new_run()
	var context := RunManager.get_run_content_context()
	var original_minerals := RunManager.minerals
	var rejected := RunMutationSet.create("contract-rejected", "contract_check", 0, context.get_state_version())
	rejected.mineral_cost = 1
	var rejection := RunManager.commit_mutation(rejected)
	_assert(not bool(rejection.get("ok", true)), "Unaffordable mutation should be rejected.")
	_assert(RunManager.minerals == original_minerals, "Rejected mutation must not change minerals.")
	var mutation := RunMutationSet.create("contract-accepted", "contract_check", 0, context.get_state_version())
	mutation.add_action(&"grant_minerals", {"amount": 17})
	var committed := RunManager.commit_mutation(mutation)
	_assert(bool(committed.get("ok", false)), "Valid mutation should commit.")
	_assert(RunManager.minerals == original_minerals + 17, "Committed mutation should apply all actions.")
	var duplicate := RunManager.commit_mutation(mutation)
	_assert(not bool(duplicate.get("ok", true)), "Duplicate mutation should be rejected.")
	var stale := RunMutationSet.create("contract-stale", "contract_check", 0, context.get_state_version())
	stale.add_action(&"grant_minerals", {"amount": 1})
	var stale_result := RunManager.commit_mutation(stale)
	_assert(not bool(stale_result.get("ok", true)), "Stale mutation should be rejected.")


func _check_legacy_choice_bridge() -> void:
	var event_node_id := -1
	for node in RunManager.map_nodes:
		if String(node.get("type", "")) == RunManager.NODE_EVENT:
			event_node_id = int(node.get("id", -1))
			break
	_assert(event_node_id > 0, "Formal run should include an event node.")
	if _failed:
		return
	var context := RunManager.get_run_content_context()
	var choices := RunManager.prepare_choices(event_node_id, context, 4242)
	_assert(not choices.is_empty(), "Facade should forward legacy event choices.")
	if choices.is_empty():
		return
	for required_key in ["choice_id", "title", "description", "preview", "risk", "disabled_reason", "tags"]:
		_assert(choices[0].has(required_key), "ChoiceView is missing %s." % required_key)
	var mutation := RunManager.resolve_choice(event_node_id, String(choices[0].get("choice_id", "")), context, 4242)
	_assert(mutation != null, "Facade should return a legacy mutation instead of changing run state.")


func _assert(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
