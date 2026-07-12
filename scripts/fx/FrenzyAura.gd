extends GPUParticles2D
## 狂热光环：狂热激活时玩家周身环形能量涡旋（粒子绕机体轨道旋转），平时熄灭。
## 轮询 GameManager.frenzy_active 开关 emitting。加色琥珀→红，配"炽热/暴走"意象。
## 单一系统、仅狂热期间发射、零逐死亡分配。

const AMOUNT := 44
const LIFETIME := 0.6


func _ready() -> void:
	add_to_group(&"quality_particles")
	apply_quality()
	lifetime = LIFETIME
	local_coords = true          # 涡旋随机体移动，围绕机身
	emitting = false
	texture = _make_dot()
	process_material = _make_process_material()
	var cim := CanvasItemMaterial.new()
	cim.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = cim


func apply_quality() -> void:
	amount = AMOUNT if not SettingsManager.reduced_effects else 18


func _process(_delta: float) -> void:
	# 幂等：狂热期间持续发射，结束即停（已发射粒子自然消散）
	emitting = GameManager.frenzy_active


func _make_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 24
	t.height = 24
	return t


func _make_process_material() -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3(0, 0, 1)
	pm.emission_ring_radius = 32.0
	pm.emission_ring_inner_radius = 24.0
	pm.emission_ring_height = 0.0
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 30.0
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 24.0
	pm.orbit_velocity_min = 0.45     # 绕机体轨道旋转（turns/s），形成涡旋
	pm.orbit_velocity_max = 0.85
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.4
	pm.scale_max = 0.75

	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.7))
	sc.add_point(Vector2(0.25, 1.0))
	sc.add_point(Vector2(1.0, 0.0))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct

	var cr := Gradient.new()
	cr.set_color(0, Color(1.0, 0.85, 0.45, 0.95))
	cr.add_point(0.5, Color(1.0, 0.55, 0.22, 0.85))
	cr.set_color(1, Color(1.0, 0.28, 0.34, 0.0))
	var crt := GradientTexture1D.new()
	crt.gradient = cr
	pm.color_ramp = crt

	return pm
