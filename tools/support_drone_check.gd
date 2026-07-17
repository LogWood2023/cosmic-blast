extends Node
## 僚机行为系统自检：验证 get_drone_loadout 按 behavior 分派，且射手僚机能实际射击伤敌

const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")
const BULLET_SCENE := preload("res://scenes/entities/projectiles/bullet.tscn")
const DRONE_SCENE_PATH := "res://scenes/entities/support/SupportDrone.tscn"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(DRONE_SCENE_PATH):
		_fail("Support drone scene should exist as an editable standalone scene.")
		return

	RunManager.start_new_run()
	RunManager.compute_capacity = 99

	# 1) 每种僚机件应装载为对应 behavior
	var cases := {
		"divine_drone_seed": "shooter",
		"divine_salvage_squadron": "miner",
		"wingman_protocol": "guardian",
		"divine_oracle_swarm_core": "kamikaze",
		"divine_repair_familiar": "medic",
	}
	for item_id in cases:
		var lo := EquipmentCatalog.get_drone_loadout("pulse_cannon", [item_id])
		if lo.is_empty() or String(lo[0].get("behavior", "")) != String(cases[item_id]):
			_fail("%s 应装载为 %s 僚机。" % [item_id, cases[item_id]])
			return

	# 蜂群圣核（自爆遗物）应贡献 3 个僚机
	var swarm := EquipmentCatalog.get_drone_loadout("pulse_cannon", ["divine_oracle_swarm_core"])
	if swarm.size() < 3:
		_fail("蜂群圣核应贡献至少 3 个自爆僚机，实得 %d。" % swarm.size())
		return

	# 混装应生成不同类型僚机并存
	var mix := EquipmentCatalog.get_drone_loadout("pulse_cannon", ["divine_drone_seed", "wingman_protocol", "divine_repair_familiar"])
	var kinds := {}
	for d in mix:
		kinds[String(d.get("behavior", ""))] = true
	if not (kinds.has("shooter") and kinds.has("guardian") and kinds.has("medic")):
		_fail("混装僚机件应生成射手/护盾/治疗并存的僚机群。")
		return

	# 2) 射手僚机应实际生成并自动射击伤敌
	RunManager.equipment_inventory = ["pulse_cannon", "divine_drone_seed", "wingman_protocol", "divine_repair_familiar"]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = ["divine_drone_seed", "wingman_protocol", "divine_repair_familiar"]

	var player = PLAYER_SCENE.instantiate()
	player.bullet_scene = BULLET_SCENE
	player.movement_bounds = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	player.global_position = Vector2(500, 500)
	add_child(player)

	await get_tree().process_frame
	var drones := get_tree().get_nodes_in_group(&"player_support_drones")
	if drones.size() < 3:
		_fail("混装射手、护盾、治疗装备后应生成三类僚机。")
		return
	var drone: Node2D
	var guardian: Node2D
	var medic: Node2D
	for candidate in drones:
		match String(candidate.get("behavior")):
			"shooter":
				drone = candidate as Node2D
			"guardian":
				guardian = candidate as Node2D
			"medic":
				medic = candidate as Node2D
	if drone == null or guardian == null or medic == null:
		_fail("玩家实例应同时生成射手、护盾与治疗僚机。")
		return
	if drone.scene_file_path != DRONE_SCENE_PATH:
		_fail("Support drone should be instanced from %s, got %s." % [DRONE_SCENE_PATH, drone.scene_file_path])
		return
	if String(drone.get("behavior")) != "shooter":
		_fail("无人机种子应生成射手僚机，实为 %s。" % String(drone.get("behavior")))
		return
	if float(drone.get("fire_interval")) > 0.55 / 3.0 + 0.001:
		_fail("僚机基础触发频率应提升到原来的三倍。")
		return
	var visual_body := drone.get_node_or_null("Visual/Body") as Polygon2D
	var rear_left := drone.get_node_or_null("Visual/RearNodeLeft") as Polygon2D
	var rear_right := drone.get_node_or_null("Visual/RearNodeRight") as Polygon2D
	if visual_body == null or not _is_horizontally_symmetric(visual_body.polygon) or drone.get_node_or_null("Visual/Fold") == null or rear_left == null or rear_right == null or not is_equal_approx(rear_left.position.x, -rear_right.position.x) or not is_equal_approx(rear_left.position.y, rear_right.position.y):
		_fail("僚机应使用沿中轴左右镜像的规则箭头与对称尾部节点。")
		return
	var glow_outer := drone.get_node_or_null("Visual/GlowOuter") as Polygon2D
	var glow_inner := drone.get_node_or_null("Visual/GlowInner") as Polygon2D
	var glow_core := drone.get_node_or_null("Visual/GlowCore") as Polygon2D
	var glow_material := glow_outer.material as CanvasItemMaterial if glow_outer != null else null
	if glow_outer == null or glow_inner == null or glow_core == null or glow_material == null or glow_material.blend_mode != CanvasItemMaterial.BLEND_MODE_ADD:
		_fail("僚机应带有使用加法混合材质的内外轮廓与核心辉光。")
		return
	var distributed_damage := 0
	for _i in range(3):
		distributed_damage += int(drone.call("_next_bullet_damage"))
	if distributed_damage != int(drone.get("bullet_damage")):
		_fail("三次高频射击的总伤害应等于改造前的一次完整伤害。")
		return

	# 无敌人时，非护盾僚机应在机尾分列；护盾僚机继续环绕。
	await get_tree().create_timer(0.45).timeout
	var player_forward: Vector2 = Vector2.UP.rotated(player.global_rotation)
	var player_right: Vector2 = player_forward.rotated(PI * 0.5)
	var shooter_offset: Vector2 = drone.global_position - player.global_position
	var medic_offset: Vector2 = medic.global_position - player.global_position
	if shooter_offset.dot(-player_forward) <= 35.0 or medic_offset.dot(-player_forward) <= 35.0:
		_fail("非护盾僚机在巡航时应跟随在玩家后方，而不是绕行。")
		return
	var shooter_side: float = shooter_offset.dot(player_right)
	var medic_side: float = medic_offset.dot(player_right)
	if shooter_side * medic_side >= 0.0:
		_fail("同排僚机应分列玩家机尾两侧，形成三角阵列。射手=%.1f，治疗=%.1f" % [shooter_side, medic_side])
		return
	var guardian_distance: float = guardian.global_position.distance_to(player.global_position)
	if guardian_distance < 45.0 or guardian_distance > 150.0:
		_fail("护盾僚机应保持环绕玩家。")
		return
	var idle_visual := drone.get_node("Visual") as Node2D
	if absf(angle_difference(idle_visual.global_rotation, player.global_rotation)) > 0.001:
		_fail("空闲时僚机必须与玩家保持统一朝向。")
		return

	# 僚机生成后，玩家主炮输入仍必须能独立生成有伤害的玩家子弹。
	var bullets_before: Array[Node] = get_tree().get_nodes_in_group(&"force_field_projectiles")
	var bullet_ids_before := {}
	for existing_bullet in bullets_before:
		bullet_ids_before[existing_bullet.get_instance_id()] = true
	player.fire_cooldown = 0.0
	Input.action_press(&"shoot")
	await get_tree().create_timer(0.08).timeout
	Input.action_release(&"shoot")
	var spawned_player_bullet: Node = null
	for candidate in get_tree().get_nodes_in_group(&"force_field_projectiles"):
		if not bullet_ids_before.has(candidate.get_instance_id()):
			spawned_player_bullet = candidate
			break
	if spawned_player_bullet == null or int(spawned_player_bullet.get("atk")) <= 0:
		_fail("僚机生成后，玩家主炮仍应响应射击输入并生成有伤害的子弹。")
		return

	var enemy := _make_enemy(Vector2(760, 500))
	enemy.set("hp", 999)
	add_child(enemy)
	await get_tree().create_timer(0.08).timeout
	var expected_target_angle: float = (enemy.global_position - drone.global_position).angle() + PI * 0.5
	if absf(angle_difference(idle_visual.global_rotation, expected_target_angle)) > 0.001:
		_fail("交战时僚机必须始终朝向自己的目标，而不是朝向移动方向。")
		return
	enemy.set("hp", 12)

	for _i in range(180):
		await get_tree().process_frame
		if int(enemy.get("hp")) < 12:
			print("Support drone check passed.")
			get_tree().quit(0)
			return

	_fail("射手僚机应自动射击伤害附近敌人。")


func _make_enemy(pos: Vector2) -> Area2D:
	var enemy := Area2D.new()
	enemy.name = "SupportDroneTarget"
	enemy.global_position = pos
	enemy.set_script(TestEnemyScript)
	enemy.add_to_group(&"enemies")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	shape.shape = circle
	enemy.add_child(shape)
	return enemy


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)


func _is_horizontally_symmetric(points: PackedVector2Array) -> bool:
	for point in points:
		var has_mirror := false
		for candidate in points:
			if is_equal_approx(candidate.x, -point.x) and is_equal_approx(candidate.y, point.y):
				has_mirror = true
				break
		if not has_mirror:
			return false
	return true


class TestEnemyScript:
	extends Area2D

	var hp: int = 12

	func take_damage(amount: int, _source: Node = null) -> void:
		hp -= maxi(0, amount)
