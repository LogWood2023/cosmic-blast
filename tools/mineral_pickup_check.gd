extends Node


const MINERAL_PICKUP_SCENE := preload("res://scenes/gameplay/explore/MineralPickup.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var node_id := _first_accessible_node()
	if node_id <= 0 or not RunManager.start_explore_node(node_id):
		push_error("Could not start explore node for mineral pickup check.")
		get_tree().quit(1)
		return
	var node := RunManager.get_map_node(node_id)
	node["reward_mult"] = 1.0
	RunManager.map_nodes[node_id] = node
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	GameManager.next_explore_room_config["reward_mineral_mult"] = 1.0
	RunManager.current_room_mineral_mult = 1.0

	var scene := Node2D.new()
	scene.name = "MineralPickupCheck"
	add_child(scene)

	var player := PLAYER_SCENE.instantiate() as Area2D
	player.global_position = Vector2(700, 500)
	scene.add_child(player)

	var pickup := MINERAL_PICKUP_SCENE.instantiate()
	pickup.global_position = Vector2(500, 500)
	scene.add_child(pickup)
	pickup.setup(9, player, false)

	for i in range(180):
		await get_tree().process_frame
		if not is_instance_valid(pickup):
			break

	var pending_minerals := int(RunManager.pending_room_loot.get("minerals", 0))
	if pending_minerals != 9:
		push_error("Mineral pickup should add 9 pending minerals, got %d." % pending_minerals)
		get_tree().quit(1)
		return
	if RunManager.minerals != 0:
		push_error("Mineral pickup should not commit minerals before evacuation.")
		get_tree().quit(1)
		return

	var result := RunManager.complete_explore_room_success()
	var directive_rewards: Dictionary = result.get("route_directive_rewards", {})
	var expected_minerals := 9 + int(directive_rewards.get("minerals", 0))
	if not bool(result.get("ok", false)) or RunManager.minerals != expected_minerals:
		push_error("Evacuation should commit collected pending minerals plus route directive rewards.")
		get_tree().quit(1)
		return

	print("Mineral pickup check passed.")
	get_tree().quit(0)


func _first_accessible_node() -> int:
	for node in RunManager.map_nodes:
		var id := int(node.get("id", -1))
		if id > 0 and RunManager.is_node_accessible(id):
			return id
	return -1
