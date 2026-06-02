shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float vignette_strength = 0.0;
uniform float vignette_spread = 1.0;
uniform float glitch_strength = 0.0;
uniform float tint_strength = 0.0;
uniform bool flip_vertical = false;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 sample_uv = uv;
	if (flip_vertical) {
		sample_uv.y = 1.0 - sample_uv.y;
	}

	float slice = floor(uv.y * 38.0);
	float noise = fract(sin(slice * 41.73 + floor(TIME * 18.0) * 9.17) * 43758.5453);
	float tear_gate = step(0.82, noise);
	float tear = (noise - 0.5) * 0.012 * glitch_strength * tear_gate;
	float wave = sin(uv.y * 82.0 + TIME * 24.0) * 0.0025 * glitch_strength;
	vec2 distorted_uv = clamp(sample_uv + vec2(tear + wave, 0.0), vec2(0.001), vec2(0.999));

	float channel_offset = 0.0035 * glitch_strength * (0.5 + tear_gate);
	float r = texture(screen_texture, clamp(distorted_uv + vec2(channel_offset, 0.0), vec2(0.001), vec2(0.999))).r;
	float g = texture(screen_texture, distorted_uv).g;
	float b = texture(screen_texture, clamp(distorted_uv - vec2(channel_offset, 0.0), vec2(0.001), vec2(0.999))).b;
	vec3 color = vec3(r, g, b);

	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(luma), 0.16 * glitch_strength);
	color = mix(color, vec3(0.0), tint_strength + tear_gate * 0.08 * glitch_strength);

	float dist = distance(uv, vec2(0.5, 0.5));
	float inner = mix(0.36, 0.18, clamp(vignette_spread - 1.0, 0.0, 1.0));
	float outer = mix(0.76, 0.58, clamp(vignette_spread - 1.0, 0.0, 1.0));
	float vignette = smoothstep(inner, outer, dist) * vignette_strength;
	color = mix(color, vec3(0.0), vignette);

	COLOR = vec4(color, 1.0);
}
