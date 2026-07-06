extends Node


const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")
const EXPLORE_REWARD_SCENE := preload("res://scenes/gameplay/explore/ExploreReward.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ore_probe = EXPLORE_REWARD_SCENE.instantiate()
	add_child(ore_probe)
	if not ore_probe.has_method("get_ore_source_profiles"):
		_fail("ExploreReward should expose ore source profiles.")
		return
	var profiles: Array = ore_probe.call("get_ore_source_profiles")
	if profiles.size() < 4:
		_fail("Ore source library should contain at least 4 source profiles, got %d." % profiles.size())
		return
	var ids := {}
	var mineral_totals := {}
	var pickup_counts := {}
	var rich_chances := {}
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		var id := String(profile.get("id", ""))
		if id.is_empty() or ids.has(id):
			_fail("Ore source profiles should expose unique ids: %s" % str(profile))
			return
		ids[id] = true
		_assert_chinese_copy(String(profile.get("name", "")), "ore source name")
		_assert_chinese_copy(String(profile.get("label", "")), "ore source label")
		if _failed:
			return
		mineral_totals["%d-%d" % [int(profile.get("mineral_min", 0)), int(profile.get("mineral_max", 0))]] = true
		pickup_counts["%d-%d" % [int(profile.get("pickup_count_min", 0)), int(profile.get("pickup_count_max", 0))]] = true
		rich_chances[float(profile.get("rich_chance", -1.0))] = true
	if mineral_totals.size() < 3 or pickup_counts.size() < 3 or rich_chances.size() < 3:
		_fail("Ore source profiles should vary mineral totals, pickup counts and rich chances.")
		return

	RunManager.start_new_run()
	var node_id := _first_accessible_node()
	if node_id <= 0 or not RunManager.start_explore_node(node_id):
		_fail("Could not start explore node for ore source profile check.")
		return
	RunManager.pending_room_loot = {"minerals": 0, "equipment": []}

	var scene := Node2D.new()
	scene.name = "OreSourceProfileCheck"
	add_child(scene)

	var player := PLAYER_SCENE.instantiate() as Area2D
	player.global_position = Vector2(760, 500)
	scene.add_child(player)

	var deepest := _find_profile(profiles, "deep_core")
	if deepest.is_empty():
		_fail("Ore source library should include a deep core profile.")
		return
	var ore = EXPLORE_REWARD_SCENE.instantiate()
	ore.setup(1)
	ore.apply_ore_source_profile(deepest)
	ore.rich_ore_chance = 1.0
	ore.global_position = Vector2(500, 500)
	scene.add_child(ore)
	ore._break()
	await get_tree().process_frame

	var pickups := _mineral_pickups(scene)
	if pickups.size() < int(deepest.get("pickup_count_min", 0)):
		_fail("Applied ore source should control pickup count, got %d." % pickups.size())
		return
	var total := 0
	var source_count := 0
	for pickup in pickups:
		total += int(pickup.get("amount"))
		if String(pickup.get_meta("ore_source_id", "")) == "deep_core":
			source_count += 1
		if String(pickup.get("mineral_label")) != String(deepest.get("label", "")):
			_fail("Mineral pickup should inherit source label.")
			return
	if source_count != pickups.size():
		_fail("Every pickup should inherit ore source metadata, got %d/%d." % [source_count, pickups.size()])
		return
	if total < int(deepest.get("mineral_min", 0)):
		_fail("Applied ore source should raise mineral value, got %d." % total)
		return

	for _i in range(240):
		await get_tree().process_frame
		if int(RunManager.pending_room_loot.get("minerals", 0)) >= total:
			break
	var pending := int(RunManager.pending_room_loot.get("minerals", 0))
	if pending < total:
		_fail("Collected source minerals should reach pending loot, expected %d got %d." % [total, pending])
		return

	for _i in range(90):
		await get_tree().process_frame
		if not is_instance_valid(ore) and _feedback_count() == 0:
			break
	scene.queue_free()
	ore_probe.queue_free()
	await get_tree().process_frame
	print("Ore source profile check passed.")
	get_tree().quit(0)


func _find_profile(profiles: Array, id: String) -> Dictionary:
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		if String(profile.get("id", "")) == id:
			return profile
	return {}


func _mineral_pickups(scene: Node) -> Array[Node]:
	var pickups: Array[Node] = []
	for child in scene.get_children():
		if child.is_in_group(&"mineral_pickups"):
			pickups.append(child)
	return pickups


func _feedback_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(&"mineral_collect_feedback"):
		if is_instance_valid(node):
			count += 1
	return count


func _first_accessible_node() -> int:
	for node in RunManager.map_nodes:
		var id := int(node.get("id", -1))
		if id > 0 and RunManager.is_node_accessible(id):
			return id
	return -1


func _assert_chinese_copy(text: String, label: String) -> void:
	if text.strip_edges().is_empty():
		_fail("%s should not be empty." % label)
		return
	for forbidden in ["TODO", "TBD", "需求", "说明", "placeholder", "debug"]:
		if text.to_lower().contains(forbidden.to_lower()):
			_fail("%s contains design-note copy: %s" % [label, text])
			return
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			_fail("%s should be Chinese player-facing copy, got: %s" % [label, text])
			return


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
