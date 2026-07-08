extends GPUParticles2D
## 玩家推进器尾焰：单一持续粒子系统，local_coords 随机体旋转始终朝机尾喷。
## 程序化构建材质（避免手写 .tscn 材质出错）；加色发光，青白色配玩家阵营色。
## 恒定开销、零逐死亡分配。挂在玩家机尾（局部 +Y 方向）。

const AMOUNT := 26
const LIFETIME := 0.34


func _ready() -> void:
	amount = AMOUNT
	lifetime = LIFETIME
	local_coords = true          # 火焰随机体旋转，始终朝机尾
	texture = _make_dot()
	process_material = _make_process_material()
	var cim := CanvasItemMaterial.new()
	cim.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = cim
	emitting = true


func _make_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	return t


func _make_process_material() -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 3.0
	pm.direction = Vector3(0, 1, 0)     # 局部 +Y = 机尾方向
	pm.spread = 15.0
	pm.initial_velocity_min = 130.0
	pm.initial_velocity_max = 200.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.5
	pm.scale_max = 0.9

	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 1.0))
	sc.add_point(Vector2(1.0, 0.0))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct

	var cr := Gradient.new()
	cr.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	cr.add_point(0.4, Color(0.32, 0.91, 1.0, 0.9))
	cr.set_color(1, Color(0.32, 0.91, 1.0, 0.0))
	var crt := GradientTexture1D.new()
	crt.gradient = cr
	pm.color_ramp = crt

	return pm
