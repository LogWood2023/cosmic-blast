extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")
const ROUTE_DIRECTIVE_POPUP_PATH := "res://scenes/ui/world_map/RouteDirectivePopup.tscn"

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_route_momentum_flow()
	if _failed:
		return
	await _check_world_map_momentum_details()
	if _failed:
		return
	await _check_route_momentum_popup()
	if _failed:
		return
	print("Route momentum check passed.")
	get_tree().quit(0)


func _check_route_momentum_flow() -> void:
	if not "active_route_momentum" in RunManager:
		_fail("RunManager should keep active_route_momentum in run state.")
		return
	if not RunManager.has_method("get_active_route_momentum_summary"):
		_fail("RunManager should expose get_active_route_momentum_summary().")
		return
	RunManager.start_new_run()
	RunManager.active_route_directives = [_make_one_step_directive()]
	var first_id := _first_accessible_exploration_node()
	if first_id <= 0:
		_fail("Need an accessible node for route momentum activation.")
		return
	if not RunManager.start_explore_node(first_id):
		_fail("Accessible node should start exploration.")
		return
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
	var first_summary: Dictionary = RunManager.complete_explore_room_success()
	if not bool(first_summary.get("ok", false)):
		_fail("Completing momentum primer node should succeed: %s" % str(first_summary))
		return
	var activated: Dictionary = first_summary.get("route_momentum_activated", {})
	if activated.is_empty():
		_fail("Completing a route directive should activate route momentum: %s" % str(first_summary))
		return
	if int(activated.get("remaining_nodes", 0)) != RunManager.ROUTE_MOMENTUM_DURATION_NODES:
		_fail("Route momentum should start with the configured duration: %s" % str(activated))
		return
	var active_summary: Dictionary = RunManager.get_active_route_momentum_summary()
	if active_summary.is_empty() or not String(active_summary.get("effects_text", "")).contains("回收"):
		_fail("Active route momentum summary should expose Chinese effects text: %s" % str(active_summary))
		return
	RunManager.active_route_directives.clear()
	var next_id := _first_accessible_exploration_node()
	if next_id <= 0:
		_fail("Need a second accessible node for route momentum payout.")
		return
	var base_chance := float(RunManager.get_map_node(next_id).get("equipment_drop_chance", 0.0))
	var boosted_chance := RunManager.get_node_equipment_drop_chance(next_id)
	if boosted_chance <= base_chance:
		_fail("Route momentum should raise equipment drop chance, base=%.3f boosted=%.3f." % [base_chance, boosted_chance])
		return
	if not RunManager.start_explore_node(next_id):
		_fail("Second accessible node should start exploration.")
		return
	RunManager.pending_room_loot = {"minerals": 100, "equipment": []}
	var minerals_before := RunManager.minerals
	var second_summary: Dictionary = RunManager.complete_explore_room_success()
	if not bool(second_summary.get("ok", false)):
		_fail("Completing route momentum payout node should succeed: %s" % str(second_summary))
		return
	var gained := RunManager.minerals - minerals_before
	if gained <= 100:
		_fail("Route momentum should add mineral recovery bonus, gained=%d summary=%s." % [gained, str(second_summary)])
		return
	if int(second_summary.get("route_momentum_minerals_added", 0)) <= 0:
		_fail("Completion summary should report route momentum minerals: %s" % str(second_summary))
		return
	var after_second: Dictionary = RunManager.get_active_route_momentum_summary()
	if int(after_second.get("remaining_nodes", 0)) != RunManager.ROUTE_MOMENTUM_DURATION_NODES - 1:
		_fail("Route momentum should tick after a completed node: %s" % str(after_second))
		return
	_finish_nodes_until_momentum_expires()
	if _failed:
		return
	if not RunManager.get_active_route_momentum_summary().is_empty():
		_fail("Route momentum should expire after its remaining node count is consumed: %s" % str(RunManager.get_active_route_momentum_summary()))


func _finish_nodes_until_momentum_expires() -> void:
	while not RunManager.get_active_route_momentum_summary().is_empty():
		RunManager.active_route_directives.clear()
		RunManager.retired_route_directive_ids = _all_route_directive_ids()
		var node_id := _first_incomplete_exploration_node()
		if node_id <= 0:
			_fail("Need enough incomplete nodes to consume route momentum.")
			return
		RunManager.current_node_id = node_id
		RunManager.pending_room_loot = {"minerals": 0, "equipment": []}
		var summary: Dictionary = RunManager.complete_explore_room_success()
		if not bool(summary.get("ok", false)):
			_fail("Completing node while consuming route momentum should succeed: %s" % str(summary))
			return


func _check_world_map_momentum_details() -> void:
	RunManager.start_new_run()
	RunManager.active_route_momentum = {
		"title": "航路动能",
		"remaining_nodes": 2,
		"duration_nodes": 3,
		"mineral_bonus_rate": 0.18,
		"equipment_chance_bonus": 0.05,
		"effects_text": "回收星髓 +18%、装备检出 +5%",
	}
	var scene := WORLD_MAP_SCENE.instantiate()
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	var world_map := scene.get_node_or_null("WorldMap")
	if world_map == null:
		_fail("WorldMap scene should expose a WorldMap node.")
		scene.queue_free()
		return
	world_map.set("_selected_node_id", RunManager.CENTER_ID)
	world_map.call("_refresh_all")
	var stats_label := world_map.get_node_or_null("TopBar/StatsLabel") as Label
	var details_body := world_map.get_node_or_null("DetailsPanel/DetailsBody") as RichTextLabel
	if stats_label == null or not stats_label.text.contains("航路动能"):
		_fail("World map top bar should show active route momentum: %s" % (stats_label.text if stats_label != null else ""))
		scene.queue_free()
		return
	if details_body == null or not details_body.text.contains("航路动能") or not details_body.text.contains("回收星髓"):
		_fail("World map center details should show route momentum copy.")
		scene.queue_free()
		return
	scene.queue_free()


func _check_route_momentum_popup() -> void:
	var packed := load(ROUTE_DIRECTIVE_POPUP_PATH) as PackedScene
	if packed == null:
		_fail("Route directive popup scene should exist at %s." % ROUTE_DIRECTIVE_POPUP_PATH)
		return
	var popup := packed.instantiate()
	add_child(popup)
	popup.call("setup", {
		"completed_directives": [
			{
				"title": "清扫前哨航线",
				"description": "方舟航线已经稳定。",
				"reward_text": "星髓矿与算力补给",
			},
		],
		"reward_summary": {"minerals": 12, "equipment_chance_bonus": 0.05},
		"route_momentum": {
			"remaining_nodes": 3,
			"effects_text": "回收星髓 +18%、装备检出 +5%",
			"activation_text": "航路动能已点燃：接下来 3 个完成节点内，回收星髓 +18%、装备检出 +5%。",
		},
	})
	await get_tree().process_frame
	var body_label := popup.get_node_or_null("Panel/BodyLabel") as RichTextLabel
	if body_label == null or not body_label.text.contains("航路动能") or not body_label.text.contains("装备检出"):
		_fail("Route directive popup should render route momentum activation copy.")
		popup.queue_free()
		return
	popup.queue_free()


func _make_one_step_directive() -> Dictionary:
	return {
		"directive_id": "test_route_momentum",
		"title": "点燃航路动能",
		"description": "方舟要求清出一段短航线，借此把回收队的推进节奏抬起来。",
		"goal_type": "complete_nodes",
		"target": "",
		"current": 0,
		"required": 1,
		"reward": {"minerals": 1, "equipment_chance_bonus": 0.05},
		"reward_text": "星髓矿与装备检出补给",
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


func _first_incomplete_exploration_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		if bool(node.get("completed", false)):
			continue
		return node_id
	return -1


func _all_route_directive_ids() -> Array[String]:
	var ids: Array[String] = []
	for raw_profile in RunManager.get_route_directive_profiles():
		var profile := Dictionary(raw_profile)
		var profile_id := String(profile.get("id", "")).strip_edges()
		if not profile_id.is_empty():
			ids.append(profile_id)
	return ids


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
