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

void fragment() {
	vec2 uv = UV;
	vec2 local = (uv - region.xy) / region.zw;
	if (flip > 0.5) {
		local.x = 1.0 - local.x;
		uv.x = region.x + local.x * region.z;
	}
	vec4 c = texture(TEXTURE, uv);
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
