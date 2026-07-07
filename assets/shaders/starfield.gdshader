shader_type canvas_item;
// 程序化深空星域背景：垂直渐变 + fbm 星云 + 三层向下漂移的星点。
// 配色锚定项目九色板(深空蓝黑 + 青白星点)。不依赖任何贴图，任意分辨率清晰。

uniform vec3 top_color : source_color = vec3(0.012, 0.027, 0.047);    // 近黑深蓝 (~#03070c)
uniform vec3 bottom_color : source_color = vec3(0.027, 0.063, 0.094); // 深空蓝 (~#071018)
uniform vec3 nebula_color : source_color = vec3(0.28, 0.42, 0.72);    // 冷青紫星云
uniform vec3 nebula_warm : source_color = vec3(0.55, 0.35, 0.55);     // 暖紫过渡
uniform float nebula_strength : hint_range(0.0, 0.5) = 0.14;
uniform float scroll_speed : hint_range(0.0, 0.2) = 0.02;
uniform vec3 star_color : source_color = vec3(0.82, 0.90, 1.0);
uniform float aspect = 1.7777;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		v += amp * vnoise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return v;
}

// 单层星点：稀疏网格，每格随机一颗，随机亮度与闪烁
float star_layer(vec2 uv, float density, float bright, float tw) {
	vec2 g = uv * density;
	vec2 id = floor(g);
	vec2 gv = fract(g) - 0.5;
	float h = hash21(id);
	if (h < 0.965) {
		return 0.0;
	}
	vec2 offs = vec2(hash21(id + 1.7), hash21(id + 3.3)) - 0.5;
	float d = length(gv - offs * 0.7);
	float core = smoothstep(0.09, 0.0, d) * bright;
	float twinkle = 0.65 + 0.35 * sin(TIME * tw + h * 6.2831);
	return core * twinkle;
}

void fragment() {
	vec2 uv = UV;
	vec3 col = mix(top_color, bottom_color, uv.y);

	// 星云：两层 fbm 叠加，缓慢上移
	vec2 nuv = uv * vec2(aspect, 1.0) * 2.4 + vec2(0.0, TIME * scroll_speed * 0.4);
	float neb = fbm(nuv);
	float neb2 = fbm(nuv * 1.9 + 7.0);
	float nmask = smoothstep(0.45, 0.95, neb);
	vec3 neb_col = mix(nebula_color, nebula_warm, neb2);
	col += neb_col * nmask * nebula_strength;

	// 三层星点，速度递增形成纵深
	vec2 suv = vec2(uv.x * aspect, uv.y);
	float s = 0.0;
	s += star_layer(suv + vec2(0.0, -TIME * scroll_speed * 1.0), 26.0, 0.45, 1.8);
	s += star_layer(suv + vec2(11.3, -TIME * scroll_speed * 2.2), 44.0, 0.75, 2.6);
	s += star_layer(suv + vec2(23.9, -TIME * scroll_speed * 4.0), 68.0, 1.0, 3.6);
	col += star_color * s;

	COLOR = vec4(col, 1.0);
}
