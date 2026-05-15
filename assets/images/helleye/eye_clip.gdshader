shader_type canvas_item;

uniform sampler2D mask_tex;
uniform vec2 mask_scale = vec2(1.0);
uniform float mask_rotation = 0.0;
uniform vec2 mask_offset_uv = vec2(0.0);
uniform vec2 content_scale = vec2(1.0);
uniform vec2 content_offset = vec2(0.0);

void fragment() {
	vec2 centered = UV - 0.5;
	float cr = cos(mask_rotation);
	float sr = sin(mask_rotation);
	vec2 rotated = vec2(centered.x * cr - centered.y * sr, centered.x * sr + centered.y * cr);
	vec2 scaled = rotated * mask_scale;
	vec2 mask_uv = scaled + 0.5 + mask_offset_uv;
	mask_uv = clamp(mask_uv, 0.0, 1.0);
	float mask_a = texture(mask_tex, mask_uv).a;
	vec2 tex_uv = (UV - 0.5) * content_scale + 0.5 + content_offset;
	vec4 c = texture(TEXTURE, tex_uv);
	COLOR = vec4(c.rgb, c.a * mask_a);
}
