shader_type canvas_item;
// 受击闪白：命中瞬间把精灵不透明部分混合到高亮色，flash 由脚本 tween 0→1→0。
// 仅作用于不透明像素，保留透明边缘；不改变形状，适配任意贴图。

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// 不透明主体混到高亮色（打击闪白更醒目），alpha 保持原样避免透明边泛白
	vec3 rgb = mix(tex.rgb, flash_color.rgb, clamp(flash, 0.0, 1.0));
	COLOR = vec4(rgb, tex.a) * COLOR;
}
