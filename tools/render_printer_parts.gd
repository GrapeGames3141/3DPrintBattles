extends "res://tools/render_art.gd"
## Renders the solid parts that make the newer Printers look different from
## the base machine: a resin bottle, a pellet hopper and a cyclone turbine.
## They are cut out on a transparent background into tools/printer_parts/ and
## tools/make_printer_variants.py places them on the machine.
##
##   godot --path . --disable-vsync -s tools/render_printer_parts.gd

const PARTS_OUT := "res://tools/printer_parts/%s.png"


func _initialize() -> void:
	await process_frame
	_build_studio()
	await process_frame
	vp.size = Vector2i(768, 768)
	vp.transparent_bg = true
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.glow_enabled = false
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("8fb4e8")
	sm.sky_horizon_color = Color("e8dcc8")
	sm.ground_bottom_color = Color("2a2f3a")
	sm.ground_horizon_color = Color("6a6a70")
	sky.sky_material = sm
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	plate.visible = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/printer_parts"))
	var jobs := {
		"resin_bottle": [_bottle, 10.0, 8.5, 1.5],
		"pellet_hopper": [_hopper, 8.0, 10.0, 1.7],
		"cyclone_turbine": [_turbine, 6.0, 7.2, 1.0],
	}
	for id in jobs:
		var job: Array = jobs[id]
		_clear()
		job[0].call()
		_aim(job[1], job[2], job[3])
		await _settle()
		vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(PARTS_OUT % id))
		print("rendered ", id)
	quit()


## Painted metal, like the machine's own frame.
func metal(col: Color, rough := 0.38, metallic := 0.75) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metallic
	m.roughness = rough
	return m


func _bottle() -> void:
	var r := group(-18.0)
	var amber := Color("e8901a")
	var glass := box(r, Vector3(1.5, 2.2, 1.5), Vector3(0, 1.1, 0), amber, Vector3.ZERO, gloss(Color("f2a229"), 0.0, 0.62, 0.05), 0.35)
	glass.name = "glass"
	# the resin inside glows a little, filled to about two thirds
	box(r, Vector3(1.3, 1.5, 1.3), Vector3(0, 0.88, 0), amber, Vector3.ZERO, gloss(Color("ffb02e"), 0.9, 0.95, 0.2), 0.3)
	var shoulder := ball(r, 0.75, Vector3(0, 2.3, 0), amber, Vector3(1.0, 0.45, 1.0))
	shoulder.material_override = gloss(Color("f2a229"), 0.0, 0.65, 0.05)
	cyl(r, 0.34, 0.34, 0.55, Vector3(0, 2.7, 0), amber, Vector3.ZERO, 32, gloss(Color("f2a229"), 0.0, 0.7, 0.05))
	var cap := cyl(r, 0.42, 0.42, 0.42, Vector3(0, 3.15, 0), Color("22262e"), Vector3.ZERO, 32, metal(Color("2a2f3a"), 0.4, 0.5))
	for i in 12:
		var a := i * TAU / 12.0
		box(r, Vector3(0.05, 0.4, 0.05), Vector3(cos(a) * 0.42, 3.15, sin(a) * 0.42), Color("4a5260"), Vector3.ZERO, metal(Color("4a5260")), 0.0)
	cap.name = "cap"
	# a label wrapped on the front
	box(r, Vector3(1.0, 1.0, 1.54), Vector3(0, 1.1, 0), WHITE, Vector3.ZERO, gloss(Color("f4ede0"), 0.0, 1.0, 0.5), 0.05)
	box(r, Vector3(1.02, 0.22, 1.56), Vector3(0, 1.45, 0), ORANGE, Vector3.ZERO, gloss(Color("ff7a1a"), 0.0, 1.0, 0.4), 0.03)
	# a hazard drop symbol
	var drop := ball(r, 0.18, Vector3(0, 0.95, 0.78), ORANGE, Vector3(0.8, 1.1, 0.3))
	drop.material_override = gloss(Color("e8761a"), 0.2, 1.0, 0.3)
	for sx in [-1.0, 1.0]:
		box(r, Vector3(0.2, 0.2, 0.2), Vector3(sx * 0.68, 0.18, 0.68), Color("2a2f3a"), Vector3.ZERO, metal(Color("c98a1c"), 0.35, 0.8), 0.04)
	# a brass collar with a tube to the machine
	torus(r, 0.38, 0.06, Vector3(0, 2.92, 0), BRASS, Vector3.ZERO, metal(Color("d9a02a"), 0.3, 0.9))
	stick(r, Vector3(0.0, 3.4, 0.0), Vector3(1.2, 3.5, 0.0), 0.09, DARK).material_override = metal(Color("1e222a"), 0.5, 0.2)


func _hopper() -> void:
	var r := group(-14.0)
	var steel := metal(Color("7d8794"), 0.34, 0.8)
	var dark := metal(Color("39414d"), 0.4, 0.7)
	var brass := metal(Color("d9a02a"), 0.3, 0.9)
	# funnel
	cyl(r, 0.28, 1.05, 1.3, Vector3(0, 0.95, 0), GREY, Vector3.ZERO, 48, steel)
	# body with a glass window showing the pellets
	cyl(r, 1.05, 1.05, 0.3, Vector3(0, 3.35, 0), GREY, Vector3.ZERO, 48, steel)
	cyl(r, 1.05, 1.05, 0.2, Vector3(0, 1.8, 0), GREY, Vector3.ZERO, 48, steel)
	var win := cyl(r, 1.06, 1.06, 1.35, Vector3(0, 2.6, 0), GREY, Vector3.ZERO, 48, gloss(Color("a8c8d8"), 0.0, 0.18, 0.04))
	win.name = "window"
	for i in 150:
		var h := fmod(i * 0.6180339, 1.0)
		var a := i * 2.399
		var rr := sqrt(fmod(i * 0.7548, 1.0)) * 0.95
		var y := 1.95 + h * 1.25 - 0.35 * (rr / 0.95)
		var pc: Color = [Color("c9d94a"), Color("8fbf3a"), Color("e8d34a")][i % 3]
		ball(r, 0.075, Vector3(cos(a) * rr, y, sin(a) * rr), pc).material_override = gloss(pc, 0.0, 1.0, 0.25)
	for y in [1.7, 3.4]:
		torus(r, 1.06, 0.07, Vector3(0, y, 0), BRASS, Vector3.ZERO, brass)
	# lid with a fill cap
	cyl(r, 1.12, 1.12, 0.14, Vector3(0, 3.55, 0), GREY, Vector3.ZERO, 48, dark)
	cyl(r, 0.5, 0.5, 0.2, Vector3(0, 3.72, 0), BRASS, Vector3.ZERO, 32, brass)
	cyl(r, 0.14, 0.14, 0.22, Vector3(0, 3.9, 0), DARK, Vector3.ZERO, 16, dark)
	# an auger housing under the funnel and a feed pipe
	cyl(r, 0.3, 0.3, 1.4, Vector3(0.5, 0.2, 0), GREY, Vector3(0, 0, 90), 32, steel)
	cyl(r, 0.34, 0.34, 0.16, Vector3(1.1, 0.2, 0), BRASS, Vector3(0, 0, 90), 32, brass)
	cyl(r, 0.2, 0.2, 0.5, Vector3(1.4, 0.2, 0), GREY, Vector3(0, 0, 90), 32, dark)
	box(r, Vector3(0.5, 0.5, 0.5), Vector3(-0.4, 0.2, 0), GREY, Vector3.ZERO, dark, 0.1)
	# three legs
	for i in 3:
		var a := i * TAU / 3.0 + 0.5
		stick(r, Vector3(cos(a) * 0.95, 1.7, sin(a) * 0.95), Vector3(cos(a) * 1.25, -0.4, sin(a) * 1.25), 0.07, GREY).material_override = dark


func _turbine() -> void:
	var r := group(-26.0)
	var steel := metal(Color("8a94a2"), 0.32, 0.85)
	var dark := metal(Color("2b323c"), 0.45, 0.6)
	var brass := metal(Color("d9a02a"), 0.3, 0.9)
	var mint := gloss(Color("7fffd0"), 1.6)
	# the housing is a squared duct with a round bore
	box(r, Vector3(2.5, 2.5, 0.9), Vector3(0, 1.4, 0), GREY, Vector3.ZERO, steel, 0.22)
	cyl(r, 1.08, 1.08, 0.05, Vector3(0, 1.4, 0.1), DARK, Vector3(90, 0, 0), 56, dark)
	torus(r, 1.12, 0.07, Vector3(0, 1.4, 0.48), BRASS, Vector3(90, 0, 0), brass)
	torus(r, 0.98, 0.03, Vector3(0, 1.4, 0.5), BRASS, Vector3(90, 0, 0), mint)
	# the blades
	var fan := Node3D.new()
	r.add_child(fan)
	fan.position = Vector3(0, 1.4, 0.3)
	for i in 9:
		var a := i * TAU / 9.0
		var blade := box(fan, Vector3(0.36, 0.9, 0.04), Vector3(cos(a) * 0.55, sin(a) * 0.55, 0), GREY, Vector3(0, 0, rad_to_deg(a) - 90.0), metal(Color("aab4c0"), 0.3, 0.85), 0.02)
		blade.rotation_degrees = Vector3(28, 0, rad_to_deg(a) - 90.0)
		blade.position = Vector3(cos(a) * 0.56, sin(a) * 0.56, 0)
	ball(fan, 0.3, Vector3(0, 0, 0.05), BRASS, Vector3(1, 1, 0.9)).material_override = brass
	ball(fan, 0.1, Vector3(0, 0, 0.3), WHITE).material_override = mint
	# bolts in the corners
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			cyl(r, 0.1, 0.1, 0.1, Vector3(sx * 1.02, 1.4 + sy * 1.02, 0.46), BRASS, Vector3(90, 0, 0), 14, brass)
	# a mounting arm
	box(r, Vector3(0.5, 0.5, 0.6), Vector3(-1.4, 0.7, -0.1), GREY, Vector3.ZERO, dark, 0.1)
