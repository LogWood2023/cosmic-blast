shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float strength = 1.0;
uniform float red_tint = 0.38;
uniform vec3 tint_color = vec3(1.0, 0.04, 0.02);
uniform vec3 tear_boost_color = vec3(1.0, 0.04, 0.02);
uniform float channel_offset = 0.006;
uniform float tear_strength = 0.018;
uniform float scanline_strength = 0.18;

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME * 18.0;
	float slice = floor(uv.y * 42.0);
	float slice_noise = fract(sin(slice * 37.71 + floor(t) * 11.13) * 43758.5453);
	float tear_gate = step(0.76, slice_noise);
	float tear = (slice_noise - 0.5) * tear_strength * strength * tear_gate;
	float wave = sin(uv.y * 95.0 + TIME * 34.0) * 0.0035 * strength;
	vec2 base_uv = uv + vec2(tear + wave, 0.0);
	float offset = channel_offset * strength * (0.5 + tear_gate);

	float r = texture(screen_texture, base_uv + vec2(offset, 0.0)).r;
	float g = texture(screen_texture, base_uv).g;
	float b = texture(screen_texture, base_uv - vec2(offset, 0.0)).b;
	vec3 color = vec3(r, g, b);

	float scanline = sin(uv.y * 1080.0 * 1.35 + TIME * 38.0) * 0.5 + 0.5;
	color *= 1.0 - scanline * scanline_strength * strength;
	color = mix(color, tint_color, red_tint * strength);
	color += tear_boost_color * 0.12 * strength * tear_gate;
	COLOR = vec4(color, 1.0);
}
