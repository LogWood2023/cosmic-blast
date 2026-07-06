extends Node


const MINERAL_PICKUP_SCENE := preload("res://scenes/gameplay/explore/MineralPickup.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var node_id := _first_accessible_node()
	if node_id <= 0 or not RunManager.start_explore_node(node_id):
		_fail("Could not start explore node for mineral collect feedback check.")
		return
	var node := RunManager.get_map_node(node_id)
	node["reward_mult"] = 1.0
	RunManager.map_nodes[node_id] = node
	GameManager.next_explore_room_config["reward_mineral_mult"] = 1.0
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}

	var scene := Node2D.new()
	scene.name = "MineralCollectFeedbackCheck"
	add_child(scene)

	var player := PLAYER_SCENE.instantiate() as Area2D
	player.global_position = Vector2(520, 500)
	scene.add_child(player)

	var pickup := MINERAL_PICKUP_SCENE.instantiate()
	pickup.global_position = Vector2(500, 500)
	pickup.attract_delay = 0.0
	scene.add_child(pickup)
	pickup.setup(7, player, false)

	for _i in range(60):
		await get_tree().process_frame
		if not is_instance_valid(pickup) or int(RunManager.pending_room_loot.get("minerals", 0)) == 7:
			break

	var pending_minerals := int(RunManager.pending_room_loot.get("minerals", 0))
	if pending_minerals != 7:
		_fail("Collecting a mineral pickup should add 7 pending minerals, got %d." % pending_minerals)
		return
	if _feedback_count() < 1:
		_fail("Collecting a mineral pickup should spawn a visible collect flash.")
		return
	if not _has_mineral_label_text("星髓"):
		_fail("Collecting a mineral pickup should show polished Chinese mineral text.")
		return
	var trail := _find_collect_trail()
	if trail == null:
		_fail("Collecting a mineral pickup should spawn a flying mineral trail.")
		return
	var trail_start: Vector2 = trail.get_meta("start_position", Vector2.ZERO)
	var trail_target: Vector2 = trail.get_meta("target_position", Vector2.ZERO)
	if trail_start.distance_to(Vector2(500, 500)) > 4.0:
		_fail("Mineral trail should remember the pickup origin, got %s." % str(trail_start))
		return
	if trail_target.distance_to(player.global_position) > 6.0:
		_fail("Mineral trail should fly toward the player, got %s." % str(trail_target))
		return

	print("Mineral collect feedback check passed.")
	get_tree().quit(0)


func _feedback_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(&"mineral_collect_feedback"):
		if is_instance_valid(node):
			count += 1
	return count


func _has_mineral_label_text(text: String) -> bool:
	for node in get_tree().get_nodes_in_group(&"mineral_collect_feedback"):
		if not is_instance_valid(node):
			continue
		if node is Label and (node as Label).text.contains(text):
			return true
	return false


func _find_collect_trail() -> Node2D:
	for node in get_tree().get_nodes_in_group(&"mineral_collect_feedback"):
		if not is_instance_valid(node):
			continue
		if node is Node2D and String(node.name).contains("星髓回收轨迹"):
			return node
	return null


func _first_accessible_node() -> int:
	for node in RunManager.map_nodes:
		var id := int(node.get("id", -1))
		if id > 0 and RunManager.is_node_accessible(id):
			return id
	return -1


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
