shader_type canvas_item;

uniform float outline_width : hint_range(0.5, 48.0) = 40.0;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 texel = 1.0 / vec2(textureSize(TEXTURE, 0)) * outline_width;

	float max_alpha = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			if (x == 0 && y == 0) continue;
			max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(float(x), float(y)) * texel).a);
		}
	}

	if (col.a > 0.01) {
		COLOR = col;
	} else if (max_alpha > 0.01) {
		COLOR = outline_color;
	} else {
		COLOR = vec4(0.0);
	}
}
