extends Control

signal closed

@onready var title_label: Label = $Panel/TitleLabel
@onready var body_label: RichTextLabel = $Panel/BodyLabel
@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)


func setup(result: Dictionary) -> void:
	var run_manager := _get_run_manager()
	var ok := bool(result.get("ok", false))
	title_label.text = "事件结算" if ok else "事件中断"
	var lines: Array[String] = [String(result.get("message", ""))]
	if ok and run_manager != null:
		lines.append("")
		lines.append("[b]节点已探索[/b]")
		lines.append("危机等级：%d" % int(run_manager.crisis_level))
		lines.append("算力容量：%d" % int(run_manager.compute_capacity))
		lines.append("星髓矿：%d" % int(run_manager.minerals))
	body_label.text = "\n".join(lines)


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()


func _get_run_manager() -> Node:
	return get_node_or_null("/root/RunManager")
