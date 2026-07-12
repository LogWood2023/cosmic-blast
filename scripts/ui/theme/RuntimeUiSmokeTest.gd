extends Node

const UI_SCENES := [
	"res://scenes/ui/main_menu/MainMenuGeneratedUI.tscn",
	"res://scenes/ui/main_menu/SettingsPopup.tscn",
	"res://scenes/ui/boss_select/BossSelectUI.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/ui/player_status/PlayerStatusHUD.tscn",
	"res://scenes/ui/BossHUD.tscn",
	"res://scenes/ui/world_map/WorldMapUI.tscn",
	"res://scenes/ui/world_map/ShopPopup.tscn",
	"res://scenes/ui/world_map/HangarPopup.tscn",
	"res://scenes/ui/world_map/EquipmentItemRow.tscn",
	"res://scenes/ui/explore/ExploreMapUI.tscn",
	"res://scenes/ui/explore/CompassMiniMap.tscn",
	"res://scenes/ui/explore/CommandConsolePopup.tscn",
	"res://scenes/ui/explore_loading/ExploreLoadingScreen.tscn",
	"res://scenes/ui/game_over/GameOverUI.tscn",
	"res://scenes/ui/EvacuationSuccessHUD.tscn",
]

var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	for scene_path in UI_SCENES:
		_check_scene(scene_path)
	if _failures.is_empty():
		print("Runtime UI smoke test passed")
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		get_tree().quit(1)


func _check_scene(scene_path: String) -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_failures.append("Runtime smoke could not load: %s" % scene_path)
		return
	var instance := packed.instantiate()
	if instance == null:
		_failures.append("Runtime smoke could not instantiate: %s" % scene_path)
		return
	add_child(instance)
	_setup_dynamic_row(instance)
	await_frame_flush()
	_scan_buttons(scene_path, instance)
	_scan_required_nodes(scene_path, instance)
	instance.queue_free()


func await_frame_flush() -> void:
	pass


func _setup_dynamic_row(instance: Node) -> void:
	if instance.has_method("setup") and instance.name == "EquipmentItemRow":
		instance.call("setup", "aux_test", "巡航纹章", "辅助机 / 算力 2", "运行校验条目", "装配", false, "")


func _scan_buttons(scene_path: String, node: Node) -> void:
	if node is Button:
		var button := node as Button
		var size := button.custom_minimum_size
		if size == Vector2.ZERO:
			size = button.size
		if size.x < 130.0 or size.y < 40.0:
			_failures.append("Runtime button too small in %s: %s %s" % [scene_path, button.name, size])
		if button.disabled and button.name not in ["StartButton"]:
			pass
	for child in node.get_children():
		_scan_buttons(scene_path, child)


func _scan_required_nodes(scene_path: String, instance: Node) -> void:
	if scene_path.ends_with("EquipmentItemRow.tscn"):
		_require_node(scene_path, instance, "InfoPanel/Margin/Inner/CrestSlot/IconTexture")
		_require_node(scene_path, instance, "InfoPanel/Margin/Inner/InfoBox/CategoryLabel")
		_require_node(scene_path, instance, "InfoPanel/Margin/Inner/InfoBox/EffectLabel")
		_require_node(scene_path, instance, "InfoPanel/Margin/Inner/InfoBox/FlavorLabel")
		_require_node(scene_path, instance, "InfoPanel/CardButton")
		_require_node(scene_path, instance, "ActionButton")
	if scene_path.ends_with("HangarPopup.tscn"):
		_require_node(scene_path, instance, "Panel/CharmBay/CharmSlots")
		_require_node(scene_path, instance, "Panel/ItemsScroll/ItemsList")
		_require_node(scene_path, instance, "Panel/CloseButton")


func _require_node(scene_path: String, instance: Node, path: NodePath) -> void:
	if instance.get_node_or_null(path) == null:
		_failures.append("Runtime missing node in %s: %s" % [scene_path, path])
