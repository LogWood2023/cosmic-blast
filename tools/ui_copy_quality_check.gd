extends Node


const UI_SCENES: Array[String] = [
	"res://scenes/ui/main_menu/MainMenuGeneratedUI.tscn",
	"res://scenes/ui/main_menu/SettingsPopup.tscn",
	"res://scenes/ui/boss_select/BossSelectUI.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/ui/player_status/PlayerStatusHUD.tscn",
	"res://scenes/ui/BossHUD.tscn",
	"res://scenes/ui/world_map/WorldMapUI.tscn",
	"res://scenes/ui/world_map/ShopPopup.tscn",
	"res://scenes/ui/world_map/HangarPopup.tscn",
	"res://scenes/ui/world_map/EventChoicePopup.tscn",
	"res://scenes/ui/world_map/BossRewardPopup.tscn",
	"res://scenes/ui/world_map/SpecialBonusPopup.tscn",
	"res://scenes/ui/world_map/EquipmentItemRow.tscn",
	"res://scenes/ui/explore/ExploreMapUI.tscn",
	"res://scenes/ui/explore/CompassMiniMap.tscn",
	"res://scenes/ui/explore/CommandConsolePopup.tscn",
	"res://scenes/ui/explore_loading/ExploreLoadingScreen.tscn",
	"res://scenes/ui/game_over/GameOverUI.tscn",
	"res://scenes/ui/EvacuationSuccessHUD.tscn",
]

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
	"Start",
	"Settings",
	"Quit",
	"Shop",
	"Hangar",
	"Equipment",
	"Loadout",
	"Debug",
	"Test",
	"Runtime",
	"smoke",
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
	if get_node_or_null("/root/RunManager") != null:
		RunManager.start_new_run()
	for scene_path in UI_SCENES:
		await _check_scene(scene_path)
		if _failed:
			return
	print("UI copy quality check passed.")
	get_tree().quit(0)


func _check_scene(scene_path: String) -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("UI copy check could not load: %s" % scene_path)
		return
	var instance := packed.instantiate()
	if instance == null:
		_fail("UI copy check could not instantiate: %s" % scene_path)
		return
	add_child(instance)
	_setup_dynamic_content(scene_path, instance)
	await get_tree().process_frame
	_scan_visible_copy(scene_path, instance)
	instance.queue_free()
	await get_tree().process_frame


func _setup_dynamic_content(scene_path: String, instance: Node) -> void:
	if scene_path.ends_with("ShopPopup.tscn") and instance.has_method("setup"):
		instance.call("setup")
	if scene_path.ends_with("HangarPopup.tscn") and instance.has_method("setup"):
		instance.call("setup")
	if scene_path.ends_with("EquipmentItemRow.tscn") and instance.has_method("setup"):
		instance.call("setup", "aux_copy_probe", "巡航纹章", "辅助机 / 算力 2", "运行校验条目", "装配", false, "")
	if scene_path.ends_with("EventChoicePopup.tscn") and instance.has_method("setup"):
		instance.call(
			"setup",
			{"tier": 2, "intel_title": "失落航标", "family_bias": "paradise"},
			[
				{"choice_id": "minerals", "title": "接入补给链", "category": "minerals", "preview": "回收一批星髓矿", "reward_preview": "星髓矿增加"},
				{"choice_id": "heal", "title": "静默修复", "category": "heal", "preview": "恢复机体结构", "reward_preview": "结构值回升"},
				{"choice_id": "equipment", "title": "密封蓝图", "category": "equipment", "preview": "取得一件装备", "reward_preview": "装备入库"},
			]
		)
	if scene_path.ends_with("BossRewardPopup.tscn") and instance.has_method("setup"):
		instance.call(
			"setup",
			{
				"ok": true,
				"stage": 1,
				"family_name": "星间巨构",
				"item_name": "巨构折跃撞角",
			}
		)
	if scene_path.ends_with("SpecialBonusPopup.tscn") and instance.has_method("setup"):
		instance.call(
			"setup",
			{
				"activated_names": ["冲刺碰撞协议"],
				"beacon_echo_routes": [
					{
						"node_name": "巨构残响带",
						"family_name": "星间巨构",
						"equipment_bonus": 0.08,
						"reward_bonus": 0.10,
					},
				],
			}
		)


func _scan_visible_copy(scene_path: String, node: Node) -> void:
	_check_node_copy(scene_path, node)
	if _failed:
		return
	for child in node.get_children():
		_scan_visible_copy(scene_path, child)
		if _failed:
			return


func _check_node_copy(scene_path: String, node: Node) -> void:
	var label := "%s/%s" % [scene_path, node.get_path()]
	if node is OptionButton:
		var option_button := node as OptionButton
		_check_copy("%s/text" % label, option_button.text, false)
		if _failed:
			return
		for i in range(option_button.get_item_count()):
			_check_copy("%s/item_%d" % [label, i], option_button.get_item_text(i), true)
			if _failed:
				return
	elif node is Button:
		_check_copy("%s/text" % label, (node as Button).text, false)
	elif node is RichTextLabel:
		_check_copy("%s/text" % label, (node as RichTextLabel).text, false)
	elif node is Label:
		_check_copy("%s/text" % label, (node as Label).text, false)
	elif node is LineEdit:
		_check_copy("%s/placeholder" % label, (node as LineEdit).placeholder_text, false)
	elif node is TextEdit:
		_check_copy("%s/placeholder" % label, (node as TextEdit).placeholder_text, false)


func _check_copy(label: String, text: String, required: bool) -> void:
	var stripped := _strip_bbcode(text).strip_edges()
	if stripped.is_empty():
		if required:
			_fail("%s should not be empty." % label)
		return
	if _is_symbolic_or_numeric(stripped):
		return
	if not _contains_cjk(stripped):
		_fail("%s should be Chinese UI copy: %s" % [label, stripped])
		return
	if _contains_ascii_letter(stripped):
		_fail("%s should not contain English letters: %s" % [label, stripped])
		return
	for term in FORBIDDEN_COPY_TERMS:
		if stripped.to_lower().contains(term.to_lower()):
			_fail("%s contains design-note term '%s': %s" % [label, term, stripped])
			return


func _strip_bbcode(text: String) -> String:
	var output := ""
	var in_tag := false
	for i in range(text.length()):
		var character := text[i]
		if character == "[":
			in_tag = true
			continue
		if character == "]" and in_tag:
			in_tag = false
			continue
		if not in_tag:
			output += character
	return output


func _is_symbolic_or_numeric(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if (code >= 0x4e00 and code <= 0x9fff) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			return false
	return true


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
