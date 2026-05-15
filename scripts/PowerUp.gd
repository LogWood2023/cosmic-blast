extends Area2D
## 道具 —— 缓慢下落，被玩家拾取后生效

enum Type { FIRERATE, ATK, HEAL, SHIELD }

@export var power_type: Type = Type.FIRERATE
@export var fall_speed: float = 80.0

var screen_size: Vector2


func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y > screen_size.y + 40:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group(&"player"):
		return

	match power_type:
		Type.FIRERATE:
			area.apply_powerup_firerate()
		Type.ATK:
			area.apply_powerup_atk()
		Type.HEAL:
			area.apply_powerup_heal()
		Type.SHIELD:
			area.apply_powerup_shield()

	queue_free()
