extends Area2D
## 敌方子弹 —— 直线飞行，碰玩家消失

@export var speed: float = 500.0
@export var world_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var direction: Vector2 = Vector2.DOWN
var ignore_body: Node2D
var damage: int = 5
var explosion_center: Vector2    # 爆炸原点（技能6设置，用于限制飞行距离）
var max_travel: float = -1.0     # 最大飞行距离，-1 表示无限


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if direction.length() > 0.001:
		rotation = direction.angle()
	position += direction * speed * delta

	if max_travel > 0 and position.distance_to(explosion_center) > max_travel:
		queue_free()
		return

	var bounds = _active_bounds()
	if position.x < bounds.position.x - 60 or position.x > bounds.position.x + bounds.size.x + 60 or position.y < bounds.position.y - 60 or position.y > bounds.position.y + bounds.size.y + 60:
		queue_free()


func _active_bounds() -> Rect2:
	if world_bounds.size != Vector2.ZERO:
		return world_bounds
	return Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(ignore_body) and body == ignore_body:
		return
	if body.is_in_group(&"space_rocks") or (body.get_parent() and body.get_parent().is_in_group(&"isolation_bands")):
		queue_free()
