shader_type canvas_item;

uniform float strength = 0.018;
uniform float wave_scale = 22.0;
uniform float wave_speed = 4.8;
uniform vec4 tint : source_color = vec4(0.72, 0.54, 1.0, 1.0);
uniform float tint_amount = 0.18;

void fragment() {
	vec2 uv = UV;
	float wave_a = sin((uv.y * wave_scale) + TIME * wave_speed);
	float wave_b = cos((uv.x * wave_scale * 0.73) - TIME * wave_speed * 1.31);
	vec2 offset = vec2(wave_a, wave_b) * strength;
	vec4 color = texture(TEXTURE, uv + offset);
	color.rgb = mix(color.rgb, color.rgb * tint.rgb, tint_amount);
	COLOR = color * COLOR;
}
