extends Node


const FORBIDDEN_COPY_TERMS: Array[String] = [
	"适合",
	"预留",
	"测试",
	"构筑",
	"需求",
	"玩家",
	"首版",
	"Boss",
	"boss",
	"build",
	"early",
	"late",
	"run",
	"drone",
	"dash",
	"fire",
]

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_profile_array("事件档案", RunManager.get_event_profiles(), ["title", "description", "risk_label", "reward_tag"])
	if _failed:
		return
	_check_profile_array("奖励节点档案", RunManager.get_reward_profiles(), ["title", "description"])
	if _failed:
		return
	_check_profile_array("战斗节点档案", RunManager.get_battle_profiles(), ["title", "description"])
	if _failed:
		return
	_check_generated_map_copy()
	if _failed:
		return
	_check_event_choice_and_result_copy()
	if _failed:
		return
	_check_management_operation_copy()
	if _failed:
		return
	print("Run copy quality check passed.")
	get_tree().quit(0)


func _check_profile_array(group_name: String, profiles: Array, keys: Array[String]) -> void:
	if profiles.is_empty():
		_fail("%s should expose profiles." % group_name)
		return
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		var id := String(profile.get("id", "unknown"))
		for key in keys:
			_check_copy("%s/%s/%s" % [group_name, id, key], String(profile.get(key, "")), true)
			if _failed:
				return
		var contract := Dictionary(profile.get("contract", {}))
		if not contract.is_empty():
			_check_copy("%s/%s/contract_title" % [group_name, id], String(contract.get("title", "")), true)
			if _failed:
				return
			_check_copy("%s/%s/contract_description" % [group_name, id], String(contract.get("description", "")), true)
			if _failed:
				return


func _check_generated_map_copy() -> void:
	for node in RunManager.map_nodes:
		var node_id := int(node.get("id", -1))
		var node_type := String(node.get("type", ""))
		_check_copy("地图节点/%d/name" % node_id, String(node.get("name", "")), true)
		if _failed:
			return
		for key in ["intel_title", "intel_description", "battle_title", "battle_description", "reward_title", "reward_description", "bonus_name", "bonus_description"]:
			if not node.has(key):
				continue
			_check_copy("地图节点/%d/%s" % [node_id, key], String(node.get(key, "")), true)
			if _failed:
				return
		if node_type == RunManager.NODE_SPECIAL and String(node.get("bonus_description", "")).is_empty():
			_fail("Special node %d should expose bonus copy." % node_id)
			return


func _check_event_choice_and_result_copy() -> void:
	var event_id := _force_accessible_event_node(2)
	if event_id <= 0:
		_fail("Need an accessible event node for copy check.")
		return
	for event_profile in RunManager.get_event_profiles():
		var choice_id := String(Dictionary(event_profile).get("id", ""))
		if choice_id.is_empty():
			continue
		RunManager.force_next_event_id = choice_id
		var choices := RunManager.prepare_event_choices(event_id, 9001)
		if choices.is_empty():
			_fail("Event copy check could not prepare choice %s." % choice_id)
			return
		var choice := Dictionary(choices[0])
		for key in ["title", "preview", "reward_preview", "cost_preview", "contract_preview", "risk_label", "reward_tag"]:
			if not choice.has(key):
				continue
			var allow_empty: bool = key == "contract_preview"
			_check_copy("事件选择/%s/%s" % [choice_id, key], String(choice.get(key, "")), not allow_empty)
			if _failed:
				return

	for event_profile in RunManager.get_event_profiles():
		RunManager.start_new_run()
		var choice_id := String(Dictionary(event_profile).get("id", ""))
		var forced_id := _force_accessible_event_node(2)
		if forced_id <= 0:
			_fail("Need event node for resolving %s." % choice_id)
			return
		RunManager.force_next_event_id = choice_id
		GameManager.player_hp = GameManager.PLAYER_MAX_HP
		var result := RunManager.resolve_event_choice(forced_id, choice_id, 9201)
		if not bool(result.get("ok", false)):
			_fail("Event copy check could not resolve %s: %s" % [choice_id, str(result)])
			return
		for key in ["event_title", "message", "risk_label", "reward_tag", "cost_preview", "contract_title", "contract_description"]:
			if not result.has(key):
				continue
			_check_copy("事件结果/%s/%s" % [choice_id, key], String(result.get(key, "")), false)
			if _failed:
				return


func _check_management_operation_copy() -> void:
	RunManager.start_new_run()
	RunManager.cancel_run()
	_check_result_message_copy("经营操作/商店/未启动", RunManager.reroll_shop_offers())
	if _failed:
		return

	RunManager.start_new_run()
	RunManager.minerals = 0
	_check_result_message_copy("经营操作/商店/矿物不足", RunManager.reroll_shop_offers())
	if _failed:
		return
	RunManager.minerals = RunManager.get_shop_reroll_cost()
	_check_result_message_copy("经营操作/商店/刷新货单", RunManager.reroll_shop_offers())
	if _failed:
		return


func _check_result_message_copy(label: String, result: Dictionary) -> void:
	if not result.has("message"):
		_fail("%s should include a user-facing message." % label)
		return
	_check_copy("%s/message" % label, String(result.get("message", "")), true)


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


func _check_copy(label: String, text: String, required: bool) -> void:
	if text.is_empty():
		if required:
			_fail("%s should not be empty." % label)
		return
	if not _contains_cjk(text):
		_fail("%s should be Chinese copy: %s" % [label, text])
		return
	if _contains_ascii_letter(text):
		_fail("%s should not contain English letters: %s" % [label, text])
		return
	for term in FORBIDDEN_COPY_TERMS:
		if text.to_lower().contains(term.to_lower()):
			_fail("%s contains design-note term '%s': %s" % [label, term, text])
			return


func _contains_cjk(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code >= 0x4e00 and code <= 0x9fff:
			return true
	return false


func _contains_ascii_letter(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
