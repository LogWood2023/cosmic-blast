extends Node2D

@onready var fill_bar: ColorRect = $FillBar
@onready var label: Label = $Label

var _full_width: float = 0.0


func _ready() -> void:
	_full_width = fill_bar.size.x
	_update_bar()


func _process(_delta: float) -> void:
	_update_bar()


func _update_bar() -> void:
	var ratio := GameManager.get_frenzy_ratio()
	fill_bar.size.x = _full_width * ratio
	label.text = "狂热" if not GameManager.frenzy_active else "狂热 %.1fs" % GameManager.frenzy_timer
	fill_bar.color = Color(1.0, 0.25, 0.08, 1.0) if GameManager.frenzy_active else Color(0.9, 0.35, 1.0, 1.0)
