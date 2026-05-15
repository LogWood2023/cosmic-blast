shader_type canvas_item;
// 遮罩着色器：将纹理亮度转为 alpha，用于 clip_children
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float brightness = (c.r + c.g + c.b) / 3.0;
	COLOR = vec4(1.0, 1.0, 1.0, brightness);
}
