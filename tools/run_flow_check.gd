extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_manager = root.get_node_or_null("RunManager")
	if run_manager == null:
		push_error("RunManager autoload not found")
		quit(1)
		return
	run_manager.start_new_run()
	assert(run_manager.map_nodes.size() == 25)
	assert(run_manager.compute_capacity == 5)
	assert(run_manager.crisis_level == 0)
	var first_accessible := -1
	for node in run_manager.map_nodes:
		var id := int(node.get("id", -1))
		if id > 0 and run_manager.is_node_accessible(id):
			first_accessible = id
			break
	assert(first_accessible > 0)
	assert(run_manager.start_explore_node(first_accessible))
	run_manager.pending_room_loot["minerals"] = 10
	var result: Dictionary = run_manager.complete_explore_room_success()
	assert(bool(result.get("ok", false)))
	assert(run_manager.crisis_level == 1)
	assert(run_manager.compute_capacity == 6)
	assert(run_manager.minerals == 10)
	assert(run_manager.is_node_completed(first_accessible))
	run_manager.crisis_level = 5
	assert(run_manager.is_alert_active())
	for node in run_manager.map_nodes:
		var id := int(node.get("id", -1))
		if id > 0 and not run_manager.is_node_completed(id):
			assert(not run_manager.is_node_accessible(id))
	assert(run_manager.begin_crisis_boss())
	assert(not run_manager.pending_boss_scene.is_empty())
	quit(0)
