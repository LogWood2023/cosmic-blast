extends Control

const REFRESH_INTERVAL := 0.2
const CONTENT_FADE_DURATION := 0.24
const PANEL_RESIZE_DURATION := 0.26
const CONTENT_SLIDE_DISTANCE := 22.0
const PANEL_EXPANDED_SIZE := Vector2(460.0, 420.0)
const PANEL_COLLAPSED_SIZE := Vector2(460.0, 54.0)

@onready var panel: PanelContainer = $Panel
@onready var content: MarginContainer = $Panel/Layout/Content
@onready var task_value: Label = $Panel/Layout/Content/Details/TaskSection/Margin/Stack/TaskValue
@onready var ore_value: Label = $Panel/Layout/Content/Details/ResourceSection/Margin/Stack/OreValue
@onready var chest_value: Label = $Panel/Layout/Content/Details/ResourceSection/Margin/Stack/ChestValue
@onready var elite_value: Label = $Panel/Layout/Content/Details/ResourceSection/Margin/Stack/EliteValue
@onready var collapse_button: Button = $Panel/Layout/Header/Margin/Row/CollapseButton
@onready var task_section: PanelContainer = $Panel/Layout/Content/Details/TaskSection
@onready var resource_section: PanelContainer = $Panel/Layout/Content/Details/ResourceSection

var _refresh_remaining := 0.0
var _rewards: Node
var _collapsed := false
var _resource_totals := {"ore_veins": 0, "chests": 0, "elites": 0}
var _toggle_tween: Tween
var _content_tween: Tween
var _content_rest_position := Vector2.ZERO
var _animation_generation := 0


func _ready() -> void:
	_hide_score_in_explore_room()
	collapse_button.pressed.connect(_toggle_collapsed)
	collapse_button.pivot_offset = collapse_button.size * 0.5
	call_deferred("_prepare_section_animation")
	_refresh()


func _process(delta: float) -> void:
	_refresh_remaining -= delta
	if _refresh_remaining <= 0.0:
		_refresh()


func _hide_score_in_explore_room() -> void:
	var score_row := get_node_or_null("../../HUD/PlayerStatusHUD/Cluster/Margin/Stack/ScoreRow") as Control
	if score_row:
		score_row.hide()


func _toggle_collapsed() -> void:
	_collapsed = not _collapsed
	_animation_generation += 1
	if _toggle_tween and _toggle_tween.is_valid():
		_toggle_tween.kill()
	if _content_tween and _content_tween.is_valid():
		_content_tween.kill()
	_toggle_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _collapsed:
		_toggle_tween.tween_property(content, "modulate:a", 0.0, CONTENT_FADE_DURATION)
		_toggle_tween.parallel().tween_property(content, "position:y", _content_rest_position.y - CONTENT_SLIDE_DISTANCE, CONTENT_FADE_DURATION)
		_toggle_tween.parallel().tween_property(task_section, "scale", Vector2(0.985, 0.94), CONTENT_FADE_DURATION)
		_toggle_tween.parallel().tween_property(resource_section, "scale", Vector2(0.985, 0.94), CONTENT_FADE_DURATION).set_delay(0.04)
		_toggle_tween.parallel().tween_property(collapse_button, "rotation", PI, PANEL_RESIZE_DURATION)
		_toggle_tween.chain().tween_callback(_hide_content)
		_toggle_tween.tween_property(panel, "size", PANEL_COLLAPSED_SIZE, PANEL_RESIZE_DURATION)
		return
	_toggle_tween.tween_property(panel, "size", PANEL_EXPANDED_SIZE, PANEL_RESIZE_DURATION)
	_toggle_tween.parallel().tween_property(collapse_button, "rotation", 0.0, PANEL_RESIZE_DURATION)
	_toggle_tween.chain().tween_callback(_show_content)


func _hide_content() -> void:
	content.hide()
	content.position = _content_rest_position


func _show_content() -> void:
	content.modulate.a = 0.0
	content.show()
	call_deferred("_animate_content_entrance", _animation_generation)


func _prepare_section_animation() -> void:
	task_section.pivot_offset = task_section.size * 0.5
	resource_section.pivot_offset = resource_section.size * 0.5
	_content_rest_position = content.position


func _animate_content_entrance(generation: int) -> void:
	await get_tree().process_frame
	if generation != _animation_generation or _collapsed:
		return
	_content_rest_position = content.position
	content.position = _content_rest_position - Vector2(0.0, CONTENT_SLIDE_DISTANCE)
	_content_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_content_tween.tween_property(content, "position:y", _content_rest_position.y, CONTENT_FADE_DURATION)
	_content_tween.parallel().tween_property(content, "modulate:a", 1.0, CONTENT_FADE_DURATION)
	_content_tween.parallel().tween_property(task_section, "scale", Vector2.ONE, CONTENT_FADE_DURATION)
	_content_tween.parallel().tween_property(resource_section, "scale", Vector2.ONE, CONTENT_FADE_DURATION).set_delay(0.04)


func _refresh() -> void:
	_refresh_remaining = REFRESH_INTERVAL
	task_value.text = _get_task_text()
	var counts := _get_remaining_reward_counts()
	var elite_count := _get_remaining_elite_count()
	var planned_reward_totals := _get_planned_reward_totals()
	ore_value.text = "剩余矿脉：%d/%d" % [int(counts["ore_veins"]), _record_total("ore_veins", int(counts["ore_veins"]), int(planned_reward_totals.get("ore_veins", 0)))]
	chest_value.text = "剩余宝箱：%d/%d" % [int(counts["chests"]), _record_total("chests", int(counts["chests"]), int(planned_reward_totals.get("chests", 0)))]
	elite_value.text = "剩余精英：%d/%d" % [elite_count, _record_total("elites", elite_count, _get_planned_elite_total())]


func _get_task_text() -> String:
	if not RunManager.has_method("get_route_directive_summaries"):
		return "暂无巡航指令"
	var directives: Array = RunManager.get_route_directive_summaries()
	if directives.is_empty():
		return "暂无巡航指令"
	var lines: Array[String] = []
	for raw_directive in directives:
		var directive := Dictionary(raw_directive)
		var description := String(directive.get("description", "")).strip_edges()
		if not description.is_empty():
			lines.append("• %s" % description)
	return "\n".join(lines) if not lines.is_empty() else "暂无巡航指令"


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


func _get_remaining_elite_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if is_instance_valid(enemy) and bool(enemy.get_meta(&"explore_elite", false)):
			count += 1
	return count


func _get_planned_reward_totals() -> Dictionary:
	var room := get_node_or_null("../..")
	if room:
		return Dictionary(room.get_meta(&"explore_reward_totals", {}))
	return {}


func _get_planned_elite_total() -> int:
	var room := get_node_or_null("../..")
	return int(room.get_meta(&"explore_elite_total", 0)) if room else 0


func _record_total(key: String, current_count: int, planned_count: int = 0) -> int:
	var total := maxi(int(_resource_totals.get(key, 0)), maxi(current_count, planned_count))
	_resource_totals[key] = total
	return total
