extends Area2D
## Boss 组件基类 —— 共享 HP / 碰撞弹飞玩家

var controller: Node
var boss_hp: int:
	get: return controller.boss_hp if controller else 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1          # 检测玩家所在层
	add_to_group(&"boss")
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	# 玩家触碰 → 击飞
	if area.is_in_group(&"player") and controller:
		area.take_knockback_damage(20, 1000, 0.5)
		return
	# 玩家子弹命中（子弹 mask=1 检测不到 layer=2 的 Boss，由 Boss 侧处理）
	if area.get(&"atk") != null:
		if controller:
			controller.apply_damage(area.atk)
		area.queue_free()


func take_boss_damage(amount: int) -> void:
	if controller:
		controller.apply_damage(amount)


func block_player() -> bool:
	return true
