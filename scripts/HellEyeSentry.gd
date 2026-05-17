extends "res://scripts/HellEyeController.gd"
class_name HellEyeSentry
## 前哨战 —— 地狱之眼亚种1
## 眼珠：机械风格 | 星云：银黑色机械高墙
## 技能：1(眯眼激光), 2(瞪眼收缩环), 3(闭眼传送)
## HP:1000, 技能冷却:3s

const SENTRY_BGM = preload("res://assets/audio/hell_eye_boss_bgm_2.mp3")

func _ready() -> void:
	boss_name = "前哨战"
	mask_rotation_deg = randf_range(0.0, 360.0)
	max_hp = 1000
	has_skill_1 = true
	has_skill_2 = true
	has_skill_3 = true
	has_skill_4 = false
	has_skill_5 = false
	has_skill_6 = false
	skill_cooldown = 3.0
	super._ready()
	boss_hp = max_hp
	bgm_player.stream = SENTRY_BGM
	_warn_color = Color(0.25, 0.25, 0.3, 0.7)
	_laser_color = Color(0.2, 0.2, 0.25, 0.8)
	_laser_glow_color = Color(0.08, 0.08, 0.1, 0.24)
	_death_particle_color = Color(0.75, 0.75, 0.8, 1.0)
	_theme_color = Color(0.55, 0.55, 0.6, 1.0)


func _setup_body() -> void:
	_mask_tex = preload("res://assets/images/helleye/mask_alpha.png")
	var nebula_tex = _load_variant_tex("res://assets/images/helleye_sentry/nebula_raw.png", "res://assets/images/helleye/nebula_raw.png")
	var eyeball_tex = _load_variant_tex("res://assets/images/helleye_sentry/eyeball_cutout.png", "res://assets/images/helleye/eyeball_cutout.png")
	var clip_shader = preload("res://assets/images/helleye/eye_clip.gdshader")

	_stroke_sprite = Sprite2D.new()
	_stroke_sprite.texture = _mask_tex
	_stroke_sprite.centered = true
	_stroke_sprite.self_modulate = mask_stroke_color
	_stroke_sprite.z_index = -3
	add_child(_stroke_sprite)

	_nebula_sprite = Sprite2D.new()
	_nebula_sprite.texture = nebula_tex
	_nebula_sprite.centered = true
	_nebula_sprite.scale = nebula_scale
	_nebula_sprite.position = nebula_offset
	_nebula_sprite.z_index = -2
	_nebula_sprite.self_modulate = Color(0.7, 0.7, 0.75, 1.0)
	_nebula_mat = ShaderMaterial.new()
	_nebula_mat.shader = clip_shader
	_nebula_mat.set_shader_parameter(&"mask_tex", _mask_tex)
	_nebula_sprite.material = _nebula_mat
	add_child(_nebula_sprite)

	body_sprite = Sprite2D.new()
	body_sprite.texture = eyeball_tex
	body_sprite.centered = true
	body_sprite.scale = eyeball_scale
	body_sprite.position = eyeball_offset
	body_sprite.z_index = -1
	body_sprite.self_modulate = Color(0.75, 0.78, 0.85, 1.0)
	_eye_mat = ShaderMaterial.new()
	_eye_mat.shader = clip_shader
	_eye_mat.set_shader_parameter(&"mask_tex", _mask_tex)
	body_sprite.material = _eye_mat
	add_child(body_sprite)

	var body_area = Area2D.new()
	body_area.collision_layer = 2
	body_area.collision_mask = 1
	body_area.add_to_group(&"boss")
	body_area.name = "BodyArea"
	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = body_collision_radius
	col.name = "BodyCol"
	body_area.add_child(col)
	body_area.area_entered.connect(_on_body_area_entered)
	add_child(body_area)


func _load_variant_tex(primary: String, fallback: String) -> Texture2D:
	if ResourceLoader.exists(primary):
		return load(primary)
	return load(fallback)
