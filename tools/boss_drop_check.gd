extends Node

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	RunManager.crisis_level = 5
	RunManager.pending_boss_threshold = 5
	RunManager.pending_boss_scene = "res://scenes/gameplay/boss/BossBattle_Frontier.tscn"
	if not RunManager.handle_boss_victory():
		_fail("Boss victory should create a reward selection.")
		return
	if not RunManager.has_pending_boss_reward():
		_fail("Boss victory should retain a pending reward selection.")
		return
	var summary := RunManager.get_pending_boss_reward_summary()
	var candidates: Array = summary.get("candidate_ids", [])
	if candidates.size() != 3:
		_fail("Boss reward selection should contain three candidates.")
		return
	var first_id := String(candidates[0])
	if not EquipmentCatalogScript.is_boss_drop(first_id) or EquipmentCatalogScript.get_family(first_id) != "colossus":
		_fail("The first candidate should be the current boss family's drop.")
		return
	if RunManager.equipment_inventory.has(first_id):
		_fail("A boss reward must not enter the inventory before selection.")
		return
	var claimed := RunManager.claim_boss_reward(first_id)
	if not bool(claimed.get("ok", false)) or not RunManager.equipment_inventory.has(first_id):
		_fail("Selecting a boss reward should add it to inventory.")
		return
	print("Boss reward selection check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
