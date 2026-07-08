class_name HitFlashFx
## 受击闪白共用工具 —— BaseEnemy / DesignedEnemy / BossBase / Player 统一入口。
## 懒挂 hit_flash shader；材质已被其它特效（神使传送、故障叠加等）占用时本次跳过，
## 避免对不含 flash 参数的材质 tween 报错。

const SHADER := preload("res://assets/shaders/hit_flash.gdshader")
const DURATION := 0.09
const _TWEEN_META := &"hit_flash_tween"


static func flash(sprite: CanvasItem) -> void:
	if sprite == null or not is_instance_valid(sprite) or not sprite.is_inside_tree():
		return
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		sprite.material = mat
	elif mat.shader != SHADER:
		return
	var prev = sprite.get_meta(_TWEEN_META, null)
	if prev is Tween and prev.is_valid():
		prev.kill()
	mat.set_shader_parameter(&"flash", 1.0)
	var tw := sprite.create_tween()
	tw.tween_property(mat, "shader_parameter/flash", 0.0, DURATION)
	sprite.set_meta(_TWEEN_META, tw)
