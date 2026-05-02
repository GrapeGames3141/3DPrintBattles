extends Control

## Clickable 3D workshop landing (Filament Fighters — Makers Guild). Ray picks hotspots → hub flows.

signal go_title
signal open_team
signal open_shop

var _toast_line: Label

const HOTSPOT_DOOR := "door"
const HOTSPOT_MONITOR := "monitor"
const HOTSPOT_PRINTER := "printer"

var _vp_container: SubViewportContainer
var _vp: SubViewport
var _camera: Camera3D


func _ready() -> void:
	name = "WorkshopLandingScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = _build_overlay_theme()

	_vp_container = SubViewportContainer.new()
	_vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vp_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_vp_container.stretch = true
	add_child(_vp_container)

	_vp = SubViewport.new()
	# With stretch enabled, resolution follows the container — do not hard-code size (avoids warnings + stale physics).
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.handle_input_locally = false
	_vp_container.add_child(_vp)

	var world := _build_workshop_world()
	_vp.add_child(world)

	var overlay := MarginContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var om: int = int(clampf(get_viewport_rect().size.x * 0.018, 10.0, 28.0))
	overlay.add_theme_constant_override("margin_left", om)
	overlay.add_theme_constant_override("margin_top", om)
	overlay.add_theme_constant_override("margin_right", om)
	overlay.add_theme_constant_override("margin_bottom", om)
	add_child(overlay)

	var root_col := VBoxContainer.new()
	root_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_col.add_theme_constant_override("separation", 0)
	overlay.add_child(root_col)

	var top_bar := PanelContainer.new()
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_theme_stylebox_override("panel", _stylebox_title_strip())
	var top_inner := MarginContainer.new()
	top_inner.add_theme_constant_override("margin_left", 14)
	top_inner.add_theme_constant_override("margin_top", 10)
	top_inner.add_theme_constant_override("margin_right", 14)
	top_inner.add_theme_constant_override("margin_bottom", 10)
	top_bar.add_child(top_inner)
	var top_hint := Label.new()
	top_hint.text = "Filament Fighters — Makers Guild"
	top_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_hint.add_theme_font_size_override("font_size", 26)
	top_hint.add_theme_color_override("font_color", Color(1.0, 0.97, 0.9))
	top_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
	top_hint.add_theme_constant_override("shadow_offset_x", 3)
	top_hint.add_theme_constant_override("shadow_offset_y", 3)
	top_inner.add_child(top_hint)
	root_col.add_child(top_bar)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_col.add_child(sp)

	var hint := Label.new()
	hint.text = "Click the workshop — or use the buttons below"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("shadow_offset_x", 2)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	root_col.add_child(hint)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 8)
	sp2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_col.add_child(sp2)

	root_col.add_child(_build_landing_bottom_shelf())

	_toast_line = Label.new()
	_toast_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_line.add_theme_font_size_override("font_size", 15)
	_toast_line.theme_type_variation = &"ToastLabel"
	root_col.add_child(_toast_line)

	if not EventBus.request_toast.is_connected(_on_hub_toast):
		EventBus.request_toast.connect(_on_hub_toast)

	# SubViewport World3D / physics space may be null until after first frames — warm up picks.
	await get_tree().process_frame
	await get_tree().physics_frame


func _build_overlay_theme() -> Theme:
	var t := Theme.new()
	var cream := Color(0.97, 0.94, 0.88)
	var shadow := Color(0, 0, 0, 0.72)
	t.set_color("font_color", "Label", cream)
	t.set_color("font_shadow_color", "Label", shadow)
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)
	t.set_font_size("font_size", "Label", 16)
	# Toast line: warm amber, still readable on shadow
	t.set_type_variation("ToastLabel", "Label")
	t.set_color("font_color", "ToastLabel", Color(1.0, 0.84, 0.52))
	t.set_color("font_shadow_color", "ToastLabel", Color(0, 0, 0, 0.85))
	t.set_constant("shadow_offset_x", "ToastLabel", 2)
	t.set_constant("shadow_offset_y", "ToastLabel", 2)
	return t


func _stylebox_title_strip() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.1, 0.07, 0.06, 0.9)
	s.border_color = Color(0.55, 0.38, 0.24, 0.85)
	s.set_border_width_all(3)
	s.corner_radius_top_left = 14
	s.corner_radius_top_right = 14
	s.corner_radius_bottom_left = 14
	s.corner_radius_bottom_right = 14
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 12
	s.shadow_offset = Vector2(2, 4)
	return s


func _build_landing_bottom_shelf() -> Control:
	var shelf := PanelContainer.new()
	shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelf.mouse_filter = Control.MOUSE_FILTER_STOP
	shelf.custom_minimum_size = Vector2(0, 100)
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0.11, 0.075, 0.055, 0.92)
	sh.border_color = Color(0.48, 0.34, 0.22, 0.8)
	sh.set_border_width_all(3)
	sh.corner_radius_top_left = 14
	sh.corner_radius_top_right = 14
	sh.corner_radius_bottom_left = 14
	sh.corner_radius_bottom_right = 14
	sh.shadow_color = Color(0, 0, 0, 0.42)
	sh.shadow_size = 10
	sh.shadow_offset = Vector2(2, 5)
	sh.content_margin_left = 12
	sh.content_margin_top = 10
	sh.content_margin_right = 12
	sh.content_margin_bottom = 10
	shelf.add_theme_stylebox_override("panel", sh)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	shelf.add_child(row)

	var ink := Color(0.06, 0.07, 0.1)
	row.add_child(_make_landing_action_button("Door → Title", Color(0.22, 0.82, 0.78), func(): go_title.emit()))

	row.add_child(_make_landing_action_button("Team Station", Color(0.28, 0.88, 0.52), func(): open_team.emit()))

	row.add_child(_make_landing_action_button("Filament Shop", Color(1.0, 0.42, 0.22), func(): open_shop.emit()))

	return shelf


func _make_landing_action_button(label: String, accent: Color, on_press: Callable) -> Button:
	var ink := Color(0.06, 0.07, 0.1)
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(168, 52)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_stretch_ratio = 1.0
	var stacks: Array = UiTheme.pill_styleboxes(
		accent.lightened(0.06),
		accent.lightened(0.16),
		accent.darkened(0.12),
		ink,
		20
	)
	b.add_theme_stylebox_override("normal", stacks[0])
	b.add_theme_stylebox_override("hover", stacks[1])
	b.add_theme_stylebox_override("pressed", stacks[2])
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", ink)
	b.pressed.connect(on_press)
	return b


func _build_workshop_world() -> Node3D:
	var root := Node3D.new()

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.065, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.48, 0.52, 0.72)
	env.ambient_light_energy = 0.38
	# ACES (“ACES Fitted” in Godot 3 naming) — vivid highlights without clipping.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.tonemap_white = 1.05
	# Subtle bloom on emissive / neon props.
	env.glow_enabled = true
	env.glow_intensity = 0.42
	env.glow_strength = 0.85
	env.glow_mix = 0.075
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 0.92
	env.glow_hdr_scale = 1.15
	env.glow_bloom = 0.08
	# Contact shadows in corners / under benches.
	env.ssao_enabled = true
	env.ssao_radius = 1.35
	env.ssao_intensity = 2.5
	env.ssao_power = 1.45
	env.ssao_detail = 0.55
	env.ssao_light_affect = 0.35
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 32, 0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.93, 0.78)
	sun.shadow_enabled = true
	sun.light_angular_distance = 0.45
	sun.shadow_blur = 1.35
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_max_distance = 48.0
	root.add_child(sun)

	var warm1 := OmniLight3D.new()
	warm1.position = Vector3(-3.2, 2.6, 2.0)
	warm1.light_energy = 2.8
	warm1.light_color = Color(1.0, 0.82, 0.55)
	warm1.omni_range = 9.0
	root.add_child(warm1)

	var warm2 := OmniLight3D.new()
	warm2.position = Vector3(3.5, 2.6, 1.5)
	warm2.light_energy = 2.6
	warm2.light_color = Color(1.0, 0.78, 0.52)
	warm2.omni_range = 8.5
	root.add_child(warm2)

	_camera = Camera3D.new()
	_camera.position = Vector3(0.15, 3.05, 9.4)
	_camera.rotation_degrees = Vector3(-18.5, 0.0, 0.0)
	_camera.fov = 52.0
	_camera.current = true
	root.add_child(_camera)

	# Floor
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(22, 14)
	floor_mi.mesh = plane
	floor_mi.position = Vector3(0, 0, 0)
	floor_mi.material_override = _mat_wood_floor()
	root.add_child(floor_mi)

	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 2
	floor_body.collision_mask = 0
	var floor_cs := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(22, 0.2, 14)
	floor_cs.shape = floor_box
	floor_body.position = Vector3(0, -0.11, 0)
	floor_body.add_child(floor_cs)
	root.add_child(floor_body)

	# Simple walls (dark wood)
	_add_wall_box(root, Vector3(0, 2.4, -7.0), Vector3(22, 5.0, 0.4))
	_add_wall_box(root, Vector3(-11.0, 2.4, 0), Vector3(0.4, 5.0, 14))
	_add_wall_box(root, Vector3(11.0, 2.4, 0), Vector3(0.4, 5.0, 14))

	# Door opening glow (cold exterior)
	var door_glow := MeshInstance3D.new()
	var dq := PlaneMesh.new()
	dq.size = Vector2(4.2, 4.8)
	door_glow.mesh = dq
	door_glow.position = Vector3(0, 2.4, -6.85)
	door_glow.rotation_degrees = Vector3(0, 180, 0)
	var dg_mat: StandardMaterial3D = _mat_plastic(
		Color(0.42, 0.58, 0.98),
		Color(0.38, 0.62, 1.0),
		0.65
	)
	dg_mat.metallic = 0.12
	dg_mat.roughness = 0.28
	door_glow.material_override = dg_mat
	root.add_child(door_glow)

	# Guild sign (Label3D) — billboard faces the camera (fixes mirrored / backwards text).
	var sign := Label3D.new()
	sign.text = "FILAMENT FIGHTERS — MAKERS GUILD"
	sign.position = Vector3(0, 3.35, -6.52)
	sign.rotation_degrees = Vector3.ZERO
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 48
	sign.modulate = Color(0.95, 0.86, 0.65)
	sign.outline_size = 14
	sign.outline_modulate = Color(0, 0, 0, 0.75)
	root.add_child(sign)

	# Left bench + printer + wireframe wolf glow
	_add_bench_cluster(root, Vector3(-4.2, 0, 1.2), true)
	# Right desk + monitor
	_add_bench_cluster(root, Vector3(4.2, 0, 1.0), false)

	# Shelf props (low-poly clutter)
	_add_spool(root, Vector3(-6.5, 1.1, -2.0), Color(0.9, 0.25, 0.2))
	_add_spool(root, Vector3(-6.0, 1.1, -2.4), Color(0.25, 0.85, 0.35))
	_add_spool(root, Vector3(6.2, 1.1, -1.8), Color(0.25, 0.45, 1.0))

	# Hotspots (invisible physics boxes)
	_add_hotspot(root, HOTSPOT_DOOR, Vector3(0, 2.0, -6.5), Vector3(3.8, 4.2, 1.2))
	_add_hotspot(root, HOTSPOT_MONITOR, Vector3(4.1, 1.55, 1.35), Vector3(2.2, 1.8, 1.4))
	_add_hotspot(root, HOTSPOT_PRINTER, Vector3(-4.1, 1.45, 1.35), Vector3(2.6, 2.0, 2.0))

	return root


func _add_wall_box(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = _mat_wood_wall()
	parent.add_child(mi)


func _add_bench_cluster(parent: Node3D, base: Vector3, is_printer_side: bool) -> void:
	var bench := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(5.0, 0.35, 2.4)
	bench.mesh = bm
	bench.position = base + Vector3(0, 0.5, 0)
	bench.material_override = _mat_wood_bench()
	parent.add_child(bench)

	if is_printer_side:
		# 3D printer stack — warm orange “PETG” cylinder chassis + glossy accents (not a grey cube).
		var pr_body := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.82
		cyl.bottom_radius = 0.82
		cyl.height = 1.52
		pr_body.mesh = cyl
		pr_body.position = base + Vector3(0.28, 1.38, 0.0)
		var orange := Color(1.0, 0.38, 0.1)
		var pr_mat: StandardMaterial3D = _mat_plastic(orange, Color(1.0, 0.28, 0.05), 0.0)
		pr_mat.metallic = 0.12
		pr_mat.roughness = 0.24
		pr_body.material_override = pr_mat
		parent.add_child(pr_body)

		var pr_cap := MeshInstance3D.new()
		var cap := CylinderMesh.new()
		cap.top_radius = 0.86
		cap.bottom_radius = 0.86
		cap.height = 0.12
		pr_cap.mesh = cap
		pr_cap.position = base + Vector3(0.28, 2.14, 0.0)
		var cap_mat: StandardMaterial3D = _mat_plastic(Color(0.18, 0.18, 0.2), Color.BLACK, 0.0)
		cap_mat.metallic = 0.35
		cap_mat.roughness = 0.22
		pr_cap.material_override = cap_mat
		parent.add_child(pr_cap)

		var feed_spool := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.34
		sm.bottom_radius = 0.34
		sm.height = 0.22
		feed_spool.mesh = sm
		feed_spool.position = base + Vector3(-0.55, 2.05, 0.35)
		feed_spool.rotation_degrees = Vector3(90, 0, 12)
		var sp := _mat_plastic(Color(0.92, 0.92, 0.95), Color.BLACK, 0.0)
		sp.roughness = 0.22
		feed_spool.material_override = sp
		parent.add_child(feed_spool)

		var wolf := MeshInstance3D.new()
		var wm := CapsuleMesh.new()
		wm.radius = 0.35
		wm.height = 0.85
		wolf.mesh = wm
		wolf.position = base + Vector3(0.42, 1.72, 0.22)
		wolf.rotation_degrees = Vector3(0, 25, 0)
		var wire := StandardMaterial3D.new()
		wire.albedo_color = Color(0.25, 0.55, 1.0, 0.88)
		wire.metallic = 0.08
		wire.roughness = 0.22
		wire.emission_enabled = true
		wire.emission = Color(0.25, 0.65, 1.0)
		wire.emission_energy_multiplier = 1.85
		wire.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wolf.material_override = wire
		parent.add_child(wolf)
	else:
		# Extruder Forge station — bright cyan plastic frame + emissive “UI” slab.
		var stand := MeshInstance3D.new()
		var st := CylinderMesh.new()
		st.top_radius = 0.14
		st.bottom_radius = 0.16
		st.height = 0.55
		stand.mesh = st
		stand.position = base + Vector3(0.45, 0.92, 1.05)
		var cyan_frame := Color(0.05, 0.72, 0.88)
		var st_mat: StandardMaterial3D = _mat_plastic(cyan_frame, Color(0.0, 0.45, 0.55), 0.0)
		st_mat.metallic = 0.14
		st_mat.roughness = 0.26
		stand.material_override = st_mat
		parent.add_child(stand)

		var mon := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = Vector3(1.45, 0.98, 0.07)
		mon.mesh = mm
		mon.position = base + Vector3(-0.15, 1.58, 1.12)
		var scr := StandardMaterial3D.new()
		scr.albedo_color = Color(0.04, 0.08, 0.12)
		scr.metallic = 0.18
		scr.roughness = 0.22
		scr.emission_enabled = true
		scr.emission = Color(0.15, 0.78, 1.0)
		scr.emission_energy_multiplier = 0.55
		mon.material_override = scr
		parent.add_child(mon)

		var bezel := MeshInstance3D.new()
		var tor := CylinderMesh.new()
		tor.top_radius = 0.06
		tor.bottom_radius = 0.06
		tor.height = 1.02
		bezel.mesh = tor
		bezel.position = base + Vector3(0.62, 1.58, 1.12)
		bezel.rotation_degrees = Vector3(0, 0, 90)
		var bz_mat: StandardMaterial3D = _mat_plastic(Color(0.02, 0.55, 0.68), Color(0.0, 0.85, 0.95), 0.15)
		bezel.material_override = bz_mat
		parent.add_child(bezel)

		var lbl := Label3D.new()
		lbl.text = "Extruder Forge"
		lbl.position = base + Vector3(-0.2, 2.42, 1.18)
		lbl.rotation_degrees = Vector3.ZERO
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.font_size = 38
		lbl.modulate = Color(0.55, 0.95, 1.0)
		lbl.outline_size = 10
		lbl.outline_modulate = Color(0, 0, 0, 0.55)
		parent.add_child(lbl)


func _add_spool(parent: Node3D, pos: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.38
	tm.bottom_radius = 0.38
	tm.height = 0.35
	mi.mesh = tm
	mi.position = pos
	mi.rotation_degrees = Vector3(90, 0, 0)
	var mat: StandardMaterial3D = _mat_plastic(col, Color.BLACK, 0.0)
	mat.roughness = 0.27
	mi.material_override = mat
	parent.add_child(mi)


func _mat_plastic(albedo: Color, emission: Color, emission_energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = 0.1
	m.roughness = 0.26
	if emission_energy > 0.001:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_energy
	return m


func _mat_wood_floor() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.38, 0.23, 0.13)
	m.metallic = 0.02
	m.roughness = 0.84
	return m


func _mat_wood_wall() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.28, 0.17, 0.1)
	m.metallic = 0.02
	m.roughness = 0.88
	return m


func _mat_wood_bench() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.4, 0.26, 0.14)
	m.metallic = 0.03
	m.roughness = 0.68
	return m


func _add_hotspot(parent: Node3D, kind: String, pos: Vector3, box_size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	body.set_meta("hotspot", kind)
	body.position = pos
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = box_size
	cs.shape = bx
	body.add_child(cs)
	parent.add_child(body)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_ray_pick(event.global_position)
	if event is InputEventScreenTouch and event.pressed:
		_try_ray_pick(event.global_position)


func _exit_tree() -> void:
	if EventBus.request_toast.is_connected(_on_hub_toast):
		EventBus.request_toast.disconnect(_on_hub_toast)


func _on_hub_toast(message: String) -> void:
	if _toast_line != null:
		_toast_line.text = str(message)


func _try_ray_pick(screen_pos: Vector2) -> void:
	if _camera == null or _vp == null or _vp_container == null:
		return
	var gr := _vp_container.get_global_rect()
	if not gr.has_point(screen_pos):
		return
	var local := screen_pos - gr.position
	var vp_rect := _vp.get_visible_rect()
	var vp_w: float = maxf(float(vp_rect.size.x), 1.0)
	var vp_h: float = maxf(float(vp_rect.size.y), 1.0)
	if vp_w <= 1.0 or vp_h <= 1.0:
		vp_w = maxf(float(_vp.size.x), 1.0)
		vp_h = maxf(float(_vp.size.y), 1.0)
	var vp_px := Vector2(
		local.x / maxf(gr.size.x, 1.0) * vp_w,
		local.y / maxf(gr.size.y, 1.0) * vp_h
	)
	var from := _camera.project_ray_origin(vp_px)
	var dir := _camera.project_ray_normal(vp_px)
	var to := from + dir * 120.0
	# SubViewport.world_3d is often null until the viewport has run; camera's world is reliable.
	var w3: World3D = _camera.get_world_3d()
	if w3 == null:
		w3 = _vp.world_3d
	if w3 == null:
		return
	var space: PhysicsDirectSpaceState3D = w3.direct_space_state
	if space == null:
		return
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	q.collide_with_areas = true
	q.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return
	var col: Object = hit.get("collider")
	if col == null:
		return
	var node: Node = col as Node
	var spot: String = ""
	var walk: Node = node
	while walk != null:
		if walk.has_meta("hotspot"):
			spot = str(walk.get_meta("hotspot"))
			break
		walk = walk.get_parent()
	if spot == "":
		return
	match spot:
		HOTSPOT_DOOR:
			go_title.emit()
		HOTSPOT_MONITOR:
			open_team.emit()
		HOTSPOT_PRINTER:
			open_shop.emit()
