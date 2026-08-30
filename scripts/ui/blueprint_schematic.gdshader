shader_type canvas_item;

// Derives a cyan technical-ink reading from an existing runtime texture.
// No text is rasterized: labels remain native controls in main.gd.
uniform vec4 ink_color : source_color = vec4(0.30, 0.93, 1.0, 1.0);

float luminance(vec3 value) {
	return dot(value, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float center = luminance(source.rgb);
	float right = luminance(texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).rgb);
	float down = luminance(texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).rgb);
	float edge = clamp(abs(center - right) + abs(center - down) * 1.8, 0.0, 1.0);
	float ink = clamp(center * 0.13 + edge * 1.65, 0.0, 1.0);
	COLOR = vec4(ink_color.rgb * ink, source.a);
}
