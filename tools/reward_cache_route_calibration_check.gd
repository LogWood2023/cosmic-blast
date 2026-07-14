extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var node_id := _force_reward_node()
	var nearby_id := _find_neighbor(node_id)
	var before := RunManager.get_map_node(nearby_id).duplicate(true)
	var choices := RunManager.prepare_reward_event_choices(node_id, 5501)
	var minerals_choice := _find_choice(choices, "minerals")
	var minerals_before := RunManager.minerals
	var result := RunManager.resolve_reward_event_choice(node_id, String(minerals_choice.get("choice_id", "")), 5501)
	if not bool(result.get("ok", false)) or RunManager.minerals <= minerals_before:
		_fail("Reward event should grant its selected reward immediately.")
		return
	if RunManager.get_map_node(nearby_id) != before:
		_fail("Reward event selection must not calibrate or mutate neighboring combat routes.")
		return
	print("Reward event route isolation check passed.")
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


func _find_neighbor(node_id: int) -> int:
	for node in RunManager.map_nodes:
		var candidate_id := int(node.get("id", -1))
		if candidate_id > 0 and candidate_id != node_id:
			return candidate_id
	return RunManager.CENTER_ID


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
