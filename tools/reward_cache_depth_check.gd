extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var node_id := _force_reward_node()
	var choices := RunManager.prepare_reward_event_choices(node_id, 9001)
	if choices.size() != 3:
		_fail("Reward event should always present three options.")
		return
	for raw_choice in choices:
		var choice := Dictionary(raw_choice)
		if String(choice.get("preview", "")).is_empty() or String(choice.get("reward_type", "")).is_empty():
			_fail("Temporary reward options must expose their exact player-facing effect.")
			return
	if RunManager.start_explore_node(node_id):
		_fail("Reward events must not open an explore combat room.")
		return
	print("Reward event depth check passed.")
	get_tree().quit(0)


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
