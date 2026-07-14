extends Node


const REWARD_EVENT_POPUP_PATH := "res://scenes/ui/world_map/RewardCacheChoicePopup.tscn"

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var reward_id := _force_accessible_reward_node()
	if reward_id <= 0:
		_fail("Need an accessible reward event node.")
		return
	var choices := RunManager.prepare_reward_event_choices(reward_id, 4401)
	_check_choice_generation(choices)
	if _failed:
		return
	await _check_choice_popup(reward_id, choices)
	if _failed:
		return
	_check_direct_reward_resolution(reward_id, choices)
	if _failed:
		return
	print("Reward event choice check passed.")
	get_tree().quit(0)


func _check_choice_generation(choices: Array) -> void:
	if choices.size() != 3:
		_fail("Reward event should offer exactly three rewards, got %d." % choices.size())
		return
	var seen_types := {}
	for raw_choice in choices:
		var choice := Dictionary(raw_choice)
		var reward_type := String(choice.get("reward_type", ""))
		if String(choice.get("choice_id", "")).is_empty() or String(choice.get("title", "")).is_empty() or String(choice.get("preview", "")).is_empty():
			_fail("Every reward event option needs player-facing content: %s" % str(choice))
			return
		seen_types[reward_type] = true
	if not seen_types.has("minerals") or not seen_types.has("repair") or not seen_types.has("equipment"):
		_fail("Reward event must offer minerals, repair, and equipment: %s" % str(seen_types.keys()))


func _check_choice_popup(reward_id: int, choices: Array) -> void:
	var packed := load(REWARD_EVENT_POPUP_PATH) as PackedScene
	if packed == null:
		_fail("Reward event popup scene should exist at %s." % REWARD_EVENT_POPUP_PATH)
		return
	var popup := packed.instantiate()
	add_child(popup)
	popup.call("setup", RunManager.get_map_node(reward_id), choices)
	await get_tree().process_frame
	var story := popup.get_node_or_null("Panel/StoryLabel") as RichTextLabel
	var list := popup.get_node_or_null("Panel/ChoicesScroll/ChoicesList") as VBoxContainer
	if story == null or story.text.is_empty() or list == null or list.get_child_count() != 3:
		_fail("Reward event popup should render its story and three choices.")
	popup.queue_free()


func _check_direct_reward_resolution(reward_id: int, choices: Array) -> void:
	var equipment_choice := _find_choice_by_type(choices, "equipment")
	var inventory_before := RunManager.equipment_inventory.duplicate()
	var result := RunManager.resolve_reward_event_choice(reward_id, String(equipment_choice.get("choice_id", "")), 4401)
	if not bool(result.get("ok", false)):
		_fail("Selecting a reward event option should succeed: %s" % str(result))
		return
	if RunManager.current_node_id != -1 or not RunManager.is_node_completed(reward_id):
		_fail("Reward event should complete directly without starting an explore room.")
		return
	if not GameManager.next_explore_room_config.is_empty():
		_fail("Reward event must not create a combat room config.")
		return
	var item_id := String(equipment_choice.get("item_id", ""))
	if not item_id.is_empty() and not inventory_before.has(item_id) and not RunManager.equipment_inventory.has(item_id):
		_fail("Selected equipment reward should be granted immediately.")


func _find_choice_by_type(choices: Array, reward_type: String) -> Dictionary:
	for raw_choice in choices:
		var choice := Dictionary(raw_choice)
		if String(choice.get("reward_type", "")) == reward_type:
			return choice
	return {}


func _force_accessible_reward_node() -> int:
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
		return node_id
	return -1


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
