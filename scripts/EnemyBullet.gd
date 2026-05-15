extends Area2D
## 敌方子弹 —— 直线飞行，碰玩家消失

@export var speed: float = 500.0
var direction: Vector2 = Vector2.DOWN
var damage: int = 5
var explosion_center: Vector2    # 爆炸原点（技能6设置，用于限制飞行距离）
var max_travel: float = -1.0     # 最大飞行距离，-1 表示无限


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position += direction * speed * delta

	if max_travel > 0 and position.distance_to(explosion_center) > max_travel:
		queue_free()
		return

	var s = get_viewport().get_visible_rect().size
	if position.x < -60 or position.x > s.x + 60 or position.y < -60 or position.y > s.y + 60:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		queue_free()
