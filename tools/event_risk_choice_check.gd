extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_event_profiles_have_risk_shape()
	if _failed:
		return
	var event_id := _force_accessible_event_node(2)
	_check_event_choices_expose_risk(event_id)
	if _failed:
		return
	_check_risky_event_applies_cost(event_id)
	if _failed:
		return
	print("Event risk choice check passed.")
	get_tree().quit(0)


func _check_event_profiles_have_risk_shape() -> void:
	var profiles: Array = RunManager.get_event_profiles()
	var seen_risks := {}
	for profile in profiles:
		var risk := int(Dictionary(profile).get("risk_level", -1))
		if risk < 0:
			_fail("Every event profile should define risk_level: %s" % str(profile))
			return
		if String(Dictionary(profile).get("risk_label", "")).is_empty():
			_fail("Every event profile should define risk_label: %s" % str(profile))
			return
		if String(Dictionary(profile).get("reward_tag", "")).is_empty():
			_fail("Every event profile should define reward_tag: %s" % str(profile))
			return
		seen_risks[risk] = true
	if seen_risks.size() < 3:
		_fail("Event catalog should contain at least 3 risk tiers, got %d." % seen_risks.size())
		return


func _check_event_choices_expose_risk(event_id: int) -> void:
	var choices: Array = RunManager.prepare_event_choices(event_id, 2201)
	if choices.size() != 3:
		_fail("Risk event choices should still offer exactly 3 choices.")
		return
	for choice in choices:
		if not Dictionary(choice).has("risk_level") or not Dictionary(choice).has("risk_label"):
			_fail("Choice should expose risk level and label: %s" % str(choice))
			return
		if String(Dictionary(choice).get("reward_preview", "")).is_empty():
			_fail("Choice should expose reward_preview: %s" % str(choice))
			return
		if String(Dictionary(choice).get("cost_preview", "")).is_empty():
			_fail("Choice should expose cost_preview: %s" % str(choice))
			return
		var tactic_preview := String(Dictionary(choice).get("tactic_preview", ""))
		if tactic_preview.is_empty() or not tactic_preview.contains("战法："):
			_fail("Choice should expose readable tactic_preview: %s" % str(choice))
			return
		if not String(Dictionary(choice).get("preview", "")).contains(String(Dictionary(choice).get("risk_label", ""))):
			_fail("Choice preview should include risk label: %s" % str(choice))
			return


func _check_risky_event_applies_cost(event_id: int) -> void:
	RunManager.force_next_event_id = "salvage_contract"
	var choices: Array = RunManager.prepare_event_choices(event_id, 3301)
	if choices.is_empty():
		_fail("Forced risky event should be offered.")
		return
	var choice_id := String(choices[0].get("choice_id", ""))
	GameManager.player_hp = 80
	var crisis_before := RunManager.crisis_level
	var result := RunManager.resolve_event_choice(event_id, choice_id, 3301)
	if not bool(result.get("ok", false)):
		_fail("Forced risky event should resolve: %s" % str(result))
		return
	if int(result.get("risk_level", 0)) < 2:
		_fail("salvage_contract should be a high-risk event result: %s" % str(result))
		return
	var paid_hp := int(result.get("hp_lost", 0))
	var paid_minerals := int(result.get("minerals_spent", 0))
	var crisis_added := int(result.get("crisis_added", 0))
	if paid_hp <= 0 and paid_minerals <= 0 and crisis_added <= 0:
		_fail("Risky event should apply at least one visible cost: %s" % str(result))
		return
	if GameManager.player_hp >= 80 and RunManager.crisis_level <= crisis_before:
		_fail("Risky event cost should affect run state, hp=%d crisis=%d result=%s" % [GameManager.player_hp, RunManager.crisis_level, str(result)])
		return


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
