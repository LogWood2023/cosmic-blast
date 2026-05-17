extends Node2D
class_name MiniHellEye

const HealthBarScript = preload("res://scripts/HealthBar.gd")
const DRAIN_DMG: int = 1
const PARTICLE_MIN: int = 8
const PARTICLE_MAX: int = 12
const PARTICLE_MAX_RADIUS: float = 5.0
const PARTICLE_MIN_RADIUS: float = 2.0
const PARTICLE_FADE_IN: float = 0.4
const PARTICLE_ACCEL: float = 300.0
const PARTICLE_ARRIVE_DIST: float = 50.0
const PARTICLE_MAX_AGE: float = 3.0
const FADE_START_DIST: float = 50.0
const EYEBALL_TRACK_PX: float = 20.0
const OPEN_SPEED: float = 4.0

var _stroke_sprite: Sprite2D
var _nebula_sprite: Sprite2D
var _eyeball_sprite: Sprite2D
var _eye_mat: ShaderMaterial
var _nebula_mat: ShaderMaterial
var _health_bar: Node2D

var max_hp: int
var _hp: int
var _dying: bool = false
var _eye_y_mult: float = 0.02
var _opening: bool = true

var _drain_timer: float = 0.0
var _particles: Array[Dictionary] = []

var _scale_factor: float = 0.2
var _neb_mask_x: float = 1.0
var _neb_mask_y: float = 1.0
var _eye_mask_x: float = 1.0
var _eye_mask_y: float = 1.0
var _stroke_mask_x: float = 0.18
var _stroke_mask_y: float = 0.18
var _stroke_th_ratio: float = 0.003
var _mask_tex: Texture2D
var _mask_rotation: float = 0.0
var _stroke_jitter: float = 1.5
var _stroke_base_color: Color = Color.BLACK
var _nebula_mask_uv: Vector2 = Vector2.ZERO
var _eye_mask_uv: Vector2 = Vector2.ZERO
var _eyeball_scale_for_track: Vector2 = Vector2(0.18, 0.18)


static func spawn(parent: Node, pos: Vector2, sc: float, hp_val: int) -> MiniHellEye:
	var m = MiniHellEye.new()
	m.position = pos
	sc *= 2.0
	m._scale_factor = sc
	m._eye_y_mult = 0.08
	m._opening = true
	m.max_hp = hp_val
	m._hp = hp_val

	var tex_mask = parent._mask_tex
	var nebula_tex = parent._nebula_sprite.texture
	var eyeball_tex = parent.body_sprite.texture
	var clip_shader = parent._nebula_mat.shader if is_instance_valid(parent._nebula_mat) else preload("res://assets/images/helleye/eye_clip.gdshader")

	var ns = parent.nebula_scale * sc
	var es = parent.eyeball_scale * sc
	var ms = parent.mask_scale * sc

	var stroke_color = parent.mask_stroke_color
	var stroke_th = parent.mask_stroke_thickness * sc

	m._mask_rotation = randf_range(0, TAU)
	var rot = m._mask_rotation

	var mask_tex_size: float = 1024.0
	m._neb_mask_x = parent.nebula_scale.x / parent.mask_scale.x
	m._neb_mask_y = parent.nebula_scale.y / parent.mask_scale.y
	m._eye_mask_x = parent.eyeball_scale.x / parent.mask_scale.x
	m._eye_mask_y = parent.eyeball_scale.y / parent.mask_scale.y
	m._stroke_mask_x = parent.mask_scale.x
	m._stroke_mask_y = parent.mask_scale.y
	m._stroke_th_ratio = parent.mask_stroke_thickness / mask_tex_size
	m._stroke_jitter = parent.mask_stroke_jitter
	m._stroke_base_color = stroke_color

	var parent_neb_off = parent.nebula_offset
	var parent_eye_off = parent.eyeball_offset
	m._nebula_mask_uv = parent_neb_off / (mask_tex_size * parent.mask_scale)
	m._eye_mask_uv = parent_eye_off / (mask_tex_size * parent.mask_scale)
	m._eyeball_scale_for_track = es

	m._mask_tex = tex_mask
	m._stroke_sprite = Sprite2D.new()
	m._stroke_sprite.texture = tex_mask
	m._stroke_sprite.centered = true
	m._stroke_sprite.self_modulate = stroke_color
	m._stroke_sprite.z_index = -3
	m._stroke_sprite.rotation = -rot
	m._stroke_sprite.scale = Vector2(ms.x + stroke_th / 1024.0, ms.y * m._eye_y_mult + stroke_th / 1024.0)
	m.add_child(m._stroke_sprite)

	m._nebula_sprite = Sprite2D.new()
	m._nebula_sprite.texture = nebula_tex
	m._nebula_sprite.centered = true
	m._nebula_sprite.scale = ns
	m._nebula_sprite.position = parent_neb_off * sc
	m._nebula_sprite.z_index = -2
	m._nebula_mat = ShaderMaterial.new()
	m._nebula_mat.shader = clip_shader
	m._nebula_mat.set_shader_parameter(&"mask_tex", tex_mask)
	m._nebula_sprite.material = m._nebula_mat
	m._sync_nebula_mask()
	m.add_child(m._nebula_sprite)

	m._eyeball_sprite = Sprite2D.new()
	m._eyeball_sprite.texture = eyeball_tex
	m._eyeball_sprite.centered = true
	m._eyeball_sprite.scale = es
	m._eyeball_sprite.position = parent_eye_off * sc
	m._eyeball_sprite.z_index = -1
	m._eye_mat = ShaderMaterial.new()
	m._eye_mat.shader = clip_shader
	m._eye_mat.set_shader_parameter(&"mask_tex", tex_mask)
	m._eyeball_sprite.material = m._eye_mat
	m._sync_eye_mask()
	m.add_child(m._eyeball_sprite)

	m._sync_stroke()

	var body_area = Area2D.new()
	body_area.collision_layer = 2
	body_area.collision_mask = 1
	body_area.name = "BodyArea"
	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = 30.0 * sc
	col.name = "BodyCol"
	body_area.add_child(col)
	body_area.area_entered.connect(m._on_body_area_entered)
	m.add_child(body_area)

	m._health_bar = Node2D.new()
	m._health_bar.set_script(HealthBarScript)
	m._health_bar.position = Vector2(0, -50)
	m.add_child(m._health_bar)
	m._health_bar.setup(hp_val)

	parent.get_tree().current_scene.add_child.call_deferred(m)
	return m


func _sync_nebula_mask() -> void:
	_nebula_mat.set_shader_parameter(&"mask_scale", Vector2(_neb_mask_x, _neb_mask_y / _eye_y_mult))
	_nebula_mat.set_shader_parameter(&"mask_offset_uv", _nebula_mask_uv)
	_nebula_mat.set_shader_parameter(&"content_scale", Vector2.ONE)
	_nebula_mat.set_shader_parameter(&"mask_rotation", _mask_rotation)


func _sync_eye_mask() -> void:
	_eye_mat.set_shader_parameter(&"mask_scale", Vector2(_eye_mask_x, _eye_mask_y / _eye_y_mult))
	_eye_mat.set_shader_parameter(&"mask_offset_uv", _eye_mask_uv)
	_eye_mat.set_shader_parameter(&"content_scale", Vector2.ONE)
	_eye_mat.set_shader_parameter(&"mask_rotation", _mask_rotation)


func _sync_stroke() -> void:
	if _stroke_sprite:
		_stroke_sprite.scale = Vector2(
			(_stroke_mask_x + _stroke_th_ratio) * _scale_factor,
			(_stroke_mask_y * _eye_y_mult + _stroke_th_ratio) * _scale_factor
		)
		var stroke_alpha = clampf((_eye_y_mult - 0.01) / 0.09, 0.0, 1.0)
		if _eye_y_mult <= 0.01:
			_stroke_sprite.visible = false
		else:
			_stroke_sprite.visible = true
			_stroke_sprite.self_modulate = Color(_stroke_base_color.r, _stroke_base_color.g, _stroke_base_color.b, _stroke_base_color.a * stroke_alpha)
	_apply_stroke_jitter()


func _apply_stroke_jitter() -> void:
	if not is_instance_valid(_stroke_sprite):
		return
	var t = Time.get_ticks_msec() / 1000.0
	var jx = sin(t * 11.0) * cos(t * 17.0) * _stroke_jitter * _scale_factor
	var jy = cos(t * 13.0) * sin(t * 19.0) * _stroke_jitter * _scale_factor
	_stroke_sprite.offset = Vector2(jx, jy)
	var sx = 1.0 + sin(t * 7.0) * cos(t * 9.0) * 0.08
	var sy = 1.0 + cos(t * 8.0) * sin(t * 11.0) * 0.08
	var sc = _stroke_sprite.scale
	_stroke_sprite.scale = Vector2(sc.x * sx, sc.y * sy)
	var rj = sin(t * 14.0) * cos(t * 10.0) * 0.03 * _scale_factor
	_stroke_sprite.rotation = -_mask_rotation + rj


func _process(delta: float) -> void:
	if _dying:
		_eye_y_mult = lerpf(_eye_y_mult, 0.0, delta * 6.0)
		_sync_eye()
		_sync_stroke()
		_update_particles(delta)
		if _eye_y_mult < 0.02:
			queue_free()
		return

	if _opening:
		_eye_y_mult = lerpf(_eye_y_mult, 1.0, delta * OPEN_SPEED)
		if _eye_y_mult > 0.98:
			_eye_y_mult = 1.0
			_opening = false
		_sync_eye()
		_sync_stroke()
		queue_redraw()
		return

	# drain + particles every 2 seconds
	_drain_timer += delta
	if _drain_timer >= 2.0:
		_drain_timer -= 2.0
		_apply_drain()

	_update_particles(delta)
	_track_player_eyeball()
	_sync_eye()
	_sync_stroke()
	queue_redraw()


func _apply_drain() -> void:
	var player = get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return
	GameManager.player_hp -= DRAIN_DMG
	if GameManager.player_hp <= 0:
		GameManager.player_hp = 0
		get_tree().change_scene_to_file.call_deferred("res://scenes/gameover.tscn")
		return
	var ppos = player.global_position
	var count = randi_range(PARTICLE_MIN, PARTICLE_MAX)
	for _i in count:
		var angle = randf_range(0, TAU)
		var speed = randf_range(40.0, 120.0)
		_particles.append({
			"pos": ppos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"age": 0.0,
			"radius": randf_range(PARTICLE_MIN_RADIUS, PARTICLE_MAX_RADIUS),
		})


func _update_particles(delta: float) -> void:
	var target = global_position
	var to_remove: Array = []
	for i in _particles.size():
		var d = _particles[i]
		d.age += delta
		if d.age > PARTICLE_MAX_AGE:
			to_remove.append(i)
			continue
		var to_target = target - d.pos
		var dist = to_target.length()
		if dist < PARTICLE_ARRIVE_DIST:
			to_remove.append(i)
			continue
		var accel = to_target.normalized() * PARTICLE_ACCEL
		d.vel += accel * delta
		d.pos += d.vel * delta
	for i in range(to_remove.size() - 1, -1, -1):
		_particles.remove_at(to_remove[i])


func _sync_eye() -> void:
	_sync_nebula_mask()
	_sync_eye_mask()


func _track_player_eyeball() -> void:
	if not is_instance_valid(_eye_mat):
		return
	var player = get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return
	var dir = player.global_position - global_position
	if dir.length() < 0.1:
		return
	dir = dir.normalized()
	var mask_size: float = 1024.0
	var uv_x = -dir.x * EYEBALL_TRACK_PX * _scale_factor / (mask_size * _eyeball_scale_for_track.x)
	var uv_y = -dir.y * EYEBALL_TRACK_PX * _scale_factor / (mask_size * _eyeball_scale_for_track.y)
	_eye_mat.set_shader_parameter(&"content_offset", Vector2(uv_x, uv_y))
	_nebula_mat.set_shader_parameter(&"content_offset", Vector2(uv_x, uv_y))


func _on_body_area_entered(area: Area2D) -> void:
	if _dying:
		return
	if area.is_in_group(&"player"):
		return
	if area.get(&"atk") != null:
		_hp -= area.atk
		_health_bar.take_hit(_hp)
		if is_instance_valid(area):
			area.queue_free()
		if _hp <= 0:
			_die()


func _die() -> void:
	if _dying:
		return
	_dying = true
	if is_instance_valid(_health_bar):
		_health_bar.queue_free()


func _draw() -> void:
	for d in _particles:
		var offset = d.pos - global_position
		var alpha: float
		if d.age < PARTICLE_FADE_IN:
			alpha = d.age / PARTICLE_FADE_IN
		else:
			alpha = 1.0
		var dist_to_center = offset.length()
		if dist_to_center < FADE_START_DIST:
			alpha *= dist_to_center / FADE_START_DIST
		draw_circle(offset, d.radius, Color(0.9, 0.15, 0.15, alpha * 0.7))
