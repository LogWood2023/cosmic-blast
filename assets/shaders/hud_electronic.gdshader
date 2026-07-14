shader_type canvas_item;
render_mode unshaded;

// 共享给左下 HUD 的所有可见图层；SCREEN_UV 让各节点的电子纹理保持同相。
uniform float scanline_strength : hint_range(0.0, 0.2, 0.005) = 0.055;
uniform float static_strength : hint_range(0.0, 0.3, 0.005) = 0.085;
uniform vec4 electron_color : source_color = vec4(0.20, 0.92, 1.0, 1.0);


float _hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}


void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float scanline = 1.0 - scanline_strength * (0.5 + 0.5 * sin(SCREEN_UV.y * 920.0 + TIME * 18.0));
	float sweep_y = fract(TIME * 0.19);
	float sweep = 1.0 - smoothstep(0.0, 0.045, abs(SCREEN_UV.y - sweep_y));
	float noise = _hash21(floor(SCREEN_UV * vec2(960.0, 540.0)) + floor(TIME * 12.0));
	float static_flash = step(0.992, noise) * static_strength;
	float electron = (sweep * 0.16 + static_flash) * source.a;
	source.rgb *= scanline;
	source.rgb += electron_color.rgb * electron;
	COLOR = source;
}
