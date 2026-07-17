extends Node

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _service := RewardService.new()
var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_pool_catalog()
	_check_regular_drafts()
	_check_protection()
	_check_boss_draft()
	if not _failed:
		print("Reward service check passed.")
		get_tree().quit(0)


func _check_pool_catalog() -> void:
	_assert(_service.get_pools().size() == 8, "Eight launch reward pools must load.")
	for pool in _service.get_pools():
		_assert(not pool.pool_id.is_empty() and not pool.reward_types.is_empty(), "Reward pool needs an id and types.")


func _check_regular_drafts() -> void:
	for seed in range(100):
		var choices := _service.prepare_choices(1, _context(), seed)
		_assert(choices.size() == 3, "Regular reward must show exactly three cards.")
		var item_ids := {}
		for choice in choices:
			_assert(not String(choice.get("title", "")).is_empty(), "Reward card must not be empty.")
			var item_id := String(choice.get("item_id", ""))
			if not item_id.is_empty():
				_assert(not item_ids.has(item_id), "A draft may not repeat equipment.")
				item_ids[item_id] = true


func _check_protection() -> void:
	var equipment_pity := _context({"nodes_without_equipment": 3})
	var choices := _service.prepare_choices(1, equipment_pity, 11)
	_assert(String(choices[0].get("reward_type", "")) == "equipment", "Three empty nodes must force one equipment card.")
	var starter_pity := _context({"drafts_without_starter": 4})
	choices = _service.prepare_choices(1, starter_pity, 12)
	_assert(String(choices[0].get("role_tag", "")) == "starter", "Four drafts without a starter must force one starter.")
	var amplifier_pity := _context({"drafts_without_amplifier": 4})
	choices = _service.prepare_choices(1, amplifier_pity, 13)
	_assert(String(choices[0].get("role_tag", "")) == "amplifier", "Four drafts without an amplifier must force one amplifier.")
	var mutation := _service.resolve_choice(1, String(choices[0].get("choice_id", "")), amplifier_pity)
	_assert(mutation != null, "A reward choice must resolve to a mutation.")
	_assert(int(Dictionary(mutation.metadata.get("reward_protection", {})).get("drafts_without_amplifier", -1)) == 0, "Consumed amplifier pity must reset once.")


func _check_boss_draft() -> void:
	var choices := _service.prepare_boss_choices(2, _context(), "colossus", 91)
	_assert(choices.size() == 4, "Boss reward must show four choices.")
	_assert(String(choices[0].get("reward_type", "")) == "equipment", "First boss card must be equipment.")
	_assert(EquipmentCatalogScript.is_boss_drop(String(choices[0].get("item_id", ""))), "First boss card must be a Boss-family item.")
	_assert(String(choices[3].get("reward_type", "")) == "maintenance", "Fourth boss card must be a maintenance pack.")
	var mutation := _service.resolve_choice(2, String(choices[3].get("choice_id", "")), _context())
	_assert(mutation != null and mutation.actions.size() == 3, "Maintenance pack must return an atomic three-action mutation.")


func _context(protection: Dictionary = {}) -> RunContentContext:
	return RunContentContext.from_snapshot({
		"state_version": 1,
		"crisis_level": 0,
		"compute_capacity": 99,
		"player_hp": 80,
		"equipment_inventory": ["pulse_cannon"],
		"active_rules": {"family_tags": ["colossus", "paradise"], "reward_protection": protection},
	})


func _assert(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
