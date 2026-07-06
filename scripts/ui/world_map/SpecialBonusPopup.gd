extends Control

signal closed

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var title_label: Label = $Panel/TitleLabel
@onready var body_label: RichTextLabel = $Panel/BodyLabel
@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	close_button.pressed.connect(_on_close_pressed)


func setup(summary: Dictionary) -> void:
	title_label.text = "信标接入"
	var lines: Array[String] = []
	var activated_names: Array[String] = _to_string_array(summary.get("activated_names", []))
	if activated_names.is_empty():
		lines.append("[b]方舟信标协议已并入航路。[/b]")
	else:
		lines.append("[b]%s已并入航路。[/b]" % "、".join(activated_names))
	var echo_routes: Array = summary.get("beacon_echo_routes", [])
	if not echo_routes.is_empty():
		lines.append("")
		lines.append("[b]回响航线：[/b]")
		for raw_route in echo_routes:
			var route := Dictionary(raw_route)
			var node_name := String(route.get("node_name", "")).strip_edges()
			if node_name.is_empty():
				continue
			var family_name := String(route.get("family_name", "")).strip_edges()
			var route_effects: Array[String] = []
			if not family_name.is_empty():
				route_effects.append(family_name)
			var equipment_bonus := float(route.get("equipment_bonus", 0.0))
			if equipment_bonus > 0.0:
				route_effects.append("装备检出 +%d%%" % int(round(equipment_bonus * 100.0)))
			var reward_bonus := float(route.get("reward_bonus", 0.0))
			if reward_bonus > 0.0:
				route_effects.append("矿物倍率 +%.2f" % reward_bonus)
			if route_effects.is_empty():
				lines.append("• %s" % node_name)
			else:
				lines.append("• %s：%s" % [node_name, " / ".join(route_effects)])
	lines.append("")
	lines.append("方舟核心会在后续探索中沿这些航线强化纹章检出与资源回收。")
	body_label.text = "\n".join(lines)


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			var text := String(item).strip_edges()
			if not text.is_empty():
				result.append(text)
	return result


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
