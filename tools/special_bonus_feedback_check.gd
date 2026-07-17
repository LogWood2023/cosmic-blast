extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_bonus_display_names()
	if _failed:
		return
	await _check_world_map_reports_activated_bonus()
	if _failed:
		return
	await _check_world_map_lists_active_bonus_summaries()
	if _failed:
		return
	await _check_world_map_lists_active_contract_summaries()
	if _failed:
		return
	await _check_world_map_reports_contract_completion_feedback()
	if _failed:
		return
	await _check_world_map_reports_beacon_echo_routes()
	if _failed:
		return
	await _check_world_map_opens_special_bonus_popup()
	if _failed:
		return
	print("Special bonus feedback check passed.")
	get_tree().quit(0)


func _check_bonus_display_names() -> void:
	if not RunManager.has_method("get_special_bonus_display_name"):
		_fail("RunManager should expose special bonus display names for UI feedback.")
		return
	var display_name := String(RunManager.call("get_special_bonus_display_name", "colossus_charge_beacon"))
	if display_name.is_empty() or display_name == "colossus_charge_beacon":
		_fail("Special bonus display name should hide internal ids: %s" % display_name)
		return
	if _contains_ascii_letter(display_name):
		_fail("Special bonus display name should be Chinese copy: %s" % display_name)
		return


func _check_world_map_reports_activated_bonus() -> void:
	RunManager.start_new_run()
	RunManager.last_node_completion_summary = {
		"ok": true,
		"minerals_committed": 17,
		"activated_specials": ["colossus_charge_beacon"],
	}
	var world_map := WORLD_MAP_SCENE.instantiate()
	add_child(world_map)
	await get_tree().process_frame
	var message_label := world_map.get_node("WorldMap/MessageLabel") as Label
	var text := message_label.text
	if not text.contains("撤离结算完成"):
		_fail("World map should report node completion feedback: %s" % text)
		return
	if not text.contains("冲刺碰撞协议"):
		_fail("World map should show activated special bonus display name: %s" % text)
		return
	if text.contains("colossus_charge_beacon"):
		_fail("World map should hide internal special bonus ids: %s" % text)
		return
	world_map.queue_free()


func _check_world_map_lists_active_bonus_summaries() -> void:
	RunManager.start_new_run()
	RunManager.active_special_bonus_ids = [
		"colossus_charge_beacon",
		"paradise_fire_beacon",
		"ark_guard_beacon",
	]
	if not RunManager.has_method("get_active_special_bonus_summaries"):
		_fail("RunManager should expose active special bonus summaries for the core map panel.")
		return
	var summaries: Array = RunManager.call("get_active_special_bonus_summaries")
	if summaries.size() != 3:
		_fail("Active special bonus summaries should include every active beacon, got %d." % summaries.size())
		return
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		var name := String(summary.get("name", ""))
		var effects := String(summary.get("effects_text", ""))
		if name.is_empty() or effects.is_empty():
			_fail("Active special bonus summary should include name and effects: %s" % str(summary))
			return
		if _contains_ascii_letter(name) or _contains_ascii_letter(effects):
			_fail("Active special bonus summary should be Chinese UI copy: %s" % str(summary))
			return

	var world_map := WORLD_MAP_SCENE.instantiate()
	add_child(world_map)
	await get_tree().process_frame
	var details_body := world_map.get_node("WorldMap/DetailsPanel/DetailsBody") as RichTextLabel
	var text := details_body.text
	if not text.contains("已接入协议"):
		_fail("Core details should list active beacon protocols: %s" % text)
		return
	for expected in ["冲刺碰撞协议", "覆盖火力协议", "核心护盾协议"]:
		if not text.contains(expected):
			_fail("Core details should include %s. Details: %s" % [expected, text])
			return
	if text.contains("colossus_charge_beacon") or text.contains("paradise_fire_beacon") or text.contains("ark_guard_beacon"):
		_fail("Core details should hide special bonus ids: %s" % text)
		return
	world_map.queue_free()


func _check_world_map_lists_active_contract_summaries() -> void:
	RunManager.start_new_run()
	RunManager.active_event_contracts = [
		{
			"contract_id": "colossus_impact_route",
			"title": "巨构撞角航线",
			"description": "接下来 2 个完成节点内，冲锋距离与撞击威力提高，余震边缘更宽。",
			"effect_type": "family_route",
			"family_bias": "colossus",
			"remaining_nodes": 2,
			"duration_nodes": 2,
			"dash_distance_mult": 1.14,
			"dash_damage_mult": 1.16,
			"dash_aftershock_radius_bonus": 48.0,
		},
		{
			"contract_id": "salvage_contract",
			"title": "回收承包合约",
			"description": "接下来 2 个完成节点的矿物结算 +35%，但每次额外提升 1 点危机。",
			"effect_type": "salvage_pressure",
			"remaining_nodes": 1,
			"duration_nodes": 2,
			"mineral_bonus_rate": 0.35,
			"extra_crisis_on_complete": 1,
		},
	]
	if not RunManager.has_method("get_active_event_contract_summaries"):
		_fail("RunManager should expose active event contract summaries for the core map panel.")
		return
	var summaries: Array = RunManager.call("get_active_event_contract_summaries")
	if summaries.size() != 2:
		_fail("Active event contract summaries should include every active contract, got %d." % summaries.size())
		return
	for raw_summary in summaries:
		var summary := Dictionary(raw_summary)
		var title := String(summary.get("title", ""))
		var effects := String(summary.get("effects_text", ""))
		if title.is_empty() or effects.is_empty():
			_fail("Active event contract summary should include title and effects: %s" % str(summary))
			return
		if _contains_ascii_letter(title) or _contains_ascii_letter(effects):
			_fail("Active event contract summary should be Chinese UI copy: %s" % str(summary))
			return

	var world_map := WORLD_MAP_SCENE.instantiate()
	add_child(world_map)
	await get_tree().process_frame
	var details_body := world_map.get_node("WorldMap/DetailsPanel/DetailsBody") as RichTextLabel
	var text := details_body.text
	if not text.contains("航路契约"):
		_fail("Core details should list active route contracts: %s" % text)
		return
	for expected in ["巨构撞角航线", "星间巨构", "冲锋强化", "剩余 2 节点", "回收承包合约", "矿物 +35%", "危机 +1"]:
		if not text.contains(expected):
			_fail("Core details should include %s. Details: %s" % [expected, text])
			return
	if text.contains("colossus_impact_route") or text.contains("salvage_contract"):
		_fail("Core details should hide internal contract ids: %s" % text)
		return
	world_map.queue_free()


func _check_world_map_reports_contract_completion_feedback() -> void:
	RunManager.start_new_run()
	RunManager.last_node_completion_summary = {
		"ok": true,
		"minerals_committed": 120,
		"event_contract_minerals_added": 35,
		"event_contract_crisis_added": 1,
		"event_contracts_applied": [
			{
				"contract_id": "salvage_contract",
				"title": "回收承包合约",
				"minerals_added": 35,
			},
			{
				"contract_id": "mercenary_marker",
				"title": "雇佣标记",
				"crisis_added": 1,
			},
		],
		"expired_event_contract_count": 1,
		"expired_event_contracts": [
			{
				"contract_id": "salvage_contract",
				"title": "回收承包合约",
			},
		],
	}
	var world_map := WORLD_MAP_SCENE.instantiate()
	add_child(world_map)
	await get_tree().process_frame
	var message_label := world_map.get_node("WorldMap/MessageLabel") as Label
	var text := message_label.text
	for expected in ["撤离结算完成", "回收星髓矿 +120", "契约回响", "回收承包合约", "矿物 +35", "危机 +1", "契约到期"]:
		if not text.contains(expected):
			_fail("World map completion message should include %s. Message: %s" % [expected, text])
			return
	if text.contains("salvage_contract") or text.contains("mercenary_marker"):
		_fail("World map completion message should hide internal contract ids: %s" % text)
		return
	world_map.queue_free()


func _check_world_map_reports_beacon_echo_routes() -> void:
	RunManager.start_new_run()
	RunManager.last_node_completion_summary = {
		"ok": true,
		"minerals_committed": 0,
		"activated_specials": ["warped_tide_beacon"],
		"beacon_echo_routes": [
			{
				"node_id": 8,
				"node_name": "暗潮裂隙",
				"bonus_id": "warped_tide_beacon",
				"bonus_name": "暗潮牵引协议",
				"family_name": "扭曲星核",
				"equipment_bonus": 0.08,
				"reward_bonus": 0.10,
			},
		],
	}
	var world_map := WORLD_MAP_SCENE.instantiate()
	add_child(world_map)
	await get_tree().process_frame
	var message_label := world_map.get_node("WorldMap/MessageLabel") as Label
	var text := message_label.text
	for expected in ["新增信标", "暗潮牵引协议", "回响航线", "暗潮裂隙", "扭曲星核", "装备出现率 +8%"]:
		if not text.contains(expected):
			_fail("World map beacon echo message should include %s. Message: %s" % [expected, text])
			return
	if text.contains("warped_tide_beacon"):
		_fail("World map beacon echo message should hide internal ids: %s" % text)
		return
	world_map.queue_free()


func _check_world_map_opens_special_bonus_popup() -> void:
	RunManager.start_new_run()
	RunManager.last_node_completion_summary = {
		"ok": true,
		"minerals_committed": 0,
		"activated_specials": ["colossus_charge_beacon"],
		"beacon_echo_routes": [
			{
				"node_id": 7,
				"node_name": "巨构残响带",
				"bonus_id": "colossus_charge_beacon",
				"bonus_name": "冲刺碰撞协议",
				"family_name": "星间巨构",
				"equipment_bonus": 0.08,
				"reward_bonus": 0.10,
			},
		],
	}
	var world_map := WORLD_MAP_SCENE.instantiate()
	add_child(world_map)
	await get_tree().process_frame
	var popup := world_map.get_node_or_null("WorldMap/SpecialBonusPopup")
	if popup == null:
		_fail("World map should open a standalone SpecialBonusPopup when a beacon protocol is connected.")
		return
	for path in ["Panel/TitleLabel", "Panel/BodyLabel", "Panel/CloseButton"]:
		if popup.get_node_or_null(path) == null:
			_fail("Special bonus popup should expose %s." % path)
			return
	var title := (popup.get_node("Panel/TitleLabel") as Label).text
	var body := (popup.get_node("Panel/BodyLabel") as RichTextLabel).text
	var text := "%s\n%s" % [title, body]
	for expected in ["信标接入", "冲刺碰撞协议", "巨构残响带", "星间巨构", "装备出现率 +8%", "矿物倍率"]:
		if not text.contains(expected):
			_fail("Special bonus popup should include %s. Popup: %s" % [expected, text])
			return
	for hidden in ["colossus_charge_beacon", "bonus_id", "node_id"]:
		if text.contains(hidden):
			_fail("Special bonus popup should hide internal ids: %s" % text)
			return
	world_map.queue_free()


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
