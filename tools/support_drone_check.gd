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
	RunManager.equipment_inventory = ["pulse_cannon", "divine_drone_seed"]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = ["divine_drone_seed"]

	var player = PLAYER_SCENE.instantiate()
	player.bullet_scene = BULLET_SCENE
	player.movement_bounds = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	player.global_position = Vector2(500, 500)
	add_child(player)

	await get_tree().process_frame
	var drones := get_tree().get_nodes_in_group(&"player_support_drones")
	if drones.size() < 1:
		_fail("装配射手僚机件应生成僚机。")
		return
	var drone := drones[0]
	if drone.scene_file_path != DRONE_SCENE_PATH:
		_fail("Support drone should be instanced from %s, got %s." % [DRONE_SCENE_PATH, drone.scene_file_path])
		return
	if String(drone.get("behavior")) != "shooter":
		_fail("无人机种子应生成射手僚机，实为 %s。" % String(drone.get("behavior")))
		return

	var enemy := _make_enemy(Vector2(760, 500))
	add_child(enemy)

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


class TestEnemyScript:
	extends Area2D

	var hp: int = 12

	func take_damage(amount: int, _source: Node = null) -> void:
		hp -= maxi(0, amount)
