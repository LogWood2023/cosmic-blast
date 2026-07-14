extends Control

signal evacuate_pressed

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var evacuate_button: Button = $Panel/EvacuateButton

var _is_closing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	evacuate_button.pressed.connect(_on_evacuate_pressed)


func _on_evacuate_pressed() -> void:
	if _is_closing:
		return
	_is_closing = true
	evacuate_button.disabled = true
	CombatUiMotion.animate_first_panel_exit(self, func() -> void:
		evacuate_pressed.emit()
	)
