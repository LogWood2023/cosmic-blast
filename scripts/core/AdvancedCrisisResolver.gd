class_name AdvancedCrisisResolver
extends RefCounted
## Resolves cumulative, copy-on-read crisis domains. Consumers never mutate Resources.

const DATA_PATHS: PackedStringArray = [
	"res://data/advanced_crisis/crisis_01.tres", "res://data/advanced_crisis/crisis_02.tres",
	"res://data/advanced_crisis/crisis_03.tres", "res://data/advanced_crisis/crisis_04.tres",
	"res://data/advanced_crisis/crisis_05.tres", "res://data/advanced_crisis/crisis_06.tres",
	"res://data/advanced_crisis/crisis_07.tres", "res://data/advanced_crisis/crisis_08.tres",
	"res://data/advanced_crisis/crisis_09.tres", "res://data/advanced_crisis/crisis_10.tres",
]


func resolve(level: int) -> Dictionary:
	var normalized := clampi(level, 0, DATA_PATHS.size())
	var domains := _default_domains()
	var modifier_ids: PackedStringArray = []
	for index in range(normalized):
		var data := load(DATA_PATHS[index]) as Resource
		if data == null:
			push_error("AdvancedCrisisResolver failed to load crisis data %d." % (index + 1))
			continue
		modifier_ids.append(data.crisis_id)
		_merge_domains(domains, data.modifiers)
	var enemy: Dictionary = domains.enemy
	var boss: Dictionary = domains.boss
	return {
		"level": normalized,
		"modifier_ids": modifier_ids,
		"domains": domains.duplicate(true),
		"economy": Dictionary(domains.economy).duplicate(true),
		"exploration": Dictionary(domains.exploration).duplicate(true),
		"enemy": enemy.duplicate(true),
		"boss": boss.duplicate(true),
		"event": Dictionary(domains.event).duplicate(true),
		"healing": Dictionary(domains.healing).duplicate(true),
		"run": Dictionary(domains.run).duplicate(true),
		"enemy_ehp_mult": float(enemy.get("elite_ehp_mult", 1.0)),
		"enemy_damage_mult": 1.0,
	}


func get_domain(level: int, domain: String) -> Dictionary:
	return Dictionary(resolve(level).get(domain, {})).duplicate(true)


func _default_domains() -> Dictionary:
	return {
		"economy": {"shop_price_mult": 1.0, "reroll_base_bonus": 0},
		"exploration": {"patrol_interval_mult": 1.0, "patrol_enemy_cap_bonus": 0, "trap_count_mult": 1.0, "trap_damage_mult": 1.0},
		"enemy": {"elite_ehp_mult": 1.0, "elite_family_affix_count": 0, "mixed_family_wave_chance": 0.0},
		"boss": {"ehp_mult": 1.0, "phase_enrage_threshold": 0.0, "phase_enrage_count": 0, "cooldown_mult": 1.0, "family_variant_count": 0, "final_family_affix_count": 0},
		"event": {"hp_cost_mult": 1.0, "mineral_cost_mult": 1.0, "high_risk_reward_mult": 1.0},
		"healing": {"mult": 1.0, "minimum": 0},
		"run": {"active_condition_count_bonus": 0},
	}


func _merge_domains(domains: Dictionary, additions: Dictionary) -> void:
	for domain_name in additions:
		var target := Dictionary(domains.get(domain_name, {}))
		for key in Dictionary(additions[domain_name]):
			var value = Dictionary(additions[domain_name])[key]
			if value is float and String(key).ends_with("_mult"):
				target[key] = float(target.get(key, 1.0)) * float(value)
			elif value is int and (String(key).ends_with("_bonus") or String(key).ends_with("_count")):
				target[key] = int(target.get(key, 0)) + int(value)
			else:
				target[key] = value
		domains[domain_name] = target
