extends Control

signal closed
signal inventory_changed
signal message_requested(message: String)

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const ITEM_ROW_SCENE := preload("res://scenes/ui/world_map/EquipmentItemRow.tscn")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")
const FAMILY_FILTER_OPTIONS: Array[Dictionary] = [
	{"id": "", "label": "全部", "node": "AllButton"},
	{"id": EquipmentCatalogScript.FAMILY_COLOSSUS, "label": "星间巨构", "node": "ColossusButton"},
	{"id": EquipmentCatalogScript.FAMILY_PARADISE, "label": "天堂号", "node": "ParadiseButton"},
	{"id": EquipmentCatalogScript.FAMILY_WARPED, "label": "扭曲星核", "node": "WarpedButton"},
	{"id": EquipmentCatalogScript.FAMILY_HELL_EYE, "label": "地狱之眼", "node": "HellEyeButton"},
	{"id": EquipmentCatalogScript.FAMILY_DIVINE, "label": "神明使者", "node": "DivineButton"},
	{"id": EquipmentCatalogScript.FAMILY_GENERAL, "label": "通用", "node": "GeneralButton"},
]
const MAX_RECOMMENDED_AUXILIARIES: int = 2

@onready var weapon_label: Label = $Panel/WeaponLabel
@onready var aux_label: Label = $Panel/AuxLabel
@onready var compute_label: Label = $Panel/ComputeLabel
@onready var message_label: Label = $Panel/MessageLabel
@onready var items_list: VBoxContainer = $Panel/ItemsScroll/ItemsList
@onready var close_button: Button = $Panel/CloseButton
@onready var charm_slots: HBoxContainer = $Panel/CharmBay/CharmSlots
@onready var summary_label: Label = $Panel/LoadoutBar/SummaryLabel
@onready var archetype_sync_label: Label = $Panel/LoadoutBar/ArchetypeSyncLabel
@onready var loadout_buttons: Array[Button] = [
	$Panel/LoadoutBar/Loadout1SaveButton,
	$Panel/LoadoutBar/Loadout1ApplyButton,
	$Panel/LoadoutBar/Loadout2SaveButton,
	$Panel/LoadoutBar/Loadout2ApplyButton,
	$Panel/LoadoutBar/Loadout3SaveButton,
	$Panel/LoadoutBar/Loadout3ApplyButton,
]
@onready var family_filter_bar: HBoxContainer = $Panel/FamilyFilterBar
@onready var build_guidance_title: Label = $Panel/BuildGuidanceBar/BuildGuidanceTitle
@onready var build_guidance_detail: Label = $Panel/BuildGuidanceBar/BuildGuidanceDetail
@onready var build_guidance_node: Label = $Panel/BuildGuidanceBar/BuildGuidanceNode
@onready var recommendation_bar: HBoxContainer = $Panel/RecommendationBar
@onready var recommendation_title: Label = $Panel/RecommendationBar/RecommendationTitle
@onready var recommendation_detail: Label = $Panel/RecommendationBar/RecommendationDetail
@onready var recommendation_equip_button: Button = $Panel/RecommendationBar/RecommendationEquipButton

var _active_family_filter: String = ""
var _recommended_auxiliaries: Array[String] = []


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	close_button.pressed.connect(_on_close_pressed)
	recommendation_equip_button.pressed.connect(_on_recommendation_equip_pressed)
	_bind_loadout_buttons()
	_bind_family_filter_buttons()


func setup() -> void:
	_refresh()


func _refresh() -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return

	weapon_label.text = "当前武器：%s" % EquipmentCatalogScript.get_display_name(run_manager.equipped_weapon)
	aux_label.text = "辅助机：%s" % _equipped_aux_text()
	compute_label.text = "算力：%d/%d" % [run_manager.get_used_compute(), int(run_manager.compute_capacity)]
	summary_label.text = _loadout_summary_text()
	archetype_sync_label.text = _archetype_sync_text()
	_refresh_charm_slots(run_manager.get_used_compute(), int(run_manager.compute_capacity))
	_refresh_loadout_button_state()
	_sync_family_filter_buttons()
	_refresh_build_guidance(run_manager)
	_refresh_recommendation(run_manager)

	for child in items_list.get_children():
		child.queue_free()

	for item_id in run_manager.equipment_inventory:
		if not _item_matches_family_filter(item_id):
			continue
		var item := EquipmentCatalogScript.get_item(item_id)
		var item_type := EquipmentCatalogScript.get_type(item_id)
		var is_weapon := item_type == EquipmentCatalogScript.TYPE_WEAPON
		var is_equipped_weapon: bool = item_id == run_manager.equipped_weapon
		var is_equipped_aux: bool = run_manager.equipped_auxiliaries.has(item_id)
		var status := ""
		if is_equipped_weapon:
			status = "[已装填]"
		elif is_equipped_aux:
			status = "[已装配]"

		var meta := EquipmentCatalogScript.get_ui_meta_text(item_id, false, 0)

		var action_text := "已装填" if is_equipped_weapon else "装配"
		if not is_weapon and is_equipped_aux:
			action_text = "卸下"

		var row = ITEM_ROW_SCENE.instantiate()
		items_list.add_child(row)
		row.setup(
			item_id,
			String(item.get("name", item_id)),
			meta,
			String(item.get("description", "")),
			action_text,
			is_equipped_weapon,
			status
		)
		row.action_pressed.connect(_on_equip_item)


func _bind_family_filter_buttons() -> void:
	for option in FAMILY_FILTER_OPTIONS:
		var button := family_filter_bar.get_node_or_null(String(option.get("node", ""))) as Button
		if button == null:
			continue
		button.toggle_mode = true
		button.text = String(option.get("label", ""))
		button.pressed.connect(_on_family_filter_pressed.bind(String(option.get("id", ""))))


func _bind_loadout_buttons() -> void:
	for i in range(3):
		var save_button := loadout_buttons[i * 2]
		var apply_button := loadout_buttons[i * 2 + 1]
		save_button.pressed.connect(_on_save_loadout_pressed.bind(i))
		apply_button.pressed.connect(_on_apply_loadout_pressed.bind(i))


func _refresh_loadout_button_state() -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	for i in range(3):
		var preset: Dictionary = run_manager.get_loadout_preset(i)
		var save_button := loadout_buttons[i * 2]
		var apply_button := loadout_buttons[i * 2 + 1]
		save_button.text = "存档 %d" % (i + 1)
		apply_button.text = "读取 %d" % (i + 1)
		apply_button.disabled = preset.is_empty()


func _sync_family_filter_buttons() -> void:
	for option in FAMILY_FILTER_OPTIONS:
		var button := family_filter_bar.get_node_or_null(String(option.get("node", ""))) as Button
		if button == null:
			continue
		button.set_pressed_no_signal(String(option.get("id", "")) == _active_family_filter)


func _refresh_charm_slots(used: int, capacity: int) -> void:
	# 算力上限随进度增长（每节点 +1，事件还能再加），场景里的固定槽位不够就动态补
	while charm_slots.get_child_count() < capacity:
		var extra_slot := ColorRect.new()
		extra_slot.custom_minimum_size = Vector2(34, 24)
		charm_slots.add_child(extra_slot)
	var slots := charm_slots.get_children()
	for i in range(slots.size()):
		var slot := slots[i] as ColorRect
		if i >= capacity:
			slot.visible = false
			continue
		slot.visible = true
		slot.color = Color(0.38, 1.0, 0.68, 0.92) if i < used else Color(0.16, 0.22, 0.28, 0.76)


func _on_equip_item(item_id: String) -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	var result: Dictionary = run_manager.equip_or_toggle(item_id)
	var text := String(result.get("message", ""))
	message_label.text = text
	message_requested.emit(text)
	if bool(result.get("ok", false)):
		inventory_changed.emit()
	_refresh()


func _on_save_loadout_pressed(slot_index: int) -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	var result: Dictionary = run_manager.save_loadout_preset(slot_index, "预设 %d" % (slot_index + 1))
	var text := String(result.get("message", ""))
	message_label.text = text
	message_requested.emit(text)
	if bool(result.get("ok", false)):
		inventory_changed.emit()
	_refresh()


func _on_apply_loadout_pressed(slot_index: int) -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	var result: Dictionary = run_manager.apply_loadout_preset(slot_index)
	var text := String(result.get("message", ""))
	var skipped_count := int(result.get("skipped_count", 0))
	if skipped_count > 0:
		text += " 跳过 %d 件不可装配装备。" % skipped_count
	message_label.text = text
	message_requested.emit(text)
	if bool(result.get("ok", false)):
		inventory_changed.emit()
	_refresh()


func _on_family_filter_pressed(family: String) -> void:
	_active_family_filter = family
	_refresh()


func _on_recommendation_equip_pressed() -> void:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return
	var equipped_names: Array[String] = []
	for item_id in _recommended_auxiliaries:
		if run_manager.equipped_auxiliaries.has(item_id):
			continue
		var result: Dictionary = run_manager.equip_or_toggle(item_id)
		if bool(result.get("ok", false)):
			equipped_names.append(EquipmentCatalogScript.get_display_name(item_id))
	if equipped_names.is_empty():
		message_label.text = "推荐槽位暂时没有可装配的纹章。"
	else:
		message_label.text = "已装配推荐纹章：%s。" % "、".join(equipped_names)
		inventory_changed.emit()
	message_requested.emit(message_label.text)
	_refresh()


func _loadout_summary_text() -> String:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return ""
	var summary: Dictionary = run_manager.get_loadout_summary()
	var text := "%s / 辅助机 %d / 算力 %d/%d / %s" % [
		String(summary.get("weapon_name", "")),
		int(summary.get("aux_count", 0)),
		int(summary.get("used_compute", 0)),
		int(summary.get("capacity", 0)),
		_family_summary_text(summary.get("families", {})),
	]
	if not _active_family_filter.is_empty():
		text += " / 筛选：%s" % EquipmentCatalogScript.get_family_display_name(_active_family_filter)
	return text


func _family_summary_text(families: Dictionary) -> String:
	if families.is_empty():
		return "通用回路"
	var parts: Array[String] = []
	for family in families.keys():
		parts.append("%s x%d" % [_family_display_name(String(family)), int(families[family])])
	return " / ".join(parts)


func _archetype_sync_text() -> String:
	var run_manager := _get_run_manager()
	if run_manager == null:
		return "主导：未定航路 / 同调 0 级 / 通用回路"
	var summary: Dictionary = run_manager.get_loadout_summary()
	var sync := Dictionary(summary.get("archetype_sync", {}))
	var family_name := String(sync.get("dominant_family_name", "未定航路"))
	var sync_text := String(sync.get("sync_text", "同调 0 级"))
	var score_text := String(sync.get("score_text", "通用回路"))
	var effect_text := String(sync.get("effect_text", "同调静默"))
	var resonance_level := int(sync.get("resonance_level", 0))
	if resonance_level > 0:
		var resonance_text := String(sync.get("resonance_text", "家族共鸣"))
		var resonance_effect_text := String(sync.get("resonance_effect_text", "同族纹章成环"))
		return "主导：%s / %s / %s / %s / %s" % [family_name, sync_text, resonance_text, resonance_effect_text, score_text]
	return "主导：%s / %s / %s / %s" % [family_name, sync_text, effect_text, score_text]


func _family_display_name(family: String) -> String:
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return "巨构"
		EquipmentCatalogScript.FAMILY_PARADISE:
			return "天堂"
		EquipmentCatalogScript.FAMILY_WARPED:
			return "星核"
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return "地狱眼"
		EquipmentCatalogScript.FAMILY_DIVINE:
			return "神使"
	return "通用"


func _item_matches_family_filter(item_id: String) -> bool:
	if _active_family_filter.is_empty():
		return true
	var item_type := EquipmentCatalogScript.get_type(item_id)
	if item_type == EquipmentCatalogScript.TYPE_WEAPON:
		return true
	var family := EquipmentCatalogScript.get_family(item_id)
	return family == _active_family_filter or family == EquipmentCatalogScript.FAMILY_GENERAL


func _refresh_build_guidance(run_manager: Node) -> void:
	if not run_manager.has_method("get_build_guidance"):
		build_guidance_title.text = "航向校准：等待航图"
		build_guidance_detail.text = "方舟尚未完成流派测算。"
		build_guidance_node.text = "下一段：未标记航线"
		return
	var guidance: Dictionary = run_manager.call("get_build_guidance", _active_family_filter)
	build_guidance_title.text = String(guidance.get("title", "航向校准：未定航路"))
	build_guidance_detail.text = "%s %s" % [
		String(guidance.get("summary", "")),
		String(guidance.get("sync_goal_text", "")),
	]
	var node_name := String(guidance.get("next_node_name", "未标记航线"))
	var route_title := String(guidance.get("route_plan_title", "等待航图刷新"))
	var route_summary := String(guidance.get("route_plan_summary", ""))
	build_guidance_node.text = "下一段：%s / %s" % [node_name, route_title]
	if not route_summary.is_empty():
		build_guidance_node.text += " / %s" % route_summary


func _refresh_recommendation(run_manager: Node) -> void:
	_recommended_auxiliaries = _build_recommended_auxiliaries(run_manager)
	var family_name := EquipmentCatalogScript.get_family_display_name(_active_family_filter)
	recommendation_title.text = "%s推荐装配" % family_name
	if _recommended_auxiliaries.is_empty():
		recommendation_detail.text = "暂无可放入剩余算力的纹章，先清理槽位或提升方舟算力。"
		recommendation_equip_button.disabled = true
		recommendation_equip_button.text = "待命"
		return
	var names: Array[String] = []
	var planned_compute: int = int(run_manager.get_used_compute())
	for item_id in _recommended_auxiliaries:
		names.append(EquipmentCatalogScript.get_display_name(item_id))
		planned_compute += EquipmentCatalogScript.get_compute_cost(item_id)
	recommendation_detail.text = "%s / 算力 %d/%d" % [
		"、".join(names),
		planned_compute,
		int(run_manager.compute_capacity),
	]
	recommendation_equip_button.disabled = false
	recommendation_equip_button.text = "装入推荐"


func _build_recommended_auxiliaries(run_manager: Node) -> Array[String]:
	var remaining_compute: int = int(run_manager.compute_capacity) - int(run_manager.get_used_compute())
	var candidates: Array[Dictionary] = []
	for item_id in run_manager.equipment_inventory:
		if EquipmentCatalogScript.get_type(item_id) != EquipmentCatalogScript.TYPE_AUX:
			continue
		if run_manager.equipped_auxiliaries.has(item_id):
			continue
		if not _item_matches_family_filter(item_id):
			continue
		var cost := EquipmentCatalogScript.get_compute_cost(item_id)
		if cost > remaining_compute:
			continue
		candidates.append({
			"id": item_id,
			"cost": cost,
			"score": _recommendation_score(item_id, cost),
		})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := int(a.get("score", 0))
		var score_b := int(b.get("score", 0))
		if score_a == score_b:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return score_a > score_b
	)
	var result: Array[String] = []
	var used := 0
	for candidate in candidates:
		var cost := int(candidate.get("cost", 0))
		if used + cost > remaining_compute:
			continue
		result.append(String(candidate.get("id", "")))
		used += cost
		if result.size() >= MAX_RECOMMENDED_AUXILIARIES:
			break
	return result


func _recommendation_score(item_id: String, cost: int) -> int:
	var score := _rarity_score(EquipmentCatalogScript.get_rarity(item_id)) * 100 + cost * 5
	var family := EquipmentCatalogScript.get_family(item_id)
	if not _active_family_filter.is_empty() and family == _active_family_filter:
		score += 1000
	elif family == EquipmentCatalogScript.FAMILY_GENERAL:
		score += 80
	return score


func _rarity_score(rarity: String) -> int:
	match rarity:
		"boss":
			return 5
		"epic":
			return 4
		"rare":
			return 3
	return 2


func _equipped_aux_text() -> String:
	var run_manager := _get_run_manager()
	if run_manager == null or run_manager.equipped_auxiliaries.is_empty():
		return "无"
	var names: Array[String] = []
	for item_id in run_manager.equipped_auxiliaries:
		names.append(EquipmentCatalogScript.get_display_name(item_id))
	return "、".join(names)


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()


func _get_run_manager() -> Node:
	return get_node_or_null("/root/RunManager")
