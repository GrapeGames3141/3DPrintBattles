extends Control

## Polished title: 3D printer centerpiece + filament-crack pedestal, pill CTAs, bottom workshop HUD.
## Signals preserved for Main: continue_pressed, new_game_confirmed, quit_pressed.

signal continue_pressed
signal new_game_confirmed
signal quit_pressed
signal open_shop_pressed
signal open_team_pressed
signal open_quests_pressed

const _CRACK_SHADER: Shader = preload("res://Shaders/title_filament_cracks.gdshader")

var _toast: Label
var _btn_continue: Button
var _confirm_new_game: AcceptDialog
var _confirm_delete: AcceptDialog
var _options_panel: PanelContainer
var _chk_music: CheckBox
var _chk_sfx: CheckBox

var _vp_container: SubViewportContainer
var _vp: SubViewport


func _ready() -> void:
	name = "TitleScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTheme.build_title_theme()
	_build_ui()
	EventBus.request_toast.connect(_on_toast)
	call_deferred("_fit_to_viewport")
	call_deferred("_refresh_continue_button")


func _exit_tree() -> void:
	if EventBus.request_toast.is_connected(_on_toast):
		EventBus.request_toast.disconnect(_on_toast)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("_fit_to_viewport")


func _fit_to_viewport() -> void:
	var r: Rect2 = get_viewport_rect()
	set_position(Vector2.ZERO)
	set_size(r.size)
	if _vp != null:
		_vp.size = Vector2i(maxi(2, int(r.size.x)), maxi(2, int(r.size.y)))


func _refresh_continue_button() -> void:
	if _btn_continue != null:
		_btn_continue.disabled = not SaveSystem.has_save()


func _build_ui() -> void:
	_vp_container = SubViewportContainer.new()
	_vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vp_container.offset_left = 0
	_vp_container.offset_top = 0
	_vp_container.offset_right = 0
	_vp_container.offset_bottom = 0
	_vp_container.stretch = true
	add_child(_vp_container)

	_vp = SubViewport.new()
	var r: Rect2 = get_viewport_rect()
	_vp.size = Vector2i(maxi(2, int(r.size.x)), maxi(2, int(r.size.y)))
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_vp.handle_input_locally = false
	_vp_container.add_child(_vp)
	_vp.add_child(_build_title_world())

	var overlay := MarginContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_constant_override("margin_left", 20)
	overlay.add_theme_constant_override("margin_top", 16)
	overlay.add_theme_constant_override("margin_right", 20)
	overlay.add_theme_constant_override("margin_bottom", 16)
	add_child(overlay)

	var main_col := VBoxContainer.new()
	main_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay.add_child(main_col)

	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_END
	top_row.add_theme_constant_override("separation", 10)
	var ver_left := Label.new()
	ver_left.text = "v %s" % ProjectSettings.get_setting("application/config/version", "0.1")
	ver_left.add_theme_font_size_override("font_size", 13)
	ver_left.modulate.a = 0.7
	ver_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(ver_left)

	var btn_opts := Button.new()
	btn_opts.text = "Options"
	btn_opts.custom_minimum_size = Vector2(120, 40)
	btn_opts.pressed.connect(_toggle_options)
	_attach_hover_sparks(btn_opts, Color(0.75, 0.95, 1.0))
	top_row.add_child(btn_opts)

	var btn_quit := Button.new()
	btn_quit.text = "Quit"
	btn_quit.custom_minimum_size = Vector2(100, 40)
	btn_quit.pressed.connect(func(): quit_pressed.emit())
	_attach_hover_sparks(btn_quit, Color(1.0, 0.55, 0.45))
	top_row.add_child(btn_quit)
	main_col.add_child(top_row)

	var title := Label.new()
	title.text = "3D PRINT BATTLES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.08, 0.1, 0.16))
	main_col.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Collect · Print · Battle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.25, 0.42, 0.55)
	subtitle.add_theme_font_size_override("font_size", 17)
	main_col.add_child(subtitle)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	main_col.add_child(gap)

	var mid_spacer := Control.new()
	mid_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_col.add_child(mid_spacer)

	var btn_stack := VBoxContainer.new()
	btn_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_stack.add_theme_constant_override("separation", 16)

	_btn_continue = Button.new()
	_btn_continue.text = "Continue"
	_btn_continue.custom_minimum_size = Vector2(320, 56)
	_btn_continue.disabled = not SaveSystem.has_save()
	_btn_continue.pressed.connect(func(): continue_pressed.emit())
	_attach_hover_sparks(_btn_continue, Color(0.4, 1.0, 0.92))
	btn_stack.add_child(_btn_continue)

	var btn_new := Button.new()
	btn_new.text = "New Game"
	btn_new.custom_minimum_size = Vector2(320, 56)
	btn_new.pressed.connect(_on_new_game_clicked)
	var ink := Color(0.12, 0.14, 0.22)
	var stacks: Array = UiTheme.pill_styleboxes(
		Color(1.0, 0.48, 0.42),
		Color(1.0, 0.62, 0.55),
		Color(0.82, 0.32, 0.28),
		ink,
		26
	)
	btn_new.add_theme_stylebox_override("normal", stacks[0])
	btn_new.add_theme_stylebox_override("hover", stacks[1])
	btn_new.add_theme_stylebox_override("pressed", stacks[2])
	_attach_hover_sparks(btn_new, Color(1.0, 0.65, 0.45))
	btn_stack.add_child(btn_new)

	main_col.add_child(btn_stack)

	var mid_spacer2 := Control.new()
	mid_spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_spacer2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_col.add_child(mid_spacer2)

	main_col.add_child(_build_bottom_hud())

	_toast = Label.new()
	_toast.text = ""
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_theme_font_size_override("font_size", 14)
	_toast.modulate = Color(0.95, 0.78, 0.45)
	main_col.add_child(_toast)

	_options_panel = _build_options_panel()
	_options_panel.visible = false
	_options_panel.set_anchors_preset(Control.PRESET_CENTER)
	_options_panel.offset_left = -200
	_options_panel.offset_top = -160
	_options_panel.offset_right = 200
	_options_panel.offset_bottom = 160
	add_child(_options_panel)

	_confirm_new_game = AcceptDialog.new()
	_confirm_new_game.title = "New Game"
	_confirm_new_game.dialog_text = "Start a new game? Your current progress on this device will be replaced."
	add_child(_confirm_new_game)
	_confirm_new_game.confirmed.connect(func(): new_game_confirmed.emit())

	_confirm_delete = AcceptDialog.new()
	_confirm_delete.title = "Delete Progress"
	_confirm_delete.dialog_text = "Erase all saved progress on this device? This cannot be undone."
	add_child(_confirm_delete)
	_confirm_delete.confirmed.connect(_on_delete_progress_confirmed)


func _build_bottom_hud() -> Control:
	var bar := PanelContainer.new()
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.18, 0.12, 0.1, 0.88)
	bar_style.border_color = Color(0.45, 0.32, 0.22, 0.65)
	bar_style.set_border_width_all(2)
	bar_style.corner_radius_top_left = 16
	bar_style.corner_radius_top_right = 16
	bar_style.corner_radius_bottom_left = 16
	bar_style.corner_radius_bottom_right = 16
	bar_style.shadow_color = Color(0, 0, 0, 0.35)
	bar_style.shadow_size = 8
	bar_style.shadow_offset = Vector2(2, 4)
	bar.add_theme_stylebox_override("panel", bar_style)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	bar.add_child(row)

	row.add_child(_make_hud_icon_button("Shop", "◉", Color(0.72, 0.38, 1.0), func(): open_shop_pressed.emit()))
	row.add_child(_make_hud_icon_button("Team", "⚙", Color(0.35, 0.88, 0.52), func(): open_team_pressed.emit()))
	row.add_child(_make_hud_icon_button("Quests", "✦", Color(1.0, 0.72, 0.28), func(): open_quests_pressed.emit()))

	return bar


func _make_hud_icon_button(label: String, glyph: String, accent: Color, on_press: Callable) -> Control:
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(76, 76)
	btn.flat = false
	var ink := Color(0.1, 0.12, 0.18)
	var pk: Array = UiTheme.pill_styleboxes(
		Color(0.22, 0.22, 0.26),
		Color(accent.r * 0.35 + 0.2, accent.g * 0.35 + 0.2, accent.b * 0.35 + 0.2),
		Color(accent.r * 0.55, accent.g * 0.55, accent.b * 0.55),
		ink,
		38
	)
	btn.add_theme_stylebox_override("normal", pk[0])
	btn.add_theme_stylebox_override("hover", pk[1])
	btn.add_theme_stylebox_override("pressed", pk[2])
	btn.add_theme_stylebox_override("disabled", pk[2])

	var inner := Label.new()
	inner.text = glyph
	inner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inner.add_theme_font_size_override("font_size", 28)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner)
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 0
	inner.offset_top = 0
	inner.offset_right = 0
	inner.offset_bottom = 0

	btn.pressed.connect(on_press)
	_attach_hover_sparks(btn, accent)
	vb.add_child(btn)

	var cap := Label.new()
	cap.text = label
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 13)
	cap.modulate = Color(0.92, 0.88, 0.82)
	vb.add_child(cap)

	return vb


func _build_title_world() -> Node3D:
	var root := Node3D.new()

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.55, 0.75)
	env.ambient_light_energy = 0.42
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 28, 0)
	sun.light_energy = 1.05
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.shadow_enabled = true
	root.add_child(sun)

	var key := OmniLight3D.new()
	key.position = Vector3(2.8, 3.2, 4.5)
	key.light_energy = 2.4
	key.light_color = Color(1.0, 0.85, 0.58)
	key.omni_range = 12.0
	root.add_child(key)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-3.0, 2.2, 3.0)
	fill.light_energy = 1.6
	fill.light_color = Color(0.65, 0.78, 1.0)
	fill.omni_range = 11.0
	root.add_child(fill)

	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 2.65, 7.8)
	cam.rotation_degrees = Vector3(-14.0, 0.0, 0.0)
	cam.fov = 48.0
	cam.current = true
	root.add_child(cam)

	# Pedestal — wood + filament crack shader
	var ped := MeshInstance3D.new()
	var ped_mesh := BoxMesh.new()
	ped_mesh.size = Vector3(5.2, 1.35, 4.2)
	ped.mesh = ped_mesh
	ped.position = Vector3(0.0, 0.68, 0.0)
	var crack_mat := ShaderMaterial.new()
	crack_mat.shader = _CRACK_SHADER
	crack_mat.set_shader_parameter("wood_albedo", Color(0.32, 0.19, 0.11))
	crack_mat.set_shader_parameter("crack_scale", 14.0)
	crack_mat.set_shader_parameter("pulse_speed", 1.25)
	crack_mat.set_shader_parameter("emission_strength", 3.4)
	ped.material_override = crack_mat
	root.add_child(ped)

	# Printer chassis — glossy PETG-like shell
	var body := MeshInstance3D.new()
	var body_m := BoxMesh.new()
	body_m.size = Vector3(2.35, 1.55, 2.05)
	body.mesh = body_m
	body.position = Vector3(0.0, 1.68 + 0.78, -0.15)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.94, 0.94, 0.96)
	body_mat.metallic = 0.25
	body_mat.roughness = 0.35
	body.material_override = body_mat
	root.add_child(body)

	var gantry := MeshInstance3D.new()
	var g_m := BoxMesh.new()
	g_m.size = Vector3(2.6, 0.14, 0.14)
	gantry.mesh = g_m
	gantry.position = Vector3(0.0, 2.55, -0.15)
	var g_mat := StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.35, 0.38, 0.42)
	g_mat.metallic = 0.6
	g_mat.roughness = 0.28
	gantry.material_override = g_mat
	root.add_child(gantry)

	var toolhead := MeshInstance3D.new()
	var th := BoxMesh.new()
	th.size = Vector3(0.55, 0.45, 0.5)
	toolhead.mesh = th
	toolhead.position = Vector3(0.65, 2.38, -0.15)
	var th_mat := StandardMaterial3D.new()
	th_mat.albedo_color = Color(0.15, 0.16, 0.18)
	th_mat.metallic = 0.75
	th_mat.roughness = 0.22
	toolhead.material_override = th_mat
	root.add_child(toolhead)

	# Core spool housing — ABS orange + translucent “glass” spool
	var spool := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.52
	cyl.bottom_radius = 0.52
	cyl.height = 0.42
	spool.mesh = cyl
	spool.position = Vector3(-0.85, 2.95, -0.15)
	spool.rotation_degrees = Vector3(90, 0, 0)
	var sp_mat := StandardMaterial3D.new()
	sp_mat.albedo_color = Color(1.0, 0.48, 0.22)
	sp_mat.metallic = 0.15
	sp_mat.roughness = 0.42
	sp_mat.emission_enabled = true
	sp_mat.emission = Color(1.0, 0.35, 0.12)
	sp_mat.emission_energy_multiplier = 0.35
	spool.material_override = sp_mat
	root.add_child(spool)

	var clear_spool := MeshInstance3D.new()
	var c2 := CylinderMesh.new()
	c2.top_radius = 0.38
	c2.bottom_radius = 0.38
	c2.height = 0.28
	clear_spool.mesh = c2
	clear_spool.position = Vector3(0.95, 2.92, 0.35)
	clear_spool.rotation_degrees = Vector3(90, 0, 18)
	var cs_mat := StandardMaterial3D.new()
	cs_mat.albedo_color = Color(0.85, 0.92, 1.0)
	cs_mat.metallic = 0.0
	cs_mat.roughness = 0.12
	cs_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cs_mat.albedo_color.a = 0.78
	clear_spool.material_override = cs_mat
	root.add_child(clear_spool)

	var bed := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(1.8, 0.06, 1.8)
	bed.mesh = plane
	bed.position = Vector3(0.0, 1.05, 0.45)
	var bed_mat := StandardMaterial3D.new()
	bed_mat.albedo_color = Color(0.2, 0.55, 0.95)
	bed_mat.emission_enabled = true
	bed_mat.emission = Color(0.25, 0.55, 1.0)
	bed_mat.emission_energy_multiplier = 0.25
	bed_mat.metallic = 0.4
	bed_mat.roughness = 0.2
	bed.material_override = bed_mat
	root.add_child(bed)

	# Ambient plastic dust
	var dust := GPUParticles3D.new()
	dust.amount = 110
	dust.lifetime = 4.0
	dust.explosiveness = 0.0
	dust.randomness = 0.45
	dust.visibility_aabb = AABB(Vector3(-6, -1, -6), Vector3(12, 8, 12))
	dust.position = Vector3(0.0, 3.0, 1.0)
	var dpm := ParticleProcessMaterial.new()
	dpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	dpm.emission_box_extents = Vector3(3.2, 0.25, 2.4)
	dpm.direction = Vector3(0.1, 1.0, 0.05)
	dpm.spread = 28.0
	dpm.initial_velocity_min = 0.05
	dpm.initial_velocity_max = 0.35
	dpm.gravity = Vector3(0, 0.04, 0)
	dpm.scale_min = 0.02
	dpm.scale_max = 0.07
	dpm.color = Color(1.0, 0.92, 0.65, 0.55)
	dust.process_material = dpm
	var dq := QuadMesh.new()
	dq.size = Vector2(0.09, 0.09)
	var dm := StandardMaterial3D.new()
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(1.0, 0.95, 0.75, 0.45)
	dm.emission_enabled = true
	dm.emission = Color(1.0, 0.85, 0.45)
	dm.emission_energy_multiplier = 0.8
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dq.material = dm
	dust.draw_pass_1 = dq
	root.add_child(dust)

	return root


func _particle_tex() -> Texture2D:
	var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	for y in range(10):
		for x in range(10):
			var d: float = Vector2(x - 5, y - 5).length()
			var a: float = clampf(1.0 - d / 5.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _attach_hover_sparks(btn: Button, accent: Color) -> void:
	var gp := GPUParticles2D.new()
	gp.z_index = 20
	gp.emitting = false
	gp.one_shot = true
	gp.amount = 32
	gp.lifetime = 0.42
	gp.explosiveness = 0.88
	gp.randomness = 0.35
	gp.visibility_rect = Rect2(-80, -80, 160, 160)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(48, 14, 0)
	pm.particle_flag_disable_z = true
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 65.0
	pm.initial_velocity_min = 80.0
	pm.initial_velocity_max = 220.0
	pm.gravity = Vector3(0, 180, 0)
	pm.scale_min = 0.15
	pm.scale_max = 0.42
	pm.color = Color(accent.r, accent.g, accent.b, 0.95)
	gp.process_material = pm
	gp.texture = _particle_tex()
	btn.add_child(gp)

	var place := func(): gp.position = btn.size * 0.5
	btn.resized.connect(place)
	place.call_deferred()

	btn.mouse_entered.connect(func():
		place.call()
		gp.restart()
		gp.emitting = true
	)


func _build_options_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2.ZERO

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var hdr := Label.new()
	hdr.text = "Options"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 22)
	vb.add_child(hdr)

	var ls: Dictionary = SaveSystem.load_local_settings()
	_chk_music = CheckBox.new()
	_chk_music.text = "Music"
	_chk_music.button_pressed = bool(ls.get("music", true))
	_chk_music.toggled.connect(func(on: bool): _persist_audio("music", on))
	vb.add_child(_chk_music)

	_chk_sfx = CheckBox.new()
	_chk_sfx.text = "Sound Effects"
	_chk_sfx.button_pressed = bool(ls.get("sfx", true))
	_chk_sfx.toggled.connect(func(on: bool): _persist_audio("sfx", on))
	vb.add_child(_chk_sfx)

	var btn_del := Button.new()
	btn_del.text = "Delete all progress…"
	btn_del.pressed.connect(func(): _confirm_delete.popup_centered())
	vb.add_child(btn_del)

	var btn_close := Button.new()
	btn_close.text = "Close"
	btn_close.pressed.connect(func(): _options_panel.visible = false)
	vb.add_child(btn_close)

	return panel


func _toggle_options() -> void:
	_options_panel.visible = not _options_panel.visible
	if _options_panel.visible:
		var ls2: Dictionary = SaveSystem.load_local_settings()
		_chk_music.button_pressed = bool(ls2.get("music", true))
		_chk_sfx.button_pressed = bool(ls2.get("sfx", true))


func _persist_audio(key: String, on: bool) -> void:
	var ls: Dictionary = SaveSystem.load_local_settings()
	ls[key] = on
	SaveSystem.write_local_settings(ls)
	AudioSettings.apply_from_local_settings()
	EventBus.request_toast.emit("Settings saved.")


func _on_delete_progress_confirmed() -> void:
	SaveSystem.delete_save()
	_refresh_continue_button()
	EventBus.request_toast.emit("Progress deleted.")
	_options_panel.visible = false


func _on_new_game_clicked() -> void:
	if SaveSystem.has_save():
		_confirm_new_game.popup_centered()
	else:
		new_game_confirmed.emit()


func _on_toast(message: String) -> void:
	_toast.text = message
