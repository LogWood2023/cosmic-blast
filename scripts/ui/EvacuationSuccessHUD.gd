extends Control

signal evacuate_pressed

@onready var evacuate_button: Button = $Panel/EvacuateButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	evacuate_button.pressed.connect(_on_evacuate_pressed)


func _on_evacuate_pressed() -> void:
	evacuate_pressed.emit()
