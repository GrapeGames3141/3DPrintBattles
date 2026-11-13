extends "res://tools/render_art.gd"
## Renders one small gadget for every Printer mod, cut out on a transparent
## background into assets/printer_mods/<mod id>.png. scripts/ui/printer_rig.gd
## bolts them onto the machine picture, so a Printer looks like what it carries.
##
##   godot --path . --disable-vsync -s tools/render_mod_parts.gd             (all)
##   godot --path . --disable-vsync -s tools/render_mod_parts.gd -- stepper   (some)
##
## Needs a real renderer, so it cannot run with --headless.

const PART_OUT := "res://assets/printer_mods/%s.png"

var steel: StandardMaterial3D
var dark: StandardMaterial3D
var brass: StandardMaterial3D
var copper: StandardMaterial3D


func _initialize() -> void:
	var only: Array = Array(OS.get_cmdline_user_args())
	await process_frame
	_build_studio()
	await process_frame
	vp.size = Vector2i(256, 256)
	vp.transparent_bg = true
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.glow_enabled = true
	env.glow_intensity = 0.5
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("8fb4e8")
	sm.sky_horizon_color = Color("e8dcc8")
	sm.ground_bottom_color = Color("2a2f3a")
	sm.ground_horizon_color = Color("6a6a70")
	sky.sky_material = sm
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	cam.fov = 28.0
	plate.visible = false
	steel = metal(Color("9aa5b4"), 0.34, 0.85)
	dark = metal(Color("2c333d"), 0.42, 0.55)
	brass = metal(Color("d9a02a"), 0.3, 0.9)
	copper = metal(Color("c8683a"), 0.32, 0.9)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/printer_mods"))
	var jobs := {
		"stepper": _stepper, "spool": _bigger_spool, "frame": _frame, "bed": _bed, "enclosure": _enclosure,
		"sensor": _sensor, "preheater": _preheater, "quickstart": _quickstart, "slicer": _slicer,
		"hot_end": _hot_end, "mixer": _mixer, "sorter": _sorter,
		"cooling_duct": _cooling_duct, "self_cleaning": _brush, "spool_feeder": _feeder,
		"capacitor_bank": _capacitors, "scrap_chute": _chute, "quick_release": _lever,
		"failsafe": _padlock, "plating": _plating, "thermal_mass": _thermal, "prehensile_gantry": _claw,
		"quantum_slicer": _quantum, "dual_extruder": _dual, "direct_drive": _gearbox,
		"spool_rack": _rack, "twin_feed": _tower, "titanium_frame": _beam, "armor_panels": _panels,
		"auto_leveler": _probe, "runout_sensor": _runout, "preheat_chamber": _chamber,
		"liquid_hot_end": _radiator, "overdrive_board": _board, "auto_sorter": _bins,
	}
	for id in jobs:
		if not only.is_empty() and not only.has(id):
			continue
		_clear()
		_holder = stage
		var r := group(-24.0)
		jobs[id].call(r)
		_aim(16.0, 6.6, 0.0)
		await _settle()
		vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(PART_OUT % id))
		print("rendered ", id)
	quit()


## Painted metal, like the machine's own frame.
func metal(col: Color, rough := 0.38, metallic := 0.75) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metallic
	m.roughness = rough
	return m


func lamp(col: Color, energy := 2.0) -> StandardMaterial3D:
	return gloss(col, energy, 1.0, 0.2)


## A rounded block, the basic bolt-on body.
func blk(r: Node3D, size: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO, bevel := 0.06) -> MeshInstance3D:
	return box(r, size, pos, GREY, rot, m, bevel)


func screws(r: Node3D, w: float, h: float, z: float, n := 4) -> void:
	for i in n:
		var sx := -1.0 if i % 2 == 0 else 1.0
		var sy := -1.0 if i < 2 else 1.0
		cyl(r, 0.07, 0.07, 0.06, Vector3(sx * w * 0.5, sy * h * 0.5, z), BRASS, Vector3(90, 0, 0), 12, brass)


## A flat gear with teeth, axis along z.
func gear(r: Node3D, radius: float, teeth: int, thick: float, pos: Vector3, m: Material) -> void:
	cyl(r, radius, radius, thick, pos, GREY, Vector3(90, 0, 0), 32, m)
	for i in teeth:
		var a := i * TAU / teeth
		blk(r, Vector3(radius * 0.32, radius * 0.3, thick), pos + Vector3(cos(a) * radius, sin(a) * radius, 0), m, Vector3(0, 0, rad_to_deg(a)), 0.02)
	cyl(r, radius * 0.3, radius * 0.3, thick + 0.06, pos, DARK, Vector3(90, 0, 0), 16, dark)


# ------------------------------------------------------------------- parts

func _stepper(r: Node3D) -> void:
	blk(r, Vector3(1.5, 1.5, 1.2), Vector3(0, 0, -0.1), dark)
	blk(r, Vector3(1.55, 1.55, 0.18), Vector3(0, 0, 0.58), steel, Vector3.ZERO, 0.05)
	blk(r, Vector3(1.55, 1.55, 0.18), Vector3(0, 0, -0.72), steel, Vector3.ZERO, 0.05)
	cyl(r, 0.42, 0.42, 0.14, Vector3(0, 0, 0.72), GREY, Vector3(90, 0, 0), 32, steel)
	cyl(r, 0.13, 0.13, 0.5, Vector3(0, 0, 0.98), GREY, Vector3(90, 0, 0), 20, steel)
	screws(r, 1.2, 1.2, 0.68)
	blk(r, Vector3(0.5, 0.22, 0.3), Vector3(0.55, -0.85, -0.2), dark)
	stick(r, Vector3(0.55, -0.95, -0.2), Vector3(1.1, -1.25, -0.3), 0.07, Color("c23a2a"))
	ball(r, 0.1, Vector3(-0.45, 0.45, 0.7), WHITE).material_override = lamp(Color("55e08a"))


func _bigger_spool(r: Node3D) -> void:
	for z in [-0.48, 0.48]:
		cyl(r, 1.15, 1.15, 0.1, Vector3(0, 0, z), GREY, Vector3(90, 0, 0), 48, gloss(Color("2a2f3a"), 0.0, 1.0, 0.3))
	cyl(r, 0.95, 0.95, 0.86, Vector3(0, 0, 0), ORANGE, Vector3(90, 0, 0), 48)
	cyl(r, 0.3, 0.3, 1.1, Vector3(0, 0, 0), GREY, Vector3(90, 0, 0), 24, steel)
	for i in 5:
		var a := i * TAU / 5.0 + 0.3
		blk(r, Vector3(0.12, 0.32, 0.04), Vector3(cos(a) * 0.62, sin(a) * 0.62, 0.53), dark, Vector3(0, 0, rad_to_deg(a) - 90.0), 0.02)
	torus(r, 0.96, 0.03, Vector3(0, 0, 0.45), WHITE, Vector3(90, 0, 0), gloss(Color("ffc928"), 0.8))


func _frame(r: Node3D) -> void:
	blk(r, Vector3(1.9, 0.34, 0.5), Vector3(0, 0.78, 0), steel)
	blk(r, Vector3(0.34, 1.9, 0.5), Vector3(-0.78, 0, 0), steel)
	blk(r, Vector3(0.9, 0.9, 0.12), Vector3(-0.28, 0.28, 0.3), dark, Vector3(0, 0, 45), 0.04)
	blk(r, Vector3(1.2, 0.12, 0.14), Vector3(-0.2, 0.2, 0.38), brass, Vector3(0, 0, -45), 0.03)
	for p in [Vector2(-0.78, 0.78), Vector2(0.55, 0.78), Vector2(-0.78, -0.6)]:
		cyl(r, 0.1, 0.1, 0.08, Vector3(p.x, p.y, 0.28), BRASS, Vector3(90, 0, 0), 12, brass)
	blk(r, Vector3(0.26, 0.26, 0.2), Vector3(-0.78, 0.78, 0.2), brass, Vector3.ZERO, 0.05)


func _bed(r: Node3D) -> void:
	blk(r, Vector3(2.5, 0.14, 1.7), Vector3(0, -0.2, 0), dark)
	blk(r, Vector3(2.3, 0.1, 1.5), Vector3(0, -0.08, 0), lamp(Color("ff7a1a"), 2.6), Vector3.ZERO, 0.03)
	for i in 5:
		blk(r, Vector3(2.3, 0.02, 0.025), Vector3(0, 0.0, -0.6 + i * 0.3), lamp(Color("ffd08a"), 1.5), Vector3.ZERO, 0.0)
	for i in 6:
		blk(r, Vector3(0.025, 0.02, 1.5), Vector3(-1.0 + i * 0.4, 0.0, 0), lamp(Color("ffd08a"), 1.5), Vector3.ZERO, 0.0)
	for s in [-1.0, 1.0]:
		cyl(r, 0.09, 0.09, 0.3, Vector3(s * 1.1, -0.36, 0.7), GREY, Vector3.ZERO, 12, steel)
	ball(r, 0.1, Vector3(1.15, -0.12, 0.8), WHITE).material_override = lamp(Color("ff3a1a"), 3.0)


func _enclosure(r: Node3D) -> void:
	var glass := gloss(Color("9ee8ff"), 0.0, 0.22, 0.03)
	blk(r, Vector3(2.3, 2.1, 0.06), Vector3(0, 0, 0), glass, Vector3.ZERO, 0.02)
	for p in [Vector3(0, 1.05, 0), Vector3(0, -1.05, 0)]:
		blk(r, Vector3(2.4, 0.12, 0.16), p, steel, Vector3.ZERO, 0.04)
	for p in [Vector3(-1.15, 0, 0), Vector3(1.15, 0, 0)]:
		blk(r, Vector3(0.12, 2.2, 0.16), p, steel, Vector3.ZERO, 0.04)
	blk(r, Vector3(0.1, 0.5, 0.1), Vector3(0.7, 0, 0.14), brass, Vector3.ZERO, 0.03)
	for y in [0.6, -0.6]:
		blk(r, Vector3(0.14, 0.22, 0.05), Vector3(-1.15, y, 0.1), brass, Vector3.ZERO, 0.02)
	blk(r, Vector3(1.0, 0.04, 0.02), Vector3(-0.3, 0.55, 0.05), gloss(Color("ffffff"), 0.0, 0.5, 0.05), Vector3(0, 0, 18), 0.0)


func _sensor(r: Node3D) -> void:
	blk(r, Vector3(1.3, 0.9, 0.8), Vector3(0, -0.1, 0), dark)
	blk(r, Vector3(1.0, 0.1, 0.84), Vector3(0, 0.3, 0), steel, Vector3.ZERO, 0.03)
	stick(r, Vector3(-0.1, 0.3, 0.45), Vector3(-0.7, 0.9, 0.7), 0.08, GREY).material_override = steel
	ball(r, 0.2, Vector3(-0.75, 0.95, 0.72), WHITE).material_override = brass
	ball(r, 0.14, Vector3(0.4, 0.05, 0.42), WHITE).material_override = lamp(Color("55e08a"), 2.6)
	cyl(r, 0.1, 0.1, 1.6, Vector3(0, -0.2, 0.45), GREY, Vector3(0, 0, 90), 14, lamp(Color("ff8a2a"), 0.6))


func _preheater(r: Node3D) -> void:
	blk(r, Vector3(1.8, 0.8, 1.0), Vector3(0, -0.4, 0), dark)
	for i in 4:
		cyl(r, 0.13, 0.13, 1.5, Vector3(-0.54 + i * 0.36, 0.1, 0.0), ORANGE, Vector3(90, 0, 0), 16, lamp(Color("ff6a1a"), 2.4))
	blk(r, Vector3(1.9, 0.14, 0.14), Vector3(0, 0.55, 0.7), steel, Vector3.ZERO, 0.03)
	blk(r, Vector3(1.9, 0.14, 0.14), Vector3(0, 0.55, -0.7), steel, Vector3.ZERO, 0.03)
	blk(r, Vector3(0.5, 0.26, 0.1), Vector3(0.5, -0.4, 0.55), dark)
	ball(r, 0.1, Vector3(0.62, -0.4, 0.62), WHITE).material_override = lamp(Color("ff3a1a"), 3.0)


func _quickstart(r: Node3D) -> void:
	cyl(r, 1.05, 1.05, 0.2, Vector3(0, 0, 0), GREY, Vector3(90, 0, 0), 40, dark)
	torus(r, 1.0, 0.08, Vector3(0, 0, 0.1), BRASS, Vector3(90, 0, 0), brass)
	var bolt := lamp(Color("ffd23a"), 2.6)
	blk(r, Vector3(0.42, 1.1, 0.16), Vector3(0.12, 0.35, 0.16), bolt, Vector3(0, 0, -22), 0.03)
	blk(r, Vector3(0.42, 1.1, 0.16), Vector3(-0.12, -0.35, 0.16), bolt, Vector3(0, 0, -22), 0.03)
	blk(r, Vector3(0.8, 0.26, 0.16), Vector3(0.0, 0.0, 0.16), bolt, Vector3(0, 0, 0), 0.03)


func _slicer(r: Node3D) -> void:
	blk(r, Vector3(2.0, 1.4, 0.4), Vector3(0, 0, 0), dark)
	blk(r, Vector3(1.7, 1.05, 0.06), Vector3(0, 0.05, 0.22), lamp(Color("0a2a30"), 0.4), Vector3.ZERO, 0.03)
	var g := lamp(Color("3affc8"), 2.2)
	blk(r, Vector3(0.5, 0.5, 0.05), Vector3(-0.35, 0.15, 0.27), g, Vector3(0, 0, 0), 0.02)
	for i in 4:
		blk(r, Vector3(0.9 - i * 0.12, 0.07, 0.05), Vector3(0.45, 0.35 - i * 0.2, 0.27), g, Vector3.ZERO, 0.0)
	for i in 3:
		ball(r, 0.07, Vector3(-0.6 + i * 0.22, -0.55, 0.26), WHITE).material_override = lamp([Color("ff5a3a"), Color("ffd23a"), Color("55e08a")][i], 2.0)


func _hot_end(r: Node3D) -> void:
	blk(r, Vector3(0.9, 0.7, 0.9), Vector3(0, 0.1, 0), brass)
	for i in 5:
		blk(r, Vector3(1.3, 0.07, 1.3), Vector3(0, 0.62 + i * 0.16, 0), steel, Vector3.ZERO, 0.02)
	cyl(r, 0.32, 0.06, 0.55, Vector3(0, -0.52, 0), BRASS, Vector3.ZERO, 24, brass)
	cyl(r, 0.1, 0.1, 0.2, Vector3(0, -0.9, 0), GREY, Vector3.ZERO, 16, lamp(Color("ff8a2a"), 2.4))
	blk(r, Vector3(0.3, 0.3, 0.3), Vector3(0.62, 0.15, 0.2), dark)
	cyl(r, 0.06, 0.06, 0.9, Vector3(0, 1.5, 0), GREY, Vector3.ZERO, 12, dark)


func _mixer(r: Node3D) -> void:
	var cols := [Color("ff4a3a"), Color("3a8cff"), Color("ffd23a")]
	for i in 3:
		var a := i * TAU / 3.0 + 0.5
		var p := Vector3(cos(a) * 0.65, 0.65, sin(a) * 0.1)
		cyl(r, 0.2, 0.2, 0.8, p, GREY, Vector3.ZERO, 20, gloss(cols[i], 0.5, 0.85, 0.1))
		stick(r, p + Vector3(0, -0.4, 0), Vector3(0, -0.25, 0), 0.08, cols[i]).material_override = gloss(cols[i], 0.3, 1.0, 0.2)
	ball(r, 0.42, Vector3(0, -0.4, 0), WHITE).material_override = gloss(Color("c88aff"), 0.8, 1.0, 0.1)
	cyl(r, 0.25, 0.05, 0.5, Vector3(0, -1.0, 0), GREY, Vector3.ZERO, 20, steel)


func _sorter(r: Node3D) -> void:
	cyl(r, 0.9, 0.9, 1.5, Vector3(0, 0, 0), GREY, Vector3.ZERO, 40, gloss(Color("bfe8ff"), 0.0, 0.28, 0.04))
	for i in 7:
		cyl(r, 0.62, 0.62, 0.1, Vector3(0.0, -0.62 + i * 0.1, 0.0), BRASS, Vector3(0, i * 25.0, 0), 32, metal(Color("e8b030"), 0.25, 0.95))
	cyl(r, 0.95, 0.95, 0.16, Vector3(0, 0.8, 0), GREY, Vector3.ZERO, 40, dark)
	blk(r, Vector3(0.6, 0.06, 0.12), Vector3(0, 0.89, 0), brass, Vector3.ZERO, 0.02)
	cyl(r, 0.95, 0.95, 0.14, Vector3(0, -0.8, 0), GREY, Vector3.ZERO, 40, dark)
	cyl(r, 0.42, 0.42, 0.06, Vector3(0.4, 0.55, 0.7), BRASS, Vector3(90, 0, 0), 24, brass)


func _cooling_duct(r: Node3D) -> void:
	cyl(r, 0.8, 0.8, 0.5, Vector3(0, 0.2, 0), GREY, Vector3(90, 0, 0), 40, dark)
	torus(r, 0.78, 0.05, Vector3(0, 0.2, 0.26), BRASS, Vector3(90, 0, 0), steel)
	for i in 7:
		var a := i * TAU / 7.0
		blk(r, Vector3(0.14, 0.58, 0.04), Vector3(cos(a) * 0.3, 0.2 + sin(a) * 0.3, 0.2), lamp(Color("49b8ff"), 0.5), Vector3(0, 0, rad_to_deg(a) - 90.0), 0.01)
	cyl(r, 0.16, 0.16, 0.12, Vector3(0, 0.2, 0.28), GREY, Vector3(90, 0, 0), 16, steel)
	blk(r, Vector3(0.8, 0.5, 0.7), Vector3(0.1, -0.7, 0), dark)
	cyl(r, 0.4, 0.15, 0.7, Vector3(0.1, -1.2, 0), GREY, Vector3.ZERO, 28, steel)


func _brush(r: Node3D) -> void:
	blk(r, Vector3(1.8, 0.4, 0.7), Vector3(0, 0.5, 0), dark)
	for i in 24:
		var x := -0.8 + (i % 8) * 0.23
		var z := -0.22 + (i / 8) * 0.22
		stick(r, Vector3(x, 0.3, z), Vector3(x + 0.02, -0.5, z), 0.045, Color("d9a02a")).material_override = brass
	cyl(r, 0.2, 0.2, 0.5, Vector3(0.9, 0.5, 0), GREY, Vector3(0, 0, 90), 16, steel)
	ball(r, 0.2, Vector3(0, -0.9, 0), WHITE).material_override = gloss(Color("49b8ff"), 0.6, 0.8, 0.1)


func _feeder(r: Node3D) -> void:
	blk(r, Vector3(1.6, 1.4, 0.7), Vector3(0, 0, 0), dark)
	gear(r, 0.5, 10, 0.2, Vector3(-0.15, 0.1, 0.42), brass)
	cyl(r, 0.24, 0.24, 0.22, Vector3(0.62, -0.1, 0.42), GREY, Vector3(90, 0, 0), 20, steel)
	stick(r, Vector3(0.6, -0.4, 0.42), Vector3(0.6, -1.3, 0.42), 0.09, Color("ff7a1a")).material_override = lamp(Color("ff7a1a"), 0.4)
	stick(r, Vector3(-0.7, 0.5, 0.42), Vector3(-1.4, 0.9, 0.42), 0.09, Color("ff7a1a")).material_override = lamp(Color("ff7a1a"), 0.4)
	ball(r, 0.1, Vector3(0.55, 0.6, 0.38), WHITE).material_override = lamp(Color("55e08a"), 2.4)


func _capacitors(r: Node3D) -> void:
	blk(r, Vector3(2.0, 0.2, 1.0), Vector3(0, -0.8, 0), dark)
	for i in 3:
		var x := -0.6 + i * 0.6
		cyl(r, 0.24, 0.24, 1.2, Vector3(x, -0.1, 0), GREY, Vector3.ZERO, 24, gloss(Color("2f6fd8"), 0.0, 1.0, 0.2))
		cyl(r, 0.25, 0.25, 0.12, Vector3(x, 0.55, 0), GREY, Vector3.ZERO, 24, steel)
		blk(r, Vector3(0.06, 1.1, 0.02), Vector3(x, -0.1, 0.25), steel, Vector3.ZERO, 0.0)
	var bolt := lamp(Color("ffe45a"), 3.0)
	blk(r, Vector3(0.14, 0.5, 0.06), Vector3(-0.3, 0.95, 0.2), bolt, Vector3(0, 0, 25), 0.01)
	blk(r, Vector3(0.14, 0.5, 0.06), Vector3(0.0, 0.8, 0.2), bolt, Vector3(0, 0, -30), 0.01)
	blk(r, Vector3(0.14, 0.5, 0.06), Vector3(0.3, 0.95, 0.2), bolt, Vector3(0, 0, 25), 0.01)


func _chute(r: Node3D) -> void:
	cyl(r, 0.9, 0.35, 1.0, Vector3(0, 0.55, 0), GREY, Vector3.ZERO, 32, gloss(Color("7b848f"), 0.0, 1.0, 0.3))
	torus(r, 0.9, 0.06, Vector3(0, 1.05, 0), BRASS, Vector3(0, 0, 0), brass)
	cyl(r, 0.35, 0.35, 0.5, Vector3(0, -0.2, 0), GREY, Vector3.ZERO, 24, steel)
	blk(r, Vector3(1.5, 0.9, 1.2), Vector3(0, -0.95, 0.2), dark)
	blk(r, Vector3(1.3, 0.5, 0.06), Vector3(0, -0.8, 0.82), lamp(Color("0a2a30"), 0.4), Vector3.ZERO, 0.02)
	for p in [Vector3(-0.2, 0.9, 0.0), Vector3(0.3, 0.75, 0.3)]:
		blk(r, Vector3(0.3, 0.2, 0.3), p, steel, Vector3(25, 30, 12), 0.03)


func _lever(r: Node3D) -> void:
	blk(r, Vector3(1.6, 0.7, 0.8), Vector3(0, -0.5, 0), dark)
	cyl(r, 0.25, 0.25, 0.9, Vector3(0, -0.1, 0), GREY, Vector3(90, 0, 0), 20, steel)
	stick(r, Vector3(0, -0.1, 0.45), Vector3(0.9, 0.85, 0.5), 0.12, GREY).material_override = steel
	ball(r, 0.3, Vector3(0.95, 0.95, 0.5), WHITE).material_override = gloss(Color("e23b2e"), 0.4, 1.0, 0.2)
	for i in 3:
		blk(r, Vector3(0.12, 0.3, 0.05), Vector3(-0.55 + i * 0.2, -0.5, 0.42), brass, Vector3.ZERO, 0.01)


func _padlock(r: Node3D) -> void:
	torus(r, 0.55, 0.12, Vector3(0, 0.55, 0), GREY, Vector3(0, 0, 0), steel)
	blk(r, Vector3(1.5, 1.2, 0.7), Vector3(0, -0.35, 0), gloss(Color("d8342a"), 0.15, 1.0, 0.18), Vector3.ZERO, 0.18)
	cyl(r, 0.15, 0.15, 0.1, Vector3(0, -0.2, 0.37), GREY, Vector3(90, 0, 0), 16, dark)
	blk(r, Vector3(0.1, 0.4, 0.1), Vector3(0, -0.55, 0.37), dark, Vector3.ZERO, 0.02)
	blk(r, Vector3(1.2, 0.06, 0.04), Vector3(0, 0.1, 0.37), lamp(Color("ffd23a"), 1.2), Vector3.ZERO, 0.0)


func _plating(r: Node3D) -> void:
	for i in 3:
		blk(r, Vector3(1.9 - i * 0.15, 0.7, 0.18), Vector3(0.05 * i, 0.7 - i * 0.62, 0.0 + i * 0.12), steel if i != 1 else metal(Color("7d8794"), 0.36, 0.85), Vector3.ZERO, 0.06)
		for s in [-1.0, 1.0]:
			cyl(r, 0.08, 0.08, 0.06, Vector3(s * (0.8 - i * 0.07) + 0.05 * i, 0.7 - i * 0.62, 0.12 * i + 0.12), BRASS, Vector3(90, 0, 0), 12, brass)
	blk(r, Vector3(0.8, 0.12, 0.05), Vector3(-0.1, 0.0, 0.3), lamp(Color("ffb02e"), 0.6), Vector3.ZERO, 0.0)


func _thermal(r: Node3D) -> void:
	blk(r, Vector3(1.6, 1.3, 1.0), Vector3(0, -0.1, 0), copper)
	for i in 6:
		blk(r, Vector3(0.12, 1.2, 1.7), Vector3(-0.7 + i * 0.28, 0.9, 0), copper, Vector3.ZERO, 0.02)
	for i in 3:
		blk(r, Vector3(0.1, 0.9, 0.04), Vector3(-0.5 + i * 0.5, -0.1, 0.52), lamp(Color("ff5a1a"), 3.0), Vector3(0, 0, 10 * (i - 1)), 0.0)
	ball(r, 0.24, Vector3(0, -0.2, 0.55), WHITE).material_override = lamp(Color("ff8a2a"), 3.2)
	cyl(r, 0.2, 0.05, 0.5, Vector3(0, -1.0, 0), BRASS, Vector3.ZERO, 20, brass)


func _claw(r: Node3D) -> void:
	blk(r, Vector3(0.8, 0.5, 0.8), Vector3(0, 1.0, 0), dark)
	stick(r, Vector3(0, 0.9, 0), Vector3(0.5, 0.1, 0.2), 0.14, GREY).material_override = steel
	ball(r, 0.22, Vector3(0.5, 0.1, 0.2), WHITE).material_override = brass
	stick(r, Vector3(0.5, 0.1, 0.2), Vector3(0.2, -0.7, 0.3), 0.12, GREY).material_override = steel
	for s in [-1.0, 1.0]:
		stick(r, Vector3(0.2, -0.7, 0.3), Vector3(0.2 + s * 0.5, -1.3, 0.3), 0.09, GREY).material_override = metal(Color("c8ccd4"), 0.3, 0.9)
		stick(r, Vector3(0.2 + s * 0.5, -1.3, 0.3), Vector3(0.2 + s * 0.2, -1.5, 0.3), 0.07, GREY).material_override = metal(Color("c8ccd4"), 0.3, 0.9)
	ball(r, 0.1, Vector3(0.2, -0.7, 0.45), WHITE).material_override = lamp(Color("ff3a3a"), 2.4)


func _quantum(r: Node3D) -> void:
	var gem := gloss(Color("b07aff"), 1.6, 0.85, 0.05)
	ball(r, 0.55, Vector3(0, 0, 0), WHITE, Vector3(0.75, 1.15, 0.75)).material_override = gem
	ball(r, 0.28, Vector3(0, 0, 0), WHITE).material_override = lamp(Color("e8d8ff"), 3.5)
	torus(r, 0.95, 0.05, Vector3(0, 0, 0), WHITE, Vector3(70, 0, 0), lamp(Color("55e0ff"), 2.0))
	torus(r, 0.95, 0.05, Vector3(0, 0, 0), WHITE, Vector3(70, 60, 0), lamp(Color("ff7aff"), 2.0))
	torus(r, 0.95, 0.05, Vector3(0, 0, 0), WHITE, Vector3(70, 120, 0), lamp(Color("ffd23a"), 2.0))
	cyl(r, 0.4, 0.55, 0.22, Vector3(0, -1.05, 0), GREY, Vector3.ZERO, 6, brass)
	for i in 6:
		var a := i * TAU / 6.0 + 0.4
		ball(r, 0.06, Vector3(cos(a) * 1.15, sin(a * 2.0) * 0.5, sin(a) * 0.5), WHITE).material_override = lamp(Color("e8d8ff"), 3.0)


func _dual(r: Node3D) -> void:
	for s in [-1.0, 1.0]:
		blk(r, Vector3(0.95, 1.1, 0.95), Vector3(s * 0.52, 0.55, 0), dark)
		cyl(r, 0.28, 0.28, 0.12, Vector3(s * 0.52, 0.55, 0.52), GREY, Vector3(90, 0, 0), 24, steel)
		blk(r, Vector3(0.5, 0.5, 0.5), Vector3(s * 0.52, -0.3, 0), brass)
		cyl(r, 0.2, 0.05, 0.45, Vector3(s * 0.52, -0.78, 0), BRASS, Vector3.ZERO, 20, brass)
		ball(r, 0.06, Vector3(s * 0.52, -1.05, 0), WHITE).material_override = lamp(Color("ff8a2a"), 3.0)
	blk(r, Vector3(2.1, 0.2, 1.0), Vector3(0, 1.2, 0), steel, Vector3.ZERO, 0.04)
	stick(r, Vector3(-0.52, 1.2, 0), Vector3(-0.8, 1.6, 0), 0.08, Color("ff7a1a")).material_override = lamp(Color("ff7a1a"), 0.4)
	stick(r, Vector3(0.52, 1.2, 0), Vector3(0.8, 1.6, 0), 0.08, Color("3a8cff")).material_override = lamp(Color("3a8cff"), 0.4)


func _gearbox(r: Node3D) -> void:
	blk(r, Vector3(2.0, 1.7, 0.5), Vector3(0, 0, -0.2), dark)
	gear(r, 0.62, 14, 0.24, Vector3(-0.42, 0.18, 0.15), brass)
	gear(r, 0.36, 9, 0.24, Vector3(0.52, -0.2, 0.15), steel)
	gear(r, 0.26, 8, 0.24, Vector3(0.5, 0.52, 0.15), copper)
	torus(r, 0.9, 0.05, Vector3(0, 0, 0.0), BRASS, Vector3(90, 0, 0), brass)
	cyl(r, 0.11, 0.11, 0.7, Vector3(0.9, -0.2, 0.3), GREY, Vector3(90, 0, 0), 14, lamp(Color("ff8a2a"), 0.5))
	screws(r, 1.7, 1.4, -0.16)


func _rack(r: Node3D) -> void:
	for s in [-1.0, 1.0]:
		blk(r, Vector3(0.18, 2.0, 0.18), Vector3(s * 0.85, 0.0, 0), steel, Vector3.ZERO, 0.04)
		blk(r, Vector3(0.5, 0.12, 0.5), Vector3(s * 0.85, -1.0, 0), dark, Vector3.ZERO, 0.03)
	blk(r, Vector3(1.9, 0.14, 0.18), Vector3(0, 0.95, 0), steel, Vector3.ZERO, 0.04)
	blk(r, Vector3(1.9, 0.12, 0.14), Vector3(0, -0.2, 0), brass, Vector3.ZERO, 0.03)
	cyl(r, 0.55, 0.55, 0.1, Vector3(0, 0.35, 0.0), GREY, Vector3(90, 0, 0), 36, gloss(Color("2a2f3a"), 0.0, 1.0, 0.3))
	cyl(r, 0.45, 0.45, 0.4, Vector3(0, 0.35, 0.0), TEAL, Vector3(90, 0, 0), 36)
	cyl(r, 0.5, 0.5, 0.1, Vector3(0, 0.35, 0.22), GREY, Vector3(90, 0, 0), 36, gloss(Color("2a2f3a"), 0.0, 1.0, 0.3))
	cyl(r, 0.12, 0.12, 0.7, Vector3(0, 0.35, 0.0), GREY, Vector3(90, 0, 0), 14, steel)


func _tower(r: Node3D) -> void:
	for i in 2:
		var y := -0.5 + i * 1.0
		blk(r, Vector3(1.4, 0.8, 0.8), Vector3(0, y, 0), dark)
		gear(r, 0.28, 8, 0.2, Vector3(-0.25, y, 0.44), brass)
		ball(r, 0.08, Vector3(0.5, y + 0.2, 0.44), WHITE).material_override = lamp(Color("55e08a"), 2.4)
		stick(r, Vector3(0.45, y - 0.3, 0.3), Vector3(0.8, y - 0.9, 0.3), 0.08, Color("ff7a1a")).material_override = lamp(Color("ff7a1a"), 0.4)
	for s in [-1.0, 1.0]:
		blk(r, Vector3(0.12, 2.1, 0.12), Vector3(s * 0.8, 0.0, -0.3), steel, Vector3.ZERO, 0.03)
	torus(r, 0.3, 0.05, Vector3(0, 1.1, 0), BRASS, Vector3(90, 0, 0), brass)


func _beam(r: Node3D) -> void:
	var ti := metal(Color("8fa3bd"), 0.28, 0.95)
	blk(r, Vector3(2.0, 0.4, 0.5), Vector3(0, 0.7, 0), ti)
	blk(r, Vector3(0.4, 2.0, 0.5), Vector3(-0.8, -0.1, 0), ti)
	for i in 4:
		cyl(r, 0.1, 0.1, 0.56, Vector3(-0.35 + i * 0.4, 0.7, 0), GREY, Vector3(90, 0, 0), 14, dark)
	for i in 3:
		cyl(r, 0.1, 0.1, 0.56, Vector3(-0.8, 0.2 - i * 0.5, 0), GREY, Vector3(90, 0, 0), 14, dark)
	blk(r, Vector3(1.2, 0.18, 0.12), Vector3(-0.1, 0.0, 0.3), lamp(Color("49b8ff"), 0.9), Vector3(0, 0, -40), 0.02)


func _panels(r: Node3D) -> void:
	for i in 3:
		var y := 0.62 - i * 0.62
		blk(r, Vector3(1.9, 0.52, 0.2), Vector3(0, y, 0.05 * i), metal(Color("55616f"), 0.4, 0.8), Vector3(0, 0, 0), 0.07)
		blk(r, Vector3(1.9, 0.06, 0.22), Vector3(0, y + 0.22, 0.05 * i), brass, Vector3.ZERO, 0.02)
		for s in [-1.0, 1.0]:
			cyl(r, 0.09, 0.09, 0.06, Vector3(s * 0.78, y, 0.14 + 0.05 * i), BRASS, Vector3(90, 0, 0), 6, brass)
	blk(r, Vector3(0.5, 0.18, 0.04), Vector3(0, 0.0, 0.3), lamp(Color("ffb02e"), 0.7), Vector3.ZERO, 0.0)


func _probe(r: Node3D) -> void:
	blk(r, Vector3(1.5, 0.5, 0.8), Vector3(0, 0.7, 0), dark)
	cyl(r, 0.18, 0.18, 0.9, Vector3(0, 0.05, 0), GREY, Vector3.ZERO, 20, steel)
	cyl(r, 0.1, 0.1, 0.5, Vector3(0, -0.6, 0), GREY, Vector3.ZERO, 16, metal(Color("d0d4dc"), 0.2, 0.95))
	ball(r, 0.14, Vector3(0, -0.92, 0), WHITE).material_override = brass
	torus(r, 0.32, 0.05, Vector3(0, 0.05, 0), BRASS, Vector3.ZERO, brass)
	ball(r, 0.1, Vector3(0.55, 0.7, 0.42), WHITE).material_override = lamp(Color("55e08a"), 2.6)
	blk(r, Vector3(2.0, 0.08, 1.2), Vector3(0, -1.15, 0), lamp(Color("ff7a1a"), 0.9), Vector3.ZERO, 0.02)


func _runout(r: Node3D) -> void:
	blk(r, Vector3(1.5, 1.1, 0.9), Vector3(0, 0, 0), dark)
	cyl(r, 0.16, 0.16, 2.0, Vector3(0, 0.0, 0), GREY, Vector3(0, 0, 90), 16, lamp(Color("ff7a1a"), 0.5))
	blk(r, Vector3(1.0, 0.1, 0.5), Vector3(0, 0.58, 0), steel, Vector3.ZERO, 0.03)
	ball(r, 0.16, Vector3(-0.45, 0.2, 0.5), WHITE).material_override = lamp(Color("ff3a3a"), 3.0)
	ball(r, 0.1, Vector3(-0.1, 0.2, 0.5), WHITE).material_override = lamp(Color("55e08a"), 1.5)
	blk(r, Vector3(0.6, 0.35, 0.05), Vector3(0.35, -0.25, 0.47), lamp(Color("0a2a30"), 0.4), Vector3.ZERO, 0.02)
	blk(r, Vector3(0.4, 0.06, 0.05), Vector3(0.35, -0.2, 0.5), lamp(Color("3affc8"), 2.0), Vector3.ZERO, 0.0)


func _chamber(r: Node3D) -> void:
	blk(r, Vector3(2.0, 1.5, 1.3), Vector3(0, 0, 0), dark)
	blk(r, Vector3(1.7, 0.18, 0.06), Vector3(0, 0.2, 0.67), lamp(Color("ff6a1a"), 2.8), Vector3.ZERO, 0.0)
	for i in 5:
		blk(r, Vector3(1.4, 0.06, 0.05), Vector3(0, -0.15 - i * 0.14, 0.67), steel, Vector3.ZERO, 0.0)
	blk(r, Vector3(2.1, 0.12, 1.4), Vector3(0, 0.82, 0), steel, Vector3.ZERO, 0.04)
	cyl(r, 0.2, 0.2, 0.3, Vector3(0.6, 1.0, 0.0), GREY, Vector3.ZERO, 20, steel)
	ball(r, 0.1, Vector3(-0.8, 0.55, 0.68), WHITE).material_override = lamp(Color("ff3a1a"), 3.0)
	screws(r, 1.8, 1.2, 0.66)


func _radiator(r: Node3D) -> void:
	blk(r, Vector3(1.8, 1.4, 0.5), Vector3(0, 0, 0), dark)
	for i in 7:
		blk(r, Vector3(0.08, 1.2, 0.56), Vector3(-0.78 + i * 0.26, 0, 0), steel, Vector3.ZERO, 0.01)
	torus(r, 0.38, 0.07, Vector3(-0.9, 0.9, 0.1), BRASS, Vector3(0, 0, 0), lamp(Color("49b8ff"), 1.2))
	stick(r, Vector3(-0.9, 1.3, 0.1), Vector3(-0.9, 1.6, 0.1), 0.09, Color("49b8ff")).material_override = lamp(Color("49b8ff"), 1.2)
	cyl(r, 0.5, 0.5, 0.2, Vector3(0.0, -0.95, 0.0), GREY, Vector3(90, 0, 0), 28, dark)
	for i in 5:
		var a := i * TAU / 5.0
		blk(r, Vector3(0.1, 0.4, 0.03), Vector3(cos(a) * 0.2, -0.95 + sin(a) * 0.2, 0.12), lamp(Color("49b8ff"), 0.5), Vector3(0, 0, rad_to_deg(a) - 90.0), 0.0)
	ball(r, 0.14, Vector3(0.75, 0.95, 0.3), WHITE).material_override = lamp(Color("49b8ff"), 2.4)


func _board(r: Node3D) -> void:
	blk(r, Vector3(2.1, 1.5, 0.12), Vector3(0, 0, 0), gloss(Color("1f8a4c"), 0.0, 1.0, 0.25), Vector3.ZERO, 0.03)
	for i in 6:
		blk(r, Vector3(1.2 - i * 0.12, 0.03, 0.03), Vector3(-0.2, 0.55 - i * 0.18, 0.08), brass, Vector3.ZERO, 0.0)
	blk(r, Vector3(0.7, 0.7, 0.14), Vector3(-0.4, 0.0, 0.12), dark, Vector3.ZERO, 0.03)
	blk(r, Vector3(0.7, 0.2, 0.1), Vector3(0.6, -0.4, 0.1), dark, Vector3.ZERO, 0.02)
	for i in 6:
		blk(r, Vector3(0.1, 0.5, 0.5), Vector3(0.45 + i * 0.12, 0.35, 0.3), copper, Vector3.ZERO, 0.01)
	ball(r, 0.1, Vector3(-0.9, -0.55, 0.1), WHITE).material_override = lamp(Color("ff3a3a"), 3.0)
	ball(r, 0.1, Vector3(-0.7, -0.55, 0.1), WHITE).material_override = lamp(Color("ffd23a"), 3.0)
	ball(r, 0.1, Vector3(-0.5, -0.55, 0.1), WHITE).material_override = lamp(Color("55e08a"), 3.0)


func _bins(r: Node3D) -> void:
	var cols := [Color("ff5a3a"), Color("ffd23a"), Color("49b8ff")]
	blk(r, Vector3(2.2, 0.16, 1.0), Vector3(0, -0.8, 0), dark)
	for i in 3:
		var x := -0.7 + i * 0.7
		cyl(r, 0.3, 0.24, 0.9, Vector3(x, -0.3, 0), GREY, Vector3.ZERO, 24, gloss(cols[i], 0.2, 0.9, 0.2))
		torus(r, 0.3, 0.04, Vector3(x, 0.15, 0), WHITE, Vector3.ZERO, steel)
	cyl(r, 0.4, 0.4, 0.08, Vector3(0, 0.95, 0.0), BRASS, Vector3(70, 0, 0), 28, metal(Color("e8b030"), 0.25, 0.95))
	blk(r, Vector3(2.0, 0.08, 0.2), Vector3(0, 0.55, 0), steel, Vector3(0, 0, 8), 0.02)
