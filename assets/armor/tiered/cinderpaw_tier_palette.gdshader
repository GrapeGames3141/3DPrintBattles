shader_type canvas_item;

// Per-master offline masks are derived from signature-blue plate candidates,
// then component-curated against each source master. Sampling them here keeps
// natural blue skin, fins, and feathers byte-stable at runtime.
uniform vec4 plate_shadow : source_color = vec4(0.07, 0.11, 0.15, 1.0);
uniform vec4 plate_primary : source_color = vec4(0.23, 0.32, 0.40, 1.0);
uniform vec4 plate_highlight : source_color = vec4(0.60, 0.70, 0.75, 1.0);
uniform sampler2D plate_mask_texture : filter_linear, repeat_disable;
uniform vec4 core_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float core_installed = 0.0;
// The authored signature-green stone has dark antialiased edge facets. Keep
// the thresholds intentionally inclusive: green is unique to the gemstone.
uniform float gem_mask_min_saturation = 0.012;
uniform float gem_mask_min_green_dominance = 0.006;
// Every approved master keeps its gem's material-derived green signature, but
// natural green/cyan identity materials are protected by this registry-driven
// measured helmet-local ellipse. It is geometric metadata, not a painted mask.
uniform vec2 gem_anchor = vec2(0.694, 0.241);
uniform vec2 gem_radius = vec2(0.045, 0.060);

float gemstone_material_mask(vec3 color) {
	float brightest = max(color.r, max(color.g, color.b));
	float darkest = min(color.r, min(color.g, color.b));
	float saturation = brightest - darkest;
	float green_dominance = color.g - max(color.r, color.b);
	return smoothstep(gem_mask_min_saturation, gem_mask_min_saturation + 0.028, saturation)
		* smoothstep(gem_mask_min_green_dominance, gem_mask_min_green_dominance + 0.029, green_dominance);
}

float helmet_gem_region_mask(vec2 uv) {
	vec2 safe_radius = max(gem_radius, vec2(0.001));
	vec2 delta = (uv - gem_anchor) / safe_radius;
	return 1.0 - smoothstep(0.82, 1.0, dot(delta, delta));
}

vec3 luminance_palette(float source_luminance, vec3 shadow, vec3 primary, vec3 highlight) {
	vec3 remapped = mix(shadow, primary, smoothstep(0.10, 0.72, source_luminance));
	return mix(remapped, highlight, smoothstep(0.63, 0.95, source_luminance) * 0.56);
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float mask = texture(plate_mask_texture, UV).r;
	float luminance = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 recolored = luminance_palette(luminance, plate_shadow.rgb, plate_primary.rgb, plate_highlight.rgb);
	vec3 armor_colored = mix(source.rgb, recolored, mask);
	// The v3 master authors a saturated signature-green stone. Green dominance
	// selects every gemstone facet without a hand-painted mask, leaving the
	// silver bezel and blue helmet untouched.
	float gem_mask = gemstone_material_mask(source.rgb) * helmet_gem_region_mask(UV);
	vec3 neutral_shadow = vec3(0.10, 0.12, 0.15);
	vec3 neutral_primary = vec3(0.34, 0.37, 0.41);
	vec3 neutral_highlight = vec3(0.78, 0.81, 0.84);
	vec3 gem_shadow = mix(vec3(0.025, 0.04, 0.07), core_tint.rgb, 0.29);
	vec3 gem_primary = mix(vec3(0.07, 0.10, 0.16), core_tint.rgb, 0.80);
	vec3 gem_highlight = mix(core_tint.rgb, vec3(1.0), 0.68);
	vec3 gem_colored = luminance_palette(luminance, mix(neutral_shadow, gem_shadow, core_installed), mix(neutral_primary, gem_primary, core_installed), mix(neutral_highlight, gem_highlight, core_installed));
	COLOR = vec4(mix(armor_colored, gem_colored, gem_mask), source.a);
}
