extends Control

signal closed

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var title_label: Label = $Panel/TitleLabel
@onready var body_label: RichTextLabel = $Panel/BodyLabel
@onready var reward_row = $Panel/RewardRow
@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	close_button.pressed.connect(_on_close_pressed)


func setup(summary: Dictionary) -> void:
	var family_name := String(summary.get("family_name", "")).strip_edges()
	var item_name := String(summary.get("item_name", "")).strip_edges()
	var item_id := String(summary.get("item_id", "")).strip_edges()
	var stage := int(summary.get("stage", 0))
	title_label.text = "执行体肃清"
	var lines: Array[String] = []
	if family_name.is_empty():
		lines.append("[color=#ffd9a0]危机残响已封存。[/color]")
	else:
		lines.append("[color=#ffd9a0]%s残响已封存。[/color]" % family_name)
	if stage > 0:
		lines.append("肃清记录：第 %d 阶危机。"% stage)
	lines.append("")
	if item_name.is_empty():
		lines.append("缴获纹章：无可用遗物信号。")
	else:
		lines.append("缴获纹章：%s。" % item_name)
	var aftershock_text := String(summary.get("boss_aftershock_text", "")).strip_edges()
	if not aftershock_text.is_empty():
		lines.append(aftershock_text)
	var shop_focus_text := String(summary.get("shop_focus_text", "")).strip_edges()
	if not shop_focus_text.is_empty():
		lines.append("%s已接入方舟货单。" % shop_focus_text)
	lines.append("方舟核心已完成封存，机库可立即装配。")
	body_label.text = "\n".join(lines)
	_refresh_reward_row(item_id, item_name)


func _refresh_reward_row(item_id: String, fallback_name: String) -> void:
	if item_id.is_empty() or not EquipmentCatalogScript.has_item(item_id):
		reward_row.visible = false
		return
	reward_row.visible = true
	var item := EquipmentCatalogScript.get_item(item_id)
	reward_row.setup(
		item_id,
		String(item.get("name", fallback_name)),
		EquipmentCatalogScript.get_ui_meta_text(item_id, false, 0),
		String(item.get("description", "")),
		"已入库",
		true,
		"[已入库]"
	)


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
