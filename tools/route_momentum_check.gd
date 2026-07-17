extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")
const ROUTE_DIRECTIVE_POPUP_PATH := "res://scenes/ui/world_map/RouteDirectivePopup.tscn"

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_route_directive_settlement()
	if _failed:
		return
	await _check_world_map_route_details()
	if _failed:
		return
	await _check_route_directive_popup()
	if _failed:
		return
	print("Route settlement check passed.")
	get_tree().quit(0)


func _check_route_directive_settlement() -> void:
	RunManager.start_new_run()
	RunManager.active_route_directives = [_make_one_step_directive()]
	var node_id := _first_accessible_exploration_node()
	if node_id <= 0 or not RunManager.start_explore_node(node_id):
		_fail("Need an accessible node for route directive settlement.")
		return
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var minerals_before := RunManager.minerals
	var summary: Dictionary = RunManager.complete_explore_room_success()
	if not bool(summary.get("ok", false)):
		_fail("Completing the route directive node should succeed: %s" % str(summary))
		return
	var completed: Array = summary.get("completed_route_directives", [])
	if completed.size() != 1 or String(Dictionary(completed[0]).get("title", "")) != "清扫前哨航线":
		_fail("Completion summary should include the finished route directive: %s" % str(summary))
		return
	var reward_summary := Dictionary(summary.get("route_directive_rewards", {}))
	if int(reward_summary.get("minerals", 0)) != 12 or RunManager.minerals - minerals_before != 12:
		_fail("Route directive mineral reward should be granted and reported once: %s" % str(reward_summary))
		return
	if not is_equal_approx(float(reward_summary.get("equipment_chance_bonus", 0.0)), 0.05):
		_fail("Route directive equipment chance reward should reach settlement copy: %s" % str(reward_summary))
		return
	if not Dictionary(summary.get("route_momentum_activated", {})).is_empty():
		_fail("Retired route-momentum state should not return in current settlement summaries.")


func _check_world_map_route_details() -> void:
	RunManager.start_new_run()
	RunManager.active_route_directives = [_make_one_step_directive()]
	var scene := WORLD_MAP_SCENE.instantiate()
	add_child(scene)
	await get_tree().process_frame
	var details_body := scene.get_node_or_null("WorldMap/DetailsPanel/DetailsBody") as RichTextLabel
	if details_body == null or not details_body.text.contains("航路指令") or not details_body.text.contains("清扫前哨航线"):
		_fail("World map core details should list current route directives.")
		scene.queue_free()
		return
	scene.queue_free()


func _check_route_directive_popup() -> void:
	var packed := load(ROUTE_DIRECTIVE_POPUP_PATH) as PackedScene
	if packed == null:
		_fail("Route directive popup scene should exist at %s." % ROUTE_DIRECTIVE_POPUP_PATH)
		return
	var popup := packed.instantiate()
	add_child(popup)
	popup.call("setup", {
		"completed_directives": [{
			"title": "清扫前哨航线",
			"description": "方舟航线已经稳定。",
			"reward_text": "星髓矿与装备补给",
		}],
		"reward_summary": {"minerals": 12, "equipment_chance_bonus": 0.05},
	})
	await get_tree().process_frame
	var body_label := popup.get_node_or_null("Panel/BodyLabel") as RichTextLabel
	if body_label == null or not body_label.text.contains("清扫前哨航线") or not body_label.text.contains("装备出现率 +5%"):
		_fail("Route directive popup should render current settlement rewards.")
		popup.queue_free()
		return
	popup.queue_free()


func _make_one_step_directive() -> Dictionary:
	return {
		"id": "current_route_settlement",
		"title": "清扫前哨航线",
		"description": "方舟要求清出一段短航线。",
		"goal_type": "complete_nodes",
		"target": "",
		"current": 0,
		"required": 1,
		"reward": {"minerals": 12, "equipment_chance_bonus": 0.05},
		"reward_text": "星髓矿 +12，装备出现率提高",
		"completed": false,
		"claimed": false,
	}


func _first_accessible_exploration_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		if bool(node.get("completed", false)):
			continue
		if RunManager.is_node_accessible(node_id):
			return node_id
	return -1


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
