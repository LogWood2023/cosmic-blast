extends Area2D

@export var speed: float = 500.0
@export var damage: int = 5
@export var lifetime: float = 8.0

var direction: Vector2 = Vector2.RIGHT
var ignore_body: Node2D
var _age: float = 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	global_position += direction * speed * delta


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		area.take_damage_from(self)
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(ignore_body) and body == ignore_body:
		return
	var parent = body.get_parent()
	if body.is_in_group(&"space_rocks") or (parent and parent.is_in_group(&"isolation_bands")):
		queue_free()
