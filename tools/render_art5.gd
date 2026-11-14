extends "res://tools/render_art4.gd"
## Fifth wave: ten more modelled prints, eight tools and six pieces of equipment.
##
##   godot --path . --disable-vsync -s tools/render_art5.gd              (all)
##   godot --path . --disable-vsync -s tools/render_art5.gd -- chillfan

func _initialize() -> void:
	var only: Array = Array(OS.get_cmdline_user_args())
	await process_frame
	_build_studio()
	await process_frame
	var tools := {
		"cable_management": [_cables, 46.0, 5.0, 0.2], "post_processing_kit": [_ppkit, 44.0, 5.2, 0.2],
		"glow_filament": [_glow_spool, 26.0, 5.2, 0.9], "pressure_advance": [_gauge, 24.0, 5.2, 0.8],
		"power_loss_recovery": [_ups, 30.0, 5.4, 0.5], "thermal_runaway": [_runaway, 22.0, 5.2, 0.8],
		"firmware_update": [_board, 44.0, 5.2, 0.2], "open_source_blueprint": [_blueprint, 40.0, 5.6, 0.4],
	}
	var gear := {
		"belt_tensioner": [_belt, 12.0, 5.6, 1.0], "linear_rails": [_rails, 12.0, 5.8, 0.4],
		"direct_drive_gearbox": [_gearbox, 14.0, 5.6, 0.8], "enclosure_panels": [_panels, 14.0, 6.0, 1.0],
		"laser_engraver": [_laser_gear, 12.0, 5.4, 0.7], "corexy_frame": [_corexy, 16.0, 6.4, 0.9],
	}
	var beasts := {
		"spool_snail": [_snail, -30.0, 0.8, 8.0, 16.0], "support_treant": [_treant, -14.0, 1.2, 8.0, 12.0],
		"spool_colossus": [_colossus, -16.0, 1.3, 8.6, 12.0], "chillfan": [_chillfan, -22.0, 0.9, 7.0, 12.0],
		"multimeter_beetle": [_beetle, -26.0, 0.8, 7.2, 16.0], "resin_jelly": [_jelly, -12.0, 1.0, 7.2, 12.0],
		"rotor_drone": [_drone, -26.0, 0.9, 8.0, 22.0], "hexnut_hog": [_hog, -28.0, 0.7, 7.0, 14.0],
		"gcode_golem": [_gcode, -20.0, 1.0, 8.0, 12.0], "heatbed_hedgehog": [_hedgehog, -26.0, 0.6, 7.0, 16.0],
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
			(job[0] as Callable).call()
			cam.fov = 28.0
			_aim(float(job[4]), float(job[3]), float(job[2]))
			await _settle()
			vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(SRC_OUT % id))
			print("rendered ", id)
	quit()


func cone(p: Node3D, base: Vector3, tip: Vector3, r: float, col: Color, m: Material = null) -> MeshInstance3D:
	var n := cyl(p, r, 0.0, base.distance_to(tip), (base + tip) * 0.5, col, Vector3.ZERO, 16, m)
	var dir := (tip - base).normalized()
	var axis := Vector3.UP.cross(dir)
	if axis.length() > 0.0001:
		n.quaternion = Quaternion(axis.normalized(), Vector3.UP.angle_to(dir))
	return n


func spool_body(p: Node3D, pos: Vector3, r: float, width: float, cols: Array, axis_rot: Vector3) -> Node3D:
	## A filament spool: two flanges, a core, and coloured wraps. Built along Y,
	## then turned by axis_rot.
	var s := Node3D.new()
	_place(p, s, pos, axis_rot)
	cyl(s, r, r, 0.07, Vector3(0, width * 0.5, 0), Color("2b3038"), Vector3.ZERO, 48)
	cyl(s, r, r, 0.07, Vector3(0, -width * 0.5, 0), Color("2b3038"), Vector3.ZERO, 48)
	cyl(s, r * 0.5, r * 0.5, width, Vector3.ZERO, Color("3a424d"), Vector3.ZERO, 32)
	var n: int = cols.size()
	for i in n:
		var h := width / n
		cyl(s, r * 0.9, r * 0.9, h * 0.98, Vector3(0, -width * 0.5 + h * (i + 0.5), 0), cols[i], Vector3.ZERO, 48, mat(cols[i], 0.02, Vector3.UP, 0.3, 0.4))
	return s


# ------------------------------------------------------------------ tools

func _cables() -> void:
	var r := group(-20.0)
	var cols := [BLUE, ORANGE, GREEN]
	for i in 3:
		torus(r, 0.55 - i * 0.14, 0.07, Vector3(0, 0.08 + i * 0.1, 0), cols[i], Vector3.ZERO)
	box(r, Vector3(1.0, 0.05, 0.28), Vector3(0.9, 0.05, 0.5), DARK, Vector3(0, 20, 0), null, 0.02)
	box(r, Vector3(0.28, 0.08, 0.28), Vector3(1.25, 0.06, 0.45), WHITE, Vector3(0, 20, 0), null, 0.02)
	for i in 4:
		torus(r, 0.14, 0.025, Vector3(-0.9 + i * 0.28, 0.06, -0.7), WHITE if i % 2 == 0 else DARK, Vector3(0, 0, 0))
	box(r, Vector3(1.3, 0.14, 0.2), Vector3(-0.3, 0.07, 0.85), GREY, Vector3(0, -8, 0), null, 0.05)
	for i in 8:
		box(r, Vector3(0.03, 0.15, 0.22), Vector3(-0.9 + i * 0.17, 0.1, 0.85 - i * 0.02), GREY.darkened(0.2), Vector3(0, -8, 0))


func _ppkit() -> void:
	var r := group(-16.0)
	box(r, Vector3(1.9, 0.12, 1.25), Vector3(0, 0.06, 0), DARK, Vector3.ZERO, null, 0.04)
	for s in [-1.0, 1.0]:
		box(r, Vector3(1.9, 0.14, 0.06), Vector3(0, 0.16, s * 0.6), DARK.lightened(0.1))
	box(r, Vector3(1.0, 0.04, 0.12), Vector3(-0.35, 0.18, -0.3), STEEL, Vector3(0, 8, 0), metal_mat(STEEL), 0.01)
	box(r, Vector3(0.4, 0.1, 0.14), Vector3(0.28, 0.2, -0.3), RED, Vector3(0, 8, 0))
	for i in 3:
		box(r, Vector3(0.5, 0.02, 0.5), Vector3(-0.45 + i * 0.08, 0.15 + i * 0.03, 0.2 - i * 0.04), Color("d9b46a").darkened(i * 0.1), Vector3(0, 12 + i * 8, 0), mat(Color("d9b46a"), 0.01, Vector3.UP, 0.9, 1.2), 0.005)
	cyl(r, 0.2, 0.2, 0.5, Vector3(0.55, 0.37, 0.25), BLUE, Vector3.ZERO, 32)
	cyl(r, 0.14, 0.14, 0.1, Vector3(0.55, 0.67, 0.25), WHITE, Vector3.ZERO, 24)
	box(r, Vector3(0.5, 0.18, 0.22), Vector3(0.62, 0.15, -0.08), WOOD, Vector3(0, -15, 0), null, 0.04)


func _glow_spool() -> void:
	var r := group(-38.0)
	var g := Color("5dff9e")
	var s := spool_body(r, Vector3(0, 0.82, 0), 0.8, 0.7, [g, Color("3be08a"), Color("86ffb8")], Vector3(0, 0, 90))
	for c in s.get_children():
		var m := c as MeshInstance3D
		if m != null and (m.mesh as CylinderMesh).height < 0.3 and (m.mesh as CylinderMesh).height > 0.1:
			m.material_override = gloss(g, 1.8, 1.0, 0.25)
	torus(r, 0.5, 0.05, Vector3(0.9, 0.05, 0.9), g, Vector3.ZERO, gloss(g, 2.5))
	glow(r, 0.08, Vector3(0.45, 0.12, 0.75), Color("b8ffd8"), 3.0)


func _gauge() -> void:
	var r := group(-12.0)
	cyl(r, 0.75, 0.75, 0.3, Vector3(0, 0.9, 0), BRASS, Vector3(90, 0, 0), 48, metal_mat(BRASS))
	cyl(r, 0.62, 0.62, 0.04, Vector3(0, 0.9, 0.17), WHITE, Vector3(90, 0, 0), 48)
	for i in 11:
		var a := deg_to_rad(-140.0 + i * 28.0)
		box(r, Vector3(0.035, 0.12, 0.02), Vector3(sin(a) * 0.5, 0.9 + cos(a) * 0.5, 0.2), DARK if i < 8 else RED, Vector3(0, 0, -rad_to_deg(a)))
	box(r, Vector3(0.05, 0.5, 0.02), Vector3(0.14, 1.04, 0.22), RED, Vector3(0, 0, -28))
	cyl(r, 0.06, 0.06, 0.06, Vector3(0, 0.9, 0.24), DARK, Vector3(90, 0, 0), 16)
	cyl(r, 0.16, 0.16, 0.5, Vector3(0, 0.3, 0.0), BRASS, Vector3.ZERO, 24, metal_mat(BRASS))
	cyl(r, 0.28, 0.28, 0.14, Vector3(0, 0.07, 0.0), BRASS, Vector3.ZERO, 6, metal_mat(BRASS))
	label(r, "PA", 12, Vector3(-0.14, 0.7, 0.24), DARK)


func _ups() -> void:
	var r := group(-22.0)
	box(r, Vector3(1.5, 0.8, 0.9), Vector3(0, 0.4, 0), Color("38414d"), Vector3.ZERO, null, 0.09)
	box(r, Vector3(1.2, 0.3, 0.06), Vector3(0, 0.5, 0.47), Color("0c1822"))
	for i in 5:
		glow(r, 0.05, Vector3(-0.4 + i * 0.2, 0.5, 0.5), GREEN if i < 4 else YELLOW, 3.0)
	box(r, Vector3(0.7, 0.14, 0.4), Vector3(0, 0.88, 0), Color("38414d").lightened(0.1), Vector3.ZERO, null, 0.05)
	torus(r, 0.5, 0.05, Vector3(0.95, 0.12, 0.35), DARK, Vector3(0, 0, 0))
	box(r, Vector3(0.28, 0.16, 0.2), Vector3(1.0, 0.1, -0.28), DARK, Vector3(0, 20, 0))
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.04, 0.1, 0.02), Vector3(1.1 + s * 0.04, 0.1, -0.4), BRASS, Vector3(0, 20, 0))
	label(r, "UPS", 18, Vector3(-0.3, 0.2, 0.48), WHITE)


func _runaway() -> void:
	var r := group(-26.0)
	box(r, Vector3(0.95, 0.7, 0.75), Vector3(0, 0.4, 0), RED, Vector3.ZERO, gloss(Color("ff5a28"), 1.6, 1.0, 0.3), 0.1)
	cyl(r, 0.3, 0.05, 0.4, Vector3(0, -0.02, 0), BRASS, Vector3.ZERO, 24, metal_mat(BRASS))
	glow(r, 0.08, Vector3(0, -0.2, 0), Color("ffe08a"), 4.0)
	for i in 7:
		var a := i * 0.9
		var base := Vector3(cos(a) * 0.28, 0.75, sin(a) * 0.22)
		cone(r, base, base + Vector3(cos(a) * 0.1, 0.55 + fmod(i * 0.31, 0.5), sin(a) * 0.1), 0.15 - (i % 3) * 0.02, Color("ff8a2a"), gloss(Color("ff8a2a"), 2.5, 0.8, 0.1))
	for i in 3:
		stick(r, Vector3(-0.5, 0.45, 0.1 * i), Vector3(-1.3, 0.1, -0.5 + i * 0.5), 0.04, RED if i != 1 else DARK)
	box(r, Vector3(1.4, 0.04, 1.2), Vector3(0, 0.02, 0), DARK.lightened(0.05))


func _board() -> void:
	var r := group(-18.0)
	box(r, Vector3(1.9, 0.1, 1.3), Vector3(0, 0.06, 0), Color("1f8a4c"), Vector3.ZERO, null, 0.03)
	for i in 6:
		box(r, Vector3(0.5 - (i % 3) * 0.08, 0.02, 0.012), Vector3(-0.2 + (i % 3) * 0.1, 0.12, -0.3 + i * 0.12), Color("a8e8b8"))
	box(r, Vector3(0.5, 0.1, 0.5), Vector3(0.1, 0.16, 0.0), DARK, Vector3(0, 8, 0), null, 0.02)
	for i in 8:
		box(r, Vector3(0.06, 0.04, 0.12), Vector3(-0.07 + i * 0.06, 0.12, 0.34), STEEL, Vector3(0, 8, 0))
		box(r, Vector3(0.06, 0.04, 0.12), Vector3(-0.07 + i * 0.06, 0.12, -0.34), STEEL, Vector3(0, 8, 0))
	box(r, Vector3(0.3, 0.1, 0.22), Vector3(-0.65, 0.16, 0.3), DARK, Vector3(0, -6, 0))
	box(r, Vector3(0.28, 0.14, 0.18), Vector3(0.75, 0.18, -0.25), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.02)
	glow(r, 0.045, Vector3(0.65, 0.14, 0.4), Color("5ad1ff"), 3.5)
	glow(r, 0.045, Vector3(0.78, 0.14, 0.4), Color("ffe05a"), 3.5)
	box(r, Vector3(0.7, 0.1, 0.28), Vector3(1.4, 0.1, 0.55), Color("d9dde2"), Vector3(0, -20, 0), null, 0.03)


func _blueprint() -> void:
	var r := group(-14.0)
	var blue := Color("2b6fd6")
	box(r, Vector3(1.9, 0.03, 1.3), Vector3(0, 0.03, 0), blue, Vector3.ZERO, null, 0.005)
	for i in 8:
		box(r, Vector3(0.01, 0.01, 1.25), Vector3(-0.85 + i * 0.24, 0.05, 0), Color("a9c9ff"))
	for i in 5:
		box(r, Vector3(1.8, 0.01, 0.01), Vector3(0, 0.05, -0.5 + i * 0.25), Color("a9c9ff"))
	torus(r, 0.3, 0.03, Vector3(-0.2, 0.06, 0.0), WHITE, Vector3.ZERO)
	for i in 8:
		var a := i * TAU / 8.0
		box(r, Vector3(0.12, 0.02, 0.08), Vector3(-0.2 + cos(a) * 0.36, 0.06, sin(a) * 0.36), WHITE, Vector3(0, -rad_to_deg(a), 0))
	box(r, Vector3(0.4, 0.015, 0.02), Vector3(0.6, 0.06, 0.2), WHITE)
	box(r, Vector3(0.3, 0.015, 0.02), Vector3(0.55, 0.06, 0.3), WHITE)
	cyl(r, 0.2, 0.2, 1.5, Vector3(-0.6, 0.22, 0.75), Color("1f56b0"), Vector3(0, 0, 90), 32)
	cyl(r, 0.12, 0.12, 1.52, Vector3(-0.6, 0.22, 0.75), CREAM, Vector3(0, 0, 90), 24)
	box(r, Vector3(0.7, 0.08, 0.08), Vector3(0.7, 0.1, 0.6), YELLOW, Vector3(0, 30, 0), null, 0.03)


# -------------------------------------------------------------- equipment

func _belt() -> void:
	var r := group(-6.0)
	var a := Vector3(-0.95, 1.0, 0)
	var b := Vector3(0.95, 1.0, 0)
	for p in [a, b]:
		cyl(r, 0.42, 0.42, 0.3, p, STEEL, Vector3(90, 0, 0), 40, metal_mat(STEEL))
		for i in 16:
			var an := i * TAU / 16.0
			box(r, Vector3(0.06, 0.08, 0.26), p + Vector3(cos(an) * 0.44, sin(an) * 0.44, 0), STEEL, Vector3(0, 0, rad_to_deg(an)))
		cyl(r, 0.1, 0.1, 0.4, p, DARK, Vector3(90, 0, 0), 20)
	for s in [-1.0, 1.0]:
		box(r, Vector3(1.9, 0.06, 0.24), Vector3(0, 1.0 + s * 0.47, 0), DARK, Vector3.ZERO, null, 0.02)
		for i in 18:
			box(r, Vector3(0.05, 0.05, 0.22), Vector3(-0.85 + i * 0.1, 1.0 + s * 0.43, 0), Color("3a424d"))
	box(r, Vector3(0.3, 0.3, 0.3), Vector3(1.5, 1.0, 0), BRASS, Vector3.ZERO, metal_mat(BRASS))
	cyl(r, 0.05, 0.05, 0.9, Vector3(1.8, 1.0, 0), STEEL, Vector3(0, 0, 90), 16, metal_mat(STEEL))
	box(r, Vector3(0.22, 0.2, 0.2), Vector3(2.2, 1.0, 0), RED, Vector3.ZERO, null, 0.04)


func _rails() -> void:
	var r := group(-12.0)
	for z in [-0.35, 0.35]:
		box(r, Vector3(2.7, 0.1, 0.2), Vector3(0, 0.05, z), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.02)
		box(r, Vector3(2.7, 0.06, 0.1), Vector3(0, 0.13, z), STEEL.lightened(0.1), Vector3.ZERO, metal_mat(STEEL.lightened(0.1)), 0.02)
	box(r, Vector3(0.9, 0.2, 1.1), Vector3(0.3, 0.32, 0), Color("2f8cf0"), Vector3.ZERO, null, 0.06)
	for z in [-0.35, 0.35]:
		box(r, Vector3(0.9, 0.12, 0.3), Vector3(0.3, 0.2, z), Color("1b4f94"), Vector3.ZERO, null, 0.04)
	for i in 4:
		cyl(r, 0.06, 0.06, 0.06, Vector3(0.0 + i * 0.2, 0.44, ((i % 2) * 2 - 1) * 0.4), BRASS, Vector3.ZERO, 6, metal_mat(BRASS))
	for i in 6:
		ball(r, 0.05, Vector3(-1.1 + i * 0.12, 0.1, 0.0), Color("dfe5ec"))


func _gearbox() -> void:
	var r := group(-16.0)
	cyl(r, 0.4, 0.4, 0.9, Vector3(-0.55, 0.7, 0), Color("38414d"), Vector3(0, 0, 90), 32)
	cyl(r, 0.42, 0.42, 0.1, Vector3(-1.05, 0.7, 0), STEEL, Vector3(0, 0, 90), 32, metal_mat(STEEL))
	box(r, Vector3(0.9, 0.8, 0.8), Vector3(0.35, 0.7, 0), Color("c8d0d8"), Vector3.ZERO, metal_mat(Color("c8d0d8")), 0.07)
	for z in [-1.0, 1.0]:
		cyl(r, 0.5, 0.5, 0.12, Vector3(0.45, 0.7, z * 0.46), BRASS, Vector3(90, 0, 0), 24, metal_mat(BRASS))
		for i in 12:
			var a := i * TAU / 12.0
			box(r, Vector3(0.1, 0.12, 0.12), Vector3(0.45 + cos(a) * 0.54, 0.7 + sin(a) * 0.54, z * 0.46), BRASS, Vector3(0, 0, rad_to_deg(a)), metal_mat(BRASS))
	cyl(r, 0.1, 0.1, 0.5, Vector3(0.45, 0.7, 0), STEEL, Vector3(90, 0, 0), 16, metal_mat(STEEL))
	for i in 4:
		cyl(r, 0.05, 0.05, 0.05, Vector3(0.05 + (i % 2) * 0.8, 0.45 + int(i / 2) * 0.5, 0.42), DARK, Vector3(90, 0, 0), 6)
	for i in 3:
		stick(r, Vector3(-1.05, 0.7, 0.1 * (i - 1)), Vector3(-1.6, 0.3 + i * 0.1, -0.3 + i * 0.3), 0.04, [RED, DARK, YELLOW][i])


func _panels() -> void:
	var r := group(-24.0)
	var smoke := Color("2b3340")
	for p in [Vector3(-0.8, 0, -0.8), Vector3(0.8, 0, -0.8), Vector3(-0.8, 0, 0.8), Vector3(0.8, 0, 0.8)]:
		box(r, Vector3(0.1, 1.9, 0.1), p + Vector3(0, 0.95, 0), Color("2b2f36"), Vector3.ZERO, null, 0.02)
	for y in [0.05, 1.9]:
		box(r, Vector3(1.7, 0.1, 0.1), Vector3(0, y, -0.8), Color("2b2f36"))
		box(r, Vector3(0.1, 0.1, 1.7), Vector3(-0.8, y, 0), Color("2b2f36"))
		box(r, Vector3(0.1, 0.1, 1.7), Vector3(0.8, y, 0), Color("2b2f36"))
		box(r, Vector3(1.7, 0.1, 0.1), Vector3(0, y, 0.8), Color("2b2f36"))
	box(r, Vector3(1.6, 1.8, 0.05), Vector3(0, 1.0, -0.8), smoke, Vector3.ZERO, gloss(smoke, 0.0, 0.55, 0.08), 0.0)
	box(r, Vector3(0.05, 1.8, 1.6), Vector3(-0.8, 1.0, 0), smoke, Vector3.ZERO, gloss(smoke, 0.0, 0.5, 0.08), 0.0)
	box(r, Vector3(0.05, 1.8, 1.6), Vector3(0.8, 1.0, 0), smoke, Vector3.ZERO, gloss(smoke, 0.0, 0.4, 0.08), 0.0)
	for i in 3:
		box(r, Vector3(0.1, 0.2, 0.12), Vector3(-0.8, 0.5 + i * 0.5, 0.78), BRASS)
	box(r, Vector3(0.6, 0.5, 0.5), Vector3(0, 0.3, -0.2), ORANGE, Vector3(0, 20, 0), null, 0.06)


func _laser_gear() -> void:
	var r := group(-14.0)
	box(r, Vector3(0.9, 0.7, 0.7), Vector3(0, 0.7, 0), Color("2b3038"), Vector3.ZERO, null, 0.07)
	for i in 7:
		box(r, Vector3(0.9, 0.04, 0.5), Vector3(0, 0.38 - i * 0.0, 0.0), Color("3a424d")) if i == 0 else null
		box(r, Vector3(0.06, 0.5, 0.74), Vector3(-0.4 + i * 0.13, 0.7, 0), Color("4a5562"))
	cyl(r, 0.2, 0.2, 0.5, Vector3(0.7, 0.7, 0), BRASS, Vector3(0, 0, 90), 28, metal_mat(BRASS))
	cyl(r, 0.14, 0.14, 0.05, Vector3(1.0, 0.7, 0), Color("bfe9f3"), Vector3(0, 0, 90), 28, gloss(Color("bfe9f3"), 0.0, 0.5, 0.05))
	cyl(r, 0.04, 0.04, 1.2, Vector3(1.6, 0.7, 0), Color("ff3a3a"), Vector3(0, 0, 90), 12, gloss(Color("ff3a3a"), 5.0))
	glow(r, 0.1, Vector3(2.2, 0.7, 0), Color("ff7a7a"), 4.0)
	glow(r, 0.04, Vector3(-0.2, 1.08, 0.3), GREEN, 3.0)


func _corexy() -> void:
	var r := group(-18.0)
	var ext := Color("2b2f36")
	var h := 1.7
	for x in [-0.9, 0.9]:
		for z in [-0.9, 0.9]:
			box(r, Vector3(0.12, h, 0.12), Vector3(x, h * 0.5, z), ext, Vector3.ZERO, null, 0.02)
	for y in [0.06, h]:
		for s in [-0.9, 0.9]:
			box(r, Vector3(1.9, 0.12, 0.12), Vector3(0, y, s), ext, Vector3.ZERO, null, 0.02)
			box(r, Vector3(0.12, 0.12, 1.9), Vector3(s, y, 0), ext, Vector3.ZERO, null, 0.02)
	for i in 8:
		box(r, Vector3(0.14, 0.1, 0.14), Vector3(-0.9 if i % 2 == 0 else 0.9, 0.06 + int(i / 2) * 0.55, -0.9 if int(i / 2) % 2 == 0 else 0.9), BRASS)
	stick(r, Vector3(-0.85, h, -0.85), Vector3(0.85, h, 0.85), 0.02, Color("e9a91c"))
	stick(r, Vector3(0.85, h, -0.85), Vector3(-0.85, h, 0.85), 0.02, Color("e9a91c"))
	box(r, Vector3(0.5, 0.18, 0.5), Vector3(0.0, h - 0.2, 0.0), BLUE, Vector3.ZERO, null, 0.05)
	cyl(r, 0.1, 0.02, 0.3, Vector3(0, h - 0.45, 0), BRASS, Vector3.ZERO, 20, metal_mat(BRASS))
	glow(r, 0.05, Vector3(0, h - 0.62, 0), ORANGE, 3.5)
	box(r, Vector3(1.4, 0.06, 1.4), Vector3(0, 0.35, 0), DARK, Vector3.ZERO, null, 0.02)


# -------------------------------------------------------------- creatures
# Each stands on y = 0 and faces +Z; _beast_root is the creature's own root.

func _snail() -> void:
	var c := _beast_root
	var skin := Color("7bd0a3")
	ball(c, 0.42, Vector3(0, 0.3, 0.1), skin, Vector3(0.95, 0.62, 2.2))
	ball(c, 0.3, Vector3(0, 0.55, 1.0), skin, Vector3(0.95, 1.1, 1.0))
	var s := spool_body(c, Vector3(0, 1.0, -0.2), 0.78, 0.6, [Color("ff7a3a"), Color("ffb02e"), Color("ff7a3a"), Color("ffd36a")], Vector3(0, 0, 90))
	torus(c, 0.34, 0.05, Vector3(0.62, 1.0, -0.2), Color("2b3038"), Vector3(0, 0, 90))
	for sx in [-1.0, 1.0]:
		stick(c, Vector3(sx * 0.12, 0.75, 1.0), Vector3(sx * 0.2, 1.3, 1.15), 0.035, skin)
		eyes_single(c, Vector3(sx * 0.2, 1.36, 1.17), 0.11)
	box(c, Vector3(0.18, 0.03, 0.03), Vector3(0, 0.5, 1.28), Color("1c2a24"))
	strand(c, Vector3(-0.5, 1.3, -0.4), Vector3(-1.0, 0.6, -0.4), 0.8, Color("ffb02e"), 3.0, 0.035)


func _treant() -> void:
	var c := _beast_root
	var bark := Color("c9b48a")
	var leaf := Color("69cf62")
	cyl(c, 0.38, 0.28, 1.0, Vector3(0, 0.75, 0), bark, Vector3.ZERO, 24)
	for s in [-1.0, 1.0]:
		leg(c, Vector3(s * 0.22, 0.3, 0.05), Vector3(s * 0.4, 0.05, 0.25), 0.1, bark.darkened(0.1))
	eyes(c, Vector3(0, 0.95, 0.27), 0.15, 0.11)
	box(c, Vector3(0.2, 0.03, 0.03), Vector3(0, 0.72, 0.32), Color("3a2a1a"))
	var tips: Array = []
	var branch := func(self_ref: Callable, a: Vector3, dir: Vector3, len: float, depth: int, seed_v: float) -> void:
		var b: Vector3 = a + dir * len
		stick(c, a, b, 0.07 * (depth + 1) * 0.55 + 0.025, bark if depth > 1 else bark.lightened(0.1))
		ball(c, 0.035 + depth * 0.012, b, bark)
		if depth == 0:
			cyl(c, 0.1, 0.1, 0.03, b + Vector3(0, 0.02, 0), leaf, Vector3.ZERO, 16)
			return
		for k in 3:
			var ang := seed_v + k * 2.1
			var nd := (dir + Vector3(cos(ang) * 0.7, 0.35, sin(ang) * 0.7)).normalized()
			self_ref.call(self_ref, b, nd, len * 0.62, depth - 1, seed_v + k * 1.3 + depth)
	branch.call(branch, Vector3(0, 1.2, 0), Vector3.UP, 0.8, 3, 0.4)


func _colossus() -> void:
	var c := _beast_root
	var cols := [Color("ff4d4d"), Color("ff9a3a"), Color("ffd83a"), Color("5ddc6a"), Color("3aa8ff"), Color("a56bff")]
	var s := spool_body(c, Vector3(0, 1.45, 0), 1.0, 0.95, cols, Vector3(90, 0, 0))
	cyl(c, 0.52, 0.52, 0.04, Vector3(0, 1.45, 0.5), Color("1c2128"), Vector3(90, 0, 0), 32)
	for i in 6:
		torus(c, 0.58 + i * 0.07, 0.035, Vector3(0, 1.45, 0.52), cols[i], Vector3(90, 0, 0))
	eyes(c, Vector3(0, 1.75, 0.54), 0.3, 0.17, 0.0)
	box(c, Vector3(0.5, 0.05, 0.04), Vector3(0, 1.12, 0.52), Color("1c2128"))
	for sx in [-1.0, 1.0]:
		cyl(c, 0.22, 0.2, 0.7, Vector3(sx * 0.5, 0.38, 0.1), Color("3a424d"), Vector3.ZERO, 24)
		ball(c, 0.26, Vector3(sx * 0.5, 0.1, 0.22), Color("3a424d"), Vector3(1.2, 0.5, 1.5))
		stick(c, Vector3(sx * 1.0, 1.5, 0.0), Vector3(sx * 1.45, 0.95, 0.35), 0.1, Color("3a424d"))
		ball(c, 0.2, Vector3(sx * 1.5, 0.88, 0.4), cols[(2 if sx < 0 else 4)])
	strand(c, Vector3(0.9, 0.95, -0.5), Vector3(1.0, -0.4, -0.2), 1.0, cols[3], 8.0, 0.05)


func _chillfan() -> void:
	var c := _beast_root
	var ice := Color("8fd8ff")
	box(c, Vector3(1.25, 1.25, 0.32), Vector3(0, 0.95, 0), Color("3f7fb5"), Vector3.ZERO, null, 0.12)
	cyl(c, 0.52, 0.52, 0.36, Vector3(0, 0.95, 0.02), Color("1a3550"), Vector3(90, 0, 0), 40)
	for i in 7:
		var a := i * TAU / 7.0
		var bl := box(c, Vector3(0.6, 0.3, 0.05), Vector3(cos(a) * 0.34, 0.95 + sin(a) * 0.34, 0.12), ice, Vector3(35, 0, rad_to_deg(a)), gloss(ice, 0.25, 0.8, 0.05), 0.01)
	cyl(c, 0.2, 0.2, 0.2, Vector3(0, 0.95, 0.2), Color("dff3ff"), Vector3(90, 0, 0), 32)
	eyes(c, Vector3(0, 0.97, 0.34), 0.1, 0.075)
	for sx in [-0.55, 0.55]:
		for sy in [0.4, 1.5]:
			cyl(c, 0.05, 0.05, 0.06, Vector3(sx, sy, 0.17), STEEL, Vector3(90, 0, 0), 12, metal_mat(STEEL))
	for s in [-1.0, 1.0]:
		leg(c, Vector3(s * 0.35, 0.3, 0.0), Vector3(s * 0.45, 0.05, 0.15), 0.07, Color("3f7fb5"))
	for i in 6:
		glow(c, 0.04, Vector3(-0.8 + fmod(i * 0.37, 1.6), 0.3 + fmod(i * 0.53, 1.6), 0.4 + fmod(i * 0.19, 0.3)), Color("e8f8ff"), 2.5)


func _beetle() -> void:
	var c := _beast_root
	var yel := Color("f2c230")
	box(c, Vector3(0.95, 1.2, 0.42), Vector3(0, 0.95, 0), yel, Vector3.ZERO, null, 0.1)
	box(c, Vector3(0.7, 0.4, 0.06), Vector3(0, 1.35, 0.22), Color("143020"))
	eyes(c, Vector3(0, 1.36, 0.27), 0.16, 0.1, 0.1)
	cyl(c, 0.24, 0.24, 0.1, Vector3(0, 0.82, 0.26), Color("2b3038"), Vector3(90, 0, 0), 32)
	box(c, Vector3(0.05, 0.2, 0.03), Vector3(0, 0.88, 0.33), WHITE, Vector3(0, 0, 30))
	for i in 3:
		cyl(c, 0.07, 0.07, 0.04, Vector3(-0.28 + i * 0.28, 0.5, 0.24), [RED, DARK, Color("a0a6ae")][i], Vector3(90, 0, 0), 20)
	for s in [-1.0, 1.0]:
		var col: Color = RED if s > 0 else DARK
		stick(c, Vector3(s * 0.2, 1.55, 0.0), Vector3(s * 0.45, 1.95, 0.2), 0.04, col)
		cone(c, Vector3(s * 0.45, 1.95, 0.2), Vector3(s * 0.55, 2.2, 0.28), 0.06, STEEL)
		for k in 3:
			var z := 0.18 - k * 0.18
			var knee := Vector3(s * 0.8, 0.55 + 0.1 * k, z)
			stick(c, Vector3(s * 0.45, 0.6 + 0.05 * k, z), knee, 0.045, col if k != 1 else Color("2b3038"))
			stick(c, knee, Vector3(s * 0.95, 0.04, z + 0.1), 0.045, col if k != 1 else Color("2b3038"))
	for i in 5:
		glow(c, 0.03, Vector3(-0.45 + i * 0.22, 0.2, 0.25), Color("ffe36a"), 2.5)


func _jelly() -> void:
	var c := _beast_root
	var orange := Color("ff9a3a")
	var dome := ball(c, 0.72, Vector3(0, 1.4, 0), orange, Vector3(1.0, 0.85, 1.0))
	dome.material_override = gloss(orange, 0.55, 0.62, 0.06)
	for i in 6:
		var a := i * 1.05
		glow(c, 0.07 + (i % 3) * 0.03, Vector3(cos(a) * 0.3, 1.35 + sin(a * 2.0) * 0.2, sin(a) * 0.3), Color("ffd58a"), 1.4)
	glow(c, 0.16, Vector3(0, 1.45, -0.05), Color("a56bff"), 2.2)
	eyes(c, Vector3(0, 1.45, 0.6), 0.22, 0.14, 0.0)
	for i in 9:
		var a := i * TAU / 9.0
		strand(c, Vector3(cos(a) * 0.5, 1.0, sin(a) * 0.5), Vector3(cos(a) * 0.3, -1.0, sin(a) * 0.3), 1.1, orange.lightened(0.15), float(i) * 1.7, 0.05)
	torus(c, 0.7, 0.04, Vector3(0, 1.02, 0), Color("ffd58a"), Vector3.ZERO, gloss(Color("ffd58a"), 1.0, 0.8, 0.1))


func _drone() -> void:
	var c := _beast_root
	var mint := Color("9fe8d2")
	ball(c, 0.4, Vector3(0, 1.0, 0), mint, Vector3(1.1, 0.8, 1.1))
	eyes(c, Vector3(0, 1.02, 0.36), 0.18, 0.15, 0.0)
	ball(c, 0.08, Vector3(0, 0.78, 0.4), Color("1c2128"))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tip := Vector3(sx * 0.95, 1.15, sz * 0.8)
			stick(c, Vector3(sx * 0.25, 1.0, sz * 0.2), tip, 0.06, Color("f2f6f8"))
			cyl(c, 0.07, 0.07, 0.14, tip, DARK, Vector3.ZERO, 16)
			torus(c, 0.42, 0.03, tip + Vector3(0, 0.12, 0), Color("f2f6f8"), Vector3.ZERO)
			box(c, Vector3(0.78, 0.015, 0.1), tip + Vector3(0, 0.12, 0), Color("c8d0d8"), Vector3(0, 25 + sx * sz * 40, 0), gloss(Color("c8d0d8"), 0.0, 0.55, 0.05), 0.0)
	for sx in [-1.0, 1.0]:
		stick(c, Vector3(sx * 0.25, 0.8, 0.0), Vector3(sx * 0.35, 0.18, 0.0), 0.04, Color("2b3038"))
		stick(c, Vector3(sx * 0.35, 0.18, -0.5), Vector3(sx * 0.35, 0.18, 0.5), 0.04, Color("2b3038"))


func _hog() -> void:
	var c := _beast_root
	var steel := Color("aab2bc")
	var nut := cyl(c, 0.7, 0.7, 0.55, Vector3(0, 0.85, 0), steel, Vector3(90, 0, 0), 6, metal_mat(steel))
	cyl(c, 0.34, 0.34, 0.6, Vector3(0, 0.85, 0.0), Color("1c2128"), Vector3(90, 0, 0), 24)
	for i in 4:
		torus(c, 0.34, 0.025, Vector3(0, 0.85, 0.22 - i * 0.14), Color("5a626c"), Vector3(90, 0, 0))
	cyl(c, 0.26, 0.26, 0.5, Vector3(0, 0.62, 0.55), COPPER, Vector3(90, 0, 0), 24, metal_mat(COPPER))
	cyl(c, 0.3, 0.3, 0.1, Vector3(0, 0.62, 0.82), COPPER, Vector3(90, 0, 0), 24, metal_mat(COPPER))
	for s in [-1.0, 1.0]:
		ball(c, 0.05, Vector3(s * 0.08, 0.62, 0.89), Color("2b1a10"))
	eyes(c, Vector3(0, 1.3, 0.3), 0.3, 0.14, 0.0)
	for s in [-1.0, 1.0]:
		torus(c, 0.2, 0.06, Vector3(s * 0.45, 1.5, 0.0), steel.darkened(0.1), Vector3(30, 0, s * 20), metal_mat(steel.darkened(0.1)))
		cyl(c, 0.1, 0.1, 0.3, Vector3(s * 0.4, 0.2, 0.3), COPPER, Vector3.ZERO, 6, metal_mat(COPPER))
		cyl(c, 0.1, 0.1, 0.3, Vector3(s * 0.4, 0.2, -0.3), COPPER, Vector3.ZERO, 6, metal_mat(COPPER))


func _gcode() -> void:
	var c := _beast_root
	var violet := Color("7a5fd0")
	var term := Color("5dff9e")
	box(c, Vector3(0.9, 0.7, 0.8), Vector3(0, 0.35, 0), violet.darkened(0.1), Vector3.ZERO, null, 0.08)
	box(c, Vector3(0.75, 0.62, 0.7), Vector3(0, 1.0, 0), violet, Vector3.ZERO, null, 0.08)
	box(c, Vector3(0.62, 0.55, 0.58), Vector3(0, 1.55, 0), violet.lightened(0.1), Vector3.ZERO, null, 0.08)
	label(c, "G1", 28, Vector3(-0.2, 0.3, 0.41), term)
	label(c, "X0", 24, Vector3(-0.18, 0.95, 0.36), term)
	label(c, "Z.2", 18, Vector3(-0.2, 1.4, 0.3), Color("a9ffd0"))
	box(c, Vector3(0.5, 0.2, 0.04), Vector3(0, 1.65, 0.3), Color("0c1812"))
	eyes(c, Vector3(0, 1.66, 0.34), 0.14, 0.085, 0.1)
	for s in [-1.0, 1.0]:
		box(c, Vector3(0.3, 0.3, 0.3), Vector3(s * 0.72, 0.95, 0.1), violet.lightened(0.05), Vector3(0, 0, s * 12), null, 0.05)
		box(c, Vector3(0.22, 0.22, 0.22), Vector3(s * 0.84, 0.55, 0.22), violet.darkened(0.05), Vector3(0, 0, s * 20), null, 0.04)
		box(c, Vector3(0.32, 0.22, 0.4), Vector3(s * 0.3, 0.08, 0.1), violet.darkened(0.25), Vector3.ZERO, null, 0.04)
	for i in 6:
		glow(c, 0.035, Vector3(-0.5 + i * 0.2, 2.0 + fmod(i * 0.37, 0.3), 0.0), term, 3.0)


func _hedgehog() -> void:
	var c := _beast_root
	var dark := Color("5a2230")
	ball(c, 0.72, Vector3(0, 0.7, -0.1), dark, Vector3(1.0, 0.85, 1.25))
	for i in 54:
		var a := i * 2.399
		var up := 0.25 + fmod(i * 0.173, 0.75)
		var dir := Vector3(cos(a) * (1.0 - up * 0.6), up, sin(a) * (1.0 - up * 0.6) - 0.15).normalized()
		var base := Vector3(0, 0.7, -0.1) + dir * Vector3(0.68, 0.6, 0.85)
		cone(c, base, base + dir * 0.42, 0.045, Color("d8dde3"), metal_mat(Color("d8dde3")))
		if i % 3 == 0:
			glow(c, 0.035, base + dir * 0.44, Color("ff8a2a"), 3.5)
	ball(c, 0.38, Vector3(0, 0.5, 0.78), Color("e8a07a"), Vector3(0.95, 0.9, 1.1))
	eyes(c, Vector3(0, 0.65, 1.05), 0.15, 0.1, 0.1)
	ball(c, 0.06, Vector3(0, 0.5, 1.16), Color("2b1a10"))
	for sx in [-1.0, 1.0]:
		leg(c, Vector3(sx * 0.4, 0.3, 0.4), Vector3(sx * 0.5, 0.05, 0.55), 0.09, Color("e8a07a"))
		leg(c, Vector3(sx * 0.4, 0.3, -0.5), Vector3(sx * 0.5, 0.05, -0.55), 0.09, Color("e8a07a"))
	glow(c, 0.5, Vector3(0, 0.1, -0.1), Color("ff7a2a"), 1.0).scale = Vector3(1.4, 0.06, 1.7)
