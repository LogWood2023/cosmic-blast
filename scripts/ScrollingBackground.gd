extends Node2D
## 卷动星空背景 —— 两张图交替滚动，实现无限循环

@export var scroll_speed: float = 120.0    # 滚动速度（像素/秒）

var _texture_height: float
var _sprite1: Sprite2D
var _sprite2: Sprite2D


func _ready() -> void:
	# 创建两张星空图，上下拼接
	var tex = preload("res://assets/images/fx/starfield_bg.png")
	_texture_height = tex.get_height()

	_sprite1 = _make_sprite(tex)
	_sprite2 = _make_sprite(tex)

	# 第二张紧接在第一张下方
	_sprite2.position.y = -_texture_height


func _make_sprite(tex: Texture2D) -> Sprite2D:
	var s = Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(1.5, 1.5)
	s.centered = true
	s.position.x = 480
	s.z_index = -100                # 最底层背景
	add_child(s)
	return s


func _process(delta: float) -> void:
	var move = scroll_speed * delta

	_sprite1.position.y += move
	_sprite2.position.y += move

	# 图 1 滚出屏幕底部 → 移到图 2 上方
	if _sprite1.position.y > _texture_height:
		_sprite1.position.y = _sprite2.position.y - _texture_height

	# 图 2 滚出屏幕底部 → 移到图 1 上方
	if _sprite2.position.y > _texture_height:
		_sprite2.position.y = _sprite1.position.y - _texture_height
