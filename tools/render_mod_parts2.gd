extends "res://tools/render_mod_parts.gd"
## The second set of Printer-mod parts: Guard Frame, Overflow Hopper, Tool Beacon,
## Spring-Loaded Bed, Salvage Arm and Twin Gantry.
##
##   godot --path . --disable-vsync -s tools/render_mod_parts2.gd

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
	var jobs := {
		"guard_frame": _guard, "overflow_hopper": _hopper, "tool_beacon": _beacon,
		"rush_springs": _springs, "salvage_arm": _arm, "twin_gantry": _twin_gantry,
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


func _guard(r: Node3D) -> void:
	blk(r, Vector3(1.6, 1.9, 0.3), Vector3(0, 0, -0.1), dark, Vector3.ZERO, 0.12)
	blk(r, Vector3(1.3, 1.6, 0.12), Vector3(0, 0, 0.1), steel, Vector3.ZERO, 0.1)
	cyl(r, 0.42, 0.42, 0.14, Vector3(0, 0.05, 0.2), BRASS, Vector3(90, 0, 0), 6, brass)
	cyl(r, 0.18, 0.18, 0.18, Vector3(0, 0.05, 0.27), GREY, Vector3(90, 0, 0), 6, dark)
	for i in 3:
		blk(r, Vector3(1.0 - i * 0.2, 0.1, 0.1), Vector3(0, -0.62 - i * 0.12, 0.18), steel, Vector3.ZERO, 0.03)
	screws(r, 1.4, 1.7, 0.14)


func _hopper(r: Node3D) -> void:
	cyl(r, 0.28, 0.9, 1.1, Vector3(0, 0.3, 0), GREY, Vector3.ZERO, 32, dark)
	torus(r, 0.9, 0.07, Vector3(0, 0.85, 0), GREY, Vector3.ZERO, steel)
	cyl(r, 0.2, 0.2, 0.7, Vector3(0, -0.55, 0), GREY, Vector3.ZERO, 20, steel)
	blk(r, Vector3(0.7, 0.12, 0.5), Vector3(0, -1.0, 0.15), brass, Vector3.ZERO, 0.03)
	for i in 4:
		var c := box(r, Vector3(0.5, 0.7, 0.05), Vector3(-0.45 + i * 0.3, 1.0, 0.0), WHITE, Vector3(0, 0, -25 + i * 17.0), null, 0.02)
		c.material_override = lamp(Color("f2f6f8") if i % 2 == 0 else Color("ffd84a"), 0.25)
	screws(r, 1.0, 0.6, 0.55, 2)


func _beacon(r: Node3D) -> void:
	blk(r, Vector3(1.0, 0.3, 0.8), Vector3(0, -1.0, 0), dark, Vector3.ZERO, 0.08)
	stick(r, Vector3(0, -0.9, 0), Vector3(0, 0.1, 0), 0.1, GREY).material_override = steel
	cyl(r, 0.32, 0.4, 0.3, Vector3(0, 0.2, 0), GREY, Vector3.ZERO, 24, brass)
	var dome := ball(r, 0.44, Vector3(0, 0.62, 0), WHITE)
	dome.material_override = gloss(Color("4fe0ff"), 1.6, 0.8, 0.1)
	torus(r, 0.5, 0.04, Vector3(0, 0.62, 0), GREY, Vector3(0, 0, 0), brass)
	for s in [-1.0, 1.0]:
		blk(r, Vector3(0.5, 0.06, 0.06), Vector3(s * 0.68, 0.62, 0), steel, Vector3(0, 0, s * 12), 0.02)


func _springs(r: Node3D) -> void:
	blk(r, Vector3(2.0, 0.25, 1.1), Vector3(0, -0.95, 0), dark, Vector3.ZERO, 0.06)
	blk(r, Vector3(2.0, 0.25, 1.1), Vector3(0, 0.6, 0), steel, Vector3.ZERO, 0.06)
	for x in [-0.65, 0.0, 0.65]:
		for i in 7:
			torus(r, 0.24, 0.055, Vector3(x, -0.78 + i * 0.2, 0.0), GREY, Vector3.ZERO, copper)
		cyl(r, 0.07, 0.07, 1.4, Vector3(x, -0.1, 0), GREY, Vector3.ZERO, 12, steel)
	screws(r, 1.7, 0.8, 0.58, 2)


func _arm(r: Node3D) -> void:
	cyl(r, 0.55, 0.65, 0.3, Vector3(0, -0.95, 0), GREY, Vector3.ZERO, 28, dark)
	ball(r, 0.2, Vector3(0, -0.7, 0), GREY).material_override = brass
	stick(r, Vector3(0, -0.7, 0), Vector3(-0.55, 0.1, 0), 0.12, GREY).material_override = steel
	ball(r, 0.2, Vector3(-0.55, 0.1, 0), GREY).material_override = brass
	stick(r, Vector3(-0.55, 0.1, 0), Vector3(0.3, 0.8, 0.1), 0.1, GREY).material_override = steel
	ball(r, 0.17, Vector3(0.3, 0.8, 0.1), GREY).material_override = brass
	for s in [-1.0, 1.0]:
		blk(r, Vector3(0.1, 0.5, 0.14), Vector3(0.3 + s * 0.2, 1.1, 0.1), steel, Vector3(0, 0, s * -14), 0.02)
	blk(r, Vector3(0.2, 0.2, 0.2), Vector3(0.3, 1.45, 0.1), lamp(Color("e23b2e"), 0.4), Vector3.ZERO, 0.04)


func _twin_gantry(r: Node3D) -> void:
	for s in [-1.0, 1.0]:
		blk(r, Vector3(0.2, 1.9, 0.5), Vector3(s * 1.05, 0, 0), dark, Vector3.ZERO, 0.05)
	for y in [-0.55, 0.55]:
		cyl(r, 0.1, 0.1, 2.2, Vector3(0, y, 0.0), GREY, Vector3(0, 0, 90), 14, steel)
	for x in [-0.45, 0.45]:
		blk(r, Vector3(0.55, 1.35, 0.6), Vector3(x, 0, 0.1), dark, Vector3.ZERO, 0.06)
		cyl(r, 0.18, 0.04, 0.35, Vector3(x, -0.95, 0.1), BRASS, Vector3.ZERO, 16, brass)
		ball(r, 0.07, Vector3(x, -1.15, 0.1), WHITE).material_override = lamp(Color("ff8a2a"), 3.0)
		cyl(r, 0.14, 0.14, 0.1, Vector3(x, 0.2, 0.42), GREY, Vector3(90, 0, 0), 20, lamp(Color("4fe0ff"), 0.8))
	screws(r, 2.0, 1.7, 0.28)
