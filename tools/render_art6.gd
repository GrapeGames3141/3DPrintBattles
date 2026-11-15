extends "res://tools/render_art5.gd"
## Rigged creatures: each is modelled from printed parts on joints, then posed
## eight times (stand, crouch, stride, proud, wind-up, strike, low, hurt) and
## rendered into a full 4x2 sprite sheet, so it really moves on the bench, plus
## a raw single-colour print for cards not yet owned.
##
## Builders take a `stage`: evolution lines grow from one builder, the way a
## Pokemon or Digimon line keeps its look as it gets bigger and wilder.
##
##   godot --path . --disable-vsync -s tools/render_art6.gd              (all)
##   godot --path . --disable-vsync -s tools/render_art6.gd -- nozzlet   (some)

const SHEET_OUT := "res://assets/creatures/2d/%s_sprite_sheet.png"
const RAW_OUT := "res://assets/creatures/2d/raw/%s_raw_print.png"
const CELL := Vector2i(384, 512)
const RAW_GREY := Color("d9dde2")

## The eight poses, in sprite-sheet order. Every value defaults to 0.
##   bob    body up/down          pitch  body tilt (+ nose down)
##   head   head tilt (+ down)    tail   tail raise
##   stride legs swing            jaw    mouth open 0..1
##   arm    wings / claws raise   lean   body forward
##   squint eyes shut 0..1        spin   floating parts' turn
const POSES := [
	{},
	{"bob": -0.07, "pitch": 6.0, "head": 4.0, "tail": -8.0, "spin": 0.25},
	{"stride": 24.0, "bob": 0.03, "tail": 10.0, "spin": 0.5},
	{"tail": 32.0, "head": -10.0, "arm": 18.0, "spin": 0.75},
	{"pitch": -12.0, "lean": -0.1, "arm": 45.0, "head": -14.0, "jaw": 0.4, "tail": 18.0, "spin": 1.0},
	{"pitch": 14.0, "lean": 0.2, "jaw": 1.0, "arm": -25.0, "stride": -16.0, "tail": -10.0, "spin": 1.25},
	{"bob": -0.13, "pitch": 10.0, "head": 10.0, "tail": -12.0, "spin": 1.5},
	{"pitch": -9.0, "lean": -0.12, "squint": 1.0, "jaw": 0.5, "head": -20.0, "tail": -22.0, "arm": -10.0, "spin": 1.75},
]

var _raw := false


func _initialize() -> void:
	var only: Array = Array(OS.get_cmdline_user_args())
	await process_frame
	_build_studio()
	await process_frame
	vp.transparent_bg = true
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.glow_enabled = false
	plate.visible = false
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var jobs := {
		"nozzlet": [_nozzle_line, 1], "extrudrake": [_nozzle_line, 2], "infernozzle": [_nozzle_line, 3],
		"bytelet": [_byte_line, 1], "voxelion": [_byte_line, 2], "teravox": [_byte_line, 3],
	}
	for id in jobs:
		if only.is_empty() or only.has(id):
			await _rig_sheet(id, jobs[id][0], int(jobs[id][1]))
	quit()


# ------------------------------------------------------------- rendering

func _p(pose: Dictionary, key: String) -> float:
	return float(pose.get(key, 0.0))


func _build(builder: Callable, stage: int, pose: Dictionary) -> Node3D:
	_clear()
	var root := group(-28.0)
	builder.call(root, pose, stage)
	return root


## Frames the camera on the creature's standing pose, then keeps it fixed for
## every pose so the frames line up when they are swapped on the bench.
func _frame(root: Node3D, aspect: float, stage := 3) -> void:
	var box := AABB()
	var first := true
	for n in _meshes(root):
		var mi := n as MeshInstance3D
		var b: AABB = mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var h := box.size.y
	var w := maxf(box.size.x, box.size.z)
	var span := maxf(h * 1.22, w * 1.06 / aspect)
	# Earlier stages of an evolution line stand smaller in their frame, so the
	# line visibly grows.
	span *= [1.14, 1.05, 1.0][clampi(stage, 1, 3) - 1]
	cam.size = span
	var look_y := box.position.y + span * 0.5 - h * 0.05 - span * 0.06
	var e := deg_to_rad(10.0)
	var c := box.get_center()
	cam.position = Vector3(c.x, look_y + sin(e) * 20.0, c.z + cos(e) * 20.0)
	cam.look_at(Vector3(c.x, look_y, c.z))


func _meshes(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		out.append_array(_meshes(c))
	return out


func _rig_sheet(id: String, builder: Callable, stage: int) -> void:
	_raw = false
	vp.size = CELL
	var rest := _build(builder, stage, POSES[0])
	await _settle()
	_frame(rest, float(CELL.x) / CELL.y, stage)
	var sheet := Image.create(CELL.x * 4, CELL.y * 2, false, Image.FORMAT_RGBA8)
	for i in POSES.size():
		_build(builder, stage, POSES[i])
		await _settle()
		var img := vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % 4) * CELL.x, (i / 4) * CELL.y))
	sheet.save_png(ProjectSettings.globalize_path(SHEET_OUT % id))
	# The raw print: the standing pose in one plain filament colour, bigger.
	_raw = true
	var keep := cam.size
	vp.size = Vector2i(1254, 1254)
	cam.size = keep * 1.0
	_build(builder, stage, POSES[0])
	await _settle()
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(RAW_OUT % id))
	_raw = false
	print("rigged ", id)


# ---------------------------------------------------- materials, raw-aware

func mat(col: Color, layer := 0.035, axis := Vector3.UP, rough := 0.36, depth := 0.6) -> ShaderMaterial:
	return super(RAW_GREY if _raw else col, layer, axis, rough, depth)


func gloss(col: Color, glow := 0.0, alpha := 1.0, rough := 0.1) -> StandardMaterial3D:
	if _raw:
		return super(RAW_GREY, 0.0, 1.0, 0.4)
	return super(col, glow, alpha, rough)


func metal_mat(col: Color) -> StandardMaterial3D:
	return super(RAW_GREY if _raw else col)


func joint(parent: Node3D, pos: Vector3, rot := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	_place(parent, n, pos, rot)
	return n


## An eye on the side of a head that faces the camera, looking forward (+x).
func side_eye(p: Node3D, pos: Vector3, r: float, squint: float, iris := Color("10151c")) -> void:
	if squint > 0.5:
		box(p, Vector3(r * 1.6, r * 0.28, r * 0.5), pos + Vector3(0, 0, r * 0.6), Color("10151c"), Vector3(0, 0, -12), null, 0.01)
		return
	ball(p, r, pos, WHITE)
	ball(p, r * 0.58, pos + Vector3(r * 0.32, -r * 0.04, r * 0.7), iris)
	ball(p, r * 0.18, pos + Vector3(r * 0.5, r * 0.26, r * 1.02), WHITE)


## A chain of rods that bends steadily: tails, necks, filament.
func chain(p: Node3D, start: Vector3, dir: Vector3, length: float, bend_deg: float, r0: float, r1: float, col: Color, n := 7, tip := Color.TRANSPARENT) -> Vector3:
	var pos := start
	var d := dir.normalized()
	var rot_axis := Vector3.BACK
	for i in n:
		d = d.rotated(rot_axis, deg_to_rad(bend_deg) / n)
		var nx := pos + d * (length / n)
		var r := lerpf(r0, r1, float(i) / n)
		stick(p, pos, nx, r, col)
		ball(p, r, nx, col)
		pos = nx
	if tip.a > 0.0:
		glow(p, r1 * 2.4, pos, tip, 3.0)
	return pos


# --------------------------------------------------------- Nozzlet line
# A salamander whose head is a hot end: brass nozzle snout, a heater block for
# a body, a strand of filament for a tail. Extrudrake grows heat-sink fins and
# horns; Infernozzle spreads fan-blade wings and wears a crown of nozzles.

func _nozzle_line(c: Node3D, p: Dictionary, stage: int) -> void:
	var k: float = [1.0, 1.22, 1.45][stage - 1]
	c.scale = Vector3.ONE * k
	var hide := Color("e2452f") if stage < 3 else Color("c92a3a")
	var belly := Color("ffb347")
	var steel := Color("c7ced6")
	var fil := Color("ffcf3a") if stage < 3 else Color("ff8a2a")
	var body := joint(c, Vector3(_p(p, "lean"), 0.6 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch")))
	# The heater block body with its silicone sock, and the belly beneath.
	box(body, Vector3(0.95, 0.5, 0.58), Vector3(0, 0.02, 0), hide, Vector3.ZERO, null, 0.12)
	box(body, Vector3(0.8, 0.12, 0.5), Vector3(0.02, -0.24, 0), belly, Vector3.ZERO, null, 0.05)
	# A ridge of little cooling spikes down the back.
	for i in 3:
		cyl(body, 0.06, 0.0, 0.16, Vector3(-0.25 + i * 0.2, 0.31, 0), belly, Vector3(0, 0, 8), 12)
	if stage >= 2:
		for i in 4:
			box(body, Vector3(0.05, 0.22 + 0.04 * stage, 0.44), Vector3(-0.3 + i * 0.16, 0.34, 0), steel, Vector3(0, 0, -8), metal_mat(steel), 0.01)
	# Legs: front pair swing forward on a stride, rear pair back; the front
	# paws come up on a wind-up.
	for side: float in [-1.0, 1.0]:
		for front: bool in [true, false]:
			var swing := _p(p, "stride") * (1.0 if front else -1.0) * side
			if front:
				swing += maxf(_p(p, "arm"), 0.0) * 0.6
			var hip := joint(body, Vector3(0.3 if front else -0.32, -0.16, side * 0.24), Vector3(0, 0, swing))
			stick(hip, Vector3.ZERO, Vector3(0.04, -0.3, 0), 0.075, hide.darkened(0.12))
			ball(hip, 0.09, Vector3(0.06, -0.38, 0), belly, Vector3(1.4, 0.7, 1.2))
	# The tail: a strand of filament curling up, glowing at the end.
	var tail := joint(body, Vector3(-0.45, 0.04, 0), Vector3(0, 0, 18.0 + _p(p, "tail")))
	chain(tail, Vector3.ZERO, Vector3(-1, 0.1, 0), 0.75 + 0.15 * stage, 80.0, 0.085, 0.03, fil, 8, Color("ffd36a") if stage >= 2 else Color.TRANSPARENT)
	# Wings (Extrudrake: small fans; Infernozzle: big fan-blade wings).
	if stage >= 2:
		# Fan-blade wings: overlapping printed blades spread like a fan.
		for side: float in [-1.0, 1.0]:
			var wing := joint(body, Vector3(-0.05, 0.28, side * 0.2), Vector3(side * 12.0, 0, 20.0 + _p(p, "arm")))
			var span := 0.5 if stage == 2 else 0.95
			var blades := 3 if stage == 2 else 5
			for b in blades:
				var a := deg_to_rad(100.0 + b * (24.0 if stage == 2 else 17.0))
				var dir := Vector3(cos(a), sin(a), 0)
				var len_b := span * (1.0 - 0.12 * b)
				var col := hide.lightened(0.1 + 0.08 * b) if b % 2 == 0 else belly
				box(wing, Vector3(len_b, 0.15, 0.035), dir * len_b * 0.5, col, Vector3(0, 0, rad_to_deg(a)), null, 0.03)
			stick(wing, Vector3.ZERO, Vector3(cos(deg_to_rad(100.0)), sin(deg_to_rad(100.0)), 0) * span, 0.035, steel)
	# A big friendly head (chibi proportions), the nozzle for a snout.
	var head := joint(body, Vector3(0.5, 0.24, 0), Vector3(0, 0, -_p(p, "head")))
	ball(head, 0.36, Vector3(0.12, 0.12, 0), hide, Vector3(1.08, 0.95, 1.0))
	ball(head, 0.2, Vector3(0.3, -0.06, 0.0), belly, Vector3(1.2, 0.7, 1.25))
	cyl(head, 0.13, 0.045, 0.3, Vector3(0.54, 0.0, 0), BRASS, Vector3(0, 0, -90), 24, metal_mat(BRASS))
	torus(head, 0.13, 0.025, Vector3(0.4, 0.0, 0), steel, Vector3(0, 0, 90), metal_mat(steel))
	glow(head, 0.05 + 0.02 * stage, Vector3(0.71, 0.0, 0), Color("ff9a2a"), 3.5)
	var jaw := joint(head, Vector3(0.18, -0.12, 0), Vector3(0, 0, -_p(p, "jaw") * 28.0))
	box(jaw, Vector3(0.36, 0.08, 0.34), Vector3(0.14, -0.04, 0), belly, Vector3.ZERO, null, 0.04)
	if _p(p, "jaw") > 0.3:
		glow(head, 0.07, Vector3(0.32, -0.14, 0), Color("ffb347"), 2.0)
	side_eye(head, Vector3(0.22, 0.26, 0.24), 0.135, _p(p, "squint"))
	side_eye(head, Vector3(0.22, 0.26, -0.24), 0.135, _p(p, "squint"))
	for side: float in [-1.0, 1.0]:
		ball(head, 0.05, Vector3(0.3, 0.08, side * 0.3), Color("ff8fa0"), Vector3(1.0, 0.6, 0.4))
	if stage >= 2:
		for side: float in [-1.0, 1.0]:
			stick(head, Vector3(-0.05, 0.22, side * 0.12), Vector3(-0.3, 0.48, side * 0.18), 0.035, steel)
			ball(head, 0.05, Vector3(-0.3, 0.48, side * 0.18), BRASS)
	if stage >= 3:
		for i in 3:
			var at := Vector3(-0.02 + i * 0.1, 0.3, (i - 1) * 0.1)
			cyl(head, 0.05, 0.02, 0.14, at, BRASS, Vector3(0, 0, 10), 16, metal_mat(BRASS))
			glow(head, 0.03, at + Vector3(0, 0.08, 0), Color("ff9a2a"), 3.0)


# ---------------------------------------------------------- Bytelet line
# A little program that printed itself: Bytelet is a floating cube with a
# pixel face and an antenna; Voxelion grows legs, a cube mane and a tail of
# bits; Teravox spreads wings of voxels and wears a glowing crown.

func _byte_line(c: Node3D, p: Dictionary, stage: int) -> void:
	var k: float = [0.9, 1.2, 1.45][stage - 1]
	c.scale = Vector3.ONE * k
	var violet := Color("8a55f0")
	var cyan := Color("4ad8ff")
	var dark := Color("1b1530")
	var spin := _p(p, "spin")
	if stage == 1:
		var body := joint(c, Vector3(_p(p, "lean"), 0.75 + _p(p, "bob") * 1.5, 0), Vector3(0, 0, -_p(p, "pitch") * 1.2))
		box(body, Vector3(0.6, 0.6, 0.6), Vector3.ZERO, violet, Vector3.ZERO, null, 0.07)
		_pixel_face(body, Vector3(0.301, 0.04, 0.0), 0.62, _p(p, "squint"), _p(p, "jaw"), cyan, dark)
		for side: float in [-1.0, 1.0]:
			box(body, Vector3(0.14, 0.2, 0.06), Vector3(-0.02, -0.05, side * 0.33), cyan, Vector3(0, 0, -20.0 - _p(p, "arm") * 0.6), null, 0.02)
		stick(body, Vector3(-0.05, 0.3, 0), Vector3(-0.12 - _p(p, "tail") * 0.004, 0.62, 0.0), 0.025, cyan)
		glow(body, 0.07, Vector3(-0.12 - _p(p, "tail") * 0.004, 0.66, 0.0), cyan, 3.5)
		# Bits orbit it like electrons.
		for i in 4:
			var a := TAU * (i / 4.0 + spin * 0.25)
			box(c, Vector3(0.09, 0.09, 0.09), Vector3(cos(a) * 0.55, 0.75 + sin(a * 2.0) * 0.1 + _p(p, "bob"), sin(a) * 0.55), cyan if i % 2 else violet, Vector3(30, a * 40.0, 10), null, 0.01)
		# Little thruster jets of light keep it up.
		glow(c, 0.06, Vector3(0, 0.36 + _p(p, "bob"), 0), cyan, 2.0)
		return
	var body := joint(c, Vector3(_p(p, "lean"), 0.62 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch")))
	box(body, Vector3(0.95, 0.46, 0.5), Vector3.ZERO, violet, Vector3.ZERO, null, 0.05)
	for i in 4:
		box(body, Vector3(0.12, 0.12, 0.52), Vector3(-0.36 + i * 0.24, 0.22, 0), cyan if i % 2 == 0 else violet.lightened(0.15), Vector3.ZERO, null, 0.01)
	for side: float in [-1.0, 1.0]:
		for front: bool in [true, false]:
			var swing := _p(p, "stride") * (1.0 if front else -1.0) * side
			if front:
				swing += maxf(_p(p, "arm"), 0.0) * 0.5
			var hip := joint(body, Vector3(0.32 if front else -0.34, -0.18, side * 0.17), Vector3(0, 0, swing))
			box(hip, Vector3(0.15, 0.36, 0.15), Vector3(0, -0.18, 0), violet.darkened(0.1), Vector3.ZERO, null, 0.02)
			box(hip, Vector3(0.2, 0.08, 0.18), Vector3(0.03, -0.38, 0), cyan, Vector3.ZERO, null, 0.02)
	var tail := joint(body, Vector3(-0.48, 0.12, 0), Vector3(0, 0, 25.0 + _p(p, "tail")))
	var pos := Vector3.ZERO
	for i in 5:
		pos += Vector3(-0.13, 0.05 + i * 0.03, 0)
		box(tail, Vector3(0.13 - i * 0.015, 0.13 - i * 0.015, 0.13 - i * 0.015), pos, violet if i % 2 else cyan, Vector3(0, 0, i * 8.0), null, 0.01)
	glow(tail, 0.07, pos + Vector3(-0.1, 0.04, 0), cyan, 3.0)
	if stage >= 3:
		var wing := joint(body, Vector3(-0.05, 0.28, -0.1), Vector3(0, 0, 18.0 + _p(p, "arm")))
		for r in 4:
			for q in 4 - r:
				box(wing, Vector3(0.14, 0.14, 0.05), Vector3(-0.1 - q * 0.16, 0.12 + r * 0.16, -0.02), cyan if (q + r) % 2 == 0 else violet.lightened(0.25), Vector3.ZERO, gloss(cyan if (q + r) % 2 == 0 else violet.lightened(0.25), 0.6, 0.9, 0.3), 0.0)
	var head := joint(body, Vector3(0.55, 0.26, 0), Vector3(0, 0, -_p(p, "head")))
	box(head, Vector3(0.46, 0.46, 0.46), Vector3(0.1, 0.05, 0), violet, Vector3.ZERO, null, 0.05)
	_pixel_face(head, Vector3(0.331, 0.05, 0.0), 0.5, _p(p, "squint"), _p(p, "jaw"), cyan, dark)
	# The mane: a ring of cubes around the back of the head.
	for i in 9:
		var a := -PI * 0.5 + PI * float(i) / 8.0
		box(head, Vector3(0.13, 0.13, 0.13), Vector3(-0.12, 0.05 + sin(a) * 0.3, cos(a) * 0.3), cyan if i % 2 == 0 else Color("ffcf3a"), Vector3(0, 0, i * 15.0), null, 0.01)
	if stage >= 3:
		for i in 3:
			box(head, Vector3(0.07, 0.16 + (0.06 if i == 1 else 0.0), 0.07), Vector3(0.0 + i * 0.1, 0.36, (i - 1) * 0.1), Color("ffcf3a"), Vector3.ZERO, gloss(Color("ffcf3a"), 1.2), 0.01)


## Pixel eyes and mouth on the front face of a cube head (`at` is the face centre).
func _pixel_face(p: Node3D, at: Vector3, s: float, squint: float, jaw: float, light: Color, dark: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var e := at + Vector3(0, s * 0.14, side * s * 0.22)
		if squint > 0.5:
			box(p, Vector3(0.02, s * 0.05, s * 0.2), e, dark, Vector3.ZERO, null, 0.0)
		else:
			box(p, Vector3(0.02, s * 0.22, s * 0.16), e, dark, Vector3.ZERO, null, 0.0)
			box(p, Vector3(0.025, s * 0.07, s * 0.06), e + Vector3(0, s * 0.05, s * 0.03), light, Vector3.ZERO, gloss(light, 1.5), 0.0)
	var mouth_h := s * (0.05 + jaw * 0.14)
	box(p, Vector3(0.02, mouth_h, s * 0.26), at + Vector3(0, -s * 0.2, 0), dark, Vector3.ZERO, null, 0.0)
