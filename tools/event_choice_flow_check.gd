extends Node

const EVENT_CHOICE_POPUP_SCENE := preload("res://scenes/ui/world_map/EventChoicePopup.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var event_id := _force_accessible_event_node()
	var choices: Array = RunManager.prepare_event_choices(event_id, 1201)
	if choices.size() != 3:
		_fail("Event node should provide three choices.")
		return
	for choice in choices:
		if String(choice.get("flavor_text", "")).is_empty() or String(choice.get("background_path", "")).is_empty():
			_fail("Event choices should provide flavor and a background path.")
			return
	var popup := EVENT_CHOICE_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.setup(RunManager.get_map_node(event_id), choices)
	await get_tree().process_frame
	var first_button := popup.get_node_or_null("Panel/ChoicesScroll/ChoicesList").get_child(0) as Button
	if first_button == null or first_button.text.contains("获得") or first_button.text.contains("代价"):
		_fail("Event choice UI must not disclose mechanical rewards or costs.")
		return
	var result := RunManager.resolve_event_choice(event_id, String(choices[0].get("choice_id", "")), 1201)
	popup.show_result(result)
	await get_tree().process_frame
	if popup.get_node("Panel/ChoicesScroll/ChoicesList").get_child(0) is not RichTextLabel:
		_fail("Event result should remain inside the original popup.")
		return
	popup.queue_free()
	print("Event choice flow check passed.")
	get_tree().quit(0)


func _force_accessible_event_node() -> int:
	for index in range(RunManager.map_nodes.size()):
		var node: Dictionary = RunManager.map_nodes[index]
		if int(node.get("id", -1)) <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL:
			continue
		node["type"] = RunManager.NODE_EVENT
		node["completed"] = false
		var links: Array = node.get("links", [])
		if not links.has(RunManager.CENTER_ID):
			links.append(RunManager.CENTER_ID)
		node["links"] = links
		RunManager.map_nodes[index] = node
		var base: Dictionary = RunManager.map_nodes[RunManager.CENTER_ID]
		var base_links: Array = base.get("links", [])
		if not base_links.has(int(node.get("id", -1))):
			base_links.append(int(node.get("id", -1)))
		base["links"] = base_links
		RunManager.map_nodes[RunManager.CENTER_ID] = base
		return int(node.get("id", -1))
	return -1


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
