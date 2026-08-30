class_name BlueprintTrayView
extends RefCounted
## Compact learned-blueprint cartridge selector embedded in Main's Arcane Forge.
## Main owns the dormant preview, navigation, and all transaction authority.

var _cached_profile_blueprints: Array = []
var _cached_ids: Array[String] = []

func blueprint_ids(profile: Dictionary) -> Array[String]:
	# The v3 Workshop owns blueprint records separately from battle cards and
	# retired creature instances.  Restrict the one-time Forge animation to
	# creature blueprints; equipment is collection/deck content, not a legacy
	# suit print.
	var stored_blueprints: Array = []
	for stored_id in profile.get("owned_blueprints", {}).keys():
		if UnifiedRules.has_printable_blueprint(profile, str(stored_id)):
			stored_blueprints.append(str(stored_id))
	stored_blueprints.sort()
	if stored_blueprints != _cached_profile_blueprints:
		_cached_profile_blueprints = stored_blueprints.duplicate(true)
		_cached_ids.clear()
		for stored_id in stored_blueprints:
			var creature_id := str(stored_id)
			if not creature_id.is_empty() and not Catalog.creature(creature_id).is_empty() and creature_id not in _cached_ids:
				_cached_ids.append(creature_id)
		_cached_ids.sort_custom(func(left: String, right: String) -> bool: return str(Catalog.creature(left).get("name", left)) < str(Catalog.creature(right).get("name", right)))
	return _cached_ids.duplicate()

func owned_count(profile: Dictionary, creature_id: String) -> int:
	var count := 0
	for model in profile.get("printed_models", {}).values():
		if model is Dictionary and str(model.get("blueprint_id", "")) == creature_id:
			count += 1
	return count

func _idle_texture(definition: Dictionary) -> Texture2D:
	var path := str(definition.get("sprite_sheet", ""))
	var sheet := ResourceLoader.load(path) as Texture2D if not path.is_empty() else null
	if sheet != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		# Stay inside the idle cell so compact thumbnails cannot leak animation frames.
		atlas.region = Rect2(2, 2, 380, 508)
		return atlas
	var raw_path := str(definition.get("raw_print", ""))
	return ResourceLoader.load(raw_path) as Texture2D if not raw_path.is_empty() else null

func _schematic_texture(definition: Dictionary) -> Texture2D:
	var raw_path := str(definition.get("raw_print", ""))
	return ResourceLoader.load(raw_path) as Texture2D if not raw_path.is_empty() else null

func _card(creature_id: String, selected: bool, context: Dictionary) -> Control:
	var definition := Catalog.creature(creature_id)
	var rarity := Catalog.rarity(str(definition.get("rarity", "common")))
	var portrait: bool = bool(context.portrait)
	var schematic_only: bool = bool(context.get("schematic_only", false))
	var card := Control.new()
	card.name = "PrinterBlueprintCard%s" % creature_id.capitalize()
	card.set_meta("creature_id", creature_id)
	card.set_meta("price", int(UnifiedRules.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), 20)))
	card.set_meta("owned_count", owned_count(context.profile, creature_id))
	card.custom_minimum_size = Vector2(168 if portrait else 146, 210 if portrait else 174)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var select_button := Button.new()
	select_button.name = "PrinterSelect%s" % creature_id.capitalize()
	select_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select_button.custom_minimum_size = Vector2(44, 44)
	select_button.tooltip_text = "Select %s for the dormant Arcane Forge build plate" % str(definition.get("name", creature_id))
	select_button.accessibility_name = ("Selected " if selected else "Select ") + str(definition.get("name", creature_id)) + " blueprint"
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		select_button.add_theme_stylebox_override(state, context.cartridge_style.call(selected or state in ["hover", "focus"]))
	select_button.pressed.connect(context.select_blueprint.bind(creature_id))
	card.add_child(select_button)
	var content := VBoxContainer.new()
	content.name = "PrinterBlueprintCardContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Preserve a clear cushion inside the raster cartridge rim for title and facts.
	content.offset_left = 13
	content.offset_top = 13
	content.offset_right = -13
	content.offset_bottom = -13
	content.add_theme_constant_override("separation", 3)
	card.add_child(content)
	var title: Label = context.label.call(str(definition.get("name", creature_id)), 16, Color("ffd36c") if selected else Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var preview := TextureRect.new()
	preview.name = "PrinterBlueprintSchematicArt" if schematic_only else "PrinterBlueprintIdleArt"
	preview.custom_minimum_size = Vector2(0, 106 if portrait else 72)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = _schematic_texture(definition) if schematic_only else _idle_texture(definition)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(preview)
	if schematic_only:
		var schematic_label: Label = context.label.call("SCHEMATIC · UNASSEMBLED", 11, Color("76ddff"))
		schematic_label.name = "PrinterBlueprintSchematicLabel"
		schematic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(schematic_label)
	var facts: Label = context.label.call("%s / %s" % [str(definition.get("element", "Unknown")), str(rarity.get("name", "Common"))], 12, Color("b8dcef"))
	facts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(facts)
	var ownership: Label = context.label.call("%d FC  |  printed %d" % [int(UnifiedRules.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), 20)), owned_count(context.profile, creature_id)], 12, Color("a8e3a5"))
	ownership.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(ownership)
	return card

func render(host: Control, selected_id: String, context: Dictionary) -> String:
	var selector: VBoxContainer = context.make_panel.call(Color("15344bea"), Color("f1be69"))
	selector.get_parent().name = "PrinterBlueprintSelector"
	host.add_child(selector.get_parent())
	var title: Label = context.label.call("Starter Blueprint Schematic" if bool(context.get("schematic_only", false)) else "Learned Blueprint Cartridges", 18, Color("76ddff") if bool(context.get("schematic_only", false)) else Color("ffd36c"))
	title.name = "PrinterBlueprintSelectorTitle"
	selector.add_child(title)
	var ids := blueprint_ids(context.profile)
	if ids.is_empty():
		var empty: Label = context.label.call("No learned creature blueprints are ready for the dormant build plate.", 15, Color("fff0a1"))
		empty.name = "PrinterBlueprintEmptyState"
		selector.add_child(empty)
		return ""
	if selected_id not in ids:
		selected_id = str(ids[0])
	# One horizontal shelf works in both responsive compositions. Landscape keeps
	# Begin and Back in the first fold while further cartridges scroll sideways.
	var scroller := ScrollContainer.new()
	scroller.name = "PrinterBlueprintCartridgeStrip"
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.custom_minimum_size = Vector2(0, 222 if bool(context.portrait) else 186)
	selector.add_child(scroller)
	var cards_host := HBoxContainer.new()
	cards_host.name = "PrinterBlueprintCartridgeStripContents"
	cards_host.add_theme_constant_override("separation", 10)
	scroller.add_child(cards_host)
	for creature_id in ids:
		cards_host.add_child(_card(creature_id, creature_id == selected_id, context))
	return selected_id
