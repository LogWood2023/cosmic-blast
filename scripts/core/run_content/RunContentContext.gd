class_name RunContentContext
extends RefCounted
## Deep-copied, read-only view of a formal run. Content services never receive RunManager.

var _snapshot: Dictionary


static func from_snapshot(snapshot: Dictionary) -> RunContentContext:
	var context := RunContentContext.new()
	context._snapshot = snapshot.duplicate(true)
	return context


func get_state_version() -> int:
	return int(_snapshot.get("state_version", 0))


func get_node(node_id: int) -> Dictionary:
	for raw_node in _snapshot.get("map_nodes", []):
		var node := Dictionary(raw_node)
		if int(node.get("id", -1)) == node_id:
			return node.duplicate(true)
	return {}


func get_minerals() -> int:
	return int(_snapshot.get("minerals", 0))


func get_player_hp() -> int:
	return int(_snapshot.get("player_hp", 0))


func get_active_rule_snapshot() -> Dictionary:
	return Dictionary(_snapshot.get("active_rules", {})).duplicate(true)


func to_dictionary() -> Dictionary:
	return _snapshot.duplicate(true)
