extends Node


const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")
const EXPLORE_REWARD_SCENE := preload("res://scenes/gameplay/explore/ExploreReward.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var node_id := _first_accessible_node()
	if node_id <= 0 or not RunManager.start_explore_node(node_id):
		_fail("Could not start explore node for rich mineral source check.")
		return
	var node := RunManager.get_map_node(node_id)
	node["reward_mult"] = 1.0
	RunManager.map_nodes[node_id] = node
	GameManager.next_explore_room_config["reward_mineral_mult"] = 1.0
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}

	var scene := Node2D.new()
	scene.name = "RichMineralSourceCheck"
	add_child(scene)

	var player := PLAYER_SCENE.instantiate() as Area2D
	player.global_position = Vector2(780, 500)
	scene.add_child(player)

	var ore := EXPLORE_REWARD_SCENE.instantiate()
	ore.setup(1)
	ore.ore_mineral_min = 30
	ore.ore_mineral_max = 30
	ore.ore_pickup_count_min = 5
	ore.ore_pickup_count_max = 5
	ore.rich_ore_chance = 1.0
	ore.rich_ore_multiplier = 2.0
	ore.rich_ore_extra_pickups = 3
	ore.global_position = Vector2(500, 500)
	scene.add_child(ore)
	ore._break()
	await get_tree().process_frame

	var pickups := _mineral_pickups(scene)
	if pickups.size() < 8:
		_fail("Rich ore should spawn extra mineral pickups, got %d." % pickups.size())
		return
	var total := 0
	var rich_count := 0
	for pickup in pickups:
		total += int(pickup.get("amount"))
		if bool(pickup.get_meta("rich_mineral", false)):
			rich_count += 1
	if total < 60:
		_fail("Rich ore should multiply total mineral value, got %d." % total)
		return
	if rich_count != pickups.size():
		_fail("Every pickup from rich ore should carry rich mineral metadata, rich=%d total=%d." % [rich_count, pickups.size()])
		return
	if not _has_rich_visual(pickups):
		_fail("Rich ore pickups should use stronger rich-mineral visuals.")
		return

	for _i in range(240):
		await get_tree().process_frame
		if int(RunManager.pending_room_loot.get("minerals", 0)) >= total:
			break
	var pending := int(RunManager.pending_room_loot.get("minerals", 0))
	if pending < total:
		_fail("Collected rich mineral pickups should reach pending loot, expected at least %d got %d." % [total, pending])
		return

	for _i in range(90):
		await get_tree().process_frame
		if not is_instance_valid(ore) and _feedback_count() == 0:
			break
	scene.queue_free()
	await get_tree().process_frame
	print("Rich mineral source check passed.")
	get_tree().quit(0)


func _mineral_pickups(scene: Node) -> Array[Node]:
	var pickups: Array[Node] = []
	for child in scene.get_children():
		if child.is_in_group(&"mineral_pickups"):
			pickups.append(child)
	return pickups


func _has_rich_visual(pickups: Array[Node]) -> bool:
	for pickup in pickups:
		if not is_instance_valid(pickup):
			continue
		if pickup.has_node("AmountLabel"):
			var label := pickup.get_node("AmountLabel") as Label
			if label.text.contains("富"):
				return true
		if pickup.modulate.r > 1.0 or pickup.scale.x > 1.05:
			return true
	return false


func _feedback_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(&"mineral_collect_feedback"):
		if is_instance_valid(node):
			count += 1
	return count


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
