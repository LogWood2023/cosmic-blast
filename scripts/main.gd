extends Node2D
## 主游戏场景控制器
## 测试缩放功能：按 F1 切换 1/3 缩放（正式版移除）


func _ready() -> void:
	if GameManager.test_scale_enabled:
		scale = Vector2(GameManager.test_scale_factor, GameManager.test_scale_factor)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_toggle_test_scale()


func _toggle_test_scale() -> void:
	GameManager.test_scale_enabled = not GameManager.test_scale_enabled
	if GameManager.test_scale_enabled:
		scale = Vector2(GameManager.test_scale_factor, GameManager.test_scale_factor)
	else:
		scale = Vector2.ONE
	var status = "ON" if GameManager.test_scale_enabled else "OFF"
	print("[Main] Test scale %s (factor=%.2f)" % [status, GameManager.test_scale_factor])
