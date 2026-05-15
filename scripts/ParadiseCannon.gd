extends Area2D
## 天堂号机炮 —— 缓慢旋转追踪玩家（补偿父节点旋转）

@export var turn_speed: float = 3.0       # 转向速度（弧度/秒）

var player: Area2D
var tracking: bool = true                # 技能中可暂停追踪


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	add_to_group(&"boss")
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if not tracking:
		return
	if not player:
		player = get_tree().get_first_node_in_group(&"player")
	if player:
		var world_dir = (player.global_position - global_position).normalized()
		var target_angle = world_dir.angle() - get_parent().rotation
		rotation = lerp_angle(rotation, target_angle, turn_speed * delta)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_knockback_damage(15, 800, 0.4)
		return
	if area.get(&"atk") != null:
		get_parent().apply_damage(area.atk)
		area.queue_free()
