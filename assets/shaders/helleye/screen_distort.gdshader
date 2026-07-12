shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength = 3.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME * 2.0;
	uv.x += sin(uv.y * 20.0 + t) * 0.008 * strength;
	uv.y += cos(uv.x * 20.0 + t * 1.3) * 0.008 * strength;
	vec4 c = texture(screen_texture, clamp(uv, vec2(0.001), vec2(0.999)));
	c.rgb = mix(c.rgb, vec3(0.35, 0.02, 0.02), 0.3 * strength / 3.0);
	COLOR = c;
}
