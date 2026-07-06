extends Node


const SAMPLE_SEED_COUNT := 160
const EXPECTED_EXPLORATION_NODE_COUNT := 24
const MIN_BATTLE_NODES := 14
const MIN_EVENT_NODES := 3
const MIN_REWARD_NODES := 3

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	for seed_value in range(SAMPLE_SEED_COUNT):
		seed(seed_value)
		RunManager.call("_generate_world_map")
		_check_map_pacing(seed_value)
		if _failed:
			return
	print("World map pacing check passed.")
	get_tree().quit(0)


func _check_map_pacing(seed_value: int) -> void:
	var counts := {
		RunManager.NODE_BATTLE: 0,
		RunManager.NODE_EVENT: 0,
		RunManager.NODE_REWARD: 0,
	}
	var exploration_count := 0
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0:
			continue
		var node_type := String(node.get("type", ""))
		if node_type == RunManager.NODE_SPECIAL:
			continue
		exploration_count += 1
		counts[node_type] = int(counts.get(node_type, 0)) + 1
	if exploration_count != EXPECTED_EXPLORATION_NODE_COUNT:
		_fail("Seed %d should generate %d exploration nodes, got %d." % [
			seed_value,
			EXPECTED_EXPLORATION_NODE_COUNT,
			exploration_count,
		])
		return
	if int(counts.get(RunManager.NODE_BATTLE, 0)) < MIN_BATTLE_NODES:
		_fail("Seed %d should keep combat as the main route pressure, counts=%s." % [seed_value, str(counts)])
		return
	if int(counts.get(RunManager.NODE_EVENT, 0)) < MIN_EVENT_NODES:
		_fail("Seed %d should keep at least %d event decisions, counts=%s." % [seed_value, MIN_EVENT_NODES, str(counts)])
		return
	if int(counts.get(RunManager.NODE_REWARD, 0)) < MIN_REWARD_NODES:
		_fail("Seed %d should keep at least %d reward caches, counts=%s." % [seed_value, MIN_REWARD_NODES, str(counts)])
		return


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
