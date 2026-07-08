shader_type canvas_item;
// 低血暗角：屏幕边缘红色渐变，intensity 由脚本按玩家血量设置（血越低越强）。
// 中心区域全透明，不遮挡视野与中央 HUD；带轻微脉动强化濒死紧张感。

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(0.85, 0.06, 0.12, 1.0);

void fragment() {
	float d = distance(UV, vec2(0.5));
	// 中心到边缘的径向渐变（椭圆，随 16:9 视口拉伸，观感自然）
	float v = smoothstep(0.42, 0.78, d);
	float pulse = 0.82 + 0.18 * sin(TIME * 3.2);
	float a = clamp(v * intensity * pulse, 0.0, 1.0);
	COLOR = vec4(edge_color.rgb, a);
}
