extends Control
## Test-only supplementary evidence for the approved M7 blueprint family.  It
## resolves the real runtime manifest textures without substituting raw prints or
## living sprites, then composites native labels over a neutral parchment field.

const IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const REVIEW_IDS := ["cinderpaw", "aurorawing", "worldcoil", "skyforge", "verdantitan", "voltwig", "runestag"]

var before_profile := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport := _requested_viewport()
	if viewport.x > 0: DisplayServer.window_set_size(viewport)
	before_profile = var_to_str(GameManager.profile)
	call_deferred("_build_and_capture")

func _build_and_capture() -> void:
	await get_tree().process_frame
	var background := ColorRect.new()
	background.color = Color("ead9b5")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var heading := Label.new()
	heading.text = "M7 BLUEPRINTS · RUNTIME RESOLVER"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color("21344b"))
	heading.anchor_left = 0.05; heading.anchor_right = 0.95; heading.anchor_top = 0.025; heading.anchor_bottom = 0.085
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	grid.anchor_left = 0.05; grid.anchor_right = 0.95; grid.anchor_top = 0.10; grid.anchor_bottom = 0.965
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grid)
	for creature_id in REVIEW_IDS:
		var card := _review_card(creature_id)
		grid.add_child(card)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if var_to_str(GameManager.profile) != before_profile:
		push_error("M7 contact-sheet blueprint resolution mutated the profile.")
		get_tree().quit(1)
		return
	var image := get_viewport().get_texture().get_image()
	var expected := _requested_viewport()
	if image == null or image.get_size() != expected:
		push_error("M7 contact-sheet capture dimensions mismatch.")
		get_tree().quit(1)
		return
	var output := _requested_output()
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	if image.save_png(output) != OK:
		push_error("M7 contact-sheet PNG save failed: %s" % output)
		get_tree().quit(1)
		return
	print("M7_BLUEPRINT_CONTACT_SHEET output=%s" % output)
	get_tree().quit(0)

func _review_card(creature_id: String) -> Control:
	var seat := PanelContainer.new()
	seat.custom_minimum_size = Vector2(0, 185)
	seat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color("f4e7cb")
	outer.border_color = Color("72512c")
	outer.set_border_width_all(3)
	outer.corner_radius_top_left = 10; outer.corner_radius_top_right = 10; outer.corner_radius_bottom_left = 10; outer.corner_radius_bottom_right = 10
	seat.add_theme_stylebox_override("panel", outer)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	seat.add_child(column)
	var name_label := Label.new()
	name_label.text = creature_id.capitalize()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color("21344b"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(name_label)
	var aperture := Control.new()
	aperture.clip_contents = true
	aperture.custom_minimum_size = Vector2(0, 134)
	aperture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aperture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(aperture)
	var texture := IMPRINT.blueprint_texture(Catalog.creature(creature_id))
	if texture == null or IMPRINT.is_neutral_placeholder(texture):
		push_error("M7 contact-sheet resolver did not return approved blueprint art: %s" % creature_id)
	var art := TextureRect.new()
	art.name = "M7Blueprint_%s" % creature_id.capitalize()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aperture.add_child(art)
	return seat

func _requested_viewport() -> Vector2i:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-viewport="):
			var values := arg.trim_prefix("--capture-viewport=").split("x")
			if values.size() == 2: return Vector2i(int(values[0]), int(values[1]))
	return Vector2i(576, 1024)

func _requested_output() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-output="): return arg.trim_prefix("--capture-output=")
	return "E:/AI Projects/games/3d print battler/build/evidence/m7-blueprint-runtime-promotion/captures-r1/M7-BlueprintContactSheet.png"
