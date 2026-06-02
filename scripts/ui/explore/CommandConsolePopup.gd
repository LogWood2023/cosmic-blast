extends Control

@onready var dialog_panel: ColorRect = $CommandDialogPanel
@onready var dialog_label: RichTextLabel = $CommandDialogPanel/CommandDialogLabel
@onready var input_panel: ColorRect = $CommandInputPanel
@onready var input_edit: LineEdit = $CommandInputPanel/CommandInputEdit


func get_dialog_panel() -> ColorRect:
	return dialog_panel


func get_dialog_label() -> RichTextLabel:
	return dialog_label


func get_input_panel() -> ColorRect:
	return input_panel


func get_input_edit() -> LineEdit:
	return input_edit
