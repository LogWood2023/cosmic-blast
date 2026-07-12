extends Control

const REFRESH_INTERVAL := 0.2

@onready var task_value: Label = $Panel/Margin/Stack/TaskValue
@onready var ore_value: Label = $Panel/Margin/Stack/OreValue
@onready var chest_value: Label = $Panel/Margin/Stack/ChestValue

var _refresh_remaining := 0.0
var _rewards: Node


func _ready() -> void:
	_hide_score_in_explore_room()
	_refresh()


func _process(delta: float) -> void:
	_refresh_remaining -= delta
	if _refresh_remaining <= 0.0:
		_refresh()


func _hide_score_in_explore_room() -> void:
	var score_row := get_node_or_null("../../HUD/PlayerStatusHUD/Cluster/Margin/Stack/ScoreRow") as Control
	if score_row:
		score_row.hide()


func _refresh() -> void:
	_refresh_remaining = REFRESH_INTERVAL
	task_value.text = _get_task_text()
	var counts := _get_remaining_reward_counts()
	ore_value.text = "剩余矿脉：%d" % int(counts["ore_veins"])
	chest_value.text = "剩余宝箱：%d" % int(counts["chests"])


func _get_task_text() -> String:
	if not RunManager.is_formal_run_active() or RunManager.current_node_id < 0:
		return "搜索资源并撤离"
	var node := RunManager.get_map_node(RunManager.current_node_id)
	if node.is_empty():
		return "搜索资源并撤离"
	match String(node.get("type", "")):
		RunManager.NODE_BATTLE:
			return String(node.get("battle_title", "清理威胁并撤离"))
		RunManager.NODE_REWARD:
			return String(node.get("reward_title", "回收资源并撤离"))
		_:
			return "搜索资源并撤离"


func _get_remaining_reward_counts() -> Dictionary:
	if not is_instance_valid(_rewards):
		_rewards = get_node_or_null("../../Rewards")
	var counts := {"ore_veins": 0, "chests": 0}
	if not _rewards:
		return counts
	for reward in _rewards.get_children():
		if not is_instance_valid(reward) or not reward.has_method("get_reward_type"):
			continue
		if bool(reward.get_meta(&"reward_depleted", false)):
			continue
		if int(reward.get_reward_type()) == 1:
			counts["ore_veins"] = int(counts["ore_veins"]) + 1
		else:
			counts["chests"] = int(counts["chests"]) + 1
	return counts
