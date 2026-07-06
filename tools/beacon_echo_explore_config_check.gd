extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var node_id := _first_accessible_exploration_node()
	if node_id <= 0:
		_fail("Need an accessible exploration node for beacon echo config check.")
		return
	var node := RunManager.get_map_node(node_id)
	node["beacon_echo"] = {
		"bonus_id": "warped_tide_beacon",
		"bonus_name": "暗潮牵引协议",
		"family_bias": EquipmentCatalog.FAMILY_WARPED,
		"family_name": "扭曲星核",
		"equipment_bonus": 0.08,
		"reward_bonus": 0.10,
	}
	node["family_bias"] = EquipmentCatalog.FAMILY_WARPED
	RunManager.map_nodes[node_id] = node

	if not RunManager.start_explore_node(node_id):
		_fail("Accessible beacon echo node should start exploration.")
		return
	var config := GameManager.next_explore_room_config.duplicate(true)
	var family_key := "%s_family_weight" % EquipmentCatalog.FAMILY_WARPED
	if float(config.get(family_key, 0.0)) < RunManager.EXPLORE_FAMILY_WEIGHT_BOOST:
		_fail("Beacon echo should push family battle weight into room config: %s" % str(config))
		return
	if String(config.get("reward_cache_family_bias", "")) != EquipmentCatalog.FAMILY_WARPED:
		_fail("Beacon echo should bias reward cache family toward the echo family: %s" % str(config))
		return
	var echo_tip := String(config.get("beacon_echo_tip_text", ""))
	if echo_tip.is_empty() or not echo_tip.contains("信标回响") or not echo_tip.contains("暗潮牵引协议"):
		_fail("Beacon echo should add a Chinese loading tip, got: %s" % echo_tip)
		return
	var modifier_tip := String(config.get("modifier_tip_text", ""))
	if modifier_tip.contains("warped_tide_beacon"):
		_fail("Beacon echo loading copy should hide internal ids: %s" % modifier_tip)
		return
	if not modifier_tip.contains("信标回响"):
		_fail("Beacon echo tip should be folded into loading modifier text, got: %s" % modifier_tip)
		return
	print("Beacon echo explore config check passed.")
	get_tree().quit(0)


func _first_accessible_exploration_node() -> int:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0:
			continue
		if String(node.get("type", "")) == RunManager.NODE_SPECIAL:
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
