class_name EquipmentWorkbenchView
extends RefCounted
## Compact responsive equipment view. Main owns mutations; this class owns layout.

const CORE_DEFS := preload("res://scripts/core/armor_core_definitions.gd")

static func build(profile: Dictionary, selected_creature_id: String, mode: String, selected_id: String, wide: bool, actions: Dictionary) -> Control:
	var root := VBoxContainer.new(); root.add_theme_constant_override("separation", 10)
	root.add_child(_label("Equipment Workbench", 25, Color("ffd36c")))
	root.add_child(_label("One complete suit per companion. Socket one optional Core into that suit.", 14, Color("dce8f4")))
	var rail := VBoxContainer.new(); rail.add_theme_constant_override("separation", 10)
	var interaction := VBoxContainer.new(); interaction.add_theme_constant_override("separation", 10); interaction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wide:
		var workspace := HBoxContainer.new(); workspace.add_theme_constant_override("separation", 16); root.add_child(workspace)
		rail.custom_minimum_size = Vector2(420, 0); workspace.add_child(rail); workspace.add_child(interaction)
	else:
		root.add_child(rail); root.add_child(interaction)
	var creature := _creature(profile, selected_creature_id)
	if creature.is_empty() and not profile.get("creatures", []).is_empty(): creature = profile.creatures[0]
	var creature_id := str(creature.get("instance_id", ""))
	var hero := HBoxContainer.new(); hero.add_theme_constant_override("separation", 18); hero.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; hero.custom_minimum_size = Vector2(0, 210 if not wide else 280); rail.add_child(hero)
	if str(creature.get("creature_id", "")) == "cinderpaw" and not str(creature.get("suit_instance_id", "")).is_empty():
		var preview := TieredArmorPalettePreview.new(); var hero_size := 300 if wide else 205; preview.custom_minimum_size = Vector2(hero_size, hero_size); preview.custom_maximum_size = Vector2(hero_size, hero_size); preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; preview.configure_tier(selected_id if mode == "suits" else _tier_for_suit(profile, str(creature.get("suit_instance_id", "")))); preview.configure_core(selected_id if mode == "cores" else _core_for_suit(profile, str(creature.get("suit_instance_id", "")))); hero.add_child(preview)
	var hero_copy := VBoxContainer.new(); hero_copy.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; hero.add_child(hero_copy)
	var creature_name := str(Catalog.creature(str(creature.get("creature_id", ""))).get("name", "Choose a companion"))
	hero_copy.add_child(_label(creature_name, 20, Color("9beaff")))
	var suit_id := str(creature.get("suit_instance_id", "")); var tier := _tier_for_suit(profile, suit_id); var core := _core_for_suit(profile, suit_id)
	hero_copy.add_child(_label("Loadout: " + (tier.capitalize() + " full suit" if not tier.is_empty() else "No full suit"), 14, Color("a8e3a5") if not tier.is_empty() else Color("fff0a1")))
	hero_copy.add_child(_label("Socket: " + (str(CORE_DEFS.definition(core).get("name", "Empty")) if not core.is_empty() else "Empty"), 14, Color("dce8f4")))
	var preview_name := (str(CORE_DEFS.definition(selected_id).get("name", "No Core")) if mode == "cores" else str(CORE_DEFS.suit_definition(selected_id).get("name", "Standard Full Suit")))
	hero_copy.add_child(_label("Preview: " + preview_name, 13, Color("ffd36c")))
	if not suit_id.is_empty(): hero_copy.add_child(_button("Remove Suit", actions.get("remove_suit"), Color("536c8d")))
	if not suit_id.is_empty() and not core.is_empty():
		var remove_core := _button("Remove Core", actions.get("remove_core").bind(suit_id), Color("536c8d"))
		remove_core.name = "EquipmentRemoveCore"
		hero_copy.add_child(remove_core)
	var creatures := HBoxContainer.new(); creatures.add_theme_constant_override("separation", 6); rail.add_child(creatures)
	for row in profile.get("creatures", []):
		var id := str(row.get("instance_id", "")); var name := str(Catalog.creature(str(row.get("creature_id", ""))).get("name", "Print"))
		creatures.add_child(_button(name, actions.get("select_creature").bind(id), Color("588d73") if id == creature_id else Color("526e93")))
	var tabs := HBoxContainer.new(); tabs.add_theme_constant_override("separation", 8); interaction.add_child(tabs)
	tabs.add_child(_button("Full Suits", actions.get("select_mode").bind("suits"), Color("a86b2e") if mode == "suits" else Color("526e93")))
	tabs.add_child(_button("Cores", actions.get("select_mode").bind("cores"), Color("7142a8") if mode == "cores" else Color("526e93")))
	var layout: Control = HBoxContainer.new() if wide else VBoxContainer.new(); layout.add_theme_constant_override("separation", 12); interaction.add_child(layout)
	var tray := GridContainer.new(); tray.columns = 2; tray.size_flags_horizontal = Control.SIZE_EXPAND_FILL; layout.add_child(tray)
	var detail := VBoxContainer.new(); detail.custom_minimum_size = Vector2(260 if wide else 0, 0); detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL; layout.add_child(detail)
	if mode == "suits":
		for suit in Catalog.SUITS:
			var tier_id := str(suit.id); var learned: bool = tier_id in profile.get("suit_blueprints", []); var owned := _count(profile.get("suits", []), "tier_id", tier_id)
			tray.add_child(_button("%s\n+%d HP  %d Guard  +%d Speed\n%s / owned %d" % [str(suit.name), int(suit.hp), int(suit.armor), int(suit.speed), "Learned" if learned else "%d FC" % int(suit.blueprint), owned], actions.get("select_item").bind(tier_id), Color("588d73") if selected_id == tier_id else Color("31506e")))
		var suit := CORE_DEFS.suit_definition(selected_id if not selected_id.is_empty() else "standard")
		detail.add_child(_label(str(suit.get("name", "Select a suit")), 19, Color("ffd36c")))
		detail.add_child(_label("Exact bonuses: +%d HP, %d Guard, +%d Speed" % [int(suit.get("hp", 0)), int(suit.get("armor", 0)), int(suit.get("speed", 0))], 14, Color("dce8f4")))
		var learned: bool = str(suit.get("id", "")) in profile.get("suit_blueprints", [])
		detail.add_child(_button(("Print for %d FC" % int(suit.get("print", 0))) if learned else ("Learn for %d FC" % int(suit.get("blueprint", 0))), actions.get("suit_action").bind(str(suit.get("id", ""))), Color("a86b2e")))
		for row in profile.get("suits", []):
			if str(row.get("tier_id", "")) == str(suit.get("id", "")):
				var state := "equipped" if not str(row.get("equipped_to", "")).is_empty() else "free"
				detail.add_child(_button("Fit %s suit" % state, actions.get("fit_suit").bind(creature_id, str(row.get("suit_instance_id", ""))), Color("588d73")))
	else:
		for core_row in Catalog.CORE_BLUEPRINTS:
			var core_id := str(core_row.id); var learned: bool = core_id in profile.get("core_blueprints", []); var owned := _count(profile.get("cores", []), "core_id", core_id)
			tray.add_child(_button("%s\n%s\n%s / owned %d" % [str(core_row.name), str(CORE_DEFS.definition(core_id).get("effect", "")), "Learned" if learned else "%d FC" % int(core_row.blueprint), owned], actions.get("select_item").bind(core_id), Color("7142a8") if selected_id == core_id else Color("31506e")))
		if selected_id.is_empty():
			detail.add_child(_label("Select a Core", 19, Color("d3a7ff")))
			detail.add_child(_label("The socket is empty. Choose a Core card to preview its gem color and effect.", 14, Color("dce8f4")))
		else:
			var selected_core := CORE_DEFS.core_blueprint_definition(selected_id)
			detail.add_child(_label(str(selected_core.get("name", "Select a Core")), 19, Color("d3a7ff")))
			detail.add_child(_label(str(selected_core.get("effect", "")), 14, Color("dce8f4")))
			var learned: bool = str(selected_core.get("id", "")) in profile.get("core_blueprints", [])
			detail.add_child(_button(("Print for %d FC" % int(selected_core.get("print", 0))) if learned else ("Learn for %d FC" % int(selected_core.get("blueprint", 0))), actions.get("core_action").bind(str(selected_core.get("id", ""))), Color("7142a8")))
			if not suit_id.is_empty():
				for row in profile.get("cores", []):
					if str(row.get("core_id", "")) == str(selected_core.get("id", "")): detail.add_child(_button("Socket owned Core", actions.get("socket_core").bind(suit_id, str(row.get("core_instance_id", ""))), Color("7142a8")))
	return root

static func _label(text: String, size: int, color: Color) -> Label:
	var value := Label.new(); value.text = text; value.add_theme_font_size_override("font_size", size); value.add_theme_color_override("font_color", color); value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; return value
static func _button(text: String, action: Callable, color: Color) -> Button:
	var value := Button.new()
	value.text = text
	value.custom_minimum_size = Vector2(0, 48)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		value.add_theme_color_override(state, Color("edf7ff") if state != "font_disabled_color" else Color("9caebb"))
	var normal := StyleBoxFlat.new(); normal.bg_color = Color("101c2b"); normal.border_color = color.lightened(0.18); normal.set_border_width_all(1); normal.set_corner_radius_all(8); normal.content_margin_left = 10; normal.content_margin_right = 10; normal.content_margin_top = 7; normal.content_margin_bottom = 7
	var hover := normal.duplicate(); hover.bg_color = color.darkened(0.58); hover.set_border_width_all(2)
	var pressed := normal.duplicate(); pressed.bg_color = color.darkened(0.44); pressed.set_border_width_all(2)
	value.add_theme_stylebox_override("normal", normal); value.add_theme_stylebox_override("hover", hover); value.add_theme_stylebox_override("pressed", pressed); value.add_theme_stylebox_override("focus", hover)
	if action.is_valid(): value.pressed.connect(action)
	return value
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
