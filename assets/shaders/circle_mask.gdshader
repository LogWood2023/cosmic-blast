shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float feather : hint_range(0.0, 0.2) = 0.01;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	float alpha = 1.0 - smoothstep(radius - feather, radius, dist);
	vec4 tex_color = texture(TEXTURE, UV) * COLOR;
	tex_color.a *= alpha;
	COLOR = tex_color;
}
