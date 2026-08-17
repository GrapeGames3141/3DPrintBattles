shader_type canvas_item;
render_mode blend_add;

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float intensity = 1.0;

float authored_gem_exclusion(vec2 uv) {
	// Every image-authored cell contains a white guide-diamond at its exact
	// center. The underlying helmet master now supplies the only colored gem;
	// retain just the atlas halo/star/spark energy around it.
	vec2 delta = abs(uv - vec2(0.5));
	float diamond = delta.x + delta.y * 0.72;
	return 1.0 - smoothstep(0.115, 0.165, diamond);
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float brightness = max(source.r, max(source.g, source.b));
	float visible = smoothstep(0.015, 0.12, brightness) * source.a * (1.0 - authored_gem_exclusion(UV));
	// Atlas black is mathematically inert: no emitted light and no alpha.
	COLOR = vec4(core_color.rgb * brightness * intensity, visible * intensity);
}
