shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform vec4 wood_albedo : source_color = vec4(0.34, 0.2, 0.11, 1.0);
uniform float crack_scale : hint_range(1.0, 32.0) = 12.0;
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.35;
uniform float emission_strength : hint_range(0.0, 10.0) = 3.2;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 uv) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	mat2 rot = mat2(vec2(0.86, 0.5), vec2(-0.5, 0.86));
	for (int i = 0; i < 5; i++) {
		v += a * noise(uv);
		uv = rot * uv * 2.05 + shift;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * crack_scale;
	float n = fbm(uv);
	float ridges = fbm(uv * 2.3 + vec2(n * 1.7, sin(uv.y * 4.1)));
	float cracks = smoothstep(0.72, 0.92, ridges) * smoothstep(0.15, 0.55, n);
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float hue_wave = TIME * pulse_speed * 0.7 + (UV.x + UV.y) * 3.14159;
	vec3 filament = vec3(
		sin(hue_wave) * 0.5 + 0.5,
		sin(hue_wave + 2.094) * 0.5 + 0.5,
		sin(hue_wave + 4.188) * 0.5 + 0.5
	);
	vec3 base = wood_albedo.rgb * (0.82 + 0.18 * n);
	ALBEDO = mix(base, vec3(0.06, 0.05, 0.08), cracks * 0.45);
	EMISSION = filament * cracks * emission_strength * (0.25 + 0.75 * pulse);
	ROUGHNESS = 0.78;
	METALLIC = 0.04;
}
