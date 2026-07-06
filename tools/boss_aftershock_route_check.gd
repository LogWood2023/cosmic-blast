extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false
var _tree: SceneTree


func _ready() -> void:
	_tree = get_tree()
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	RunManager.crisis_level = 5
	RunManager.pending_boss_threshold = 5
	RunManager.pending_boss_scene = "res://scenes/gameplay/boss/BossBattle_PeachBlossom.tscn"
	RunManager.shop_preferred_family = ""
	RunManager.shop_offer_ids.clear()
	RunManager.shop_draft_initialized = false
	if not RunManager.handle_boss_victory():
		_fail("RunManager should handle paradise boss victory.")
		return
	if String(RunManager.shop_preferred_family) != EquipmentCatalogScript.FAMILY_PARADISE:
		_fail("Boss victory should focus shop toward defeated family, got %s." % String(RunManager.shop_preferred_family))
		return
	var summary := RunManager.last_boss_completion_summary.duplicate(true)
	_check_boss_aftershock_summary(summary)
	if _failed:
		return
	var route_id := _find_boss_aftershock_route(EquipmentCatalogScript.FAMILY_PARADISE)
	if route_id <= 0:
		_fail("Boss victory should calibrate at least one accessible route toward paradise.")
		return
	await _check_world_map_feedback(route_id)
	if _failed:
		return
	_check_shop_and_route_config(route_id)
	if _failed:
		return
	print("Boss aftershock route check passed.")
	_tree.quit(0)


func _check_boss_aftershock_summary(summary: Dictionary) -> void:
	if summary.is_empty() or not bool(summary.get("ok", false)):
		_fail("Boss completion summary should remain available after victory.")
		return
	for key in ["boss_aftershock_text", "shop_focus_text"]:
		var text := String(summary.get(key, "")).strip_edges()
		if text.is_empty() or _contains_ascii_identifier(text):
			_fail("Boss aftershock summary should expose Chinese %s: %s" % [key, str(summary)])
			return
	if not String(summary.get("boss_aftershock_text", "")).contains("余波校准"):
		_fail("Boss aftershock summary should mention route calibration: %s" % str(summary))
		return
	if int(summary.get("boss_aftershock_route_count", 0)) <= 0:
		_fail("Boss completion summary should report calibrated routes: %s" % str(summary))
		return


func _check_world_map_feedback(route_id: int) -> void:
	var scene := WORLD_MAP_SCENE.instantiate()
	_tree.root.add_child(scene)
	await _tree.process_frame
	var world_map := scene.get_node_or_null("WorldMap")
	if world_map == null:
		_fail("WorldMap scene should expose a WorldMap node.")
		scene.queue_free()
		return
	var message_label := world_map.get_node_or_null("MessageLabel") as Label
	if message_label == null:
		_fail("WorldMap should expose MessageLabel.")
		scene.queue_free()
		return
	var message := message_label.text
	for expected in ["执行体肃清", "天堂号", "余波校准", "货单导向"]:
		if not message.contains(expected):
			_fail("World map boss aftershock feedback should include %s. Message: %s" % [expected, message])
			scene.queue_free()
			return
	world_map.set("_selected_node_id", route_id)
	world_map.call("_refresh_details")
	var details_body := world_map.get_node_or_null("DetailsPanel/DetailsBody") as RichTextLabel
	if details_body == null:
		_fail("WorldMap details body missing.")
		scene.queue_free()
		return
	var details := details_body.text
	scene.queue_free()
	for expected in ["执行体余波", "天堂号", "货单导向", "流派倾向"]:
		if not details.contains(expected):
			_fail("World map route details should show boss aftershock %s. Details: %s" % [expected, details])
			return
	if details.contains("BossBattle") or details.contains("boss_aftershock") or details.contains("paradise"):
		_fail("World map boss aftershock copy should hide internal ids: %s" % details)


func _check_shop_and_route_config(route_id: int) -> void:
	var guidance := RunManager.get_shop_guidance()
	if String(guidance.get("family", "")) != EquipmentCatalogScript.FAMILY_PARADISE:
		_fail("Shop guidance should follow boss aftershock family: %s" % str(guidance))
		return
	var offers := RunManager.get_shop_offer_ids()
	if _count_family(offers, EquipmentCatalogScript.FAMILY_PARADISE) < 2:
		_fail("Boss aftershock shop focus should refresh offers toward paradise, offers=%s" % str(offers))
		return
	if not RunManager.start_explore_node(route_id):
		_fail("Boss aftershock route should remain enterable.")
		return
	var config := GameManager.next_explore_room_config.duplicate(true)
	var family_key := "%s_family_weight" % EquipmentCatalogScript.FAMILY_PARADISE
	if float(config.get(family_key, 0.0)) < RunManager.EXPLORE_FAMILY_WEIGHT_BOOST:
		_fail("Boss aftershock route should bias room family weight: %s" % str(config))
		return
	var tip := String(config.get("modifier_tip_text", ""))
	if tip.is_empty() or not tip.contains("执行体余波") or not tip.contains("天堂号"):
		_fail("Boss aftershock route should add loading tip, got: %s config=%s" % [tip, str(config)])


func _find_boss_aftershock_route(family: String) -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		if not RunManager.is_node_accessible(node_id):
			continue
		var aftershock: Dictionary = node.get("boss_aftershock", {})
		if String(aftershock.get("family_bias", "")) == family:
			return node_id
	return -1


func _count_family(item_ids: Array, family: String) -> int:
	var count := 0
	for item_id in item_ids:
		if EquipmentCatalogScript.get_family(String(item_id)) == family:
			count += 1
	return count


func _contains_ascii_identifier(text: String) -> bool:
	for token in ["colossus", "paradise", "warped", "hell_eye", "divine", "boss_aftershock", "BossBattle", "family_bias", "_"]:
		if text.contains(token):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	if _tree != null:
		_tree.quit(1)
