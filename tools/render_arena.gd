extends "res://tools/render_art2.gd"
## Renders the battle arenas: six themed benches, each with glowing lanes for
## the two sides, mats where the Printers stand, and printed tools lying around.
## Layout comes from scripts/ui/arena_layout.gd so picture and game agree.
##
##   godot --path . --disable-vsync -s tools/render_arena.gd            (all themes)
##   godot --path . --disable-vsync -s tools/render_arena.gd -- neon    (just one)

const ME := Color("35d6ff")
const FOE := Color("ffa62e")

var _spec: Dictionary
var _theme_nodes: Array = []

## Per theme: lighting, and the order of props to scatter on the bench.
const THEMES := {
	"bench": {"bg": "05070b", "ambient": "ffd9b0", "amb_e": 0.2, "glow": 0.7, "key": ["ffe2bd", 0.75, Vector3(-58, -36, 0)], "fill": ["7fb0ff", 0.22, Vector3(-40, 140, 0)],
		"lamps": [["ffd9a8", 5.5], ["ffae5c", 6.0], ["ffae5c", 5.0]]},
	"lab": {"bg": "0a0e14", "ambient": "dce8ff", "amb_e": 0.25, "glow": 0.5, "key": ["f4f8ff", 0.7, Vector3(-62, -30, 0)], "fill": ["cfe6ff", 0.25, Vector3(-40, 140, 0)],
		"lamps": [["e8f2ff", 4.0], ["d8ecff", 3.5], ["d8ecff", 3.5]]},
	"farm": {"bg": "04060a", "ambient": "b0b8c8", "amb_e": 0.16, "glow": 0.8, "key": ["f0f0ff", 0.5, Vector3(-64, -20, 0)], "fill": ["8ab0e0", 0.15, Vector3(-40, 150, 0)],
		"lamps": [["9ecbff", 6.0], ["ffb347", 6.5], ["9ecbff", 5.0]]},
	"hobby": {"bg": "0a0805", "ambient": "ffe9c8", "amb_e": 0.3, "glow": 0.55, "key": ["fff0d0", 0.85, Vector3(-56, -40, 0)], "fill": ["a8d8c0", 0.2, Vector3(-40, 140, 0)],
		"lamps": [["ffe0b0", 6.0], ["ffcf90", 5.5], ["ffe0b0", 5.0]]},
	"neon": {"bg": "04020a", "ambient": "5030a0", "amb_e": 0.16, "glow": 1.3, "key": ["c070ff", 0.4, Vector3(-60, -30, 0)], "fill": ["30d0ff", 0.55, Vector3(-40, 150, 0)],
		"lamps": [["ff40c0", 7.0], ["30e0ff", 6.5], ["ff40c0", 6.0]]},
	"forge": {"bg": "060302", "ambient": "804030", "amb_e": 0.2, "glow": 1.0, "key": ["ff9050", 0.6, Vector3(-58, -34, 0)], "fill": ["ff5020", 0.3, Vector3(-40, 140, 0)],
		"lamps": [["ff8a40", 8.0], ["ff6a20", 7.0], ["ffa060", 6.0]]},
}

## Where the loose props go (stage pixel, turn, size), landscape and portrait.
const SPOTS_L := [[Vector2(96, 262), -18.0, 0.95], [Vector2(196, 350), 24.0, 0.7], [Vector2(690, 46), 12.0, 0.42], [Vector2(1170, 316), 28.0, 0.62],
	[Vector2(1196, 382), -160.0, 0.5], [Vector2(-150, 330), 70.0, 1.0], [Vector2(-170, 560), 100.0, 1.0], [Vector2(-80, 120), 0.0, 1.0],
	[Vector2(1400, 520), 0.0, 1.0], [Vector2(1420, 200), 0.0, 1.0], [Vector2(1380, 360), 30.0, 0.9], [Vector2(560, -50), 10.0, 0.9],
	[Vector2(1330, 700), 30.0, 1.0], [Vector2(-170, 20), 0.0, 1.0]]
const SPOTS_P := [[Vector2(600, -70), 20.0, 1.0], [Vector2(420, -110), -30.0, 0.9], [Vector2(180, -90), 25.0, 0.9], [Vector2(330, 192), 10.0, 0.5],
	[Vector2(-70, 520), 80.0, 0.8], [Vector2(790, 380), 100.0, 0.8], [Vector2(800, 620), 0.0, 0.8], [Vector2(-60, 300), 70.0, 0.8],
	[Vector2(60, 1340), 0.0, 0.9], [Vector2(600, 1380), -40.0, 1.0], [Vector2(330, 1360), 15.0, 0.9]]


func _initialize() -> void:
	await process_frame
	_build_studio()
	await process_frame
	for l in lights:
		(l as Node).queue_free()
	plate.queue_free()
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.9
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.0

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/ui/arena"))
	var only: Array = Array(OS.get_cmdline_user_args())
	for theme in THEMES:
		if not only.is_empty() and not only.has(theme):
			continue
		for key_name in ["L", "P"]:
			await _render(theme, key_name)
	quit()


## Stage pixel -> the point on the table top underneath it.
func at(p: Vector2) -> Vector3:
	var ip: Vector2 = (p + _spec["margin"]) * Arena.RENDER_SCALE
	var o := cam.project_ray_origin(ip)
	var n := cam.project_ray_normal(ip)
	return o + n * (-o.y / n.y)


func _glow(col: Color, energy: float, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(col, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = energy
	return m


func _bar(a: Vector3, b: Vector3, width: float, m: Material) -> void:
	var n := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(a.distance_to(b) + width, 0.02, width)
	n.mesh = bm
	n.material_override = m
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.add_child(n)
	n.position = (a + b) * 0.5 + Vector3(0, 0.02, 0)
	n.rotation.y = -atan2(b.z - a.z, b.x - a.x)


## A lane painted on the bench: a lit outline, a faint fill, corner brackets.
func _zone(r: Rect2, col: Color) -> void:
	var nl := at(Vector2(r.position.x, r.end.y))
	var nr := at(Vector2(r.end.x, r.end.y))
	var far_z := at(Vector2(r.get_center().x, r.position.y)).z
	var a := Vector3(nl.x, 0, nl.z)
	var b := Vector3(nr.x, 0, nl.z)
	var c := Vector3(nr.x, 0, far_z)
	var d := Vector3(nl.x, 0, far_z)
	var fill := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(b.x - a.x, a.z - d.z)
	fill.mesh = pm
	fill.material_override = _glow(col, 0.0, 0.07)
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.add_child(fill)
	fill.position = (a + c) * 0.5 + Vector3(0, 0.012, 0)
	var line := _glow(col, 2.2)
	for seg in [[a, b], [b, c], [c, d], [d, a]]:
		_bar(seg[0], seg[1], 0.07, line)
	var bold := _glow(col.lerp(Color.WHITE, 0.25), 3.2)
	var k := 0.9
	for corner in [[a, Vector3(1, 0, 0), Vector3(0, 0, -1)], [b, Vector3(-1, 0, 0), Vector3(0, 0, -1)],
			[c, Vector3(-1, 0, 0), Vector3(0, 0, 1)], [d, Vector3(1, 0, 0), Vector3(0, 0, 1)]]:
		_bar(corner[0], corner[0] + corner[1] * k, 0.16, bold)
		_bar(corner[0], corner[0] + corner[2] * k, 0.16, bold)
	# A dashed centre line where the prints stand.
	var mid_z := lerpf(a.z, d.z, 0.42)
	var dash := _glow(col, 1.2)
	var x := a.x + 0.8
	while x < b.x - 0.8:
		_bar(Vector3(x, 0, mid_z), Vector3(x + 0.35, 0, mid_z), 0.04, dash)
		x += 0.9


## A rubber mat for a Printer to stand on.
func _pad(r: Rect2) -> void:
	var nl := at(Vector2(r.position.x, r.end.y))
	var nr := at(Vector2(r.end.x, r.end.y))
	var far_z := at(Vector2(r.get_center().x, r.position.y)).z
	var size := Vector3(nr.x - nl.x, 0.06, nl.z - far_z)
	var centre := Vector3((nl.x + nr.x) * 0.5, 0.03, (nl.z + far_z) * 0.5)
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color("171c24")
	rubber.roughness = 0.92
	box(stage, size, centre, DARK, Vector3.ZERO, rubber)
	var edge := StandardMaterial3D.new()
	edge.albedo_color = Color("6b5a34")
	edge.metallic = 0.7
	edge.roughness = 0.4
	box(stage, size + Vector3(0.14, -0.03, 0.14), centre - Vector3(0, 0.012, 0), DARK, Vector3.ZERO, edge)


## Drops one of the tool models onto the bench under a stage pixel.
func prop(builder: Callable, px: Vector2, rot_y: float, size: float) -> void:
	var h := Node3D.new()
	stage.add_child(h)
	h.position = at(px)
	h.rotation_degrees = Vector3(0, rot_y, 0)
	h.scale = Vector3.ONE * size
	_holder = h
	builder.call()
	_holder = stage


const WOOD := """
shader_type spatial;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
void fragment() {
	float plank_w = 1.45;
	float row = floor(wp.z / plank_w);
	float fz = fract(wp.z / plank_w);
	float plank_l = 8.0;
	float xo = wp.x + hash(vec2(row, 3.0)) * plank_l;
	float col = floor(xo / plank_l);
	float fx = fract(xo / plank_l);
	float tone = hash(vec2(row, col));
	vec3 base = mix(vec3(0.15, 0.078, 0.04), vec3(0.27, 0.15, 0.078), tone);
	float g = fbm(vec2(wp.x * 0.22 + tone * 40.0, wp.z * 5.5 + tone * 9.0));
	float streak = fbm(vec2(wp.x * 0.05 + tone * 13.0, wp.z * 22.0));
	float rings = sin(wp.z * 7.0 + g * 9.0) * 0.5 + 0.5;
	base *= 0.55 + 0.75 * g;
	base *= 0.82 + 0.26 * rings;
	base *= 0.80 + 0.36 * streak;
	float seam = smoothstep(0.0, 0.018, fz) * smoothstep(1.0, 0.982, fz);
	float butt = smoothstep(0.0, 0.0035, fx) * smoothstep(1.0, 0.9965, fx);
	base *= mix(0.22, 1.0, seam * butt);
	float bevel = smoothstep(0.018, 0.06, fz) * smoothstep(0.982, 0.94, fz);
	base *= mix(1.12, 1.0, bevel);
	float edge = smoothstep(7.0, 21.0, length(wp.xz * vec2(1.0, 1.35)));
	ALBEDO = base * mix(1.0, 0.3, edge);
	ROUGHNESS = 0.42 + 0.3 * g;
	SPECULAR = 0.35;
}
"""

const COMMON := """
shader_type spatial;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}
float edge_fade() { return smoothstep(9.0, 26.0, length(wp.xz * vec2(1.0, 1.35))); }
"""

## The surface of each theme's table, as the body of fragment().
const SURFACES := {
	"lab": """
void fragment() {
	vec2 g = abs(fract(wp.xz / 2.0) - 0.5);
	float seam = 1.0 - smoothstep(0.0, 0.012, min(0.5 - g.x, 0.5 - g.y));
	float fine = noise(wp.xz * 40.0);
	vec3 base = vec3(0.36, 0.40, 0.45) * (0.94 + 0.06 * fine);
	base *= 0.7 + 0.3 * fbm(wp.xz * 0.35);
	base = mix(base, vec3(0.28, 0.32, 0.38), seam * 0.9);
	vec2 d = abs(fract(wp.xz / 0.5) - 0.5);
	base = mix(base, vec3(0.5, 0.6, 0.7), (1.0 - smoothstep(0.0, 0.01, min(d.x, d.y))) * 0.16);
	ALBEDO = base * mix(1.0, 0.35, edge_fade());
	ROUGHNESS = 0.32;
	SPECULAR = 0.55;
}
""",
	"farm": """
void fragment() {
	vec2 p = wp.xz * 2.2;
	vec2 q = vec2(p.x + p.y, p.x - p.y);
	vec2 f = abs(fract(q * 0.5) - 0.5);
	float diamond = smoothstep(0.1, 0.35, min(f.x, f.y));
	vec3 base = vec3(0.05, 0.055, 0.065) + vec3(0.03) * diamond;
	base *= 0.75 + 0.5 * fbm(wp.xz * 0.6);
	float stripe = step(0.5, fract((wp.x + wp.z) * 0.18));
	float lane = smoothstep(11.0, 11.4, abs(mod(wp.z, 22.0) - 11.0) + 0.0);
	base = mix(base, mix(vec3(0.85, 0.65, 0.05), vec3(0.06), stripe), (1.0 - smoothstep(0.0, 0.22, abs(mod(wp.z + 6.0, 24.0) - 12.0))) * 0.9);
	ALBEDO = base * mix(1.0, 0.3, edge_fade());
	ROUGHNESS = 0.4 + 0.3 * diamond;
	METALLIC = 0.25;
	SPECULAR = 0.5;
}
""",
	"hobby": """
void fragment() {
	vec2 g = abs(fract(wp.xz) - 0.5);
	float minor = 1.0 - smoothstep(0.0, 0.018, min(0.5 - g.x, 0.5 - g.y));
	vec2 g5 = abs(fract(wp.xz / 5.0) - 0.5);
	float major = 1.0 - smoothstep(0.0, 0.012, min(0.5 - g5.x, 0.5 - g5.y));
	vec3 base = vec3(0.05, 0.26, 0.17) * (0.85 + 0.3 * fbm(wp.xz * 3.0));
	base = mix(base, vec3(0.75, 0.9, 0.8), minor * 0.35 + major * 0.35);
	float scuff = smoothstep(0.62, 0.85, fbm(wp.xz * 1.7)) * 0.3;
	base = mix(base, vec3(0.7, 0.85, 0.75), scuff * 0.4);
	float wood = fbm(vec2(wp.x * 0.3, wp.z * 9.0));
	vec3 timber = vec3(0.26, 0.15, 0.08) * (0.6 + 0.8 * wood);
	float mat = 1.0 - smoothstep(13.0, 14.0, length(wp.xz * vec2(0.8, 1.0)));
	vec3 col = mix(timber, base, mat);
	ALBEDO = col * mix(1.0, 0.3, edge_fade());
	ROUGHNESS = mix(0.5, 0.75, mat);
	SPECULAR = 0.3;
}
""",
	"neon": """
void fragment() {
	vec2 g = abs(fract(wp.xz / 1.5) - 0.5);
	float line = 1.0 - smoothstep(0.0, 0.03, min(0.5 - g.x, 0.5 - g.y));
	vec2 g3 = abs(fract(wp.xz / 7.5) - 0.5);
	float bold = 1.0 - smoothstep(0.0, 0.025, min(0.5 - g3.x, 0.5 - g3.y));
	vec3 base = vec3(0.012, 0.012, 0.02) + 0.02 * fbm(wp.xz * 0.5);
	vec3 neon = mix(vec3(0.1, 0.8, 1.0), vec3(1.0, 0.2, 0.75), step(0.5, fract(wp.x / 15.0 + 0.25)));
	vec3 col = base + neon * (line * 0.35 + bold * 0.9);
	float fade = 1.0 - edge_fade();
	ALBEDO = base;
	EMISSION = (col - base) * fade * 1.4;
	ROUGHNESS = 0.12;
	METALLIC = 0.7;
	SPECULAR = 0.9;
}
""",
	"forge": """
void fragment() {
	float n = fbm(wp.xz * 0.9);
	float n2 = fbm(wp.xz * 2.4 + 7.0);
	vec3 base = vec3(0.06, 0.052, 0.05) * (0.5 + 1.2 * n2);
	float crack = 1.0 - smoothstep(0.0, 0.02, abs(n - 0.5));
	float crack2 = 1.0 - smoothstep(0.0, 0.013, abs(n2 - 0.52));
	vec3 lava = vec3(1.0, 0.36, 0.06) * (crack * 1.1 + crack2 * 0.5);
	vec2 g = abs(fract(wp.xz / 3.0) - 0.5);
	float plate = 1.0 - smoothstep(0.0, 0.015, min(0.5 - g.x, 0.5 - g.y));
	base *= 1.0 - plate * 0.7;
	float fade = 1.0 - edge_fade();
	ALBEDO = base;
	EMISSION = lava * fade * 0.55;
	ROUGHNESS = 0.55;
	METALLIC = 0.6;
	SPECULAR = 0.5;
}
""",
}


func _table(theme: String) -> void:
	var t := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	t.mesh = pm
	var sh := Shader.new()
	sh.code = WOOD if theme == "bench" else COMMON + SURFACES[theme]
	var m := ShaderMaterial.new()
	m.shader = sh
	t.material_override = m
	stage.add_child(t)
	_theme_nodes.append(t)


func _props(theme: String) -> Array:
	var spool := _spool.bind(false)
	var rainbow := _spool.bind(true)
	match theme:
		"lab":
			return [_dryer, _blueprint, _feeler, _calipers, _tweezers, _goggles, _nozzle, _bed_leveling, _hex_keys, _cooling_fan, _soldering_iron, _glue_gun, _hobby_knife, _test_print]
		"farm":
			return [spool, rainbow, _estop, _cooling_fan, _backup_spool, _plug, _wrench, _gears, _spaghetti, _bed_scraper, spool, _goggles, _dryer, _tree_supports]
		"hobby":
			return [_hobby_knife, _glue_stick, _test_print, _tweezers, _glue_gun, _soldering_iron, _calipers, rainbow, spool, _bed_scraper, _hex_keys, _nozzle, _tree_supports, _goggles]
		"neon":
			return [_gears, rainbow, _cooling_fan, _estop, _nozzle, _blueprint, _bed_leveling, _spaghetti, _plug, _glue_gun, _feeler, spool, _scrap, _backup_spool]
		"forge":
			return [_wrench, _gears, _soldering_iron, _estop, _plug, _hex_keys, _bed_scraper, _spaghetti, _glue_gun, _gears, _calipers, _nozzle, _hobby_knife, spool]
	return [spool, rainbow, _gears, _calipers, _hex_keys, _wrench, _bed_scraper, _glue_stick, _nozzle, _estop, _cooling_fan, _hobby_knife, spool, _tree_supports]


## The portrait list is in a different order (it has fewer spots).
func _props_portrait(theme: String) -> Array:
	var all := _props(theme)
	if theme == "bench":
		var spool := _spool.bind(false)
		return [spool, _spool.bind(true), _wrench, _gears, _calipers, _hex_keys, _nozzle, _bed_scraper, _glue_stick, spool, _hobby_knife]
	return all.slice(0, SPOTS_P.size())


func _render(theme: String, key_name: String) -> void:
	_spec = Arena.SPECS[key_name]
	var portrait := key_name == "P"
	var look: Dictionary = THEMES[theme]
	var px: Vector2 = (_spec["stage"] + _spec["margin"] * 2.0)
	vp.size = Vector2i(px * Arena.RENDER_SCALE)
	_clear()
	for n in _theme_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_theme_nodes.clear()
	env.background_color = Color(look["bg"])
	env.ambient_light_color = Color(look["ambient"])
	env.ambient_light_energy = float(look["amb_e"])
	env.glow_intensity = float(look["glow"])
	env.glow_bloom = 0.12
	for spec in [look["key"], look["fill"]]:
		var d := DirectionalLight3D.new()
		d.light_color = Color(spec[0])
		d.light_energy = float(spec[1])
		d.shadow_enabled = spec == look["key"]
		d.shadow_blur = 2.2
		d.directional_shadow_max_distance = 120.0
		vp.add_child(d)
		d.rotation_degrees = spec[2]
		_theme_nodes.append(d)
	cam.fov = 28.0
	var view_h := px.y / Arena.PIXELS_PER_UNIT
	var dist := (view_h * 0.5) / tan(deg_to_rad(14.0))
	_aim(57.0, dist, 0.0)
	cam.far = 400.0
	await process_frame
	await process_frame

	_table(theme)
	_zone(_spec["zone_foe"], FOE)
	_zone(_spec["zone_me"], ME)
	_pad(_spec["mat_me"])
	_pad(_spec["mat_foe"])

	# Lamps: pools of light so the bench is not evenly lit.
	var s: Vector2 = _spec["stage"]
	var lamps: Array = look["lamps"]
	var spots := [[Vector2(s.x * 0.5, s.y * 0.45), 34.0], [Vector2(s.x * 0.1, s.y * 0.72), 15.0], [Vector2(s.x * 0.88, s.y * 0.16), 15.0]]
	for i in 3:
		var o := OmniLight3D.new()
		o.light_color = Color(lamps[i][0])
		o.light_energy = float(lamps[i][1])
		o.omni_range = spots[i][1]
		o.omni_attenuation = 1.4
		stage.add_child(o)
		o.position = at(spots[i][0]) + Vector3(0, float(spots[i][1]) * 0.42, 0)

	var builders: Array = _props_portrait(theme) if portrait else _props(theme)
	var places: Array = SPOTS_P if portrait else SPOTS_L
	for i in mini(builders.size(), places.size()):
		prop(builders[i], places[i][0], places[i][1], places[i][2])
	await _settle()
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var path: String = Arena.image(theme, portrait)
	img.save_jpg(ProjectSettings.globalize_path(path), 0.9)
	print("rendered ", path, " ", img.get_size())
