extends GPUParticles2D
## 矿石回收粒子尾迹：挂在飞向玩家的回收光点上，飞行途中撒下微光火花。
## 叠加在既有 Line2D 流光之上，把拾取流光升级为粒子版。
## 性能：材质/纹理静态共享（只构建一次）；颜色用 self_modulate 逐实例着色（矿石色）。

const AMOUNT := 18
const LIFETIME := 0.4

static var _shared_pm: ParticleProcessMaterial
static var _shared_tex: GradientTexture2D


func _ready() -> void:
	amount = AMOUNT
	lifetime = LIFETIME
	local_coords = false          # 世界空间：光点飞行时留下尾迹
	texture = _get_tex()
	process_material = _get_pm()
	var cim := CanvasItemMaterial.new()
	cim.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = cim
	emitting = true


static func _get_tex() -> GradientTexture2D:
	if _shared_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		_shared_tex = GradientTexture2D.new()
		_shared_tex.gradient = g
		_shared_tex.fill = GradientTexture2D.FILL_RADIAL
		_shared_tex.fill_from = Vector2(0.5, 0.5)
		_shared_tex.fill_to = Vector2(1.0, 0.5)
		_shared_tex.width = 16
		_shared_tex.height = 16
	return _shared_tex


static func _get_pm() -> ParticleProcessMaterial:
	if _shared_pm == null:
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		pm.direction = Vector3(1, 0, 0)
		pm.spread = 180.0
		pm.initial_velocity_min = 10.0
		pm.initial_velocity_max = 45.0
		pm.damping_min = 20.0
		pm.damping_max = 50.0
		pm.gravity = Vector3.ZERO
		pm.scale_min = 0.15
		pm.scale_max = 0.32

		var sc := Curve.new()
		sc.add_point(Vector2(0.0, 1.0))
		sc.add_point(Vector2(1.0, 0.0))
		var sct := CurveTexture.new()
		sct.curve = sc
		pm.scale_curve = sct

		# 白→透明；实例侧用 self_modulate 着成矿石色
		var cr := Gradient.new()
		cr.set_color(0, Color(1, 1, 1, 1))
		cr.set_color(1, Color(1, 1, 1, 0))
		var crt := GradientTexture1D.new()
		crt.gradient = cr
		pm.color_ramp = crt

		_shared_pm = pm
	return _shared_pm
