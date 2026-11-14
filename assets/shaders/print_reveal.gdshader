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
// Death: `crumble` runs 0..1. Each kind breaks a print up its own way:
// 0 layers slide apart, 1 burns to ash, 2 melts, 3 glitches out, 4 withers,
// 5 freezes and shatters, 6 crumbles to rubble, 7 blows away, 8 implodes.
uniform float crumble = 0.0;
uniform int crumble_kind = 0;
uniform float crumble_seed = 0.0;
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


float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Pieces of the print as tiles on a grid. Every tile flies off on its own;
// this finds which tile covers the pixel `l` now and where it came from.
// `fall` is how far tiles drop, `spread` how far they fly apart, `lag` how
// much the top goes first.
vec3 tile_source(vec2 l, vec2 g, float p, float seed, float fall, float spread, float lag) {
	vec2 here = floor(l * g);
	for (int dy = -3; dy <= 3; dy++) {
		for (int dx = -2; dx <= 2; dx++) {
			vec2 id = here + vec2(float(dx), float(dy));
			if (id.x < 0.0 || id.y < 0.0 || id.x >= g.x || id.y >= g.y) {
				continue;
			}
			float r = hash21(id + seed);
			float q = clamp((p - (id.y / g.y) * lag - r * 0.15) / (1.0 - lag - 0.15), 0.0, 1.0);
			vec2 out_dir = normalize((id + 0.5) / g - vec2(0.5, 0.55) + 0.001);
			vec2 off = out_dir * spread * q * (0.4 + r) + vec2((r - 0.5) * 0.1 * q, fall * q * q);
			vec2 src = l - off;
			if (floor(src * g) == id) {
				return vec3(src, q);
			}
		}
	}
	return vec3(-1.0, -1.0, 1.0);
}

void fragment() {
	vec2 local = (UV - region.xy) / region.zw;
	float h = 1.0 - local.y;
	float cr_alpha = 1.0;
	float cr_dark = 0.0;
	float cr_raw = 0.0;
	float cr_tint = 0.0;
	float cr_frost = 0.0;
	vec3 cr_glow = vec3(0.0);
	if (crumble > 0.0) {
		float p = crumble;
		float sd = crumble_seed;
		vec2 l = local;
		if (crumble_kind == 0) {
			// Layers: the print comes apart the way it was made, slice by slice.
			float n = 18.0 + floor(hash11(sd) * 10.0);
			float i = floor((1.0 - l.y) * n);
			float r = hash11(i + sd * 17.0);
			float dir = mod(i, 2.0) < 0.5 ? 1.0 : -1.0;
			float q = clamp((p - (1.0 - i / n) * 0.45) / 0.55, 0.0, 1.0);
			l.x -= dir * q * q * (0.25 + r * 0.3);
			l.y -= q * q * 0.12;
			cr_alpha *= 1.0 - smoothstep(0.55, 1.0, q);
			cr_raw = smoothstep(0.0, 0.5, q);
		} else if (crumble_kind == 1) {
			// Ash: a burn front eats it from the noise outward.
			float n = vnoise(l * vec2(7.0, 9.0) + sd * 31.0) * 0.7 + vnoise(l * 23.0 + sd) * 0.3;
			float thr = p * 1.3 - 0.12;
			cr_alpha *= step(thr, n);
			float edge = smoothstep(0.10, 0.0, abs(n - thr));
			cr_glow = vec3(1.0, 0.45, 0.08) * edge * 2.2;
			cr_dark = smoothstep(0.0, 0.7, p) * 0.75;
			l.y += p * 0.03;
		} else if (crumble_kind == 2) {
			// Melt: it slumps into a puddle on the bed.
			float sq = 1.0 - 0.9 * smoothstep(0.0, 0.85, p);
			l.y = 1.0 - (1.0 - l.y) / sq;
			l.x = 0.5 + (l.x - 0.5) / (1.0 + 1.4 * (1.0 - sq));
			l.x += sin(l.y * 22.0 + p * 20.0) * 0.012 * p;
			cr_tint = smoothstep(0.0, 0.6, p);
			cr_alpha *= 1.0 - smoothstep(0.72, 1.0, p);
		} else if (crumble_kind == 3) {
			// Glitch: it tears into scan rows, pixelates and drops out.
			float t = floor(TIME * 28.0);
			float row = floor(l.y * 42.0);
			l.x += (hash21(vec2(row, t + sd)) - 0.5) * 0.3 * min(p * 2.2, 1.0);
			float g = mix(300.0, 9.0 + hash11(sd) * 6.0, smoothstep(0.2, 0.9, p));
			l = floor(l * g) / g;
			float cell = hash21(floor(l * vec2(14.0, 18.0)) + sd);
			cr_alpha *= step(p * 1.15 - 0.1, cell);
			cr_glow = vec3(1.0, 0.95, 0.4) * step(0.55, hash11(t + sd)) * (1.0 - p) * 0.8;
		} else if (crumble_kind == 4) {
			// Wither: it droops, browns, then blows apart from the top down.
			float d = smoothstep(0.0, 0.55, p);
			float lean = (hash11(sd) < 0.5 ? 1.0 : -1.0);
			l.y = 1.0 - (1.0 - l.y) / (1.0 - 0.3 * d);
			l.x += (1.0 - l.y) * (1.0 - l.y) * 0.3 * d * lean;
			float n = vnoise(l * vec2(8.0, 6.0) + sd * 13.0);
			float t = clamp((p - 0.4) / 0.6, 0.0, 1.0);
			cr_alpha *= step(t * 1.5 - 0.15, l.y + n * 0.25);
			cr_tint = d * 0.6;
			cr_dark = d * 0.25;
		} else if (crumble_kind == 5) {
			// Ice: it frosts over and breaks into shards.
			cr_frost = smoothstep(0.0, 0.3, p);
			vec2 g = vec2(4.0 + floor(hash11(sd) * 3.0), 5.0 + floor(hash11(sd + 3.0) * 3.0));
			vec3 s3 = tile_source(l, g, clamp((p - 0.25) / 0.75, 0.0, 1.0), sd, 0.3, 0.32, 0.0);
			l = s3.xy;
			cr_alpha *= 1.0 - smoothstep(0.55, 1.0, s3.z);
			if (s3.x < 0.0) { cr_alpha = 0.0; }
		} else if (crumble_kind == 6) {
			// Rubble: the print comes down in blocks, top first.
			vec2 g = vec2(4.0 + floor(hash11(sd) * 3.0), 6.0 + floor(hash11(sd + 5.0) * 3.0));
			vec3 s3 = tile_source(l, g, p, sd, 0.5, 0.06, 0.35);
			l = s3.xy;
			cr_alpha *= 1.0 - smoothstep(0.7, 1.0, s3.z);
			cr_dark = s3.z * 0.35;
			if (s3.x < 0.0) { cr_alpha = 0.0; }
		} else if (crumble_kind == 7) {
			// Dust: a gust sweeps it away, left to right.
			float n = vnoise(l * vec2(6.0, 8.0) + sd * 23.0);
			float val = l.x * 0.55 + n * 0.45;
			float t = p * 1.35 - 0.1;
			float reach = clamp(t - val + 0.15, 0.0, 0.4);
			l.x -= reach * 1.4;
			l.y += (n - 0.5) * reach * 0.4;
			cr_alpha *= 1.0 - smoothstep(0.1, 0.4, reach);
			cr_tint = smoothstep(0.0, 0.5, reach) * 0.5;
		} else {
			// Implode: it spins in on itself in a flash of light.
			vec2 c = vec2(0.5, 0.62);
			float k = max(1.0 - p * 0.98, 0.03);
			vec2 d = (l - c) / k;
			float ang = p * 5.0 * (hash11(sd) < 0.5 ? 1.0 : -1.0);
			d = vec2(d.x * cos(ang) - d.y * sin(ang), d.x * sin(ang) + d.y * cos(ang));
			l = c + d;
			cr_glow = vec3(0.65, 0.45, 1.0) * smoothstep(0.1, 1.0, p) * 0.9;
			cr_alpha *= 1.0 - smoothstep(0.88, 1.0, p);
		}
		local = l;
		if (local.x < 0.004 || local.x > 0.996 || local.y < 0.004 || local.y > 0.996) {
			cr_alpha = 0.0;
			local = clamp(local, vec2(0.004), vec2(0.996));
		}
	}
	vec2 uv = UV;
	if (flip > 0.5) {
		local.x = 1.0 - local.x;
	}
	uv = region.xy + local * region.zw;
	vec4 c = texture(TEXTURE, uv);
	if (hue_shift != 0.0 || sat_mul != 1.0 || val_mul != 1.0) {
		vec3 hsv = rgb2hsv(c.rgb);
		hsv.x = fract(hsv.x + hue_shift);
		hsv.y = clamp(hsv.y * sat_mul, 0.0, 1.0);
		hsv.z = clamp(hsv.z * val_mul, 0.0, 1.0);
		c.rgb = hsv2rgb(hsv);
	}
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));

	vec3 raw = filament.rgb * (0.30 + lum * 1.05);
	raw *= 0.86 + 0.14 * step(0.5, fract(h * 56.0));
	vec3 col = mix(raw, c.rgb, colorize);
	col = mix(col, vec3(0.55, 0.85, 1.0) * (0.45 + lum * 0.8), frost * 0.65);
	col = mix(col, vec3(lum) * 0.55, dim);
	col = mix(col, filament.rgb * (0.3 + lum * 1.05), cr_raw);
	col = mix(col, filament.rgb * (0.4 + lum * 0.9), cr_tint);
	col = mix(col, vec3(0.55, 0.85, 1.0) * (0.45 + lum * 0.8), cr_frost * 0.8);
	col = mix(col, col * vec3(0.18, 0.16, 0.15), cr_dark);
	col += cr_glow;
	col = mix(col, vec3(1.0), flash);

	float printing = step(progress, 0.999);
	float hot = smoothstep(0.03, 0.0, abs(h - progress)) * printing;
	col += vec3(1.0, 0.72, 0.25) * hot * 1.6;

	COLOR = vec4(col, c.a * cr_alpha * step(h, progress));
}
