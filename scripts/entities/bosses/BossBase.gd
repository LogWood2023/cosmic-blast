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
	if area.is_in_group(&"player") and controller:
		if area.get(&"atk") != null:
			controller.apply_damage(area.atk * 3)
		area.take_knockback_damage(20, 1000, 0.5)
		return
	if area.get(&"atk") != null:
		if controller:
			controller.apply_damage(area.atk)
		_destroy_projectile(area)


func take_boss_damage(amount: int) -> void:
	if controller:
		controller.apply_damage(amount)


func block_player() -> bool:
	return true


func _destroy_projectile(area: Area2D) -> void:
	if area.has_method(&"destroy"):
		area.destroy()
	else:
		area.queue_free()
