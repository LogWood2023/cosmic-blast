extends Area2D

signal evacuation_completed

@export var size: Vector2 = Vector2(128.0, 128.0)
@export var duration: float = 5.0
@export var base_alpha: float = 0.5
@export var filled_alpha: float = 1.0
@export var icon_texture: Texture2D

var _progress: float = 0.0
var _player_inside: bool = false
var _completed: bool = false

@onready var base_sprite: Sprite2D = $BaseSprite
@onready var fill_sprite: Sprite2D = $FillSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group(&"evac_points")
	collision_layer = 0
	collision_mask = 1
	var shape = RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape
	_apply_visuals()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _process(delta: float) -> void:
	if _completed:
		return
	if _player_inside:
		_progress = minf(1.0, _progress + delta / maxf(0.1, duration))
		if _progress >= 1.0:
			_completed = true
			evacuation_completed.emit()
	else:
		_progress = maxf(0.0, _progress - delta / maxf(0.1, duration))
	_update_fill_region()


func _apply_visuals() -> void:
	base_sprite.texture = icon_texture
	fill_sprite.texture = icon_texture
	base_sprite.centered = true
	fill_sprite.centered = true
	base_sprite.modulate = Color(1.0, 1.0, 1.0, base_alpha)
	fill_sprite.modulate = Color(1.0, 1.0, 1.0, filled_alpha)
	if not icon_texture:
		return
	var tex_size = icon_texture.get_size()
	var max_side = maxf(tex_size.x, tex_size.y)
	var scale_value = size.x / maxf(1.0, max_side)
	base_sprite.scale = Vector2.ONE * scale_value
	fill_sprite.scale = Vector2.ONE * scale_value
	fill_sprite.region_enabled = true
	_update_fill_region()


func _update_fill_region() -> void:
	if not icon_texture:
		return
	var tex_size = icon_texture.get_size()
	var fill_height = tex_size.y * _progress
	if fill_height <= 0.0:
		fill_sprite.visible = false
		return
	fill_sprite.visible = true
	fill_sprite.region_rect = Rect2(Vector2(0.0, tex_size.y - fill_height), Vector2(tex_size.x, fill_height))
	fill_sprite.offset = Vector2(0.0, (tex_size.y - fill_height) * 0.5)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(&"player"):
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group(&"player"):
		_player_inside = false


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		_player_inside = true


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group(&"player"):
		_player_inside = false
