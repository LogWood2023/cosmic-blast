extends Area2D
## 玩家子弹 —— 飞行 + 碰撞扣血

@export var speed: float = 500.0
var direction: Vector2 = Vector2.UP
var atk: int = 1


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position += direction * speed * delta
	var s = get_viewport().get_visible_rect().size
	if position.x < -50 or position.x > s.x + 50 or position.y < -50 or position.y > s.y + 50:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"enemies"):
		area.take_damage(atk)
		queue_free()
