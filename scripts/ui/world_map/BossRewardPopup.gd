extends Control

signal closed
signal reward_selected(item_id: String)

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var title_label: Label = $Panel/TitleLabel
@onready var body_label: RichTextLabel = $Panel/BodyLabel
@onready var reward_rows: Array = [$Panel/RewardRows/CandidateRow1, $Panel/RewardRows/CandidateRow2, $Panel/RewardRows/CandidateRow3]

var _is_closing := false


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	for reward_row in reward_rows:
		reward_row.action_pressed.connect(_on_reward_row_pressed)


func setup(summary: Dictionary) -> void:
	var family_name := String(summary.get("family_name", "")).strip_edges()
	var stage := int(summary.get("stage", 0))
	title_label.text = "选择执行体缴获"
	var lines: Array[String] = []
	if family_name.is_empty():
		lines.append("[color=#ffd9a0]危机残响已封存。[/color]")
	else:
		lines.append("[color=#ffd9a0]%s残响已封存。[/color]" % family_name)
	if stage > 0:
		lines.append("肃清记录：第 %d 阶危机。"% stage)
	lines.append("")
	lines.append("从三项未入库装备中选择一项。确认后将立即写入机库。")
	var aftershock_text := String(summary.get("boss_aftershock_text", "")).strip_edges()
	if not aftershock_text.is_empty():
		lines.append(aftershock_text)
	var shop_focus_text := String(summary.get("shop_focus_text", "")).strip_edges()
	if not shop_focus_text.is_empty():
		lines.append("%s已接入方舟货单。" % shop_focus_text)
	if bool(summary.get("is_final", false)):
		lines.append("这是最终缴获。完成选择后将进入本次远征结算。")
	else:
		lines.append("选择完成后可继续在航图推进。")
	body_label.text = "\n".join(lines)
	_refresh_reward_rows(Array(summary.get("candidate_ids", [])))


func _refresh_reward_rows(candidate_ids: Array) -> void:
	for index in range(reward_rows.size()):
		var reward_row = reward_rows[index]
		var item_id := String(candidate_ids[index]) if index < candidate_ids.size() else ""
		if item_id.is_empty() or not EquipmentCatalogScript.has_item(item_id):
			reward_row.visible = false
			continue
		reward_row.visible = true
		var item := EquipmentCatalogScript.get_item(item_id)
		reward_row.setup(
			item_id,
			String(item.get("name", item_id)),
			EquipmentCatalogScript.get_ui_meta_text(item_id, false, 0),
			String(item.get("description", "")),
			"选择此装备",
			false
		)


func _on_reward_row_pressed(item_id: String) -> void:
	reward_selected.emit(item_id)


func finish_selection() -> void:
	if _is_closing:
		return
	_is_closing = true
	CombatUiMotion.animate_first_panel_exit(self, func() -> void:
		closed.emit()
		queue_free()
	)
