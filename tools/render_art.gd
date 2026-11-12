extends SceneTree
## Renders the tool card art with Godot itself: each tool is modelled from
## primitives, given the printed-plastic layer-line shader, lit on a print bed
## and saved to assets/tools/<id>.png.
##
##   godot --path . -s tools/render_art.gd            (all)
##   godot --path . -s tools/render_art.gd -- gear_up (just some)
##
## Needs a real renderer, so it cannot run with --headless.

const OUT := "res://assets/tools/%s.png"
const SIZE := Vector2i(640, 480)
const PLASTIC := preload("res://assets/shaders/printed_plastic.gdshader")

const ORANGE := Color("ff7a1a")
const RED := Color("e23b2e")
const YELLOW := Color("ffc928")
const GREEN := Color("4ccb5f")
const TEAL := Color("14b8a0")
const BLUE := Color("2f8cf0")
const PURPLE := Color("9a5cf5")
const WHITE := Color("eef1f4")
const GREY := Color("aab2bc")
const DARK := Color("2b3038")
const BRASS := Color("e9a91c")

var vp: SubViewport
var stage: Node3D
var cam: Camera3D
var plate: MeshInstance3D
var env: Environment


func _initialize() -> void:
	var only: Array = Array(OS.get_cmdline_user_args())
	await process_frame
	_build_studio()
	await process_frame
	var jobs := {
		"heat_gun": [_heat_gun, 34.0, 4.6, 0.75],
		"glue_stick": [_glue_stick, 30.0, 4.4, 0.7],
		"spare_spool": [_spool.bind(false), 26.0, 5.0, 0.9],
		"rainbow_spool": [_spool.bind(true), 26.0, 5.0, 0.9],
		"calipers": [_calipers, 52.0, 4.6, 0.1],
		"hobby_knife": [_hobby_knife, 50.0, 4.3, 0.1],
		"bed_scraper": [_bed_scraper, 50.0, 4.6, 0.1],
		"cooling_fan": [_cooling_fan, 24.0, 4.6, 0.75],
		"tree_supports": [_tree_supports, 24.0, 4.8, 0.75],
		"test_print": [_test_print, 34.0, 4.4, 0.45],
		"printed_wrench": [_wrench, 52.0, 4.6, 0.05],
		"hex_keys": [_hex_keys, 50.0, 4.6, 0.1],
		"bed_leveling": [_bed_leveling, 36.0, 5.4, 0.45],
		"clean_nozzle": [_nozzle, 26.0, 4.6, 0.75],
		"emergency_stop": [_estop, 36.0, 4.8, 0.6],
		"gear_up": [_gears, 52.0, 4.6, 0.1],
		"filament_scrap": [_scrap, 44.0, 4.2, 0.2],
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/tools"))
	for id in jobs:
		if not only.is_empty() and not only.has(id):
			continue
		var job: Array = jobs[id]
		await _shoot(id, job[0], job[1], job[2], job[3])
	if only.is_empty() or only.has("cali_cube_sprite"):
		await _shoot_sprite()
	quit()


# ----------------------------------------------------------------- studio

func _build_studio() -> void:
	vp = SubViewport.new()
	vp.size = SIZE
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("070b14")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8fa6d8")
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_radius = 0.6
	env.ssao_intensity = 2.5
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.08
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)

	cam = Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)

	var key := DirectionalLight3D.new()
	key.light_color = Color("fff0dc")
	key.light_energy = 1.7
	key.shadow_enabled = true
	key.shadow_blur = 1.6
	key.directional_shadow_max_distance = 20.0
	vp.add_child(key)
	key.rotation_degrees = Vector3(-52, 38, 0)

	var rim := OmniLight3D.new()
	rim.light_color = Color("47c8ff")
	rim.light_energy = 5.0
	rim.omni_range = 9.0
	rim.position = Vector3(-2.6, 1.8, -2.4)
	vp.add_child(rim)

	var warm := OmniLight3D.new()
	warm.light_color = Color("ffb057")
	warm.light_energy = 2.2
	warm.omni_range = 8.0
	warm.position = Vector3(3.0, 1.4, 1.6)
	vp.add_child(warm)

	# The print bed: a dark textured sheet with a calibration grid that fades
	# into the dark so there is no visible horizon.
	plate = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	plate.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 g = abs(fract(wp.xz / 0.5) - 0.5);
	float line = 1.0 - smoothstep(0.0, 0.025, min(g.x, g.y));
	float speck = hash(floor(wp.xz * 90.0));
	vec3 base = vec3(0.022, 0.032, 0.058) + vec3(0.012) * speck;
	vec3 col = mix(base, vec3(0.07, 0.20, 0.34), line * 0.5);
	float fade = 1.0 - smoothstep(1.3, 4.6, length(wp.xz));
	ALBEDO = col * fade;
	ROUGHNESS = 0.55 + 0.25 * speck;
	SPECULAR = 0.4;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	plate.material_override = mat
	vp.add_child(plate)

	stage = Node3D.new()
	vp.add_child(stage)


func _aim(elevation: float, dist: float, look_y: float) -> void:
	var e := deg_to_rad(elevation)
	cam.position = Vector3(0, look_y + sin(e) * dist, cos(e) * dist)
	cam.look_at(Vector3(0, look_y, 0))


func _clear() -> void:
	for c in stage.get_children():
		stage.remove_child(c)
		c.queue_free()


func _settle() -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw


func _shoot(id: String, builder: Callable, elevation: float, dist: float, look_y: float) -> void:
	_clear()
	builder.call()
	_aim(elevation, dist, look_y)
	await _settle()
	var img := vp.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT % id))
	print("rendered ", id)


## The Calibration Cube token also stands on the battlefield, so it gets a
## transparent cut-out the same shape as one creature sprite cell.
func _shoot_sprite() -> void:
	_clear()
	vp.size = Vector2i(384, 512)
	vp.transparent_bg = true
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.glow_enabled = false
	plate.visible = false
	var r := Node3D.new()
	stage.add_child(r)
	_cube(r, 1.25, Vector3(0, 0.625, 0), -28.0, ORANGE)
	cam.fov = 26.0
	_aim(20.0, 5.6, 0.75)
	await _settle()
	var img := vp.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT % "cali_cube_sprite"))
	print("rendered cali_cube_sprite")


# ---------------------------------------------------------------- helpers

func mat(col: Color, layer := 0.035, axis := Vector3.UP, rough := 0.36, depth := 0.6) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PLASTIC
	m.set_shader_parameter("color", col)
	m.set_shader_parameter("layer_h", layer)
	m.set_shader_parameter("layer_axis", axis)
	m.set_shader_parameter("rough", rough)
	m.set_shader_parameter("depth", depth)
	return m


func _place(parent: Node3D, n: Node3D, pos: Vector3, rot: Vector3) -> void:
	parent.add_child(n)
	n.position = pos
	n.rotation_degrees = rot


func box(parent: Node3D, size: Vector3, pos: Vector3, col: Color, rot := Vector3.ZERO, m: Material = null) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	n.mesh = b
	n.material_override = m if m else mat(col)
	_place(parent, n, pos, rot)
	return n


func cyl(parent: Node3D, r_bottom: float, r_top: float, h: float, pos: Vector3, col: Color, rot := Vector3.ZERO, sides := 48, m: Material = null) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.bottom_radius = r_bottom
	c.top_radius = r_top
	c.height = h
	c.radial_segments = sides
	n.mesh = c
	n.material_override = m if m else mat(col)
	_place(parent, n, pos, rot)
	return n


func ball(parent: Node3D, r: float, pos: Vector3, col: Color, squash := Vector3.ONE) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	n.mesh = s
	n.material_override = mat(col)
	_place(parent, n, pos, Vector3.ZERO)
	n.scale = squash
	return n


func torus(parent: Node3D, radius: float, tube: float, pos: Vector3, col: Color, rot := Vector3.ZERO, m: Material = null) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = radius - tube
	t.outer_radius = radius + tube
	n.mesh = t
	n.material_override = m if m else mat(col, 0.02)
	_place(parent, n, pos, rot)
	return n


## A thin rod between two points.
func stick(parent: Node3D, a: Vector3, b: Vector3, r: float, col: Color) -> MeshInstance3D:
	var n := cyl(parent, r, r, a.distance_to(b), (a + b) * 0.5, col, Vector3.ZERO, 16)
	var dir := (b - a).normalized()
	var up := Vector3.UP
	var axis := up.cross(dir)
	if axis.length() > 0.0001:
		n.quaternion = Quaternion(axis.normalized(), up.angle_to(dir))
	return n


func label(parent: Node3D, text: String, size: int, pos: Vector3, col: Color, rot := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var t := TextMesh.new()
	t.text = text
	t.font = load("res://assets/fonts/Arvo-Bold.ttf")
	t.font_size = size
	t.depth = 0.05
	t.pixel_size = 0.01
	n.mesh = t
	n.material_override = mat(col, 0.02, Vector3.UP, 0.4, 0.2)
	_place(parent, n, pos, rot)
	return n


func group(rot_y: float, pos := Vector3.ZERO) -> Node3D:
	var r := Node3D.new()
	stage.add_child(r)
	r.rotation_degrees = Vector3(0, rot_y, 0)
	r.position = pos
	return r


func csg(parent: Node3D, pos: Vector3, rot: Vector3) -> CSGCombiner3D:
	var c := CSGCombiner3D.new()
	_place(parent, c, pos, rot)
	return c


func _cube(parent: Node3D, s: float, pos: Vector3, rot_y: float, col: Color) -> void:
	var c := Node3D.new()
	_place(parent, c, pos, Vector3(0, rot_y, 0))
	box(c, Vector3(s, s, s), Vector3.ZERO, col, Vector3.ZERO, mat(col, s / 18.0))
	var fs := int(s * 62.0)
	var dark := col.darkened(0.45)
	label(c, "X", fs, Vector3(0, 0, s * 0.5), dark)
	label(c, "Y", fs, Vector3(s * 0.5, 0, 0), dark, Vector3(0, 90, 0))
	label(c, "Z", fs, Vector3(0, s * 0.5, 0), dark, Vector3(-90, 0, 0))


# ------------------------------------------------------------------ tools

func _heat_gun() -> void:
	var r := group(-28.0, Vector3(0.1, 0, 0))
	cyl(r, 0.36, 0.36, 1.25, Vector3(0.1, 1.05, 0), RED, Vector3(0, 0, 90))
	cyl(r, 0.38, 0.38, 0.14, Vector3(0.78, 1.05, 0), DARK, Vector3(0, 0, 90))
	cyl(r, 0.3, 0.3, 0.1, Vector3(-0.56, 1.05, 0), DARK, Vector3(0, 0, 90))
	cyl(r, 0.27, 0.19, 0.55, Vector3(-0.86, 1.05, 0), GREY, Vector3(0, 0, 90), 48, mat(GREY, 0.035, Vector3.UP, 0.22))
	cyl(r, 0.13, 0.13, 0.08, Vector3(-1.14, 1.05, 0), Color("ff8a3d"), Vector3(0, 0, 90))
	box(r, Vector3(0.36, 1.0, 0.38), Vector3(0.42, 0.5, 0), RED.darkened(0.12), Vector3(0, 0, -10))
	box(r, Vector3(0.12, 0.3, 0.2), Vector3(0.14, 0.66, 0), DARK, Vector3(0, 0, -10))
	box(r, Vector3(0.62, 0.1, 0.56), Vector3(0.52, 0.05, 0), DARK)
	for i in 4:
		box(r, Vector3(0.05, 0.3, 0.74), Vector3(0.36 + i * 0.1, 1.05, 0), DARK)


func _glue_stick() -> void:
	var r := group(0.0)
	cyl(r, 0.33, 0.33, 0.26, Vector3(-0.3, 0.13, 0), RED, Vector3.ZERO, 14)
	cyl(r, 0.3, 0.3, 1.05, Vector3(-0.3, 0.78, 0), YELLOW)
	cyl(r, 0.25, 0.25, 0.2, Vector3(-0.3, 1.4, 0), WHITE)
	ball(r, 0.25, Vector3(-0.3, 1.5, 0), WHITE, Vector3(1, 0.45, 1))
	cyl(r, 0.34, 0.34, 0.55, Vector3(0.62, 0.34, 0.35), RED, Vector3(0, 30, 90))


func _spool(rainbow: bool) -> void:
	var r := group(62.0)
	var axis: Vector3 = r.transform.basis * Vector3.BACK
	var rx := Vector3(90, 0, 0)
	cyl(r, 0.9, 0.9, 0.06, Vector3(0, 0.95, 0.31), DARK, rx, 64)
	cyl(r, 0.9, 0.9, 0.06, Vector3(0, 0.95, -0.31), DARK, rx, 64)
	if rainbow:
		var cols := [RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE]
		for i in cols.size():
			var z := -0.275 + (i + 0.5) * (0.55 / cols.size())
			cyl(r, 0.74, 0.74, 0.55 / cols.size() + 0.002, Vector3(0, 0.95, z), cols[i], rx, 64, mat(cols[i], 0.03, axis, 0.3, 0.8))
		stick(r, Vector3(0.5, 1.5, 0.2), Vector3(1.15, 1.95, 0.25), 0.03, PURPLE)
	else:
		cyl(r, 0.74, 0.74, 0.55, Vector3(0, 0.95, 0), ORANGE, rx, 64, mat(ORANGE, 0.03, axis, 0.3, 0.8))
		stick(r, Vector3(0.5, 1.5, 0.2), Vector3(1.15, 1.95, 0.25), 0.03, ORANGE)
	cyl(r, 0.24, 0.24, 0.72, Vector3(0, 0.95, 0), GREY, rx)
	cyl(r, 0.15, 0.15, 0.74, Vector3(0, 0.95, 0), Color("0c0f14"), rx)
	for i in 3:
		var a := deg_to_rad(i * 120.0 + 20.0)
		cyl(r, 0.11, 0.11, 0.09, Vector3(cos(a) * 0.5, 0.95 + sin(a) * 0.5, 0.31), Color("0c0f14"), rx)


func _calipers() -> void:
	var r := group(18.0)
	var c := Color("dfe5ec")
	box(r, Vector3(2.3, 0.08, 0.2), Vector3(0.1, 0.04, 0), c)
	box(r, Vector3(0.18, 0.08, 0.8), Vector3(-0.96, 0.04, 0.38), c)
	box(r, Vector3(0.12, 0.08, 0.34), Vector3(-0.99, 0.04, -0.24), c)
	box(r, Vector3(0.6, 0.13, 0.36), Vector3(-0.2, 0.065, 0), BLUE)
	box(r, Vector3(0.18, 0.11, 0.74), Vector3(-0.41, 0.055, 0.41), BLUE)
	box(r, Vector3(0.12, 0.11, 0.3), Vector3(-0.44, 0.055, -0.26), BLUE)
	box(r, Vector3(0.34, 0.03, 0.18), Vector3(-0.2, 0.14, 0), Color("10151c"))
	cyl(r, 0.09, 0.09, 0.1, Vector3(0.05, 0.07, 0.2), DARK, Vector3.ZERO, 14)
	box(r, Vector3(0.55, 0.04, 0.05), Vector3(1.5, 0.03, 0), c)
	for i in 16:
		box(r, Vector3(0.012, 0.012, 0.09 if i % 4 else 0.15), Vector3(0.2 + i * 0.065, 0.085, -0.05), DARK)


func _hobby_knife() -> void:
	var r := group(-24.0)
	var rz := Vector3(0, 0, 90)
	cyl(r, 0.1, 0.1, 1.5, Vector3(0.3, 0.1, 0), TEAL, rz, 12)
	cyl(r, 0.125, 0.125, 0.42, Vector3(-0.42, 0.125, 0), DARK, rz, 10)
	cyl(r, 0.12, 0.06, 0.16, Vector3(-0.71, 0.1, 0), GREY, rz, 24, mat(GREY, 0.03, Vector3.UP, 0.2))
	var blade := CSGPolygon3D.new()
	blade.polygon = PackedVector2Array([Vector2(-0.78, -0.08), Vector2(-0.78, 0.08), Vector2(-1.38, -0.08)])
	blade.depth = 0.02
	blade.material = mat(Color("e6ebf0"), 0.02, Vector3.UP, 0.15, 0.25)
	_place(r, blade, Vector3(0, 0.11, 0), Vector3(90, 0, 0))
	cyl(r, 0.13, 0.13, 0.5, Vector3(0.5, 0.13, 0.55), TEAL.lightened(0.25), Vector3(0, 12, 90), 12)


func _bed_scraper() -> void:
	var r := group(28.0)
	var blade := CSGPolygon3D.new()
	blade.polygon = PackedVector2Array([Vector2(-1.2, -0.46), Vector2(-1.2, 0.46), Vector2(-0.2, 0.3), Vector2(-0.2, -0.3)])
	blade.depth = 0.03
	blade.material = mat(Color("cfd6de"), 0.03, Vector3.UP, 0.16, 0.25)
	_place(r, blade, Vector3(0, 0.05, 0), Vector3(90, 0, 0))
	box(r, Vector3(0.16, 0.16, 0.56), Vector3(-0.18, 0.09, 0), DARK)
	box(r, Vector3(1.15, 0.22, 0.44), Vector3(0.46, 0.12, 0), RED)
	cyl(r, 0.22, 0.22, 0.22, Vector3(1.04, 0.12, 0), RED)
	cyl(r, 0.08, 0.08, 0.24, Vector3(1.04, 0.12, 0), Color("0c0f14"))
	for i in 4:
		box(r, Vector3(0.05, 0.24, 0.46), Vector3(0.2 + i * 0.16, 0.12, 0), RED.darkened(0.25))


func _cooling_fan() -> void:
	var r := group(-24.0)
	var frame := csg(r, Vector3(0, 0.8, 0), Vector3.ZERO)
	var b := CSGBox3D.new()
	b.size = Vector3(1.6, 1.6, 0.4)
	b.material = mat(DARK)
	frame.add_child(b)
	var hole := CSGCylinder3D.new()
	hole.radius = 0.72
	hole.height = 0.6
	hole.sides = 48
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	hole.rotation_degrees = Vector3(90, 0, 0)
	hole.material = mat(DARK)
	frame.add_child(hole)
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			cyl(r, 0.07, 0.07, 0.42, Vector3(sx * 0.68, 0.8 + sy * 0.68, 0), Color("0c0f14"), Vector3(90, 0, 0), 16)
	cyl(r, 0.26, 0.26, 0.32, Vector3(0, 0.8, 0), Color("3b424d"), Vector3(90, 0, 0))
	cyl(r, 0.19, 0.19, 0.34, Vector3(0, 0.8, 0), BLUE, Vector3(90, 0, 0))
	for i in 7:
		var pivot := Node3D.new()
		_place(r, pivot, Vector3(0, 0.8, 0), Vector3(0, 0, i * 360.0 / 7.0))
		box(pivot, Vector3(0.44, 0.3, 0.035), Vector3(0.45, 0, 0), BLUE, Vector3(32, 0, 12))


func _tree_supports() -> void:
	var r := group(-22.0)
	box(r, Vector3(0.34, 1.2, 0.56), Vector3(-0.62, 0.6, 0), ORANGE)
	box(r, Vector3(1.5, 0.26, 0.56), Vector3(-0.04, 1.33, 0), ORANGE)
	var sup := Color("9af0a8")
	cyl(r, 0.26, 0.26, 0.03, Vector3(0.32, 0.015, 0), sup)
	stick(r, Vector3(0.32, 0.0, 0), Vector3(0.32, 0.62, 0), 0.075, sup)
	for tip in [Vector3(-0.1, 1.2, 0.16), Vector3(0.24, 1.2, -0.16), Vector3(0.5, 1.2, 0.14), Vector3(0.62, 1.2, -0.1)]:
		stick(r, Vector3(0.32, 0.6, 0), tip, 0.04, sup)
		ball(r, 0.05, tip, sup)
	ball(r, 0.08, Vector3(0.32, 0.62, 0), sup)


func _test_print() -> void:
	var r := group(0.0)
	_cube(r, 0.82, Vector3(-0.5, 0.41, -0.1), 28.0, ORANGE)
	_cube(r, 0.6, Vector3(0.56, 0.3, 0.4), -24.0, TEAL)


func _wrench() -> void:
	var r := group(-30.0)
	var m := mat(ORANGE, 0.035, Vector3.UP, 0.34)
	var w := csg(r, Vector3(0, 0.07, 0), Vector3.ZERO)
	var handle := CSGBox3D.new()
	handle.size = Vector3(1.7, 0.14, 0.3)
	handle.material = m
	w.add_child(handle)
	var head := CSGCylinder3D.new()
	head.radius = 0.42
	head.height = 0.14
	head.sides = 40
	head.position = Vector3(-0.95, 0, 0)
	head.material = m
	w.add_child(head)
	var ring := CSGCylinder3D.new()
	ring.radius = 0.34
	ring.height = 0.14
	ring.sides = 40
	ring.position = Vector3(0.95, 0, 0)
	ring.material = m
	w.add_child(ring)
	var notch := CSGBox3D.new()
	notch.size = Vector3(0.6, 0.4, 0.32)
	notch.position = Vector3(-1.2, 0, 0.02)
	notch.rotation_degrees = Vector3(0, 14, 0)
	notch.operation = CSGShape3D.OPERATION_SUBTRACTION
	notch.material = m
	w.add_child(notch)
	var hexhole := CSGCylinder3D.new()
	hexhole.radius = 0.19
	hexhole.height = 0.4
	hexhole.sides = 6
	hexhole.position = Vector3(0.95, 0, 0)
	hexhole.operation = CSGShape3D.OPERATION_SUBTRACTION
	hexhole.material = m
	w.add_child(hexhole)
	var groove := CSGBox3D.new()
	groove.size = Vector3(1.0, 0.06, 0.12)
	groove.position = Vector3(0, 0.07, 0)
	groove.operation = CSGShape3D.OPERATION_SUBTRACTION
	groove.material = m
	w.add_child(groove)


func _hex_keys() -> void:
	var r := group(0.0)
	var specs := [[0.075, 1.7, -14.0, -0.45, Color("3b424d")], [0.06, 1.4, 4.0, 0.0, Color("3b424d")], [0.045, 1.1, 22.0, 0.42, Color("3b424d")]]
	for s in specs:
		var k := Node3D.new()
		_place(r, k, Vector3(0.1, s[0], s[3]), Vector3(0, s[2], 0))
		var m := mat(s[4], 0.03, Vector3.UP, 0.25, 0.3)
		cyl(k, s[0], s[0], s[1], Vector3(-s[1] * 0.5 + 0.3, 0, 0), s[4], Vector3(0, 0, 90), 6, m)
		cyl(k, s[0], s[0], 0.42, Vector3(-s[1] + 0.3, 0, 0.21), s[4], Vector3(90, 0, 0), 6, m)
	box(r, Vector3(0.36, 0.3, 1.25), Vector3(0.62, 0.15, 0), BLUE, Vector3(0, 4, 0))


func _bed_leveling() -> void:
	var r := group(32.0)
	box(r, Vector3(1.8, 0.1, 1.8), Vector3(0, 0.05, 0), DARK)
	var steel := mat(Color("cfd6de"), 0.02, Vector3.UP, 0.2, 0.2)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var p := Vector3(sx * 0.68, 0, sz * 0.68)
			cyl(r, 0.22, 0.22, 0.13, p + Vector3(0, 0.165, 0), ORANGE, Vector3.ZERO, 10)
			for i in 5:
				torus(r, 0.1, 0.022, p + Vector3(0, 0.27 + i * 0.06, 0), GREY, Vector3.ZERO, steel)
	box(r, Vector3(1.8, 0.07, 1.8), Vector3(0, 0.6, 0), Color("3b424d"))
	box(r, Vector3(1.7, 0.025, 1.7), Vector3(0, 0.647, 0), BRASS, Vector3.ZERO, mat(BRASS, 0.05, Vector3.UP, 0.5, 0.25))
	cyl(r, 0.1, 0.1, 0.8, Vector3(0.1, 0.76, 0.1), GREEN, Vector3(0, 25, 90))
	for s in [-1, 1]:
		var cap := cyl(r, 0.115, 0.115, 0.1, Vector3(0.1, 0.76, 0.1), YELLOW, Vector3(0, 25, 90))
		cap.translate_object_local(Vector3(0, s * 0.42, 0))
	box(r, Vector3(0.5, 0.012, 0.7), Vector3(-0.45, 0.668, 0.45), WHITE, Vector3(0, 18, 0))


func _nozzle() -> void:
	var r := group(0.0)
	var m := mat(BRASS, 0.03, Vector3.UP, 0.22, 0.45)
	cyl(r, 0.28, 0.28, 0.52, Vector3(0, 0.26, 0), BRASS, Vector3.ZERO, 48, m)
	for i in 6:
		torus(r, 0.285, 0.035, Vector3(0, 0.06 + i * 0.08, 0), BRASS, Vector3.ZERO, m)
	cyl(r, 0.5, 0.5, 0.36, Vector3(0, 0.7, 0), BRASS, Vector3(0, 12, 0), 6, m)
	cyl(r, 0.44, 0.1, 0.55, Vector3(0, 1.155, 0), BRASS, Vector3.ZERO, 48, m)
	cyl(r, 0.1, 0.085, 0.09, Vector3(0, 1.47, 0), BRASS, Vector3.ZERO, 32, m)
	cyl(r, 0.035, 0.035, 0.02, Vector3(0, 1.52, 0), Color("0c0f14"))
	stick(r, Vector3(0.75, 0.02, 0.4), Vector3(1.0, 1.0, 0.2), 0.018, Color("e6ebf0"))
	stick(r, Vector3(1.0, 1.0, 0.2), Vector3(1.07, 1.28, 0.14), 0.07, BLUE)


func _estop() -> void:
	var r := group(30.0)
	box(r, Vector3(1.35, 0.6, 1.35), Vector3(0, 0.3, 0), YELLOW)
	cyl(r, 0.52, 0.52, 0.12, Vector3(0, 0.66, 0), DARK)
	cyl(r, 0.26, 0.26, 0.26, Vector3(0, 0.84, 0), Color("3b424d"))
	cyl(r, 0.62, 0.54, 0.2, Vector3(0, 1.05, 0), RED)
	ball(r, 0.54, Vector3(0, 1.14, 0), RED, Vector3(1, 0.36, 1))
	label(r, "STOP", 30, Vector3(0, 0.3, 0.68), DARK)


func _gear_points(teeth: int, root_r: float, tip_r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var step := TAU / teeth
	for i in teeth:
		var a := i * step
		pts.append(Vector2(cos(a - step * 0.24), sin(a - step * 0.24)) * root_r)
		pts.append(Vector2(cos(a - step * 0.13), sin(a - step * 0.13)) * tip_r)
		pts.append(Vector2(cos(a + step * 0.13), sin(a + step * 0.13)) * tip_r)
		pts.append(Vector2(cos(a + step * 0.24), sin(a + step * 0.24)) * root_r)
	return pts


func _gear(parent: Node3D, teeth: int, root_r: float, tip_r: float, pos: Vector3, col: Color, spin: float) -> void:
	var g := csg(parent, pos, Vector3(90, 0, spin))
	var m := mat(col, 0.035, Vector3.UP, 0.34)
	var body := CSGPolygon3D.new()
	body.polygon = _gear_points(teeth, root_r, tip_r)
	body.depth = 0.24
	body.material = m
	g.add_child(body)
	var hole := CSGCylinder3D.new()
	hole.radius = root_r * 0.26
	hole.height = 1.0
	hole.sides = 6
	hole.rotation_degrees = Vector3(90, 0, 0)
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	hole.material = m
	g.add_child(hole)
	for i in 5:
		var a := i * TAU / 5.0
		var cut := CSGCylinder3D.new()
		cut.radius = root_r * 0.17
		cut.height = 1.0
		cut.sides = 24
		cut.position = Vector3(cos(a), sin(a), 0) * root_r * 0.62
		cut.rotation_degrees = Vector3(90, 0, 0)
		cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		cut.material = m
		g.add_child(cut)


func _gears() -> void:
	var r := group(-16.0)
	_gear(r, 16, 0.66, 0.8, Vector3(-0.48, 0.24, 0.05), ORANGE, 0.0)
	_gear(r, 10, 0.4, 0.54, Vector3(0.78, 0.24, -0.1), BLUE, 18.0)


func _scrap() -> void:
	var r := group(20.0)
	var m := mat(Color("35c6ff"), 0.02, Vector3.UP, 0.3, 0.3)
	for i in 5:
		torus(r, 0.55 - i * 0.012, 0.05, Vector3(sin(i * 1.7) * 0.03, 0.05 + i * 0.085, cos(i * 2.3) * 0.03), Color("35c6ff"), Vector3(sin(i * 1.3) * 4.0, 0, cos(i * 0.9) * 4.0), m)
	stick(r, Vector3(0.5, 0.42, 0.1), Vector3(1.15, 0.05, 0.5), 0.05, Color("35c6ff"))
