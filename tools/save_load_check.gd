extends Node
## 存档往返自检：start_new_run → 改状态 → save → 清内存 → load → 断言恢复 → finish 清档


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.clear_saved_run()
	RunManager.start_new_run()
	RunManager.minerals = 137
	RunManager.crisis_level = 4
	RunManager.compute_capacity = 8
	if not RunManager.equipment_inventory.has("warped_quarry_lens"):
		RunManager.equipment_inventory.append("warped_quarry_lens")
	RunManager.equipped_auxiliaries.append("warped_quarry_lens")
	GameManager.player_hp = 57
	var node_count := RunManager.map_nodes.size()
	if node_count < 1:
		_fail("start_new_run 应生成地图节点")
		return

	RunManager.save_run()
	if not RunManager.has_saved_run():
		_fail("save_run 后应存在存档文件")
		return

	# 打乱内存状态，模拟退出到主菜单
	RunManager.cancel_run()
	GameManager.player_hp = 100
	RunManager.minerals = 0
	RunManager.crisis_level = 0
	RunManager.map_nodes.clear()

	if not RunManager.load_saved_run():
		_fail("load_saved_run 应成功")
		return
	if RunManager.minerals != 137:
		_fail("minerals 未恢复：%d" % RunManager.minerals)
		return
	if RunManager.crisis_level != 4:
		_fail("crisis_level 未恢复：%d" % RunManager.crisis_level)
		return
	if RunManager.compute_capacity != 8:
		_fail("compute_capacity 未恢复：%d" % RunManager.compute_capacity)
		return
	if not RunManager.equipment_inventory.has("warped_quarry_lens"):
		_fail("equipment_inventory 未恢复")
		return
	if GameManager.player_hp != 57:
		_fail("player_hp 未恢复：%d" % GameManager.player_hp)
		return
	if RunManager.map_nodes.size() != node_count:
		_fail("map_nodes 数量不符：%d vs %d" % [RunManager.map_nodes.size(), node_count])
		return
	if not RunManager.is_formal_run_active():
		_fail("恢复后 run 应为激活状态")
		return
	# Vector2 往返：节点数据里应保留 Vector2 字段（store_var full_objects）
	var found_vec := false
	for key in RunManager.map_nodes[0].keys():
		if typeof(RunManager.map_nodes[0][key]) == TYPE_VECTOR2:
			found_vec = true
			break
	if not found_vec:
		_fail("map_nodes 的 Vector2 字段未能往返恢复")
		return

	# 一局结束应清除存档
	RunManager.finish_run(false)
	if RunManager.has_saved_run():
		_fail("finish_run 后存档应被清除")
		return

	RunManager.clear_saved_run()
	print("Save load check passed.")
	get_tree().quit(0)


func _fail(msg: String) -> void:
	push_error("Save load check failed: " + msg)
	get_tree().quit(1)
