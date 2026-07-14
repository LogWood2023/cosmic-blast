extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var profiles: Array = RunManager.get_reward_profiles()
	if profiles.size() < 5:
		_fail("Reward event catalog should keep several narrative profiles.")
		return
	var node_id := _force_reward_node()
	var choices := RunManager.prepare_reward_event_choices(node_id, 3301)
	var node := RunManager.get_map_node(node_id)
	if String(node.get("reward_title", "")).is_empty() or String(node.get("reward_description", "")).is_empty():
		_fail("Reward event node should expose temporary title and narrative text.")
		return
	var repair_choice := _find_choice(choices, "repair")
	var hp_before := GameManager.player_hp
	var result := RunManager.resolve_reward_event_choice(node_id, String(repair_choice.get("choice_id", "")), 3301)
	if not bool(result.get("ok", false)) or int(result.get("healed", 0)) <= 0:
		_fail("Repair reward should resolve as a direct event reward.")
		return
	if GameManager.player_hp < hp_before or not RunManager.is_node_completed(node_id):
		_fail("Reward event should heal immediately and complete the node.")
		return
	print("Reward event profile check passed.")
	get_tree().quit(0)


func _find_choice(choices: Array, reward_type: String) -> Dictionary:
	for raw_choice in choices:
		var choice := Dictionary(raw_choice)
		if String(choice.get("reward_type", "")) == reward_type:
			return choice
	return {}


func _force_reward_node() -> int:
	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		node["type"] = RunManager.NODE_REWARD
		node["completed"] = false
		node["links"] = [RunManager.CENTER_ID]
		RunManager.map_nodes[i] = node
		var base := RunManager.map_nodes[RunManager.CENTER_ID]
		base["links"] = [node_id]
		RunManager.map_nodes[RunManager.CENTER_ID] = base
		return node_id
	return -1


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
