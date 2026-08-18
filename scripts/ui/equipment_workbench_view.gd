class_name EquipmentWorkbenchView
extends RefCounted
## Compact responsive equipment view. Main owns mutations; this class owns layout.

const CORE_DEFS := preload("res://scripts/core/armor_core_definitions.gd")
const TIERED_ARMOR_ROSTER := preload("res://scripts/ui/tiered_armor_roster.gd")
# TIERED_ARMOR_ROSTER is the local alias for TieredArmorRoster.
const TIERED_ARMOR_PREVIEW := preload("res://scripts/ui/tiered_armor_palette_preview.gd")
const FOUNDRY_THEME := preload("res://scripts/ui/arcane_foundry_theme_kit.gd")

static func build(profile: Dictionary, selected_creature_id: String, mode: String, selected_id: String, wide: bool, actions: Dictionary, high_contrast := false, text_scale_bps := 10000) -> Control:
	var root := VBoxContainer.new(); root.name = "EquipmentWorkbenchRoot"; root.add_theme_constant_override("separation", 10)
	var title_header := _section_heading("Equipment Workbench", 23, Color("ffd36c"), "commit", high_contrast, text_scale_bps)
	title_header.name = "EquipmentWorkbenchHeading"
	root.add_child(title_header)
	root.add_child(_label("One complete suit per companion. Socket one optional Core into that suit.", 14, Color("dce8f4"), text_scale_bps))
	var rail := VBoxContainer.new(); rail.add_theme_constant_override("separation", 10)
	var interaction := VBoxContainer.new(); interaction.add_theme_constant_override("separation", 10); interaction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wide:
		var workspace := HBoxContainer.new(); workspace.add_theme_constant_override("separation", 16); root.add_child(workspace)
		rail.custom_minimum_size = Vector2(520, 0); workspace.add_child(rail); workspace.add_child(interaction)
	else:
		root.add_child(rail); root.add_child(interaction)
	var creature := _creature(profile, selected_creature_id)
	if creature.is_empty() and not profile.get("creatures", []).is_empty(): creature = profile.creatures[0]
	var creature_id := str(creature.get("instance_id", ""))
	var hero := HBoxContainer.new(); hero.name = "EquipmentWorkbenchHero"; hero.add_theme_constant_override("separation", 18); hero.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; hero.custom_minimum_size = Vector2(0, 210 if not wide else 280); rail.add_child(hero)
	var species_id := str(creature.get("creature_id", ""))
	if TIERED_ARMOR_ROSTER.has_master(species_id) and not str(creature.get("suit_instance_id", "")).is_empty():
		var hero_size := 260 if wide and text_scale_bps >= 12500 else (300 if wide else 205)
		var preview := TIERED_ARMOR_PREVIEW.new(); preview.custom_minimum_size = Vector2(hero_size, hero_size); preview.custom_maximum_size = Vector2(hero_size, hero_size); preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; preview.configure_creature(species_id); preview.configure_tier(selected_id if mode == "suits" else _tier_for_suit(profile, str(creature.get("suit_instance_id", "")))); preview.configure_core(selected_id if mode == "cores" else _core_for_suit(profile, str(creature.get("suit_instance_id", "")))); hero.add_child(preview)
	var hero_copy := VBoxContainer.new(); hero_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hero_copy.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; hero.add_child(hero_copy)
	var creature_name := str(Catalog.creature(str(creature.get("creature_id", ""))).get("name", "Choose a companion"))
	hero_copy.add_child(_section_heading(creature_name, 18, Color("9beaff"), "secondary", high_contrast, text_scale_bps))
	var suit_id := str(creature.get("suit_instance_id", "")); var tier := _tier_for_suit(profile, suit_id); var core := _core_for_suit(profile, suit_id)
	hero_copy.add_child(_status_chip("LOADOUT  " + (tier.capitalize() + " full suit" if not tier.is_empty() else "No full suit"), "success" if not tier.is_empty() else "commit", Color("a8e3a5") if not tier.is_empty() else Color("fff0a1"), high_contrast, text_scale_bps))
	hero_copy.add_child(_status_chip("SOCKET  " + (str(CORE_DEFS.definition(core).get("name", "Empty")) if not core.is_empty() else "Empty"), "secondary", Color("dce8f4"), high_contrast, text_scale_bps))
	var preview_name := (str(CORE_DEFS.definition(selected_id).get("name", "No Core")) if mode == "cores" else str(CORE_DEFS.suit_definition(selected_id).get("name", "Standard Full Suit")))
	hero_copy.add_child(_label("Preview: " + preview_name, 13, Color("ffd36c"), text_scale_bps))
	if not suit_id.is_empty(): hero_copy.add_child(_button("Remove Suit", actions.get("remove_suit"), Color("536c8d"), high_contrast, false, false, text_scale_bps))
	if not suit_id.is_empty() and not core.is_empty():
		var remove_core := _button("Remove Core", actions.get("remove_core").bind(suit_id), Color("536c8d"), high_contrast, false, false, text_scale_bps)
		remove_core.name = "EquipmentRemoveCore"
		hero_copy.add_child(remove_core)
	var creatures := HBoxContainer.new(); creatures.name = "EquipmentWorkbenchCreatureSelector"; creatures.add_theme_constant_override("separation", 6); rail.add_child(creatures)
	for row in profile.get("creatures", []):
		var id := str(row.get("instance_id", "")); var name := str(Catalog.creature(str(row.get("creature_id", ""))).get("name", "Print"))
		creatures.add_child(_button(name, actions.get("select_creature").bind(id), Color("588d73") if id == creature_id else Color("526e93"), high_contrast, false, id == creature_id, text_scale_bps))
	var tabs := HBoxContainer.new(); tabs.name = "EquipmentWorkbenchTabs"; tabs.add_theme_constant_override("separation", 8); interaction.add_child(tabs)
	tabs.add_child(_button("Full Suits", actions.get("select_mode").bind("suits"), Color("a86b2e") if mode == "suits" else Color("526e93"), high_contrast, false, mode == "suits", text_scale_bps))
	tabs.add_child(_button("Cores", actions.get("select_mode").bind("cores"), Color("7142a8") if mode == "cores" else Color("526e93"), high_contrast, false, mode == "cores", text_scale_bps))
	var layout: Control = HBoxContainer.new() if wide else VBoxContainer.new(); layout.add_theme_constant_override("separation", 12); interaction.add_child(layout)
	var tray := GridContainer.new(); tray.name = "EquipmentWorkbenchTierCards"; tray.columns = 1 if wide and text_scale_bps >= 12500 else 2; tray.size_flags_horizontal = Control.SIZE_EXPAND_FILL; layout.add_child(tray)
	var detail := VBoxContainer.new(); detail.name = "EquipmentWorkbenchDetail"; detail.custom_minimum_size = Vector2(260 if wide else 0, 0); detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL; layout.add_child(detail)
	if mode == "suits":
		for suit in Catalog.SUITS:
			var tier_id := str(suit.id); var learned: bool = tier_id in profile.get("suit_blueprints", []); var owned := _count(profile.get("suits", []), "tier_id", tier_id)
			tray.add_child(_button("%s\n+%d HP  %d Guard  +%d Speed\n%s / owned %d" % [str(suit.name), int(suit.hp), int(suit.armor), int(suit.speed), "Learned" if learned else "%d FC" % int(suit.blueprint), owned], actions.get("select_item").bind(tier_id), Color("588d73") if selected_id == tier_id else Color("31506e"), high_contrast, true, selected_id == tier_id, text_scale_bps))
		var suit := CORE_DEFS.suit_definition(selected_id if not selected_id.is_empty() else "standard")
		detail.add_child(_section_heading(str(suit.get("name", "Select a suit")), 18, Color("ffd36c"), "commit", high_contrast, text_scale_bps))
		detail.add_child(_label("Exact bonuses: +%d HP, %d Guard, +%d Speed" % [int(suit.get("hp", 0)), int(suit.get("armor", 0)), int(suit.get("speed", 0))], 14, Color("dce8f4"), text_scale_bps))
		var learned: bool = str(suit.get("id", "")) in profile.get("suit_blueprints", [])
		detail.add_child(_button(("Print for %d FC" % int(suit.get("print", 0))) if learned else ("Learn for %d FC" % int(suit.get("blueprint", 0))), actions.get("suit_action").bind(str(suit.get("id", ""))), Color("a86b2e"), high_contrast, false, false, text_scale_bps))
		for row in profile.get("suits", []):
			if str(row.get("tier_id", "")) == str(suit.get("id", "")):
				var state := "equipped" if not str(row.get("equipped_to", "")).is_empty() else "free"
				detail.add_child(_button("Fit %s suit" % state, actions.get("fit_suit").bind(creature_id, str(row.get("suit_instance_id", ""))), Color("588d73"), high_contrast, false, false, text_scale_bps))
	else:
		for core_row in Catalog.CORE_BLUEPRINTS:
			var core_id := str(core_row.id); var learned: bool = core_id in profile.get("core_blueprints", []); var owned := _count(profile.get("cores", []), "core_id", core_id)
			tray.add_child(_button("%s\n%s\n%s / owned %d" % [str(core_row.name), str(CORE_DEFS.definition(core_id).get("effect", "")), "Learned" if learned else "%d FC" % int(core_row.blueprint), owned], actions.get("select_item").bind(core_id), Color("7142a8") if selected_id == core_id else Color("31506e"), high_contrast, true, selected_id == core_id, text_scale_bps))
		if selected_id.is_empty():
			detail.add_child(_section_heading("Select a Core", 18, Color("d3a7ff"), "arcane", high_contrast, text_scale_bps))
			detail.add_child(_label("The socket is empty. Choose a Core card to preview its gem color and effect.", 14, Color("dce8f4"), text_scale_bps))
		else:
			var selected_core := CORE_DEFS.core_blueprint_definition(selected_id)
			detail.add_child(_section_heading(str(selected_core.get("name", "Select a Core")), 18, Color("d3a7ff"), "arcane", high_contrast, text_scale_bps))
			detail.add_child(_label(str(selected_core.get("effect", "")), 14, Color("dce8f4"), text_scale_bps))
			var learned: bool = str(selected_core.get("id", "")) in profile.get("core_blueprints", [])
			detail.add_child(_button(("Print for %d FC" % int(selected_core.get("print", 0))) if learned else ("Learn for %d FC" % int(selected_core.get("blueprint", 0))), actions.get("core_action").bind(str(selected_core.get("id", ""))), Color("7142a8"), high_contrast, false, false, text_scale_bps))
			if not suit_id.is_empty():
				for row in profile.get("cores", []):
					if str(row.get("core_id", "")) == str(selected_core.get("id", "")): detail.add_child(_button("Socket owned Core", actions.get("socket_core").bind(suit_id, str(row.get("core_instance_id", ""))), Color("7142a8"), high_contrast, false, false, text_scale_bps))
	return root

static func _label(text: String, size: int, color: Color, text_scale_bps := 10000) -> Label:
	var text_color := Color("e6dfd0") if color.is_equal_approx(Color("dce8f4")) else color
	var value := Label.new(); value.text = text; value.add_theme_font_override("font", FOUNDRY_THEME.display_font()); value.add_theme_font_size_override("font_size", _scaled_font(size, text_scale_bps)); value.add_theme_color_override("font_color", text_color); value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if size >= 19: value.add_theme_color_override("font_outline_color", Color("080909")); value.add_theme_constant_override("outline_size", 1)
	return value
static func _section_heading(text: String, size: int, color: Color, role: String, high_contrast: bool, text_scale_bps: int) -> PanelContainer:
	var panel := PanelContainer.new(); panel.name = "EquipmentSectionHeader"; panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; panel.add_theme_stylebox_override("panel", FOUNDRY_THEME.section_header(role, high_contrast))
	var heading := _label(text, size, color, text_scale_bps); heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; heading.custom_minimum_size.y = maxi(30, _scaled_font(size, text_scale_bps) + 12); panel.add_child(heading)
	return panel
static func _status_chip(text: String, role: String, color: Color, high_contrast: bool, text_scale_bps: int) -> PanelContainer:
	var panel := PanelContainer.new(); panel.name = "EquipmentStatusChip"; panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; panel.add_theme_stylebox_override("panel", FOUNDRY_THEME.status_chip(role, high_contrast))
	var value := _label(text, 12, color, text_scale_bps); value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; panel.add_child(value)
	return panel
static func _button(text: String, action: Callable, color: Color, high_contrast := false, inset := false, selected := false, text_scale_bps := 10000) -> Button:
	var value := Button.new()
	value.text = text
	value.custom_minimum_size = Vector2(0, maxi(76, _scaled_font(12, text_scale_bps) * 3 + 20) if text.contains("\n") else 48)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.add_theme_font_override("font", FOUNDRY_THEME.display_font())
	if text.contains("\n"): value.add_theme_font_size_override("font_size", _scaled_font(12, text_scale_bps))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		value.add_theme_color_override(state, Color("f0e8d8") if state != "font_disabled_color" else Color("aaa69c"))
	var role := "commit" if color.is_equal_approx(Color("a86b2e")) else ("arcane" if color.is_equal_approx(Color("7142a8")) else ("success" if color.is_equal_approx(Color("588d73")) else "secondary"))
	if inset:
		# A PanelContainer can use the large inset raster, but applying that source
		# directly to compact card buttons imports its full native minimum height.
		# Use the shared keycap states here so 3-line cards remain dense and touch-safe.
		value.add_theme_stylebox_override("normal", FOUNDRY_THEME.selected_button(role, high_contrast) if selected else FOUNDRY_THEME.button(role, "normal", high_contrast)); value.add_theme_stylebox_override("hover", FOUNDRY_THEME.button(role, "hover", high_contrast)); value.add_theme_stylebox_override("pressed", FOUNDRY_THEME.button(role, "pressed", high_contrast)); value.add_theme_stylebox_override("focus", FOUNDRY_THEME.button(role, "focus", high_contrast)); value.add_theme_stylebox_override("disabled", FOUNDRY_THEME.button(role, "disabled", high_contrast))
	else:
		value.add_theme_stylebox_override("normal", FOUNDRY_THEME.selected_button(role, high_contrast) if selected else FOUNDRY_THEME.button(role, "normal", high_contrast)); value.add_theme_stylebox_override("hover", FOUNDRY_THEME.button(role, "hover", high_contrast)); value.add_theme_stylebox_override("pressed", FOUNDRY_THEME.button(role, "pressed", high_contrast)); value.add_theme_stylebox_override("focus", FOUNDRY_THEME.button(role, "focus", high_contrast)); value.add_theme_stylebox_override("disabled", FOUNDRY_THEME.button(role, "disabled", high_contrast))
	if action.is_valid(): value.pressed.connect(action)
	return value
static func _scaled_font(base: int, text_scale_bps: int) -> int:
	return maxi(12, (base * text_scale_bps) / 10000)
static func _creature(profile: Dictionary, id: String) -> Dictionary:
	for row in profile.get("creatures", []): if str(row.get("instance_id", "")) == id: return row
	return {}
static func _count(rows: Array, key: String, value: String) -> int:
	var total := 0; for row in rows: if row is Dictionary and str(row.get(key, "")) == value: total += 1
	return total
static func _tier_for_suit(profile: Dictionary, id: String) -> String:
	for row in profile.get("suits", []): if str(row.get("suit_instance_id", "")) == id: return str(row.get("tier_id", ""))
	return ""
static func _core_for_suit(profile: Dictionary, id: String) -> String:
	for suit in profile.get("suits", []):
		if str(suit.get("suit_instance_id", "")) == id:
			var core_instance := str(suit.get("socketed_core_id", ""))
			for core in profile.get("cores", []): if str(core.get("core_instance_id", "")) == core_instance: return str(core.get("core_id", ""))
	return ""
