extends "res://tools/render_art.gd"
## Third wave of card art: 27 tools (on the print bed) and 20 pieces of
## equipment (cut out on a transparent background).
##
##   godot --path . --disable-vsync -s tools/render_art3.gd              (all)
##   godot --path . --disable-vsync -s tools/render_art3.gd -- kiln       (just some)

const ARMOR_OUT := "res://assets/armor/raw/%s_raw_print_alpha_v2.png"
const STEEL := Color("b9c2cc")
const WOOD := Color("b07a46")
const CREAM := Color("efe3c4")
const PINK := Color("f06aa8")


func _initialize() -> void:
	var only: Array = Array(OS.get_cmdline_user_args())
	await process_frame
	_build_studio()
	await process_frame
	var tools := {
		"zip_ties": [_zip_ties, 40.0, 4.8, 0.2], "sandpaper": [_sandpaper, 40.0, 4.6, 0.3], "masking_tape": [_tape, 36.0, 4.8, 0.4],
		"nozzle_brush": [_brush, 50.0, 4.6, 0.1], "needle_pliers": [_pliers.bind(RED, true), 52.0, 4.6, 0.1], "iso_wipes": [_wipes, 32.0, 5.0, 0.7],
		"heat_block": [_heat_block, 32.0, 4.8, 0.5], "hot_plate": [_hot_plate, 34.0, 5.0, 0.4], "desiccant_packs": [_packs, 44.0, 4.8, 0.2],
		"digital_scale": [_scale_tool, 34.0, 4.9, 0.4], "flush_cutters": [_pliers.bind(BLUE, false), 52.0, 4.6, 0.1], "print_remover": [_spatula, 52.0, 4.6, 0.1],
		"cooling_spray": [_spray, 28.0, 5.2, 0.9], "soldering_station": [_station, 34.0, 5.0, 0.5], "torque_wrench": [_torque, 52.0, 5.0, 0.1],
		"laser_level": [_laser, 32.0, 5.0, 0.4], "multimeter": [_meter, 38.0, 5.0, 0.4], "wash_station": [_wash, 28.0, 5.4, 0.8],
		"color_change": [_rainbow_spool, 26.0, 5.2, 0.9], "plasma_cutter": [_plasma, 36.0, 5.0, 0.7], "hot_swap": [_swap, 34.0, 5.0, 0.6],
		"kiln": [_kiln, 26.0, 5.6, 0.9], "overclock_kit": [_chip.bind(true), 44.0, 5.0, 0.3], "bulk_order": [_boxes, 30.0, 5.8, 0.9],
		"print_farm": [_farm, 34.0, 6.2, 0.7], "mega_spool": [_mega_spool, 24.0, 6.2, 1.1], "master_slicer": [_slicer, 30.0, 5.8, 0.8],
	}
	var gear := {
		"rubber_feet": [_feet, 20.0, 7.2, 0.4], "mini_fan": [_mini_fan, 8.0, 5.0, 1.0], "spool_holder": [_holder_bracket, 16.0, 5.6, 0.8],
		"cable_chain": [_chain, 24.0, 6.8, 0.8], "nozzle_guard": [_guard, 14.0, 5.4, 0.8], "heat_sink": [_sink, 18.0, 5.0, 0.7],
		"grappling_hook": [_hook, 14.0, 8.0, 1.4], "carbon_plate": [_carbon, 12.0, 5.4, 0.8], "servo_arms": [_servo, 14.0, 6.0, 1.0],
		"turbo_fan": [_turbo, 8.0, 5.2, 1.0], "silk_cape": [_cape, 8.0, 6.0, 1.1], "spiked_gauntlets": [_gauntlet, 18.0, 6.6, 1.1],
		"thermal_core": [_core, 14.0, 5.0, 1.0], "overdrive_chip": [_chip.bind(false), 40.0, 5.2, 0.3], "exo_frame": [_exo, 10.0, 8.2, 1.6],
		"phoenix_wings": [_phoenix, 8.0, 6.4, 1.1], "vampire_fangs": [_fangs, 14.0, 5.0, 0.6], "quad_nozzle": [_quad, 22.0, 5.0, 0.6],
		"titan_exosuit": [_titan, 10.0, 8.2, 1.7], "omega_core": [_omega, 12.0, 5.8, 1.0],
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


func glow(parent: Node3D, r: float, pos: Vector3, col: Color, energy := 2.5) -> MeshInstance3D:
	var n := ball(parent, r, pos, col)
	n.material_override = gloss(col, energy)
	return n


# ------------------------------------------------------------------ tools

func _zip_ties() -> void:
	var r := group(-20.0)
	for i in 4:
		var c := Vector3(-0.9 + i * 0.6, 0.0, sin(i * 1.7) * 0.5)
		torus(r, 0.3, 0.035, c + Vector3(0, 0.3, 0), WHITE if i % 2 == 0 else Color("2b3038"), Vector3(80, i * 25.0, 0))
		box(r, Vector3(0.14, 0.12, 0.16), c + Vector3(0.28, 0.3, 0.0), WHITE if i % 2 == 0 else Color("2b3038"), Vector3(0, 0, i * 20.0), null, 0.03)
		box(r, Vector3(0.7, 0.025, 0.06), c + Vector3(0.4, 0.04, 0.5), WHITE if i % 2 == 0 else Color("2b3038"), Vector3(0, i * 30.0, 0), null, 0.01)


func _sandpaper() -> void:
	var r := group(-18.0)
	box(r, Vector3(0.9, 0.5, 0.5), Vector3(-0.7, 0.25, -0.2), WOOD, Vector3(0, 8, 0), null, 0.08)
	for i in 3:
		var sheet := box(r, Vector3(1.4, 0.03, 0.95), Vector3(0.25 + i * 0.1, 0.03 + i * 0.045, 0.2 - i * 0.12), Color("d9b46a").darkened(i * 0.12), Vector3(0, -10 + i * 9.0, 0), null, 0.01)
		sheet.material_override = mat(Color("d9b46a").darkened(i * 0.12), 0.012, Vector3.UP, 0.9, 1.4)


func _tape() -> void:
	var r := group(0.0)
	torus(r, 0.62, 0.28, Vector3(0, 0.3, 0), CREAM, Vector3(0, 0, 0), mat(CREAM, 0.02, Vector3.UP, 0.5, 0.5))
	torus(r, 0.4, 0.05, Vector3(0, 0.3, 0), WHITE)
	box(r, Vector3(0.9, 0.025, 0.4), Vector3(0.95, 0.03, 0.25), CREAM, Vector3(0, 20, 0), null, 0.01)
	box(r, Vector3(0.5, 0.025, 0.4), Vector3(0.5, 0.18, 0.55), CREAM, Vector3(15, 25, 0), null, 0.01)


func _brush() -> void:
	var r := group(-30.0)
	cyl(r, 0.14, 0.12, 1.5, Vector3(-0.5, 0.15, 0), WOOD, Vector3(0, 0, 90), 24)
	cyl(r, 0.19, 0.19, 0.25, Vector3(0.35, 0.15, 0), BRASS, Vector3(0, 0, 90), 24)
	for i in 70:
		var a := i * 2.399
		var rad := sqrt(fmod(i * 0.618, 1.0)) * 0.15
		stick(r, Vector3(0.45, 0.15 + cos(a) * rad, sin(a) * rad), Vector3(0.9 + 0.05 * sin(i), 0.15 + cos(a) * rad * 1.5, sin(a) * rad * 1.5), 0.012, Color("c9b273"))


func _pliers(col: Color, pointed: bool) -> void:
	var r := group(-25.0)
	for s in [-1.0, 1.0]:
		box(r, Vector3(1.5, 0.12, 0.2), Vector3(-0.8, 0.1, s * 0.22), col, Vector3(0, -s * 7, 0), null, 0.05)
		box(r, Vector3(1.0 if pointed else 0.7, 0.1, 0.16 if pointed else 0.28), Vector3(0.5 if pointed else 0.35, 0.1, s * 0.06), STEEL, Vector3(0, s * (-4 if pointed else -12), 0), null, 0.03)
	cyl(r, 0.14, 0.14, 0.2, Vector3(-0.05, 0.12, 0), BRASS, Vector3.ZERO, 20)


func _wipes() -> void:
	var r := group(-10.0)
	cyl(r, 0.6, 0.6, 0.9, Vector3(0, 0.45, 0), WHITE, Vector3.ZERO, 40)
	cyl(r, 0.62, 0.62, 0.22, Vector3(0, 0.96, 0), BLUE, Vector3.ZERO, 40)
	cyl(r, 0.45, 0.45, 0.04, Vector3(0, 1.08, 0), DARK, Vector3.ZERO, 32)
	cyl(r, 0.605, 0.605, 0.4, Vector3(0, 0.45, 0), BLUE, Vector3.ZERO, 40)
	for i in 3:
		box(r, Vector3(0.45, 0.02, 0.45), Vector3(0.0 + i * 0.05, 1.2 + i * 0.08, 0.0), WHITE, Vector3(i * 14, i * 25.0, i * 8), null, 0.01)


func _heat_block() -> void:
	var r := group(-28.0)
	box(r, Vector3(0.9, 0.7, 0.7), Vector3(0, 0.38, 0), BRASS, Vector3.ZERO, metal_mat(BRASS), 0.1)
	cyl(r, 0.1, 0.1, 1.2, Vector3(0, 0.45, 0), RED, Vector3(0, 0, 90), 20)
	cyl(r, 0.13, 0.02, 0.5, Vector3(0, -0.12, 0), BRASS, Vector3.ZERO, 24, metal_mat(BRASS))
	glow(r, 0.09, Vector3(0.0, 0.7, 0.36), ORANGE, 3.0)
	for i in 2:
		stick(r, Vector3(-0.6, 0.45, 0), Vector3(-1.3, 0.1, -0.4 + i * 0.5), 0.04, RED if i else DARK)


func metal_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.85
	m.roughness = 0.32
	return m


func _hot_plate() -> void:
	var r := group(-15.0)
	cyl(r, 0.9, 0.95, 0.22, Vector3(0, 0.15, 0), DARK, Vector3.ZERO, 48)
	cyl(r, 0.8, 0.8, 0.06, Vector3(0, 0.3, 0), Color("4a5260"), Vector3.ZERO, 48, metal_mat(Color("4a5260")))
	for i in 4:
		var t := torus(r, 0.18 + i * 0.17, 0.035, Vector3(0, 0.35, 0), ORANGE, Vector3.ZERO)
		t.material_override = gloss(Color("ff7a1a"), 2.2)
	box(r, Vector3(0.3, 0.18, 0.12), Vector3(0.6, 0.12, 0.92), RED, Vector3.ZERO, null, 0.04)
	glow(r, 0.05, Vector3(0.6, 0.23, 1.0), GREEN, 3.0)


func _packs() -> void:
	var r := group(-20.0)
	for i in 3:
		box(r, Vector3(0.7, 0.14, 0.5), Vector3(-0.6 + i * 0.5, 0.1 + i * 0.12, -0.3 + i * 0.35), WHITE, Vector3(0, -15 + i * 18.0, 0), null, 0.07)
		box(r, Vector3(0.3, 0.145, 0.12), Vector3(-0.6 + i * 0.5, 0.1 + i * 0.12, -0.3 + i * 0.35), BLUE, Vector3(0, -15 + i * 18.0, 0), null, 0.03)
	for i in 14:
		var a := i * 2.4
		glow(r, 0.05, Vector3(sin(a) * 1.0 + 0.4, 0.05, cos(a * 1.3) * 0.7 + 0.5), BLUE, 0.6)


func _scale_tool() -> void:
	var r := group(-24.0)
	box(r, Vector3(1.6, 0.2, 1.1), Vector3(0, 0.12, 0), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.1)
	box(r, Vector3(0.6, 0.04, 0.26), Vector3(0.3, 0.24, 0.42), DARK, Vector3.ZERO, gloss(Color("0b2a14"), 0.0, 1.0, 0.1), 0.02)
	box(r, Vector3(0.45, 0.02, 0.16), Vector3(0.3, 0.27, 0.42), GREEN, Vector3.ZERO, gloss(Color("5cff7a"), 1.4), 0.01)
	cyl(r, 0.2, 0.2, 0.12, Vector3(-0.3, 0.3, -0.1), BRASS, Vector3.ZERO, 32, metal_mat(BRASS))
	cyl(r, 0.1, 0.1, 0.1, Vector3(-0.3, 0.4, -0.1), BRASS, Vector3.ZERO, 24, metal_mat(BRASS))


func _spatula() -> void:
	var r := group(-35.0)
	box(r, Vector3(1.5, 0.04, 0.55), Vector3(0.5, 0.06, 0), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.02)
	box(r, Vector3(0.3, 0.05, 0.55), Vector3(1.3, 0.05, 0), STEEL, Vector3(0, 0, -3), metal_mat(STEEL), 0.01)
	cyl(r, 0.1, 0.1, 0.9, Vector3(-0.7, 0.12, 0), WOOD, Vector3(0, 0, 90), 24)
	box(r, Vector3(0.35, 0.16, 0.2), Vector3(-0.2, 0.1, 0), DARK, Vector3.ZERO, null, 0.05)


func _spray() -> void:
	var r := group(-10.0)
	cyl(r, 0.4, 0.4, 1.4, Vector3(0, 0.7, 0), WHITE, Vector3.ZERO, 40)
	cyl(r, 0.405, 0.405, 0.5, Vector3(0, 0.55, 0), TEAL, Vector3.ZERO, 40)
	cyl(r, 0.38, 0.3, 0.3, Vector3(0, 1.5, 0), STEEL, Vector3.ZERO, 40, metal_mat(STEEL))
	cyl(r, 0.14, 0.14, 0.25, Vector3(0, 1.75, 0), RED, Vector3.ZERO, 20)
	box(r, Vector3(0.2, 0.06, 0.1), Vector3(0.2, 1.8, 0), RED, Vector3.ZERO, null, 0.02)
	for i in 7:
		var m := ball(r, 0.1 + 0.03 * (i % 3), Vector3(0.7 + i * 0.22, 1.65 + sin(i * 2.0) * 0.18, 0.1 * sin(i)), WHITE)
		m.material_override = gloss(Color("dff6ff"), 0.4, 0.55)


func _station() -> void:
	var r := group(-25.0)
	box(r, Vector3(1.6, 0.35, 1.1), Vector3(0, 0.2, 0), DARK, Vector3.ZERO, null, 0.1)
	box(r, Vector3(0.5, 0.05, 0.3), Vector3(-0.4, 0.4, 0.3), Color("0b2a14"), Vector3(-30, 0, 0), gloss(Color("0b2a14"), 0, 1.0, 0.1), 0.02)
	box(r, Vector3(0.38, 0.03, 0.18), Vector3(-0.4, 0.42, 0.3), GREEN, Vector3(-30, 0, 0), gloss(Color("5cff7a"), 1.4), 0.01)
	cyl(r, 0.12, 0.12, 0.1, Vector3(0.2, 0.4, 0.35), RED, Vector3.ZERO, 20)
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.12, 0.7, 0.12), Vector3(0.45 + s * 0.2, 0.7, -0.3), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.03)
	cyl(r, 0.05, 0.05, 1.3, Vector3(0.5, 1.0, -0.3), DARK, Vector3(0, 0, 70), 16)
	glow(r, 0.06, Vector3(1.05, 0.75, -0.3), ORANGE, 3.0)
	cyl(r, 0.25, 0.25, 0.08, Vector3(-0.1, 0.4, -0.2), YELLOW, Vector3.ZERO, 20)


func _torque() -> void:
	var r := group(-30.0)
	box(r, Vector3(2.0, 0.12, 0.2), Vector3(0, 0.1, 0), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.05)
	cyl(r, 0.18, 0.18, 0.2, Vector3(1.15, 0.1, 0), STEEL, Vector3.ZERO, 6, metal_mat(STEEL))
	cyl(r, 0.28, 0.28, 0.14, Vector3(1.15, 0.1, 0), STEEL, Vector3.ZERO, 32, metal_mat(STEEL))
	cyl(r, 0.14, 0.14, 0.7, Vector3(-0.85, 0.1, 0), RED, Vector3(0, 0, 90), 24)
	box(r, Vector3(0.34, 0.1, 0.12), Vector3(0.2, 0.18, 0), YELLOW, Vector3.ZERO, null, 0.03)
	for i in 5:
		box(r, Vector3(0.02, 0.05, 0.14), Vector3(-0.1 + i * 0.1, 0.17, 0), DARK, Vector3.ZERO, null, 0.0)


func _laser() -> void:
	var r := group(-25.0)
	box(r, Vector3(1.0, 0.7, 0.8), Vector3(0, 0.38, 0), ORANGE, Vector3.ZERO, null, 0.15)
	cyl(r, 0.1, 0.1, 0.15, Vector3(0.55, 0.45, 0), DARK, Vector3(0, 0, 90), 20)
	var beam := box(r, Vector3(3.2, 0.03, 0.03), Vector3(2.2, 0.45, 0), RED, Vector3.ZERO, gloss(Color("ff2a2a"), 4.0), 0.0)
	beam.name = "beam"
	cyl(r, 0.12, 0.12, 0.08, Vector3(0, 0.78, 0), DARK, Vector3.ZERO, 20)
	glow(r, 0.05, Vector3(0.1, 0.78, 0.0), GREEN, 3.0)
	box(r, Vector3(0.7, 0.08, 0.5), Vector3(0, 0.04, 0), DARK, Vector3.ZERO, null, 0.03)


func _meter() -> void:
	var r := group(-22.0)
	box(r, Vector3(1.0, 0.25, 1.7), Vector3(0, 0.2, 0), YELLOW, Vector3.ZERO, null, 0.14)
	box(r, Vector3(0.78, 0.03, 0.55), Vector3(0, 0.34, -0.45), Color("0b2a14"), Vector3.ZERO, gloss(Color("c9ffd6"), 0.5, 1.0, 0.1), 0.02)
	cyl(r, 0.28, 0.28, 0.08, Vector3(0, 0.36, 0.25), DARK, Vector3.ZERO, 32)
	box(r, Vector3(0.05, 0.03, 0.22), Vector3(0.0, 0.42, 0.14), RED, Vector3(0, 40, 0), null, 0.0)
	for i in 2:
		cyl(r, 0.07, 0.07, 0.1, Vector3(-0.2 + i * 0.4, 0.28, 0.75), RED if i else DARK, Vector3(90, 0, 0), 16)
		stick(r, Vector3(-0.2 + i * 0.4, 0.2, 0.85), Vector3(-0.9 + i * 1.8, 0.05, 1.6), 0.035, RED if i else DARK)


func _wash() -> void:
	var r := group(0.0)
	var tub := cyl(r, 0.8, 0.7, 1.0, Vector3(0, 0.5, 0), BLUE, Vector3.ZERO, 40, gloss(Color("7cc8ff"), 0.0, 0.5, 0.05))
	tub.name = "tub"
	cyl(r, 0.72, 0.64, 0.6, Vector3(0, 0.34, 0), ORANGE, Vector3.ZERO, 40, gloss(Color("ffa02a"), 0.6, 0.9, 0.15))
	box(r, Vector3(0.3, 0.4, 0.3), Vector3(0.1, 0.5, 0.0), GREEN, Vector3(0, 30, 0), null, 0.06)
	torus(r, 0.82, 0.06, Vector3(0, 1.0, 0), STEEL, Vector3.ZERO, metal_mat(STEEL))
	cyl(r, 0.5, 0.5, 0.06, Vector3(1.3, 0.04, 0.6), DARK, Vector3.ZERO, 32)


func _rainbow_spool_parts(r: Node3D, s: float) -> void:
	var cols := [RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE]
	for side in [-1.0, 1.0]:
		cyl(r, 0.9 * s, 0.9 * s, 0.06 * s, Vector3(0, 0.95 * s, side * 0.34 * s), DARK, Vector3(90, 0, 0), 64)
	for i in cols.size():
		cyl(r, 0.74 * s, 0.74 * s, 0.09 * s, Vector3(0, 0.95 * s, (-0.27 + i * 0.108) * s), cols[i], Vector3(90, 0, 0), 64)
	cyl(r, 0.24 * s, 0.24 * s, 0.72 * s, Vector3(0, 0.95 * s, 0), GREY, Vector3(90, 0, 0))


func _rainbow_spool() -> void:
	_rainbow_spool_parts(group(35.0), 1.0)


func _mega_spool() -> void:
	var r := group(30.0)
	var s := 1.5
	for side in [-1.0, 1.0]:
		cyl(r, 0.9 * s, 0.9 * s, 0.08 * s, Vector3(0, 0.95 * s, side * 0.34 * s), BRASS, Vector3(90, 0, 0), 64, metal_mat(BRASS))
	var cols := [RED, ORANGE, YELLOW, GREEN, TEAL, BLUE, PURPLE]
	for i in cols.size():
		cyl(r, 0.76 * s, 0.76 * s, 0.1 * s, Vector3(0, 0.95 * s, (-0.3 + i * 0.1) * s), cols[i], Vector3(90, 0, 0), 64)
	cyl(r, 0.26 * s, 0.26 * s, 0.8 * s, Vector3(0, 0.95 * s, 0), STEEL, Vector3(90, 0, 0), 32, metal_mat(STEEL))
	for side in [-1.0, 1.0]:
		glow(r, 0.08 * s, Vector3(0, 0.95 * s, side * 0.42 * s), YELLOW, 2.0)


func _plasma() -> void:
	var r := group(-30.0)
	cyl(r, 0.2, 0.2, 1.3, Vector3(-0.2, 0.4, 0), DARK, Vector3(0, 0, 90), 28)
	cyl(r, 0.24, 0.24, 0.5, Vector3(-0.5, 0.4, 0), RED, Vector3(0, 0, 90), 28)
	cyl(r, 0.16, 0.08, 0.35, Vector3(0.62, 0.4, 0), STEEL, Vector3(0, 0, -90), 24, metal_mat(STEEL))
	var jet := cyl(r, 0.1, 0.0, 1.1, Vector3(1.4, 0.4, 0), BLUE, Vector3(0, 0, -90), 24, gloss(Color("7fe0ff"), 4.5))
	cyl(r, 0.04, 0.0, 0.8, Vector3(1.3, 0.4, 0), WHITE, Vector3(0, 0, -90), 16, gloss(Color("ffffff"), 6.0))
	for i in 9:
		glow(r, 0.035, Vector3(1.3 + sin(i * 2.0) * 0.5, 0.1 + abs(cos(i * 3.0)) * 0.5, sin(i * 5.0) * 0.4), YELLOW, 4.0)
	box(r, Vector3(1.4, 0.04, 0.8), Vector3(1.6, 0.03, 0), STEEL, Vector3.ZERO, metal_mat(Color("6a7480")), 0.01)


func _swap() -> void:
	var r := group(-25.0)
	box(r, Vector3(0.8, 0.5, 0.6), Vector3(0, 0.45, 0), BRASS, Vector3.ZERO, metal_mat(BRASS), 0.1)
	for i in 2:
		cyl(r, 0.14, 0.02, 0.55, Vector3(-0.2 + i * 0.4, 0.0, 0), BRASS, Vector3.ZERO, 24, metal_mat(BRASS))
	glow(r, 0.08, Vector3(0, 0.72, 0.31), ORANGE, 3.0)
	torus(r, 0.9, 0.05, Vector3(0, 0.5, 0), CYAN_C, Vector3(90, 0, 0)).material_override = gloss(Color("4ad8ff"), 2.0)
	for s in [-1.0, 1.0]:
		cyl(r, 0.14, 0.0, 0.3, Vector3(s * 0.9, 0.5, 0.0), CYAN_C, Vector3(0, 0, -s * 90), 20, gloss(Color("4ad8ff"), 2.0))


const CYAN_C := Color("4ad8ff")


func _kiln() -> void:
	var r := group(-15.0)
	var dome := ball(r, 1.0, Vector3(0, 0.6, 0), RED, Vector3(1.0, 0.85, 1.0))
	dome.material_override = mat(Color("b0482e"), 0.04, Vector3.UP, 0.7, 0.9)
	cyl(r, 1.05, 1.05, 0.5, Vector3(0, 0.25, 0), Color("8a3a26"), Vector3.ZERO, 40)
	box(r, Vector3(0.7, 0.4, 0.1), Vector3(0, 0.45, 0.97), DARK, Vector3.ZERO, gloss(Color("ff7a1a"), 3.5), 0.05)
	torus(r, 1.0, 0.07, Vector3(0, 0.5, 0), STEEL, Vector3(90, 0, 0), metal_mat(STEEL))
	cyl(r, 0.18, 0.2, 0.4, Vector3(0, 1.5, 0), STEEL, Vector3.ZERO, 24, metal_mat(Color("6a7480")))
	box(r, Vector3(0.3, 0.12, 0.12), Vector3(0.6, 0.78, 0.92), GREEN, Vector3.ZERO, gloss(Color("5cff7a"), 1.5), 0.03)


func _chip(clock: bool) -> void:
	var r := group(-20.0)
	var body := Color("22262e") if clock else Color("1c3a2a")
	box(r, Vector3(1.2, 0.14, 1.2), Vector3(0, 0.12, 0), body, Vector3.ZERO, null, 0.05)
	for i in 8:
		for s in [-1.0, 1.0]:
			box(r, Vector3(0.05, 0.04, 0.16), Vector3(-0.5 + i * 0.14, 0.1, s * 0.68), BRASS, Vector3.ZERO, metal_mat(BRASS), 0.0)
			box(r, Vector3(0.16, 0.04, 0.05), Vector3(s * 0.68, 0.1, -0.5 + i * 0.14), BRASS, Vector3.ZERO, metal_mat(BRASS), 0.0)
	if clock:
		for i in 9:
			box(r, Vector3(0.05, 0.4, 0.8), Vector3(-0.4 + i * 0.1, 0.4, 0), RED, Vector3.ZERO, metal_mat(RED), 0.01)
	else:
		for i in 5:
			stick(r, Vector3(-0.4, 0.2, -0.4 + i * 0.2), Vector3(0.1 + i * 0.1, 0.2, -0.4 + i * 0.2), 0.02, Color("e8c14a"))
		glow(r, 0.14, Vector3(0.1, 0.3, 0.1), GREEN, 2.5)


func _boxes() -> void:
	var r := group(-20.0)
	var card := Color("c49a5e")
	for i in 3:
		var y := 0.3 if i < 2 else 0.9
		box(r, Vector3(1.1, 0.6, 0.9), Vector3(-0.6 + (i % 2) * 1.15 if i < 2 else 0.0, y, 0.0), card.darkened(i * 0.06), Vector3(0, i * 6.0, 0), null, 0.05)
		box(r, Vector3(1.12, 0.03, 0.2), Vector3(-0.6 + (i % 2) * 1.15 if i < 2 else 0.0, y + 0.3, 0.0), CREAM, Vector3(0, i * 6.0, 0), null, 0.01)
	cyl(r, 0.4, 0.4, 0.12, Vector3(0.1, 1.3, 0.0), TEAL, Vector3(90, 0, 0), 40)
	box(r, Vector3(0.4, 0.25, 0.02), Vector3(-0.6, 0.35, 0.47), WHITE, Vector3.ZERO, null, 0.0)


func _farm() -> void:
	var r := group(-20.0)
	for i in 3:
		var x := -1.3 + i * 1.3
		box(r, Vector3(1.0, 0.1, 0.9), Vector3(x, 0.1, 0.0), DARK, Vector3.ZERO, null, 0.04)
		for sx in [-1.0, 1.0]:
			box(r, Vector3(0.08, 1.0, 0.08), Vector3(x + sx * 0.46, 0.6, -0.3), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.02)
		box(r, Vector3(1.0, 0.08, 0.14), Vector3(x, 1.1, -0.3), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.02)
		box(r, Vector3(0.2, 0.14, 0.2), Vector3(x, 0.8, -0.3), BRASS, Vector3.ZERO, metal_mat(BRASS), 0.04)
		box(r, Vector3(0.7, 0.03, 0.6), Vector3(x, 0.2, 0.0), ORANGE.lerp(RED, i * 0.4), Vector3.ZERO, gloss(ORANGE.lerp(RED, i * 0.4), 0.8), 0.01)
		cyl(r, 0.1, 0.1, 0.2 + i * 0.12, Vector3(x, 0.32 + i * 0.06, 0.0), [TEAL, YELLOW, PURPLE][i], Vector3.ZERO, 20)


func _slicer() -> void:
	var r := group(-25.0)
	box(r, Vector3(1.8, 0.1, 1.2), Vector3(0, 0.08, 0.2), Color("8a94a2"), Vector3.ZERO, metal_mat(Color("8a94a2")), 0.05)
	box(r, Vector3(1.8, 1.1, 0.08), Vector3(0, 0.62, -0.4), Color("20252d"), Vector3(-12, 0, 0), null, 0.04)
	box(r, Vector3(1.6, 0.95, 0.03), Vector3(0, 0.63, -0.34), BLUE, Vector3(-12, 0, 0), gloss(Color("2f8cf0"), 1.4), 0.01)
	for i in 6:
		box(r, Vector3(0.5 - i * 0.03, 0.04, 0.4 - i * 0.02), Vector3(0, 0.62 + i * 0.06, -0.3), ORANGE.lerp(YELLOW, i / 6.0), Vector3(-12, 0, 0), gloss(ORANGE, 0.5), 0.01)
	box(r, Vector3(0.9, 0.02, 0.5), Vector3(0, 0.15, 0.3), Color("2a3038"), Vector3.ZERO, null, 0.01)
	box(r, Vector3(1.9, 0.02, 0.03), Vector3(0, 0.75, -0.2), WHITE, Vector3(-12, 0, 0), gloss(Color("ffffff"), 3.0), 0.0)


# -------------------------------------------------------------- equipment

func _feet() -> void:
	var r := group(0.0)
	for i in 4:
		var x := -1.2 + i * 0.8
		cyl(r, 0.32, 0.38, 0.5, Vector3(x, 0.4, 0), DARK, Vector3.ZERO, 36)
		for k in 3:
			torus(r, 0.35, 0.03, Vector3(x, 0.25 + k * 0.14, 0), Color("4a5260"))
		cyl(r, 0.2, 0.2, 0.1, Vector3(x, 0.7, 0), BRASS, Vector3.ZERO, 24, metal_mat(BRASS))


func _fan_blades(r: Node3D, center: Vector3, n: int, rad: float, col: Color) -> void:
	var fan := Node3D.new()
	r.add_child(fan)
	fan.position = center
	for i in n:
		var a := i * TAU / n
		var blade := box(fan, Vector3(rad * 0.45, rad, 0.04), Vector3(cos(a) * rad * 0.5, sin(a) * rad * 0.5, 0), col, Vector3(30, 0, rad_to_deg(a) - 90.0), metal_mat(col), 0.02)
		blade.position = Vector3(cos(a) * rad * 0.5, sin(a) * rad * 0.5, 0)
	ball(fan, rad * 0.22, Vector3(0, 0, 0.04), BRASS).material_override = metal_mat(BRASS)


func _mini_fan() -> void:
	var r := group(-20.0)
	box(r, Vector3(1.9, 1.9, 0.5), Vector3(0, 1.0, 0), DARK, Vector3.ZERO, null, 0.2)
	cyl(r, 0.8, 0.8, 0.52, Vector3(0, 1.0, 0.0), Color("0b0e14"), Vector3(90, 0, 0), 48)
	_fan_blades(r, Vector3(0, 1.0, 0.2), 7, 0.75, WHITE)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			cyl(r, 0.07, 0.07, 0.1, Vector3(sx * 0.78, 1.0 + sy * 0.78, 0.27), BRASS, Vector3(90, 0, 0), 12, metal_mat(BRASS))


func _turbo() -> void:
	var r := group(-25.0)
	box(r, Vector3(2.4, 2.4, 0.7), Vector3(0, 1.2, 0), Color("2b3a4a"), Vector3.ZERO, metal_mat(Color("2b3a4a")), 0.25)
	torus(r, 1.0, 0.09, Vector3(0, 1.2, 0.36), TEAL, Vector3(90, 0, 0)).material_override = gloss(Color("14b8a0"), 1.6)
	cyl(r, 1.0, 1.0, 0.06, Vector3(0, 1.2, 0.1), DARK, Vector3(90, 0, 0), 48)
	_fan_blades(r, Vector3(0, 1.2, 0.3), 11, 0.95, Color("9fd8ff"))


func _holder_bracket() -> void:
	var r := group(0.0)
	box(r, Vector3(2.2, 0.2, 0.7), Vector3(0, 0.15, 0), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.07)
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.2, 1.4, 0.7), Vector3(s * 1.0, 0.85, 0), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.07)
		cyl(r, 0.14, 0.14, 0.12, Vector3(s * 1.0, 1.4, 0.36), BRASS, Vector3(90, 0, 0), 20, metal_mat(BRASS))
	cyl(r, 0.1, 0.1, 2.0, Vector3(0, 1.4, 0), BRASS, Vector3(0, 0, 90), 20, metal_mat(BRASS))
	cyl(r, 0.62, 0.62, 0.55, Vector3(0, 1.4, 0), ORANGE, Vector3(0, 0, 90), 40)


func _chain() -> void:
	var r := group(0.0)
	for i in 12:
		var t := i / 11.0
		var pos := Vector3(-1.3 + t * 2.6, 0.5 + sin(t * PI) * 0.9, 0.0)
		var rot := Vector3(0, 0, cos(t * PI) * -45.0)
		box(r, Vector3(0.34, 0.3, 0.42), pos, Color("2b3038"), rot, null, 0.07)
		box(r, Vector3(0.12, 0.34, 0.44), pos, ORANGE if i % 2 == 0 else Color("4a5260"), rot, null, 0.03)
	cyl(r, 0.2, 0.2, 0.5, Vector3(-1.45, 0.45, 0), BRASS, Vector3(90, 0, 0), 20, metal_mat(BRASS))
	cyl(r, 0.2, 0.2, 0.5, Vector3(1.45, 0.45, 0), BRASS, Vector3(90, 0, 0), 20, metal_mat(BRASS))


func _guard() -> void:
	var r := group(0.0)
	cyl(r, 0.35, 0.85, 1.0, Vector3(0, 0.7, 0), BRASS, Vector3.ZERO, 48, metal_mat(BRASS))
	torus(r, 0.86, 0.07, Vector3(0, 0.2, 0), BRASS, Vector3.ZERO, metal_mat(Color("e8b840")))
	for i in 8:
		var a := i * TAU / 8.0
		box(r, Vector3(0.06, 0.5, 0.04), Vector3(cos(a) * 0.62, 0.7, sin(a) * 0.62), Color("6b4a12"), Vector3(0, -rad_to_deg(a), 0), null, 0.0)
	cyl(r, 0.2, 0.08, 0.5, Vector3(0, 1.4, 0), STEEL, Vector3.ZERO, 24, metal_mat(STEEL))
	glow(r, 0.1, Vector3(0, 1.7, 0), ORANGE, 3.0)


func _sink() -> void:
	var r := group(-20.0)
	box(r, Vector3(1.8, 0.2, 1.1), Vector3(0, 0.15, 0), Color("4a5260"), Vector3.ZERO, metal_mat(Color("4a5260")), 0.05)
	for i in 11:
		var t := i / 10.0
		box(r, Vector3(0.07, 1.0 + 0.2 * sin(t * PI), 1.0), Vector3(-0.8 + t * 1.6, 0.7 + 0.1 * sin(t * PI), 0.0), RED.lerp(ORANGE, t), Vector3.ZERO, metal_mat(RED.lerp(ORANGE, t)), 0.02)
	glow(r, 0.1, Vector3(0, 0.2, 0.58), ORANGE, 3.0)


func _hook() -> void:
	var r := group(0.0)
	for i in 3:
		var a := deg_to_rad(-70 + i * 70)
		var prong := cyl(r, 0.14, 0.0, 1.0, Vector3(sin(a) * 0.6, 0.9 + cos(a) * 0.3, 0), STEEL, Vector3(0, 0, rad_to_deg(-a) - 30.0 + 60.0), 20, metal_mat(STEEL))
		prong.position = Vector3(sin(a) * 0.75, 0.55 + cos(a) * 0.25, 0.0)
		prong.rotation_degrees = Vector3(0, 0, -rad_to_deg(a) * 0.9)
	cyl(r, 0.2, 0.2, 0.8, Vector3(0, 1.3, 0), STEEL, Vector3.ZERO, 24, metal_mat(STEEL))
	torus(r, 0.22, 0.06, Vector3(0, 1.85, 0), BRASS, Vector3(90, 0, 0), metal_mat(BRASS))
	for i in 6:
		torus(r, 0.1, 0.03, Vector3(0.0, 2.2 + i * 0.16, 0), WOOD, Vector3(90 * (i % 2), 90 * ((i + 1) % 2), 0))


func _carbon() -> void:
	var r := group(0.0)
	box(r, Vector3(2.0, 1.5, 0.16), Vector3(0, 0.9, 0), Color("16191f"), Vector3.ZERO, null, 0.08)
	for i in 14:
		box(r, Vector3(0.05, 1.5, 0.19), Vector3(-0.9 + i * 0.14, 0.9, 0), Color("2b3038"), Vector3(0, 0, 0), metal_mat(Color("2b3038")), 0.0)
	for i in 11:
		box(r, Vector3(2.0, 0.05, 0.2), Vector3(0, 0.2 + i * 0.14, 0), Color("22262e"), Vector3.ZERO, metal_mat(Color("22262e")), 0.0)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			cyl(r, 0.07, 0.07, 0.1, Vector3(sx * 0.88, 0.9 + sy * 0.64, 0.12), BRASS, Vector3(90, 0, 0), 16, metal_mat(BRASS))


func _servo() -> void:
	var r := group(0.0)
	for s in [-1.0, 1.0]:
		box(r, Vector3(0.5, 0.5, 0.5), Vector3(s * 0.55, 0.5, 0), DARK, Vector3.ZERO, null, 0.1)
		stick(r, Vector3(s * 0.55, 0.6, 0), Vector3(s * 1.2, 1.4, 0.1), 0.12, STEEL).material_override = metal_mat(STEEL)
		glow(r, 0.16, Vector3(s * 1.2, 1.4, 0.1), BRASS, 0.0).material_override = metal_mat(BRASS)
		stick(r, Vector3(s * 1.2, 1.4, 0.1), Vector3(s * 0.85, 2.2, 0.3), 0.1, ORANGE)
		box(r, Vector3(0.25, 0.4, 0.2), Vector3(s * 0.8, 2.3, 0.3), STEEL, Vector3(0, 0, -s * 20), metal_mat(STEEL), 0.04)
	cyl(r, 0.2, 0.2, 1.2, Vector3(0, 0.5, 0), STEEL, Vector3(0, 0, 90), 20, metal_mat(STEEL))


func _cape() -> void:
	var r := group(0.0)
	box(r, Vector3(1.6, 0.18, 0.3), Vector3(0, 2.0, 0), BRASS, Vector3.ZERO, metal_mat(BRASS), 0.07)
	for i in 9:
		var t := i / 8.0
		var x := -1.2 + t * 2.4
		var f := ball(r, 1.0, Vector3(x, 1.0, 0.0), PURPLE.lerp(PINK, t))
		f.scale = Vector3(0.22, 1.0 - 0.15 * abs(t - 0.5) * 2.0, 0.04)
		f.rotation_degrees = Vector3(0, 0, (t - 0.5) * -26.0)
		f.position = Vector3(x * 1.05, 1.0, 0.0)
		f.material_override = gloss(PURPLE.lerp(PINK, t), 0.15, 1.0, 0.18)
	for s in [-1.0, 1.0]:
		glow(r, 0.14, Vector3(s * 0.85, 2.0, 0.18), YELLOW, 1.5)


func _gauntlet() -> void:
	var r := group(0.0)
	box(r, Vector3(1.3, 1.0, 0.8), Vector3(0, 0.7, 0), Color("4a5260"), Vector3.ZERO, metal_mat(Color("4a5260")), 0.18)
	box(r, Vector3(1.0, 0.7, 0.9), Vector3(0, 1.4, 0.0), Color("4a5260"), Vector3.ZERO, metal_mat(Color("4a5260")), 0.15)
	for i in 4:
		box(r, Vector3(0.2, 0.34, 0.6), Vector3(-0.42 + i * 0.28, 1.85, 0.2), STEEL, Vector3.ZERO, metal_mat(STEEL), 0.07)
		cyl(r, 0.1, 0.0, 0.36, Vector3(-0.42 + i * 0.28, 2.1, 0.5), RED, Vector3(-60, 0, 0), 16)
	box(r, Vector3(1.4, 0.2, 0.9), Vector3(0, 0.15, 0), DARK, Vector3.ZERO, null, 0.08)
	cyl(r, 0.14, 0.14, 0.1, Vector3(0, 0.75, 0.42), BRASS, Vector3(90, 0, 0), 16, metal_mat(BRASS))


func _core() -> void:
	var r := group(0.0)
	var o := ball(r, 0.7, Vector3(0, 1.0, 0), RED)
	o.material_override = gloss(Color("ff4a1a"), 3.0, 0.9)
	ball(r, 0.35, Vector3(0, 1.0, 0), YELLOW).material_override = gloss(Color("ffe45a"), 5.0)
	for i in 3:
		torus(r, 0.95, 0.05, Vector3(0, 1.0, 0), BRASS, Vector3(i * 60.0, i * 40.0, 0), metal_mat(BRASS))
	cyl(r, 0.5, 0.6, 0.2, Vector3(0, 0.15, 0), DARK, Vector3.ZERO, 32)


func _exo() -> void:
	var r := group(0.0)
	box(r, Vector3(1.2, 1.5, 0.45), Vector3(0, 2.0, 0), Color("5a6472"), Vector3.ZERO, metal_mat(Color("5a6472")), 0.18)
	glow(r, 0.2, Vector3(0, 2.1, 0.26), CYAN_C, 3.0)
	for s in [-1.0, 1.0]:
		ball(r, 0.34, Vector3(s * 0.85, 2.5, 0), STEEL).material_override = metal_mat(STEEL)
		stick(r, Vector3(s * 0.85, 2.5, 0), Vector3(s * 1.2, 1.5, 0.1), 0.1, STEEL).material_override = metal_mat(STEEL)
		stick(r, Vector3(s * 0.3, 1.2, 0), Vector3(s * 0.4, 0.2, 0), 0.12, STEEL).material_override = metal_mat(STEEL)
		ball(r, 0.18, Vector3(s * 0.35, 0.7, 0), BRASS).material_override = metal_mat(BRASS)
	box(r, Vector3(1.0, 0.3, 0.4), Vector3(0, 1.1, 0), DARK, Vector3.ZERO, null, 0.1)


func _phoenix() -> void:
	var r := group(0.0)
	box(r, Vector3(0.5, 0.8, 0.24), Vector3(0, 0.9, 0), DARK, Vector3.ZERO, null, 0.1)
	for s in [-1.0, 1.0]:
		for i in 7:
			var t := i / 6.0
			var length := 1.7 - t * 0.45
			var a := deg_to_rad(10.0 + t * 85.0)
			var col := YELLOW.lerp(RED, t)
			var f := ball(r, 1.0, Vector3(s * 0.3, 1.0, 0) + Vector3(s * cos(a), sin(a), 0) * length * 0.5, col)
			f.scale = Vector3(length * 0.5, 0.13, 0.05)
			f.rotation_degrees = Vector3(0, 0, s * rad_to_deg(a))
			f.material_override = gloss(col, 0.9, 1.0, 0.25)


func _fangs() -> void:
	var r := group(0.0)
	box(r, Vector3(2.0, 0.4, 0.5), Vector3(0, 1.5, 0), Color("6a1a2a"), Vector3.ZERO, null, 0.18)
	for s in [-1.0, 1.0]:
		var f := cyl(r, 0.2, 0.0, 1.5, Vector3(s * 0.6, 0.75, 0), WHITE, Vector3(0, 0, -s * 6), 24)
		f.material_override = gloss(Color("f6f2e8"), 0.0, 1.0, 0.1)
		glow(r, 0.06, Vector3(s * 0.57, 0.1, 0), RED, 2.5)
	for s in [-1.0, 1.0]:
		cyl(r, 0.09, 0.0, 0.6, Vector3(s * 1.0, 1.1, 0), WHITE, Vector3.ZERO, 16, gloss(Color("f6f2e8"), 0.0, 1.0, 0.1))


func _quad() -> void:
	var r := group(0.0)
	box(r, Vector3(2.0, 0.6, 0.8), Vector3(0, 1.2, 0), BRASS, Vector3.ZERO, metal_mat(BRASS), 0.14)
	for i in 4:
		var x := -0.75 + i * 0.5
		cyl(r, 0.16, 0.03, 0.9, Vector3(x, 0.45, 0), BRASS, Vector3.ZERO, 24, metal_mat(Color("e8b840")))
		cyl(r, 0.2, 0.2, 0.15, Vector3(x, 0.95, 0), STEEL, Vector3.ZERO, 6, metal_mat(STEEL))
		glow(r, 0.05, Vector3(x, 0.0, 0.0), ORANGE, 4.0)
	for i in 4:
		cyl(r, 0.06, 0.06, 0.8, Vector3(-0.75 + i * 0.5, 1.9, 0), DARK, Vector3.ZERO, 12)


func _titan() -> void:
	var r := group(0.0)
	box(r, Vector3(1.9, 1.8, 0.8), Vector3(0, 1.7, 0), Color("6a7480"), Vector3.ZERO, metal_mat(Color("6a7480")), 0.28)
	box(r, Vector3(1.2, 1.2, 0.2), Vector3(0, 1.7, 0.42), Color("4a5260"), Vector3.ZERO, metal_mat(Color("4a5260")), 0.1)
	glow(r, 0.3, Vector3(0, 1.75, 0.55), ORANGE, 3.5)
	torus(r, 0.38, 0.06, Vector3(0, 1.75, 0.55), BRASS, Vector3(90, 0, 0), metal_mat(BRASS))
	for s in [-1.0, 1.0]:
		var sh := ball(r, 0.7, Vector3(s * 1.15, 2.4, 0), STEEL, Vector3(1.0, 0.7, 1.0))
		sh.material_override = metal_mat(Color("8a94a2"))
		for k in 3:
			cyl(r, 0.1, 0.0, 0.4, Vector3(s * (1.0 + k * 0.2), 2.8 - k * 0.1, 0.0), BRASS, Vector3(0, 0, -s * (20 + k * 25)), 16, metal_mat(BRASS))
	box(r, Vector3(1.3, 0.5, 0.7), Vector3(0, 0.6, 0), Color("4a5260"), Vector3.ZERO, metal_mat(Color("4a5260")), 0.15)


func _omega() -> void:
	var r := group(0.0)
	var cols := [RED, ORANGE, YELLOW, GREEN, CYAN_C, PURPLE]
	ball(r, 0.5, Vector3(0, 1.1, 0), WHITE).material_override = gloss(Color("ffffff"), 4.5)
	for i in 6:
		torus(r, 0.85, 0.045, Vector3(0, 1.1, 0), cols[i], Vector3(i * 30.0, i * 55.0, 0)).material_override = gloss(cols[i], 2.2)
	for i in 8:
		var a := i * TAU / 8.0
		var sp := cyl(r, 0.08, 0.0, 0.5, Vector3(cos(a) * 1.15, 1.1 + sin(a) * 1.15, 0), STEEL, Vector3(0, 0, rad_to_deg(a) - 90.0), 16, metal_mat(STEEL))
	cyl(r, 0.5, 0.65, 0.2, Vector3(0, 0.1, 0), DARK, Vector3.ZERO, 32)
