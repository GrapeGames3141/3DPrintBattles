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
		"spike_collar": [_collar, 42.0, 4.6, 0.45],
		"spare_plating": [_plating, 12.0, 5.4, 0.9],
		"wing_kit": [_wings, 14.0, 4.6, 1.0],
		"scale_mail": [_scales, 12.0, 5.6, 0.9],
		"jet_pack": [_jetpack, 14.0, 5.8, 0.9],
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
	box(r, Vector3(1.3, 0.55, 0.5), Vector3(0.0, 0.95, 0), YELLOW)
	box(r, Vector3(0.42, 0.95, 0.4), Vector3(-0.35, 0.4, 0), DARK, Vector3(0, 0, -12))
	box(r, Vector3(0.14, 0.3, 0.12), Vector3(0.0, 0.62, 0.0), RED, Vector3(0, 0, 16))
	cyl(r, 0.2, 0.2, 0.5, Vector3(0.86, 0.95, 0), GREY, Vector3(0, 0, -90), 24)
	cyl(r, 0.12, 0.03, 0.34, Vector3(1.2, 0.95, 0), BRASS, Vector3(0, 0, -90), 24)
	cyl(r, 0.1, 0.1, 1.1, Vector3(-1.05, 0.98, 0), WHITE, Vector3(0, 0, 90), 24)
	ball(r, 0.1, Vector3(1.4, 0.95, 0), WHITE, Vector3(1.2, 0.8, 0.8))


func _soldering_iron() -> void:
	var r := group(-38.0)
	cyl(r, 0.17, 0.17, 1.5, Vector3(-0.55, 0.3, 0), DARK, Vector3(0, 0, 90), 32)
	cyl(r, 0.2, 0.2, 0.3, Vector3(0.28, 0.3, 0), RED, Vector3(0, 0, 90), 32)
	cyl(r, 0.08, 0.08, 0.9, Vector3(0.9, 0.3, 0), GREY, Vector3(0, 0, 90), 24)
	cyl(r, 0.08, 0.02, 0.35, Vector3(1.52, 0.3, 0), BRASS, Vector3(0, 0, -90), 24)
	for i in 5:
		torus(r, 0.3, 0.045, Vector3(-0.1, 0.07 + i * 0.0, -0.9 + i * 0.0), GREY, Vector3(90, 0, 0))
	box(r, Vector3(1.1, 0.1, 0.6), Vector3(0.1, 0.05, -0.85), DARK)
	for i in 4:
		torus(r, 0.22, 0.04, Vector3(0.1 - 0.1 * i, 0.2 + i * 0.07, -0.85), GREY, Vector3(90, 0, 0))


func _tweezers() -> void:
	var r := group(-24.0)
	for s in [-1.0, 1.0]:
		box(r, Vector3(2.0, 0.07, 0.2), Vector3(0.05, 0.06, s * 0.1), GREY, Vector3(0, s * 3.5, 0))
	box(r, Vector3(0.3, 0.1, 0.46), Vector3(-1.05, 0.07, 0), BLUE)
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.3, 0.1, 0.1), Vector3(1.0, 0.07, s * 0.05), DARK, Vector3(0, s * 3.5, 0))


func _goggles() -> void:
	var r := group(-12.0)
	for s in [-1.0, 1.0]:
		torus(r, 0.46, 0.1, Vector3(s * 0.58, 0.62, 0), ORANGE, Vector3(90, 0, 0))
		cyl(r, 0.45, 0.45, 0.05, Vector3(s * 0.58, 0.62, 0.0), Color("9fd8ff"), Vector3(90, 0, 0), 40)
	box(r, Vector3(0.3, 0.14, 0.12), Vector3(0, 0.66, 0), ORANGE)
	torus(r, 1.1, 0.07, Vector3(0, 0.62, -0.18), DARK, Vector3(90, 0, 0))
	box(r, Vector3(0.55, 0.18, 0.1), Vector3(-1.05, 0.62, 0.0), DARK, Vector3(0, 80, 0))
	box(r, Vector3(0.55, 0.18, 0.1), Vector3(1.05, 0.62, 0.0), DARK, Vector3(0, -80, 0))


func _dryer() -> void:
	var r := group(-26.0)
	box(r, Vector3(1.7, 0.7, 1.3), Vector3(0, 0.35, 0), WHITE)
	ball(r, 0.72, Vector3(0, 0.7, 0), TEAL, Vector3(1.1, 0.7, 0.9))
	var axis: Vector3 = (r.global_transform.basis * Vector3.RIGHT).normalized()
	cyl(r, 0.5, 0.5, 0.3, Vector3(0, 1.0, 0), ORANGE, Vector3(0, 0, 0), 48, mat(ORANGE, 0.03, axis, 0.3, 0.8))
	box(r, Vector3(0.5, 0.2, 0.05), Vector3(0.45, 0.35, 0.67), DARK)
	box(r, Vector3(0.16, 0.08, 0.02), Vector3(0.45, 0.35, 0.7), GREEN)
	cyl(r, 0.07, 0.07, 0.5, Vector3(-0.7, 0.5, 0.66), GREY, Vector3(90, 0, 0), 16)


func _feeler() -> void:
	var r := group(-8.0)
	var cols := [GREY, BLUE, TEAL, GREEN, YELLOW, ORANGE]
	for i in cols.size():
		box(r, Vector3(1.8, 0.035, 0.26), Vector3(0.45 + cos(deg_to_rad(i * 13.0)) * 0.0, 0.05 + i * 0.045, 0), cols[i], Vector3(0, i * 13.0 - 30.0, 0))
	cyl(r, 0.14, 0.14, 0.4, Vector3(-0.45, 0.17, 0), BRASS, Vector3.ZERO, 24)


func _spaghetti() -> void:
	var r := group(0.0)
	box(r, Vector3(1.5, 0.1, 1.3), Vector3(0, 0.05, 0), DARK)
	var m := mat(ORANGE, 0.02, Vector3.UP, 0.3, 0.3)
	for i in 26:
		var a := i * 2.399
		var radius := 0.22 + 0.2 * fmod(i * 0.37, 1.0)
		torus(r, radius, 0.05, Vector3(sin(a) * 0.32, 0.14 + (i % 9) * 0.07, cos(a * 1.3) * 0.28), ORANGE, Vector3(sin(a * 1.7) * 70.0, a * 40.0, cos(a) * 70.0), m)
	for i in 5:
		var a := i * 1.3
		stick(r, Vector3(sin(a) * 0.5, 0.2, cos(a) * 0.4), Vector3(sin(a + 2.0) * 0.8, 0.9 + i * 0.1, cos(a + 1.0) * 0.6), 0.05, ORANGE)


func _plug() -> void:
	var r := group(-30.0)
	box(r, Vector3(0.95, 0.7, 0.8), Vector3(0, 0.55, 0), DARK)
	box(r, Vector3(0.7, 0.5, 0.3), Vector3(0, 0.6, 0.45), RED)
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.1, 0.34, 0.5), Vector3(s * 0.22, 0.58, 0.9), BRASS)
	cyl(r, 0.16, 0.16, 0.6, Vector3(0, 0.55, -0.6), DARK, Vector3(90, 0, 0), 24)
	for i in 6:
		var t := i / 5.0
		stick(r, Vector3(-0.1 - t * 1.2, 0.2 + sin(t * 3.0) * 0.12, -0.8 - t * 0.6), Vector3(-0.1 - (t + 0.2) * 1.2, 0.2 + sin((t + 0.2) * 3.0) * 0.12, -0.8 - (t + 0.2) * 0.6), 0.07, DARK)
	for i in 6:
		var a := i * 1.05
		stick(r, Vector3(0, 0.7, 1.1), Vector3(sin(a) * 0.5, 0.7 + cos(a) * 0.4, 1.3), 0.03, YELLOW)


func _backup_spool() -> void:
	for k in 2:
		var r := group(62.0 - k * 50.0, Vector3(-0.55 + k * 1.15, 0, -0.1 * k))
		var s := 1.0 - 0.28 * k
		var col: Color = TEAL if k == 0 else BLUE
		var axis: Vector3 = (r.global_transform.basis * Vector3.BACK).normalized()
		var rx := Vector3(90, 0, 0)
		cyl(r, 0.9 * s, 0.9 * s, 0.06, Vector3(0, 0.95 * s, 0.31 * s), DARK, rx, 64)
		cyl(r, 0.9 * s, 0.9 * s, 0.06, Vector3(0, 0.95 * s, -0.31 * s), DARK, rx, 64)
		cyl(r, 0.74 * s, 0.74 * s, 0.55 * s, Vector3(0, 0.95 * s, 0), col, rx, 64, mat(col, 0.03, axis, 0.3, 0.8))
		cyl(r, 0.24 * s, 0.24 * s, 0.72 * s, Vector3(0, 0.95 * s, 0), GREY, rx)
	box(_holder, Vector3(0.7, 0.03, 0.18), Vector3(0.1, 0.02, 0.9), YELLOW, Vector3(0, 12, 0))


func _blueprint() -> void:
	var r := group(-20.0)
	box(r, Vector3(2.0, 0.05, 1.3), Vector3(0.0, 0.03, 0.1), BLUE)
	for i in 6:
		box(r, Vector3(2.0, 0.052, 0.025), Vector3(0.0, 0.032, -0.4 + i * 0.2), Color("8fc4ff"))
	for i in 9:
		box(r, Vector3(0.025, 0.052, 1.3), Vector3(-0.9 + i * 0.225, 0.032, 0.1), Color("8fc4ff"))
	cyl(r, 0.3, 0.3, 1.6, Vector3(-0.2, 0.4, -0.55), Color("e6e0c8"), Vector3(0, 0, 90), 40)
	for s in [-1.0, 1.0]:
		cyl(r, 0.33, 0.33, 0.05, Vector3(-0.2 + s * 0.82, 0.4, -0.55), BRASS, Vector3(0, 0, 90), 40)
	cyl(r, 0.31, 0.31, 0.18, Vector3(-0.2, 0.4, -0.55), RED, Vector3(0, 0, 90), 40)


# --------------------------------------------------------------- equipment

func _collar() -> void:
	var r := group(0.0)
	torus(r, 0.78, 0.14, Vector3(0, 0.5, 0), DARK)
	for i in 14:
		var a := i * TAU / 14.0
		var p := Vector3(cos(a) * 0.78, 0.5, sin(a) * 0.78)
		# spikes point out from the ring, which lies almost flat
		var out := Vector3(cos(a), 0.0, sin(a))
		var n := cyl(r, 0.12, 0.0, 0.42, p + out * 0.2 + Vector3(0, 0.0, 0), RED, Vector3.ZERO, 16)
		n.quaternion = Quaternion(Vector3.UP.cross(out).normalized() if Vector3.UP.cross(out).length() > 0.001 else Vector3.RIGHT, Vector3.UP.angle_to(out))
	box(r, Vector3(0.26, 0.26, 0.12), Vector3(0, 0.5, 1.0), BRASS)


func _plating() -> void:
	var r := group(0.0)
	for i in 3:
		box(r, Vector3(1.3, 0.95, 0.12), Vector3(-0.35 + i * 0.35, 0.9 - i * 0.12, i * 0.12), GREY if i != 1 else Color("c4ccd6"), Vector3(0, -8 + i * 8, 0))
	for i in 3:
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				cyl(r, 0.05, 0.05, 0.05, Vector3(-0.35 + i * 0.35 + sx * 0.5, 0.9 - i * 0.12 + sy * 0.38, i * 0.12 + 0.08), BRASS, Vector3(90, 0, 0), 12)


func _wings() -> void:
	var r := group(0.0)
	box(r, Vector3(0.5, 0.9, 0.2), Vector3(0, 0.9, 0), DARK)
	for s in [-1.0, 1.0]:
		for i in 5:
			var len := 1.4 - i * 0.14
			var a := deg_to_rad(20.0 + i * 15.0)
			var tip := Vector3(s * cos(a) * len, 0.95 + sin(a) * len * 0.7, 0)
			var mid := Vector3(s * 0.22, 0.95, 0) .lerp(tip, 0.5)
			var f := box(r, Vector3(len, 0.06, 0.34), mid, TEAL if i % 2 == 0 else WHITE, Vector3(0, 0, s * rad_to_deg(a) * 0.7))


func _scales() -> void:
	var r := group(0.0)
	var cols := [GREEN, TEAL, GREEN, TEAL]
	for row in 5:
		for col in 5:
			var x := -0.9 + col * 0.45 + (0.22 if row % 2 == 1 else 0.0)
			cyl(r, 0.27, 0.27, 0.08, Vector3(x, 0.3 + row * 0.28, row * 0.02), cols[(row + col) % 4], Vector3(90, 0, 0), 6)


func _jetpack() -> void:
	var r := group(0.0)
	for s in [-1.0, 1.0]:
		cyl(r, 0.3, 0.3, 1.2, Vector3(s * 0.42, 1.0, 0), GREY)
		cyl(r, 0.3, 0.18, 0.2, Vector3(s * 0.42, 0.3, 0), BRASS)
		cyl(r, 0.0, 0.2, 0.55, Vector3(s * 0.42, 0.0, 0), ORANGE)
		cyl(r, 0.31, 0.31, 0.18, Vector3(s * 0.42, 1.4, 0), RED)
	box(r, Vector3(0.9, 0.3, 0.3), Vector3(0, 1.0, -0.1), DARK)
	box(r, Vector3(0.18, 1.1, 0.12), Vector3(-0.8, 0.95, 0.25), DARK)
	box(r, Vector3(0.18, 1.1, 0.12), Vector3(0.8, 0.95, 0.25), DARK)


func _crown() -> void:
	var r := group(0.0)
	cyl(r, 0.7, 0.7, 0.4, Vector3(0, 0.4, 0), BRASS, Vector3.ZERO, 40)
	cyl(r, 0.6, 0.6, 0.42, Vector3(0, 0.4, 0), Color("6b4a12"), Vector3.ZERO, 40)
	for i in 6:
		var a := i * TAU / 6.0
		var p := Vector3(cos(a) * 0.62, 0.9, sin(a) * 0.62)
		cyl(r, 0.2, 0.0, 0.6, p, BRASS, Vector3.ZERO, 16)
		ball(r, 0.1, p + Vector3(0, 0.38, 0), PURPLE if i % 2 == 0 else RED)
	ball(r, 0.13, Vector3(0, 0.42, 0.68), BLUE)
	torus(r, 0.7, 0.06, Vector3(0, 0.62, 0), BRASS)
