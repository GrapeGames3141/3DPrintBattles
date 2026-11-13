extends "res://tools/render_art.gd"
## Renders the second wave of card art: ten tools (on the print bed, like the
## first set) and six pieces of equipment (cut out on a transparent
## background, like the armor that came before them).
##
##   godot --path . --disable-vsync -s tools/render_art2.gd              (all)
##   godot --path . --disable-vsync -s tools/render_art2.gd -- crown      (just some)

const ARMOR_OUT := "res://assets/armor/raw/%s_raw_print_alpha_v2.png"


func _initialize() -> void:
	var only: Array = Array(OS.get_cmdline_user_args())
	await process_frame
	_build_studio()
	await process_frame
	var tools := {
		"glue_gun": [_glue_gun, 34.0, 4.9, 0.55],
		"soldering_iron": [_soldering_iron, 40.0, 5.0, 0.3],
		"tweezers": [_tweezers, 52.0, 4.8, 0.1],
		"safety_goggles": [_goggles, 20.0, 5.6, 0.7],
		"filament_dryer": [_dryer, 28.0, 5.2, 0.55],
		"z_offset": [_feeler, 52.0, 4.6, 0.1],
		"spaghetti": [_spaghetti, 34.0, 4.8, 0.45],
		"power_outage": [_plug, 36.0, 5.0, 0.4],
		"backup_spool": [_backup_spool, 26.0, 5.6, 0.9],
		"master_blueprint": [_blueprint, 40.0, 5.0, 0.35],
	}
	var gear := {
		"spike_collar": [_collar, 42.0, 5.4, 0.45],
		"spare_plating": [_plating, 12.0, 5.4, 0.9],
		"wing_kit": [_wings, 14.0, 5.6, 1.1],
		"scale_mail": [_scales, 12.0, 6.8, 0.9],
		"jet_pack": [_jetpack, 14.0, 6.9, 0.75],
		"crown": [_crown, 20.0, 5.0, 0.65],
	}
	for id in tools:
		if only.is_empty() or only.has(id):
			var job: Array = tools[id]
			await _shoot(id, job[0], job[1], job[2], job[3])
	vp.size = Vector2i(512, 512)
	vp.transparent_bg = true
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.glow_enabled = false
	plate.visible = false
	for id in gear:
		if only.is_empty() or only.has(id):
			var job: Array = gear[id]
			_clear()
			job[0].call()
			_aim(job[1], job[2], job[3])
			await _settle()
			vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(ARMOR_OUT % id))
			print("rendered ", id)
	quit()


# ------------------------------------------------------------------ tools

func _glue_gun() -> void:
	var r := group(-32.0)
	box(r, Vector3(1.35, 0.62, 0.56), Vector3(0.0, 0.98, 0), YELLOW, Vector3.ZERO, null, 0.14)
	box(r, Vector3(1.37, 0.1, 0.58), Vector3(-0.05, 1.0, 0), RED, Vector3.ZERO, null, 0.04)
	for i in 4:
		box(r, Vector3(0.07, 0.04, 0.34), Vector3(-0.35 + i * 0.16, 1.3, 0), DARK, Vector3.ZERO, null, 0.015)
	box(r, Vector3(0.46, 1.0, 0.42), Vector3(-0.38, 0.42, 0), DARK, Vector3(0, 0, -12), null, 0.12)
	for i in 3:
		box(r, Vector3(0.5, 0.05, 0.44), Vector3(-0.31 - i * 0.04, 0.45 - i * 0.2, 0), GREY, Vector3(0, 0, -12), null, 0.02)
	box(r, Vector3(0.14, 0.32, 0.12), Vector3(0.02, 0.66, 0.0), RED, Vector3(0, 0, 18), null, 0.05)
	cyl(r, 0.22, 0.22, 0.46, Vector3(0.9, 0.98, 0), GREY, Vector3(0, 0, -90), 32)
	cyl(r, 0.25, 0.25, 0.08, Vector3(0.66, 0.98, 0), DARK, Vector3(0, 0, -90), 32)
	cyl(r, 0.13, 0.04, 0.36, Vector3(1.28, 0.98, 0), BRASS, Vector3(0, 0, -90), 32)
	var drop := ball(r, 0.1, Vector3(1.5, 0.92, 0), Color("fff2c8"), Vector3(0.9, 1.3, 0.9))
	drop.material_override = gloss(Color("ffd9a0"), 1.2)
	cyl(r, 0.11, 0.11, 1.15, Vector3(-1.1, 1.0, 0), WHITE, Vector3(0, 0, 90), 24)
	stick(r, Vector3(-0.6, 0.0, 0.0), Vector3(-1.6, 0.12, -0.5), 0.07, DARK)
	var puddle := ball(_holder, 0.3, Vector3(1.0, 0.03, 0.9), WHITE, Vector3(1.4, 0.18, 1.0))
	puddle.material_override = gloss(Color("ffe9c4"), 0.0, 1.0, 0.25)


func _soldering_iron() -> void:
	var r := group(-38.0)
	cyl(r, 0.18, 0.18, 1.5, Vector3(-0.55, 0.32, 0), DARK, Vector3(0, 0, 90), 32)
	for i in 5:
		torus(r, 0.185, 0.03, Vector3(-1.05 + i * 0.2, 0.32, 0), Color("4a5260"), Vector3(0, 0, 90))
	cyl(r, 0.22, 0.22, 0.3, Vector3(0.28, 0.32, 0), RED, Vector3(0, 0, 90), 32)
	cyl(r, 0.1, 0.1, 0.9, Vector3(0.9, 0.32, 0), GREY, Vector3(0, 0, 90), 24)
	cyl(r, 0.09, 0.02, 0.42, Vector3(1.55, 0.32, 0), BRASS, Vector3(0, 0, -90), 24)
	var glow := ball(r, 0.05, Vector3(1.78, 0.32, 0), ORANGE)
	glow.material_override = gloss(Color("ff9a3c"), 2.5)
	# the stand: a heavy base with a spring cradle
	box(r, Vector3(1.3, 0.12, 0.7), Vector3(0.1, 0.06, -0.85), DARK, Vector3.ZERO, null, 0.05)
	for i in 8:
		torus(r, 0.24, 0.04, Vector3(-0.35 + i * 0.16, 0.34, -0.85), GREY, Vector3(0, 0, 90))
	box(r, Vector3(0.3, 0.3, 0.5), Vector3(0.55, 0.27, -0.85), DARK, Vector3.ZERO, null, 0.06)
	# a brass-wool tip cleaner and a little roll of solder
	cyl(r, 0.2, 0.2, 0.14, Vector3(0.6, 0.07, 0.6), BRASS, Vector3.ZERO, 24)
	for i in 5:
		torus(r, 0.15, 0.035, Vector3(-0.2, 0.05 + i * 0.05, 0.75), Color("d6dbe2"), Vector3(0, 0, 0))


func _tweezers() -> void:
	var r := group(-24.0)
	for s in [-1.0, 1.0]:
		box(r, Vector3(2.1, 0.07, 0.2), Vector3(0.05, 0.07, s * 0.12), GREY, Vector3(0, -s * 3.0, 0), null, 0.03)
		for i in 5:
			box(r, Vector3(0.05, 0.075, 0.2), Vector3(-0.6 - i * 0.12, 0.075, s * (0.12 + 0.012 * i)), Color("7e8793"), Vector3(0, -s * 3.0, 0), null, 0.01)
		box(r, Vector3(0.34, 0.06, 0.07), Vector3(1.05, 0.06, s * 0.035), DARK, Vector3(0, -s * 3.0, 0), null, 0.02)
	box(r, Vector3(0.34, 0.12, 0.5), Vector3(-1.1, 0.08, 0), BLUE, Vector3.ZERO, null, 0.05)
	box(r, Vector3(0.18, 0.13, 0.52), Vector3(-1.1, 0.085, 0), Color("1f5fb8"), Vector3.ZERO, null, 0.03)
	# gripping a tiny print
	box(r, Vector3(0.16, 0.16, 0.16), Vector3(1.3, 0.1, 0.0), ORANGE, Vector3(0, 22, 0), null, 0.02)


func _goggles() -> void:
	var r := group(-12.0)
	for s in [-1.0, 1.0]:
		var lens := cyl(r, 0.45, 0.45, 0.07, Vector3(s * 0.6, 0.64, 0.0), Color("9fd8ff"), Vector3(90, 0, 0), 48)
		lens.material_override = gloss(Color("a8dcff"), 0.0, 0.55, 0.04)
		torus(r, 0.47, 0.1, Vector3(s * 0.6, 0.64, 0), ORANGE, Vector3(90, 0, 0))
		torus(r, 0.38, 0.025, Vector3(s * 0.6, 0.64, 0.04), WHITE, Vector3(90, 0, 0))
		for i in 3:
			cyl(r, 0.035, 0.035, 0.12, Vector3(s * (1.07 + i * 0.0), 0.5 + i * 0.12, 0.0), DARK, Vector3(0, 0, 90), 12)
	box(r, Vector3(0.34, 0.16, 0.14), Vector3(0, 0.68, 0), ORANGE, Vector3.ZERO, null, 0.06)
	torus(r, 1.1, 0.07, Vector3(0, 0.64, -0.2), DARK, Vector3(90, 0, 0))
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.5, 0.2, 0.1), Vector3(s * 1.08, 0.64, -0.02), DARK, Vector3(0, -s * 80, 0), null, 0.04)
	box(r, Vector3(0.22, 0.22, 0.12), Vector3(1.4, 0.64, -0.22), BRASS, Vector3(0, 70, 0), null, 0.04)


func _dryer() -> void:
	var r := group(-26.0)
	box(r, Vector3(1.8, 0.7, 1.35), Vector3(0, 0.35, 0), WHITE, Vector3.ZERO, null, 0.16)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			cyl(r, 0.09, 0.09, 0.08, Vector3(sx * 0.7, 0.02, sz * 0.5), DARK, Vector3.ZERO, 16)
	cyl(r, 0.74, 0.74, 0.12, Vector3(0, 0.74, 0), ORANGE, Vector3.ZERO, 48)
	# a spool inside a glass dome
	var axis: Vector3 = (r.global_transform.basis * Vector3.RIGHT).normalized()
	cyl(r, 0.4, 0.4, 0.32, Vector3(0, 1.0, 0), TEAL, Vector3(0, 0, 0), 40, mat(TEAL, 0.03, axis, 0.3, 0.8))
	cyl(r, 0.12, 0.12, 0.36, Vector3(0, 1.0, 0), GREY, Vector3.ZERO, 16)
	for k in [-1.0, 1.0]:
		cyl(r, 0.5, 0.5, 0.04, Vector3(0, 1.0 + k * 0.17, 0), DARK, Vector3.ZERO, 40)
	var dome := ball(r, 0.72, Vector3(0, 0.78, 0), WHITE)
	dome.material_override = gloss(Color("dff4ff"), 0.0, 0.28, 0.03)
	box(r, Vector3(0.62, 0.24, 0.05), Vector3(0.4, 0.34, 0.68), DARK, Vector3.ZERO, null, 0.02)
	var leds := [Color("5cff7a"), Color("ffb02e"), Color("ff4a3a")]
	for i in 3:
		var led := ball(r, 0.04, Vector3(0.22 + i * 0.18, 0.36, 0.72), leds[i])
		led.material_override = gloss(leds[i], 2.5 if i == 0 else 0.5)
	cyl(r, 0.1, 0.1, 0.12, Vector3(-0.5, 0.4, 0.7), ORANGE, Vector3(90, 0, 0), 20)
	stick(r, Vector3(-0.9, 0.25, -0.5), Vector3(-1.6, 0.06, -0.9), 0.06, DARK)


func _feeler() -> void:
	var r := group(-8.0)
	var cols := [GREY, BLUE, TEAL, GREEN, YELLOW, ORANGE, RED]
	for i in cols.size():
		var a := i * 11.0 - 30.0
		var leaf := box(r, Vector3(1.9, 0.034, 0.27), Vector3(0.45, 0.06 + i * 0.042, 0), cols[i], Vector3(0, a, 0), null, 0.012)
		leaf.position = Vector3(-0.45, 0.06 + i * 0.042, 0) + Vector3(cos(deg_to_rad(a)), 0, -sin(deg_to_rad(a))) * 0.95
	cyl(r, 0.16, 0.16, 0.42, Vector3(-0.45, 0.2, 0), BRASS, Vector3.ZERO, 28)
	cyl(r, 0.2, 0.2, 0.06, Vector3(-0.45, 0.4, 0), GREY, Vector3.ZERO, 6)
	cyl(r, 0.06, 0.06, 0.08, Vector3(-0.45, 0.44, 0), DARK, Vector3.ZERO, 12)


func _spaghetti() -> void:
	var r := group(0.0)
	box(r, Vector3(1.6, 0.1, 1.4), Vector3(0, 0.05, 0), DARK, Vector3.ZERO, null, 0.04)
	box(r, Vector3(0.6, 0.5, 0.5), Vector3(-0.45, 0.35, -0.3), ORANGE, Vector3(0, 20, 12), null, 0.05)
	var cols := [ORANGE, ORANGE, YELLOW]
	for i in 30:
		var a := i * 2.399
		var c: Color = cols[i % 3]
		var radius := 0.2 + 0.2 * fmod(i * 0.37, 1.0)
		torus(r, radius, 0.05, Vector3(sin(a) * 0.36, 0.16 + (i % 10) * 0.07, cos(a * 1.3) * 0.3), c, Vector3(sin(a * 1.7) * 70.0, a * 40.0, cos(a) * 70.0), mat(c, 0.02, Vector3.UP, 0.3, 0.3))
	for i in 6:
		var a := i * 1.3
		stick(r, Vector3(sin(a) * 0.5, 0.2, cos(a) * 0.4), Vector3(sin(a + 2.0) * 0.9, 0.9 + i * 0.1, cos(a + 1.0) * 0.6), 0.045, cols[i % 3])


func _plug() -> void:
	var r := group(-30.0)
	box(r, Vector3(0.95, 0.72, 0.8), Vector3(0, 0.55, 0), DARK, Vector3.ZERO, null, 0.14)
	box(r, Vector3(0.7, 0.5, 0.3), Vector3(0, 0.6, 0.42), RED, Vector3.ZERO, null, 0.08)
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.1, 0.36, 0.55), Vector3(s * 0.22, 0.58, 0.9), BRASS, Vector3.ZERO, null, 0.03)
	cyl(r, 0.16, 0.16, 0.6, Vector3(0, 0.55, -0.6), DARK, Vector3(90, 0, 0), 24)
	for i in 8:
		var t := i / 7.0
		var a := Vector3(-0.1 - t * 1.3, 0.2 + sin(t * 3.0) * 0.14, -0.8 - t * 0.7)
		var b := Vector3(-0.1 - (t + 0.14) * 1.3, 0.2 + sin((t + 0.14) * 3.0) * 0.14, -0.8 - (t + 0.14) * 0.7)
		stick(r, a, b, 0.075, DARK)
	# a bolt of lightning leaping off the prongs
	var bolt := [Vector3(0.1, 1.5, 1.15), Vector3(-0.2, 1.1, 1.3), Vector3(0.0, 1.05, 1.3), Vector3(-0.3, 0.55, 1.45)]
	for i in 3:
		var seg := stick(r, bolt[i], bolt[i + 1], 0.06, YELLOW)
		seg.material_override = gloss(Color("ffe45a"), 3.0)
	for i in 6:
		var a := i * 1.05
		var sp := ball(r, 0.035, Vector3(sin(a) * 0.55, 0.8 + cos(a) * 0.4, 1.25 + 0.1 * sin(a * 2.0)), YELLOW)
		sp.material_override = gloss(Color("fff08a"), 3.0)


func _backup_spool() -> void:
	for k in 2:
		var r := group(62.0 - k * 50.0, Vector3(-0.55 + k * 1.15, 0, -0.1 * k))
		var s := 1.0 - 0.28 * k
		var col: Color = TEAL if k == 0 else BLUE
		var axis: Vector3 = (r.global_transform.basis * Vector3.BACK).normalized()
		var rx := Vector3(90, 0, 0)
		for side in [-1.0, 1.0]:
			cyl(r, 0.9 * s, 0.9 * s, 0.06, Vector3(0, 0.95 * s, side * 0.31 * s), DARK, rx, 64)
			torus(r, 0.88 * s, 0.035 * s, Vector3(0, 0.95 * s, side * 0.31 * s), Color("4a5260"), rx)
			for h in 5:
				var a := h * TAU / 5.0
				cyl(r, 0.11 * s, 0.11 * s, 0.07, Vector3(sin(a) * 0.5 * s, 0.95 * s + cos(a) * 0.5 * s, side * 0.31 * s), Color("0b0e14"), rx, 20)
		cyl(r, 0.74 * s, 0.74 * s, 0.55 * s, Vector3(0, 0.95 * s, 0), col, rx, 64, mat(col, 0.03, axis, 0.3, 0.8))
		cyl(r, 0.24 * s, 0.24 * s, 0.72 * s, Vector3(0, 0.95 * s, 0), GREY, rx)
	box(_holder, Vector3(0.7, 0.03, 0.18), Vector3(0.1, 0.02, 0.9), YELLOW, Vector3(0, 12, 0))


func _blueprint() -> void:
	var r := group(-20.0)
	box(r, Vector3(2.0, 0.05, 1.3), Vector3(0.0, 0.03, 0.1), BLUE, Vector3.ZERO, null, 0.02)
	for i in 6:
		box(r, Vector3(2.0, 0.052, 0.025), Vector3(0.0, 0.032, -0.4 + i * 0.2), Color("8fc4ff"), Vector3.ZERO, null, 0.0)
	for i in 9:
		box(r, Vector3(0.025, 0.052, 1.3), Vector3(-0.9 + i * 0.225, 0.032, 0.1), Color("8fc4ff"), Vector3.ZERO, null, 0.0)
	cyl(r, 0.3, 0.3, 1.6, Vector3(-0.2, 0.4, -0.55), Color("e6e0c8"), Vector3(0, 0, 90), 40)
	for s in [-1.0, 1.0]:
		cyl(r, 0.33, 0.33, 0.05, Vector3(-0.2 + s * 0.82, 0.4, -0.55), BRASS, Vector3(0, 0, 90), 40)
		cyl(r, 0.08, 0.08, 0.09, Vector3(-0.2 + s * 0.87, 0.4, -0.55), BRASS, Vector3(0, 0, 90), 16)
	cyl(r, 0.31, 0.31, 0.18, Vector3(-0.2, 0.4, -0.55), RED, Vector3(0, 0, 90), 40)
	# a pencil resting on the sheet
	cyl(r, 0.045, 0.045, 1.0, Vector3(0.55, 0.1, 0.45), YELLOW, Vector3(0, 0, 90), 6)
	cyl(r, 0.045, 0.0, 0.14, Vector3(1.12, 0.1, 0.45), Color("e8c9a0"), Vector3(0, 0, -90), 6)
	cyl(r, 0.045, 0.045, 0.1, Vector3(0.02, 0.1, 0.45), RED, Vector3(0, 0, 90), 12)


# --------------------------------------------------------------- equipment

func _collar() -> void:
	var r := group(0.0)
	torus(r, 0.78, 0.15, Vector3(0, 0.5, 0), DARK)
	torus(r, 0.78, 0.04, Vector3(0, 0.6, 0), Color("5a6472"))
	for i in 14:
		var a := i * TAU / 14.0
		var out := Vector3(cos(a), 0.0, sin(a))
		var p := Vector3(cos(a) * 0.78, 0.5, sin(a) * 0.78)
		cyl(r, 0.085, 0.085, 0.05, p + out * 0.05 + Vector3(0, 0.1, 0), BRASS, Vector3.ZERO, 16)
		var n := cyl(r, 0.12, 0.0, 0.46, p + out * 0.24, RED, Vector3.ZERO, 16)
		n.quaternion = Quaternion(Vector3.UP.cross(out).normalized(), Vector3.UP.angle_to(out))
	# a brass buckle at the front
	box(r, Vector3(0.36, 0.3, 0.12), Vector3(0, 0.5, 0.95), BRASS, Vector3.ZERO, null, 0.05)
	box(r, Vector3(0.2, 0.16, 0.14), Vector3(0, 0.5, 0.95), DARK, Vector3.ZERO, null, 0.03)
	box(r, Vector3(0.05, 0.34, 0.14), Vector3(0.0, 0.5, 0.97), Color("ffd35a"), Vector3.ZERO, null, 0.02)


func _plating() -> void:
	var r := group(0.0)
	var tints := [Color("b6bec9"), Color("dde3ea"), Color("aab2bc")]
	for i in 3:
		var base := Vector3(-0.35 + i * 0.35, 0.9 - i * 0.12, i * 0.14)
		box(r, Vector3(1.3, 0.95, 0.12), base, tints[i], Vector3(0, -8 + i * 8, 0), null, 0.06)
		box(r, Vector3(1.14, 0.1, 0.14), base + Vector3(0, 0.3, 0.0), RED if i == 1 else Color("5a6472"), Vector3(0, -8 + i * 8, 0), null, 0.03)
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				cyl(r, 0.06, 0.06, 0.05, base + Vector3(sx * 0.5, sy * 0.38, 0.08), BRASS, Vector3(90, 0, 0), 14)
				cyl(r, 0.025, 0.025, 0.06, base + Vector3(sx * 0.5, sy * 0.38, 0.1), Color("6b4a12"), Vector3(90, 0, 0), 8)


func _wings() -> void:
	var r := group(0.0)
	box(r, Vector3(0.62, 0.95, 0.24), Vector3(0, 0.9, 0), DARK, Vector3.ZERO, null, 0.1)
	box(r, Vector3(0.3, 0.3, 0.1), Vector3(0, 0.95, 0.16), BRASS, Vector3.ZERO, null, 0.05)
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.12, 1.0, 0.1), Vector3(s * 0.22, 0.9, 0.18), Color("3a4250"), Vector3.ZERO, null, 0.04)
		# two layers of feathers, long ones behind and short coverts in front
		for layer in 2:
			var count := 6 if layer == 0 else 5
			for i in count:
				var t := float(i) / float(count - 1)
				var ang := 14.0 + t * 82.0
				var length := (1.55 - t * 0.35) * (1.0 if layer == 0 else 0.62)
				var a := deg_to_rad(ang)
				var root := Vector3(s * 0.28, 1.0, -0.1 + layer * 0.07)
				var col: Color = TEAL.lerp(WHITE, t * 0.9 if layer == 0 else 0.15 + t * 0.4)
				var f := ball(r, 1.0, root + Vector3(s * cos(a), sin(a), 0) * (length * 0.5), col)
				f.scale = Vector3(length * 0.5, 0.15 if layer == 0 else 0.12, 0.05)
				f.rotation_degrees = Vector3(0, 0, s * ang)
		stick(r, Vector3(s * 0.3, 1.1, 0.1), Vector3(s * 1.2, 1.9, 0.1), 0.04, GREY)


func _scales() -> void:
	var r := group(0.0)
	var rows := 7
	for row in rows:
		for col in 6:
			var x := -1.1 + col * 0.44 + (0.22 if row % 2 == 1 else 0.0)
			var t := float(row) / float(rows - 1)
			var c := GREEN.lerp(TEAL, t) if (row + col) % 2 == 0 else GREEN.lerp(TEAL, t).lightened(0.12)
			var sc := ball(r, 1.0, Vector3(x, 0.2 + row * 0.24, row * 0.05), c)
			sc.scale = Vector3(0.27, 0.33, 0.07)
			sc.rotation_degrees = Vector3(-18, 0, 0)
			sc.material_override = mat(c, 0.03, Vector3.UP, 0.3, 0.7)
			var gem := ball(r, 0.04, Vector3(x, 0.2 + row * 0.24 + 0.08, row * 0.05 + 0.08), WHITE)
			gem.material_override = gloss(c.lightened(0.45), 0.4)


func _jetpack() -> void:
	var r := group(0.0)
	box(r, Vector3(1.6, 1.3, 0.22), Vector3(0, 1.0, -0.38), DARK, Vector3.ZERO, null, 0.1)
	for s in [-1.0, 1.0]:
		var x: float = s * 0.45
		cyl(r, 0.3, 0.3, 1.2, Vector3(x, 1.05, 0), Color("dfe5ec"))
		var dome := ball(r, 0.3, Vector3(x, 1.65, 0), Color("dfe5ec"), Vector3(1.0, 0.7, 1.0))
		dome.material_override = mat(Color("dfe5ec"), 0.03, Vector3.UP, 0.3, 0.7)
		for k in 2:
			torus(r, 0.305, 0.04, Vector3(x, 0.8 + k * 0.5, 0), RED)
		cyl(r, 0.3, 0.2, 0.22, Vector3(x, 0.36, 0), BRASS)
		cyl(r, 0.2, 0.28, 0.3, Vector3(x, 0.1, 0), GREY)
		var flame := cyl(r, 0.24, 0.0, 0.75, Vector3(x, -0.4, 0), ORANGE, Vector3.ZERO, 24)
		flame.material_override = gloss(Color("ff7a1a"), 3.0, 0.9)
		var core := cyl(r, 0.12, 0.0, 0.5, Vector3(x, -0.28, 0), YELLOW, Vector3.ZERO, 24)
		core.material_override = gloss(Color("ffe45a"), 4.0)
	box(r, Vector3(0.5, 0.34, 0.34), Vector3(0, 1.1, 0.02), Color("2b3038"), Vector3.ZERO, null, 0.08)
	for i in 3:
		var led := ball(r, 0.035, Vector3(-0.12 + i * 0.12, 1.12, 0.2), GREEN)
		led.material_override = gloss([Color("5cff7a"), Color("ffb02e"), Color("ff4a3a")][i], 2.0)
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.16, 1.2, 0.1), Vector3(s * 0.88, 0.95, 0.1), Color("3a4250"), Vector3.ZERO, null, 0.04)
		box(r, Vector3(0.22, 0.2, 0.12), Vector3(s * 0.88, 0.7, 0.18), BRASS, Vector3.ZERO, null, 0.04)


func _crown() -> void:
	var r := group(0.0)
	cyl(r, 0.72, 0.72, 0.42, Vector3(0, 0.4, 0), BRASS, Vector3.ZERO, 48)
	cyl(r, 0.6, 0.6, 0.44, Vector3(0, 0.4, 0), Color("6b3a2a"), Vector3.ZERO, 48)
	torus(r, 0.72, 0.05, Vector3(0, 0.62, 0), BRASS)
	torus(r, 0.72, 0.05, Vector3(0, 0.2, 0), BRASS)
	var gems := [PURPLE, RED, BLUE, GREEN, RED, PURPLE]
	for i in 6:
		var a := i * TAU / 6.0
		var p := Vector3(cos(a) * 0.62, 0.92, sin(a) * 0.62)
		var spike := cyl(r, 0.2, 0.0, 0.66, p, BRASS, Vector3.ZERO, 16)
		spike.rotation_degrees = Vector3(sin(a) * 6.0, 0, -cos(a) * 6.0)
		var orb := ball(r, 0.11, p + Vector3(0, 0.42, 0), gems[i])
		orb.material_override = gloss(gems[i], 0.7, 1.0, 0.04)
	var front := ball(r, 0.14, Vector3(0, 0.42, 0.74), BLUE, Vector3(1.0, 1.15, 0.7))
	front.material_override = gloss(Color("4aa8ff"), 1.0, 1.0, 0.03)
	for i in 6:
		var a := (i + 0.5) * TAU / 6.0
		var jewel := ball(r, 0.06, Vector3(cos(a) * 0.73, 0.4, sin(a) * 0.73), WHITE)
		jewel.material_override = gloss(Color("ffe9a0"), 0.6, 1.0, 0.05)
