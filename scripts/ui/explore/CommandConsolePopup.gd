extends Control

@onready var dialog_panel: Panel = $CommandDialogPanel
@onready var dialog_label: RichTextLabel = $CommandDialogPanel/CommandDialogLabel
@onready var input_panel: Panel = $CommandInputPanel
@onready var input_edit: LineEdit = $CommandInputPanel/CommandInputEdit


func get_dialog_panel() -> Panel:
	return dialog_panel


func get_dialog_label() -> RichTextLabel:
	return dialog_label


func get_input_panel() -> Panel:
	return input_panel


func get_input_edit() -> LineEdit:
	return input_edit
