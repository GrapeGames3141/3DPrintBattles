extends "res://tools/render_art3.gd"
## Fourth wave: six tools, four pieces of equipment and nine creatures that are
## modelled from primitives in the printed-plastic look, so they are new designs
## rather than recolours. Creatures are written to tools/creature_sources/ as
## cut-outs; tools/make_creatures.py fits them into sprite cells ("src:<id>").
##
##   godot --path . --disable-vsync -s tools/render_art4.gd              (all)
##   godot --path . --disable-vsync -s tools/render_art4.gd -- benchy_boss

const SRC_OUT := "res://tools/creature_sources/%s.png"
const MINT := Color("5fe0b4")
const COPPER := Color("d9773a")
const LIME := Color("b6e04a")
const ICE := Color("8fd8ff")
const VIOLET := Color("9c63f2")
const PINKISH := Color("ff7ac8")
const SLATE := Color("6b7480")
const SAND := Color("e9d8a6")


func _initialize() -> void:
	var only: Array = Array(OS.get_cmdline_user_args())
	await process_frame
	_build_studio()
	await process_frame
	var tools := {
		"fine_tweezers": [_tweezers, 40.0, 4.6, 0.1], "cutting_mat": [_mat_tool, 48.0, 5.0, 0.1],
		"magnifier_lamp": [_lamp, 22.0, 5.4, 0.9], "fire_extinguisher": [_extinguisher, 20.0, 5.4, 0.9],
		"dry_box": [_dryer, 30.0, 5.4, 0.6], "resin_printer": [_resin, 26.0, 5.8, 0.8],
	}
	var gear := {
		"glass_bed_shield": [_bed_shield, 10.0, 5.4, 0.9], "lead_screw_lance": [_lance, 10.0, 8.6, 1.0],
		"bowden_whip": [_whip, 10.0, 6.4, 0.9], "hotend_crown": [_crown, 12.0, 5.4, 0.6],
	}
	var beasts := {
		"benchy_boss": [_benchy, -26.0, 0.78], "spaghetti_mess": [_spaghetti, -18.0, 0.8],
		"cube_crab": [_crab, -28.0, 0.62], "layer_shifter": [_shifter, -20.0, 0.85],
		"stepper_golem": [_golem, -22.0, 0.95], "coil_cobra": [_cobra, -16.0, 0.95],
		"clog_goblin": [_goblin, -20.0, 0.72], "gantry_mantis": [_mantis, -24.0, 1.0],
		"tri_head_hydra": [_hydra, -14.0, 1.0], "cutie": [_roto, -16.0, 1.5, 8.6],
	}
	for id in tools:
		if only.is_empty() or only.has(id):
			var job: Array = tools[id]
			await _shoot(id, job[0], job[1], job[2], job[3])
	vp.transparent_bg = true
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.glow_enabled = false
	plate.visible = false
	vp.size = Vector2i(512, 512)
	for id in gear:
		if only.is_empty() or only.has(id):
			var job: Array = gear[id]
			_clear()
			job[0].call()
			_aim(job[1], job[2], job[3])
			await _settle()
			vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(ARMOR_OUT % id))
			print("rendered ", id)
	vp.size = Vector2i(1024, 1024)
	for id in beasts:
		if only.is_empty() or only.has(id):
			var job: Array = beasts[id]
			_clear()
			var r := group(job[1])
			_beast_root = r
			_holder = r
			(job[0] as Callable).call()
			_holder = stage
			cam.fov = 28.0
			_aim(14.0, float(job[3]) if job.size() > 3 else 6.2, job[2])
			await _settle()
			vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(SRC_OUT % id))
			print("rendered ", id)
	quit()


var _beast_root: Node3D


# ---------------------------------------------------------------- helpers

## Big friendly eyes, so a pile of parts reads as a creature.
func eyes(p: Node3D, pos: Vector3, spread: float, r := 0.13, look := 0.0) -> void:
	for s in [-1.0, 1.0]:
		var c: Vector3 = pos + Vector3(s * spread, 0, 0)
		ball(p, r, c, WHITE)
		ball(p, r * 0.55, c + Vector3(s * look * r, -r * 0.05, r * 0.78), Color("10151c"))
		ball(p, r * 0.18, c + Vector3(s * look * r + r * 0.18, r * 0.2, r * 1.2), WHITE)


func leg(p: Node3D, top: Vector3, foot: Vector3, r: float, col: Color) -> void:
	stick(p, top, foot, r, col)
	ball(p, r * 1.5, foot, col, Vector3(1.2, 0.6, 1.4))


func strand(p: Node3D, a: Vector3, dir: Vector3, length: float, col: Color, seed_v: float, r := 0.035) -> void:
	# A wobbly noodle: a chain of short rods that curls as it goes.
	var pos := a
	var d := dir.normalized()
	var n := 7
	for i in n:
		var bend := Vector3(sin(seed_v * 3.1 + i * 1.3), cos(seed_v * 1.7 + i * 0.9) * 0.6 - 0.35, cos(seed_v * 2.3 + i * 1.1)) * 0.55
		d = (d + bend).normalized()
		var nx := pos + d * (length / n)
		stick(p, pos, nx, r, col)
		ball(p, r, nx, col)
		pos = nx


# ------------------------------------------------------------------ tools

func _tweezers() -> void:
	var r := group(-20.0)
	for s in [-1.0, 1.0]:
		box(r, Vector3(1.9, 0.05, 0.14), Vector3(-0.3, 0.06 + 0.05, s * 0.12 + s * 0.0), STEEL, Vector3(0, -s * 4.0, 0), metal_mat(STEEL), 0.02)
		box(r, Vector3(0.5, 0.05, 0.05), Vector3(0.88, 0.11, s * 0.03), STEEL, Vector3(0, -s * 6.0, 0), metal_mat(STEEL), 0.01)
	box(r, Vector3(0.3, 0.06, 0.34), Vector3(-1.25, 0.11, 0), RED, Vector3.ZERO, null, 0.03)
	var tiny := group(-20.0, Vector3(0.5, 0, 0.9))
	box(tiny, Vector3(0.14, 0.14, 0.14), Vector3(0, 0.07, 0), ORANGE, Vector3(0, 30, 0))
	box(tiny, Vector3(0.1, 0.1, 0.1), Vector3(0.22, 0.05, 0.1), BLUE, Vector3(0, 10, 0))


func _mat_tool() -> void:
	var r := group(-12.0)
	box(r, Vector3(2.2, 0.08, 1.5), Vector3(0, 0.04, 0), Color("2f9a62"), Vector3.ZERO, null, 0.03)
	for i in 9:
		box(r, Vector3(0.012, 0.01, 1.4), Vector3(-0.96 + i * 0.24, 0.088, 0), WHITE.darkened(0.1))
	for i in 6:
		box(r, Vector3(2.1, 0.01, 0.012), Vector3(0, 0.088, -0.6 + i * 0.24), WHITE.darkened(0.1))
	box(r, Vector3(0.3, 0.012, 0.3), Vector3(0.0, 0.092, 0.0), Color("2f9a62").lightened(0.2))
	for i in 8:
		box(r, Vector3(0.012, 0.012, 0.09 if i % 2 else 0.16), Vector3(-0.9 + i * 0.12, 0.09, 0.66), YELLOW)
	box(r, Vector3(0.5, 0.2, 0.18), Vector3(0.55, 0.18, -0.15), ORANGE, Vector3(0, 25, 0))


func _lamp() -> void:
	var r := group(-26.0)
	cyl(r, 0.5, 0.55, 0.12, Vector3(-0.6, 0.06, 0), DARK)
	stick(r, Vector3(-0.6, 0.1, 0), Vector3(-0.3, 1.15, 0), 0.06, GREY)
	ball(r, 0.1, Vector3(-0.3, 1.15, 0), BRASS)
	stick(r, Vector3(-0.3, 1.15, 0), Vector3(0.45, 1.5, 0.05), 0.055, GREY)
	torus(r, 0.62, 0.07, Vector3(0.6, 1.3, 0.12), DARK, Vector3(70, 0, 20))
	var lens := cyl(r, 0.58, 0.58, 0.04, Vector3(0.6, 1.3, 0.12), ICE, Vector3(70, 0, 20), 48, gloss(ICE, 0.15, 0.4, 0.05))
	lens.rotation_degrees = Vector3(70, 0, 20)
	torus(r, 0.52, 0.035, Vector3(0.6, 1.3, 0.12), Color("fff1b8"), Vector3(70, 0, 20), gloss(Color("fff1b8"), 3.0))
	cyl(r, 0.45, 0.45, 0.05, Vector3(0.25, 0.04, 0.55), Color("8a929c"))


func _extinguisher() -> void:
	var r := group(-18.0)
	cyl(r, 0.42, 0.42, 1.3, Vector3(0, 0.7, 0), RED, Vector3.ZERO, 40)
	ball(r, 0.42, Vector3(0, 1.35, 0), RED, Vector3(1.0, 0.55, 1.0))
	cyl(r, 0.43, 0.43, 0.18, Vector3(0, 0.3, 0), DARK, Vector3.ZERO, 40)
	cyl(r, 0.14, 0.14, 0.22, Vector3(0, 1.72, 0), BRASS)
	box(r, Vector3(0.7, 0.09, 0.16), Vector3(0.18, 1.88, 0), DARK, Vector3(0, 0, 8))
	box(r, Vector3(0.5, 0.07, 0.14), Vector3(0.28, 1.68, 0), DARK, Vector3(0, 0, -10))
	torus(r, 0.38, 0.045, Vector3(0.55, 1.2, 0.1), DARK, Vector3(90, 0, 0))
	stick(r, Vector3(0.45, 1.3, 0.05), Vector3(0.85, 0.75, 0.3), 0.045, DARK)
	cyl(r, 0.07, 0.15, 0.25, Vector3(0.95, 0.58, 0.34), DARK, Vector3(0, 0, 30))
	cyl(r, 0.12, 0.12, 0.03, Vector3(-0.2, 1.62, 0.2), WHITE, Vector3(80, 0, 0))
	box(r, Vector3(0.5, 0.45, 0.04), Vector3(0, 0.78, 0.43), WHITE)
	box(r, Vector3(0.36, 0.06, 0.05), Vector3(0, 0.84, 0.455), RED)
	box(r, Vector3(0.06, 0.28, 0.05), Vector3(0, 0.78, 0.455), RED)


func _dryer() -> void:
	var r := group(-22.0)
	box(r, Vector3(1.6, 0.35, 1.2), Vector3(0, 0.18, 0), DARK, Vector3.ZERO, null, 0.06)
	box(r, Vector3(1.5, 0.7, 1.1), Vector3(0, 0.7, 0), ICE, Vector3.ZERO, gloss(ICE, 0.0, 0.32, 0.05), 0.08)
	cyl(r, 0.46, 0.46, 0.62, Vector3(0, 0.62, 0), ORANGE, Vector3(0, 0, 90))
	cyl(r, 0.14, 0.14, 0.66, Vector3(0, 0.62, 0), DARK, Vector3(0, 0, 90))
	for s in [-1.0, 1.0]:
		cyl(r, 0.5, 0.5, 0.03, Vector3(s * 0.33, 0.62, 0), WHITE, Vector3(0, 0, 90))
	box(r, Vector3(0.5, 0.14, 0.04), Vector3(-0.35, 0.18, 0.62), Color("0c1822"))
	label(r, "45C", 12, Vector3(-0.5, 0.15, 0.64), MINT)
	for i in 4:
		box(r, Vector3(0.3, 0.03, 0.04), Vector3(0.45, 0.1 + i * 0.07, 0.62), Color("1b2028"))
	glow(r, 0.05, Vector3(0.7, 0.3, 0.62), GREEN, 3.0)


func _resin() -> void:
	var r := group(-24.0)
	box(r, Vector3(1.5, 0.5, 1.3), Vector3(0, 0.25, 0), DARK, Vector3.ZERO, null, 0.07)
	box(r, Vector3(1.05, 0.14, 0.9), Vector3(0, 0.57, 0), Color("c8d0d8"), Vector3.ZERO, metal_mat(Color("c8d0d8")), 0.03)
	box(r, Vector3(0.9, 0.12, 0.75), Vector3(0, 0.66, 0), ORANGE, Vector3.ZERO, gloss(ORANGE, 0.9, 0.7, 0.05), 0.02)
	stick(r, Vector3(-0.65, 0.5, -0.55), Vector3(-0.65, 1.9, -0.55), 0.06, STEEL)
	box(r, Vector3(0.9, 0.08, 0.5), Vector3(-0.2, 1.2, -0.45), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.02)
	var hood := ball(r, 0.9, Vector3(0, 0.62, 0), YELLOW, Vector3(1.0, 0.95, 0.88))
	hood.material_override = gloss(YELLOW, 0.0, 0.34, 0.05)
	box(r, Vector3(0.5, 0.1, 0.04), Vector3(0, 0.22, 0.66), Color("0c1822"))
	glow(r, 0.045, Vector3(0.55, 0.22, 0.66), PURPLE, 3.0)
	label(r, "UV", 12, Vector3(-0.4, 0.2, 0.68), PURPLE.lightened(0.3))


# -------------------------------------------------------------- equipment

func _bed_shield() -> void:
	var r := group(-18.0)
	cyl(r, 0.95, 0.95, 0.09, Vector3(0, 1.0, 0), ICE, Vector3(90, 0, 0), 64, gloss(ICE, 0.12, 0.45, 0.04))
	torus(r, 0.95, 0.07, Vector3(0, 1.0, 0.0), BRASS, Vector3(90, 0, 0))
	for i in 4:
		var a := deg_to_rad(45.0 + i * 90.0)
		box(r, Vector3(0.22, 0.14, 0.12), Vector3(cos(a) * 0.95, 1.0 + sin(a) * 0.95, 0.03), DARK, Vector3(0, 0, rad_to_deg(a)))
	for i in 8:
		box(r, Vector3(0.012, 0.012, 1.7), Vector3(0, 1.0, 0.06), WHITE.darkened(0.2), Vector3(0, 0, i * 22.5))
	box(r, Vector3(0.45, 0.14, 0.1), Vector3(0, 1.0, 0.12), DARK)


func _lance() -> void:
	var r := group(-10.0)
	var rod := cyl(r, 0.07, 0.07, 3.2, Vector3(0, 1.0, 0), STEEL, Vector3(0, 0, -70), 24, metal_mat(STEEL))
	rod.position = Vector3(0, 1.0, 0)
	var dir := Vector3(cos(deg_to_rad(20.0)), sin(deg_to_rad(20.0)), 0)
	for i in 34:
		var t := -1.5 + i * 0.085
		torus(r, 0.1, 0.022, Vector3(0, 1.0, 0) + dir * t, STEEL, Vector3(0, 0, -70), metal_mat(STEEL.darkened(0.15)))
	cyl(r, 0.16, 0.0, 0.5, Vector3(0, 1.0, 0) + dir * 1.8, STEEL, Vector3(0, 0, -70), 24, metal_mat(STEEL.lightened(0.1)))
	cyl(r, 0.26, 0.26, 0.3, Vector3(0, 1.0, 0) - dir * 0.9, BRASS, Vector3(0, 0, -70), 6, metal_mat(BRASS))
	cyl(r, 0.2, 0.2, 0.4, Vector3(0, 1.0, 0) - dir * 1.5, DARK, Vector3(0, 0, -70), 28)


func _whip() -> void:
	var r := group(-12.0)
	var pts: Array = []
	for i in 22:
		var t := i / 21.0
		pts.append(Vector3(-1.4 + t * 2.8, 0.55 + sin(t * 5.2) * 0.45 + t * 0.4, sin(t * 3.0) * 0.12))
	for i in pts.size() - 1:
		stick(r, pts[i], pts[i + 1], 0.085, WHITE)
	for i in range(1, pts.size() - 1, 3):
		torus(r, 0.1, 0.02, pts[i], Color("c9d3de"), Vector3(0, 0, 90))
	for e in [0, pts.size() - 1]:
		cyl(r, 0.15, 0.15, 0.26, pts[e], BLUE, Vector3(0, 0, 90 if e == 0 else 60), 6)
		cyl(r, 0.1, 0.1, 0.12, pts[e] + Vector3(-0.2 if e == 0 else 0.2, 0, 0), BRASS, Vector3(0, 0, 90))
	box(r, Vector3(0.1, 0.12, 0.1), pts[pts.size() - 1] + Vector3(0.32, 0.1, 0), RED, Vector3(0, 0, 30))


func _crown() -> void:
	var r := group(-12.0)
	torus(r, 0.85, 0.12, Vector3(0, 0.8, 0), BRASS, Vector3.ZERO, metal_mat(BRASS))
	cyl(r, 0.97, 0.97, 0.35, Vector3(0, 0.62, 0), BRASS, Vector3.ZERO, 40, metal_mat(BRASS.darkened(0.1)))
	for i in 5:
		var a := deg_to_rad(i * 72.0 - 18.0)
		var c := Vector3(cos(a) * 0.85, 0.95, sin(a) * 0.85)
		box(r, Vector3(0.24, 0.34, 0.24), c + Vector3(0, 0.2, 0), RED, Vector3(0, -rad_to_deg(a), 0), null, 0.04)
		cyl(r, 0.09, 0.03, 0.35, c + Vector3(0, 0.55, 0), BRASS, Vector3.ZERO, 20, metal_mat(BRASS))
		glow(r, 0.06, c + Vector3(0, 0.76, 0), ORANGE, 3.5)
		ball(r, 0.07, Vector3(cos(a + 0.6) * 0.97, 0.66, sin(a + 0.6) * 0.97), [BLUE, GREEN, PURPLE, YELLOW, TEAL][i])


# -------------------------------------------------------------- creatures
# Each is built around the origin, standing on y = 0, facing +Z. _holder is the
# creature's own root, so the shape helpers add to it.

func _benchy() -> void:
	var c := _beast_root
	var hull := Color("2d86d6")
	var white := Color("f2f4f6")
	var red := Color("e5453a")
	var legs := Color("1d5aa0")
	for s in [-1.0, 1.0]:
		leg(c, Vector3(s * 0.45, 0.32, 0.1), Vector3(s * 0.45, 0.07, 0.15), 0.07, legs)
		leg(c, Vector3(s * 0.45, 0.32, -0.15), Vector3(s * 0.45, 0.07, -0.2), 0.07, legs)
	box(c, Vector3(1.55, 0.4, 0.78), Vector3(-0.1, 0.5, 0), hull, Vector3.ZERO, null, 0.1)
	box(c, Vector3(0.6, 0.4, 0.6), Vector3(0.78, 0.5, 0), hull, Vector3(0, 45, 0), null, 0.1)
	box(c, Vector3(1.7, 0.1, 0.84), Vector3(-0.05, 0.72, 0), white, Vector3.ZERO, null, 0.03)
	box(c, Vector3(0.6, 0.16, 0.6), Vector3(0.78, 0.72, 0), white, Vector3(0, 45, 0), null, 0.03)
	box(c, Vector3(0.62, 0.56, 0.62), Vector3(-0.3, 1.05, 0), red, Vector3.ZERO, null, 0.07)
	box(c, Vector3(0.74, 0.08, 0.72), Vector3(-0.3, 1.36, 0), white, Vector3.ZERO, null, 0.03)
	cyl(c, 0.09, 0.09, 0.4, Vector3(-0.52, 1.6, -0.1), red, Vector3.ZERO, 24)
	cyl(c, 0.115, 0.115, 0.1, Vector3(-0.52, 1.83, -0.1), Color("1c2128"), Vector3.ZERO, 24)
	eyes(c, Vector3(-0.3, 1.08, 0.31), 0.15, 0.13)
	box(c, Vector3(0.3, 0.05, 0.05), Vector3(-0.3, 0.88, 0.33), Color("1c2128"))
	ball(c, 0.11, Vector3(0.38, 0.9, 0.35), white)
	for s in [-1.0, 1.0]:
		ball(c, 0.12, Vector3(-0.3 + s * 0.45, 0.62, 0.4), legs)
	label(c, "3D", 22, Vector3(0.35, 0.5, 0.4), white)


func _spaghetti() -> void:
	var c := _beast_root
	var cols := [Color("ecd35a"), Color("c9e06a"), Color("f0e4a0"), Color("8fcf5a"), Color("e8b84a")]
	ball(c, 0.6, Vector3(0, 0.7, 0), Color("d8c04a"), Vector3(1.0, 0.85, 0.95))
	for i in 46:
		var a := i * 2.399
		var v := Vector3(cos(a) * 0.85, 0.55 + fmod(i * 0.37, 1.0) * 0.8, sin(a) * 0.85)
		strand(c, Vector3(cos(a) * 0.4, 0.55 + fmod(i * 0.37, 1.0) * 0.55, sin(a) * 0.4), v, 0.9 + fmod(i * 0.13, 0.5), cols[i % cols.size()], float(i))
	for i in 7:
		var a := -0.9 + i * 0.3
		strand(c, Vector3(a, 0.4, 0.4), Vector3(a * 0.5, -1.0, 0.8), 0.7, cols[i % cols.size()], float(i) + 50.0, 0.04)
	eyes(c, Vector3(0, 0.82, 0.54), 0.2, 0.2, 0.3)
	ball(c, 0.07, Vector3(0, 0.52, 0.62), Color("a3532b"), Vector3(1.6, 0.8, 0.8))
	for s in [-1.0, 1.0]:
		leg(c, Vector3(s * 0.32, 0.28, 0.1), Vector3(s * 0.4, 0.06, 0.2), 0.07, Color("c9a83a"))


func _crab() -> void:
	var c := _beast_root
	var body := ICE.lerp(Color("5aa8e8"), 0.35)
	box(c, Vector3(0.95, 0.85, 0.85), Vector3(0, 0.78, 0), body, Vector3(0, 0, 0), null, 0.08)
	label(c, "X", 36, Vector3(-0.15, 0.55, 0.43), Color("f4fbff"))
	label(c, "Y", 28, Vector3(0.48, 0.55, 0.0), Color("f4fbff"), Vector3(0, 90, 0))
	for s in [-1.0, 1.0]:
		for k in 3:
			var z := 0.25 - k * 0.28
			var knee := Vector3(s * 0.85, 0.7 - k * 0.04, z)
			stick(c, Vector3(s * 0.45, 0.55, z), knee, 0.055, body.darkened(0.15))
			stick(c, knee, Vector3(s * 1.05, 0.04, z + 0.1), 0.05, body.darkened(0.15))
			ball(c, 0.07, knee, ICE)
		var arm := Vector3(s * 0.85, 1.05, 0.5)
		stick(c, Vector3(s * 0.45, 0.95, 0.35), arm, 0.07, body.darkened(0.1))
		box(c, Vector3(0.32, 0.36, 0.2), arm + Vector3(s * 0.12, 0.2, 0.08), body, Vector3(0, 0, -s * 15), null, 0.05)
		box(c, Vector3(0.1, 0.26, 0.16), arm + Vector3(s * 0.04, 0.45, 0.08), body.darkened(0.1), Vector3(0, 0, -s * 22), null, 0.03)
		stick(c, Vector3(s * 0.2, 1.2, 0.1), Vector3(s * 0.22, 1.5, 0.25), 0.04, body.darkened(0.1))
		eyes_single(c, Vector3(s * 0.22, 1.55, 0.27), 0.12)
	box(c, Vector3(0.36, 0.06, 0.04), Vector3(0.0, 0.84, 0.44), Color("17212c"), Vector3(0, 0, 0))


func eyes_single(p: Node3D, pos: Vector3, r: float) -> void:
	ball(p, r, pos, WHITE)
	ball(p, r * 0.55, pos + Vector3(0, -r * 0.05, r * 0.78), Color("10151c"))
	ball(p, r * 0.18, pos + Vector3(r * 0.18, r * 0.2, r * 1.2), WHITE)


func _shifter() -> void:
	var c := _beast_root
	var n := 12
	for i in n:
		var t := i / float(n - 1)
		var col := VIOLET.lerp(PINKISH, t)
		var w := 0.95 - 0.35 * absf(t - 0.4)
		box(c, Vector3(w, 0.105, 0.74), Vector3(sin(i * 1.45) * 0.2, 0.36 + i * 0.105, 0), col, Vector3.ZERO, mat(col, 0.02), 0.025)
	glow(c, 0.5, Vector3(0, 0.2, 0.0), VIOLET, 1.4).scale = Vector3(1.2, 0.1, 1.0)
	var top := 0.36 + 8 * 0.105
	eyes(c, Vector3(sin(8 * 1.45) * 0.2 - 0.15, top, 0.38), 0.17, 0.12, 0.2)
	box(c, Vector3(0.22, 0.04, 0.04), Vector3(sin(8 * 1.45) * 0.2 - 0.15, top - 0.2, 0.39), Color("1c1430"))
	for s in [-1.0, 1.0]:
		var y := 0.36 + 5 * 0.105
		stick(c, Vector3(s * 0.45 + sin(5 * 1.45) * 0.2, y, 0.1), Vector3(s * 0.8, y - 0.1, 0.3), 0.07, VIOLET.lerp(PINKISH, 0.4))
		ball(c, 0.11, Vector3(s * 0.82, y - 0.12, 0.32), VIOLET.lerp(PINKISH, 0.4))
	for i in 5:
		glow(c, 0.04, Vector3(-0.6 + i * 0.3, 0.1 + fmod(i * 0.37, 0.3), 0.3 + fmod(i * 0.21, 0.3)), PINKISH.lightened(0.3), 3.0)


func _golem() -> void:
	var c := _beast_root
	var body := SLATE
	for s in [-1.0, 1.0]:
		box(c, Vector3(0.38, 0.4, 0.45), Vector3(s * 0.3, 0.22, 0.0), body.darkened(0.15), Vector3.ZERO, null, 0.06)
		stick(c, Vector3(s * 0.62, 1.25, 0.0), Vector3(s * 0.95, 0.82, 0.18), 0.12, body)
		ball(c, 0.22, Vector3(s * 0.98, 0.7, 0.2), body.lightened(0.1))
		ball(c, 0.2, Vector3(s * 0.65, 1.28, 0.0), COPPER, Vector3(1.0, 1.0, 1.0))
	box(c, Vector3(1.05, 0.95, 0.85), Vector3(0, 0.95, 0), body, Vector3.ZERO, null, 0.08)
	box(c, Vector3(0.95, 0.12, 0.8), Vector3(0, 1.46, 0.0), Color("2b3038"), Vector3.ZERO, null, 0.04)
	cyl(c, 0.24, 0.24, 0.3, Vector3(0, 1.65, 0.0), STEEL, Vector3.ZERO, 36, metal_mat(STEEL))
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			cyl(c, 0.055, 0.055, 0.05, Vector3(sx * 0.4, 0.95 + sy * 0.38, 0.44), BRASS, Vector3(90, 0, 0), 6, metal_mat(BRASS))
	box(c, Vector3(0.7, 0.34, 0.06), Vector3(0, 1.05, 0.44), Color("1c2128"), Vector3.ZERO, null, 0.02)
	eyes(c, Vector3(0, 1.06, 0.5), 0.2, 0.12, 0.0)
	box(c, Vector3(0.4, 0.05, 0.05), Vector3(0, 0.78, 0.45), COPPER)
	box(c, Vector3(0.7, 0.03, 0.03), Vector3(0, 0.5, 0.43), COPPER)
	torus(c, 0.34, 0.04, Vector3(0.0, 0.62, -0.5), COPPER, Vector3(0, 0, 0))
	glow(c, 0.06, Vector3(0.0, 1.66, 0.0), ORANGE, 2.5)


func _cobra() -> void:
	var c := _beast_root
	var cu := COPPER
	for i in 6:
		var rr := 0.62 - i * 0.045
		torus(c, rr, 0.12, Vector3(0, 0.12 + i * 0.2, 0), cu.lerp(YELLOW, i * 0.06), Vector3.ZERO, mat(cu.lerp(YELLOW, i * 0.06), 0.03, Vector3.UP, 0.25, 0.4))
	cyl(c, 0.34, 0.34, 0.9, Vector3(0, 0.6, 0), Color("a95a2b"), Vector3.ZERO, 32)
	var pts: Array = []
	for i in 9:
		var t := i / 8.0
		pts.append(Vector3(sin(t * 2.4) * 0.28, 1.15 + t * 0.75, 0.1 + t * 0.2 - sin(t * 3.0) * 0.1))
	for i in pts.size() - 1:
		stick(c, pts[i], pts[i + 1], 0.17 - i * 0.008, cu)
		ball(c, 0.17 - i * 0.008, pts[i], cu)
	var head: Vector3 = pts[pts.size() - 1]
	ball(c, 0.28, head + Vector3(0, 0.05, 0.12), cu.lightened(0.1), Vector3(1.1, 0.85, 1.25))
	for s in [-1.0, 1.0]:
		cyl(c, 0.3, 0.3, 0.05, head + Vector3(s * 0.28, -0.12, -0.05), YELLOW, Vector3(0, 0, 90 + s * 20), 24, null)
		glow(c, 0.1, head + Vector3(s * 0.17, 0.14, 0.34), YELLOW.lightened(0.4), 2.2)
		ball(c, 0.045, head + Vector3(s * 0.17, 0.14, 0.43), Color("10151c"))
	stick(c, head + Vector3(0, -0.03, 0.36), head + Vector3(0, -0.12, 0.62), 0.018, Color("4fc8ff"))
	for s in [-1.0, 1.0]:
		stick(c, head + Vector3(0, -0.12, 0.62), head + Vector3(s * 0.08, -0.1, 0.74), 0.014, Color("4fc8ff"))
	for i in 6:
		glow(c, 0.035, Vector3(cos(i * 1.1) * 0.8, 0.5 + fmod(i * 0.43, 0.9), sin(i * 1.3) * 0.5 + 0.2), Color("7fe3ff"), 3.5)


func _goblin() -> void:
	var c := _beast_root
	var skin := Color("e8661f")
	ball(c, 0.38, Vector3(0, 0.55, 0), skin, Vector3(1.0, 1.1, 0.9))
	for s in [-1.0, 1.0]:
		leg(c, Vector3(s * 0.2, 0.3, 0.05), Vector3(s * 0.24, 0.06, 0.18), 0.07, skin.darkened(0.2))
		stick(c, Vector3(s * 0.32, 0.65, 0.05), Vector3(s * 0.62, 0.45, 0.2), 0.07, skin.darkened(0.1))
		ball(c, 0.1, Vector3(s * 0.64, 0.43, 0.22), skin.lightened(0.1))
		cyl(c, 0.14, 0.0, 0.5, Vector3(s * 0.62, 1.4, -0.05), skin, Vector3(0, 0, -s * 70), 4)
	box(c, Vector3(0.82, 0.55, 0.72), Vector3(0, 1.12, 0), RED.darkened(0.1), Vector3.ZERO, null, 0.09)
	for i in 5:
		box(c, Vector3(0.82, 0.04, 0.74), Vector3(0, 0.95 + i * 0.1, 0), RED.lightened(0.15))
	cyl(c, 0.32, 0.1, 0.34, Vector3(0, 0.78, 0.46), BRASS, Vector3(80, 0, 0), 28, metal_mat(BRASS))
	cyl(c, 0.1, 0.03, 0.14, Vector3(0, 0.62, 0.66), BRASS, Vector3(80, 0, 0), 20, metal_mat(BRASS))
	glow(c, 0.06, Vector3(0, 0.6, 0.72), Color("ffb347"), 4.0)
	eyes(c, Vector3(0, 1.18, 0.37), 0.2, 0.13, -0.2)
	for s in [-1.0, 1.0]:
		box(c, Vector3(0.28, 0.05, 0.05), Vector3(s * 0.2, 1.35, 0.4), Color("1c1010"), Vector3(0, 0, s * -20))
	for i in 4:
		ball(c, 0.12 + i * 0.03, Vector3(-0.05 + i * 0.1, 1.75 + i * 0.22, -0.05), Color("2a2c33").lightened(i * 0.06), Vector3(1.0, 0.8, 1.0))
	box(c, Vector3(0.4, 0.06, 0.04), Vector3(0, 0.98, 0.37), Color("1c1010"))


func _mantis() -> void:
	var c := _beast_root
	var g := Color("49c6a8")
	var w := Color("f2f6f8")
	for s in [-1.0, 1.0]:
		var hip := Vector3(s * 0.22, 0.7, -0.2)
		var knee := Vector3(s * 0.55, 0.85, -0.35)
		var foot := Vector3(s * 0.7, 0.04, -0.2)
		stick(c, hip, knee, 0.055, g.darkened(0.2))
		stick(c, knee, foot, 0.05, g.darkened(0.2))
		ball(c, 0.07, knee, g)
		ball(c, 0.09, foot, g.darkened(0.2), Vector3(1.2, 0.5, 1.5))
		var hip2 := Vector3(s * 0.2, 0.62, 0.15)
		stick(c, hip2, Vector3(s * 0.52, 0.5, 0.45), 0.05, g.darkened(0.2))
		stick(c, Vector3(s * 0.52, 0.5, 0.45), Vector3(s * 0.62, 0.04, 0.5), 0.045, g.darkened(0.2))
		# Raised forearms: rails with a nozzle for a claw.
		var sh := Vector3(s * 0.3, 1.35, 0.15)
		var el := Vector3(s * 0.62, 1.45, 0.45)
		stick(c, sh, el, 0.07, w)
		box(c, Vector3(0.1, 0.62, 0.1), el + Vector3(s * 0.05, 0.28, 0.1), w, Vector3(0, 0, s * 12), null, 0.02)
		var top := el + Vector3(-s * 0.014, 0.58, 0.1)
		cyl(c, 0.075, 0.0, 0.28, top + Vector3(-s * 0.03, 0.12, 0.0), BRASS, Vector3(0, 0, s * 12), 16, metal_mat(BRASS))
		glow(c, 0.04, top + Vector3(-s * 0.06, 0.28, 0.0), ORANGE, 3.0)
		box(c, Vector3(0.5, 0.02, 0.9), Vector3(s * 0.45, 1.25, -0.5), Color("bfe9f3"), Vector3(0, s * 12, s * 10), gloss(Color("bfe9f3"), 0.0, 0.4, 0.05), 0.0)
	ball(c, 0.28, Vector3(0, 0.75, -0.15), g, Vector3(0.8, 0.8, 1.45))
	box(c, Vector3(0.42, 0.55, 0.38), Vector3(0, 1.25, 0.05), g, Vector3(10, 0, 0), null, 0.08)
	box(c, Vector3(0.5, 0.06, 0.44), Vector3(0, 1.22, 0.05), w, Vector3(10, 0, 0), null, 0.02)
	ball(c, 0.3, Vector3(0, 1.82, 0.32), g.lightened(0.08), Vector3(1.15, 0.85, 0.95))
	eyes(c, Vector3(0, 1.86, 0.52), 0.22, 0.16, 0.0)
	for s in [-1.0, 1.0]:
		stick(c, Vector3(s * 0.12, 2.05, 0.4), Vector3(s * 0.3, 2.4, 0.3), 0.02, w)
		ball(c, 0.04, Vector3(s * 0.3, 2.4, 0.3), YELLOW)


func _hydra() -> void:
	var c := _beast_root
	var body := Color("d6452a")
	var belly := Color("f0a050")
	torus(c, 0.78, 0.2, Vector3(0, 0.95, -0.55), Color("2f8cf0"), Vector3(90, 0, 0), mat(Color("2f8cf0"), 0.03, Vector3.UP, 0.3, 0.5))
	cyl(c, 0.2, 0.2, 0.3, Vector3(0, 0.95, -0.55), Color("e8edf2"), Vector3(90, 0, 0))
	ball(c, 0.62, Vector3(0, 0.62, 0.05), body, Vector3(1.2, 0.95, 1.0))
	ball(c, 0.42, Vector3(0, 0.56, 0.4), belly, Vector3(1.1, 0.9, 0.5))
	for s in [-1.0, 1.0]:
		leg(c, Vector3(s * 0.5, 0.45, 0.1), Vector3(s * 0.58, 0.07, 0.3), 0.12, body.darkened(0.15))
		leg(c, Vector3(s * 0.45, 0.45, -0.25), Vector3(s * 0.55, 0.07, -0.25), 0.1, body.darkened(0.15))
	var heads := [Vector3(-0.7, 1.9, 0.35), Vector3(0.0, 2.2, 0.45), Vector3(0.7, 1.9, 0.35)]
	for i in 3:
		var hp: Vector3 = heads[i]
		var from := Vector3((i - 1) * 0.3, 0.95, 0.1)
		var mid := Vector3(hp.x * 0.5 + (i - 1) * 0.15, 1.45, 0.05)
		stick(c, from, mid, 0.16, body)
		stick(c, mid, hp, 0.14, body)
		ball(c, 0.16, mid, body)
		ball(c, 0.27, hp + Vector3(0, 0, 0.05), body.lightened(0.05), Vector3(1.1, 0.9, 1.1))
		cyl(c, 0.17, 0.07, 0.28, hp + Vector3(0, -0.12, 0.34), BRASS, Vector3(85, 0, 0), 20, metal_mat(BRASS))
		glow(c, 0.045, hp + Vector3(0, -0.14, 0.5), Color("ffb347"), 4.0)
		eyes(c, hp + Vector3(0, 0.1, 0.22), 0.13, 0.085, 0.1)
		for s in [-1.0, 1.0]:
			cyl(c, 0.07, 0.0, 0.26, hp + Vector3(s * 0.2, 0.28, -0.05), belly, Vector3(0, 0, -s * 25), 4)
	for i in 5:
		glow(c, 0.045, Vector3(-0.5 + i * 0.25, 0.4 + fmod(i * 0.37, 0.7), -0.2), ORANGE, 2.5)


## Cutie: a wheel-shaped print with eyes on stalks. Built from the maker's own
## printed figure: a solid disc whose face has a hub with a hole and five
## dimples, ribbed pockets and a rim, hollow square trays around the edge, and a
## chunky eye bar on top with two black stalks and flat round eyes.
func _roto() -> void:
	var c := _beast_root
	var white := Color("f1f2f4")
	var shade := Color("d9dce1")
	var dark := Color("1a1d22")
	var cy := 1.0
	var R := 0.78
	var lm := mat(white, 0.03, Vector3(0, 0, 1), 0.42, 0.5)
	# The disc: back plate, outer rim and the raised hub.
	cyl(c, R, R, 0.16, Vector3(0, cy, -0.06), white, Vector3(90, 0, 0), 48, lm)
	torus(c, R - 0.05, 0.12, Vector3(0, cy, 0.04), white, Vector3(90, 0, 0), lm)
	cyl(c, 0.3, 0.3, 0.32, Vector3(0, cy, 0.04), white, Vector3(90, 0, 0), 40, lm)
	cyl(c, 0.08, 0.08, 0.34, Vector3(0, cy, 0.05), dark, Vector3(90, 0, 0), 20)
	for i in 5:
		var a := i * TAU / 5.0 + 0.3
		cyl(c, 0.045, 0.045, 0.02, Vector3(cos(a) * 0.19, cy + sin(a) * 0.19, 0.21), shade, Vector3(90, 0, 0), 14)
	# Ribs between the hub and the rim make the pockets.
	for i in 8:
		var a := i * TAU / 8.0 + 0.2
		var mid := Vector3(cos(a), sin(a), 0) * 0.5
		box(c, Vector3(0.3, 0.07, 0.2), Vector3(0, cy, 0.0) + mid + Vector3(0, 0, 0.0), white, Vector3(0, 0, rad_to_deg(a)), lm, 0.02)
		box(c, Vector3(0.08, 0.1, 0.07), Vector3(0, cy, 0.0) + Vector3(cos(a + 0.4), sin(a + 0.4), 0) * 0.5 + Vector3(0, 0, 0.0), shade, Vector3(0, 0, rad_to_deg(a)), lm, 0.02)
	# Hollow square trays around the edge, each hung a little differently.
	for i in 8:
		var deg := i * 45.0 + 22.5
		if absf(deg - 90.0) < 30.0:
			continue
		var a := deg_to_rad(deg)
		var node := Node3D.new()
		var wob := float((i * 37) % 17 - 8)
		_place(c, node, Vector3(cos(a), sin(a) + cy / (R + 0.2), 0) * 0.0 + Vector3(cos(a) * (R + 0.2), cy + sin(a) * (R + 0.2), 0.0 + (i % 2) * 0.04), Vector3(wob * 0.5, 0, deg - 90.0 + wob))
		box(node, Vector3(0.4, 0.38, 0.05), Vector3(0, 0, -0.04), white, Vector3.ZERO, lm, 0.015)
		box(node, Vector3(0.05, 0.38, 0.17), Vector3(-0.175, 0, 0.04), white, Vector3.ZERO, lm, 0.015)
		box(node, Vector3(0.05, 0.38, 0.17), Vector3(0.175, 0, 0.04), white, Vector3.ZERO, lm, 0.015)
		box(node, Vector3(0.4, 0.05, 0.17), Vector3(0, -0.165, 0.04), white, Vector3.ZERO, lm, 0.015)
		box(node, Vector3(0.4, 0.05, 0.17), Vector3(0, 0.165, 0.04), white, Vector3.ZERO, lm, 0.015)
		# A black tread on the far side of each tray.
		box(node, Vector3(0.3, 0.1, 0.05), Vector3(0, 0.0, -0.1), dark, Vector3.ZERO, null, 0.01)
	# The eye bar: a chunky tile on top of the rim.
	box(c, Vector3(0.34, 0.22, 0.3), Vector3(0, cy + R + 0.06, -0.02), white, Vector3.ZERO, lm, 0.04)
	box(c, Vector3(1.25, 0.3, 0.38), Vector3(0, cy + R + 0.25, -0.02), white, Vector3.ZERO, lm, 0.13)
	for sx in [-1.0, 1.0]:
		var base := Vector3(sx * 0.4, cy + R + 0.39, -0.02)
		cyl(c, 0.09, 0.09, 0.36, base + Vector3(0, 0.18, 0.0), dark, Vector3.ZERO, 24)
		var top := base + Vector3(0, 0.4, 0.0)
		var tilt := Vector3(48, 0, 0)
		var n := Vector3(0, cos(deg_to_rad(48.0)), sin(deg_to_rad(48.0)))
		cyl(c, 0.27, 0.27, 0.14, top, white, tilt, 40, lm)
		cyl(c, 0.22, 0.22, 0.03, top + n * 0.08, Color("9fd4ee"), tilt, 40)
		cyl(c, 0.185, 0.185, 0.04, top + n * 0.095, dark, tilt, 40)
		ball(c, 0.042, top + n * 0.12 + Vector3(sx * 0.05, 0.07, 0.0), WHITE)
