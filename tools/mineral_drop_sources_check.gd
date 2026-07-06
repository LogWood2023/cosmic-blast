extends Node


const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")
const EXPLORE_REWARD_SCENE := preload("res://scenes/gameplay/explore/ExploreReward.tscn")
const SPACE_CLUTTER_SCENE := preload("res://scenes/gameplay/explore/SpaceClutter.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var node_id := _first_accessible_node()
	if node_id <= 0 or not RunManager.start_explore_node(node_id):
		push_error("Could not start explore node for mineral source check.")
		get_tree().quit(1)
		return

	var scene := Node2D.new()
	scene.name = "MineralDropSourcesCheck"
	add_child(scene)

	var player := PLAYER_SCENE.instantiate() as Area2D
	player.global_position = Vector2(800, 500)
	scene.add_child(player)

	var ore := EXPLORE_REWARD_SCENE.instantiate()
	ore.setup(1)
	ore.ore_mineral_min = 30
	ore.ore_mineral_max = 30
	ore.ore_pickup_count_min = 5
	ore.ore_pickup_count_max = 5
	ore.global_position = Vector2(500, 500)
	scene.add_child(ore)
	ore._break()
	await get_tree().process_frame
	if _pickup_count(scene) < 5:
		push_error("Ore vein should spawn at least 5 mineral pickups.")
		get_tree().quit(1)
		return

	var clutter := SPACE_CLUTTER_SCENE.instantiate()
	clutter.mineral_min = 3
	clutter.mineral_max = 3
	clutter.mineral_pickup_count_min = 2
	clutter.mineral_pickup_count_max = 2
	clutter.global_position = Vector2(600, 500)
	scene.add_child(clutter)
	clutter._break()
	await get_tree().process_frame
	if _pickup_count(scene) < 7:
		push_error("Clutter should add small mineral pickups.")
		get_tree().quit(1)
		return

	for i in range(240):
		await get_tree().process_frame

	var pending := int(RunManager.pending_room_loot.get("minerals", 0))
	if pending < 33:
		push_error("Collected source minerals should reach pending loot, got %d." % pending)
		get_tree().quit(1)
		return

	scene.queue_free()
	await get_tree().process_frame
	print("Mineral drop sources check passed.")
	get_tree().quit(0)


func _pickup_count(scene: Node) -> int:
	var count := 0
	for child in scene.get_children():
		if child.is_in_group(&"mineral_pickups"):
			count += 1
	return count


func _first_accessible_node() -> int:
	for node in RunManager.map_nodes:
		var id := int(node.get("id", -1))
		if id > 0 and RunManager.is_node_accessible(id):
			return id
	return -1
