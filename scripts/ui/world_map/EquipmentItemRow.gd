extends HBoxContainer

signal action_pressed(item_id: String)

var _item_id: String = ""

@onready var name_label: Label = $InfoBox/NameLabel
@onready var meta_label: Label = $InfoBox/MetaLabel
@onready var description_label: Label = $InfoBox/DescriptionLabel
@onready var action_button: Button = $ActionButton


func _ready() -> void:
	action_button.pressed.connect(_on_action_pressed)


func setup(item_id: String, item_name: String, meta_text: String, description: String, action_text: String, disabled: bool, status_text: String = "") -> void:
	_item_id = item_id
	name_label.text = item_name if status_text.is_empty() else "%s  %s" % [item_name, status_text]
	meta_label.text = meta_text
	description_label.text = description
	action_button.text = action_text
	action_button.disabled = disabled


func _on_action_pressed() -> void:
	action_pressed.emit(_item_id)
