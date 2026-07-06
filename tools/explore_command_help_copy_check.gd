extends Node


const EXPLORE_ROOM_SCRIPT := preload("res://scripts/gameplay/explore/ExploreRoom.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var room := Node2D.new()
	room.set_script(EXPLORE_ROOM_SCRIPT)

	var help_text := String(room.call("_execute_command", "/help"))
	for expected in ["/展示陷阱", "/展示刷怪", "/清除迷雾", "航图指令"]:
		if not help_text.contains(expected):
			_fail("Explore command help should keep player-facing command %s. Help: %s" % [expected, help_text])
			return
	for forbidden in [
		"测试",
		"临时",
		"卡顿",
		"colossus",
		"paradise",
		"warped",
		"hell_eye",
		"divine",
		"/刷敌",
		"/刷校准者",
		"/刷小怪家族",
		"/刷全敌",
		"/轮测敌",
	]:
		if help_text.contains(forbidden):
			_fail("Explore command help should hide debug/internal copy '%s'. Help: %s" % [forbidden, help_text])
			return

	var spawn_response := String(room.call("_execute_command", "/刷敌 1 1"))
	if not spawn_response.contains("工程席位"):
		_fail("Hidden debug spawn commands should answer with in-world gated copy. Response: %s" % spawn_response)
		return
	if spawn_response.contains("测试") or spawn_response.contains("临时"):
		_fail("Hidden debug spawn command response should avoid design-note copy. Response: %s" % spawn_response)
		return

	room.free()

	print("Explore command help copy check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
