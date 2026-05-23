shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.2;

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv) * 1.414;
	float alpha = 1.0 - smoothstep(0.0, 1.0, dist);
	vec4 tex = texture(TEXTURE, UV);
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float final_alpha = alpha * intensity * (0.5 + 0.5 * pulse);
	COLOR = tex * final_alpha;
}
