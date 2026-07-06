extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var reward_id := _force_reward_node_with_cache_family(EquipmentCatalogScript.FAMILY_WARPED)
	if reward_id <= 0:
		_fail("Need a forced reward node for world map reward detail check.")
		return

	var scene := WORLD_MAP_SCENE.instantiate()
	get_tree().root.add_child(scene)
	await get_tree().process_frame

	var world_map := scene.get_node_or_null("WorldMap")
	if world_map == null:
		_fail("WorldMap scene should expose a WorldMap node.")
		scene.queue_free()
		return
	world_map.set("_selected_node_id", reward_id)
	world_map.call("_refresh_all")

	var details_body := world_map.get_node_or_null("DetailsPanel/DetailsBody") as RichTextLabel
	if details_body == null:
		_fail("WorldMap details body missing.")
		scene.queue_free()
		return
	var details_text := details_body.text
	scene.queue_free()

	if not details_text.contains("航域扰动"):
		_fail("World map details should show node domain modifiers. Details: %s" % details_text)
		return
	if not details_text.contains("·"):
		_fail("World map details should list modifier entries. Details: %s" % details_text)
		return
	if not details_text.contains("装备缓存倾向"):
		_fail("Reward node details should label the equipment cache bias. Details: %s" % details_text)
		return
	if not details_text.contains("扭曲星核"):
		_fail("Reward node details should show the cache family display name. Details: %s" % details_text)
		return

	print("World map reward details check passed.")
	get_tree().quit(0)


func _force_reward_node_with_cache_family(cache_family: String) -> int:
	var picked_profile := {}
	for raw_profile in RunManager.get_reward_profiles():
		var profile := Dictionary(raw_profile)
		if String(profile.get("cache_family_bias", "")) == cache_family:
			picked_profile = profile
			break
	if picked_profile.is_empty():
		return -1

	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		node["type"] = RunManager.NODE_REWARD
		node["completed"] = false
		var links: Array = node.get("links", [])
		if not links.has(RunManager.CENTER_ID):
			links.append(RunManager.CENTER_ID)
		node["links"] = links
		RunManager.map_nodes[i] = node

		var base := RunManager.map_nodes[RunManager.CENTER_ID]
		var base_links: Array = base.get("links", [])
		if not base_links.has(node_id):
			base_links.append(node_id)
		base["links"] = base_links
		RunManager.map_nodes[RunManager.CENTER_ID] = base

		RunManager.call("_apply_reward_profile_data_to_node", node, picked_profile)
		RunManager.map_nodes[i] = node
		return node_id
	return -1


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
