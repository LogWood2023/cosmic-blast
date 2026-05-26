shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 4.0) = 0.0;
uniform float glow_size : hint_range(0.0, 0.05) = 0.008;
uniform int glow_spread : hint_range(1, 10) = 5;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	float blur_a = 0.0;
	float total_weight = 0.0;

	for (int r = 1; r <= 10; r++) {
		if (r > glow_spread) break;
		float radius = glow_size * float(r);
		float weight = 1.0 / float(r);
		for (int i = 0; i < 8; i++) {
			float angle = float(i) * 3.14159265 * 2.0 / 8.0;
			vec2 offset = vec2(cos(angle), sin(angle)) * radius;
			blur_a += texture(TEXTURE, UV + offset).a * weight;
		}
		total_weight += weight * 8.0;
	}
	total_weight = max(total_weight, 0.0001);
	blur_a /= total_weight;

	float glow = blur_a * (1.0 - base.a);
	glow = clamp(glow, 0.0, 1.0);
	float final_glow = glow * glow_intensity;
	vec3 hdr_glow = glow_color.rgb * final_glow;
	COLOR = (vec4(base.rgb + hdr_glow, base.a + final_glow * glow_color.a)) * COLOR;
}
