extends Node2D

@export var endpoint_size: float = 96.0

var _start_point: Vector2 = Vector2.ZERO
var _end_point: Vector2 = Vector2.ZERO
var _start_texture: Texture2D
var _end_texture: Texture2D
var _start_target: Node2D
var _end_target: Node2D
var _start_offset: Vector2 = Vector2.ZERO
var _end_offset: Vector2 = Vector2.ZERO
var _start_angle: float = 0.0
var _end_angle: float = 0.0

@onready var start_sprite: Sprite2D = $StartEndpoint
@onready var end_sprite: Sprite2D = $EndEndpoint


func _ready() -> void:
	add_to_group(&"electric_isolation_bands")
	_apply_visuals()


func _process(_delta: float) -> void:
	if is_instance_valid(_start_target):
		_start_point = _start_target.global_position + _start_offset
	if is_instance_valid(_end_target):
		_end_point = _end_target.global_position + _end_offset
	_apply_positions()


func setup(start_point: Vector2, end_point: Vector2, start_angle: float, end_angle: float, start_texture: Texture2D, end_texture: Texture2D) -> void:
	_start_point = start_point
	_end_point = end_point
	_start_angle = start_angle
	_end_angle = end_angle
	_start_texture = start_texture
	_end_texture = end_texture
	if is_node_ready():
		_apply_visuals()


func follow_targets(start_target: Node2D, start_offset: Vector2, end_target: Node2D, end_offset: Vector2) -> void:
	_start_target = start_target
	_start_offset = start_offset
	_end_target = end_target
	_end_offset = end_offset


func get_map_endpoints() -> Array[Dictionary]:
	return [
		{
			"position": _start_point,
			"rotation": _start_angle,
			"texture": _start_texture,
		},
		{
			"position": _end_point,
			"rotation": _end_angle,
			"texture": _end_texture,
		},
	]


func _apply_visuals() -> void:
	start_sprite.texture = _start_texture
	end_sprite.texture = _end_texture
	_apply_sprite_scale(start_sprite)
	_apply_sprite_scale(end_sprite)
	_apply_positions()


func _apply_positions() -> void:
	start_sprite.global_position = _start_point
	start_sprite.global_rotation = _start_angle
	end_sprite.global_position = _end_point
	end_sprite.global_rotation = _end_angle


func _apply_sprite_scale(sprite: Sprite2D) -> void:
	if not sprite.texture:
		return
	var size = sprite.texture.get_size()
	var max_side = maxf(size.x, size.y)
	sprite.scale = Vector2.ONE * (endpoint_size / maxf(1.0, max_side))
