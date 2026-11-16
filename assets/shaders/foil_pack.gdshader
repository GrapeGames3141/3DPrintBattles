shader_type canvas_item;
// A sealed foil card pack, drawn whole: crimped ends, a pillowed metallic
// body with creases, the printed art window, and a moving gloss. The same
// shader tears the top strip off: everything above the ragged tear line, up
// to `tear` of the way across, lifts away as one rigid piece.
//
// The node may be larger than the pack (room for the strip to fly); `origin`
// is the pack's top-left corner inside the node, in the node's own pixels.

uniform vec2 rect_size = vec2(336.0, 520.0);
uniform vec2 origin = vec2(0.0);
uniform vec2 pack_size = vec2(336.0, 520.0);
uniform vec3 tint : source_color = vec3(0.25, 0.65, 1.0);
uniform vec3 tint_deep : source_color = vec3(0.06, 0.18, 0.5);
uniform float holo = 0.0;
uniform float tilt = 0.0;

uniform sampler2D art : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 art_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform float art_aspect = 1.0;
uniform float art_fit = 0.92;
uniform float art_raw = 0.0;   // 1 shows the figure as a raw, unpainted print
uniform vec4 window = vec4(38.0, 92.0, 260.0, 260.0);

uniform float tear = 0.0;
uniform float tear_dir = 1.0;
uniform float tear_y = 46.0;
uniform float strip_angle = 0.0;
uniform vec2 strip_offset = vec2(0.0);
uniform float strip_alpha = 1.0;

const float CRIMP = 30.0;
const vec3 PAPER = vec3(0.93, 0.95, 0.97);

// Integer hash: a sine-based one gives different answers for the same lattice
// point on some GPUs, which shows up as hard-edged blocks in the foil.
float hash(vec2 p) {
	uvec2 q = uvec2(ivec2(p)) * uvec2(1597334673u, 3812015801u);
	uint n = (q.x ^ q.y) * 1597334673u;
	return float(n) * (1.0 / 4294967295.0);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float tear_line(float x) {
	return tear_y + (noise(vec2(x * 0.11, 3.7)) - 0.5) * 9.0 + (noise(vec2(x * 0.5, 9.1)) - 0.5) * 4.0;
}

// Coverage of the pouch outline: straight sides, saw-tooth ends.
float pouch(vec2 q, float aa) {
	float teeth = abs(fract(q.x / 12.0) - 0.5) * 10.0;
	float d = min(min(q.y - teeth, pack_size.y - teeth - q.y), min(q.x, pack_size.x - q.x));
	return clamp(d / aa + 0.5, 0.0, 1.0);
}

vec3 foil(vec2 q, float aa) {
	vec2 uv = q / pack_size;
	bool crimp = q.y < CRIMP || q.y > pack_size.y - CRIMP;
	vec3 base = mix(tint, tint_deep, smoothstep(0.05, 1.0, uv.y) * 0.75);
	vec3 n;
	if (crimp) {
		// Heat-sealed strip: flat, with fine ridges pressed across it.
		n = normalize(vec3(sin(q.x * 6.2831 / 6.0) * 0.85, 0.0, 1.0));
		base = mix(base, vec3(0.8, 0.84, 0.9), 0.22);
	} else {
		vec2 c = vec2(uv.x * 2.0 - 1.0, (q.y - CRIMP) / (pack_size.y - 2.0 * CRIMP) * 2.0 - 1.0);
		float ends = c.y * c.y;
		// Creases run out of the seals and fade toward the middle.
		float crease = (noise(vec2(q.x * 0.05, q.y * 0.006)) - 0.5) * (0.16 + 1.0 * ends)
				+ (noise(vec2(q.x * 0.13 + 7.0, q.y * 0.012)) - 0.5) * 0.5 * ends;
		vec2 dent = vec2(noise(q * 0.013 + 3.0), noise(q * 0.013 + 11.0)) - 0.5;
		n = normalize(vec3(c.x * c.x * c.x * 1.1 + crease + dent.x * 0.4,
				pow(abs(c.y), 5.0) * sign(c.y) * 1.3 + dent.y * 0.4, 1.0));
	}
	vec3 light = normalize(vec3(-0.35 + tilt * 0.7, -0.55, 0.78));
	float diff = clamp(dot(n, light), 0.0, 1.0);
	float spec = pow(clamp(dot(n, normalize(light + vec3(0.0, 0.0, 1.0))), 0.0, 1.0), 42.0);
	// Fake chrome: brightness bands that slide as the surface bends.
	float env = 0.5 + 0.5 * sin(n.x * 9.0 + n.y * 4.0 + tilt * 3.0 + 1.0);
	vec3 col = base * (0.3 + 0.55 * diff + 0.38 * env);
	vec3 rainbow = 0.5 + 0.5 * cos(6.2831 * (n.x * 1.4 + uv.y * 0.9 + tilt * 0.6 + TIME * 0.04) + vec3(0.0, 2.1, 4.2));
	col = mix(col, col * (0.55 + rainbow), holo * 0.55);
	float sweep = uv.x + uv.y * 0.3 - (fract(TIME * 0.27) * 2.8 - 0.9);
	float gloss = spec * 0.85 + exp(-sweep * sweep / 0.003) * 0.3;

	// Seal lines where the crimps meet the body.
	float seal = min(abs(q.y - CRIMP), abs(q.y - (pack_size.y - CRIMP)));
	col *= 1.0 - 0.45 * smoothstep(2.0, 0.0, seal);

	// The printed window with the figure in it.
	vec2 half_size = window.zw * 0.5;
	vec2 rel = q - window.xy - half_size;
	vec2 dd = abs(rel) - half_size + 20.0;
	float sd = length(max(dd, 0.0)) + min(max(dd.x, dd.y), 0.0) - 20.0;
	float inside = clamp(0.5 - sd / aa, 0.0, 1.0);
	if (inside > 0.0 && !crimp) {
		float glow = 1.0 - clamp(length(rel / half_size) * 0.8, 0.0, 1.0);
		vec3 back = mix(tint_deep * 0.22, tint * 0.6, glow * glow);
		vec2 grid = abs(fract(rel / 26.0) - 0.5);
		back += tint * 0.16 * smoothstep(0.47, 0.5, max(grid.x, grid.y));
		vec2 a = rel / (window.w * art_fit * vec2(art_aspect, 1.0)) + 0.5;
		if (a.x > 0.0 && a.x < 1.0 && a.y > 0.0 && a.y < 1.0) {
			vec4 fig = texture(art, art_region.xy + a * art_region.zw);
			if (art_raw > 0.5) {
				float lum = dot(fig.rgb, vec3(0.299, 0.587, 0.114));
				fig.rgb = vec3(0.97, 0.98, 1.0) * (0.35 + lum * 0.7) * (0.9 + 0.1 * step(0.5, fract(a.y * 60.0)));
			}
			back = mix(back, fig.rgb, fig.a);
		}
		float rim = smoothstep(5.0, 2.0, -sd);
		back = mix(back, mix(tint, vec3(1.0), 0.6) * (0.55 + 0.6 * env), rim);
		col = mix(col, back, inside);
		gloss *= mix(1.0, 0.45, inside);
	}
	return col + gloss;
}

void fragment() {
	vec2 p = UV * rect_size - origin;
	float aa = max(length(vec2(dFdx(p.x), dFdy(p.x))), 0.0001);
	float front = tear * (pack_size.x + 2.0);
	vec4 result = vec4(0.0);

	float cover = pouch(p, aa);
	if (cover > 0.0) {
		vec3 col = foil(p, aa);
		float keep = 1.0;
		if (tear > 0.0) {
			float line = tear_line(p.x);
			float along = tear_dir > 0.0 ? p.x : pack_size.x - p.x;
			float torn = step(along, front);
			float above = clamp((line - p.y) / aa + 0.5, 0.0, 1.0);
			keep = 1.0 - above * torn;
			// The foil's pale inner layer shows along the ripped edge.
			col = mix(col, PAPER, smoothstep(3.0, 0.0, p.y - line) * torn * 0.85);
		}
		result = vec4(col, cover * keep);
	}

	if (tear > 0.0 && strip_alpha > 0.0) {
		vec2 hinge = vec2(clamp(tear_dir > 0.0 ? front : pack_size.x - front, 0.0, pack_size.x), tear_y);
		float ang = strip_angle * tear_dir;
		vec2 r = p - strip_offset - hinge;
		vec2 src = hinge + vec2(cos(ang) * r.x + sin(ang) * r.y, -sin(ang) * r.x + cos(ang) * r.y);
		float cover2 = pouch(src, aa);
		if (cover2 > 0.0) {
			float line = tear_line(src.x);
			float along = tear_dir > 0.0 ? src.x : pack_size.x - src.x;
			float m = cover2 * clamp((line - src.y) / aa + 0.5, 0.0, 1.0) * step(along, front) * strip_alpha;
			if (m > 0.0) {
				vec3 col = foil(src, aa) * 1.1;
				col = mix(col, PAPER, smoothstep(3.0, 0.0, line - src.y) * 0.85);
				float a = m + result.a * (1.0 - m);
				result = vec4((col * m + result.rgb * result.a * (1.0 - m)) / max(a, 0.0001), a);
			}
		}
	}
	COLOR = result;
}
