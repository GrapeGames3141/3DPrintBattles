shader_type canvas_item;
// Draws a creature as if it were being 3D printed: it appears layer by layer
// from the bed upward in raw single-colour filament, then floods with colour.
// Also carries the hit flash and the "jammed" frost tint.

uniform float progress = 1.0;   // 0..1 height printed so far
uniform float colorize = 1.0;   // 0 raw filament, 1 finished colours
uniform vec4 filament : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float flash = 0.0;
uniform float frost = 0.0;
uniform float dim = 0.0;
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0); // atlas cell in UV: x, y, w, h
uniform float flip = 0.0;
uniform float hue_shift = 0.0;  // the card's paint: turns, saturation, brightness
uniform float sat_mul = 1.0;
uniform float val_mul = 1.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec2 uv = UV;
	vec2 local = (uv - region.xy) / region.zw;
	if (flip > 0.5) {
		local.x = 1.0 - local.x;
		uv.x = region.x + local.x * region.z;
	}
	vec4 c = texture(TEXTURE, uv);
	if (hue_shift != 0.0 || sat_mul != 1.0 || val_mul != 1.0) {
		vec3 hsv = rgb2hsv(c.rgb);
		hsv.x = fract(hsv.x + hue_shift);
		hsv.y = clamp(hsv.y * sat_mul, 0.0, 1.0);
		hsv.z = clamp(hsv.z * val_mul, 0.0, 1.0);
		c.rgb = hsv2rgb(hsv);
	}
	float h = 1.0 - local.y;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));

	vec3 raw = filament.rgb * (0.30 + lum * 1.05);
	raw *= 0.86 + 0.14 * step(0.5, fract(h * 56.0));
	vec3 col = mix(raw, c.rgb, colorize);
	col = mix(col, vec3(0.55, 0.85, 1.0) * (0.45 + lum * 0.8), frost * 0.65);
	col = mix(col, vec3(lum) * 0.55, dim);
	col = mix(col, vec3(1.0), flash);

	float printing = step(progress, 0.999);
	float hot = smoothstep(0.03, 0.0, abs(h - progress)) * printing;
	col += vec3(1.0, 0.72, 0.25) * hot * 1.6;

	COLOR = vec4(col, c.a * step(h, progress));
}
