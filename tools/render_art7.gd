extends "res://tools/render_art6.gd"
## Wave 6 art. Every new creature is built from its `look` (written by
## tools/catalog/build.py into tools/catalog/looks.json): a body plan, its
## element and a seed. The seed picks the build (heads, ears, horns, tails,
## crests, spikes, wings, eyes), so no two prints share a body. Each is posed
## in all eight frames. New tools are modelled on the print bed and new
## equipment as cut-out props, each with its own little build.
##
##   godot --path . --disable-vsync -s tools/render_art7.gd                 (all)
##   godot --path . --disable-vsync -s tools/render_art7.gd -- creatures    (all creatures)
##   godot --path . --disable-vsync -s tools/render_art7.gd -- ashling       (some)

const LOOKS := "res://tools/catalog/looks.json"
const TOOL_OUT := "res://assets/tools/%s.png"

## Element palettes: body, second colour, accent, glow.
const PAL := {
	"Fire": [Color("e8492e"), Color("ffb347"), Color("ffd84a"), Color("ff8a2a")],
	"Water": [Color("3a8ee8"), Color("bfe9ff"), Color("23c4c4"), Color("6ad8ff")],
	"Lightning": [Color("ffcf2e"), Color("2b2f3a"), Color("5fe6ff"), Color("fff27a")],
	"Nature": [Color("56b84a"), Color("8a5a32"), Color("ff8fc0"), Color("b6ff6a")],
	"Ice": [Color("9fdcff"), Color("f4fbff"), Color("8f8cf0"), Color("c8f2ff")],
	"Stone": [Color("8d8a86"), Color("6b5a48"), Color("e9a91c"), Color("ffb84a")],
	"Wind": [Color("7fe0c4"), Color("f2f6f8"), Color("7fb8ff"), Color("c6fff0")],
	"Arcane": [Color("8a55f0"), Color("e05ad8"), Color("ffcf3a"), Color("c9a0ff")],
	"Neutral": [Color("ff8a2a"), Color("eef1f4"), Color("2f8cf0"), Color("ffd36a")],
}

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	var only: Array = Array(OS.get_cmdline_user_args())
	await process_frame
	_build_studio()
	await process_frame
	var looks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LOOKS))
	var want_all := only.is_empty()
	# Tools first (on the bed, like the other tool art).
	for id in TOOLS_BUILT:
		if want_all or only.has(id) or only.has("tools"):
			_clear()
			cam.projection = Camera3D.PROJECTION_PERSPECTIVE
			cam.fov = 30.0
			vp.transparent_bg = false
			env.background_mode = Environment.BG_COLOR
			env.glow_enabled = true
			plate.visible = true
			vp.size = SIZE
			var r := group(-20.0)
			_holder = r
			call("_t_" + id, r)
			_holder = stage
			_aim(32.0, 4.8, 0.5)
			await _settle()
			vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(TOOL_OUT % id))
			print("tool ", id)
	# Equipment: cut-out props.
	for id in GEAR_BUILT:
		if want_all or only.has(id) or only.has("gear"):
			_clear()
			cam.projection = Camera3D.PROJECTION_PERSPECTIVE
			cam.fov = 30.0
			vp.transparent_bg = true
			env.background_mode = Environment.BG_CLEAR_COLOR
			env.glow_enabled = false
			plate.visible = false
			vp.size = Vector2i(512, 512)
			var r := group(-24.0)
			_holder = r
			call("_g_" + id, r)
			_holder = stage
			_aim(14.0, 4.6, 0.55)
			await _settle()
			vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(ARMOR_OUT % id))
			print("gear ", id)
	# Creatures.
	vp.transparent_bg = true
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.glow_enabled = false
	plate.visible = false
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	for id in looks:
		if want_all or only.has(id) or only.has("creatures"):
			var lk: Dictionary = looks[id]
			await _rig_sheet(id, _gen.bind(lk), int(lk.get("stage", _stage_for(lk))))
	quit()


func _stage_for(lk: Dictionary) -> int:
	return 2


# =================================================================== creatures

func _pick(arr: Array):
	return arr[_rng.randi() % arr.size()]


func _gen(c: Node3D, p: Dictionary, stage: int, lk: Dictionary) -> void:
	_rng.seed = int(lk["seed"])
	var pal: Array = PAL.get(str(lk["element"]), PAL["Neutral"])
	var hue_shift := _rng.randf_range(-0.04, 0.04)
	var body_col: Color = (pal[0] as Color)
	body_col = Color.from_hsv(fposmod(body_col.h + hue_shift, 1.0), clampf(body_col.s * _rng.randf_range(0.85, 1.1), 0, 1), body_col.v)
	var cols := {"body": body_col, "second": pal[1], "accent": pal[2], "glow": pal[3], "el": str(lk["element"]), "bull": bool(lk.get("bull", false)), "cyclops": bool(lk.get("cyclops", false))}
	var k: float = [0.9, 1.0, 1.2][clampi(stage, 1, 3) - 1]
	c.scale = Vector3.ONE * k
	match str(lk["plan"]):
		"biped":
			_plan_biped(c, p, cols)
		"bird":
			_plan_bird(c, p, cols)
		"serpent":
			_plan_serpent(c, p, cols)
		"bug":
			_plan_bug(c, p, cols, bool(lk.get("swarm", false)), bool(lk.get("crown", false)))
		"blob":
			_plan_blob(c, p, cols)
		"fish":
			_plan_fish(c, p, cols)
		"floater":
			_plan_floater(c, p, cols)
		"shell":
			_plan_shell(c, p, cols)
		"boat":
			_plan_boat(c, p, cols)
		"part":
			_plan_part(c, p, cols, str(lk.get("part", "")))
		"dragon":
			_plan_dragon(c, p, cols, lk)
		"horse":
			_plan_horse(c, p, cols, lk)
		"beast":
			_plan_beast(c, p, cols, lk)
		"hydra":
			_plan_hydra(c, p, cols, lk)
		"kraken":
			_plan_kraken(c, p, cols)
		"egg":
			_plan_egg(c, p, cols)
		"phoenix":
			_plan_phoenix(c, p, cols)
		_:
			_plan_quad(c, p, cols)


## A head facing +x: shape, face, ears or horns and a crest, chosen by the seed.
func _head(parent: Node3D, at: Vector3, r: float, p: Dictionary, cols: Dictionary) -> Node3D:
	var head := joint(parent, at, Vector3(0, 0, -_p(p, "head")))
	var shape: int = _rng.randi() % 4
	var body: Color = cols["body"]
	match shape:
		0:
			ball(head, r, Vector3.ZERO, body, Vector3(1.1, 0.95, 1.0))
		1:
			box(head, Vector3(r * 1.9, r * 1.7, r * 1.8), Vector3.ZERO, body, Vector3.ZERO, null, r * 0.35)
		2:
			ball(head, r, Vector3.ZERO, body, Vector3(1.3, 0.85, 0.95))
		_:
			ball(head, r * 0.95, Vector3.ZERO, body)
			ball(head, r * 0.55, Vector3(r * 0.75, -r * 0.2, 0), cols["second"], Vector3(1.2, 0.8, 1.0))
	# Snout or beak-ish muzzle.
	var snout: int = _rng.randi() % 3
	if snout == 1:
		ball(head, r * 0.42, Vector3(r * 0.95, -r * 0.25, 0), cols["second"], Vector3(1.3, 0.8, 1.1))
		ball(head, r * 0.1, Vector3(r * 1.35, -r * 0.12, 0), Color("2b2f3a"))
	elif snout == 2:
		cyl(head, r * 0.28, r * 0.05, r * 0.7, Vector3(r * 1.15, -r * 0.1, 0), cols["accent"], Vector3(0, 0, -90), 16)
	# Mouth that opens with the jaw.
	var jaw := joint(head, Vector3(r * 0.6, -r * 0.45, 0), Vector3(0, 0, -_p(p, "jaw") * 26.0))
	box(jaw, Vector3(r * 0.8, r * 0.16, r * 1.0), Vector3(r * 0.2, -r * 0.05, 0), cols["second"].darkened(0.1), Vector3.ZERO, null, r * 0.06)
	if _p(p, "jaw") > 0.3:
		ball(head, r * 0.22, Vector3(r * 0.7, -r * 0.45, 0), Color("4a1020"), Vector3(1.4, 0.6, 1.4))
	# Eyes: two big ones, sometimes one or three.
	var eye_r := r * _rng.randf_range(0.3, 0.42)
	var eyes_n: int = _pick([2, 2, 2, 2, 1, 3])
	if bool(cols.get("cyclops", false)):
		eyes_n = 1
		eye_r *= 1.25
	var iris: Color = _pick([Color("10151c"), Color("10151c"), cols["accent"].darkened(0.5), Color("3a1a5a")])
	if eyes_n == 1:
		side_eye(head, Vector3(r * 0.55, r * 0.35, r * 0.62), eye_r * 1.25, _p(p, "squint"), iris)
	else:
		for side: float in [-1.0, 1.0]:
			side_eye(head, Vector3(r * 0.45, r * 0.3, side * r * 0.62), eye_r, _p(p, "squint"), iris)
		if eyes_n == 3:
			side_eye(head, Vector3(r * 0.35, r * 0.85, 0), eye_r * 0.7, _p(p, "squint"), iris)
	# Ears, horns, antlers, antennae or a crest.
	match _rng.randi() % 7:
		0:
			for side: float in [-1.0, 1.0]:
				cyl(head, r * 0.28, 0.0, r * 0.75, Vector3(-r * 0.15, r * 0.95, side * r * 0.45), body, Vector3(side * 18, 0, 10), 12)
		1:
			for side: float in [-1.0, 1.0]:
				ball(head, r * 0.32, Vector3(-r * 0.2, r * 0.85, side * r * 0.5), cols["second"], Vector3(0.6, 1.0, 1.0))
		2:
			for side: float in [-1.0, 1.0]:
				cyl(head, r * 0.13, 0.0, r * 0.95, Vector3(-r * 0.3, r * 0.95, side * r * 0.35), cols["accent"], Vector3(side * 12, 0, 35), 12)
		3:
			for side: float in [-1.0, 1.0]:
				var base := Vector3(-r * 0.2, r * 0.8, side * r * 0.3)
				var tip := chain(head, base, Vector3(-0.3, 1, side * 0.4), r * 1.2, -40.0, r * 0.07, r * 0.04, cols["second"], 4)
				ball(head, r * 0.12, tip, cols["glow"])
		4:
			for i in 4:
				box(head, Vector3(r * 0.5, r * 0.18, r * 0.1), Vector3(-r * 0.3 - i * r * 0.18, r * 0.85 - i * r * 0.1, 0), cols["accent"], Vector3(0, 0, 60 - i * 10), null, r * 0.04)
		5:
			for side: float in [-1.0, 1.0]:
				stick(head, Vector3(0, r * 0.8, side * r * 0.25), Vector3(-r * 0.2, r * 1.6, side * r * 0.45), r * 0.05, Color("2b2f3a"))
				ball(head, r * 0.13, Vector3(-r * 0.2, r * 1.6, side * r * 0.45), cols["glow"])
		_:
			pass
	_element_bits(head, Vector3(-r * 0.1, r * 0.9, 0), r * 0.5, cols)
	return head


## A touch of the element on top of the head or back: flames, bolts, leaves,
## crystals, rocks, feathers, runes or bubbles.
func _element_bits(parent: Node3D, at: Vector3, s: float, cols: Dictionary) -> void:
	if _rng.randf() < 0.35:
		return
	var glow_c: Color = cols["glow"]
	match str(cols["el"]):
		"Fire":
			for i in 3:
				cyl(parent, s * 0.22, 0.0, s * (0.6 + 0.2 * i), at + Vector3(-s * 0.3 * i, s * 0.2, 0), cols["accent"] if i != 1 else cols["second"], Vector3(0, 0, 15 + i * 10), 12, gloss(cols["accent"], 1.2, 1.0, 0.3))
		"Lightning":
			var a := at
			for i in 3:
				var b := a + Vector3(-s * 0.25, s * 0.35, (i % 2) * s * 0.2 - s * 0.1)
				stick(parent, a, b, s * 0.07, glow_c)
				a = b
		"Nature":
			for i in 2:
				box(parent, Vector3(s * 0.6, s * 0.08, s * 0.35), at + Vector3(-s * 0.2 * i, s * 0.2, (i - 0.5) * s * 0.4), cols["body"].lightened(0.15), Vector3(20 * (i * 2 - 1), 0, 30), null, s * 0.05)
			ball(parent, s * 0.15, at + Vector3(0, s * 0.3, 0), cols["accent"])
		"Ice":
			for i in 3:
				cyl(parent, s * 0.12, 0.0, s * (0.5 + 0.25 * (i % 2)), at + Vector3(-s * 0.2 * i, s * 0.15, (i - 1) * s * 0.2), glow_c, Vector3((i - 1) * 15, 0, 10), 6, gloss(glow_c, 0.3, 0.85, 0.05))
		"Stone":
			for i in 2:
				box(parent, Vector3(s * 0.35, s * 0.3, s * 0.3), at + Vector3(-s * 0.3 * i, s * 0.05, (i - 0.5) * s * 0.3), cols["second"], Vector3(i * 30, 20, 15), null, s * 0.06)
		"Wind":
			for i in 3:
				box(parent, Vector3(s * 0.7, s * 0.12, s * 0.05), at + Vector3(-s * 0.25 * i, s * 0.15 * i, 0), cols["second"], Vector3(0, 0, 40 + i * 12), null, s * 0.04)
		"Arcane":
			glow(parent, s * 0.18, at + Vector3(0, s * 0.35, 0), glow_c, 3.0)
			torus(parent, s * 0.3, s * 0.03, at + Vector3(0, s * 0.35, 0), cols["accent"], Vector3(70, 0, 0), gloss(cols["accent"], 0.8))
		"Water":
			for i in 3:
				ball(parent, s * (0.1 + 0.04 * i), at + Vector3(-s * 0.2 * i, s * (0.2 + 0.25 * i), 0), glow_c)
		_:
			cyl(parent, s * 0.2, s * 0.08, s * 0.4, at + Vector3(0, s * 0.2, 0), BRASS, Vector3.ZERO, 16, metal_mat(BRASS))


## Legs that swing with the stride; `front` decides the direction of the swing.
func _legs4(body: Node3D, p: Dictionary, cols: Dictionary, half_len: float, half_w: float, y: float, length: float, r: float) -> void:
	var style: int = _rng.randi() % 3
	for side: float in [-1.0, 1.0]:
		for front: bool in [true, false]:
			var swing: float = _p(p, "stride") * (1.0 if front else -1.0) * side
			if front:
				swing += maxf(_p(p, "arm"), 0.0) * 0.6
			var hip := joint(body, Vector3(half_len if front else -half_len, y, side * half_w), Vector3(0, 0, swing))
			match style:
				0:
					stick(hip, Vector3.ZERO, Vector3(0.03, -length, 0), r, cols["body"].darkened(0.12))
					ball(hip, r * 1.25, Vector3(0.06, -length - r * 0.2, 0), cols["second"], Vector3(1.4, 0.7, 1.2))
				1:
					box(hip, Vector3(r * 2.2, length, r * 2.2), Vector3(0, -length * 0.5, 0), cols["body"].darkened(0.1), Vector3.ZERO, null, r * 0.4)
					box(hip, Vector3(r * 2.8, r * 0.9, r * 2.6), Vector3(r * 0.4, -length, 0), cols["second"], Vector3.ZERO, null, r * 0.3)
				_:
					var knee := Vector3(r * 0.8, -length * 0.5, 0)
					stick(hip, Vector3.ZERO, knee, r, cols["body"].darkened(0.1))
					stick(hip, knee, Vector3(0, -length, 0), r * 0.85, cols["body"].darkened(0.2))
					ball(hip, r * 1.1, Vector3(0.04, -length - r * 0.1, 0), cols["accent"], Vector3(1.5, 0.6, 1.2))


func _tail(body: Node3D, at: Vector3, p: Dictionary, cols: Dictionary, size: float) -> void:
	var tail := joint(body, at, Vector3(0, 0, 15.0 + _p(p, "tail")))
	match _rng.randi() % 5:
		0:
			chain(tail, Vector3.ZERO, Vector3(-1, 0.2, 0), size * 1.1, 70.0, size * 0.12, size * 0.04, cols["body"], 7, cols["glow"] if _rng.randf() < 0.5 else Color.TRANSPARENT)
		1:
			stick(tail, Vector3.ZERO, Vector3(-size * 0.35, size * 0.25, 0), size * 0.08, cols["body"])
			ball(tail, size * 0.28, Vector3(-size * 0.5, size * 0.4, 0), cols["second"])
		2:
			var end := chain(tail, Vector3.ZERO, Vector3(-1, 0.4, 0), size * 0.8, 30.0, size * 0.1, size * 0.06, cols["body"], 5)
			cyl(tail, size * 0.2, 0.0, size * 0.5, end + Vector3(-size * 0.1, size * 0.1, 0), cols["accent"], Vector3(0, 0, 60), 4)
		3:
			for i in 3:
				box(tail, Vector3(size * 0.6, size * 0.12, size * 0.05), Vector3(-size * 0.3, size * 0.1 * i, (i - 1) * size * 0.1), cols["second"] if i == 1 else cols["body"], Vector3((i - 1) * 20, 0, 30 + i * 10), null, size * 0.04)
		_:
			ball(tail, size * 0.2, Vector3(-size * 0.15, size * 0.05, 0), cols["second"])


func _back(body: Node3D, len_x: float, top: float, cols: Dictionary) -> void:
	match _rng.randi() % 5:
		0:
			for i in 4:
				cyl(body, 0.07, 0.0, 0.2, Vector3(-len_x * 0.6 + i * len_x * 0.4, top, 0), cols["accent"], Vector3(0, 0, 10), 8)
		1:
			for i in 3:
				box(body, Vector3(0.05, 0.25, len_x * 0.5), Vector3(-len_x * 0.4 + i * len_x * 0.35, top + 0.08, 0), cols["second"], Vector3(0, 0, -10), null, 0.02)
		2:
			box(body, Vector3(len_x * 1.4, 0.06, 0.5), Vector3(0, top, 0), cols["second"], Vector3.ZERO, null, 0.03)
		3:
			for i in 5:
				ball(body, 0.08, Vector3(-len_x * 0.7 + i * len_x * 0.35, top + 0.03, 0), cols["glow"])
		_:
			pass


func _plan_quad(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var len_x := _rng.randf_range(0.38, 0.55)
	var tall := _rng.randf_range(0.42, 0.6)
	var leg := _rng.randf_range(0.28, 0.42)
	var body := joint(c, Vector3(_p(p, "lean"), leg + tall * 0.5 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch")))
	if _rng.randf() < 0.5:
		box(body, Vector3(len_x * 2.0, tall, tall * 1.05), Vector3.ZERO, cols["body"], Vector3.ZERO, null, tall * 0.25)
	else:
		ball(body, tall * 0.62, Vector3.ZERO, cols["body"], Vector3(len_x / (tall * 0.62) * 1.05, 0.85, 0.95))
	box(body, Vector3(len_x * 1.6, tall * 0.18, tall * 0.85), Vector3(0.02, -tall * 0.45, 0), cols["second"], Vector3.ZERO, null, tall * 0.08)
	_back(body, len_x, tall * 0.5, cols)
	_legs4(body, p, cols, len_x * 0.7, tall * 0.4, -tall * 0.3, leg, _rng.randf_range(0.06, 0.09))
	_tail(body, Vector3(-len_x, tall * 0.1, 0), p, cols, _rng.randf_range(0.6, 0.9))
	_head(body, Vector3(len_x + 0.15, tall * 0.45, 0), _rng.randf_range(0.28, 0.36), p, cols)


func _plan_shell(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.45 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch") * 0.6))
	ball(body, 0.62, Vector3(0, 0.15, 0), cols["second"], Vector3(1.15, 0.8, 1.0))
	for i in 6:
		var a := TAU * i / 6.0
		box(body, Vector3(0.28, 0.06, 0.28), Vector3(cos(a) * 0.38, 0.55, sin(a) * 0.38), cols["accent"], Vector3(0, rad_to_deg(a), 18), null, 0.05)
	_element_bits(body, Vector3(0, 0.65, 0), 0.5, cols)
	box(body, Vector3(1.3, 0.12, 1.0), Vector3(0, -0.15, 0), cols["body"], Vector3.ZERO, null, 0.05)
	_legs4(body, p, cols, 0.42, 0.35, -0.15, 0.28, 0.1)
	_tail(body, Vector3(-0.65, -0.05, 0), p, cols, 0.5)
	var neck := joint(body, Vector3(0.6, 0.0, 0), Vector3(0, 0, 0))
	stick(neck, Vector3.ZERO, Vector3(0.2, 0.18, 0), 0.12, cols["body"])
	_head(neck, Vector3(0.32, 0.3, 0), 0.3, p, cols)


func _plan_biped(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var leg := _rng.randf_range(0.4, 0.55)
	var torso := _rng.randf_range(0.55, 0.75)
	var wide := _rng.randf_range(0.42, 0.6)
	var body := joint(c, Vector3(_p(p, "lean"), leg + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch") * 0.7))
	var chunky := _rng.randf() < 0.55
	if chunky:
		box(body, Vector3(wide * 0.9, torso, wide * 1.2), Vector3(0, torso * 0.5, 0), cols["body"], Vector3.ZERO, null, wide * 0.15)
	else:
		ball(body, torso * 0.55, Vector3(0, torso * 0.5, 0), cols["body"], Vector3(0.8, 1.0, 1.0))
	box(body, Vector3(wide * 0.7, torso * 0.35, wide * 1.0), Vector3(wide * 0.15, torso * 0.4, 0), cols["second"], Vector3.ZERO, null, wide * 0.1)
	if _rng.randf() < 0.5:
		glow(body, 0.07, Vector3(wide * 0.5, torso * 0.55, 0), cols["glow"], 2.0)
	for side: float in [-1.0, 1.0]:
		var hip := joint(body, Vector3(0, 0.02, side * wide * 0.35), Vector3(0, 0, _p(p, "stride") * side))
		if chunky:
			box(hip, Vector3(0.2, leg, 0.2), Vector3(0, -leg * 0.5, 0), cols["body"].darkened(0.15), Vector3.ZERO, null, 0.05)
		else:
			stick(hip, Vector3.ZERO, Vector3(0, -leg, 0), 0.08, cols["body"].darkened(0.15))
		box(hip, Vector3(0.3, 0.1, 0.22), Vector3(0.06, -leg, 0), cols["second"], Vector3.ZERO, null, 0.04)
		var sh := joint(body, Vector3(0, torso * 0.85, side * (wide * 0.62 + 0.05)), Vector3(side * 8.0, 0, 20.0 + _p(p, "arm") * 1.4 - _p(p, "stride") * side * 0.5))
		var arm_len := torso * _rng.randf_range(0.7, 0.95)
		if chunky:
			box(sh, Vector3(0.18, arm_len, 0.18), Vector3(0, -arm_len * 0.5, 0), cols["body"].darkened(0.08), Vector3.ZERO, null, 0.05)
			ball(sh, 0.15, Vector3(0, -arm_len, 0), cols["accent"])
		else:
			stick(sh, Vector3.ZERO, Vector3(0.05, -arm_len, 0), 0.06, cols["body"].darkened(0.08))
			ball(sh, 0.09, Vector3(0.05, -arm_len, 0), cols["second"])
	_back(body, wide * 0.4, torso * 1.0, cols)
	if _rng.randf() < 0.3:
		_tail(body, Vector3(-wide * 0.45, torso * 0.2, 0), p, cols, 0.5)
	var head := _head(body, Vector3(0.05, torso + 0.25, 0), _rng.randf_range(0.27, 0.34), p, cols)
	if bool(cols.get("bull", false)):
		horns(head, Vector3(0.0, 0.2, 0), 0.5, Color("f4efe0"), 60.0)
		torus(head, 0.07, 0.015, Vector3(0.42, -0.12, 0), Color("ffcf3a"), Vector3(0, 90, 0), metal_mat(Color("ffcf3a")))
	if _rng.randf() < 0.3:
		for i in 3:
			cyl(head, 0.05, 0.0, 0.16 + (0.06 if i == 1 else 0.0), Vector3(-0.05, 0.36, (i - 1) * 0.12), BRASS, Vector3.ZERO, 8, metal_mat(BRASS))


func _plan_bird(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.62 + _p(p, "bob") * 1.4, 0), Vector3(0, 0, -_p(p, "pitch") * 1.2 + 8))
	ball(body, 0.42, Vector3.ZERO, cols["body"], Vector3(1.1, 0.95, 0.95))
	ball(body, 0.3, Vector3(0.12, -0.08, 0), cols["second"], Vector3(1.0, 1.0, 1.05))
	for side: float in [-1.0, 1.0]:
		var wing := joint(body, Vector3(-0.05, 0.12, side * 0.35), Vector3(side * (10.0 + _p(p, "arm") * 1.2), 0, -10.0 + _p(p, "arm") * 0.3))
		for f in 4:
			box(wing, Vector3(0.62 - f * 0.08, 0.06, 0.16), Vector3(-0.25 - f * 0.03, 0.05 - f * 0.05, side * (0.08 + f * 0.1)), cols["body"].darkened(0.08 * f) if f % 2 == 0 else cols["accent"], Vector3(0, side * (10 + f * 12), -10 - f * 6), null, 0.03)
	for i in 3:
		box(body, Vector3(0.5, 0.05, 0.14), Vector3(-0.55, 0.05 + i * 0.03, (i - 1) * 0.1), cols["accent"] if i == 1 else cols["body"], Vector3((i - 1) * 18, 0, 25 + _p(p, "tail") * 0.6), null, 0.03)
	for side: float in [-1.0, 1.0]:
		var hip := joint(body, Vector3(0.05, -0.32, side * 0.14), Vector3(0, 0, _p(p, "stride") * side * 0.6))
		stick(hip, Vector3.ZERO, Vector3(0, -0.28, 0), 0.03, Color("e9a91c"))
		for t in 3:
			stick(hip, Vector3(0, -0.28, 0), Vector3(0.1 - t * 0.05, -0.31, (t - 1) * 0.06), 0.02, Color("e9a91c"))
	var head := joint(body, Vector3(0.38, 0.3, 0), Vector3(0, 0, -_p(p, "head")))
	ball(head, 0.27, Vector3.ZERO, cols["body"])
	cyl(head, 0.1, 0.0, 0.26, Vector3(0.32, -0.05, 0), Color("ffb347"), Vector3(0, 0, -90 + _p(p, "jaw") * 10.0), 12)
	for side: float in [-1.0, 1.0]:
		side_eye(head, Vector3(0.12, 0.08, side * 0.19), 0.1, _p(p, "squint"))
	if _rng.randf() < 0.7:
		for i in 3:
			box(head, Vector3(0.28, 0.05, 0.08), Vector3(-0.12 - i * 0.05, 0.25 + i * 0.03, 0), cols["accent"], Vector3(0, 0, 50 + i * 15), null, 0.02)
	_element_bits(head, Vector3(-0.05, 0.25, 0), 0.4, cols)


func _plan_serpent(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var root := joint(c, Vector3(_p(p, "lean"), 0.0 + _p(p, "bob"), 0), Vector3.ZERO)
	var n := 8
	var phase := _p(p, "stride") * 0.04 + _p(p, "spin")
	var prev := Vector3(-0.95, 0.15, 0)
	var r0 := _rng.randf_range(0.14, 0.2)
	for i in n:
		var t := float(i) / (n - 1)
		var pt := Vector3(-0.95 + t * 1.3, 0.15 + t * t * 0.55 + sin(t * 6.0 + phase * 4.0) * 0.05, sin(t * 5.0 + phase * 3.0) * 0.18)
		var r := lerpf(r0 * 0.5, r0, minf(t * 2.0, 1.0))
		stick(root, prev, pt, r, cols["body"] if i % 2 == 0 else cols["body"].darkened(0.06))
		ball(root, r, pt, cols["body"])
		if i % 2 == 1:
			ball(root, r * 0.7, pt + Vector3(0, -r * 0.45, 0), cols["second"], Vector3(1.0, 0.5, 1.0))
		prev = pt
	if _rng.randf() < 0.55:
		for side: float in [-1.0, 1.0]:
			var wing := joint(root, Vector3(0.0, 0.45, side * 0.15), Vector3(side * 10, 0, 25 + _p(p, "arm")))
			for f in 4:
				var a := deg_to_rad(95.0 + f * 20.0)
				var d := Vector3(cos(a), sin(a), 0)
				box(wing, Vector3(0.5 - f * 0.07, 0.12, 0.03), d * (0.25 - f * 0.03), cols["accent"] if f % 2 else cols["second"], Vector3(0, 0, rad_to_deg(a)), null, 0.02)
	var head := _head(root, prev + Vector3(0.12, 0.08, 0), r0 * 1.7, p, cols)
	head.rotation_degrees.z += -_p(p, "pitch") * 0.5


func _plan_bug(c: Node3D, p: Dictionary, cols: Dictionary, swarm: bool, crown: bool) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.45 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch")))
	var shell_col: Color = cols["body"]
	ball(body, 0.34, Vector3(-0.35, 0.05, 0), shell_col, Vector3(1.3, 0.85, 1.0))
	ball(body, 0.24, Vector3(0.05, 0.05, 0), cols["second"])
	if swarm:
		for i in 3:
			torus(body, 0.3 - i * 0.02, 0.025, Vector3(-0.5 + i * 0.15, 0.05, 0), Color("ffcf3a"), Vector3(0, 0, 90), gloss(Color("ffcf3a"), 0.4))
	else:
		_back(body, 0.35, 0.3, cols)
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var swing: float = _p(p, "stride") * (1.0 if i % 2 == 0 else -1.0) * side
			var hip := joint(body, Vector3(-0.15 + i * 0.15, -0.05, side * 0.2), Vector3(side * 10, 0, swing))
			var knee := Vector3(0.05, 0.05, side * 0.25)
			stick(hip, Vector3.ZERO, knee, 0.03, Color("2b2f3a"))
			stick(hip, knee, Vector3(0.08 - i * 0.04, -0.4, side * 0.3), 0.025, Color("2b2f3a"))
	if _rng.randf() < 0.75:
		# Wings: two panes each side, raised up so they show above the body.
		var wing_col: Color = cols["accent"].lerp(cols["glow"], 0.3)
		for side: float in [-1.0, 1.0]:
			var wing := joint(body, Vector3(-0.15, 0.25, side * 0.12), Vector3(side * (35.0 + _p(p, "arm") * 0.8), 0, 35 + _p(p, "arm")))
			box(wing, Vector3(0.75, 0.03, 0.34), Vector3(-0.3, 0.05, side * 0.16), wing_col, Vector3(0, 0, 10), gloss(wing_col, 0.35, 0.8, 0.1), 0.0)
			box(wing, Vector3(0.5, 0.03, 0.26), Vector3(-0.42, -0.02, side * 0.36), wing_col.darkened(0.15), Vector3(0, side * 25, -5), gloss(wing_col.darkened(0.15), 0.3, 0.8, 0.1), 0.0)
	var head := _head(body, Vector3(0.38, 0.12, 0), 0.24, p, cols)
	for side: float in [-1.0, 1.0]:
		stick(head, Vector3(0.2, -0.15, side * 0.1), Vector3(0.42, -0.2 - _p(p, "jaw") * 0.06, side * (0.04 + _p(p, "jaw") * 0.08)), 0.025, cols["accent"])
	if crown:
		for i in 5:
			cyl(head, 0.04, 0.0, 0.2 + (0.08 if i == 2 else 0.0), Vector3(-0.05, 0.3, (i - 2) * 0.07), Color("ffcf3a"), Vector3.ZERO, 8, gloss(Color("ffcf3a"), 0.8))


func _plan_blob(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var squash := 1.0 - _p(p, "bob") * 1.6 - _p(p, "pitch") * 0.004
	var body := joint(c, Vector3(_p(p, "lean"), 0.0, 0), Vector3(0, 0, -_p(p, "pitch") * 0.3))
	var dome := ball(body, 0.6, Vector3(0, 0.5 * squash, 0), cols["body"], Vector3(1.05 / squash * 0.95, squash, 1.0))
	dome.material_override = gloss(cols["body"], 0.0, 0.92, 0.2) if _rng.randf() < 0.5 else dome.material_override
	for i in 4:
		var a := TAU * i / 4.0 + 0.3
		ball(body, 0.1, Vector3(cos(a) * 0.5, 0.05, sin(a) * 0.5), cols["body"].darkened(0.1), Vector3(1, 0.6, 1))
	var face := joint(body, Vector3(0.38, 0.55 * squash, 0.0), Vector3(0, 0, -_p(p, "head") * 0.5))
	for side: float in [-1.0, 1.0]:
		side_eye(face, Vector3(0.12, 0.08, side * 0.2), 0.13, _p(p, "squint"))
	ball(face, 0.06 + _p(p, "jaw") * 0.06, Vector3(0.2, -0.15, 0), Color("4a1020"), Vector3(0.6, 0.7 + _p(p, "jaw"), 1.4))
	_element_bits(body, Vector3(0, 1.0 * squash, 0), 0.6, cols)
	if _rng.randf() < 0.4:
		cyl(body, 0.32, 0.25, 0.25, Vector3(0, 1.05 * squash + 0.1, 0), cols["accent"], Vector3(0, 0, 8), 24)


func _plan_fish(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.6 + _p(p, "bob") * 1.5, 0), Vector3(0, 0, -_p(p, "pitch")))
	ball(body, 0.42, Vector3.ZERO, cols["body"], Vector3(1.45, 0.85, 0.8))
	ball(body, 0.3, Vector3(0.1, -0.12, 0), cols["second"], Vector3(1.5, 0.6, 0.8))
	var tail := joint(body, Vector3(-0.58, 0.0, 0), Vector3(0, 0, _p(p, "tail") * 0.6 + sin(_p(p, "spin") * TAU) * 10.0))
	for s2: float in [-1.0, 1.0]:
		box(tail, Vector3(0.36, 0.14, 0.04), Vector3(-0.15, s2 * 0.12, 0), cols["accent"], Vector3(0, 0, s2 * 35), null, 0.03)
	box(body, Vector3(0.36, 0.2, 0.04), Vector3(-0.05, 0.38, 0), cols["accent"], Vector3(0, 0, -25), null, 0.03)
	for side: float in [-1.0, 1.0]:
		var fin := joint(body, Vector3(0.1, -0.15, side * 0.3), Vector3(side * (25 + _p(p, "arm")), 0, -20))
		box(fin, Vector3(0.3, 0.04, 0.16), Vector3(-0.08, 0, side * 0.06), cols["accent"], Vector3.ZERO, null, 0.02)
	var head := joint(body, Vector3(0.45, 0.05, 0), Vector3(0, 0, -_p(p, "head")))
	for side: float in [-1.0, 1.0]:
		side_eye(head, Vector3(0.08, 0.1, side * 0.24), 0.12, _p(p, "squint"))
	ball(head, 0.07 + _p(p, "jaw") * 0.05, Vector3(0.2, -0.1, 0), Color("4a1020"), Vector3(0.6, 0.8 + _p(p, "jaw"), 1.3))
	if _rng.randf() < 0.4:
		cyl(head, 0.06, 0.0, 0.7, Vector3(0.45, 0.1, 0), cols["second"], Vector3(0, 0, -80), 12)
	_element_bits(body, Vector3(0.05, 0.4, 0), 0.4, cols)


func _plan_floater(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.75 + _p(p, "bob") * 2.0, 0), Vector3(0, 0, -_p(p, "pitch")))
	ball(body, 0.36, Vector3.ZERO, cols["body"], Vector3(0.95, 1.05, 0.95)).material_override = gloss(cols["body"], 0.25, 0.9, 0.25)
	cyl(body, 0.3, 0.0, 0.55, Vector3(-0.05, -0.42, 0), cols["body"], Vector3(0, 0, -15 + _p(p, "tail") * 0.5), 20, gloss(cols["body"], 0.2, 0.75, 0.3))
	glow(body, 0.1, Vector3(0.05, -0.05, 0), cols["glow"], 3.0)
	for side: float in [-1.0, 1.0]:
		var arm := joint(body, Vector3(0, -0.02, side * 0.3), Vector3(side * 15, 0, 40 + _p(p, "arm") * 1.5))
		stick(arm, Vector3.ZERO, Vector3(0, -0.3, side * 0.06), 0.04, cols["second"])
		ball(arm, 0.06, Vector3(0, -0.32, side * 0.06), cols["glow"])
	for i in 3:
		var a := TAU * (i / 3.0 + _p(p, "spin") * 0.25)
		ball(c, 0.06, Vector3(cos(a) * 0.55, 0.75 + sin(a * 2.0) * 0.12 + _p(p, "bob"), sin(a) * 0.55), cols["accent"])
	var face := joint(body, Vector3(0.24, 0.1, 0), Vector3(0, 0, -_p(p, "head")))
	for side: float in [-1.0, 1.0]:
		side_eye(face, Vector3(0.05, 0.05, side * 0.14), 0.11, _p(p, "squint"))
	_element_bits(body, Vector3(-0.05, 0.3, 0), 0.45, cols)


func _plan_boat(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.25 + _p(p, "bob"), 0), Vector3(_p(p, "stride") * 0.2, 0, -_p(p, "pitch") * 0.5))
	var orange := Color("ff7a2a")
	box(body, Vector3(1.4, 0.4, 0.7), Vector3(0, 0.1, 0), orange, Vector3.ZERO, null, 0.15)
	cyl(body, 0.36, 0.0, 0.5, Vector3(0.82, 0.1, 0), orange, Vector3(0, 0, -90), 4)
	box(body, Vector3(0.6, 0.38, 0.5), Vector3(-0.15, 0.5, 0), orange, Vector3.ZERO, null, 0.06)
	box(body, Vector3(0.4, 0.2, 0.44), Vector3(-0.2, 0.78, 0), orange.lightened(0.1), Vector3.ZERO, null, 0.05)
	cyl(body, 0.09, 0.09, 0.35, Vector3(-0.32, 1.0, 0), orange, Vector3.ZERO, 16)
	for side: float in [-1.0, 1.0]:
		side_eye(body, Vector3(0.12, 0.52, side * 0.24), 0.12, _p(p, "squint"))
	torus(body, 0.08, 0.025, Vector3(0.0, 0.5, 0.26), Color("2b2f3a"), Vector3(90, 0, 0))
	box(body, Vector3(0.14, 0.03, 0.1), Vector3(0.18, 0.4 - _p(p, "jaw") * 0.03, 0.26), Color("4a1020"), Vector3.ZERO, null, 0.0)


func _plan_part(c: Node3D, p: Dictionary, cols: Dictionary, part: String) -> void:
	# The Forbidden Printer's parts: dark machine pieces with a violet glow and a face.
	var dark := Color("2b2633")
	var violet := Color("9c63f2")
	var body := joint(c, Vector3(_p(p, "lean"), 0.5 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch") * 0.6))
	match part:
		"fp_left_rail", "fp_right_rail":
			box(body, Vector3(1.5, 0.22, 0.28), Vector3(0, 0.1, 0), Color("b9c2cc"), Vector3.ZERO, metal_mat(Color("b9c2cc")), 0.04)
			box(body, Vector3(0.45, 0.3, 0.4), Vector3(0.1 + _p(p, "stride") * 0.01, 0.32, 0), dark, Vector3.ZERO, null, 0.05)
			for x in [-0.6, 0.6]:
				cyl(body, 0.15, 0.15, 0.36, Vector3(x, -0.08, 0), dark, Vector3(90, 0, 0), 24)
		"fp_hot_end":
			box(body, Vector3(0.6, 0.5, 0.5), Vector3(0, 0.25, 0), Color("c22a2a"), Vector3.ZERO, null, 0.06)
			cyl(body, 0.22, 0.04, 0.5, Vector3(0, -0.2, 0), BRASS, Vector3.ZERO, 24, metal_mat(BRASS))
			glow(body, 0.08, Vector3(0, -0.47, 0), Color("ff8a2a"), 4.0)
			for i in 5:
				box(body, Vector3(0.66, 0.04, 0.56), Vector3(0, 0.6 + i * 0.08, 0), Color("b9c2cc"), Vector3.ZERO, metal_mat(Color("b9c2cc")), 0.01)
		"fp_frame":
			for x in [-0.55, 0.55]:
				box(body, Vector3(0.12, 1.3, 0.12), Vector3(x, 0.4, 0), dark, Vector3.ZERO, null, 0.02)
			box(body, Vector3(1.22, 0.12, 0.12), Vector3(0, 1.05, 0), dark, Vector3.ZERO, null, 0.02)
			box(body, Vector3(1.22, 0.12, 0.6), Vector3(0, -0.25, 0), dark, Vector3.ZERO, null, 0.02)
		_:
			box(body, Vector3(1.1, 0.08, 0.8), Vector3(0, 0.0, 0), Color("1f6b3a"), Vector3.ZERO, null, 0.02)
			for i in 6:
				box(body, Vector3(0.18, 0.08, 0.18), Vector3(-0.4 + (i % 3) * 0.35, 0.08, -0.2 + (i / 3) * 0.4), dark, Vector3.ZERO, null, 0.01)
			glow(body, 0.06, Vector3(0.45, 0.1, 0.3), Color("4ccb5f"), 3.0)
	for side: float in [-1.0, 1.0]:
		side_eye(body, Vector3(0.3, 0.45, side * 0.18), 0.11, _p(p, "squint"), violet)
	glow(body, 0.12, Vector3(0, 0.4, 0), violet, 3.0)
	torus(body, 0.5, 0.02, Vector3(0, 0.4, 0), violet, Vector3(80, 0, 0), gloss(violet, 1.5))


# ======================================================================= tools

const TOOLS_BUILT := ["lightning_rod", "scatter_shot", "mute_button", "shapeshifter_resin", "glitch_patch", "double_extrusion",
	"paint_thinner", "rebalance", "bed_purge", "pest_control", "data_leak", "siphon_filament", "thermal_throttle",
	"scrap_recycler", "last_layer", "team_build", "sacrificial_layer", "tribute_kiln", "field_calibration", "lucky_spool",
	"toolbox", "reinforcement_ribs", "overcharge", "echo_print", "gravity_well", "mass_production", "data_overload",
	"resin_bath", "poison_dart", "weathering", "final_countdown", "print_duel"]


func _t_lightning_rod(r: Node3D) -> void:
	cyl(r, 0.35, 0.4, 0.15, Vector3(0, 0.08, 0), DARK)
	cyl(r, 0.05, 0.05, 1.3, Vector3(0, 0.8, 0), GREY, Vector3.ZERO, 16, metal_mat(GREY))
	for i in 6:
		torus(r, 0.13, 0.025, Vector3(0, 0.35 + i * 0.1, 0), COPPER, Vector3.ZERO, metal_mat(COPPER))
	glow(r, 0.12, Vector3(0, 1.5, 0), Color("fff27a"), 4.0)
	var a := Vector3(0, 1.5, 0)
	for i in 4:
		var b := a + Vector3(0.18 * (1 if i % 2 == 0 else -1), -0.15, 0.1)
		stick(r, a, b, 0.025, Color("fff27a")).material_override = gloss(Color("fff27a"), 3.0)
		a = b


func _t_scatter_shot(r: Node3D) -> void:
	cyl(r, 0.22, 0.18, 0.9, Vector3(0.1, 0.45, 0), DARK, Vector3(0, 0, -60), 24)
	for x in [-0.3, 0.3]:
		cyl(r, 0.2, 0.2, 0.08, Vector3(x * 0.6, 0.2, x), BRASS, Vector3(90, 0, 0), 24, metal_mat(BRASS))
	for i in 7:
		ball(r, 0.07, Vector3(0.8 + randf_range(-0.2, 0.3), 0.5 + randf_range(-0.2, 0.4), randf_range(-0.3, 0.3)), ORANGE)


func _t_mute_button(r: Node3D) -> void:
	box(r, Vector3(1.0, 0.25, 1.0), Vector3(0, 0.12, 0), DARK, Vector3.ZERO, null, 0.08)
	cyl(r, 0.38, 0.38, 0.22, Vector3(0, 0.36, 0), RED, Vector3.ZERO, 32, gloss(RED, 0.2, 1.0, 0.3))
	box(r, Vector3(0.18, 0.02, 0.22), Vector3(-0.08, 0.48, 0), WHITE, Vector3.ZERO, null, 0.0)
	stick(r, Vector3(0.05, 0.49, -0.15), Vector3(0.22, 0.49, 0.15), 0.025, WHITE)
	stick(r, Vector3(0.22, 0.49, -0.15), Vector3(0.05, 0.49, 0.15), 0.025, WHITE)


func _t_shapeshifter_resin(r: Node3D) -> void:
	cyl(r, 0.32, 0.32, 0.8, Vector3(0, 0.4, 0), Color("d05cff"), Vector3.ZERO, 32, gloss(Color("d05cff"), 0.4, 0.75, 0.1))
	cyl(r, 0.18, 0.18, 0.2, Vector3(0, 0.9, 0), DARK)
	for i in 5:
		ball(r, 0.07, Vector3(cos(i * 1.3) * 0.18, 0.2 + i * 0.13, sin(i * 1.3) * 0.18), Color("ffe08a"))


func _t_glitch_patch(r: Node3D) -> void:
	for x in 4:
		for z in 4:
			if (x + z) % 3 != 2:
				box(r, Vector3(0.22, 0.08 + ((x * 7 + z * 3) % 4) * 0.06, 0.22), Vector3(-0.35 + x * 0.24, 0.1, -0.35 + z * 0.24), [MINT, VIOLET, PINKISH, ICE][(x + z) % 4], Vector3.ZERO, null, 0.02)


func _t_double_extrusion(r: Node3D) -> void:
	box(r, Vector3(1.0, 0.4, 0.5), Vector3(0, 0.9, 0), DARK, Vector3.ZERO, null, 0.06)
	for x in [-0.25, 0.25]:
		cyl(r, 0.13, 0.04, 0.35, Vector3(x, 0.55, 0), BRASS, Vector3.ZERO, 24, metal_mat(BRASS))
		glow(r, 0.05, Vector3(x, 0.36, 0), ORANGE, 3.0)
		cyl(r, 0.06, 0.06, 0.3, Vector3(x, 0.15, 0), [ORANGE, TEAL][int(x > 0)], Vector3.ZERO, 16)


func _t_paint_thinner(r: Node3D) -> void:
	cyl(r, 0.32, 0.32, 0.75, Vector3(0, 0.38, 0), GREY, Vector3.ZERO, 32, metal_mat(GREY))
	cyl(r, 0.33, 0.33, 0.35, Vector3(0, 0.38, 0), YELLOW)
	cyl(r, 0.08, 0.08, 0.12, Vector3(0.15, 0.8, 0), RED)
	for i in 3:
		ball(r, 0.05, Vector3(0.55 + i * 0.12, 0.05, 0.2 - i * 0.1), Color("e0e6ff"))


func _t_rebalance(r: Node3D) -> void:
	cyl(r, 0.3, 0.35, 0.1, Vector3(0, 0.05, 0), BRASS, Vector3.ZERO, 32, metal_mat(BRASS))
	cyl(r, 0.04, 0.04, 0.9, Vector3(0, 0.5, 0), BRASS, Vector3.ZERO, 16, metal_mat(BRASS))
	box(r, Vector3(1.3, 0.05, 0.06), Vector3(0, 0.95, 0), BRASS, Vector3(0, 0, -8), metal_mat(BRASS), 0.0)
	for x in [-0.6, 0.6]:
		cyl(r, 0.22, 0.25, 0.06, Vector3(x, 0.7 + (0.08 if x < 0 else -0.08), 0), BRASS, Vector3.ZERO, 32, metal_mat(BRASS))
	box(r, Vector3(0.18, 0.18, 0.18), Vector3(-0.6, 0.86, 0), RED, Vector3.ZERO, null, 0.03)
	ball(r, 0.1, Vector3(0.6, 0.7, 0), TEAL)


func _t_bed_purge(r: Node3D) -> void:
	box(r, Vector3(1.4, 0.06, 1.0), Vector3(0, 0.05, 0), Color("17202c"), Vector3.ZERO, null, 0.02)
	box(r, Vector3(0.6, 0.04, 0.4), Vector3(0.1, 0.25, 0), GREY, Vector3(0, 20, -15), metal_mat(GREY), 0.0)
	stick(r, Vector3(-0.15, 0.3, 0), Vector3(-0.7, 0.75, -0.2), 0.05, RED)
	for i in 6:
		box(r, Vector3(0.12, 0.03, 0.05), Vector3(0.5 + randf() * 0.3, 0.1, -0.3 + i * 0.12), [ORANGE, GREEN, BLUE][i % 3], Vector3(0, i * 40, 0), null, 0.0)


func _t_pest_control(r: Node3D) -> void:
	cyl(r, 0.25, 0.25, 0.7, Vector3(0, 0.35, 0), GREEN, Vector3.ZERO, 32)
	box(r, Vector3(0.18, 0.25, 0.14), Vector3(0, 0.82, 0), DARK, Vector3.ZERO, null, 0.03)
	cyl(r, 0.04, 0.04, 0.3, Vector3(0.18, 0.9, 0), DARK, Vector3(0, 0, -90), 12)
	for i in 6:
		ball(r, 0.04 + i * 0.01, Vector3(0.45 + i * 0.1, 0.9 + randf_range(-0.05, 0.05), randf_range(-0.1, 0.1)), Color("c8f7c0"))


func _t_data_leak(r: Node3D) -> void:
	box(r, Vector3(0.8, 0.06, 0.8), Vector3(0, 0.6, 0), BLUE, Vector3(-60, 0, 10), null, 0.03)
	box(r, Vector3(0.4, 0.07, 0.25), Vector3(0, 0.75, -0.12), GREY, Vector3(-60, 0, 10), metal_mat(GREY), 0.0)
	for i in 5:
		box(r, Vector3(0.08, 0.08, 0.08), Vector3(randf_range(-0.2, 0.2), 0.3 - i * 0.05, 0.3 + i * 0.05), [MINT, ICE, WHITE][i % 3], Vector3(0, i * 30, 0), gloss([MINT, ICE, WHITE][i % 3], 1.0), 0.0)


func _t_siphon_filament(r: Node3D) -> void:
	_spool_at(r, Vector3(-0.35, 0.35, 0), ORANGE)
	var a := Vector3(-0.1, 0.5, 0)
	chain(r, a, Vector3(1, 0.4, 0), 0.9, -120.0, 0.04, 0.04, Color("e0e6ff"), 8)
	cyl(r, 0.18, 0.2, 0.3, Vector3(0.55, 0.15, 0), GREY, Vector3.ZERO, 24, metal_mat(GREY))


func _spool_at(r: Node3D, at: Vector3, col: Color) -> void:
	for z in [-0.2, 0.2]:
		cyl(r, 0.35, 0.35, 0.04, at + Vector3(0, 0, z), DARK, Vector3(90, 0, 0), 32)
	cyl(r, 0.3, 0.3, 0.36, at, col, Vector3(90, 0, 0), 32, mat(col, 0.02, Vector3.BACK))


func _t_thermal_throttle(r: Node3D) -> void:
	cyl(r, 0.08, 0.08, 1.0, Vector3(0, 0.6, 0), WHITE, Vector3.ZERO, 16, gloss(WHITE, 0.0, 0.6, 0.05))
	ball(r, 0.16, Vector3(0, 0.12, 0), RED, Vector3.ONE).material_override = gloss(RED, 0.8)
	cyl(r, 0.05, 0.05, 0.4, Vector3(0, 0.35, 0), RED, Vector3.ZERO, 12, gloss(RED, 0.8))
	box(r, Vector3(0.5, 0.4, 0.06), Vector3(0.45, 0.5, 0), ICE, Vector3(0, -20, 0), null, 0.05)


func _t_scrap_recycler(r: Node3D) -> void:
	cyl(r, 0.4, 0.33, 0.7, Vector3(0, 0.35, 0), GREEN, Vector3.ZERO, 6)
	for i in 3:
		box(r, Vector3(0.3, 0.06, 0.1), Vector3(cos(i * 2.1) * 0.25, 0.85, sin(i * 2.1) * 0.25), WHITE, Vector3(0, -rad_to_deg(i * 2.1), 20), null, 0.02)
	for i in 4:
		box(r, Vector3(0.15, 0.1, 0.1), Vector3(randf_range(-0.2, 0.2), 0.75, randf_range(-0.2, 0.2)), [ORANGE, BLUE, YELLOW, RED][i], Vector3(i * 30, i * 20, 0), null, 0.02)


func _t_last_layer(r: Node3D) -> void:
	for i in 8:
		box(r, Vector3(0.9 - i * 0.05, 0.05, 0.9 - i * 0.05), Vector3(0, 0.03 + i * 0.06, 0), ORANGE.lerp(YELLOW, i / 8.0), Vector3.ZERO, null, 0.0)
	glow(r, 0.08, Vector3(0, 0.6, 0), Color("ffd36a"), 4.0)


func _t_team_build(r: Node3D) -> void:
	for i in 3:
		_bot(r, Vector3(-0.45 + i * 0.45, 0, 0.1 * (i % 2)), 0.42, -20.0 + i * 20.0, [ORANGE, TEAL, PURPLE][i])


func _t_sacrificial_layer(r: Node3D) -> void:
	box(r, Vector3(1.0, 0.35, 0.6), Vector3(0, 0.18, 0), SLATE, Vector3.ZERO, null, 0.04)
	for x in [-0.35, 0.35]:
		cyl(r, 0.06, 0.06, 0.3, Vector3(x, 0.5, 0), CREAM)
		glow(r, 0.05, Vector3(x, 0.7, 0), ORANGE, 3.0)
	_bot(r, Vector3(0, 0.35, 0), 0.32, 0.0, GREY)


func _t_tribute_kiln(r: Node3D) -> void:
	box(r, Vector3(0.9, 0.8, 0.8), Vector3(0, 0.4, 0), Color("7a3a2a"), Vector3.ZERO, null, 0.08)
	box(r, Vector3(0.4, 0.35, 0.02), Vector3(0.0, 0.35, 0.41), DARK, Vector3.ZERO, null, 0.03)
	glow(r, 0.14, Vector3(0, 0.33, 0.35), ORANGE, 4.0)
	cyl(r, 0.1, 0.1, 0.4, Vector3(0.25, 0.95, 0), SLATE)


func _t_field_calibration(r: Node3D) -> void:
	box(r, Vector3(0.5, 0.5, 0.5), Vector3(0, 0.25, 0), MINT, Vector3(0, 20, 0), null, 0.03)
	label(r, "XYZ", 22, Vector3(-0.15, 0.25, 0.26), DARK, Vector3(0, 20, 0))
	box(r, Vector3(1.2, 0.05, 0.12), Vector3(0.1, 0.06, 0.55), GREY, Vector3(0, -10, 0), metal_mat(GREY), 0.0)


func _t_lucky_spool(r: Node3D) -> void:
	_spool_at(r, Vector3(0, 0.38, 0), GREEN)
	for i in 4:
		var a := i * PI * 0.5
		ball(r, 0.1, Vector3(0.0, 0.38 + sin(a) * 0.1, 0.24 + cos(a) * 0.1), Color("8be04a"), Vector3(1, 1, 0.3))


func _t_toolbox(r: Node3D) -> void:
	box(r, Vector3(1.1, 0.5, 0.55), Vector3(0, 0.25, 0), RED, Vector3.ZERO, null, 0.05)
	box(r, Vector3(0.5, 0.06, 0.08), Vector3(0, 0.62, 0), DARK, Vector3.ZERO, null, 0.02)
	for x in [-0.2, 0.2]:
		stick(r, Vector3(x, 0.5, 0), Vector3(x, 0.62, 0), 0.03, DARK)
	box(r, Vector3(0.12, 0.08, 0.02), Vector3(0, 0.38, 0.28), GREY, Vector3.ZERO, metal_mat(GREY), 0.0)


func _t_reinforcement_ribs(r: Node3D) -> void:
	for i in 4:
		torus(r, 0.38 - i * 0.04, 0.04, Vector3(-0.3 + i * 0.2, 0.4, 0), STEEL, Vector3(0, 0, 90), metal_mat(STEEL))
	box(r, Vector3(0.9, 0.06, 0.06), Vector3(0, 0.05, 0), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.0)


func _t_overcharge(r: Node3D) -> void:
	cyl(r, 0.25, 0.25, 0.8, Vector3(0, 0.4, 0), DARK, Vector3.ZERO, 32)
	cyl(r, 0.26, 0.26, 0.25, Vector3(0, 0.6, 0), YELLOW)
	cyl(r, 0.08, 0.08, 0.1, Vector3(0, 0.85, 0), GREY, Vector3.ZERO, 16, metal_mat(GREY))
	for i in 3:
		var a := Vector3(0.3, 0.9 - i * 0.2, 0)
		stick(r, a, a + Vector3(0.25, 0.1, 0.1), 0.025, YELLOW).material_override = gloss(YELLOW, 3.0)


func _t_echo_print(r: Node3D) -> void:
	box(r, Vector3(0.45, 0.45, 0.45), Vector3(-0.25, 0.23, 0), ORANGE, Vector3(0, 15, 0), null, 0.05)
	box(r, Vector3(0.45, 0.45, 0.45), Vector3(0.3, 0.23, -0.1), ORANGE, Vector3(0, 15, 0), gloss(ORANGE, 0.6, 0.45, 0.2), 0.05)


func _t_gravity_well(r: Node3D) -> void:
	ball(r, 0.35, Vector3(0, 0.5, 0), Color("1a1030"))
	for i in 3:
		torus(r, 0.55 + i * 0.12, 0.02, Vector3(0, 0.5, 0), VIOLET, Vector3(75 - i * 10, i * 20, 0), gloss(VIOLET, 1.5))


func _t_mass_production(r: Node3D) -> void:
	for x in 3:
		for z in 2:
			_bot(r, Vector3(-0.5 + x * 0.5, 0, -0.25 + z * 0.5), 0.3, -10.0, [ORANGE, TEAL, PURPLE, YELLOW, GREEN, BLUE][x + z * 3])


func _t_data_overload(r: Node3D) -> void:
	box(r, Vector3(1.0, 0.65, 0.08), Vector3(0, 0.55, 0), DARK, Vector3.ZERO, null, 0.04)
	box(r, Vector3(0.88, 0.52, 0.02), Vector3(0, 0.55, 0.05), Color("ff4a4a"), Vector3.ZERO, gloss(Color("ff4a4a"), 1.2), 0.0)
	label(r, "!", 40, Vector3(-0.05, 0.4, 0.07), WHITE)
	cyl(r, 0.06, 0.06, 0.2, Vector3(0, 0.12, 0), DARK)


func _t_resin_bath(r: Node3D) -> void:
	cyl(r, 0.5, 0.45, 0.35, Vector3(0, 0.18, 0), WHITE, Vector3.ZERO, 32)
	cyl(r, 0.46, 0.46, 0.04, Vector3(0, 0.34, 0), MINT, Vector3.ZERO, 32, gloss(MINT, 0.4, 0.8, 0.05))
	for i in 4:
		ball(r, 0.05, Vector3(randf_range(-0.3, 0.3), 0.45 + i * 0.08, randf_range(-0.2, 0.2)), Color("d8fff2"))


func _t_poison_dart(r: Node3D) -> void:
	stick(r, Vector3(-0.6, 0.35, 0), Vector3(0.4, 0.55, 0), 0.04, DARK)
	cyl(r, 0.04, 0.0, 0.25, Vector3(0.52, 0.58, 0), GREY, Vector3(0, 0, -78), 12, metal_mat(GREY))
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.22, 0.02, 0.12), Vector3(-0.55, 0.36, s * 0.06), GREEN, Vector3(s * 30, 0, 10), null, 0.0)
	ball(r, 0.06, Vector3(0.7, 0.55, 0), Color("8be04a")).material_override = gloss(Color("8be04a"), 1.0)


func _t_weathering(r: Node3D) -> void:
	for i in 4:
		ball(r, 0.22 + (i % 2) * 0.06, Vector3(-0.35 + i * 0.22, 1.0 + (i % 2) * 0.08, 0), Color("c9d2e0"))
	for i in 8:
		stick(r, Vector3(-0.4 + i * 0.11, 0.8, 0), Vector3(-0.45 + i * 0.11, 0.55, 0), 0.015, BLUE)


func _t_final_countdown(r: Node3D) -> void:
	ball(r, 0.42, Vector3(0, 0.45, 0), DARK)
	cyl(r, 0.1, 0.1, 0.15, Vector3(0.1, 0.9, 0), GREY, Vector3(0, 0, -20), 16, metal_mat(GREY))
	glow(r, 0.06, Vector3(0.2, 1.0, 0), ORANGE, 4.0)
	box(r, Vector3(0.4, 0.2, 0.02), Vector3(0, 0.45, 0.42), Color("101010"), Vector3.ZERO, null, 0.0)
	label(r, "0:03", 16, Vector3(-0.14, 0.4, 0.44), Color("ff4a4a"))


func _t_print_duel(r: Node3D) -> void:
	for s in [-1.0, 1.0]:
		stick(r, Vector3(-0.5 * s, 0.1, 0), Vector3(0.45 * s, 1.0, 0), 0.04, STEEL).material_override = metal_mat(STEEL)
		box(r, Vector3(0.3, 0.05, 0.08), Vector3(-0.32 * s, 0.28, 0), BRASS, Vector3(0, 0, -45 * s), metal_mat(BRASS), 0.0)


# =================================================================== equipment

const GEAR_BUILT := ["spiked_bumper", "lucky_keychain", "rocket_boots", "leech_nozzle", "thermal_camera", "toxic_tip",
	"mirror_plating", "growth_serum", "scrap_magnet", "signal_booster", "ward_rune", "berserker_chip", "snap_jaws",
	"quickdraw_holster", "overflow_valve", "reprint_backup", "menace_mask", "turret_mount", "healing_halo", "battery_pack",
	"rally_banner", "golden_spool_crown", "dragon_scale_mail", "thruster_pack", "cursed_gear", "silence_emitter", "tribe_totem"]


func _g_spiked_bumper(r: Node3D) -> void:
	box(r, Vector3(1.2, 0.3, 0.3), Vector3(0, 0.5, 0), SLATE, Vector3.ZERO, null, 0.08)
	for i in 5:
		cyl(r, 0.07, 0.0, 0.25, Vector3(-0.5 + i * 0.25, 0.5, 0.25), STEEL, Vector3(90, 0, 0), 12, metal_mat(STEEL))


func _g_lucky_keychain(r: Node3D) -> void:
	torus(r, 0.18, 0.03, Vector3(0, 0.95, 0), STEEL, Vector3(90, 0, 0), metal_mat(STEEL))
	stick(r, Vector3(0, 0.78, 0), Vector3(0, 0.55, 0), 0.02, STEEL)
	for i in 4:
		var a := i * PI * 0.5
		ball(r, 0.16, Vector3(sin(a) * 0.17, 0.38 + cos(a) * 0.17, 0), GREEN, Vector3(1, 1, 0.3))


func _g_rocket_boots(r: Node3D) -> void:
	for x in [-0.28, 0.28]:
		box(r, Vector3(0.32, 0.5, 0.36), Vector3(x, 0.5, 0), RED, Vector3.ZERO, null, 0.08)
		box(r, Vector3(0.36, 0.15, 0.58), Vector3(x, 0.22, 0.1), RED.darkened(0.2), Vector3.ZERO, null, 0.06)
		cyl(r, 0.1, 0.13, 0.15, Vector3(x, 0.08, -0.05), GREY, Vector3.ZERO, 16, metal_mat(GREY))
		glow(r, 0.09, Vector3(x, -0.02, -0.05), ORANGE, 4.0)


func _g_leech_nozzle(r: Node3D) -> void:
	cyl(r, 0.25, 0.06, 0.7, Vector3(0, 0.5, 0), Color("b33a5a"), Vector3(0, 0, 20), 24)
	for i in 4:
		cyl(r, 0.03, 0.0, 0.12, Vector3(0.12 + i * 0.03, 0.18 + i * 0.04, 0.06), WHITE, Vector3(0, 0, -60), 8)


func _g_thermal_camera(r: Node3D) -> void:
	box(r, Vector3(0.7, 0.5, 0.45), Vector3(0, 0.55, 0), DARK, Vector3.ZERO, null, 0.06)
	cyl(r, 0.18, 0.2, 0.25, Vector3(0.0, 0.55, 0.32), DARK, Vector3(90, 0, 0), 24)
	cyl(r, 0.14, 0.14, 0.02, Vector3(0.0, 0.55, 0.45), ORANGE, Vector3(90, 0, 0), 24, gloss(ORANGE, 1.4))


func _g_toxic_tip(r: Node3D) -> void:
	cyl(r, 0.12, 0.0, 0.7, Vector3(0, 0.6, 0), GREEN, Vector3(0, 0, 0), 16)
	cyl(r, 0.18, 0.18, 0.3, Vector3(0, 0.15, 0), DARK)
	ball(r, 0.06, Vector3(0, 0.98, 0), Color("8be04a")).material_override = gloss(Color("8be04a"), 2.0)


func _g_mirror_plating(r: Node3D) -> void:
	box(r, Vector3(0.9, 1.0, 0.08), Vector3(0, 0.55, 0), Color("e0f4ff"), Vector3(0, 0, 0), gloss(Color("e0f4ff"), 0.0, 1.0, 0.02), 0.08)
	box(r, Vector3(0.95, 1.05, 0.04), Vector3(0, 0.55, -0.05), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.06)


func _g_growth_serum(r: Node3D) -> void:
	cyl(r, 0.25, 0.25, 0.75, Vector3(0, 0.5, 0), Color("8be04a"), Vector3.ZERO, 32, gloss(Color("8be04a"), 0.8, 0.7, 0.05))
	for y in [0.1, 0.9]:
		cyl(r, 0.28, 0.28, 0.08, Vector3(0, y, 0), STEEL, Vector3.ZERO, 32, metal_mat(STEEL))
	ball(r, 0.08, Vector3(0, 0.5, 0), WHITE)


func _g_scrap_magnet(r: Node3D) -> void:
	torus(r, 0.35, 0.12, Vector3(0, 0.6, 0), RED, Vector3(90, 0, 0))
	box(r, Vector3(0.6, 0.4, 0.3), Vector3(0, 0.3, 0), Color("10151c"), Vector3.ZERO, null, 0.0)
	for x in [-0.35, 0.35]:
		box(r, Vector3(0.24, 0.2, 0.26), Vector3(x, 0.2, 0), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.02)


func _g_signal_booster(r: Node3D) -> void:
	box(r, Vector3(0.5, 0.3, 0.4), Vector3(0, 0.2, 0), DARK, Vector3.ZERO, null, 0.05)
	stick(r, Vector3(0, 0.35, 0), Vector3(0, 1.0, 0), 0.03, STEEL)
	for i in 3:
		torus(r, 0.15 + i * 0.12, 0.015, Vector3(0, 1.0, 0), CYAN_C, Vector3(90, 0, 0), gloss(CYAN_C, 1.5))


func _g_ward_rune(r: Node3D) -> void:
	cyl(r, 0.45, 0.45, 0.08, Vector3(0, 0.55, 0), VIOLET, Vector3(80, 0, 0), 6, gloss(VIOLET, 0.6, 1.0, 0.2))
	torus(r, 0.3, 0.025, Vector3(0, 0.55, 0.06), Color("ffcf3a"), Vector3(80, 0, 0), gloss(Color("ffcf3a"), 1.5))


func _g_berserker_chip(r: Node3D) -> void:
	box(r, Vector3(0.6, 0.06, 0.6), Vector3(0, 0.5, 0), DARK, Vector3(60, 0, 0), null, 0.02)
	for i in 6:
		box(r, Vector3(0.06, 0.04, 0.1), Vector3(-0.25 + i * 0.1, 0.25, 0.1), BRASS, Vector3(60, 0, 0), metal_mat(BRASS), 0.0)
	glow(r, 0.08, Vector3(0, 0.55, 0.06), RED, 3.0)


func _g_snap_jaws(r: Node3D) -> void:
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.8, 0.12, 0.4), Vector3(0, 0.55 + s * 0.15, 0), STEEL, Vector3(0, 0, s * 12), metal_mat(STEEL), 0.04)
		for i in 5:
			cyl(r, 0.05, 0.0, 0.14, Vector3(-0.3 + i * 0.15, 0.55 + s * 0.06, 0), WHITE, Vector3(0, 0, 180 if s > 0 else 0), 6)


func _g_quickdraw_holster(r: Node3D) -> void:
	box(r, Vector3(0.35, 0.7, 0.2), Vector3(0, 0.5, 0), Color("8a5a32"), Vector3(0, 0, 10), null, 0.08)
	stick(r, Vector3(0.05, 0.85, 0), Vector3(0.2, 1.1, 0), 0.05, DARK)


func _g_overflow_valve(r: Node3D) -> void:
	cyl(r, 0.1, 0.1, 0.9, Vector3(0, 0.5, 0), COPPER, Vector3(0, 0, 90), 16, metal_mat(COPPER))
	cyl(r, 0.2, 0.2, 0.2, Vector3(0, 0.5, 0), COPPER, Vector3.ZERO, 16, metal_mat(COPPER))
	torus(r, 0.2, 0.04, Vector3(0, 0.75, 0), RED)
	for i in 3:
		ball(r, 0.06, Vector3(0.5 + i * 0.08, 0.45 - i * 0.12, 0), BLUE)


func _g_reprint_backup(r: Node3D) -> void:
	box(r, Vector3(0.5, 0.65, 0.08), Vector3(0, 0.5, 0), BLUE, Vector3.ZERO, null, 0.04)
	box(r, Vector3(0.3, 0.2, 0.02), Vector3(0, 0.7, 0.05), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.0)
	torus(r, 0.12, 0.03, Vector3(0, 0.38, 0.06), WHITE, Vector3(90, 0, 0))


func _g_menace_mask(r: Node3D) -> void:
	ball(r, 0.42, Vector3(0, 0.55, 0), Color("4a2a5a"), Vector3(1, 1.1, 0.5))
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.16, 0.06, 0.05), Vector3(s * 0.15, 0.65, 0.2), Color("ff4a4a"), Vector3(0, 0, s * -20), gloss(Color("ff4a4a"), 2.0), 0.0)
		cyl(r, 0.06, 0.0, 0.3, Vector3(s * 0.3, 0.95, 0), WHITE, Vector3(0, 0, s * -25), 8)


func _g_turret_mount(r: Node3D) -> void:
	cyl(r, 0.3, 0.35, 0.2, Vector3(0, 0.15, 0), SLATE)
	box(r, Vector3(0.45, 0.3, 0.35), Vector3(0, 0.45, 0), SLATE.lightened(0.1), Vector3.ZERO, null, 0.05)
	cyl(r, 0.06, 0.06, 0.6, Vector3(0.4, 0.5, 0), DARK, Vector3(0, 0, -90), 16)
	glow(r, 0.04, Vector3(0.72, 0.5, 0), ORANGE, 3.0)


func _g_healing_halo(r: Node3D) -> void:
	torus(r, 0.4, 0.05, Vector3(0, 0.7, 0), Color("ffe58a"), Vector3(70, 0, 0), gloss(Color("ffe58a"), 1.5))
	for i in 4:
		ball(r, 0.05, Vector3(cos(i * 1.57) * 0.4, 0.7, sin(i * 1.57) * 0.13), GREEN)


func _g_battery_pack(r: Node3D) -> void:
	box(r, Vector3(0.5, 0.75, 0.3), Vector3(0, 0.45, 0), DARK, Vector3.ZERO, null, 0.05)
	for i in 3:
		box(r, Vector3(0.36, 0.14, 0.02), Vector3(0, 0.25 + i * 0.2, 0.16), GREEN, Vector3.ZERO, gloss(GREEN, 1.0), 0.0)
	label(r, "+", 30, Vector3(-0.05, 0.85, 0.16), YELLOW)


func _g_rally_banner(r: Node3D) -> void:
	stick(r, Vector3(-0.3, 0.0, 0), Vector3(-0.3, 1.2, 0), 0.03, BRASS)
	box(r, Vector3(0.6, 0.45, 0.02), Vector3(0.02, 0.95, 0), RED, Vector3(0, 0, 0), null, 0.0)
	cyl(r, 0.06, 0.0, 0.2, Vector3(-0.3, 1.3, 0), BRASS, Vector3.ZERO, 8, metal_mat(BRASS))


func _g_golden_spool_crown(r: Node3D) -> void:
	cyl(r, 0.4, 0.4, 0.25, Vector3(0, 0.4, 0), Color("ffcf3a"), Vector3.ZERO, 40, metal_mat(Color("ffcf3a")))
	for i in 6:
		var a := TAU * i / 6.0
		cyl(r, 0.08, 0.0, 0.3, Vector3(cos(a) * 0.38, 0.65, sin(a) * 0.38), Color("ffcf3a"), Vector3.ZERO, 8, metal_mat(Color("ffcf3a")))
		ball(r, 0.05, Vector3(cos(a) * 0.38, 0.82, sin(a) * 0.38), [RED, BLUE, GREEN][i % 3])


func _g_dragon_scale_mail(r: Node3D) -> void:
	for row in 4:
		for col in 4:
			box(r, Vector3(0.22, 0.2, 0.05), Vector3(-0.33 + col * 0.22 + (row % 2) * 0.11, 0.25 + row * 0.18, 0), Color("c92a3a").lerp(Color("ffcf3a"), row / 6.0), Vector3(-10, 0, 45), metal_mat(Color("c92a3a").lerp(Color("ffcf3a"), row / 6.0)), 0.02)


func _g_thruster_pack(r: Node3D) -> void:
	for x in [-0.18, 0.18]:
		cyl(r, 0.15, 0.15, 0.6, Vector3(x, 0.55, 0), STEEL, Vector3.ZERO, 24, metal_mat(STEEL))
		cyl(r, 0.08, 0.12, 0.15, Vector3(x, 0.18, 0), DARK)
		glow(r, 0.08, Vector3(x, 0.05, 0), ORANGE, 4.0)
	box(r, Vector3(0.3, 0.4, 0.1), Vector3(0, 0.55, -0.15), RED, Vector3.ZERO, null, 0.04)


func _g_cursed_gear(r: Node3D) -> void:
	_gear(r, 10, 0.32, 0.42, Vector3(0, 0.55, 0), Color("4a2a5a"), 0.0)
	glow(r, 0.1, Vector3(0, 0.55, 0.1), Color("c46aff"), 3.0)


func _g_silence_emitter(r: Node3D) -> void:
	box(r, Vector3(0.4, 0.4, 0.4), Vector3(0, 0.3, 0), SLATE, Vector3.ZERO, null, 0.05)
	cyl(r, 0.12, 0.35, 0.4, Vector3(0, 0.7, 0), GREY, Vector3.ZERO, 24, metal_mat(GREY))
	torus(r, 0.38, 0.02, Vector3(0, 0.95, 0), WHITE, Vector3(90, 0, 0), gloss(WHITE, 1.0))


func _g_tribe_totem(r: Node3D) -> void:
	for i in 3:
		ball(r, 0.2 - i * 0.03, Vector3(0, 0.25 + i * 0.32, 0), [Color("56b84a"), Color("ffcf3a"), Color("56b84a")][i], Vector3(1.2, 0.9, 1.0))
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.4, 0.02, 0.15), Vector3(s * 0.25, 0.9, 0), Color("c8f2ff"), Vector3(0, 0, s * 20), gloss(Color("c8f2ff"), 0.3, 0.6), 0.0)


# =================================================================== mythical

## A double-sided skin stretched over points (a fan from the first point):
## dragon and bat wings, fins, frills.
func membrane(parent: Node3D, pts: Array, col: Color, alpha := 0.92) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, pts.size() - 1):
		for v in [pts[0], pts[i], pts[i + 1]]:
			st.add_vertex(v)
	st.generate_normals()
	var n := MeshInstance3D.new()
	n.mesh = st.commit()
	var m := StandardMaterial3D.new()
	var c2: Color = RAW_GREY if _raw else col
	m.albedo_color = Color(c2.r, c2.g, c2.b, alpha)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.5
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	n.material_override = m
	parent.add_child(n)


## Bat-style wings: finger bones from the shoulder with skin between them.
func bat_wings(body: Node3D, at: Vector3, span: float, p: Dictionary, bone: Color, skin: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var w := joint(body, at + Vector3(0, 0, side * 0.18), Vector3(side * (12.0 + _p(p, "arm") * 0.6), 0, 25.0 + _p(p, "arm") * 1.1))
		var tips: Array = []
		for f in 4:
			var a := deg_to_rad(80.0 + f * 28.0)
			var tip := Vector3(cos(a) * span * (1.0 - f * 0.12), sin(a) * span * (1.0 - f * 0.12), side * f * 0.05)
			stick(w, Vector3.ZERO, tip, 0.035, bone)
			ball(w, 0.045, tip, bone)
			tips.append(tip)
		var fan: Array = [Vector3.ZERO]
		fan.append_array(tips)
		fan.append(Vector3(-span * 0.35, -0.05, 0))
		membrane(w, fan, skin)


## Feathered wings: overlapping long feathers.
func feather_wings(body: Node3D, at: Vector3, span: float, p: Dictionary, a_col: Color, b_col: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var w := joint(body, at + Vector3(0, 0, side * 0.2), Vector3(side * (15.0 + _p(p, "arm") * 0.7), 0, 30.0 + _p(p, "arm") * 1.1))
		# Feathers lie flat in the wing's plane, fanning back from the shoulder.
		for f in 6:
			var a := deg_to_rad(100.0 + f * 15.0)
			var d := Vector3(cos(a), sin(a), 0)
			var length := span * (1.0 - f * 0.09)
			box(w, Vector3(length, 0.18, 0.04), d * length * 0.5 + Vector3(0, 0, side * f * 0.015), a_col if f % 2 == 0 else b_col, Vector3(0, 0, rad_to_deg(a)), null, 0.05)


func horns(head: Node3D, at: Vector3, length: float, col: Color, curl := -50.0) -> void:
	for side: float in [-1.0, 1.0]:
		chain(head, at + Vector3(0, 0, side * 0.12), Vector3(-0.7, 0.8, side * 0.35), length, curl, 0.06, 0.015, col, 5)


## A spiral horn, the unicorn's: rings stacked on a tapering cone.
func spiral_horn(head: Node3D, at: Vector3, length: float, col: Color) -> void:
	var tilt := Vector3(0, 0, -35)
	cyl(head, 0.07, 0.0, length, at + Vector3(length * 0.25, length * 0.4, 0), col, tilt, 24, gloss(col, 0.6, 1.0, 0.15))
	for i in 5:
		var t := float(i) / 5.0
		torus(head, 0.065 * (1.0 - t), 0.012, at + Vector3(length * 0.25 * (0.2 + t * 1.0) - length * 0.05, length * (0.08 + t * 0.62), 0), col.lightened(0.3), tilt, gloss(col.lightened(0.3), 0.8))


func spikes_along(parent: Node3D, pts: Array, col: Color, size: float) -> void:
	for pt in pts:
		cyl(parent, size * 0.4, 0.0, size, pt + Vector3(0, size * 0.4, 0), col, Vector3(0, 0, 18), 8)


## A dragon: four strong legs, a long spined neck, a horned head with a jaw
## that breathes, bat wings, a spiked tail with a spade.
func _plan_dragon(c: Node3D, p: Dictionary, cols: Dictionary, lk: Dictionary) -> void:
	var scales: Color = cols["body"]
	var belly: Color = cols["second"]
	var spike: Color = cols["accent"]
	var body := joint(c, Vector3(_p(p, "lean"), 0.62 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch")))
	ball(body, 0.45, Vector3.ZERO, scales, Vector3(1.4, 0.9, 0.95))
	for i in 4:
		ball(body, 0.17, Vector3(-0.3 + i * 0.2, -0.3, 0), belly, Vector3(1.0, 0.45, 1.6))
	spikes_along(body, [Vector3(-0.35, 0.36, 0), Vector3(-0.1, 0.4, 0), Vector3(0.15, 0.38, 0)], spike, 0.16)
	# Legs: thick thighs, claws.
	for side: float in [-1.0, 1.0]:
		for front: bool in [true, false]:
			var swing: float = _p(p, "stride") * (1.0 if front else -1.0) * side
			if front:
				swing += maxf(_p(p, "arm"), 0.0) * 0.5
			var hip := joint(body, Vector3(0.35 if front else -0.38, -0.12, side * 0.3), Vector3(0, 0, swing))
			ball(hip, 0.15, Vector3(0, -0.05, 0), scales.darkened(0.08), Vector3(1.0, 1.3, 1.0))
			stick(hip, Vector3(0, -0.1, 0), Vector3(0.05, -0.42, 0), 0.08, scales.darkened(0.12))
			for t in 3:
				cyl(hip, 0.035, 0.0, 0.12, Vector3(0.14, -0.48, (t - 1) * 0.06), Color("f4efe0"), Vector3(0, 0, -80), 8)
	# Tail with a spade.
	var tail := joint(body, Vector3(-0.58, 0.05, 0), Vector3(0, 0, 10.0 + _p(p, "tail")))
	var end := chain(tail, Vector3.ZERO, Vector3(-1, -0.1, 0), 1.0, 70.0, 0.14, 0.05, scales, 8)
	box(tail, Vector3(0.22, 0.2, 0.04), end + Vector3(-0.05, 0.04, 0), spike, Vector3(0, 0, 45), null, 0.02)
	# Wings.
	var span := 1.05 if not lk.get("small", false) else 0.6
	bat_wings(body, Vector3(0.05, 0.3, 0), span, p, scales.darkened(0.2), cols["accent"].lerp(scales, 0.4))
	# Neck and head.
	var neck_end := chain(body, Vector3(0.5, 0.18, 0), Vector3(0.6, 1.0, 0), 0.55, -40.0, 0.15, 0.11, scales, 5)
	var head := joint(body, neck_end + Vector3(0.05, 0.02, 0), Vector3(0, 0, -_p(p, "head") - 10.0))
	box(head, Vector3(0.42, 0.28, 0.32), Vector3(0.1, 0.0, 0), scales, Vector3.ZERO, null, 0.1)
	box(head, Vector3(0.32, 0.16, 0.24), Vector3(0.38, -0.04, 0), scales.lightened(0.05), Vector3.ZERO, null, 0.06)
	for side: float in [-1.0, 1.0]:
		ball(head, 0.025, Vector3(0.53, 0.02, side * 0.06), Color("2b2f3a"))
	var jaw := joint(head, Vector3(0.12, -0.12, 0), Vector3(0, 0, -_p(p, "jaw") * 30.0))
	box(jaw, Vector3(0.48, 0.07, 0.24), Vector3(0.22, -0.02, 0), belly, Vector3.ZERO, null, 0.03)
	for t in 3:
		cyl(jaw, 0.02, 0.0, 0.06, Vector3(0.3 + t * 0.08, 0.03, 0.09), WHITE, Vector3.ZERO, 6)
	if _p(p, "jaw") > 0.5:
		glow(head, 0.1, Vector3(0.6, -0.12, 0), cols["glow"], 4.0)
		for i in 4:
			ball(head, 0.06 + i * 0.02, Vector3(0.7 + i * 0.13, -0.15 - i * 0.03, 0), cols["glow"]).material_override = gloss(cols["glow"], 2.5, 0.8)
	for side: float in [-1.0, 1.0]:
		side_eye(head, Vector3(0.15, 0.1, side * 0.15), 0.09, _p(p, "squint"), Color("2a1a08"))
	horns(head, Vector3(-0.08, 0.12, 0), 0.45, Color("f4efe0"))
	spikes_along(head, [Vector3(-0.1, 0.12, 0), Vector3(-0.16, 0.05, 0)], spike, 0.1)


## Horses of legend: unicorn (spiral horn), pegasus (wings), alicorn (both).
func _plan_horse(c: Node3D, p: Dictionary, cols: Dictionary, lk: Dictionary) -> void:
	var coat: Color = cols["second"] if bool(lk.get("pale", true)) else cols["body"]
	var mane_cols: Array = [cols["body"], cols["accent"], cols["glow"]]
	if bool(lk.get("rainbow", false)):
		mane_cols = [Color("ff5a5a"), Color("ffb347"), Color("ffe14a"), Color("6ad86a"), Color("5ab0ff"), Color("b07aff")]
	var foal: bool = bool(lk.get("foal", false))
	var leg := 0.42 if not foal else 0.3
	var body := joint(c, Vector3(_p(p, "lean"), leg + 0.3 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch") * 0.8))
	ball(body, 0.36, Vector3.ZERO, coat, Vector3(1.55, 0.9, 0.85))
	for side: float in [-1.0, 1.0]:
		for front: bool in [true, false]:
			var swing: float = _p(p, "stride") * (1.0 if front else -1.0) * side
			if front:
				swing += maxf(_p(p, "arm"), 0.0) * 0.9
			var hip := joint(body, Vector3(0.36 if front else -0.38, -0.15, side * 0.16), Vector3(0, 0, swing))
			var knee := Vector3(0.03, -leg * 0.55, 0)
			stick(hip, Vector3.ZERO, knee, 0.055, coat)
			stick(hip, knee, Vector3(0, -leg, 0), 0.045, coat)
			cyl(hip, 0.06, 0.07, 0.08, Vector3(0, -leg - 0.02, 0), Color("ffcf3a") if bool(lk.get("horn", false)) else Color("5a4a3a"), Vector3.ZERO, 16)
	# Tail: flowing strands.
	var tail := joint(body, Vector3(-0.55, 0.12, 0), Vector3(0, 0, 20.0 + _p(p, "tail")))
	for i in mane_cols.size():
		chain(tail, Vector3(0, 0, (i - mane_cols.size() * 0.5) * 0.03), Vector3(-1, -0.6, 0), 0.55, 40.0 + i * 6.0, 0.05, 0.02, mane_cols[i], 6)
	if bool(lk.get("wings", false)):
		feather_wings(body, Vector3(0.0, 0.25, 0), 0.85 if not foal else 0.5, p, WHITE, cols["glow"])
	# Neck and head.
	var neck := joint(body, Vector3(0.42, 0.15, 0), Vector3(0, 0, 0))
	stick(neck, Vector3.ZERO, Vector3(0.18, 0.42, 0), 0.13, coat)
	var head := joint(neck, Vector3(0.22, 0.5, 0), Vector3(0, 0, -_p(p, "head") - 20.0))
	box(head, Vector3(0.3, 0.22, 0.22), Vector3(0.05, 0, 0), coat, Vector3.ZERO, null, 0.08)
	box(head, Vector3(0.22, 0.16, 0.18), Vector3(0.25, -0.06, 0), coat.darkened(0.04), Vector3(0, 0, -10), null, 0.06)
	var jaw := joint(head, Vector3(0.2, -0.12, 0), Vector3(0, 0, -_p(p, "jaw") * 20.0))
	box(jaw, Vector3(0.18, 0.04, 0.14), Vector3(0.08, 0, 0), coat.darkened(0.1), Vector3.ZERO, null, 0.02)
	for side: float in [-1.0, 1.0]:
		side_eye(head, Vector3(0.08, 0.05, side * 0.12), 0.07, _p(p, "squint"), Color("3a2a5a"))
		cyl(head, 0.04, 0.0, 0.12, Vector3(-0.06, 0.15, side * 0.07), coat, Vector3(side * 10, 0, 10), 8)
	# Mane: strands down the neck.
	for i in 6:
		var at := Vector3(-0.02 + i * 0.03, 0.08 + i * 0.07, 0)
		chain(neck, at, Vector3(-1, 0.2, 0), 0.25, 30.0, 0.045, 0.02, mane_cols[i % mane_cols.size()], 3)
	if bool(lk.get("horn", false)):
		spiral_horn(head, Vector3(0.12, 0.1, 0), 0.32 if not foal else 0.18, Color("ffe58a"))


## Mixed beasts from legend, on a lion-like body: griffin (eagle head and
## wings), kitsune (fox with many tails), cerberus (three heads), manticore
## (bat wings and a scorpion tail), chimera (goat horns, snake tail), sphinx.
func _plan_beast(c: Node3D, p: Dictionary, cols: Dictionary, lk: Dictionary) -> void:
	var kind := str(lk.get("beast", "griffin"))
	var fur: Color = cols["body"]
	var body := joint(c, Vector3(_p(p, "lean"), 0.58 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch")))
	ball(body, 0.38, Vector3.ZERO, fur, Vector3(1.4, 0.88, 0.92))
	_legs4(body, p, cols, 0.36, 0.22, -0.18, 0.38, 0.075)
	var heads: Array = [0.0]
	if kind == "cerberus":
		heads = [-0.22, 0.0, 0.22]
	match kind:
		"griffin":
			feather_wings(body, Vector3(0.05, 0.25, 0), 0.9, p, cols["second"], cols["accent"])
			chain(body, Vector3(-0.5, 0.05, 0), Vector3(-1, 0.2, 0), 0.5, 50.0, 0.04, 0.02, fur, 5)
			ball(body, 0.08, Vector3(-0.85, 0.3, 0), fur.darkened(0.2))
		"kitsune":
			var tails: int = int(lk.get("tails", 5))
			for i in tails:
				var spread := (i - (tails - 1) * 0.5) * 0.18
				var t := joint(body, Vector3(-0.5, 0.15, spread * 0.3), Vector3(0, spread * 30.0, -50.0 + i * (100.0 / tails) + _p(p, "tail")))
				var tip := chain(t, Vector3.ZERO, Vector3(-0.5, 1.0, 0), 0.7, -50.0, 0.1, 0.07, fur if i % 2 == 0 else fur.lightened(0.15), 5)
				ball(t, 0.1, tip, WHITE)
				glow(t, 0.05, tip + Vector3(-0.05, 0.05, 0), cols["glow"], 2.5)
		"manticore":
			bat_wings(body, Vector3(0.0, 0.28, 0), 0.75, p, fur.darkened(0.25), cols["accent"])
			var t := joint(body, Vector3(-0.5, 0.15, 0), Vector3(0, 0, 50.0 + _p(p, "tail")))
			var tip := chain(t, Vector3.ZERO, Vector3(-0.6, 1, 0), 0.75, -120.0, 0.09, 0.06, cols["second"], 7)
			cyl(t, 0.07, 0.0, 0.2, tip + Vector3(0.05, -0.05, 0), Color("2b2f3a"), Vector3(0, 0, -150), 8)
		"chimera":
			var t := joint(body, Vector3(-0.5, 0.05, 0), Vector3(0, 0, 25.0 + _p(p, "tail")))
			var tip := chain(t, Vector3.ZERO, Vector3(-1, 0.5, 0), 0.6, 60.0, 0.07, 0.05, Color("56b84a"), 6)
			ball(t, 0.1, tip, Color("56b84a"), Vector3(1.4, 0.8, 0.9))
			side_eye(t, tip + Vector3(0.03, 0.05, 0.06), 0.04, 0.0)
			ball(body, 0.24, Vector3(0.1, 0.36, 0), Color("e9e2d0"))
			horns(body, Vector3(0.12, 0.5, 0), 0.35, Color("8a6a4a"), -80.0)
		"sphinx":
			chain(body, Vector3(-0.5, 0.0, 0), Vector3(-1, 0.1, 0), 0.5, 40.0, 0.04, 0.02, fur, 5)
			feather_wings(body, Vector3(0.0, 0.25, 0), 0.6, p, Color("ffcf3a"), cols["accent"])
		_:
			chain(body, Vector3(-0.5, 0.05, 0), Vector3(-1, 0.2, 0), 0.5, 50.0, 0.05, 0.03, fur, 5)
	for hz in heads:
		var head := joint(body, Vector3(0.5, 0.28, float(hz)), Vector3(float(hz) * -40.0, 0, -_p(p, "head") - (float(hz) * 20.0 if kind == "cerberus" else 0.0)))
		if kind == "griffin":
			ball(head, 0.24, Vector3.ZERO, WHITE)
			cyl(head, 0.09, 0.0, 0.26, Vector3(0.28, -0.04, 0), Color("ffb347"), Vector3(0, 0, -100 + _p(p, "jaw") * 10.0), 12)
			for i in 3:
				box(head, Vector3(0.25, 0.05, 0.08), Vector3(-0.15, 0.1 + i * 0.05, 0), cols["accent"], Vector3(0, 0, 30 + i * 12), null, 0.02)
			for side: float in [-1.0, 1.0]:
				side_eye(head, Vector3(0.1, 0.06, side * 0.16), 0.08, _p(p, "squint"))
			continue
		var r := 0.25 if kind != "cerberus" else 0.19
		ball(head, r, Vector3.ZERO, fur, Vector3(1.05, 0.95, 1.0))
		ball(head, r * 0.55, Vector3(r * 0.9, -r * 0.25, 0), cols["second"], Vector3(1.3, 0.8, 1.0))
		ball(head, r * 0.12, Vector3(r * 1.45, -r * 0.15, 0), Color("2b2f3a"))
		var jaw := joint(head, Vector3(r * 0.7, -r * 0.5, 0), Vector3(0, 0, -_p(p, "jaw") * 26.0))
		box(jaw, Vector3(r * 0.8, r * 0.15, r * 0.8), Vector3(r * 0.25, 0, 0), cols["second"], Vector3.ZERO, null, r * 0.05)
		for side: float in [-1.0, 1.0]:
			side_eye(head, Vector3(r * 0.45, r * 0.3, side * r * 0.6), r * 0.33, _p(p, "squint"), cols["accent"].darkened(0.5))
			if kind == "kitsune" or kind == "cerberus":
				cyl(head, r * 0.3, 0.0, r * 0.9, Vector3(-r * 0.2, r * 0.95, side * r * 0.45), fur, Vector3(side * 15, 0, 10), 8)
		if kind == "sphinx":
			box(head, Vector3(r * 1.6, r * 0.5, r * 2.4), Vector3(-r * 0.4, r * 0.5, 0), Color("ffcf3a"), Vector3(0, 0, 10), null, 0.04)
			for i in 3:
				box(head, Vector3(r * 1.62, r * 0.08, r * 2.42), Vector3(-r * 0.4, r * 0.35 + i * r * 0.15, 0), Color("2f8cf0"), Vector3(0, 0, 10), null, 0.0)
		if kind == "manticore":
			for i in 7:
				var a := TAU * i / 7.0
				ball(head, r * 0.35, Vector3(-r * 0.3, sin(a) * r * 0.85, cos(a) * r * 0.85), cols["accent"])


## Many heads on one body.
func _plan_hydra(c: Node3D, p: Dictionary, cols: Dictionary, lk: Dictionary) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.45 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch") * 0.5))
	ball(body, 0.48, Vector3.ZERO, cols["body"], Vector3(1.2, 0.85, 1.0))
	ball(body, 0.35, Vector3(0.1, -0.15, 0), cols["second"], Vector3(1.2, 0.7, 1.1))
	_legs4(body, p, cols, 0.34, 0.3, -0.2, 0.25, 0.09)
	chain(body, Vector3(-0.5, 0.0, 0), Vector3(-1, -0.2, 0), 0.7, 60.0, 0.14, 0.04, cols["body"], 6)
	var n: int = int(lk.get("heads", 3))
	for i in n:
		var z := (i - (n - 1) * 0.5) * 0.3
		var sway := sin(_p(p, "spin") * TAU + i * 1.7) * 12.0
		var neck := joint(body, Vector3(0.3, 0.25, z), Vector3(z * 60.0, 0, sway))
		var tip := chain(neck, Vector3.ZERO, Vector3(0.4, 1.0, z * 1.2), 0.85 + (0.15 if i == n / 2 else 0.0), -60.0, 0.11, 0.08, cols["body"], 6)
		var head := joint(neck, tip + Vector3(0.04, 0, 0), Vector3(0, 0, -_p(p, "head") - 15.0))
		box(head, Vector3(0.28, 0.18, 0.2), Vector3(0.08, 0, 0), cols["body"], Vector3.ZERO, null, 0.07)
		var jaw := joint(head, Vector3(0.05, -0.08, 0), Vector3(0, 0, -_p(p, "jaw") * 30.0))
		box(jaw, Vector3(0.26, 0.05, 0.16), Vector3(0.12, 0, 0), cols["second"], Vector3.ZERO, null, 0.02)
		for side: float in [-1.0, 1.0]:
			side_eye(head, Vector3(0.1, 0.07, side * 0.09), 0.055, _p(p, "squint"), Color("2a1a08"))
		cyl(head, 0.03, 0.0, 0.14, Vector3(-0.05, 0.12, 0), cols["accent"], Vector3(0, 0, 30), 6)


## A kraken: a big dome with eyes and curling tentacles.
func _plan_kraken(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.65 + _p(p, "bob") * 1.5, 0), Vector3(0, 0, -_p(p, "pitch") * 0.6))
	ball(body, 0.5, Vector3(-0.05, 0.25, 0), cols["body"], Vector3(1.0, 1.25, 1.0))
	for i in 5:
		ball(body, 0.06, Vector3(-0.25 + i * 0.06, 0.6 - abs(i - 2) * 0.05, 0.3), cols["accent"])
	for side: float in [-1.0, 1.0]:
		side_eye(body, Vector3(0.32, 0.15, side * 0.22), 0.14, _p(p, "squint"), Color("ffcf3a").darkened(0.6))
	for i in 8:
		var a := TAU * i / 8.0
		var root := Vector3(cos(a) * 0.32, -0.15, sin(a) * 0.32)
		var wave := sin(_p(p, "spin") * TAU + i) * 30.0
		chain(body, root, Vector3(cos(a), -1.0, sin(a)), 0.8, 90.0 + wave, 0.08, 0.025, cols["body"] if i % 2 else cols["second"], 7)


## An egg about to hatch: a spotted shell with eyes peeking through a crack.
func _plan_egg(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	var body := joint(c, Vector3(_p(p, "lean") * 0.3, 0.0, 0), Vector3(_p(p, "stride") * 0.3, 0, -_p(p, "pitch") * 0.8))
	ball(body, 0.45, Vector3(0, 0.55 + _p(p, "bob") * 0.5, 0), cols["second"], Vector3(0.95, 1.25, 0.95))
	for i in 7:
		var a := float(i) * 2.3
		ball(body, 0.09, Vector3(cos(a) * 0.36, 0.35 + (i % 3) * 0.22, sin(a) * 0.36 + 0.06), cols["body"], Vector3(1, 1, 0.3))
	for i in 5:
		box(body, Vector3(0.12, 0.03, 0.02), Vector3(0.32, 0.7 + (i % 2) * 0.04, -0.16 + i * 0.08), Color("2b2f3a"), Vector3(0, 70, 25 if i % 2 else -25), null, 0.0)
	for side: float in [-1.0, 1.0]:
		side_eye(body, Vector3(0.36, 0.62, side * 0.1), 0.06, _p(p, "squint"), Color("2a1a08"))
	glow(body, 0.05, Vector3(0.38, 0.55, 0), cols["glow"], 2.0)


## A phoenix: a bird of fire with a long trailing tail of flames.
func _plan_phoenix(c: Node3D, p: Dictionary, cols: Dictionary) -> void:
	_plan_bird(c, p, cols)
	var body: Node3D = c.get_child(0) as Node3D
	for i in 5:
		var t := joint(body, Vector3(-0.4, 0.0, (i - 2) * 0.06), Vector3((i - 2) * 8.0, 0, -20.0 + _p(p, "tail") * 0.5))
		var tip := chain(t, Vector3.ZERO, Vector3(-1, -0.2, 0), 0.9 + (0.2 if i == 2 else 0.0), 50.0, 0.05, 0.02, cols["accent"] if i % 2 else cols["body"], 6)
		glow(t, 0.07, tip, cols["glow"], 3.5)
	for i in 3:
		cyl(body, 0.06, 0.0, 0.35, Vector3(-0.05 + i * 0.1, 0.42, 0), cols["accent"], Vector3(0, 0, -20 + i * 20), 8, gloss(cols["accent"], 1.5))
