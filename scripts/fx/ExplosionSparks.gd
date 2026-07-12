extends GPUParticles2D
## 爆炸火花：一次性向外迸射的高亮火星，配合冲击环/亮闪。
## 性能关键——ParticleProcessMaterial 与纹理用静态共享（只构建一次），
## 每次爆炸仅实例一个引用共享资源的节点，避免逐爆炸分配材质。one_shot 完成即自毁。

const AMOUNT := 14
const LIFETIME := 0.42

static var _shared_pm: ParticleProcessMaterial
static var _shared_tex: GradientTexture2D


func _ready() -> void:
	one_shot = true
	explosiveness = 1.0
	add_to_group(&"quality_particles")
	apply_quality()
	lifetime = LIFETIME
	local_coords = false          # 世界空间：火花迸射后独立于发射点
	texture = _get_tex()
	process_material = _get_pm()
	var cim := CanvasItemMaterial.new()
	cim.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = cim
	emitting = true
	finished.connect(queue_free)


func apply_quality() -> void:
	amount = AMOUNT if not SettingsManager.reduced_effects else 6


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
		pm.spread = 180.0             # 全向迸射
		pm.initial_velocity_min = 180.0
		pm.initial_velocity_max = 380.0
		pm.damping_min = 60.0
		pm.damping_max = 130.0        # 迅速减速，火星拖尾后停住
		pm.gravity = Vector3.ZERO
		pm.scale_min = 0.18
		pm.scale_max = 0.4

		var sc := Curve.new()
		sc.add_point(Vector2(0.0, 1.0))
		sc.add_point(Vector2(1.0, 0.0))
		var sct := CurveTexture.new()
		sct.curve = sc
		pm.scale_curve = sct

		var cr := Gradient.new()
		cr.set_color(0, Color(1.0, 0.98, 0.85, 1.0))
		cr.add_point(0.45, Color(1.0, 0.62, 0.25, 0.95))
		cr.set_color(1, Color(1.0, 0.35, 0.2, 0.0))
		var crt := GradientTexture1D.new()
		crt.gradient = cr
		pm.color_ramp = crt

		_shared_pm = pm
	return _shared_pm
