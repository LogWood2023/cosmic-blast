extends Node
## Debug-only, scene-independent command console.
##
## The overlay is owned by an autoload so it survives scene transitions. Individual
## gameplay scenes opt in by exposing `_execute_command(command: String) -> String`.

const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")
const CONSOLE_POPUP_SCENE := preload("res://scenes/ui/explore/CommandConsolePopup.tscn")
const MAX_DIALOG_ENTRIES := 8
const MAX_INPUT_HISTORY := 32

var _layer: CanvasLayer
var _console: Control
var _dialog_panel: Panel
var _dialog_label: RichTextLabel
var _input_panel: Panel
var _input_edit: LineEdit
var _dialog_tween: Tween
var _dialog_history: Array[String] = []
var _input_history: Array[String] = []
var _history_index := -1
var _is_open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.command_console_open = false
	if not _is_console_available():
		set_process_unhandled_key_input(false)
		return
	_setup_overlay()


func _exit_tree() -> void:
	GameManager.command_console_open = false


func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_console_available() or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _is_open:
		if event.keycode == KEY_ESCAPE:
			_close_console(true)
			get_viewport().set_input_as_handled()
		return
	if event.keycode in [KEY_F2, KEY_QUOTELEFT]:
		_open_console()
		get_viewport().set_input_as_handled()


func _is_console_available() -> bool:
	# Editor runs and debug exports return true; release exports return false.
	return OS.is_debug_build()


func _setup_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "DebugCommandConsoleLayer"
	_layer.layer = 100
	add_child(_layer)

	_console = CONSOLE_POPUP_SCENE.instantiate() as Control
	_layer.add_child(_console)
	_dialog_panel = _console.call("get_dialog_panel") as Panel
	_dialog_label = _console.call("get_dialog_label") as RichTextLabel
	_input_panel = _console.call("get_input_panel") as Panel
	_input_edit = _console.call("get_input_edit") as LineEdit
	_input_edit.text_submitted.connect(_submit_command)
	_input_edit.gui_input.connect(_on_input_gui_input)
	_input_panel.visible = false
	_dialog_panel.visible = false


func _open_console() -> void:
	if not is_instance_valid(_input_edit):
		return
	if _dialog_tween and _dialog_tween.is_running():
		_dialog_tween.kill()
	_is_open = true
	GameManager.command_console_open = true
	_input_panel.visible = true
	CombatUiMotion.animate_panel_enter(_input_panel)
	_dialog_panel.visible = true
	CombatUiMotion.animate_panel_enter(_dialog_panel)
	_refresh_dialog()
	_history_index = _input_history.size()
	_input_edit.clear()
	_input_edit.grab_focus()


func _submit_command(text: String) -> void:
	var command := text.strip_edges()
	if command.is_empty():
		_close_console(true)
		return
	_remember_command(command)
	var response := _execute_command(command)
	_close_console()
	_append_dialog(command, response)


func _execute_command(command: String) -> String:
	if not command.begins_with("/"):
		return "请输入以 / 开头的指令，输入 /help 查看可用指令。"
	var parts := command.split(" ", false)
	var verb := String(parts[0]) if not parts.is_empty() else ""
	var active_scene := get_tree().current_scene
	if command == "/help":
		var lines: Array[String] = [
			"调试控制台（仅 Debug 构建可用）",
			"快捷键：F2 或 ` 打开；Enter 提交；Esc 关闭；↑/↓ 调取历史指令。",
			"/加危机 [数量]（或 /危机+ [数量]）：提升正式航程的危机等级，首领阈值会自动停下。",
		]
		if is_instance_valid(active_scene) and active_scene.has_method("_execute_command"):
			lines.append("")
			lines.append(String(active_scene.call("_execute_command", command)))
		else:
			lines.append("当前界面没有专属调试指令。")
		return "\n".join(lines)
	if verb == "/加危机" or verb == "/危机+":
		return _execute_add_crisis_command(parts, active_scene)
	if is_instance_valid(active_scene) and active_scene.has_method("_execute_command"):
		return String(active_scene.call("_execute_command", command))
	return "当前界面不支持指令 %s。输入 /help 查看控制台说明。" % command


func _execute_add_crisis_command(parts: PackedStringArray, active_scene: Node) -> String:
	if parts.size() > 2 or (parts.size() == 2 and not parts[1].is_valid_int()):
		return "用法：/加危机 [数量]，数量为 1-99。"
	var amount := 1 if parts.size() == 1 else clampi(int(parts[1]), 1, 99)
	var result: Dictionary = RunManager.debug_add_crisis(amount)
	if bool(result.get("ok", false)) and is_instance_valid(active_scene) and active_scene.has_method("_refresh_all"):
		active_scene.call_deferred("_refresh_all")
	return String(result.get("message", "危机等级操作失败。"))


func show_response(command: String, response: String) -> void:
	if _is_console_available() and is_instance_valid(_dialog_panel):
		_append_dialog(command, response)


func _on_input_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_UP:
		_select_history(-1)
		_input_edit.accept_event()
	elif event.keycode == KEY_DOWN:
		_select_history(1)
		_input_edit.accept_event()


func _select_history(direction: int) -> void:
	if _input_history.is_empty():
		return
	_history_index = clampi(_history_index + direction, 0, _input_history.size())
	if _history_index == _input_history.size():
		_input_edit.clear()
	else:
		_input_edit.text = _input_history[_history_index]
		_input_edit.caret_column = _input_edit.text.length()


func _remember_command(command: String) -> void:
	_input_history.erase(command)
	_input_history.append(command)
	while _input_history.size() > MAX_INPUT_HISTORY:
		_input_history.pop_front()
	_history_index = _input_history.size()


func _append_dialog(command: String, response: String) -> void:
	if _dialog_tween and _dialog_tween.is_running():
		_dialog_tween.kill()
	_dialog_panel.visible = true
	CombatUiMotion.animate_panel_enter(_dialog_panel)
	_dialog_history.append("> %s\n%s" % [command, response])
	while _dialog_history.size() > MAX_DIALOG_ENTRIES:
		_dialog_history.pop_front()
	_refresh_dialog()
	_dialog_tween = create_tween()
	_dialog_tween.tween_interval(2.0)
	_dialog_tween.tween_callback(func() -> void:
		CombatUiMotion.animate_panel_exit(_dialog_panel, func() -> void:
			_dialog_panel.visible = false
		)
	)


func _refresh_dialog() -> void:
	_dialog_label.text = "\n\n".join(_dialog_history)
	_dialog_label.call_deferred("scroll_to_line", max(0, _dialog_label.get_line_count() - 1))


func _close_console(hide_dialog: bool = false) -> void:
	_is_open = false
	GameManager.command_console_open = false
	_input_edit.release_focus()
	_input_edit.clear()
	CombatUiMotion.animate_panel_exit(_input_panel, func() -> void:
		_input_panel.visible = false
	)
	if hide_dialog:
		if _dialog_tween and _dialog_tween.is_running():
			_dialog_tween.kill()
		CombatUiMotion.animate_panel_exit(_dialog_panel, func() -> void:
			_dialog_panel.visible = false
		)
