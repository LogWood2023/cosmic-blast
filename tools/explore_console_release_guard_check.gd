extends Node

# Regression guard for the explore debug console's engineering tier.
#
# The console popup (Enter to open) and its player-facing map helpers
# (/help, /展示陷阱, /展示刷怪, /清除迷雾) are intentionally always available.
# The hidden engineering/debug tier (/工程席位 unlock + /刷敌, /清测试敌,
# /轮测敌, ...) must only be reachable in debug builds. ExploreRoom gates it
# behind OS.is_debug_build() via _is_engineering_console_available(); this test
# proves the gate blocks shipped release builds while preserving the editor /
# debug-export workflow.

const EXPLORE_ROOM_SCRIPT := preload("res://scripts/gameplay/explore/ExploreRoom.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	if not OS.is_debug_build():
		_fail("This harness must run under a debug build (editor/headless).")
		return
	_check_debug_build_preserves_workflow()
	if _failed:
		return
	_check_release_build_blocks_console()
	if _failed:
		return
	print("Explore console release-guard check passed.")
	get_tree().quit(0)


func _check_debug_build_preserves_workflow() -> void:
	var room := Node2D.new()
	room.set_script(EXPLORE_ROOM_SCRIPT)
	# Engineering commands stay gated until the seat is taken, even in debug.
	var before := String(room.call("_execute_command", "/停轮测"))
	if not before.contains("尚未接管"):
		_fail("Debug build: engineering command should be gated before /工程席位. Got: %s" % before)
		room.free()
		return
	# The unlock command itself works in debug builds.
	var unlock := String(room.call("_execute_command", "/工程席位"))
	if not unlock.contains("已接管"):
		_fail("Debug build: /工程席位 should unlock the console. Got: %s" % unlock)
		room.free()
		return
	# After unlocking, engineering commands run — the debug workflow is preserved.
	var after := String(room.call("_execute_command", "/停轮测"))
	if after.contains("尚未接管") or not after.contains("已停止敌人轮测"):
		_fail("Debug build: engineering command should execute after unlock. Got: %s" % after)
		room.free()
		return
	room.free()


func _check_release_build_blocks_console() -> void:
	# Simulate a shipped release build by overriding the debug-only gate to false.
	var release_script := GDScript.new()
	release_script.source_code = (
		"extends \"res://scripts/gameplay/explore/ExploreRoom.gd\"\n"
		+ "func _is_engineering_console_available() -> bool:\n"
		+ "\treturn false\n"
	)
	if release_script.reload() != OK:
		_fail("Failed to compile the release-build simulation subclass.")
		return
	var room := Node2D.new()
	room.set_script(release_script)
	# Player-facing help still works in release builds.
	var help := String(room.call("_execute_command", "/help"))
	if not help.contains("航图指令"):
		_fail("Release build: /help should still work. Got: %s" % help)
		room.free()
		return
	# The unlock backdoor must be rejected as an unknown command.
	var unlock := String(room.call("_execute_command", "/工程席位"))
	if unlock.contains("已接管") or not unlock.contains("未知指令"):
		_fail("Release build: /工程席位 must not unlock the console. Got: %s" % unlock)
		room.free()
		return
	# Every engineering command stays blocked, even after an unlock attempt.
	for debug_command in ["/停轮测", "/清测试敌", "/刷敌 1 1", "/刷全敌", "/轮测敌"]:
		var response := String(room.call("_execute_command", debug_command))
		if not response.contains("尚未接管"):
			_fail("Release build: %s must stay gated. Got: %s" % [debug_command, response])
			room.free()
			return
	room.free()


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
