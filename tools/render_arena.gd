extends "res://tools/render_art.gd"
## Renders the battle arena: a wooden workbench with glowing lanes for the two
## sides, mats where the Printers stand, and printed tools lying around.
## Layout comes from scripts/ui/arena_layout.gd so picture and game agree.
##
##   godot --path . --disable-vsync -s tools/render_arena.gd

const ME := Color("35d6ff")
const FOE := Color("ffa62e")

var _spec: Dictionary


func _initialize() -> void:
	await process_frame
	_build_studio()
	await process_frame
	for l in lights:
		(l as Node).queue_free()
	plate.queue_free()
	env.background_color = Color("05070b")
	env.ambient_light_color = Color("ffd9b0")
	env.ambient_light_energy = 0.2
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.9
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.0

	var key := DirectionalLight3D.new()
	key.light_color = Color("ffe2bd")
	key.light_energy = 0.75
	key.shadow_enabled = true
	key.shadow_blur = 2.2
	key.directional_shadow_max_distance = 120.0
	vp.add_child(key)
	key.rotation_degrees = Vector3(-58, -36, 0)
	var cool := DirectionalLight3D.new()
	cool.light_color = Color("7fb0ff")
	cool.light_energy = 0.22
	vp.add_child(cool)
	cool.rotation_degrees = Vector3(-40, 140, 0)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/ui/arena"))
	for key_name in ["L", "P"]:
		await _render(key_name)
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


func _table() -> void:
	var t := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	t.mesh = pm
	var sh := Shader.new()
	sh.code = """
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
	var m := ShaderMaterial.new()
	m.shader = sh
	t.material_override = m
	stage.add_child(t)


func _render(key_name: String) -> void:
	_spec = Arena.SPECS[key_name]
	var portrait := key_name == "P"
	var px: Vector2 = (_spec["stage"] + _spec["margin"] * 2.0)
	vp.size = Vector2i(px * Arena.RENDER_SCALE)
	_clear()
	cam.fov = 28.0
	var view_h := px.y / Arena.PIXELS_PER_UNIT
	var dist := (view_h * 0.5) / tan(deg_to_rad(14.0))
	_aim(57.0, dist, 0.0)
	cam.far = 400.0
	await process_frame
	await process_frame

	_table()
	_zone(_spec["zone_foe"], FOE)
	_zone(_spec["zone_me"], ME)
	_pad(_spec["mat_me"])
	_pad(_spec["mat_foe"])

	# Lamps: warm pools of light so the bench is not evenly lit.
	var s: Vector2 = _spec["stage"]
	for lamp in [[Vector2(s.x * 0.5, s.y * 0.45), 34.0, 5.5, Color("ffd9a8")], [Vector2(s.x * 0.1, s.y * 0.72), 15.0, 6.0, Color("ffae5c")],
			[Vector2(s.x * 0.88, s.y * 0.16), 15.0, 5.0, Color("ffae5c")]]:
		var o := OmniLight3D.new()
		o.light_color = lamp[3]
		o.light_energy = lamp[2]
		o.omni_range = lamp[1]
		o.omni_attenuation = 1.4
		stage.add_child(o)
		o.position = at(lamp[0]) + Vector3(0, lamp[1] * 0.42, 0)

	if portrait:
		prop(_spool.bind(false), Vector2(600, -70), 20.0, 1.0)
		prop(_spool.bind(true), Vector2(420, -110), -30.0, 0.9)
		prop(_wrench, Vector2(180, -90), 25.0, 0.9)
		prop(_gears, Vector2(330, 192), 10.0, 0.5)
		prop(_calipers, Vector2(-70, 520), 80.0, 0.8)
		prop(_hex_keys, Vector2(790, 380), 100.0, 0.8)
		prop(_nozzle, Vector2(800, 620), 0.0, 0.8)
		prop(_bed_scraper, Vector2(-60, 300), 70.0, 0.8)
		prop(_glue_stick, Vector2(60, 1340), 0.0, 0.9)
		prop(_spool.bind(false), Vector2(600, 1380), -40.0, 1.0)
		prop(_hobby_knife, Vector2(330, 1360), 15.0, 0.9)
	else:
		prop(_spool.bind(false), Vector2(96, 262), -18.0, 0.95)
		prop(_spool.bind(true), Vector2(196, 350), 24.0, 0.7)
		prop(_gears, Vector2(690, 46), 12.0, 0.42)
		prop(_calipers, Vector2(1170, 316), 28.0, 0.62)
		prop(_hex_keys, Vector2(1196, 382), -160.0, 0.5)
		prop(_wrench, Vector2(-150, 330), 70.0, 1.0)
		prop(_bed_scraper, Vector2(-170, 560), 100.0, 1.0)
		prop(_glue_stick, Vector2(-80, 120), 0.0, 1.0)
		prop(_nozzle, Vector2(1400, 520), 0.0, 1.0)
		prop(_estop, Vector2(1420, 200), 0.0, 1.0)
		prop(_cooling_fan, Vector2(1380, 360), 30.0, 0.9)
		prop(_hobby_knife, Vector2(560, -50), 10.0, 0.9)
		prop(_spool.bind(false), Vector2(1330, 700), 30.0, 1.0)
		prop(_tree_supports, Vector2(-170, 20), 0.0, 1.0)
	await _settle()
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var path: String = _spec["image"]
	img.save_jpg(ProjectSettings.globalize_path(path), 0.9)
	print("rendered ", path, " ", img.get_size())
