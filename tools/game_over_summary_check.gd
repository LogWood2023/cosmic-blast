extends Node


const GAME_OVER_UI_SCENE := preload("res://scenes/ui/game_over/GameOverUI.tscn")
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var drop_id := EquipmentCatalogScript.get_boss_drop_for_family(EquipmentCatalogScript.FAMILY_COLOSSUS, [])
	if drop_id.is_empty():
		_fail("Need a colossus boss drop for game over summary check.")
		return
	RunManager.last_result_summary = {
		"victory": true,
		"score": 9400,
		"crisis_level": 21,
		"compute_capacity": 26,
		"minerals": 340,
		"completed_node_count": 21,
		"equipment_count": 38,
		"cleared_boss_count": 3,
		"last_boss_reward": {
			"family": EquipmentCatalogScript.FAMILY_COLOSSUS,
			"item_id": drop_id,
			"threshold": 21,
		},
	}

	var ui := GAME_OVER_UI_SCENE.instantiate()
	get_tree().root.add_child(ui)
	await get_tree().process_frame

	var final_score_label := ui.get_node_or_null("FinalScoreLabel") as Label
	if final_score_label == null:
		_fail("Game over UI should expose FinalScoreLabel.")
		ui.queue_free()
		return
	var summary_text := final_score_label.text
	ui.queue_free()

	if not summary_text.contains("肃清执行体"):
		_fail("Game over summary should show cleared boss stages. Summary: %s" % summary_text)
		return
	if not summary_text.contains("3/3"):
		_fail("Game over summary should show all 3 crisis stages cleared. Summary: %s" % summary_text)
		return
	var drop_name := EquipmentCatalogScript.get_display_name(drop_id)
	if not summary_text.contains(drop_name):
		_fail("Game over summary should show boss drop name %s. Summary: %s" % [drop_name, summary_text])
		return

	print("Game over summary check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
