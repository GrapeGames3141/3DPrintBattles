extends Control

## Title screen: Hearthstone-style spatial layout (central framed menu + bottom shelf) over a 3D workshop desk.
## Signals: continue_pressed, new_game_confirmed, quit_pressed, open_shop_pressed, open_team_pressed, open_quests_pressed.

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
	_apply_overlay_label_theme()
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
	# SubViewport resolution follows SubViewportContainer when stretch is enabled — do not assign size manually.


func _refresh_continue_button() -> void:
	if _btn_continue != null:
		_btn_continue.disabled = not SaveSystem.has_save()


func _apply_overlay_label_theme() -> void:
	# Strong separation from busy 3D background (kid-safe readability).
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
	add_theme_constant_override("shadow_offset_x", 3)
	add_theme_constant_override("shadow_offset_y", 3)


func _build_ui() -> void:
	# Layer 0 — 3D workshop (full viewport).
	_vp_container = SubViewportContainer.new()
	_vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp_container.stretch = true
	add_child(_vp_container)

	_vp = SubViewport.new()
	var r: Rect2 = get_viewport_rect()
	_vp.size = Vector2i(maxi(2, int(r.size.x)), maxi(2, int(r.size.y)))
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_vp.handle_input_locally = false
	_vp_container.add_child(_vp)
	_vp.add_child(_build_title_world())

	# Layer 1 — UI (blocks raycasts; structured like Hearthstone: center frame + bottom shelf).
	var fg := Control.new()
	fg.set_anchors_preset(Control.PRESET_FULL_RECT)
	fg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var m: int = int(clampf(get_viewport_rect().size.x * 0.018, 10.0, 28.0))
	margin.add_theme_constant_override("margin_left", m)
	margin.add_theme_constant_override("margin_top", m)
	margin.add_theme_constant_override("margin_right", m)
	margin.add_theme_constant_override("margin_bottom", m)
	fg.add_child(margin)

	var root_col := VBoxContainer.new()
	root_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_col.add_theme_constant_override("separation", 0)
	margin.add_child(root_col)

	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.size_flags_stretch_ratio = 1.15
	root_col.add_child(top_spacer)

	var center_row := HBoxContainer.new()
	center_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_row.add_theme_constant_override("separation", 0)
	root_col.add_child(center_row)

	var left_pad := Control.new()
	left_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_row.add_child(left_pad)

	var center_wrap := CenterContainer.new()
	center_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_row.add_child(center_wrap)

	var main_frame := _build_hearthstone_main_frame()
	center_wrap.add_child(main_frame)

	var right_pad := Control.new()
	right_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_row.add_child(right_pad)

	var bot_spacer := Control.new()
	bot_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bot_spacer.size_flags_stretch_ratio = 0.82
	root_col.add_child(bot_spacer)

	root_col.add_child(_build_hearthstone_bottom_shelf())

	_toast = Label.new()
	_toast.text = ""
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_theme_font_size_override("font_size", 15)
	_toast.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	_toast.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_toast.add_theme_constant_override("shadow_offset_x", 2)
	_toast.add_theme_constant_override("shadow_offset_y", 2)
	root_col.add_child(_toast)

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


func _build_hearthstone_main_frame() -> Control:
	var ink := Color(0.08, 0.09, 0.14)

	var outer := PanelContainer.new()
	outer.mouse_filter = Control.MOUSE_FILTER_STOP
	outer.custom_minimum_size = Vector2(
		clampf(get_viewport_rect().size.x * 0.42, 320.0, 540.0),
		clampf(get_viewport_rect().size.y * 0.62, 420.0, 620.0)
	)
	var outer_sb := _stylebox_chunky_frame()
	outer.add_theme_stylebox_override("panel", outer_sb)

	var inner_col := VBoxContainer.new()
	inner_col.add_theme_constant_override("separation", 10)
	outer.add_child(inner_col)

	var title := Label.new()
	title.text = "3D PRINT BATTLES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.97, 0.9))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	inner_col.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Collect · Print · Battle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	inner_col.add_child(subtitle)

	var plate := PanelContainer.new()
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var plate_min: float = clampf(minf(outer.custom_minimum_size.x, outer.custom_minimum_size.y) * 0.92, 280.0, 480.0)
	plate.custom_minimum_size = Vector2(plate_min, plate_min)
	var plate_sb := _stylebox_circle_plate()
	plate.add_theme_stylebox_override("panel", plate_sb)

	var plate_margin := MarginContainer.new()
	plate_margin.add_theme_constant_override("margin_left", 18)
	plate_margin.add_theme_constant_override("margin_top", 22)
	plate_margin.add_theme_constant_override("margin_right", 18)
	plate_margin.add_theme_constant_override("margin_bottom", 18)
	plate.add_child(plate_margin)

	var btn_stack := VBoxContainer.new()
	btn_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_stack.add_theme_constant_override("separation", 12)
	plate_margin.add_child(btn_stack)

	var btn_w: float = clampf(plate_min - 52.0, 240.0, 400.0)
	var btn_h: float = 52.0

	_btn_continue = Button.new()
	_btn_continue.text = "Continue"
	_btn_continue.custom_minimum_size = Vector2(btn_w, btn_h)
	_btn_continue.disabled = not SaveSystem.has_save()
	_btn_continue.pressed.connect(func(): continue_pressed.emit())
	_apply_plastic_button(_btn_continue, Color(0.12, 0.82, 0.88), Color(0.2, 0.92, 0.98), Color(0.08, 0.58, 0.62), ink, 22)
	_attach_hover_sparks(_btn_continue, Color(0.35, 1.0, 0.95))
	btn_stack.add_child(_btn_continue)

	var btn_new := Button.new()
	btn_new.text = "New Game"
	btn_new.custom_minimum_size = Vector2(btn_w, btn_h)
	btn_new.pressed.connect(_on_new_game_clicked)
	_apply_plastic_button(btn_new, Color(0.98, 0.35, 0.62), Color(1.0, 0.48, 0.72), Color(0.72, 0.18, 0.42), ink, 22)
	_attach_hover_sparks(btn_new, Color(1.0, 0.55, 0.75))
	btn_stack.add_child(btn_new)

	var btn_opts := Button.new()
	btn_opts.text = "Options"
	btn_opts.custom_minimum_size = Vector2(btn_w, btn_h)
	btn_opts.pressed.connect(_toggle_options)
	_apply_plastic_button(btn_opts, Color(1.0, 0.86, 0.18), Color(1.0, 0.93, 0.38), Color(0.78, 0.62, 0.08), ink, 22)
	_attach_hover_sparks(btn_opts, Color(1.0, 0.95, 0.45))
	btn_stack.add_child(btn_opts)

	var btn_quit := Button.new()
	btn_quit.text = "Quit"
	btn_quit.custom_minimum_size = Vector2(btn_w, btn_h)
	btn_quit.pressed.connect(func(): quit_pressed.emit())
	_apply_plastic_button(btn_quit, Color(0.52, 0.42, 0.78), Color(0.62, 0.52, 0.92), Color(0.35, 0.28, 0.55), ink, 22)
	_attach_hover_sparks(btn_quit, Color(0.75, 0.55, 1.0))
	btn_stack.add_child(btn_quit)

	inner_col.add_child(plate)

	return outer


func _stylebox_chunky_frame() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.14, 0.09, 0.07, 0.92)
	s.border_color = Color(0.72, 0.52, 0.28, 0.95)
	s.set_border_width_all(5)
	s.corner_radius_top_left = 18
	s.corner_radius_top_right = 18
	s.corner_radius_bottom_left = 18
	s.corner_radius_bottom_right = 18
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 18
	s.shadow_offset = Vector2(4, 8)
	s.content_margin_left = 20
	s.content_margin_top = 18
	s.content_margin_right = 20
	s.content_margin_bottom = 18
	return s


func _stylebox_circle_plate() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.06, 0.12, 0.72)
	s.border_color = Color(0.35, 0.85, 0.98, 0.55)
	s.set_border_width_all(4)
	var rad := 240
	s.corner_radius_top_left = rad
	s.corner_radius_top_right = rad
	s.corner_radius_bottom_right = rad
	s.corner_radius_bottom_left = rad
	s.shadow_color = Color(0.15, 0.55, 0.95, 0.35)
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left = 12
	s.content_margin_top = 12
	s.content_margin_right = 12
	s.content_margin_bottom = 12
	return s


func _apply_plastic_button(
	btn: Button,
	bg: Color,
	bg_hover: Color,
	bg_press: Color,
	ink: Color,
	pill_r: int
) -> void:
	var stacks: Array = UiTheme.pill_styleboxes(bg, bg_hover, bg_press, ink, pill_r)
	btn.add_theme_stylebox_override("normal", stacks[0])
	btn.add_theme_stylebox_override("hover", stacks[1])
	btn.add_theme_stylebox_override("pressed", stacks[2])
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", ink)
	btn.add_theme_color_override("font_hover_color", ink)
	btn.add_theme_color_override("font_pressed_color", ink)


func _build_hearthstone_bottom_shelf() -> Control:
	var shelf := PanelContainer.new()
	shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelf.custom_minimum_size = Vector2(0, 108)
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0.1, 0.07, 0.06, 0.88)
	sh.border_color = Color(0.5, 0.36, 0.22, 0.75)
	sh.set_border_width_all(3)
	sh.corner_radius_top_left = 14
	sh.corner_radius_top_right = 14
	sh.corner_radius_bottom_left = 14
	sh.corner_radius_bottom_right = 14
	sh.shadow_color = Color(0, 0, 0, 0.45)
	sh.shadow_size = 12
	sh.shadow_offset = Vector2(2, 5)
	sh.content_margin_left = 14
	sh.content_margin_top = 12
	sh.content_margin_right = 14
	sh.content_margin_bottom = 12
	shelf.add_theme_stylebox_override("panel", sh)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	shelf.add_child(row)

	# Left — circular shortcuts (match reference: icons on the left).
	row.add_child(_make_hud_icon_button("Shop", "◉", Color(0.85, 0.45, 1.0), func(): open_shop_pressed.emit()))
	row.add_child(_make_hud_icon_button("Team", "⚙", Color(0.35, 0.92, 0.55), func(): open_team_pressed.emit()))

	var mid_sp := Control.new()
	mid_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_sp.custom_minimum_size.x = 8
	row.add_child(mid_sp)

	# Center — two wide “drawer” buttons (Open Packs / Collection analogue).
	var wide_a := _make_wide_shelf_button("Filament Shop", Color(0.95, 0.55, 0.22), func(): open_shop_pressed.emit())
	var wide_b := _make_wide_shelf_button("Team Bench", Color(0.22, 0.78, 0.95), func(): open_team_pressed.emit())
	row.add_child(wide_a)
	row.add_child(wide_b)

	var mid_sp2 := Control.new()
	mid_sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_sp2.custom_minimum_size.x = 8
	row.add_child(mid_sp2)

	row.add_child(_make_hud_icon_button("Quests", "✦", Color(1.0, 0.78, 0.22), func(): open_quests_pressed.emit()))

	var ver_col := VBoxContainer.new()
	ver_col.alignment = BoxContainer.ALIGNMENT_CENTER
	var ver := Label.new()
	ver.text = "v %s" % ProjectSettings.get_setting("application/config/version", "0.1")
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", Color(0.92, 0.88, 0.82))
	ver.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	ver.add_theme_constant_override("shadow_offset_x", 1)
	ver.add_theme_constant_override("shadow_offset_y", 1)
	ver_col.add_child(ver)

	var gear := Button.new()
	gear.text = "⚙"
	gear.custom_minimum_size = Vector2(44, 44)
	gear.flat = false
	_apply_plastic_button(gear, Color(0.35, 0.38, 0.48), Color(0.45, 0.5, 0.62), Color(0.25, 0.28, 0.36), Color(0.06, 0.07, 0.1), 22)
	gear.pressed.connect(_toggle_options)
	_attach_hover_sparks(gear, Color(0.7, 0.85, 1.0))
	ver_col.add_child(gear)
	row.add_child(ver_col)

	return shelf


func _make_wide_shelf_button(text_str: String, accent: Color, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text_str
	b.custom_minimum_size = Vector2(168, 56)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_stretch_ratio = 0.5
	var ink := Color(0.06, 0.07, 0.1)
	var stacks: Array = UiTheme.pill_styleboxes(
		accent.lightened(0.08),
		accent.lightened(0.18),
		accent.darkened(0.12),
		ink,
		16
	)
	b.add_theme_stylebox_override("normal", stacks[0])
	b.add_theme_stylebox_override("hover", stacks[1])
	b.add_theme_stylebox_override("pressed", stacks[2])
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", ink)
	b.pressed.connect(on_press)
	_attach_hover_sparks(b, accent)
	return b


func _make_hud_icon_button(label: String, glyph: String, accent: Color, on_press: Callable) -> Control:
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 72)
	btn.flat = false
	var ink := Color(0.1, 0.12, 0.18)
	var pk: Array = UiTheme.pill_styleboxes(
		Color(0.22, 0.22, 0.26),
		Color(accent.r * 0.35 + 0.2, accent.g * 0.35 + 0.2, accent.b * 0.35 + 0.2),
		Color(accent.r * 0.55, accent.g * 0.55, accent.b * 0.55),
		ink,
		36
	)
	btn.add_theme_stylebox_override("normal", pk[0])
	btn.add_theme_stylebox_override("hover", pk[1])
	btn.add_theme_stylebox_override("pressed", pk[2])
	btn.add_theme_stylebox_override("disabled", pk[2])

	var inner := Label.new()
	inner.text = glyph
	inner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inner.add_theme_font_size_override("font_size", 26)
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
	cap.add_theme_font_size_override("font_size", 12)
	cap.add_theme_color_override("font_color", Color(0.94, 0.9, 0.85))
	cap.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	cap.add_theme_constant_override("shadow_offset_x", 1)
	cap.add_theme_constant_override("shadow_offset_y", 1)
	vb.add_child(cap)

	return vb


func _build_title_world() -> Node3D:
	var root := Node3D.new()

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.055, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.52, 0.72)
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.38
	env.glow_strength = 0.8
	env.glow_mix = 0.07
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 0.92
	env.glow_bloom = 0.06
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.2
	env.ssao_power = 1.4
	env.ssao_light_affect = 0.3
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 24, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.shadow_enabled = true
	sun.light_angular_distance = 0.4
	sun.shadow_blur = 1.25
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_max_distance = 55.0
	root.add_child(sun)

	var key := OmniLight3D.new()
	key.position = Vector3(2.6, 3.0, 4.2)
	key.light_energy = 2.2
	key.light_color = Color(1.0, 0.86, 0.55)
	key.omni_range = 12.0
	root.add_child(key)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.8, 2.0, 3.2)
	fill.light_energy = 1.5
	fill.light_color = Color(0.6, 0.75, 1.0)
	fill.omni_range = 11.0
	root.add_child(fill)

	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 2.5, 7.4)
	cam.rotation_degrees = Vector3(-13.0, 0.0, 0.0)
	cam.fov = 48.0
	cam.current = true
	root.add_child(cam)

	# Wide desk surface — fills lower frame (workshop hero read).
	var desk := MeshInstance3D.new()
	var dmesh := BoxMesh.new()
	dmesh.size = Vector3(10.0, 0.22, 5.5)
	desk.mesh = dmesh
	desk.position = Vector3(0.0, 0.85, 1.2)
	var desk_m := StandardMaterial3D.new()
	desk_m.albedo_color = Color(0.32, 0.2, 0.12)
	desk_m.metallic = 0.04
	desk_m.roughness = 0.78
	desk.material_override = desk_m
	root.add_child(desk)

	# Pedestal / build plate with filament shader (visual anchor behind UI center).
	var ped := MeshInstance3D.new()
	var ped_mesh := BoxMesh.new()
	ped_mesh.size = Vector3(4.8, 1.15, 3.8)
	ped.mesh = ped_mesh
	ped.position = Vector3(0.0, 0.58, -0.6)
	var crack_mat := ShaderMaterial.new()
	crack_mat.shader = _CRACK_SHADER
	crack_mat.set_shader_parameter("wood_albedo", Color(0.3, 0.18, 0.1))
	crack_mat.set_shader_parameter("crack_scale", 13.0)
	crack_mat.set_shader_parameter("pulse_speed", 1.2)
	crack_mat.set_shader_parameter("emission_strength", 3.0)
	ped.material_override = crack_mat
	root.add_child(ped)

	var body := MeshInstance3D.new()
	var body_m := CylinderMesh.new()
	body_m.top_radius = 1.05
	body_m.bottom_radius = 1.05
	body_m.height = 1.35
	body.mesh = body_m
	body.position = Vector3(-1.1, 1.55, 0.35)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.85, 0.95)
	body_mat.metallic = 0.12
	body_mat.roughness = 0.24
	body.material_override = body_mat
	root.add_child(body)

	var body2 := MeshInstance3D.new()
	var bm2 := CylinderMesh.new()
	bm2.top_radius = 0.72
	bm2.bottom_radius = 0.72
	bm2.height = 1.2
	body2.mesh = bm2
	body2.position = Vector3(1.35, 1.48, 0.2)
	var orange := StandardMaterial3D.new()
	orange.albedo_color = Color(1.0, 0.42, 0.15)
	orange.metallic = 0.1
	orange.roughness = 0.26
	orange.emission_enabled = true
	orange.emission = Color(1.0, 0.3, 0.08)
	orange.emission_energy_multiplier = 0.25
	body2.material_override = orange
	root.add_child(body2)

	var spool := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.48
	cyl.bottom_radius = 0.48
	cyl.height = 0.38
	spool.mesh = cyl
	spool.position = Vector3(2.2, 2.05, 0.5)
	spool.rotation_degrees = Vector3(90, 0, 15)
	var sp_m := StandardMaterial3D.new()
	sp_m.albedo_color = Color(0.9, 0.92, 0.98)
	sp_m.metallic = 0.08
	sp_m.roughness = 0.22
	spool.material_override = sp_m
	root.add_child(spool)

	var bed := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(1.6, 0.05, 1.6)
	bed.mesh = plane
	bed.position = Vector3(-1.1, 1.02, 0.35)
	var bed_mat := StandardMaterial3D.new()
	bed_mat.albedo_color = Color(0.18, 0.5, 0.95)
	bed_mat.emission_enabled = true
	bed_mat.emission = Color(0.2, 0.5, 1.0)
	bed_mat.emission_energy_multiplier = 0.3
	bed_mat.metallic = 0.35
	bed_mat.roughness = 0.2
	bed.material_override = bed_mat
	root.add_child(bed)

	var dust := GPUParticles3D.new()
	dust.amount = 90
	dust.lifetime = 4.0
	dust.explosiveness = 0.0
	dust.randomness = 0.45
	dust.position = Vector3(0.0, 2.8, 1.0)
	var dpm := ParticleProcessMaterial.new()
	dpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	dpm.emission_box_extents = Vector3(4.0, 0.2, 2.5)
	dpm.direction = Vector3(0.05, 1.0, 0.05)
	dpm.spread = 26.0
	dpm.initial_velocity_min = 0.04
	dpm.initial_velocity_max = 0.32
	dpm.gravity = Vector3(0, 0.035, 0)
	dpm.scale_min = 0.02
	dpm.scale_max = 0.065
	dpm.color = Color(1.0, 0.9, 0.6, 0.5)
	dust.process_material = dpm
	var dq := QuadMesh.new()
	dq.size = Vector2(0.08, 0.08)
	var dm := StandardMaterial3D.new()
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(1.0, 0.95, 0.75, 0.42)
	dm.emission_enabled = true
	dm.emission = Color(1.0, 0.85, 0.45)
	dm.emission_energy_multiplier = 0.75
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
	gp.amount = 28
	gp.lifetime = 0.4
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
