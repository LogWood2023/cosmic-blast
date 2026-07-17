class_name RewardService
extends RefCounted
## Deterministic reward drafting with read-only equipment queries and protection metadata.

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const REWARD_DIRECTORY: String = "res://data/rewards"

var _resolver: RewardResolver = RewardResolver.new()
var _pools: Array[RewardPoolData] = []
var _draft_cards: Dictionary = {}


func _init() -> void:
	_load_pools()


func get_pools() -> Array[RewardPoolData]:
	return _pools.duplicate()


func prepare_choices(node_id: int, context: RunContentContext, seed: int) -> Array[Dictionary]:
	var cards := _make_regular_cards(node_id, context, seed)
	_draft_cards[_draft_key(node_id, context)] = cards
	var views: Array[Dictionary] = []
	for card in cards:
		views.append(_resolver.make_choice_view(card))
	return views


func prepare_boss_choices(node_id: int, context: RunContentContext, boss_family: String, seed: int) -> Array[Dictionary]:
	var cards := _make_boss_cards(node_id, context, boss_family, seed)
	_draft_cards[_draft_key(node_id, context)] = cards
	var views: Array[Dictionary] = []
	for card in cards:
		views.append(_resolver.make_choice_view(card))
	return views


func resolve_choice(node_id: int, choice_id: String, context: RunContentContext) -> RunMutationSet:
	var cards: Array = _draft_cards.get(_draft_key(node_id, context), [])
	for raw_card in cards:
		var card := raw_card as RewardDefinition
		if card != null and card.reward_id == choice_id:
			var mutation := _resolver.resolve(card, context, node_id)
			if mutation != null:
				mutation.metadata["reward_protection"] = _next_protection(card, context)
			return mutation
	return null


func _make_regular_cards(node_id: int, context: RunContentContext, seed: int) -> Array[RewardDefinition]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var stage := _stage(context)
	var protection := _protection(context)
	var cards: Array[RewardDefinition] = []
	var used_items: Dictionary = {}
	if int(protection.get("nodes_without_equipment", 0)) >= 3:
		cards.append(_make_equipment_card(context, node_id, rng, used_items, "", ""))
	elif int(protection.get("drafts_without_starter", 0)) >= 4:
		cards.append(_make_equipment_card(context, node_id, rng, used_items, "", "starter"))
	elif int(protection.get("drafts_without_amplifier", 0)) >= 4:
		cards.append(_make_equipment_card(context, node_id, rng, used_items, "", "amplifier"))
	while cards.size() < 3:
		var pool := _take_weighted_pool(stage, rng)
		if pool == null:
			break
		var card := _make_card_for_pool(pool.pool_id, context, node_id, rng, used_items)
		if card != null:
			cards.append(card)
	if cards.is_empty():
		cards.append(_make_mineral_card(45, "fallback"))
	while cards.size() < 3:
		cards.append(_make_mineral_card(45 + cards.size() * 10, "fallback_%d" % cards.size()))
	return cards


func _make_boss_cards(node_id: int, context: RunContentContext, boss_family: String, seed: int) -> Array[RewardDefinition]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var used_items: Dictionary = {}
	var stage := _stage(context)
	var cards: Array[RewardDefinition] = []
	cards.append(_make_equipment_card(context, node_id, rng, used_items, boss_family, "boss"))
	cards.append(_make_equipment_card(context, node_id, rng, used_items, _primary_family(context, boss_family), "amplifier"))
	var bridge_family := _secondary_family(context, boss_family)
	cards.append(_make_equipment_card(context, node_id, rng, used_items, bridge_family, "starter"))
	var maintenance := RewardDefinition.new()
	maintenance.reward_id = "boss_maintenance_%d" % stage
	maintenance.title = "核心维护包"
	maintenance.description = "获得 2 点算力并修复船体；后续两次奖励提高装备权重。"
	maintenance.preview_text = "算力 +2，修复 %d 生命。" % [25 + (stage - 1) * 10]
	maintenance.reward_type = "maintenance"
	maintenance.payload = {"heal": 25 + (stage - 1) * 10}
	maintenance.tags = PackedStringArray(["boss", "survival", "pity"])
	cards.append(maintenance)
	return cards


func _make_card_for_pool(pool_id: String, context: RunContentContext, node_id: int, rng: RandomNumberGenerator, used_items: Dictionary) -> RewardDefinition:
	match pool_id:
		"stable_supply":
			return _make_heal_card(26 + (_stage(context) - 1) * 8, pool_id) if _is_low_hp(context) else _make_mineral_card(45 + (_stage(context) - 1) * 25, pool_id)
		"equipment_draft":
			return _make_equipment_card(context, node_id, rng, used_items, "", "")
		"mechanic_starter":
			return _make_equipment_card(context, node_id, rng, used_items, "", "starter")
		"mechanic_amplifier":
			return _make_equipment_card(context, node_id, rng, used_items, "", "amplifier")
		"cross_family_bridge":
			return _make_equipment_card(context, node_id, rng, used_items, _secondary_family(context, ""), "starter")
		"repair_compute":
			return _make_heal_card(32 + (_stage(context) - 1) * 10, pool_id) if _is_low_hp(context) else _make_compute_card(1, pool_id)
		"high_risk_mineral":
			return _make_mineral_card(75 + (_stage(context) - 1) * 45, pool_id)
		"family_archive":
			return _make_equipment_card(context, node_id, rng, used_items, _primary_family(context, ""), "")
	return _make_mineral_card(45, "fallback")


func _make_equipment_card(context: RunContentContext, node_id: int, rng: RandomNumberGenerator, used_items: Dictionary, family: String, role: String) -> RewardDefinition:
	var item_id := _pick_item(context, rng, used_items, family, role)
	if item_id.is_empty():
		return _make_mineral_card(45 + (_stage(context) - 1) * 25, "equipment_fallback")
	used_items[item_id] = true
	var item := EquipmentCatalogScript.get_item(item_id)
	var card := RewardDefinition.new()
	card.reward_id = "equipment:%s" % item_id
	card.title = String(item.get("name", item_id))
	card.description = String(item.get("description", "可装配的遗失装备。"))
	card.preview_text = "%s · %s · 算力 %d" % [EquipmentCatalogScript.get_family_display_name(EquipmentCatalogScript.get_family(item_id)), _role_for_item(item_id), EquipmentCatalogScript.get_compute_cost(item_id)]
	card.reward_type = "equipment"
	card.item_id = item_id
	card.family_tag = EquipmentCatalogScript.get_family(item_id)
	card.role_tag = _role_for_item(item_id)
	card.tags = PackedStringArray(["equipment", card.family_tag, card.role_tag])
	return card


func _make_mineral_card(amount: int, suffix: String) -> RewardDefinition:
	var card := RewardDefinition.new()
	card.reward_id = "minerals:%s:%d" % [suffix, amount]
	card.title = "稳定星髓矿"
	card.description = "将可回收物压缩为立即可用的星髓矿。"
	card.preview_text = "获得 %d 星髓矿。" % amount
	card.reward_type = "minerals"
	card.payload = {"amount": amount}
	card.tags = PackedStringArray(["economy", "safe"])
	return card


func _make_heal_card(amount: int, suffix: String) -> RewardDefinition:
	var card := RewardDefinition.new()
	card.reward_id = "heal:%s:%d" % [suffix, amount]
	card.title = "船体维护包"
	card.description = "将纳米修复剂导入船体维护接口。"
	card.preview_text = "恢复 %d 生命。" % amount
	card.reward_type = "heal"
	card.payload = {"amount": amount}
	card.tags = PackedStringArray(["survival", "safe"])
	return card


func _make_compute_card(amount: int, suffix: String) -> RewardDefinition:
	var card := RewardDefinition.new()
	card.reward_id = "compute:%s:%d" % [suffix, amount]
	card.title = "算力扩容"
	card.description = "扩展本局可用算力容量。"
	card.preview_text = "获得 %d 点算力。" % amount
	card.reward_type = "compute"
	card.payload = {"amount": amount}
	card.tags = PackedStringArray(["compute"])
	return card


func _pick_item(context: RunContentContext, rng: RandomNumberGenerator, used_items: Dictionary, family: String, role: String) -> String:
	var snapshot := context.to_dictionary()
	var owned: Array = snapshot.get("equipment_inventory", [])
	var capacity := int(snapshot.get("compute_capacity", 99))
	var candidates: Array[String] = []
	var source_ids: Array[String] = EquipmentCatalogScript.get_boss_drop_item_ids() if role == "boss" else EquipmentCatalogScript.get_loot_item_ids()
	for raw_id in source_ids:
		var item_id := String(raw_id)
		if owned.has(item_id) or used_items.has(item_id):
			continue
		if not family.is_empty() and EquipmentCatalogScript.get_family(item_id) != family:
			continue
		if role == "boss" and not EquipmentCatalogScript.is_boss_drop(item_id):
			continue
		if role != "boss" and EquipmentCatalogScript.is_boss_drop(item_id):
			continue
		if not role.is_empty() and role != "boss" and _role_for_item(item_id) != role:
			continue
		if EquipmentCatalogScript.get_compute_cost(item_id) > capacity:
			continue
		candidates.append(item_id)
	if candidates.is_empty() and not role.is_empty():
		return _pick_item(context, rng, used_items, family, "")
	if candidates.is_empty() and not family.is_empty():
		return _pick_item(context, rng, used_items, "", role)
	if candidates.is_empty():
		return ""
	candidates.sort()
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _role_for_item(item_id: String) -> String:
	# WG-06 replacement point: temporary role contract derived from the read-only legacy catalog.
	if EquipmentCatalogScript.get_type(item_id) == "weapon" or EquipmentCatalogScript.get_rarity(item_id) == "common":
		return "starter"
	return "amplifier"


func _take_weighted_pool(stage: int, rng: RandomNumberGenerator) -> RewardPoolData:
	var candidates: Array[RewardPoolData] = []
	var total_weight := 0.0
	for pool in _pools:
		if stage < pool.min_stage:
			continue
		candidates.append(pool)
		total_weight += pool.weight
	if candidates.is_empty():
		return null
	var roll := rng.randf_range(0.0, total_weight)
	for pool in candidates:
		roll -= pool.weight
		if roll <= 0.0:
			return pool
	return candidates.back()


func _load_pools() -> void:
	var directory := DirAccess.open(REWARD_DIRECTORY)
	if directory == null:
		push_error("RewardService: reward directory is unavailable: %s" % REWARD_DIRECTORY)
		return
	for filename in directory.get_files():
		if filename.ends_with(".tres"):
			var pool := load("%s/%s" % [REWARD_DIRECTORY, filename]) as RewardPoolData
			if pool != null and not pool.pool_id.is_empty():
				_pools.append(pool)
	_pools.sort_custom(func(a: RewardPoolData, b: RewardPoolData) -> bool: return a.pool_id < b.pool_id)


func _protection(context: RunContentContext) -> Dictionary:
	return Dictionary(context.get_active_rule_snapshot().get("reward_protection", {}))


func _next_protection(card: RewardDefinition, context: RunContentContext) -> Dictionary:
	var next := _protection(context).duplicate(true)
	var is_equipment := card.reward_type == "equipment"
	next["nodes_without_equipment"] = 0 if is_equipment else int(next.get("nodes_without_equipment", 0)) + 1
	next["drafts_without_starter"] = 0 if card.role_tag == "starter" else int(next.get("drafts_without_starter", 0)) + 1
	next["drafts_without_amplifier"] = 0 if card.role_tag == "amplifier" else int(next.get("drafts_without_amplifier", 0)) + 1
	return next


func _stage(context: RunContentContext) -> int:
	var crisis := int(context.to_dictionary().get("crisis_level", 0))
	return 1 if crisis < 5 else (2 if crisis < 12 else 3)


func _is_low_hp(context: RunContentContext) -> bool:
	return context.get_player_hp() <= 30


func _primary_family(context: RunContentContext, fallback: String) -> String:
	var families: Array = context.get_active_rule_snapshot().get("family_tags", [])
	return String(families[0]) if not families.is_empty() else fallback


func _secondary_family(context: RunContentContext, fallback: String) -> String:
	var families: Array = context.get_active_rule_snapshot().get("family_tags", [])
	return String(families[1]) if families.size() > 1 else fallback


func _draft_key(node_id: int, context: RunContentContext) -> String:
	return "%d:%d" % [node_id, context.get_state_version()]
