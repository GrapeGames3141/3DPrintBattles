extends "res://tools/render_art7.gd"
## Hybrids of legend, the way a maker would print them: two-tone silk
## filament, armour plates, brass gears on the joints, glowing resin parts.
## A creature's `look` names a frame and the parts that go on it:
##
##   frame   taur (a torso on a beast or insect body), quad, biped, kraken,
##           seahorse (a horse with a fish tail), wyrm (long body, many heads),
##           crawler (many legs), rover (wheels)
##   head    human, medusa, jackal, eagle, lion, bull, horse, dog, serpent, ram,
##           stag, bug, robot, dish, rock, fox, owl, skull
##   lower   scarab, lion, insect, horse, tentacles, wheels, serpent, rock
##   extras  feather_wings, bat_wings, bug_wings, nine_tails, snake_tail,
##           segment_tail, fish_tail, spikes, coil_spine, core, antlers,
##           ram_horns, drills, solar, flame_mane, crown, mask, armor, gears
##   colors  [main, second, metal, glow] as hex, for a two-tone print
##
##   godot --path . --disable-vsync -s tools/render_art8.gd -- <id ...>   (or "hybrids")

const LOOKS8 := "res://tools/catalog/looks.json"


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
	var looks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LOOKS8))
	for id in looks:
		var lk: Dictionary = looks[id]
		if str(lk.get("plan", "")) != "hybrid":
			continue
		if only.is_empty() or only.has(id) or only.has("hybrids"):
			await _rig_sheet(id, _hyb.bind(lk), int(lk.get("stage", 2)))
	quit()


func _hc(lk: Dictionary) -> Dictionary:
	var pal: Array = PAL.get(str(lk.get("element", "Neutral")), PAL["Neutral"])
	var given: Array = lk.get("colors", [])
	var main: Color = Color(given[0]) if given.size() > 0 else pal[0]
	var second: Color = Color(given[1]) if given.size() > 1 else pal[1]
	var metal: Color = Color(given[2]) if given.size() > 2 else Color("e9a91c")
	var glow_c: Color = Color(given[3]) if given.size() > 3 else pal[3]
	return {"body": main, "second": second, "metal": metal, "glow": glow_c, "accent": metal, "el": str(lk.get("element", "Neutral"))}


## Silk filament: two colours swirled, done by alternating the colour of parts.
func silk(i: int, h: Dictionary) -> Color:
	return h["body"] if i % 2 == 0 else (h["body"] as Color).lerp(h["second"], 0.55)


func gear_at(parent: Node3D, at: Vector3, r: float, h: Dictionary, facing := Vector3(90, 0, 0)) -> void:
	cyl(parent, r, r, r * 0.35, at, h["metal"], facing, 12, metal_mat(h["metal"]))
	for t in 8:
		var a := TAU * t / 8.0
		var off := Vector3(cos(a) * r * 1.15, sin(a) * r * 1.15, 0)
		if facing.x == 90:
			off = Vector3(cos(a) * r * 1.15, sin(a) * r * 1.15, 0)
		box(parent, Vector3(r * 0.3, r * 0.3, r * 0.3), at + off, h["metal"], Vector3(0, 0, rad_to_deg(a)), metal_mat(h["metal"]), 0.0)
	ball(parent, r * 0.3, at + Vector3(0, 0, r * 0.2), (h["metal"] as Color).darkened(0.3))


func plate_on(parent: Node3D, size: Vector3, at: Vector3, h: Dictionary, rot := Vector3.ZERO, i := 0) -> void:
	box(parent, size, at, silk(i, h), rot, null, minf(size.x, size.y) * 0.25)
	for s in [-1.0, 1.0]:
		ball(parent, minf(size.x, size.y) * 0.08, at + Vector3(size.x * 0.35 * s, size.y * 0.3, size.z * 0.5), h["metal"])


func _hyb(c: Node3D, p: Dictionary, stage: int, lk: Dictionary) -> void:
	_rng.seed = int(lk.get("seed", 1))
	var h := _hc(lk)
	c.scale = Vector3.ONE * float(lk.get("scale", 1.0))
	var extras: Array = lk.get("extras", [])
	match str(lk.get("frame", "quad")):
		"taur":
			_f_taur(c, p, h, lk, extras)
		"biped":
			_f_biped(c, p, h, lk, extras)
		"kraken":
			_f_kraken(c, p, h, lk, extras)
		"seahorse":
			_f_seahorse(c, p, h, lk, extras)
		"wyrm":
			_f_wyrm(c, p, h, lk, extras)
		"crawler":
			_f_crawler(c, p, h, lk, extras)
		"rover":
			_f_rover(c, p, h, lk, extras)
		_:
			_f_quad(c, p, h, lk, extras)


# ----------------------------------------------------------------- heads

func hhead(parent: Node3D, at: Vector3, kind: String, s: float, p: Dictionary, h: Dictionary, extras: Array) -> Node3D:
	var head := joint(parent, at, Vector3(0, 0, -_p(p, "head")))
	var main: Color = h["body"]
	var sq := _p(p, "squint")
	match kind:
		"human", "medusa":
			ball(head, s * 0.8, Vector3.ZERO, main.lightened(0.1), Vector3(0.95, 1.1, 0.9))
			box(head, Vector3(s * 0.3, s * 0.2, s * 0.25), Vector3(s * 0.72, -s * 0.05, 0), main.lightened(0.1), Vector3.ZERO, null, s * 0.05)
			for side: float in [-1.0, 1.0]:
				side_eye(head, Vector3(s * 0.55, s * 0.18, side * s * 0.3), s * 0.18, sq, Color("2a1a08"))
			box(head, Vector3(s * 0.05, s * 0.05 + _p(p, "jaw") * s * 0.15, s * 0.3), Vector3(s * 0.72, -s * 0.38, 0), Color("4a1020"), Vector3.ZERO, null, 0.0)
			if kind == "medusa":
				for i in 12:
					var a := TAU * i / 12.0
					var root := Vector3(-s * 0.1 + cos(a) * s * 0.3, s * 0.55 + sin(a) * s * 0.25, sin(a) * s * 0.6)
					var tip := chain(head, root, Vector3(-0.5 + cos(a) * 0.5, 0.9, sin(a)), s * 1.3, -90.0 + (i % 3) * 40.0, s * 0.09, s * 0.06, silk(i, h), 5)
					ball(head, s * 0.11, tip, silk(i + 1, h), Vector3(1.4, 0.9, 1.0))
		"jackal":
			ball(head, s * 0.65, Vector3.ZERO, main, Vector3(1.0, 0.95, 0.9))
			cyl(head, s * 0.32, s * 0.12, s * 0.9, Vector3(s * 0.75, -s * 0.15, 0), main, Vector3(0, 0, -100), 16)
			for side: float in [-1.0, 1.0]:
				cyl(head, s * 0.22, 0.0, s * 1.1, Vector3(-s * 0.1, s * 0.95, side * s * 0.3), main, Vector3(side * 5, 0, -5), 4)
				side_eye(head, Vector3(s * 0.38, s * 0.15, side * s * 0.38), s * 0.15, sq, h["metal"])
		"eagle", "owl":
			ball(head, s * 0.7, Vector3.ZERO, h["second"] if kind == "eagle" else main)
			cyl(head, s * 0.25, 0.0, s * 0.6, Vector3(s * 0.72, -s * 0.12, 0), h["metal"], Vector3(0, 0, -110), 12, metal_mat(h["metal"]))
			for side: float in [-1.0, 1.0]:
				side_eye(head, Vector3(s * 0.38, s * 0.15, side * s * 0.42), s * (0.17 if kind == "eagle" else 0.24), sq, Color("2a1a08"))
			for i in 5:
				box(head, Vector3(s * 0.8, s * 0.12, s * 0.2), Vector3(-s * 0.4, s * 0.35 + i * s * 0.1, (i - 2) * s * 0.12), silk(i, h), Vector3(0, (i - 2) * 12, 35 + i * 8), null, s * 0.04)
		"lion", "ram", "stag", "fox", "dog":
			ball(head, s * 0.65, Vector3.ZERO, main)
			ball(head, s * 0.38, Vector3(s * 0.55, -s * 0.18, 0), h["second"], Vector3(1.3, 0.85, 1.0))
			ball(head, s * 0.1, Vector3(s * 0.95, -s * 0.08, 0), Color("2b2f3a"))
			var jaw := joint(head, Vector3(s * 0.45, -s * 0.42, 0), Vector3(0, 0, -_p(p, "jaw") * 28.0))
			box(jaw, Vector3(s * 0.5, s * 0.12, s * 0.5), Vector3(s * 0.15, 0, 0), h["second"], Vector3.ZERO, null, s * 0.04)
			for t in 2:
				cyl(jaw, s * 0.05, 0.0, s * 0.15, Vector3(s * 0.3, s * 0.08, (t - 0.5) * s * 0.3), WHITE, Vector3.ZERO, 6)
			for side: float in [-1.0, 1.0]:
				side_eye(head, Vector3(s * 0.38, s * 0.22, side * s * 0.4), s * 0.16, sq, h["metal"].darkened(0.4))
			if kind == "lion" or kind == "ram" or kind == "stag":
				for i in 14:
					var a := TAU * i / 14.0
					cyl(head, s * 0.16, 0.0, s * 0.55, Vector3(-s * 0.2, cos(a) * s * 0.62, sin(a) * s * 0.62), silk(i, h) if not extras.has("flame_mane") else h["glow"], Vector3(rad_to_deg(a) - 90, 0, 0), 6, gloss(h["glow"], 1.4, 0.85) if extras.has("flame_mane") else null)
			if kind == "fox" or kind == "dog":
				for side: float in [-1.0, 1.0]:
					cyl(head, s * 0.25, 0.0, s * 0.6, Vector3(-s * 0.05, s * 0.68, side * s * 0.32), main, Vector3(side * 12, 0, 8), 8)
			if kind == "ram":
				horns(head, Vector3(-s * 0.15, s * 0.45, 0), s * 1.4, h["metal"], -220.0)
			if kind == "stag":
				_antlers(head, Vector3(-s * 0.15, s * 0.55, 0), s, h)
		"bull":
			ball(head, s * 0.7, Vector3.ZERO, main, Vector3(1.05, 0.95, 1.1))
			box(head, Vector3(s * 0.55, s * 0.45, s * 0.7), Vector3(s * 0.55, -s * 0.2, 0), main.lightened(0.08), Vector3.ZERO, null, s * 0.15)
			torus(head, s * 0.14, s * 0.035, Vector3(s * 0.85, -s * 0.38, 0), h["metal"], Vector3(0, 90, 0), metal_mat(h["metal"]))
			horns(head, Vector3(-s * 0.05, s * 0.5, 0), s * 1.3, Color("f4efe0"), 70.0)
			for side: float in [-1.0, 1.0]:
				side_eye(head, Vector3(s * 0.38, s * 0.22, side * s * 0.45), s * 0.15, sq, Color("8a1a1a"))
		"horse":
			box(head, Vector3(s * 1.0, s * 0.6, s * 0.6), Vector3(s * 0.2, 0, 0), main, Vector3(0, 0, -15), null, s * 0.2)
			for side: float in [-1.0, 1.0]:
				side_eye(head, Vector3(s * 0.05, s * 0.18, side * s * 0.3), s * 0.13, sq)
				cyl(head, s * 0.12, 0.0, s * 0.35, Vector3(-s * 0.2, s * 0.45, side * s * 0.18), main, Vector3(side * 10, 0, 15), 8)
			plate_on(head, Vector3(s * 0.7, s * 0.25, s * 0.62), Vector3(s * 0.25, s * 0.25, 0), h, Vector3(0, 0, -15), 1)
		"serpent":
			box(head, Vector3(s * 1.0, s * 0.5, s * 0.55), Vector3(s * 0.25, 0, 0), main, Vector3.ZERO, null, s * 0.18)
			var jaw := joint(head, Vector3(s * 0.1, -s * 0.22, 0), Vector3(0, 0, -_p(p, "jaw") * 32.0))
			box(jaw, Vector3(s * 0.9, s * 0.12, s * 0.45), Vector3(s * 0.35, 0, 0), h["second"], Vector3.ZERO, null, s * 0.04)
			for t in 3:
				cyl(jaw, s * 0.04, 0.0, s * 0.14, Vector3(s * 0.4 + t * s * 0.15, s * 0.08, s * 0.16), WHITE, Vector3.ZERO, 6)
			for side: float in [-1.0, 1.0]:
				side_eye(head, Vector3(s * 0.3, s * 0.2, side * s * 0.28), s * 0.12, sq, Color("ffcf3a").darkened(0.5))
			for i in 6:
				box(head, Vector3(s * 0.75, s * 0.12, s * 0.15), Vector3(-s * 0.3, s * 0.2 + i * s * 0.09, (i - 2.5) * s * 0.1), h["glow"] if i % 2 else h["second"], Vector3((i - 2.5) * 14, 0, 45 + i * 6), null, s * 0.03)
		"bug":
			ball(head, s * 0.6, Vector3.ZERO, main, Vector3(1.1, 0.9, 1.0))
			for side: float in [-1.0, 1.0]:
				ball(head, s * 0.3, Vector3(s * 0.35, s * 0.15, side * s * 0.35), h["glow"]).material_override = gloss(h["glow"], 0.8, 1.0, 0.1)
				stick(head, Vector3(s * 0.5, -s * 0.3, side * s * 0.15), Vector3(s * 0.95, -s * 0.45 - _p(p, "jaw") * s * 0.15, side * s * (0.1 + _p(p, "jaw") * 0.2)), s * 0.06, h["metal"])
				chain(head, Vector3(s * 0.2, s * 0.5, side * s * 0.2), Vector3(0.6, 1, side * 0.4), s * 1.0, -40.0, s * 0.03, s * 0.02, h["metal"], 4)
		"robot", "dish":
			box(head, Vector3(s * 1.0, s * 0.8, s * 0.9), Vector3.ZERO, main, Vector3.ZERO, null, s * 0.15)
			box(head, Vector3(s * 0.05, s * 0.22, s * 0.7), Vector3(s * 0.5, s * 0.1, 0), h["glow"], Vector3.ZERO, gloss(h["glow"], 2.0), 0.0)
			if kind == "dish":
				cyl(head, s * 0.8, s * 0.2, s * 0.25, Vector3(-s * 0.1, s * 0.7, 0), Color("c7ced6"), Vector3(0, 0, -30), 32, metal_mat(Color("c7ced6")))
				stick(head, Vector3(-s * 0.1, s * 0.7, 0), Vector3(s * 0.25, s * 1.0, 0), s * 0.04, h["metal"])
			else:
				for side: float in [-1.0, 1.0]:
					stick(head, Vector3(0, s * 0.4, side * s * 0.3), Vector3(-s * 0.2, s * 1.0, side * s * 0.45), s * 0.04, h["metal"])
					glow(head, s * 0.08, Vector3(-s * 0.2, s * 1.0, side * s * 0.45), h["glow"], 3.0)
		"rock":
			for i in 5:
				box(head, Vector3(s * 0.6, s * 0.5, s * 0.6), Vector3((i % 2) * s * 0.2 - s * 0.1, (i / 2) * s * 0.25, (i % 3 - 1) * s * 0.2), silk(i, h), Vector3(i * 20, i * 33, i * 11), null, s * 0.08)
			for side: float in [-1.0, 1.0]:
				glow(head, s * 0.1, Vector3(s * 0.4, s * 0.2, side * s * 0.2), h["glow"], 4.0)
		"skull":
			ball(head, s * 0.7, Vector3.ZERO, Color("eee8d8"), Vector3(1.0, 1.0, 0.95))
			for side: float in [-1.0, 1.0]:
				ball(head, s * 0.2, Vector3(s * 0.48, s * 0.1, side * s * 0.25), Color("1a1418"))
				glow(head, s * 0.07, Vector3(s * 0.6, s * 0.1, side * s * 0.25), h["glow"], 4.0)
		_:
			ball(head, s * 0.65, Vector3.ZERO, main)
			for side: float in [-1.0, 1.0]:
				side_eye(head, Vector3(s * 0.4, s * 0.2, side * s * 0.4), s * 0.17, sq)
	if extras.has("crown"):
		for i in 5:
			cyl(head, s * 0.09, 0.0, s * (0.35 + (0.15 if i == 2 else 0.0)), Vector3(-s * 0.05, s * 0.7, (i - 2) * s * 0.18), h["metal"], Vector3.ZERO, 8, metal_mat(h["metal"]))
	if extras.has("mask"):
		box(head, Vector3(s * 0.12, s * 0.7, s * 0.8), Vector3(s * 0.62, s * 0.12, 0), h["metal"], Vector3.ZERO, metal_mat(h["metal"]), s * 0.1)
		for side: float in [-1.0, 1.0]:
			ball(head, s * 0.09, Vector3(s * 0.7, s * 0.22, side * s * 0.2), Color("10151c"))
	if extras.has("antlers") and kind != "stag":
		_antlers(head, Vector3(-s * 0.15, s * 0.55, 0), s, h)
	if extras.has("ram_horns") and kind != "ram":
		horns(head, Vector3(-s * 0.15, s * 0.45, 0), s * 1.3, h["metal"], -220.0)
	if extras.has("headdress"):
		box(head, Vector3(s * 1.0, s * 0.35, s * 1.5), Vector3(-s * 0.2, s * 0.55, 0), h["metal"], Vector3(0, 0, 8), metal_mat(h["metal"]), s * 0.06)
		for i in 3:
			box(head, Vector3(s * 0.5, s * 0.06, s * 1.52), Vector3(-s * 0.55, s * 0.2 - i * s * 0.18, 0), h["body"], Vector3(0, 0, 70), null, 0.0)
	return head


func _antlers(head: Node3D, at: Vector3, s: float, h: Dictionary) -> void:
	for side: float in [-1.0, 1.0]:
		var base := at + Vector3(0, 0, side * s * 0.3)
		var top := chain(head, base, Vector3(-0.3, 1, side * 0.5), s * 1.6, -20.0, s * 0.08, s * 0.05, h["second"], 5)
		for b in 3:
			var from: Vector3 = base.lerp(top, 0.35 + b * 0.22)
			chain(head, from, Vector3(0.3 + b * 0.1, 1, side * 0.3), s * 0.6, 30.0, s * 0.05, s * 0.03, h["second"], 3)


# ---------------------------------------------------------------- extras

func hextras(body: Node3D, extras: Array, p: Dictionary, h: Dictionary, back: Vector3, top: Vector3, size: float) -> void:
	if extras.has("feather_wings"):
		feather_wings(body, top, size * 1.0, p, h["body"], h["metal"] if extras.has("gold_feathers") else h["second"])
	if extras.has("bat_wings"):
		bat_wings(body, top, size * 0.95, p, (h["body"] as Color).darkened(0.25), h["second"])
	if extras.has("bug_wings"):
		for side: float in [-1.0, 1.0]:
			var w := joint(body, top, Vector3(side * (30.0 + _p(p, "arm") * 0.6), 0, 40 + _p(p, "arm")))
			for k in 2:
				box(w, Vector3(size * 0.75, 0.025, size * 0.24), Vector3(-size * 0.35, k * 0.04, side * (size * 0.15 + k * size * 0.22)), h["glow"], Vector3(0, side * k * 20, 10), gloss(h["glow"], 0.4, 0.65, 0.05), 0.0)
	if extras.has("nine_tails"):
		for i in 9:
			var t := joint(body, back, Vector3(0, (i - 4) * 9.0, -40.0 + i * 12.0 + _p(p, "tail")))
			var tip := chain(t, Vector3.ZERO, Vector3(-0.6, 1.0, 0), size * 0.75, -60.0, size * 0.08, size * 0.03, h["glow"], 5)
			glow(t, size * 0.04, tip, h["glow"], 2.5)
			for n in _meshes(t):
				(n as MeshInstance3D).material_override = gloss(h["glow"], 1.2, 0.85, 0.2)
	if extras.has("snake_tail"):
		var t := joint(body, back, Vector3(0, 0, 30.0 + _p(p, "tail")))
		var tip := chain(t, Vector3.ZERO, Vector3(-1, 0.8, 0), size * 1.0, -150.0, size * 0.09, size * 0.06, h["second"], 8)
		hhead(t, tip + Vector3(0.05, 0, 0), "serpent", size * 0.16, p, h, [])
	if extras.has("segment_tail"):
		var t := joint(body, back, Vector3(0, 0, -20.0 + _p(p, "tail")))
		var pos := Vector3.ZERO
		for i in 9:
			var nx := pos + Vector3(-size * 0.12, -size * 0.04 + i * size * 0.01, 0)
			box(t, Vector3(size * 0.13, size * 0.1, size * 0.1), nx, h["body"] if i % 2 else h["metal"], Vector3(0, 0, -10 + i * 5), null, size * 0.02)
			pos = nx
	if extras.has("fish_tail"):
		var t := joint(body, back, Vector3(0, 0, -10.0 + _p(p, "tail") + sin(_p(p, "spin") * TAU) * 10.0))
		var tip := chain(t, Vector3.ZERO, Vector3(-1, -0.2, 0), size * 1.1, 80.0, size * 0.2, size * 0.06, h["second"], 8)
		for s2: float in [-1.0, 1.0]:
			box(t, Vector3(size * 0.45, size * 0.2, 0.03), tip + Vector3(-size * 0.15, s2 * size * 0.15, 0), h["glow"], Vector3(0, 0, s2 * 40), gloss(h["glow"], 0.6, 0.8, 0.1), 0.02)
	if extras.has("spikes"):
		for i in 6:
			var at := top + Vector3(-size * 0.5 + i * size * 0.18, size * 0.05, (i % 2 - 0.5) * size * 0.3)
			cyl(body, size * 0.06, 0.0, size * 0.4, at, h["glow"], Vector3((i % 2 - 0.5) * 40, 0, 20), 5, gloss(h["glow"], 1.5, 0.9, 0.2))
	if extras.has("coil_spine"):
		for i in 8:
			torus(body, size * 0.1, size * 0.025, top + Vector3(-size * 0.5 + i * size * 0.12, size * 0.04, 0), h["metal"], Vector3(0, 0, 90), metal_mat(h["metal"]))
	if extras.has("solar"):
		for side: float in [-1.0, 1.0]:
			var w := joint(body, top, Vector3(side * 30, 0, 20 + _p(p, "arm")))
			box(w, Vector3(size * 0.7, 0.03, size * 0.45), Vector3(-size * 0.2, 0, side * size * 0.3), Color("1a3a8a"), Vector3.ZERO, gloss(Color("2a5ad8"), 0.3, 1.0, 0.05), 0.0)
	if extras.has("gears"):
		gear_at(body, top + Vector3(0, -size * 0.25, size * 0.3), size * 0.1, h)
		gear_at(body, top + Vector3(-size * 0.35, -size * 0.2, size * 0.3), size * 0.08, h)


func core_window(body: Node3D, at: Vector3, r: float, h: Dictionary) -> void:
	torus(body, r, r * 0.18, at, h["metal"], Vector3(90, 0, 0), metal_mat(h["metal"]))
	glow(body, r * 0.8, at, h["glow"], 4.0)


# ----------------------------------------------------------------- frames

## A beast on four legs: lion, ram, stag, dog. Cerberus gets three heads.
func _f_quad(c: Node3D, p: Dictionary, h: Dictionary, lk: Dictionary, extras: Array) -> void:
	# Each beast's own proportions: long or stocky, tall or low.
	var blen := _rng.randf_range(1.15, 1.75)
	var bh := _rng.randf_range(0.75, 1.05)
	var legk := _rng.randf_range(0.75, 1.35)
	var body := joint(c, Vector3(_p(p, "lean"), 0.45 + 0.17 * legk + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch")))
	ball(body, 0.42, Vector3.ZERO, h["body"], Vector3(blen, bh, 0.9))
	if extras.has("armor"):
		for i in 3:
			plate_on(body, Vector3(0.32, 0.18, 0.7), Vector3(-0.3 + i * 0.3, 0.3, 0), h, Vector3(0, 0, -8 + i * 8), i)
		plate_on(body, Vector3(0.18, 0.4, 0.55), Vector3(0.55, 0.0, 0), h, Vector3.ZERO, 1)
	if extras.has("core"):
		core_window(body, Vector3(0.55, 0.0, 0.0), 0.15, h)
	for side: float in [-1.0, 1.0]:
		for front: bool in [true, false]:
			var swing: float = _p(p, "stride") * (1.0 if front else -1.0) * side
			if front:
				swing += maxf(_p(p, "arm"), 0.0) * 0.6
			var hip := joint(body, Vector3((0.38 if front else -0.4) * blen / 1.45, -0.12, side * 0.25), Vector3(0, 0, swing))
			hip.scale = Vector3(1.0, legk, 1.0)
			ball(hip, 0.14, Vector3.ZERO, silk(int(front), h), Vector3(1.0, 1.4, 1.0))
			if extras.has("gears"):
				gear_at(hip, Vector3(0, -0.05, side * 0.12), 0.06, h)
			box(hip, Vector3(0.15, 0.36, 0.15), Vector3(0.02, -0.25, 0), silk(int(front) + 1, h), Vector3.ZERO, null, 0.04)
			for t in 3:
				cyl(hip, 0.035, 0.0, 0.13, Vector3(0.12, -0.45, (t - 1) * 0.06), (h["glow"] if extras.has("glow_claws") else Color("2b2f3a")), Vector3(0, 0, -80), 8)
	var back := Vector3(-0.58 * blen / 1.45, 0.1, 0)
	if not (extras.has("snake_tail") or extras.has("segment_tail") or extras.has("fish_tail") or extras.has("nine_tails")):
		var t := joint(body, back, Vector3(0, 0, 20.0 + _p(p, "tail")))
		var tip := chain(t, Vector3.ZERO, Vector3(-1, 0.4, 0), 0.6, 60.0, 0.05, 0.03, h["body"], 6)
		ball(t, 0.1, tip, h["second"])
	hextras(body, extras, p, h, back, Vector3(0.0, 0.3, 0), 0.9)
	var kind := str(lk.get("head", "lion"))
	var heads: Array = [0.0]
	if extras.has("three_heads"):
		heads = [-0.3, 0.0, 0.3]
	for hz in heads:
		var neck := joint(body, Vector3(0.55 * blen / 1.45, 0.22, float(hz)), Vector3(float(hz) * -30.0, 0, _rng.randf_range(-10.0, 25.0)))
		stick(neck, Vector3(-0.1, -0.05, 0), Vector3(0.2, 0.2, 0), 0.13 if heads.size() == 1 else 0.09, h["body"])
		hhead(neck, Vector3(0.22, 0.24, 0), kind, 0.5 if heads.size() == 1 else 0.36, p, h, extras)


## A torso standing on a beast or a bug: centaurs, a Medusa on a scarab.
func _f_taur(c: Node3D, p: Dictionary, h: Dictionary, lk: Dictionary, extras: Array) -> void:
	var lower := str(lk.get("lower", "lion"))
	var body := joint(c, Vector3(_p(p, "lean"), 0.6 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch") * 0.5))
	if lower == "scarab" or lower == "insect":
		ball(body, 0.48, Vector3(-0.25, 0.0, 0), h["body"], Vector3(1.35, 0.9, 1.05))
		for i in 4:
			torus(body, 0.38 - i * 0.04, 0.02, Vector3(-0.55 + i * 0.12, 0.0, 0), h["second"], Vector3(0, 0, 90), null)
		box(body, Vector3(0.02, 0.5, 0.02), Vector3(-0.25, 0.42, 0), h["metal"], Vector3(0, 0, 90), metal_mat(h["metal"]), 0.0)
		for side: float in [-1.0, 1.0]:
			for i in 3:
				var swing: float = _p(p, "stride") * (1.0 if i % 2 == 0 else -1.0) * side
				var hip := joint(body, Vector3(-0.1 - i * 0.2, -0.15, side * 0.3), Vector3(side * 20, 0, swing))
				gear_at(hip, Vector3(0, 0, side * 0.04), 0.05, h)
				var knee := Vector3(0.05, 0.18, side * 0.42)
				stick(hip, Vector3.ZERO, knee, 0.045, silk(i, h))
				var foot := Vector3(0.3 - i * 0.25, -0.5, side * 0.58)
				stick(hip, knee, foot, 0.04, silk(i + 1, h))
				cyl(hip, 0.04, 0.0, 0.12, foot + Vector3(0, -0.06, 0), h["second"], Vector3(0, 0, 180), 6)
	else:
		ball(body, 0.38, Vector3(-0.2, 0.0, 0), h["body"], Vector3(1.4, 0.85, 0.9))
		for side: float in [-1.0, 1.0]:
			for front: bool in [true, false]:
				var swing: float = _p(p, "stride") * (1.0 if front else -1.0) * side
				var hip := joint(body, Vector3(0.1 if front else -0.5, -0.12, side * 0.2), Vector3(0, 0, swing))
				box(hip, Vector3(0.14, 0.45, 0.14), Vector3(0, -0.25, 0), silk(int(front), h), Vector3.ZERO, null, 0.04)
				box(hip, Vector3(0.18, 0.08, 0.18), Vector3(0.02, -0.5, 0), h["metal"], Vector3.ZERO, metal_mat(h["metal"]), 0.02)
	hextras(body, extras, p, h, Vector3(-0.75, 0.1, 0), Vector3(-0.2, 0.35, 0), 0.9)
	# The upright torso.
	var torso := joint(body, Vector3(0.15, 0.25, 0), Vector3(0, 0, -_p(p, "lean") * 30.0))
	torso.scale = Vector3.ONE * 1.3
	box(torso, Vector3(0.32, 0.55, 0.45), Vector3(0, 0.3, 0), h["body"], Vector3.ZERO, null, 0.1)
	plate_on(torso, Vector3(0.12, 0.35, 0.4), Vector3(0.14, 0.38, 0), h, Vector3.ZERO, 1)
	for i in 3:
		box(torso, Vector3(0.1, 0.06, 0.3), Vector3(0.15, 0.08 + i * 0.07, 0), h["second"], Vector3.ZERO, null, 0.02)
	if extras.has("core"):
		core_window(torso, Vector3(0.18, 0.35, 0), 0.09, h)
	for side: float in [-1.0, 1.0]:
		var sh := joint(torso, Vector3(0, 0.52, side * 0.3), Vector3(side * 10, 0, 25.0 + _p(p, "arm") * 1.4))
		gear_at(sh, Vector3(0, 0, side * 0.06), 0.06, h)
		stick(sh, Vector3.ZERO, Vector3(0.12, -0.28, side * 0.05), 0.05, silk(0, h))
		stick(sh, Vector3(0.12, -0.28, side * 0.05), Vector3(0.3, -0.42, side * 0.05), 0.045, silk(1, h))
		for t in 3:
			cyl(sh, 0.025, 0.0, 0.12, Vector3(0.33 + t * 0.02, -0.46, side * 0.05 + (t - 1) * 0.03), h["second"], Vector3(0, 0, -120), 6)
	hhead(torso, Vector3(0.05, 0.82, 0), str(lk.get("head", "human")), 0.3, p, h, extras)


## Standing on two legs: Anubis with wings, a bull with fox tails, golems.
func _f_biped(c: Node3D, p: Dictionary, h: Dictionary, lk: Dictionary, extras: Array) -> void:
	var bird_legs := str(lk.get("lower", "")) == "bird"
	var rocky := str(lk.get("lower", "")) == "rock"
	var leg := 0.5
	var legk := _rng.randf_range(0.7, 1.3)
	var bodyk := _rng.randf_range(0.8, 1.25)
	var body := joint(c, Vector3(_p(p, "lean"), leg * legk + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch") * 0.6))
	for side: float in [-1.0, 1.0]:
		var hip := joint(body, Vector3(0, 0.05, side * 0.18), Vector3(0, 0, _p(p, "stride") * side))
		hip.scale = Vector3(1.0, legk, 1.0)
		if bird_legs:
			stick(hip, Vector3.ZERO, Vector3(0.12, -0.22, 0), 0.07, h["metal"])
			stick(hip, Vector3(0.12, -0.22, 0), Vector3(-0.04, -0.48, 0), 0.05, h["body"])
			for t in 3:
				cyl(hip, 0.03, 0.0, 0.16, Vector3(0.05 + t * 0.02, -0.52, (t - 1) * 0.07), h["body"], Vector3(0, (t - 1) * 30, -80), 6)
		elif rocky:
			box(hip, Vector3(0.22, 0.5, 0.22), Vector3(0, -0.25, 0), silk(int(side > 0), h), Vector3(0, 20, 5), null, 0.05)
		else:
			box(hip, Vector3(0.16, 0.5, 0.16), Vector3(0, -0.25, 0), silk(int(side > 0), h), Vector3.ZERO, null, 0.05)
			plate_on(hip, Vector3(0.18, 0.2, 0.2), Vector3(0.03, -0.12, 0), h, Vector3.ZERO, 1)
		box(hip, Vector3(0.24, 0.07, 0.2), Vector3(0.06, -0.5, 0), h["metal"], Vector3.ZERO, metal_mat(h["metal"]), 0.02)
	var wide := (0.5 if not rocky else 0.65) * bodyk
	box(body, Vector3(0.36 * bodyk, 0.6, wide), Vector3(0, 0.38, 0), h["body"], Vector3.ZERO, null, 0.12)
	plate_on(body, Vector3(0.14, 0.4, wide * 0.85), Vector3(0.17, 0.45, 0), h, Vector3.ZERO, 1)
	if rocky:
		for i in 6:
			box(body, Vector3(0.2, 0.18, 0.2), Vector3(randf_range(-0.15, 0.1), 0.2 + i * 0.09, (i % 3 - 1) * 0.22), h["second"], Vector3(i * 31, i * 17, 9), null, 0.04)
	if extras.has("core"):
		core_window(body, Vector3(0.2, 0.42, 0), 0.1, h)
	for side: float in [-1.0, 1.0]:
		var sh := joint(body, Vector3(0, 0.62, side * (wide * 0.5 + 0.06)), Vector3(side * 8, 0, 20.0 + _p(p, "arm") * 1.4 - _p(p, "stride") * side * 0.4))
		box(sh, Vector3(0.22, 0.18, 0.22), Vector3(0, 0.02, 0), h["metal"], Vector3.ZERO, metal_mat(h["metal"]), 0.05)
		stick(sh, Vector3.ZERO, Vector3(0.05, -0.32, 0), 0.06, silk(0, h))
		stick(sh, Vector3(0.05, -0.32, 0), Vector3(0.12, -0.55, 0), 0.055, silk(1, h))
		if extras.has("drills"):
			cyl(sh, 0.1, 0.0, 0.3, Vector3(0.2, -0.7, 0), Color("c7ced6"), Vector3(0, 0, 20), 12, metal_mat(Color("c7ced6")))
		else:
			for t in 3:
				cyl(sh, 0.025, 0.0, 0.12, Vector3(0.14 + t * 0.02, -0.6, (t - 1) * 0.04), Color("2b2f3a"), Vector3(0, 0, -150), 6)
	hextras(body, extras, p, h, Vector3(-0.2, 0.15, 0), Vector3(-0.05, 0.62, 0), 0.9)
	stick(body, Vector3(0.02, 0.62, 0), Vector3(0.05, 0.86, 0), 0.1, h["second"])
	hhead(body, Vector3(0.05, 0.98, 0), str(lk.get("head", "human")), 0.34, p, h, extras)


## A monster on tentacles: Scylla, with dog heads around its waist.
func _f_kraken(c: Node3D, p: Dictionary, h: Dictionary, lk: Dictionary, extras: Array) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.65 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch") * 0.5))
	var arms := _rng.randi_range(5, 9)
	var reach := _rng.randf_range(0.6, 1.05)
	for i in arms:
		var a := TAU * i / float(arms)
		var wave := sin(_p(p, "spin") * TAU + i) * 35.0
		var tip := chain(body, Vector3(cos(a) * 0.22, -0.1, sin(a) * 0.22), Vector3(cos(a) * 0.8, -1, sin(a) * 0.8), reach, _rng.randf_range(90.0, 200.0) + wave, 0.07, 0.04, h["second"], 9)
	box(body, Vector3(0.45, 0.6, 0.55), Vector3(0, 0.3, 0), h["body"], Vector3.ZERO, null, 0.12)
	for i in 3:
		plate_on(body, Vector3(0.14, 0.15, 0.5), Vector3(0.2, 0.15 + i * 0.16, 0), h, Vector3.ZERO, i)
	spikes_along(body, [Vector3(-0.1, 0.62, 0), Vector3(-0.2, 0.52, 0.1), Vector3(-0.2, 0.52, -0.1)], h["metal"], 0.18)
	if extras.has("three_heads") or true:
		for i in 4:
			var a := -PI * 0.4 + i * PI * 0.27
			hhead(body, Vector3(cos(a) * 0.32, 0.0, sin(a) * 0.32), "dog", 0.13, p, h, [])
	hhead(body, Vector3(0.05, 0.75, 0), str(lk.get("head", "serpent")), 0.22, p, h, extras)


## A winged horse whose hindquarters end in a fish tail.
func _f_seahorse(c: Node3D, p: Dictionary, h: Dictionary, lk: Dictionary, extras: Array) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.7 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch") * 0.7))
	ball(body, 0.34, Vector3(0.1, 0, 0), h["body"], Vector3(1.3, 0.95, 0.85))
	ball(body, 0.24, Vector3(0.2, -0.05, 0), h["glow"], Vector3(1.0, 0.9, 1.05)).material_override = gloss(h["glow"], 0.3, 0.9, 0.2)
	for side: float in [-1.0, 1.0]:
		var hip := joint(body, Vector3(0.3, -0.15, side * 0.15), Vector3(0, 0, _p(p, "stride") * side + maxf(_p(p, "arm"), 0.0) * 0.8))
		stick(hip, Vector3.ZERO, Vector3(0.05, -0.3, 0), 0.055, h["body"])
		stick(hip, Vector3(0.05, -0.3, 0), Vector3(0, -0.55, 0), 0.045, h["body"])
		cyl(hip, 0.06, 0.07, 0.08, Vector3(0, -0.57, 0), h["metal"], Vector3.ZERO, 16, metal_mat(h["metal"]))
	hextras(body, ["fish_tail"] + extras, p, h, Vector3(-0.3, 0.0, 0), Vector3(0.0, 0.25, 0), 0.9)
	var neck := joint(body, Vector3(0.42, 0.15, 0), Vector3.ZERO)
	stick(neck, Vector3.ZERO, Vector3(0.12, 0.3, 0), 0.13, h["body"])
	for i in 6:
		cyl(neck, 0.05, 0.0, 0.2, Vector3(-0.03 + i * 0.03, 0.08 + i * 0.07, 0), h["glow"], Vector3(0, 0, 60), 4, gloss(h["glow"], 0.8, 0.85, 0.1))
	hhead(neck, Vector3(0.18, 0.4, 0), "horse", 0.3, p, h, extras)


## A long body with several heads on necks, wings and a feathered crest.
func _f_wyrm(c: Node3D, p: Dictionary, h: Dictionary, lk: Dictionary, extras: Array) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.5 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch") * 0.5))
	ball(body, 0.4, Vector3.ZERO, h["body"], Vector3(1.3, 0.85, 0.95))
	for i in 5:
		torus(body, 0.26 - absf(i - 2) * 0.03, 0.03, Vector3(-0.35 + i * 0.17, 0.0, 0), h["metal"], Vector3(0, 0, 90), metal_mat(h["metal"]))
	_legs4(body, p, h, 0.32, 0.25, -0.15, 0.32, 0.075)
	var t := joint(body, Vector3(-0.5, 0.0, 0), Vector3(0, 0, -10.0 + _p(p, "tail")))
	var tip := chain(t, Vector3.ZERO, Vector3(-1, -0.1, 0), 1.0, 60.0, 0.15, 0.05, h["body"], 9)
	spikes_along(t, [tip], h["glow"], 0.15)
	hextras(body, extras, p, h, Vector3(-0.5, 0.0, 0), Vector3(0.0, 0.28, 0), 1.0)
	var n: int = int(lk.get("heads", 3))
	for i in n:
		var z := (i - (n - 1) * 0.5) * 0.28
		var neck := joint(body, Vector3(0.35, 0.2, z), Vector3(z * 50.0, 0, sin(_p(p, "spin") * TAU + i * 1.7) * 10.0))
		var top := chain(neck, Vector3.ZERO, Vector3(0.4, 1.0, z * 1.2), 0.8 + (0.15 if i == n / 2 else 0.0), -55.0, 0.11, 0.08, silk(i, h), 7)
		for r in 4:
			torus(neck, 0.11, 0.015, top * (0.25 + r * 0.18), h["metal"], Vector3(0, 0, 40), metal_mat(h["metal"]))
		hhead(neck, top + Vector3(0.05, 0, 0), str(lk.get("head", "serpent")), 0.24, p, h, extras)


## Many legs and a low body: stalkers, crawlers, grubbers.
func _f_crawler(c: Node3D, p: Dictionary, h: Dictionary, lk: Dictionary, extras: Array) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.45 + _p(p, "bob"), 0), Vector3(0, 0, -_p(p, "pitch")))
	var shell := str(lk.get("lower", "insect"))
	if shell == "rock":
		for i in 7:
			box(body, Vector3(0.38, 0.32, 0.4), Vector3(-0.3 + (i % 3) * 0.25, (i / 3) * 0.15, (i % 2 - 0.5) * 0.3), silk(i, h), Vector3(i * 23, i * 41, i * 13), null, 0.06)
	else:
		ball(body, 0.42, Vector3(-0.1, 0.05, 0), h["body"], Vector3(1.3, 0.75, 1.1))
		for i in 3:
			torus(body, 0.4 - i * 0.05, 0.02, Vector3(-0.35 + i * 0.18, 0.05, 0), h["metal"], Vector3(0, 0, 90), metal_mat(h["metal"]))
	var pairs := _rng.randi_range(3, 5)
	body.scale = Vector3(_rng.randf_range(0.85, 1.3), _rng.randf_range(0.8, 1.2), 1.0)
	for side: float in [-1.0, 1.0]:
		for i in pairs:
			var swing: float = _p(p, "stride") * (1.0 if i % 2 == 0 else -1.0) * side
			var hip := joint(body, Vector3(0.25 - i * (0.7 / pairs), -0.05, side * 0.32), Vector3(side * 15, 0, swing))
			var knee := Vector3(0.0, 0.2, side * 0.4)
			stick(hip, Vector3.ZERO, knee, 0.04, silk(i, h))
			var foot := Vector3(0.3 - i * 0.2, -0.42, side * 0.6)
			stick(hip, knee, foot, 0.035, silk(i + 1, h))
			cyl(hip, 0.035, 0.0, 0.1, foot + Vector3(0, -0.04, 0), h["second"], Vector3(0, 0, 180), 6)
			if extras.has("gears"):
				gear_at(hip, Vector3(0, 0, side * 0.03), 0.04, h)
	hextras(body, extras, p, h, Vector3(-0.55, 0.05, 0), Vector3(-0.1, 0.3, 0), 0.85)
	hhead(body, Vector3(0.5, 0.12, 0), str(lk.get("head", "bug")), 0.3, p, h, extras)


## On wheels: a rover with a sensor head.
func _f_rover(c: Node3D, p: Dictionary, h: Dictionary, lk: Dictionary, extras: Array) -> void:
	var body := joint(c, Vector3(_p(p, "lean"), 0.35 + _p(p, "bob") * 0.5, 0), Vector3(0, 0, -_p(p, "pitch") * 0.4))
	box(body, Vector3(1.0, 0.3, 0.7), Vector3(0, 0.1, 0), h["body"], Vector3.ZERO, null, 0.08)
	plate_on(body, Vector3(0.6, 0.12, 0.62), Vector3(-0.05, 0.3, 0), h, Vector3.ZERO, 1)
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var at := Vector3(-0.38 + i * 0.38, -0.12, side * 0.4)
			cyl(body, 0.15, 0.15, 0.12, at, Color("2b2f3a"), Vector3(90, 0, _p(p, "spin") * 180.0), 18)
			cyl(body, 0.07, 0.07, 0.13, at, h["metal"], Vector3(90, 0, 0), 12, metal_mat(h["metal"]))
	hextras(body, extras, p, h, Vector3(-0.5, 0.15, 0), Vector3(-0.1, 0.35, 0), 0.9)
	var neck := joint(body, Vector3(0.35, 0.3, 0), Vector3(0, 0, -_p(p, "arm") * 0.3))
	stick(neck, Vector3.ZERO, Vector3(0.05, 0.3, 0), 0.05, h["metal"])
	hhead(neck, Vector3(0.08, 0.42, 0), str(lk.get("head", "robot")), 0.2, p, h, extras)
