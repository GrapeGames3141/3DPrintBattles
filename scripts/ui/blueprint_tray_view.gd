class_name BlueprintTrayView
extends RefCounted
## Builds the station-local Blueprint Tray from Main-supplied UI primitives.
## Main owns navigation, open/close state, and the selected blueprint ID.

var _cached_profile_blueprints: Array = []
var _cached_ids: Array[String] = []

func _section_heading(text_value: String, size: int, color: Color, role: String, context: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "BlueprintTraySectionHeader"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", context.section_header_style.call(role))
	var title: Label = context.label.call(text_value, size, color)
	title.name = "BlueprintTraySectionHeaderTitle"
	title.custom_minimum_size.y = 30
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(title)
	return panel

func blueprint_ids(profile: Dictionary) -> Array[String]:
	var stored_blueprints: Array = profile.get("blueprints", [])
	if stored_blueprints != _cached_profile_blueprints:
		_cached_profile_blueprints = stored_blueprints.duplicate(true)
		_cached_ids.clear()
		for stored_id in stored_blueprints:
			var creature_id := str(stored_id)
			if not creature_id.is_empty() and not Catalog.creature(creature_id).is_empty() and creature_id not in _cached_ids:
				_cached_ids.append(creature_id)
		_cached_ids.sort_custom(func(left: String, right: String) -> bool: return str(Catalog.creature(left).get("name", left)) < str(Catalog.creature(right).get("name", right)))
	return _cached_ids.duplicate()

func _owned_count(profile: Dictionary, creature_id: String) -> int:
	var count := 0
	for instance in profile.get("creatures", []):
		if str(instance.get("creature_id", "")) == creature_id:
			count += 1
	return count

func _idle_texture(definition: Dictionary) -> Texture2D:
	var path := str(definition.get("sprite_sheet", ""))
	var sheet := ResourceLoader.load(path) as Texture2D if not path.is_empty() else null
	if sheet != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		# Stay inside the idle cell so filtered compact thumbnails cannot leak frames.
		atlas.region = Rect2(2, 2, 380, 508)
		return atlas
	var raw_path := str(definition.get("raw_print", ""))
	return ResourceLoader.load(raw_path) as Texture2D if not raw_path.is_empty() else null

func _card(creature_id: String, selected: bool, context: Dictionary) -> Control:
	var definition := Catalog.creature(creature_id)
	var rarity := Catalog.rarity(str(definition.get("rarity", "common")))
	var portrait: bool = bool(context.portrait)
	var card := Control.new()
	card.name = "PrinterBlueprintCard%s" % creature_id.capitalize()
	card.set_meta("creature_id", creature_id)
	card.set_meta("price", int(rarity.get("print", 0)))
	card.set_meta("owned_count", _owned_count(context.profile, creature_id))
	card.custom_minimum_size = Vector2(156 if portrait else 168, 208 if portrait else 156)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var select_button := Button.new()
	select_button.name = "PrinterSelect%s" % creature_id.capitalize()
	select_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select_button.accessibility_name = ("Selected " if selected else "Inspect ") + str(definition.get("name", creature_id)) + " blueprint"
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		select_button.add_theme_stylebox_override(state, context.cartridge_style.call(selected or state in ["hover", "focus"]))
	select_button.pressed.connect(context.select_blueprint.bind(creature_id))
	card.add_child(select_button)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	content.add_theme_constant_override("separation", 3)
	card.add_child(content)
	var title: Label = context.label.call(str(definition.get("name", creature_id)), 16, Color("ffd36c") if selected else Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var preview := TextureRect.new()
	preview.name = "PrinterBlueprintIdleArt"
	preview.custom_minimum_size = Vector2(0, 108 if portrait else 64)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = _idle_texture(definition)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(preview)
	var facts: Label = context.label.call("%s / %s" % [str(definition.get("element", "Unknown")), str(rarity.get("name", "Common"))], 12, Color("b8dcef"))
	facts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(facts)
	var indicator: Label = context.label.call("Selected" if selected else "Inspect", 12, Color("ffd36c") if selected else Color("dce8f4"))
	indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(indicator)
	return card

func _detail(creature_id: String, use_tray_heading: bool, context: Dictionary) -> Control:
	var definition := Catalog.creature(creature_id)
	var rarity := Catalog.rarity(str(definition.get("rarity", "common")))
	var detail := VBoxContainer.new()
	detail.name = "PrinterBlueprintDetail"
	detail.add_theme_constant_override("separation", 8)
	# The landscape detail panel is already an inset well; keeping its title as a
	# direct child preserves the established first-fold geometry at short heights.
	var heading: Label = context.label.call("Blueprint Tray - Choose a Print" if use_tray_heading else "Blueprint Detail", 18, Color("ffd36c") if use_tray_heading else Color("9beaff"))
	heading.name = "PrinterBlueprintTrayTitle" if use_tray_heading else "PrinterBlueprintDetailTitle"
	heading.custom_minimum_size.y = 30
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail.add_child(heading)
	var art := TextureRect.new()
	art.name = "PrinterBlueprintDetailArt"
	art.custom_minimum_size = Vector2(0, 180)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = _idle_texture(definition)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(art)
	detail.add_child(context.label.call(str(definition.get("name", creature_id)), 23, Color("ffd36c")))
	detail.add_child(context.label.call("%s  •  %s" % [str(definition.get("element", "Unknown")), str(rarity.get("name", "Common"))], 14, Color("b8dcef")))
	detail.add_child(context.label.call("Forge Coin print: %d" % int(rarity.get("print", 0)), 14, Color("a8e3a5")))
	detail.add_child(context.label.call("Owned prints: %d" % _owned_count(context.profile, creature_id), 14, Color("a8e3a5")))
	detail.add_child(context.label.call("Previewing is safe. Coins and inventory remain unchanged until Begin Print reaches the secured commit seam.", 14, Color("e6dfd0")))
	var preview_button: Button = context.make_button.call("Preview in Arcane Forge", context.preview_print.bind(creature_id), Color("a86b2e"))
	preview_button.name = "PrinterPreview%s" % creature_id.capitalize()
	preview_button.tooltip_text = "Preview %s in the Arcane Forge" % str(definition.get("name", creature_id))
	detail.add_child(preview_button)
	return detail

func render(host: Control, selected_id: String, context: Dictionary) -> String:
	var tray: VBoxContainer = context.make_panel.call(Color("15344bea"), Color("f1be69"))
	tray.get_parent().name = "PrinterBlueprintTray"
	host.add_child(tray.get_parent())
	# The Printer station reserves a narrow landscape side column. Treat that
	# local host like a compact tray instead of squeezing a two-column detail
	# workspace into it; the standalone Tray still uses its broad layout.
	var wide := not bool(context.portrait) and not bool(context.get("compact_host", false))
	if bool(context.portrait):
		var title_inset := Control.new()
		title_inset.custom_minimum_size = Vector2(0, 10)
		tray.add_child(title_inset)
		var tray_title := _section_heading("Blueprint Tray - Choose a Print", 21, Color("ffd36c"), "commit", context)
		tray_title.name = "BlueprintTrayHeader"
		var tray_title_label := tray_title.find_child("BlueprintTraySectionHeaderTitle", true, false) as Label
		if tray_title_label != null: tray_title_label.name = "PrinterBlueprintTrayTitle"
		tray.add_child(tray_title)
		tray.add_child(context.label.call("Previewing is safe: Forge Coins and inventory change only when Begin Print reaches the secured commit seam.", 14, Color("dce8f4")))
	var ids := blueprint_ids(context.profile)
	if ids.is_empty():
		var empty: Label = context.label.call("No learned creature blueprints are ready. Visit Forge Offers to learn a pattern, then return to this bench.", 16, Color("fff0a1"))
		empty.name = "PrinterBlueprintEmptyState"
		tray.add_child(empty)
		var offers: Button = context.make_button.call("Open Forge Offers", context.open_offers, Color("2f93a8"))
		offers.name = "PrinterBlueprintEmptyOffers"
		tray.add_child(offers)
		tray.add_child(context.make_button.call("Close Blueprint Tray", context.close_tray, Color("536c8d")))
		return selected_id
	if selected_id not in ids:
		selected_id = str(ids[0])
	var workspace: Control = HBoxContainer.new() if wide else VBoxContainer.new()
	workspace.name = "PrinterBlueprintWorkspace"
	workspace.add_theme_constant_override("separation", 12)
	tray.add_child(workspace)
	if not bool(context.reduced_motion):
		workspace.modulate.a = 0.0
		var reveal := host.create_tween()
		reveal.tween_property(workspace, "modulate:a", 1.0, 0.12)
	var cards_host: Control
	if wide:
		cards_host = GridContainer.new()
		(cards_host as GridContainer).columns = 2
		cards_host.custom_minimum_size = Vector2(380, 0)
	else:
		var scroller := ScrollContainer.new()
		scroller.name = "PrinterBlueprintCartridgeStrip"
		scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroller.custom_minimum_size = Vector2(0, 222)
		workspace.add_child(scroller)
		var strip := HBoxContainer.new()
		strip.name = "PrinterBlueprintCartridgeStripContents"
		strip.add_theme_constant_override("separation", 10)
		scroller.add_child(strip)
		cards_host = strip
	cards_host.name = "PrinterBlueprintGrid"
	cards_host.add_theme_constant_override("separation", 10)
	if wide:
		workspace.add_child(cards_host)
	for creature_id in ids:
		cards_host.add_child(_card(creature_id, creature_id == selected_id, context))
	var detail_panel := PanelContainer.new()
	detail_panel.name = "PrinterBlueprintDetailPanel"
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", context.inset_style.call(Color("102940ec"), Color("6bd6ed")))
	# In a compact landscape side host the detail well owns the tray heading,
	# just like the full landscape workspace. Portrait keeps its heading above
	# the horizontal cartridge strip for easier touch scanning.
	detail_panel.add_child(_detail(selected_id, not bool(context.portrait), context))
	workspace.add_child(detail_panel)
	tray.add_child(context.make_button.call("Close Blueprint Tray", context.close_tray, Color("536c8d")))
	return selected_id
