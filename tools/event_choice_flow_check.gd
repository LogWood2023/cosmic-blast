extends Node

const EVENT_CHOICE_POPUP_SCENE := preload("res://scenes/ui/world_map/EventChoicePopup.tscn")
const EVENT_RESULT_POPUP_SCENE := preload("res://scenes/ui/world_map/EventResultPopup.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var event_id := _force_accessible_event_node(2)
	_check_choice_generation(event_id)
	if _failed:
		return
	await _check_choice_popup_shows_tactic(event_id)
	if _failed:
		return
	await _check_choice_resolution(event_id)
	if _failed:
		return
	print("Event choice flow check passed.")
	get_tree().quit(0)


func _check_choice_generation(event_id: int) -> void:
	if not RunManager.has_method("prepare_event_choices"):
		_fail("RunManager should expose prepare_event_choices().")
		return
	var choices: Array = RunManager.prepare_event_choices(event_id, 1201)
	if choices.size() != 3:
		_fail("Event node should offer exactly 3 choices, got %d." % choices.size())
		return
	var seen := {}
	for choice in choices:
		var choice_id := String(choice.get("choice_id", ""))
		var title := String(choice.get("title", ""))
		var category := String(choice.get("category", ""))
		var preview := String(choice.get("preview", ""))
		var tactic_preview := String(choice.get("tactic_preview", ""))
		if choice_id.is_empty() or title.is_empty() or category.is_empty() or preview.is_empty() or tactic_preview.is_empty():
			_fail("Each event choice should expose choice_id/title/category/preview/tactic_preview.")
			return
		if not tactic_preview.contains("战法："):
			_fail("Event tactic preview should use in-game battle-plan copy, got: %s" % tactic_preview)
			return
		if _contains_ascii_letter(tactic_preview):
			_fail("Event tactic preview should be Chinese UI copy, got: %s" % tactic_preview)
			return
		if seen.has(choice_id):
			_fail("Event choices should be unique.")
			return
		seen[choice_id] = true


func _check_choice_popup_shows_tactic(event_id: int) -> void:
	var node := RunManager.get_map_node(event_id)
	var choices: Array = RunManager.prepare_event_choices(event_id, 1201)
	var popup := EVENT_CHOICE_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup", node, choices)
	await get_tree().process_frame
	var list := popup.get_node_or_null("Panel/ChoicesScroll/ChoicesList") as VBoxContainer
	if list == null or list.get_child_count() <= 0:
		_fail("Event choice popup should render choice buttons.")
		popup.queue_free()
		return
	var button := list.get_child(0) as Button
	if button == null or not button.text.contains("战法："):
		_fail("Event choice popup should show tactic preview, got: %s" % (button.text if button else ""))
		popup.queue_free()
		return
	popup.queue_free()


func _check_choice_resolution(event_id: int) -> void:
	var choices: Array = RunManager.prepare_event_choices(event_id, 1201)
	var chosen_id := String(choices[1].get("choice_id", ""))
	if not RunManager.has_method("resolve_event_choice"):
		_fail("RunManager should expose resolve_event_choice().")
		return
	var result: Dictionary = RunManager.resolve_event_choice(event_id, chosen_id, 1201)
	if not bool(result.get("ok", false)):
		_fail("Resolving an offered event choice should succeed: %s" % str(result))
		return
	if String(result.get("event_id", "")) != chosen_id:
		_fail("Resolved event should match selected choice.")
		return
	var tactic_preview := String(result.get("tactic_preview", ""))
	if tactic_preview.is_empty() or not tactic_preview.contains("战法："):
		_fail("Resolved event should carry tactic preview, got: %s" % str(result))
		return
	await _check_result_popup_shows_tactic(result, tactic_preview)
	if _failed:
		return
	if not RunManager.is_node_completed(event_id):
		_fail("Resolving an event choice should complete the node.")
		return
	var repeat: Dictionary = RunManager.resolve_event_choice(event_id, chosen_id, 1201)
	if bool(repeat.get("ok", false)):
		_fail("Resolved event node should not resolve a second time.")
		return


func _check_result_popup_shows_tactic(result: Dictionary, tactic_preview: String) -> void:
	var popup := EVENT_RESULT_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup", result)
	await get_tree().process_frame
	var body_label := popup.get_node_or_null("Panel/BodyLabel") as RichTextLabel
	if body_label == null or not body_label.text.contains(tactic_preview):
		_fail("Event result popup should show tactic preview. Expected: %s Body: %s" % [tactic_preview, body_label.text if body_label else ""])
		popup.queue_free()
		return
	popup.queue_free()


func _force_accessible_event_node(tier: int) -> int:
	for i in range(RunManager.map_nodes.size()):
		var node := RunManager.map_nodes[i]
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == RunManager.NODE_SPECIAL or int(node.get("tier", 0)) != tier:
			continue
		node["type"] = RunManager.NODE_EVENT
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


func _contains_ascii_letter(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			return true
	return false
