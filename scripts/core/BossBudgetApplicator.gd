class_name BossBudgetApplicator
extends RefCounted
## Applies the formal-run boss budget once, leaving Boss Select/sandbox scenes untouched.

const FAMILY_KEYS := {
	"colossus": "星间巨构",
	"paradise": "天堂号",
	"warped": "扭曲星核",
	"hell_eye": "地狱之眼",
	"divine": "神明使者",
}


static func apply_to(controller: Node, family_id: String) -> Dictionary:
	if not RunManager.is_formal_run_active():
		return {}
	var budget := RunManager.get_formal_boss_budget(String(FAMILY_KEYS.get(family_id, family_id)))
	if budget.is_empty():
		return {}
	controller.set("max_hp", int(budget.get("ehp", controller.get("max_hp"))))
	if _has_property(controller, &"skill_cooldown"):
		controller.set("skill_cooldown", float(controller.get("skill_cooldown")) * float(budget.get("cooldown_mult", 1.0)))
	controller.set_meta(&"formal_boss_budget", budget.duplicate(true))
	controller.set_meta(&"formal_boss_enrage_applied", false)
	return budget


static func apply_damage_phase_modifier(controller: Node, current_hp: int) -> bool:
	if not controller.has_meta(&"formal_boss_budget"):
		return false
	if bool(controller.get_meta(&"formal_boss_enrage_applied", false)):
		return false
	if not _has_property(controller, &"max_hp") or int(controller.get("max_hp")) <= 0:
		return false
	var budget := Dictionary(controller.get_meta(&"formal_boss_budget", {}))
	if int(budget.get("phase_enrage_count", 0)) <= 0:
		return false
	var threshold := float(budget.get("phase_enrage_threshold", 0.0))
	if threshold <= 0.0 or float(current_hp) / float(controller.get("max_hp")) > threshold:
		return false
	# Crisis 5 adds one decisive phase: crossing 60% HP shortens future skill cycles by 15%.
	if _has_property(controller, &"skill_cooldown"):
		controller.set("skill_cooldown", float(controller.get("skill_cooldown")) * 0.85)
	controller.set_meta(&"formal_boss_enrage_applied", true)
	controller.set_meta(&"formal_boss_enrage_hp", current_hp)
	return true


static func _has_property(controller: Object, property_name: StringName) -> bool:
	for property_info in controller.get_property_list():
		if StringName(property_info.get("name", "")) == property_name:
			return true
	return false
