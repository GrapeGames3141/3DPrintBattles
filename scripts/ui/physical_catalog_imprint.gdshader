shader_type canvas_item;
// Paper ink treatment: alpha-aware transparent creatures retain clean edges while
// opaque support art receives a deterministic light/chroma matte removal.
uniform vec4 ink_tint : source_color = vec4(0.19, 0.12, 0.07, 1.0);
uniform bool remove_dark_matte = false;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float lightness = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float chroma = max(source.r, max(source.g, source.b)) - min(source.r, min(source.g, source.b));
	float edge = abs(lightness - dot(texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114))) + abs(lightness - dot(texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).rgb, vec3(0.299, 0.587, 0.114)));
	float opaque_matte = smoothstep(0.82, 0.98, lightness) * (1.0 - smoothstep(0.025, 0.14, chroma));
	// Some existing support art has a black/near-neutral opaque canvas. Remove
	// only low-chroma, low-luminance, low-edge fields so dark ink linework survives.
	float dark_matte = (1.0 - smoothstep(0.035, 0.20, lightness)) * (1.0 - smoothstep(0.025, 0.13, chroma)) * (1.0 - smoothstep(0.025, 0.12, edge));
	float alpha = source.a * (1.0 - max(opaque_matte * 0.88, dark_matte * 0.96 * float(remove_dark_matte)));
	vec3 printed = mix(ink_tint.rgb, source.rgb, 0.52);
	COLOR = vec4(printed, alpha * 0.82);
}
