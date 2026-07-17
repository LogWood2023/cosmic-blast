extends Node

const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var special_id := _first_special_node_id()
	if special_id <= 0:
		_fail("World map should generate at least one special bonus node.")
		return
	if RunManager.is_special_bonus_active(special_id):
		_fail("Special bonus node should not start active.")
		return
	var special_node := RunManager.get_map_node(special_id)
	var linked_anchor := _first_exploration_link(special_node)
	if linked_anchor <= 0:
		_fail("Special bonus node should connect to an exploration node for activation.")
		return

	var before_stats := RunManager.get_player_stats()

	# Special nodes may now spawn deeper than the first accessible ring. Activate
	# the linked anchor directly so this check covers beacon behavior, not routing.
	RunManager.current_node_id = linked_anchor
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var result := RunManager.complete_explore_room_success()
	if not bool(result.get("ok", false)):
		_fail("Completing linked node should succeed.")
		return
	if not RunManager.is_special_bonus_active(special_id):
		_fail("Completing a linked node should activate the connected special bonus node.")
		return
	await _check_special_beacon_echo(special_id, linked_anchor)
	if _failed:
		return

	var after_stats := RunManager.get_player_stats()
	if not _stats_improved(before_stats, after_stats):
		_fail("Activated special bonus should improve player stats.")
		return
	_check_guard_beacon_reduces_regular_damage()

	print("Special node check passed.")
	get_tree().quit(0)


func _first_special_node_id() -> int:
	for node in RunManager.map_nodes:
		if String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			return int(node.get("id", -1))
	return -1


func _first_exploration_link(node: Dictionary) -> int:
	for linked_id in node.get("links", []):
		var id := int(linked_id)
		if id > 0 and String(RunManager.get_map_node(id).get("type", "")) != RunManager.NODE_SPECIAL:
			return id
	return -1


func _check_special_beacon_echo(special_id: int, completed_anchor_id: int) -> void:
	var echoed_id := _first_echo_target(completed_anchor_id)
	if echoed_id <= 0:
		_fail("Special beacon check needs an unfinished neighbor to receive beacon echo.")
		return
	var echoed_node := RunManager.get_map_node(echoed_id)
	var echo: Dictionary = echoed_node.get("beacon_echo", {})
	if echo.is_empty():
		_fail("Activating a special beacon should write beacon_echo to nearby unfinished routes.")
		return
	var special_node := RunManager.get_map_node(special_id)
	var bonus_id := String(special_node.get("bonus_id", ""))
	var family := String(special_node.get("family_bias", ""))
	if String(echo.get("bonus_id", "")) != bonus_id:
		_fail("Beacon echo should record the source bonus id.")
		return
	if String(echo.get("family_bias", "")) != family:
		_fail("Beacon echo should inherit source family bias, got: %s" % str(echo))
		return
	if RunManager.get_node_family_bias(echoed_id) != family:
		_fail("Beacon echo should redirect nearby route family bias.")
		return
	if float(echoed_node.get("equipment_drop_chance", 0.0)) < 0.08:
		_fail("Beacon echo should leave a visible equipment search bonus.")
		return

	var world_map := WORLD_MAP_SCENE.instantiate()
	add_child(world_map)
	await get_tree().process_frame
	var map_view := world_map.get_node("WorldMap")
	map_view.set("_selected_node_id", echoed_id)
	map_view.call("_refresh_details")
	var details_body := map_view.get_node("DetailsPanel/DetailsBody") as RichTextLabel
	var text := details_body.text
	for expected in ["信标回响", "装备出现率", "方舟航图"]:
		if not text.contains(expected):
			_fail("World map details should show beacon echo %s. Details: %s" % [expected, text])
			return
	if text.contains(bonus_id):
		_fail("World map details should hide beacon echo internal ids: %s" % text)
		return
	world_map.queue_free()


func _first_echo_target(anchor_id: int) -> int:
	var anchor := RunManager.get_map_node(anchor_id)
	for linked_id in anchor.get("links", []):
		var id := int(linked_id)
		if id <= 0:
			continue
		var node := RunManager.get_map_node(id)
		if String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		if bool(node.get("completed", false)):
			continue
		return id
	return -1


func _stats_improved(before: Dictionary, after: Dictionary) -> bool:
	for key in [
		"speed_mult",
		"mineral_bonus",
		"dash_distance_mult",
		"dash_speed_mult",
		"dash_damage_mult",
		"bullet_count",
		"bullet_speed_mult",
		"homing_strength",
		"homing_range",
		"frenzy_gain_mult",
		"drone_slots",
	]:
		if float(after.get(key, 0.0)) > float(before.get(key, 0.0)):
			return true
	return false


func _check_guard_beacon_reduces_regular_damage() -> void:
	RunManager.start_new_run()
	GameManager.frenzy_active = false
	var plain_damage := GameManager.get_incoming_damage_after_frenzy(10)
	RunManager.active_special_bonus_ids = ["ark_guard_beacon"]
	var guarded_damage := GameManager.get_incoming_damage_after_frenzy(10)
	if guarded_damage >= plain_damage:
		_fail("Ark guard beacon should reduce regular incoming damage, plain=%d guarded=%d." % [plain_damage, guarded_damage])
		return


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
