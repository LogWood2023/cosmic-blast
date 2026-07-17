extends Node


const EXPLORE_ROOM_SCENE := preload("res://scenes/gameplay/explore/ExploreRoom.tscn")
const READY_CONTEXT := "ExploreRoom.ready"
const READY_TIMEOUT_SECONDS := 20.0

var _failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var room := EXPLORE_ROOM_SCENE.instantiate()
	room.setup_room_config({
		"large_space_rock_count": 0,
		"trap_count": 0,
		"chest_crystal_count": 5,
		"clutter_count": 0,
		"enemy_spawn_interval": 999.0,
		"max_patrol_enemy_count": 0,
		"battle_patrol_path_min_count": 0,
		"battle_patrol_path_max_count": 0,
		"battle_elite_replacement_min": 3,
		"battle_elite_replacement_max": 3,
	})
	add_child(room)
	var elapsed := 0.0
	while elapsed < READY_TIMEOUT_SECONDS and GameManager.stutter_context != READY_CONTEXT:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if GameManager.stutter_context != READY_CONTEXT:
		_fail("ExploreRoom did not finish loading before objective HUD timeout. Last context: %s" % GameManager.stutter_context)
		return
	await get_tree().process_frame
	var chest_label := room.get_node_or_null("UILayer/ExploreObjectivesHUD/Panel/Layout/Content/Details/ResourceSection/Margin/Stack/ChestValue") as Label
	var elite_label := room.get_node_or_null("UILayer/ExploreObjectivesHUD/Panel/Layout/Content/Details/ResourceSection/Margin/Stack/EliteValue") as Label
	if not chest_label or not elite_label:
		_fail("Explore objective HUD labels were not found.")
		return
	if chest_label.text != "剩余宝箱：2/2":
		_fail("Expected final chest total after elite replacement to be 2/2, got %s." % chest_label.text)
		return
	if elite_label.text != "剩余精英：3/3":
		_fail("Expected elite objective total to be 3/3, got %s." % elite_label.text)
		return
	remove_child(room)
	room.queue_free()
	print("Explore objectives HUD count check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
