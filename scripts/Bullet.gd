extends Area2D
## 玩家子弹 —— 飞行 + 碰撞扣血

@export var speed: float = 500.0
@export var world_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var direction: Vector2 = Vector2.UP
var atk: int = 1


func _ready() -> void:
	collision_mask = 1 | 2 | 4
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	position += direction * speed * delta
	var bounds = _active_bounds()
	if position.x < bounds.position.x - 50 or position.x > bounds.position.x + bounds.size.x + 50 or position.y < bounds.position.y - 50 or position.y > bounds.position.y + bounds.size.y + 50:
		queue_free()


func _active_bounds() -> Rect2:
	if world_bounds.size != Vector2.ZERO:
		return world_bounds
	return Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"enemies"):
		area.take_damage(atk)
		queue_free()
	elif area.is_in_group(&"explore_rewards"):
		if area.has_method("take_damage"):
			area.take_damage(1)
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"space_rocks") or body.get_parent().is_in_group(&"isolation_bands"):
		queue_free()
