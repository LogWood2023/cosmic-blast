extends Node

const EXPECTED_IDS: PackedStringArray = [
	"old_supply_chain", "ark_medical_relay", "lost_cartographer", "sealed_weapon_cache",
	"overdrawn_core", "volatile_incubator", "salvage_contract", "marked_bounty",
	"procurement_future", "scrap_exchange", "role_inverter", "bridge_forge",
	"colossus_impact_route", "paradise_barrage_route", "warped_tide_route",
	"hell_eye_redline_route", "divine_seraph_route", "gravity_shrapnel_treaty",
	"seraph_furnace_treaty", "rammed_magazine_treaty", "quiet_channel", "family_aftershock",
	"quantum_crate", "ore_pledge",
]

var _service := EventService.new()
var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_catalog()
	_check_candidate_rules()
	_check_choice_and_mutation_rules()
	if not _failed:
		print("Event service check passed.")
		get_tree().quit(0)


func _check_catalog() -> void:
	var definitions := _service.get_definitions()
	_assert(definitions.size() == EXPECTED_IDS.size(), "Expected 24 event resources.")
	for event_id in EXPECTED_IDS:
		var definition := _service.get_definition(event_id)
		_assert(definition != null, "Missing event resource %s." % event_id)
		if definition == null:
			continue
		_assert(definition.options.size() >= 2, "%s must have at least two options." % event_id)
		for option in definition.options:
			_assert(not option.preview_text.is_empty(), "%s option needs preview text." % event_id)
	_assert(_service.get_definition("procurement_discount").event_id == "procurement_future", "Legacy ID migration should resolve procurement_discount.")


func _check_candidate_rules() -> void:
	var no_family_context := _context({"family_tags": []})
	var candidates := _service.get_candidate_definitions(no_family_context, no_family_context.get_node(1))
	_assert(not _contains(candidates, "gravity_shrapnel_treaty"), "Cross-family event must not enter an invalid pool.")
	var family_context := _context({"family_tags": ["paradise", "warped"]})
	candidates = _service.get_candidate_definitions(family_context, family_context.get_node(1))
	_assert(_contains(candidates, "gravity_shrapnel_treaty"), "Valid cross-family tags should enable the treaty.")
	for seed in range(1000):
		var choices := _service.prepare_choices(1, _context({"completed_node_count": 2}), seed)
		var seen := {}
		var safe_present := false
		for choice in choices:
			var event_id := String(choice.get("event_id", ""))
			if event_id.is_empty():
				continue
			seen[event_id] = true
			if String(choice.get("category", "")) == "safe":
				safe_present = true
		_assert(seen.size() <= 3, "One roll must not contain duplicate unique events.")
		_assert(safe_present, "Early rolls must include a safe candidate.")
	var recent_context := _context({"recent_event_families": ["colossus", "colossus"]})
	for choice in _service.prepare_choices(1, recent_context, 99):
		_assert(String(choice.get("event_id", "")) != "colossus_impact_route", "A third same-family route must be filtered.")


func _check_choice_and_mutation_rules() -> void:
	var poor_context := _context({"minerals": 0})
	var procurement := _service.get_definition("procurement_future")
	var procurement_view := EventResolver.new().make_choice_views(procurement, poor_context)[0]
	_assert(not String(procurement_view.get("disabled_reason", "")).is_empty(), "Unaffordable choice should be disabled.")
	var leave := _service.resolve_choice(1, "old_supply_chain:leave", _context())
	_assert(leave != null and leave.actions.size() == 1, "Leaving should create a harmless mutation.")
	var contract_context := _context()
	var contract := _service.resolve_choice(1, "salvage_contract:sign", contract_context)
	_assert(contract != null and contract.actions.size() == 1, "Contract choice should resolve to one declarative action.")
	var snapshot := EventResolver.new().get_contract_snapshot(_service.get_definition("salvage_contract"), "sign", contract_context)
	_assert(int(snapshot.get("remaining_nodes", 0)) == 2, "Contract duration should remain visible in the snapshot.")
	var visited_context := _context({}, true)
	_assert(_service.prepare_choices(1, visited_context, 1).is_empty(), "Visited nodes must not receive event choices.")


func _context(extra_rules: Dictionary = {}, completed: bool = false) -> RunContentContext:
	var rules := {"seen_event_ids": [], "recent_event_families": [], "family_tags": []}
	for key in extra_rules:
		rules[key] = extra_rules[key]
	return RunContentContext.from_snapshot({
		"state_version": 1,
		"current_node_id": 1,
		"map_nodes": [{"id": 1, "type": "event", "completed": completed}],
		"crisis_level": 0,
		"completed_node_count": int(extra_rules.get("completed_node_count", 0)),
		"minerals": int(extra_rules.get("minerals", 120)),
		"player_hp": 100,
		"equipment_inventory": ["pulse_cannon"],
		"active_rules": rules,
	})


func _contains(definitions: Array[EventDefinition], event_id: String) -> bool:
	for definition in definitions:
		if definition.event_id == event_id:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
