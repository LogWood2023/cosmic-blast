extends Node

const DEBUG_CONSOLE_SCRIPT := preload("res://scripts/core/DebugCommandConsole.gd")

var _failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_debug_build_creates_global_overlay()
	if not _failed:
		_check_release_build_skips_overlay()
	if not _failed:
		_check_debug_crisis_increment_stops_at_alert()
	if not _failed:
		print("Debug command console check passed.")
		get_tree().quit(0)


func _check_debug_build_creates_global_overlay() -> void:
	var console := Node.new()
	console.set_script(DEBUG_CONSOLE_SCRIPT)
	add_child(console)
	if not console.has_node("DebugCommandConsoleLayer"):
		_fail("Debug build should create the console overlay.")
		return
	var help_text := String(console.call("_execute_command", "/help"))
	if not help_text.contains("F2") or not help_text.contains("仅 Debug 构建可用") or not help_text.contains("/加危机"):
		_fail("Debug console help should describe its debug-only shortcut. Got: %s" % help_text)
		return
	console.queue_free()


func _check_release_build_skips_overlay() -> void:
	var release_script := GDScript.new()
	release_script.source_code = (
		"extends \"res://scripts/core/DebugCommandConsole.gd\"\n"
		+ "func _is_console_available() -> bool:\n"
		+ "\treturn false\n"
	)
	if release_script.reload() != OK:
		_fail("Failed to compile the release-build simulation subclass.")
		return
	var console := Node.new()
	console.set_script(release_script)
	add_child(console)
	if console.has_node("DebugCommandConsoleLayer"):
		_fail("Release build must not create a console overlay.")
		return
	console.queue_free()


func _check_debug_crisis_increment_stops_at_alert() -> void:
	var run_manager_script := GDScript.new()
	run_manager_script.source_code = (
		"extends \"res://scripts/core/RunManager.gd\"\n"
		+ "func save_run() -> void:\n"
		+ "\tpass\n"
	)
	if run_manager_script.reload() != OK:
		_fail("Failed to compile the debug crisis test subclass.")
		return
	var run_manager := Node.new()
	run_manager.set_script(run_manager_script)
	add_child(run_manager)
	run_manager.set("run_active", true)
	run_manager.set("run_finished", false)
	run_manager.set("crisis_level", 0)
	var result: Dictionary = run_manager.call("debug_add_crisis", 9)
	if not bool(result.get("ok", false)) or int(result.get("added", 0)) != 5 or int(run_manager.get("crisis_level")) != 5:
		_fail("Debug crisis command should stop at the first alert threshold. Got: %s" % result)
		return
	run_manager.queue_free()


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
