class_name CombatHudBuilder
extends RefCounted


func build(owner: Node, callbacks: Dictionary) -> Dictionary:
	var refs := {}
	var canvas := CanvasLayer.new()
	canvas.name = "CombatUI"
	owner.add_child(canvas)

	var top_bar := PanelContainer.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 58.0
	top_bar.add_theme_stylebox_override("panel", _panel_style(Color("#101b2dda"), Color("#d7bb75")))
	canvas.add_child(top_bar)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 28)
	top_bar.add_child(top_row)
	refs["top_status"] = _label("PRINTFORGE // COMBAT PROOF", 20, Color("#ffd886"))
	refs["top_status"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(refs["top_status"])
	refs["round_label"] = _label("ROUND 1", 18, Color.WHITE)
	top_row.add_child(refs["round_label"])
	refs["printer_label"] = _label("FORGES G50 • E50", 16, Color("#ffb49c"))
	top_row.add_child(refs["printer_label"])
	refs["filament_label"] = _label("FILAMENT", 18, Color("#7de3b0"))
	top_row.add_child(refs["filament_label"])
	refs["active_label"] = _label("DEPLOYMENT", 18, Color("#8ccfff"))
	refs["active_label"].custom_minimum_size.x = 290.0
	top_row.add_child(refs["active_label"])
	var reset_view_button := action_button("RESET VIEW")
	reset_view_button.custom_minimum_size = Vector2(112.0, 38.0)
	reset_view_button.pressed.connect(callbacks["reset_view"])
	top_row.add_child(reset_view_button)

	var roster_box := PanelContainer.new()
	roster_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	roster_box.position = Vector2(16.0, -245.0)
	roster_box.size = Vector2(300.0, 490.0)
	roster_box.add_theme_stylebox_override("panel", _panel_style(Color("#101b2ded"), Color("#53718b")))
	canvas.add_child(roster_box)
	var roster_margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		roster_margin.add_theme_constant_override(side, 12)
	roster_box.add_child(roster_margin)
	refs["roster_panel"] = VBoxContainer.new()
	refs["roster_panel"].add_theme_constant_override("separation", 8)
	roster_margin.add_child(refs["roster_panel"])

	var inspector_box := PanelContainer.new()
	inspector_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	inspector_box.position = Vector2(-316.0, -245.0)
	inspector_box.size = Vector2(300.0, 490.0)
	inspector_box.add_theme_stylebox_override("panel", _panel_style(Color("#101b2ded"), Color("#53718b")))
	canvas.add_child(inspector_box)
	var inspector_margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		inspector_margin.add_theme_constant_override(side, 14)
	inspector_box.add_child(inspector_margin)
	var inspector_column := VBoxContainer.new()
	inspector_column.add_theme_constant_override("separation", 8)
	inspector_margin.add_child(inspector_column)
	refs["inspector_title"] = _label("SELECT A UNIT", 22, Color("#ffd886"))
	refs["inspector_title"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector_column.add_child(refs["inspector_title"])
	refs["inspector_portrait"] = TextureRect.new()
	refs["inspector_portrait"].custom_minimum_size.y = 92.0
	refs["inspector_portrait"].expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	refs["inspector_portrait"].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inspector_column.add_child(refs["inspector_portrait"])
	refs["inspector_body"] = _label("Choose a roster card to deploy, or click a figure on the field.", 14, Color("#d8e2ed"))
	refs["inspector_body"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	refs["inspector_body"].size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_column.add_child(refs["inspector_body"])

	var bottom_box := PanelContainer.new()
	bottom_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom_box.position = Vector2(-350.0, -82.0)
	bottom_box.size = Vector2(700.0, 66.0)
	bottom_box.add_theme_stylebox_override("panel", _panel_style(Color("#101b2ded"), Color("#d7bb75")))
	canvas.add_child(bottom_box)
	refs["action_panel"] = HBoxContainer.new()
	refs["action_panel"].alignment = BoxContainer.ALIGNMENT_CENTER
	refs["action_panel"].add_theme_constant_override("separation", 12)
	bottom_box.add_child(refs["action_panel"])
	refs["attack_button"] = action_button("BASIC ATTACK")
	refs["attack_button"].pressed.connect(callbacks["attack"])
	refs["action_panel"].add_child(refs["attack_button"])
	refs["ability_button"] = action_button("ABILITY")
	refs["ability_button"].pressed.connect(callbacks["ability"])
	refs["action_panel"].add_child(refs["ability_button"])
	refs["wait_button"] = action_button("WAIT")
	refs["wait_button"].pressed.connect(callbacks["wait"])
	refs["action_panel"].add_child(refs["wait_button"])
	refs["skip_spawn_button"] = action_button("SKIP SPAWN")
	refs["skip_spawn_button"].pressed.connect(callbacks["skip_spawn"])
	refs["action_panel"].add_child(refs["skip_spawn_button"])

	refs["session_overlay"] = _build_modal(canvas, "CHOOSE BATTLE MODE", "Solo keeps the tactical AI. ENet hosts and joins a direct two-player match on UDP port 7000.")
	var session_panel: PanelContainer = refs["session_overlay"].get_node("Panel")
	session_panel.position = Vector2(-285.0, -175.0)
	session_panel.size = Vector2(570.0, 350.0)
	var session_column: VBoxContainer = refs["session_overlay"].get_node("Panel/Margin/Column")
	refs["address_input"] = LineEdit.new()
	refs["address_input"].placeholder_text = "Host address, for example 192.168.1.25"
	refs["address_input"].text = "127.0.0.1"
	refs["address_input"].custom_minimum_size = Vector2(450.0, 40.0)
	session_column.add_child(refs["address_input"])
	session_column.move_child(refs["address_input"], session_column.get_node("Buttons").get_index())
	refs["session_status"] = _label("", 14, Color("#ffb49c"))
	refs["session_status"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	refs["session_status"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	session_column.add_child(refs["session_status"])
	session_column.move_child(refs["session_status"], session_column.get_node("Buttons").get_index())
	var session_buttons: HBoxContainer = refs["session_overlay"].get_node("Panel/Margin/Column/Buttons")
	var solo_button := action_button("SOLO VS AI")
	solo_button.pressed.connect(callbacks["solo"])
	session_buttons.add_child(solo_button)
	var host_button := action_button("HOST ENET")
	host_button.pressed.connect(callbacks["host"])
	session_buttons.add_child(host_button)
	var join_button := action_button("JOIN ENET")
	join_button.pressed.connect(func() -> void: callbacks["join"].call(refs["address_input"].text))
	session_buttons.add_child(join_button)

	refs["faction_overlay"] = _build_modal(canvas, "CHOOSE YOUR ARMY", "The other army is controlled by the tactical AI.")
	var modal_buttons: HBoxContainer = refs["faction_overlay"].get_node("Panel/Margin/Column/Buttons")
	var elves_button := action_button("PLAY ELVES")
	elves_button.pressed.connect(callbacks["choose_faction"].bind("elves"))
	modal_buttons.add_child(elves_button)
	var goblins_button := action_button("PLAY GOBLINS")
	goblins_button.pressed.connect(callbacks["choose_faction"].bind("goblins"))
	modal_buttons.add_child(goblins_button)
	refs["faction_overlay"].visible = false

	refs["winner_overlay"] = _build_modal(canvas, "BATTLE COMPLETE", "")
	refs["winner_label"] = refs["winner_overlay"].get_node("Panel/Margin/Column/Body")
	var winner_buttons: HBoxContainer = refs["winner_overlay"].get_node("Panel/Margin/Column/Buttons")
	var rematch := action_button("REMATCH")
	rematch.pressed.connect(callbacks["reload"])
	winner_buttons.add_child(rematch)
	refs["winner_overlay"].visible = false
	return refs


func label(text_value: String, size: int, color: Color) -> Label:
	return _label(text_value, size, color)


func action_button(text_value: String) -> Button:
	var result := Button.new()
	result.text = text_value
	result.custom_minimum_size = Vector2(145.0, 42.0)
	result.add_theme_font_size_override("font_size", 15)
	return result


func _build_modal(canvas: CanvasLayer, heading: String, body: String) -> Control:
	var shade := ColorRect.new()
	shade.color = Color("#07101bd9")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(shade)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-270.0, -125.0)
	panel.size = Vector2(540.0, 250.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#132238"), Color("#d7bb75"), 3))
	shade.add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var title := _label(heading, 28, Color("#ffd886"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var body_label := _label(body, 17, Color("#d8e2ed"))
	body_label.name = "Body"
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body_label)
	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)
	return shade


func _panel_style(color: Color, border: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


func _label(text_value: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result
