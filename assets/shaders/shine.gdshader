shader_type canvas_item;

uniform float speed : hint_range(0.1, 5.0) = 0.6;
uniform float stripe_width : hint_range(0.01, 0.5) = 0.12;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float diag = UV.x * 0.707 + UV.y * 0.707;
	float stripe = 1.0 - smoothstep(0.0, stripe_width, abs(fract(diag + TIME * speed) - 0.5));
	float alpha = stripe * tex.a * brightness;
	COLOR = vec4(1.0, 1.0, 1.0, alpha);
}
