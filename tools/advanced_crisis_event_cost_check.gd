extends Node

const EventService := preload("res://scripts/core/run_content/EventService.gd")
const RunContentContext := preload("res://scripts/core/run_content/RunContentContext.gd")
const AdvancedCrisisResolver := preload("res://scripts/core/AdvancedCrisisResolver.gd")


func _ready() -> void:
	var context := RunContentContext.from_snapshot({
		"state_version": 1,
		"crisis_level": 0,
		"minerals": 999,
		"player_hp": 100,
		"map_nodes": [{"id": 7, "type": "event", "completed": false}],
		"active_rules": {"advanced_crisis": AdvancedCrisisResolver.new().resolve(4)},
	})
	var service := EventService.new()
	var cost_mutation := service.resolve_choice(7, "overdrawn_core:overdraw", context)
	if cost_mutation == null or cost_mutation.hp_cost != 15:
		_fail("Crisis 4 did not apply the 20% event HP cost multiplier.")
		return
	var reward_mutation := service.resolve_choice(7, "ore_pledge:sell", context)
	if reward_mutation == null or reward_mutation.actions.is_empty() or int(Dictionary(reward_mutation.actions[0]).get("payload", {}).get("amount", 0)) != 20:
		_fail("Crisis 4 did not apply high-risk event reward scaling.")
		return
	print("Advanced crisis event cost check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
