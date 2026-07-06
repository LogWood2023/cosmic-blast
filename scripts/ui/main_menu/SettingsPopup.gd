extends Control

signal closed

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

@onready var close_button: Button = $Panel/CloseButton


func _ready() -> void:
	CombatUiMotion.bind_tree(self)
	CombatUiMotion.animate_first_panel_enter(self)
	close_button.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
