extends Control
## Reference-driven workshop presentation; final character art remains approval-gated.
const REFERENCE_TEXTURE := preload("res://docs/art/reference/workshop-theme-reference.jpg")
const WORKSHOP_OVERVIEW_LANDSCAPE_TEXTURE := preload("res://assets/ui/workshop/workshop_overview_landscape_v3.png")
const WORKSHOP_OVERVIEW_PORTRAIT_TEXTURE := preload("res://assets/ui/workshop/workshop_overview_portrait_v3.png")
const WORKSHOP_AMBIENT_LAYER := preload("res://scripts/ui/workshop_ambient_layer.gd")
const WORKSHOP_HOTSPOT_OVERLAY := preload("res://scripts/ui/workshop_hotspot_overlay.gd")
const WORKSHOP_PAN_AFFORDANCE := preload("res://scripts/ui/workshop_pan_affordance.gd")
const WORKSHOP_STATION_LIVE_LAYER := preload("res://scripts/ui/workshop_station_live_layer.gd")
const ELEMENT_COLORS := {"Fire":"f17e5b", "Water":"5fb9f5", "Lightning":"efd862", "Nature":"7bcf89", "Ice":"a5ecff", "Stone":"b7a48b", "Wind":"a6d7c8"}
# Approved perspective-matched workshop station close-ups. Each keeps its visible
# props aligned with the normalized, accessible object hotspots below.
const WORKSHOP_CLOSEUP_PATHS := {
	"printer": "res://assets/ui/workshop/workshop_printer_closeup_v2.png",
	"maker": "res://assets/ui/workshop/workshop_maker_closeup_v2.png",
	"terminal": "res://assets/ui/workshop/workshop_terminal_closeup_v2.png",
	"proving": "res://assets/ui/workshop/workshop_proving_closeup_v2.png",
	"yard": "res://assets/ui/workshop/workshop_yard_closeup_v2.png"
}

var screen := "workshop"
var workshop_selected := "printer"
var workshop_view := "overview"
var workshop_drawer_object := ""
var printer_picker_open := false
var workshop_return_view := "overview"
var pending_starter_id := ""
var shop_day_key := ""
var team_draft: Array = []
var deck_draft: Array = []
var deck_slot_id := ProgressionRules.STARTER_DECK_ID
var battle: BattleState
var body: VBoxContainer
var status: Label
var battle_last_event := ""
var battle_last_actor := 0
var ai_pending := false
var battle_concede_armed := false
var battle_secondary_open := false
var battle_secondary_tab := "bench"
var local_concede_armed := false
var local_authority: LocalBattleAuthority
var local_ready_seat := -1
var local_trade: LocalTradeAuthority
var trade_creator_choice := ""
var trade_partner_choice := ""
var printer_sequence: ArcaneForgeSequence
var printer_creature_id := ""
var printer_price := 0
var printer_tick_accumulator := 0.0
var printer_presentation_seconds := 0.0
var printer_capture_freeze := false
var printer_failure := ""
var printer_return_screen := "collection"
var workshop_ambient_capture_freeze := false
var workshop_station_live_capture_progress := -1
var workshop_station_live_capture_seed := 17
var overview_layout_portrait := false

func settings() -> Dictionary:
	return GameManager.profile.get("settings", AccessibilityRules.defaults())

func scaled_font(base: int) -> int:
	return maxi(12, (base * int(settings().get("text_scale_bps", 10000))) / 10000)

func is_portrait_layout() -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return viewport_size.y > viewport_size.x

func _ready() -> void:
	if shop_day_key.is_empty(): shop_day_key = Time.get_date_string_from_system()
	GameManager.profile_changed.connect(render)
	GameManager.toast_requested.connect(_toast)
	# A capture harness may select a non-default destination before this node enters
	# the tree. Normal launches use the workshop default and route from profile state.
	if screen == "workshop": screen = OnboardingState.screen_for_profile(GameManager.profile)
	render()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		# Containers handle ordinary resize. An orientation flip needs its matching
		# v3 overview plate and fresh normalized hotspot layout.
		if screen == "workshop" and workshop_view == "overview" and is_portrait_layout() != overview_layout_portrait:
			call_deferred("render")
		queue_redraw()

func _process(delta: float) -> void:
	if printer_capture_freeze: return
	if screen != "printer" or printer_sequence == null: return
	if printer_sequence.phase not in [ArcaneForgeSequence.PRINTING, ArcaneForgeSequence.RAW_HOLD, ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.DEPARTING]: return
	if not printer_sequence.reduced_motion: printer_presentation_seconds += delta
	printer_tick_accumulator += delta
	if printer_tick_accumulator < ArcaneForgeSequence.presentation_interval_seconds(printer_sequence.reduced_motion): return
	printer_tick_accumulator = 0.0
	printer_sequence.advance(ArcaneForgeSequence.presentation_step_bps(printer_sequence.reduced_motion, printer_sequence.phase))
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE: _commit_printer_once()
	render()

func navigate_to(target: String) -> void:
	if screen == "workshop" and target != "workshop":
		workshop_return_view = workshop_view
	if target == "workshop":
		workshop_view = workshop_return_view
		workshop_drawer_object = ""
	screen = target
	render()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE): return
	if screen == "workshop":
		if not workshop_drawer_object.is_empty():
			close_workshop_drawer()
		elif workshop_view != "overview":
			open_workshop_view("overview")
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and screen == "printer":
		if printer_sequence != null and printer_sequence.phase == ArcaneForgeSequence.IDLE:
			cancel_printer_preview()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and screen != "onboarding" and screen != "workshop":
		screen = "workshop"
		workshop_view = workshop_return_view
		workshop_drawer_object = ""
		local_ready_seat = -1
		render()
		get_viewport().set_input_as_handled()

func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func panel_style(color: Color, border: Color = Color("6bd6ed")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if bool(settings().get("high_contrast", false)):
		color = Color("07111fff")
		border = Color("ffffffff")
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(3 if bool(settings().get("high_contrast", false)) else 1)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	style.shadow_color = Color(0.02, 0.04, 0.10, 0.5)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style

func make_panel(color := Color("172942cc"), border := Color("6bd6ed")) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(220, 0)
	panel.add_theme_stylebox_override("panel", panel_style(color, border))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	return content

func make_button(text_value: String, callback: Callable, accent := Color("2f93a8")) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", scaled_font(15))
	button.add_theme_stylebox_override("normal", panel_style(Color(accent, 0.90), Color("a8edff")))
	button.add_theme_stylebox_override("hover", panel_style(Color(accent, 1.0).lightened(0.12), Color("fff0a1")))
	button.add_theme_stylebox_override("pressed", panel_style(Color(accent, 1.0).darkened(0.12), Color("ffffff")))
	button.pressed.connect(callback)
	return button

func workshop_hotspot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.shadow_color = Color(0, 0, 0, 0)
	style.shadow_size = 0
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func label(text_value: String, size := 16, color := Color.WHITE) -> Label:
	var value := Label.new()
	value.text = text_value
	value.add_theme_font_size_override("font_size", scaled_font(size))
	value.add_theme_color_override("font_color", color)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return value

func render() -> void:
	clear_children(self)
	var backdrop := TextureRect.new()
	backdrop.texture = REFERENCE_TEXTURE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.72, 0.82, 1.0, 0.52)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var cool_overlay := ColorRect.new()
	cool_overlay.color = Color("071326b8")
	cool_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cool_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cool_overlay)
	var warm_glow := ColorRect.new()
	warm_glow.color = Color("8c4e1d3b")
	warm_glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	warm_glow.offset_bottom = 260
	warm_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warm_glow)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var portrait := size.y > size.x
	margin.add_theme_constant_override("margin_left", 14 if portrait else 26)
	margin.add_theme_constant_override("margin_right", 14 if portrait else 26)
	margin.add_theme_constant_override("margin_top", 14 if portrait else 20)
	margin.add_theme_constant_override("margin_bottom", 14 if portrait else 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	render_header(root)
	# Battle is a first-fold activity, not a list below a generic scrolling shell.
	# Give it the remaining safe content area directly so mobile layout cannot
	# collapse action rows to zero height before the scroll container settles.
	if screen == "battle":
		render_battle_fullscreen(root)
		call_deferred("focus_first_button")
		return
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	status = label("", 15, Color("fff0a1"))
	body.add_child(status)
	match screen:
		"onboarding": render_onboarding()
		"battle": render_battle()
		"shop": render_shop()
		"codex": render_codex()
		"collection": render_collection()
		"team": render_team()
		"armor": render_armor()
		"deck": render_deck()
		"yard": render_print_yard()
		"calibration": render_calibration_bench()
		"printer": render_printer()
		"settings": render_settings()
		"local_vs": render_local_vs()
		"trade": render_local_trade()
		_: render_workshop()
	call_deferred("focus_first_button")

func focus_first_button() -> void:
	for node in find_children("*", "Button", true, false):
		var button := node as Button
		if button and button.is_visible_in_tree() and button.disabled == false:
			button.grab_focus()
			return

func render_header(root: VBoxContainer) -> void:
	var header_box := PanelContainer.new()
	header_box.name = "WorkshopHeader"
	var portrait := size.y > size.x
	header_box.custom_minimum_size = Vector2(0, 126 if portrait else 90)
	header_box.add_theme_stylebox_override("panel", panel_style(Color("142840eb"), Color("f1be69")))
	root.add_child(header_box)
	var header: BoxContainer = VBoxContainer.new() if portrait else HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 100 if portrait else 64)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 16)
	header_box.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.custom_minimum_size = Vector2(0 if portrait else 560, 58)
	header.add_child(titles)
	titles.add_child(label("PRINTFORGE LEGENDS", 29, Color("ffd36c")))
	titles.add_child(label("Makers Guild Workshop", 14, Color("9beaff")))
	if GameManager.has_selected_starter():
		var account := label("Forge Coins  %d\nSpool  %d / 10" % [int(GameManager.profile.coins), GameManager.filament_cap()], 16, Color("d6f7ff"))
		account.custom_minimum_size = Vector2(0 if portrait else 190, 40 if portrait else 58)
		account.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
		account.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
		account.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(account)
	else:
		var ceremony := label("AWAKENING CEREMONY", 15, Color("fff0a1"))
		ceremony.custom_minimum_size = Vector2(0 if portrait else 220, 40 if portrait else 58)
		ceremony.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
		ceremony.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
		ceremony.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(ceremony)

func render_onboarding() -> void:
	var intro := make_panel(Color("182d49ed"), Color("f1be69"))
	body.add_child(intro.get_parent())
	intro.add_child(label("Choose your first Forge Companion", 27, Color("ffd36c")))
	intro.add_child(label("Three living blueprints are waiting in your new workshop. Your choice is permanent, bound to your Forge, and cannot be traded. You will receive its blueprint and one printed companion.", 17, Color("e1eef9")))
	var cards := GridContainer.new()
	cards.columns = 3 if size.x >= 900 else 1
	cards.add_theme_constant_override("h_separation", 14)
	cards.add_theme_constant_override("v_separation", 14)
	body.add_child(cards)
	for starter_id in ProfileRules.STARTER_IDS:
		var creature := Catalog.creature(starter_id)
		var element_color := Color(ELEMENT_COLORS.get(str(creature.element), "9beaff"))
		var card := make_panel(Color("15263fe8"), element_color if pending_starter_id == starter_id else Color("5e7f9b"))
		cards.add_child(card.get_parent())
		card.add_child(label(str(creature.name), 24, element_color))
		card.add_child(label("%s  •  %s" % [creature.element, Catalog.rarity(creature.rarity).name], 15, Color("dbe9f6")))
		card.add_child(label("%d HP   %d ATK   %d SPD" % [int(creature.hp), int(creature.attack), int(creature.speed)], 16, Color("ffffff")))
		card.add_child(label("Signature: %s\nFilament %d • Cooldown %d" % [creature.ability, int(creature.ability_cost), int(creature.cooldown)], 14, Color("b9d3e8")))
		card.add_child(make_button("Selected" if pending_starter_id == starter_id else "Choose %s" % creature.name, func(): pending_starter_id = starter_id; render(), element_color.darkened(0.35)))
	var confirmation := make_panel(Color("352719ed"), Color("f1be69"))
	body.add_child(confirmation.get_parent())
	confirmation.add_child(label("Permanent starter choice", 19, Color("fff0a1")))
	confirmation.add_child(label("Once confirmed, this companion is bound and nontradable. You can discover and print other creatures later, but cannot change this first companion.", 15, Color("fff9df")))
	if pending_starter_id.is_empty():
		confirmation.add_child(label("Select one card above to enable confirmation.", 15, Color("c6d7e8")))
	else:
		confirmation.add_child(make_button("Confirm %s as my permanent starter" % Catalog.creature(pending_starter_id).name, confirm_starter, Color("a86b2e")))

func confirm_starter() -> void:
	if not OnboardingState.can_confirm(GameManager.profile, pending_starter_id):
		_toast("Choose one Forge Trio companion first.")
		return
	# Set the destination before the synchronous profile_changed signal. That
	# signal performs the one successful transition render.
	screen = "workshop"
	if GameManager.choose_starter(pending_starter_id):
		pending_starter_id = ""
		return
	screen = "onboarding"
	render()

func render_workshop_legacy() -> void:
	var hero := make_panel(Color("19334de8"), Color("f1be69"))
	body.add_child(hero.get_parent())
	var starter_name: String = str(Catalog.creature(str(GameManager.profile.onboarding.starter_id)).name)
	hero.add_child(label("Welcome back, Forge Apprentice", 26, Color("ffd36c")))
	hero.add_child(label("%s watches the printer glow while snowlight frames your warm workshop. Choose a station to continue your legend." % starter_name, 16, Color("e2edf6")))
	var grid := GridContainer.new()
	grid.columns = 3 if size.x >= 900 else 1
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	body.add_child(grid)
	for item in [["Main Printer","Print blueprints you have mastered.","Print %s (20 FC)" % starter_name],["Extruder Forge","Browse today’s forge offers.","Open Shop"],["Forgedex","Track discovered blueprints.","Open Forgedex"],["Proving Grounds","Take your current team into training.","Start Training Match"],["Team Builder","Choose one to three prints.","Edit Team"],["Deck Builder","Tune a 15-card support deck.","Edit Deck"],["Armor Workbench","Learn, print, and equip armor.","Open Armor"],["Collection","Review printed companions.","Open Collection"],["Print Yard","See your companions at play.","Visit Print Yard"]]:
		var station := make_panel(Color("152842e8"), Color("5e99b4"))
		grid.add_child(station.get_parent())
		station.add_child(label(item[0], 20, Color("8deaff")))
		station.add_child(label(item[1], 14, Color("c9d8e6")))
		match item[0]:
			"Main Printer": station.add_child(make_button(item[2], func(): open_printer(str(GameManager.profile.onboarding.starter_id))))
			"Extruder Forge": station.add_child(make_button(item[2], navigate_to.bind("shop")))
			"Forgedex": station.add_child(make_button(item[2], navigate_to.bind("codex")))
			"Proving Grounds": station.add_child(make_button(item[2], start_battle, Color("9a5b6f")))
			"Team Builder": station.add_child(make_button(item[2], navigate_to.bind("team")))
			"Deck Builder": station.add_child(make_button(item[2], navigate_to.bind("deck")))
			"Armor Workbench": station.add_child(make_button(item[2], navigate_to.bind("armor")))
			"Collection": station.add_child(make_button(item[2], navigate_to.bind("collection")))
			"Workbench": station.add_child(make_button(item[2], func(): _toast("Calibration complete: +%d Forge Coins" % GameManager.complete_workshop_job(72)), Color("588d73")))
			"Print Yard": station.add_child(label("%d printed companion%s are wandering." % [GameManager.profile.creatures.size(), "" if GameManager.profile.creatures.size()==1 else "s"], 14, Color("a8e3a5")))

	var settings_station := make_panel(Color("152842e8"), Color("ffd36c"))
	grid.add_child(settings_station.get_parent())
	settings_station.add_child(label("Settings", 20, Color("ffd36c")))
	settings_station.add_child(label("Text, contrast, motion, and training AI.", 14, Color("c9d8e6")))
	settings_station.add_child(make_button("Open Settings", navigate_to.bind("settings")))
	var versus_station := make_panel(Color("203348ed"), Color("f1be69")); grid.add_child(versus_station.get_parent())
	versus_station.add_child(label("Local Versus", 20, Color("ffd36c")))
	versus_station.add_child(label("Private hot-seat match with revisioned local authority.", 14, Color("c9d8e6")))
	versus_station.add_child(make_button("Begin Local Versus", start_local_vs, Color("a86b2e")))
	var trade_station := make_panel(Color("203348ed"), Color("a8edff")); grid.add_child(trade_station.get_parent())
	trade_station.add_child(label("Guild Trade Table", 20, Color("a8edff")))
	trade_station.add_child(label("Credential-free local escrow demo. No chat or typed codes.", 14, Color("c9d8e6")))
	trade_station.add_child(make_button("Open Local Trade", func(): local_trade=null; trade_creator_choice=""; trade_partner_choice=""; screen="trade"; render(), Color("4d7898")))

func render_workshop_button_tray() -> void:
	var starter_name: String = str(Catalog.creature(str(GameManager.profile.onboarding.starter_id)).name)
	var hero := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(hero.get_parent())
	hero.add_child(label("Makers Guild Workshop", 26, Color("ffd36c")))
	hero.add_child(label("%s watches the warm tools glow beneath the snowlight. Choose a place in the workshop, then use the station tray below." % starter_name, 16, Color("e2edf6")))
	var used_today: int = int(GameManager.profile.daily_job_count) if str(GameManager.profile.last_job_day) == shop_day_key else 0
	hero.add_child(label("Progress: %d Forge Coins | Spool %d / 10 | XP %d / %d | Calibration %d / %d" % [int(GameManager.profile.coins), GameManager.filament_cap(), int(GameManager.profile.xp), GameManager.filament_cap() * 100, used_today, ProgressionRules.DAILY_CALIBRATION_LIMIT], 15, Color("9beaff")))
	var map_frame := PanelContainer.new(); map_frame.custom_minimum_size = Vector2(0, 250); map_frame.add_theme_stylebox_override("panel", panel_style(Color("071526e8"), Color("6bd6ed"))); body.add_child(map_frame)
	var map := Control.new(); map.name = "WorkshopMap"; map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); map_frame.add_child(map)
	var image := TextureRect.new(); image.texture = REFERENCE_TEXTURE; image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); image.mouse_filter = Control.MOUSE_FILTER_IGNORE; image.modulate = Color(0.88, 0.94, 1.0, 0.88); map.add_child(image)
	var tint := ColorRect.new(); tint.color = Color("07132675"); tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); tint.mouse_filter = Control.MOUSE_FILTER_IGNORE; map.add_child(tint)
	for station in _workshop_stations(): map.add_child(_workshop_hotspot(station))
	var tray := make_panel(Color("152d49ed"), Color("f1be69")); body.add_child(tray.get_parent())
	var selected := _workshop_station(workshop_selected)
	tray.add_child(label(str(selected.name), 22, Color("ffd36c") if workshop_selected == "maker" else Color("9beaff")))
	tray.add_child(label(str(selected.description), 16, Color("dce8f4")))
	if workshop_selected == "yard": tray.add_child(label("%d companions are ready for one calm filament lesson today." % GameManager.profile.creatures.size(), 14, Color("a8e3a5")))
	if workshop_selected == "maker": tray.add_child(label("Calibration remaining today: %d of %d." % [maxi(0, ProgressionRules.DAILY_CALIBRATION_LIMIT - used_today), ProgressionRules.DAILY_CALIBRATION_LIMIT], 14, Color("fff0a1")))
	var actions: Array = selected.get("actions", [])
	for entry in actions:
		var action: Dictionary = entry
		tray.add_child(make_button(str(action.label), _run_workshop_station.bind(str(action.target)), Color("a86b2e") if str(action.target) in ["printer", "calibration", "proving", "local_vs"] else Color("2f93a8")))

func render_workshop() -> void:
	var used_today: int = int(GameManager.profile.daily_job_count) if str(GameManager.profile.last_job_day) == shop_day_key else 0
	if workshop_view == "overview":
		render_workshop_overview(used_today)
	else:
		render_workshop_closeup(used_today)
	return

func _workshop_views() -> Array:
	return [
		{"id":"printer", "name":"Printer Bench", "callout":"Arcane Forge and Collection", "description":"The left Arcane Forge holds learned blueprints and printed companions.", "rect":Rect2(0.08, 0.32, 0.28, 0.44), "objects":[{"id":"forge_machine", "name":"Arcane Forge", "description":"Prepare a learned blueprint for a safe, witnessed print.", "target":"printer", "rect":Rect2(0.34, 0.27, 0.36, 0.56)}, {"id":"collection_case", "name":"Collection Case", "description":"Review your learned blueprints and printed companions.", "target":"collection", "rect":Rect2(0.08, 0.06, 0.25, 0.66)}]},
		{"id":"maker", "name":"Maker Bench", "callout":"Team, decks, armor, calibration", "description":"Shape your active team and every field-ready loadout.", "rect":Rect2(0.03, 0.68, 0.31, 0.26), "objects":[{"id":"team_board", "name":"Team Board", "description":"Set one to three printed companions as your active team.", "target":"team", "rect":Rect2(0.02, 0.47, 0.27, 0.28)}, {"id":"deck_blueprints", "name":"Deck Blueprint Rack", "description":"Choose and name a legal fifteen-card support deck.", "target":"deck", "rect":Rect2(0.38, 0.26, 0.24, 0.40)}, {"id":"armor_tools", "name":"Armor Tools", "description":"Learn, print, fit, unequip, and reassign armor.", "target":"armor", "rect":Rect2(0.58, 0.15, 0.24, 0.55)}, {"id":"calibration_dial", "name":"Calibration Dial", "description":"Run today's finite calibration pattern for a measured reward.", "target":"calibration", "rect":Rect2(0.80, 0.40, 0.16, 0.32)}]},
		{"id":"terminal", "name":"Forge Terminal", "callout":"Offers, Forgedex, Guild Trade", "description":"Browse fixed daily offers, records, and a local kid-safe trade demo.", "rect":Rect2(0.65, 0.30, 0.23, 0.34), "objects":[{"id":"offer_screen", "name":"Forge Offers", "description":"Review today's deterministic blueprint, card, and armor offers.", "target":"shop", "rect":Rect2(0.57, 0.35, 0.10, 0.29)}, {"id":"forgedex_screen", "name":"Forgedex Terminal", "description":"Track every discovered creature blueprint.", "target":"codex", "rect":Rect2(0.67, 0.35, 0.11, 0.29)}, {"id":"trade_terminal", "name":"Guild Trade Table", "description":"Open a credential-free two-profile escrow demonstration.", "target":"trade", "rect":Rect2(0.78, 0.35, 0.12, 0.29)}]},
		{"id":"proving", "name":"Proving Door", "callout":"Training and Local Versus", "description":"Step through the center door for a deterministic training rival or private hot-seat match.", "rect":Rect2(0.45, 0.18, 0.20, 0.50), "objects":[{"id":"training_door", "name":"Training Match", "description":"Face today's deterministic rival with your active team and deck.", "target":"proving", "rect":Rect2(0.42, 0.39, 0.23, 0.27)}, {"id":"versus_marker", "name":"Local Versus", "description":"Pass the device between two private players. No rewards are granted.", "target":"local_vs", "rect":Rect2(0.48, 0.64, 0.16, 0.17)}]},
		{"id":"yard", "name":"Print Yard", "callout":"Daily filament lesson", "description":"Visit printed companions for one calm, limited XP lesson each day.", "rect":Rect2(0.37, 0.63, 0.27, 0.29), "objects":[{"id":"yard_companions", "name":"Daily Print Yard", "description":"Share today's local filament lesson with your current collection.", "target":"yard", "rect":Rect2(0.31, 0.44, 0.34, 0.28)}]}
	]

func _workshop_view_data(view_id: String) -> Dictionary:
	for view in _workshop_views():
		if str(view.id) == view_id: return view
	return {}

func _workshop_overview_texture() -> Texture2D:
	return WORKSHOP_OVERVIEW_PORTRAIT_TEXTURE if is_portrait_layout() else WORKSHOP_OVERVIEW_LANDSCAPE_TEXTURE

func _workshop_overview_zones() -> Array:
	# v3 plates are separate compositions, not crops. Rectangles are normalized
	# directly against each plate's pictured props.
	if is_portrait_layout():
		return [
			{"id":"printer", "name":"Printer Bench", "callout":"Arcane Forge and Collection", "rect":Rect2(0.06, 0.51, 0.37, 0.25)},
			{"id":"maker", "name":"Maker Bench", "callout":"Team, decks, armor, calibration", "rect":Rect2(0.58, 0.50, 0.36, 0.25)},
			{"id":"terminal", "name":"Forge Terminal", "callout":"Offers, Forgedex, Guild Trade", "rect":Rect2(0.61, 0.23, 0.31, 0.25)},
			{"id":"proving", "name":"Proving Door", "callout":"Training and Local Versus", "rect":Rect2(0.42, 0.13, 0.18, 0.35)},
			# Keep the portrait yard zone above the compact in-map status tray so it
			# remains reachable without a body scroll on small 576x1024 devices.
			{"id":"yard", "name":"Print Yard", "callout":"Daily filament lesson", "rect":Rect2(0.40, 0.59, 0.20, 0.14)}
		]
	return [
		{"id":"printer", "name":"Printer Bench", "callout":"Arcane Forge and Collection", "rect":Rect2(0.06, 0.48, 0.36, 0.34)},
		{"id":"maker", "name":"Maker Bench", "callout":"Team, decks, armor, calibration", "rect":Rect2(0.60, 0.57, 0.35, 0.28)},
		{"id":"terminal", "name":"Forge Terminal", "callout":"Offers, Forgedex, Guild Trade", "rect":Rect2(0.59, 0.29, 0.22, 0.29)},
		{"id":"proving", "name":"Proving Door", "callout":"Training and Local Versus", "rect":Rect2(0.44, 0.16, 0.14, 0.46)},
		{"id":"yard", "name":"Print Yard", "callout":"Daily filament lesson", "rect":Rect2(0.40, 0.63, 0.16, 0.14)}
	]

func _workshop_texture(view_id: String) -> Texture2D:
	var path: String = str(WORKSHOP_CLOSEUP_PATHS.get(view_id, "res://docs/art/reference/workshop-theme-reference.jpg"))
	var resource := load(path)
	return resource as Texture2D if resource is Texture2D else REFERENCE_TEXTURE

func _workshop_station_texture(view_id: String) -> Texture2D:
	if view_id in ["printer", "maker"]:
		return _workshop_overview_texture()
	return _workshop_texture(view_id)

func _workshop_station_focus(view_id: String) -> Vector2:
	if view_id == "printer":
		return Vector2(0.26, 0.52) if is_portrait_layout() else Vector2(0.25, 0.63)
	if view_id == "maker":
		return Vector2(0.75, 0.52) if is_portrait_layout() else Vector2(0.80, 0.78)
	return Vector2(0.5, 0.5)

func _workshop_station_zoom(view_id: String) -> float:
	if view_id not in ["printer", "maker"]:
		return 1.0
	if is_portrait_layout():
		return 1.50
	return 1.70 if view_id == "printer" else 2.00

func _add_workshop_station_live(art_plane: Control) -> void:
	if workshop_view not in ["printer", "maker"]:
		return
	var layer := WORKSHOP_STATION_LIVE_LAYER.new()
	layer.name = "WorkshopStationLiveLayer"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.configure(GameManager.profile, workshop_view, is_portrait_layout(), bool(settings().get("reduced_motion", false)), bool(settings().get("high_contrast", false)), workshop_station_live_capture_seed, workshop_station_live_capture_progress >= 0 or workshop_ambient_capture_freeze)
	if workshop_station_live_capture_progress >= 0:
		layer.set_capture_progress(workshop_station_live_capture_progress)
	art_plane.add_child(layer)

func _workshop_surface(name_value: String, texture: Texture2D, minimum_height: float, host: Control = null, cover_art := false, ambient_view := "overview", cover_backdrop := false, allow_portrait_pan := true, focus := Vector2(0.5, 0.5), art_zoom := 1.0) -> Control:
	var map_frame := PanelContainer.new()
	map_frame.custom_minimum_size = Vector2(0, minimum_height)
	map_frame.add_theme_stylebox_override("panel", panel_style(Color("071526e8"), Color("6bd6ed")))
	(host if host != null else body).add_child(map_frame)
	var map := Control.new()
	map.name = name_value
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.clip_contents = true
	map_frame.add_child(map)
	if cover_backdrop:
		var cover_image := TextureRect.new()
		cover_image.name = "WorkshopCoverBackdrop"
		cover_image.texture = texture
		cover_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		cover_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cover_image.modulate = Color(0.58, 0.75, 0.96, 0.60)
		cover_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map.add_child(cover_image)
		var cover_shade := ColorRect.new()
		cover_shade.color = Color("07132670")
		cover_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cover_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map.add_child(cover_shade)
	var art_plane := Control.new()
	art_plane.name = "%sArtPlane" % name_value
	# Empty room pixels pass drag input to the clipped map; child prop Buttons
	# retain their own click/focus behavior and forward drag gestures explicitly.
	art_plane.mouse_filter = Control.MOUSE_FILTER_PASS
	map.add_child(art_plane)
	var texture_size := texture.get_size()
	map.set_meta("workshop_art_aspect", texture_size.x / texture_size.y if texture_size.y > 0.0 else 1.5)
	map.set_meta("workshop_art_cover", cover_art)
	map.set_meta("workshop_stage_texture", texture.resource_path)
	map.set_meta("workshop_pan_enabled", cover_art and allow_portrait_pan and is_portrait_layout())
	map.set_meta("workshop_art_focus", focus)
	map.set_meta("workshop_art_zoom", art_zoom)
	map.resized.connect(_fit_workshop_art_plane.bind(map, art_plane))
	if bool(map.get_meta("workshop_pan_enabled", false)):
		map.gui_input.connect(_on_workshop_pan_gui_input.bind(map, art_plane))
		_add_workshop_pan_affordance(map, art_plane)
	call_deferred("_fit_workshop_art_plane", map, art_plane)
	var image := TextureRect.new()
	image.name = "WorkshopArtTexture"
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover_art else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.modulate = Color(0.94, 0.97, 1.0, 0.96)
	art_plane.add_child(image)
	var tint := ColorRect.new()
	tint.color = Color("07132618")
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_plane.add_child(tint)
	if ambient_view != "overview":
		var ambient := WORKSHOP_AMBIENT_LAYER.new()
		ambient.name = "WorkshopAmbientLayer"
		ambient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ambient.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ambient.configure(ambient_view, not bool(settings().get("reduced_motion", false)) and not workshop_ambient_capture_freeze, 0.35)
		art_plane.add_child(ambient)
	if ambient_view != "overview" and not bool(settings().get("reduced_motion", false)) and not workshop_ambient_capture_freeze:
		var veil := ColorRect.new()
		veil.color = Color("b7efff80")
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_plane.add_child(veil)
		var tween := create_tween()
		tween.tween_property(veil, "modulate:a", 0.0, 0.18)
	return art_plane

func _fit_workshop_art_plane(map: Control, art_plane: Control) -> void:
	var available := map.size
	if available.x <= 0.0 or available.y <= 0.0: return
	var aspect: float = float(map.get_meta("workshop_art_aspect", 1.5))
	var fitted_width := maxf(available.x, available.y * aspect) if bool(map.get_meta("workshop_art_cover", false)) else minf(available.x, available.y * aspect)
	var fitted_size := Vector2(fitted_width, fitted_width / aspect)
	fitted_size *= float(map.get_meta("workshop_art_zoom", 1.0))
	art_plane.size = fitted_size
	var focus: Vector2 = map.get_meta("workshop_art_focus", Vector2(0.5, 0.5))
	var centered_position := available * 0.5 - fitted_size * focus
	if not bool(map.get_meta("workshop_art_cover", false)):
		centered_position = (available - fitted_size) * 0.5
	else:
		centered_position.x = clampf(centered_position.x, available.x - fitted_size.x, 0.0)
		centered_position.y = clampf(centered_position.y, available.y - fitted_size.y, 0.0)
	art_plane.position = centered_position
	if bool(map.get_meta("workshop_pan_enabled", false)):
		var saved_pan: float = float(map.get_meta("workshop_pan_x", centered_position.x))
		_set_workshop_pan(map, art_plane, saved_pan)

func _set_workshop_pan(map: Control, art_plane: Control, next_x: float) -> void:
	var minimum_x := minf(0.0, map.size.x - art_plane.size.x)
	var maximum_x := 0.0
	art_plane.position.x = clampf(next_x, minimum_x, maximum_x)
	map.set_meta("workshop_pan_x", art_plane.position.x)

func _on_workshop_pan_gui_input(event: InputEvent, map: Control, art_plane: Control) -> void:
	if not bool(map.get_meta("workshop_pan_enabled", false)):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_workshop_pan(map, art_plane, event.position)
		else:
			_end_workshop_pan(map)
	elif event is InputEventMouseMotion and bool(map.get_meta("workshop_pan_tracking", false)):
		_move_workshop_pan(map, art_plane, event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_workshop_pan(map, art_plane, event.position)
		else:
			_end_workshop_pan(map)
	elif event is InputEventScreenDrag:
		_move_workshop_pan(map, art_plane, event.position)

func _begin_workshop_pan(map: Control, art_plane: Control, pointer: Vector2) -> void:
	map.set_meta("workshop_pan_tracking", true)
	map.set_meta("workshop_pan_dragged", false)
	map.set_meta("workshop_pan_start_pointer", pointer)
	map.set_meta("workshop_pan_start_x", art_plane.position.x)

func _move_workshop_pan(map: Control, art_plane: Control, pointer: Vector2) -> void:
	var start_pointer: Vector2 = map.get_meta("workshop_pan_start_pointer", pointer)
	var delta_x := pointer.x - start_pointer.x
	if absf(delta_x) < 10.0 and not bool(map.get_meta("workshop_pan_dragged", false)):
		return
	map.set_meta("workshop_pan_dragged", true)
	_set_workshop_pan(map, art_plane, float(map.get_meta("workshop_pan_start_x", art_plane.position.x)) + delta_x)

func _end_workshop_pan(map: Control) -> void:
	map.set_meta("workshop_pan_tracking", false)

func _on_workshop_hotspot_gui_input(event: InputEvent, button: Button) -> void:
	var art_plane := button.get_parent() as Control
	var map := _workshop_scene_map(art_plane)
	if map == null or not bool(map.get_meta("workshop_pan_enabled", false)):
		return
	var was_dragged := bool(map.get_meta("workshop_pan_dragged", false))
	_on_workshop_pan_gui_input(event, map, art_plane)
	if was_dragged or bool(map.get_meta("workshop_pan_dragged", false)):
		button.set_meta("workshop_pan_cancelled", true)

func _pan_workshop_hotspot_into_view(button: Button) -> void:
	var art_plane := button.get_parent() as Control
	var map := _workshop_scene_map(art_plane)
	if map == null or not bool(map.get_meta("workshop_pan_enabled", false)):
		return
	var map_rect := map.get_global_rect()
	var hotspot_rect := button.get_global_rect()
	var padding := 18.0
	var adjustment := 0.0
	if hotspot_rect.position.x < map_rect.position.x + padding:
		adjustment = map_rect.position.x + padding - hotspot_rect.position.x
	elif hotspot_rect.end.x > map_rect.end.x - padding:
		adjustment = map_rect.end.x - padding - hotspot_rect.end.x
	if not is_zero_approx(adjustment):
		_set_workshop_pan(map, art_plane, art_plane.position.x + adjustment)

func _toggle_workshop_pan(map: Control, art_plane: Control) -> void:
	var minimum_x := minf(0.0, map.size.x - art_plane.size.x)
	var target_x := minimum_x if art_plane.position.x > minimum_x * 0.5 else 0.0
	_set_workshop_pan(map, art_plane, target_x)

func _add_workshop_pan_affordance(map: Control, art_plane: Control) -> void:
	var button := Button.new()
	button.name = "WorkshopPanAffordance"
	button.text = ""
	button.tooltip_text = "Swipe the workshop view to reach more tools"
	button.accessibility_name = "Swipe the workshop view to reach more tools"
	button.anchor_left = 0.45; button.anchor_right = 0.55
	button.anchor_top = 0.82; button.anchor_bottom = 0.88
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.custom_minimum_size = Vector2(44, 30)
	button.add_theme_stylebox_override("normal", workshop_hotspot_style())
	button.add_theme_stylebox_override("hover", workshop_hotspot_style())
	button.add_theme_stylebox_override("focus", workshop_hotspot_style())
	button.add_theme_stylebox_override("pressed", workshop_hotspot_style())
	var glyph := WORKSHOP_PAN_AFFORDANCE.new()
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(glyph)
	button.pressed.connect(_toggle_workshop_pan.bind(map, art_plane))
	map.add_child(button)

func _workshop_zone_button(view: Dictionary) -> Button:
	var rect: Rect2 = view.rect
	var button := Button.new()
	button.name = "WorkshopZone%s" % str(view.id).capitalize()
	button.text = ""
	button.tooltip_text = "%s: %s" % [str(view.name), str(view.callout)]
	button.accessibility_name = "%s work area" % str(view.name)
	button.anchor_left = rect.position.x; button.anchor_top = rect.position.y; button.anchor_right = rect.end.x; button.anchor_bottom = rect.end.y
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.custom_minimum_size = Vector2(44, 44)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", workshop_hotspot_style())
	button.add_theme_stylebox_override("hover", workshop_hotspot_style())
	button.add_theme_stylebox_override("focus", workshop_hotspot_style())
	button.add_theme_stylebox_override("pressed", workshop_hotspot_style())
	_add_workshop_hotspot_overlay(button, Color("9beaff"))
	button.pressed.connect(open_workshop_view.bind(str(view.id)))
	return button

func _workshop_object_rect(object: Dictionary) -> Rect2:
	var object_id := str(object.id)
	# v3 live stations use landmark rectangles on the same cropped art plane as
	# their drawn printer/team display, so focus glow never crosses a live figure.
	if workshop_view == "printer":
		if object_id == "forge_machine":
			return Rect2(0.10, 0.38, 0.34, 0.26) if is_portrait_layout() else Rect2(0.08, 0.42, 0.24, 0.42)
		if object_id == "collection_case":
			return Rect2(0.02, 0.18, 0.20, 0.22) if is_portrait_layout() else Rect2(0.02, 0.18, 0.22, 0.24)
	if workshop_view == "maker":
		if object_id == "team_board":
			return Rect2(0.57, 0.43, 0.36, 0.17) if is_portrait_layout() else Rect2(0.63, 0.61, 0.31, 0.25)
		if object_id == "deck_blueprints":
			return Rect2(0.48, 0.34, 0.13, 0.12) if is_portrait_layout() else Rect2(0.53, 0.28, 0.12, 0.12)
		if object_id == "armor_tools":
			return Rect2(0.76, 0.36, 0.14, 0.13) if is_portrait_layout() else Rect2(0.84, 0.24, 0.12, 0.14)
		if object_id == "calibration_dial":
			return Rect2(0.63, 0.42, 0.12, 0.11) if is_portrait_layout() else Rect2(0.68, 0.34, 0.12, 0.12)
	return object.rect

func _workshop_object_button(object: Dictionary) -> Button:
	var rect: Rect2 = _workshop_object_rect(object)
	var button := Button.new()
	button.name = "WorkshopObject%s" % str(object.id).capitalize()
	button.text = ""
	button.tooltip_text = "%s: %s" % [str(object.name), str(object.description)]
	button.accessibility_name = str(object.name)
	button.anchor_left = rect.position.x; button.anchor_top = rect.position.y; button.anchor_right = rect.end.x; button.anchor_bottom = rect.end.y
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.custom_minimum_size = Vector2(44, 44)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", workshop_hotspot_style())
	button.add_theme_stylebox_override("hover", workshop_hotspot_style())
	button.add_theme_stylebox_override("focus", workshop_hotspot_style())
	button.add_theme_stylebox_override("pressed", workshop_hotspot_style())
	_add_workshop_hotspot_overlay(button, Color("ffd36c"))
	button.gui_input.connect(_on_workshop_hotspot_gui_input.bind(button))
	button.focus_entered.connect(_pan_workshop_hotspot_into_view.bind(button))
	button.pressed.connect(_select_workshop_object_if_not_dragged.bind(str(object.id), button))
	return button

func _select_workshop_object_if_not_dragged(object_id: String, button: Button) -> void:
	if bool(button.get_meta("workshop_pan_cancelled", false)):
		button.set_meta("workshop_pan_cancelled", false)
		return
	select_workshop_object(object_id)

func _add_workshop_hotspot_overlay(button: Button, color: Color) -> void:
	var overlay := WORKSHOP_HOTSPOT_OVERLAY.new()
	overlay.name = "WorkshopHotspotOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.configure(color, not bool(settings().get("reduced_motion", false)) and not workshop_ambient_capture_freeze, 0.25)
	button.add_child(overlay)
	button.mouse_entered.connect(overlay.set_emphasis.bind(0.65))
	button.mouse_exited.connect(overlay.set_emphasis.bind(0.0))
	button.focus_entered.connect(overlay.set_emphasis.bind(1.0))
	button.focus_exited.connect(overlay.set_emphasis.bind(0.0))
	button.button_down.connect(overlay.set_emphasis.bind(1.0))

func _workshop_settings_button() -> Button:
	var button := make_button("\u2699", navigate_to.bind("settings"), Color("536c8d"))
	button.name = "WorkshopSettingsButton"
	button.tooltip_text = "Settings: text scale, contrast, motion, and training difficulty"
	button.accessibility_name = "Workshop settings"
	button.anchor_left = 0.91; button.anchor_top = 0.035; button.anchor_right = 0.975; button.anchor_bottom = 0.145
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.add_theme_font_size_override("font_size", scaled_font(23))
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	return button

func _printer_picker_button() -> Button:
	var button := make_button("Close Blueprint Tray" if printer_picker_open else "Choose a Print", close_printer_picker if printer_picker_open else open_printer_picker, Color("a86b2e"))
	button.name = "PrinterBlueprintTrayButton"
	button.tooltip_text = "Choose a learned creature blueprint to preview in the Arcane Forge"
	button.accessibility_name = "Choose a Print Blueprint Tray"
	# Keep selection reachable in the physical Printer station without covering the
	# presentation-only Forge. The right floor/cabinet stays clear in both crops.
	button.anchor_left = 0.70; button.anchor_right = 0.88
	button.anchor_top = 0.72 if is_portrait_layout() else 0.76
	button.anchor_bottom = button.anchor_top
	button.offset_left = 0; button.offset_right = 0
	button.offset_top = 0; button.offset_bottom = 48
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button

func _workshop_overview_button() -> Button:
	var button := make_button("\u2190", open_workshop_view.bind("overview"), Color("536c8d"))
	button.name = "WorkshopOverviewButton"
	button.tooltip_text = "Return to the full workshop overview"
	button.accessibility_name = "Return to Workshop Overview"
	button.anchor_left = 0.025; button.anchor_top = 0.035; button.anchor_right = 0.09; button.anchor_bottom = 0.145
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.add_theme_font_size_override("font_size", scaled_font(23))
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return button

func render_workshop_overview(used_today: int) -> void:
	overview_layout_portrait = is_portrait_layout()
	var overview_height := maxf(620.0, get_viewport().get_visible_rect().size.y - 215.0) if overview_layout_portrait else maxf(500.0, get_viewport().get_visible_rect().size.y - 150.0)
	# v3 overview plates are aspect-specific, static establishing shots. They never
	# host mutable-looking printer/team overlays or motion; those belong in stations.
	var map := _workshop_surface("WorkshopMap", _workshop_overview_texture(), overview_height, null, true, "overview", false, false)
	map.add_child(_workshop_settings_button())
	for view in _workshop_overview_zones(): map.add_child(_workshop_zone_button(view))
	_add_workshop_overview_status(map, used_today)

func render_workshop_closeup(used_today: int) -> void:
	var view := _workshop_view_data(workshop_view)
	if view.is_empty():
		open_workshop_view("overview")
		return
	var picker_open := workshop_view == "printer" and printer_picker_open
	# A selected tool gets a dedicated right-hand blueprint tray on desktop.
	# Portrait deliberately keeps the proven art-over-tray composition instead.
	if not is_portrait_layout() and (not workshop_drawer_object.is_empty() or picker_open):
		var split := HBoxContainer.new()
		split.name = "WorkshopCloseupSplit"
		split.custom_minimum_size = Vector2(0, 500)
		split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		split.add_theme_constant_override("separation", 16)
		body.add_child(split)
		var art_column := VBoxContainer.new()
		art_column.name = "WorkshopCloseupArt"
		art_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art_column.size_flags_stretch_ratio = 6.0 if picker_open else 7.0
		split.add_child(art_column)
		var tray_column := VBoxContainer.new()
		tray_column.name = "WorkshopBlueprintTrayColumn"
		tray_column.custom_minimum_size = Vector2(420 if picker_open else 300, 0)
		tray_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tray_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tray_column.size_flags_stretch_ratio = 4.0 if picker_open else 3.0
		split.add_child(tray_column)
		var split_map := _workshop_surface("WorkshopCloseupMap", _workshop_station_texture(workshop_view), 500, art_column, true, workshop_view, false, true, _workshop_station_focus(workshop_view), _workshop_station_zoom(workshop_view))
		_add_workshop_station_live(split_map)
		var split_chrome := _workshop_scene_map(split_map)
		split_chrome.add_child(_workshop_overview_button())
		split_chrome.add_child(_workshop_settings_button())
		if workshop_view == "printer":
			split_chrome.add_child(_printer_picker_button())
		for object in view.objects: split_map.add_child(_workshop_object_button(object))
		if picker_open:
			render_printer_blueprint_tray(tray_column)
		else:
			render_workshop_drawer(view, tray_column)
		return
	var portrait := is_portrait_layout()
	var closeup_height := 430.0 if portrait else 330.0
	if picker_open and portrait:
		# Leave enough room for the first picker tiles on small Android portrait
		# screens while retaining an unobscured live Printer Bench above them.
		closeup_height = 320.0
	elif workshop_drawer_object.is_empty():
		closeup_height = maxf(720.0, get_viewport().get_visible_rect().size.y - 250.0) if portrait else 560.0
	var live_station := workshop_view in ["printer", "maker"]
	var map := _workshop_surface("WorkshopCloseupMap", _workshop_station_texture(workshop_view), closeup_height, null, portrait or live_station, workshop_view, false, true, _workshop_station_focus(workshop_view), _workshop_station_zoom(workshop_view))
	_add_workshop_station_live(map)
	var chrome := _workshop_scene_map(map)
	chrome.add_child(_workshop_overview_button())
	chrome.add_child(_workshop_settings_button())
	if workshop_view == "printer":
		chrome.add_child(_printer_picker_button())
	for object in view.objects: map.add_child(_workshop_object_button(object))
	_add_workshop_scene_status(map, view, used_today)
	if picker_open:
		render_printer_blueprint_tray()
		return
	if workshop_drawer_object.is_empty():
		return
	render_workshop_drawer(view)

func _add_workshop_scene_status(art_plane: Control, view: Dictionary, used_today: int) -> void:
	var scene_map := _workshop_scene_map(art_plane)
	if scene_map == null:
		return
	var strip := PanelContainer.new()
	strip.name = "WorkshopSceneStatus"
	strip.anchor_left = 0.025; strip.anchor_right = 0.975
	if workshop_view == "maker" and not is_portrait_layout():
		# The landscape three-plinth row rises into the upper-right. Keep its
		# compact explanatory tray on the unused lower-left rug/floor instead.
		strip.anchor_left = 0.04; strip.anchor_right = 0.40
		strip.anchor_top = 0.78; strip.anchor_bottom = 0.78
		strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = 0; strip.offset_bottom = 58
	elif workshop_view in ["printer", "maker"]:
		# Live v3 station scenes reserve their lower landmarks for the printer bed or
		# three plinths. A compact top strip leaves both controls and prop bases clear.
		strip.anchor_left = 0.14; strip.anchor_right = 0.84
		strip.anchor_top = 0.025; strip.anchor_bottom = 0.025
		strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = 0; strip.offset_bottom = 58
	else:
		strip.anchor_top = 1.0; strip.anchor_bottom = 1.0
		strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = -94; strip.offset_bottom = -14
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_theme_stylebox_override("panel", panel_style(Color("102940e8"), Color("f1be69")))
	scene_map.add_child(strip)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	strip.add_child(content)
	content.add_child(label("%s - %s" % [str(view.name), str(view.callout)], 16, Color("ffd36c")))
	var detail := "Focus a highlighted tool to open its Blueprint Tray."
	if workshop_view == "maker": detail = "Calibration remaining today: %d / %d." % [maxi(0, ProgressionRules.DAILY_CALIBRATION_LIMIT - used_today), ProgressionRules.DAILY_CALIBRATION_LIMIT]
	elif workshop_view == "yard": detail = "%d companions are ready for one calm filament lesson today." % GameManager.profile.creatures.size()
	content.add_child(label(detail, 13, Color("dce8f4")))

func _add_workshop_overview_status(art_plane: Control, used_today: int) -> void:
	var scene_map := _workshop_scene_map(art_plane)
	if scene_map == null:
		return
	var strip := PanelContainer.new()
	strip.name = "WorkshopProgressionStrip"
	strip.anchor_left = 0.025; strip.anchor_right = 0.975
	strip.anchor_top = 1.0; strip.anchor_bottom = 1.0
	strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = -94; strip.offset_bottom = -14
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_theme_stylebox_override("panel", panel_style(Color("102940e8"), Color("6bd6ed")))
	scene_map.add_child(strip)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	strip.add_child(content)
	content.add_child(label("Explore the Workshop", 16, Color("9beaff")))
	content.add_child(label("Focus a soft-lit work area to move closer. XP %d / %d | Calibration %d / %d" % [int(GameManager.profile.xp), GameManager.filament_cap() * 100, used_today, ProgressionRules.DAILY_CALIBRATION_LIMIT], 13, Color("dce8f4")))

func _workshop_scene_map(art_plane: Control) -> Control:
	return art_plane.get_parent() as Control

func _workshop_object_data(view: Dictionary, object_id: String) -> Dictionary:
	for object in view.objects:
		if str(object.id) == object_id: return object
	return {}

func render_workshop_drawer(view: Dictionary, host: Control = null) -> void:
	var object := _workshop_object_data(view, workshop_drawer_object)
	if object.is_empty():
		workshop_drawer_object = ""
		return
	var drawer := make_panel(Color("15344bea"), Color("f1be69"))
	drawer.get_parent().name = "WorkshopContextDrawer"
	(host if host != null else body).add_child(drawer.get_parent())
	drawer.add_child(label("Blueprint Tray - %s" % str(object.name), 20, Color("ffd36c")))
	drawer.add_child(label(str(object.description), 15, Color("e4edf7")))
	var target: String = str(object.target)
	var action_tiles := GridContainer.new()
	action_tiles.name = "WorkshopDrawerActions"
	action_tiles.columns = 2
	action_tiles.add_theme_constant_override("h_separation", 10)
	action_tiles.add_theme_constant_override("v_separation", 10)
	drawer.add_child(action_tiles)
	action_tiles.add_child(make_button(_workshop_action_label(target), _run_workshop_station.bind(target), Color("a86b2e") if target in ["printer", "calibration", "proving", "local_vs"] else Color("2f93a8")))
	action_tiles.add_child(make_button("Close Tray", close_workshop_drawer, Color("536c8d")))

func printer_blueprint_ids() -> Array[String]:
	var ids: Array[String] = []
	for stored_id in GameManager.profile.get("blueprints", []):
		var creature_id := str(stored_id)
		if not creature_id.is_empty() and not Catalog.creature(creature_id).is_empty() and creature_id not in ids:
			ids.append(creature_id)
	ids.sort_custom(func(left: String, right: String) -> bool: return str(Catalog.creature(left).get("name", left)) < str(Catalog.creature(right).get("name", right)))
	return ids

func _printer_owned_count(creature_id: String) -> int:
	var count := 0
	for instance in GameManager.profile.get("creatures", []):
		if str(instance.get("creature_id", "")) == creature_id:
			count += 1
	return count

func _printer_idle_texture(definition: Dictionary) -> Texture2D:
	var path := str(definition.get("sprite_sheet", ""))
	var sheet := ResourceLoader.load(path) as Texture2D if not path.is_empty() else null
	if sheet != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		# Stay two pixels inside the 384x512 idle cell so linear filtering cannot
		# leak a neighboring animation frame into this compact picker thumbnail.
		atlas.region = Rect2(2, 2, 380, 508)
		return atlas
	var raw_path := str(definition.get("raw_print", ""))
	return ResourceLoader.load(raw_path) as Texture2D if not raw_path.is_empty() else null

func _printer_blueprint_card(creature_id: String) -> Control:
	var definition := Catalog.creature(creature_id)
	var rarity := Catalog.rarity(str(definition.get("rarity", "common")))
	var price := int(rarity.get("print", 0))
	var owned := _printer_owned_count(creature_id)
	var card := PanelContainer.new()
	card.name = "PrinterBlueprintCard%s" % creature_id.capitalize()
	card.set_meta("creature_id", creature_id)
	card.set_meta("price", price)
	card.set_meta("owned_count", owned)
	card.custom_minimum_size = Vector2(190, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", panel_style(Color("102940ec"), Color(str(rarity.get("color", "6bd6ed")))))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	card.add_child(content)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 8)
	content.add_child(identity)
	var preview := TextureRect.new()
	preview.name = "PrinterBlueprintIdleArt"
	preview.custom_minimum_size = Vector2(76, 104)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = _printer_idle_texture(definition)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_child(preview)
	var facts := VBoxContainer.new()
	facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(facts)
	facts.add_child(label(str(definition.get("name", creature_id)), 17, Color("ffffff")))
	facts.add_child(label("%s - %s" % [str(definition.get("element", "Unknown")), str(rarity.get("name", "Common"))], 13, Color("b8dcef")))
	facts.add_child(label("Forge Coin print: %d" % price, 13, Color("ffd36c")))
	facts.add_child(label("Owned prints: %d" % owned, 13, Color("a8e3a5")))
	var preview_button := make_button("Preview %s" % str(definition.get("name", creature_id)), open_printer.bind(creature_id), Color("a86b2e"))
	preview_button.name = "PrinterPreview%s" % creature_id.capitalize()
	preview_button.tooltip_text = "Preview %s in the Arcane Forge" % str(definition.get("name", creature_id))
	content.add_child(preview_button)
	return card

func render_printer_blueprint_tray(host: Control = null) -> void:
	var tray := make_panel(Color("15344bea"), Color("f1be69"))
	tray.get_parent().name = "PrinterBlueprintTray"
	(host if host != null else body).add_child(tray.get_parent())
	tray.add_child(label("Blueprint Tray - Choose a Print", 21, Color("ffd36c")))
	tray.add_child(label("Previewing is safe: Forge Coins and inventory change only when Begin Print reaches the secured commit seam.", 14, Color("dce8f4")))
	var ids := printer_blueprint_ids()
	if ids.is_empty():
		var empty := label("No learned creature blueprints are ready. Visit Forge Offers to learn a pattern, then return to this bench.", 16, Color("fff0a1"))
		empty.name = "PrinterBlueprintEmptyState"
		tray.add_child(empty)
		var offers := make_button("Open Forge Offers", navigate_to.bind("shop"), Color("2f93a8"))
		offers.name = "PrinterBlueprintEmptyOffers"
		tray.add_child(offers)
		tray.add_child(make_button("Close Blueprint Tray", close_printer_picker, Color("536c8d")))
		return
	var cards := GridContainer.new()
	cards.name = "PrinterBlueprintGrid"
	cards.columns = 1 if is_portrait_layout() else 2
	cards.add_theme_constant_override("h_separation", 10)
	cards.add_theme_constant_override("v_separation", 10)
	tray.add_child(cards)
	for creature_id in ids:
		cards.add_child(_printer_blueprint_card(creature_id))
	tray.add_child(make_button("Close Blueprint Tray", close_printer_picker, Color("536c8d")))

func _workshop_action_label(target: String) -> String:
	var names := {"printer":"Open Arcane Forge", "collection":"Open Collection", "team":"Edit Team", "deck":"Edit Deck Slots", "armor":"Open Armor", "calibration":"Run Calibration", "shop":"Open Forge Offers", "codex":"Open Forgedex", "trade":"Open Guild Trade", "proving":"Start Training", "local_vs":"Start Local Versus", "yard":"Visit Print Yard"}
	return str(names.get(target, "Open Station"))

func open_workshop_view(view_id: String) -> void:
	workshop_view = view_id if view_id == "overview" or not _workshop_view_data(view_id).is_empty() else "overview"
	workshop_selected = workshop_view
	workshop_drawer_object = ""
	printer_picker_open = false
	render()

func select_workshop_object(object_id: String) -> void:
	var object := _workshop_object_data(_workshop_view_data(workshop_view), object_id)
	if object.is_empty(): return
	workshop_drawer_object = object_id
	_toast(str(object.name))
	render()

func close_workshop_drawer() -> void:
	if workshop_drawer_object.is_empty(): return
	workshop_drawer_object = ""
	render()

func open_printer_picker() -> void:
	# The Printer Bench is self-sufficient: selection is deliberate and never
	# guesses a starter blueprint or mutates profile state.
	if screen != "workshop":
		screen = "workshop"
	workshop_view = "printer"
	workshop_selected = "printer"
	workshop_drawer_object = ""
	printer_picker_open = true
	render()

func close_printer_picker() -> void:
	if not printer_picker_open:
		return
	printer_picker_open = false
	render()

func _workshop_stations() -> Array:
	return [
		{"id":"forge","name":"Printer Bench","description":"The left Arcane Forge holds every learned blueprint and printed companion.","actions":[{"label":"Open Arcane Forge","target":"printer"},{"label":"Open Collection","target":"collection"}],"rect":Rect2(0.05,0.48,0.17,0.23)},
		{"id":"maker","name":"Maker Bench","description":"Shape the active team, named deck slots, fitted armor, and daily calibration patterns at one maker table.","actions":[{"label":"Edit Team","target":"team"},{"label":"Edit Deck Slots","target":"deck"},{"label":"Open Armor","target":"armor"},{"label":"Run Calibration","target":"calibration"}],"rect":Rect2(0.27,0.68,0.25,0.17)},
		{"id":"terminal","name":"Forge Terminal","description":"Browse deterministic offers, track creature records, or open the kid-safe local trade table.","actions":[{"label":"Open Forge Offers","target":"shop"},{"label":"Open Forgedex","target":"codex"},{"label":"Open Trade Table","target":"trade"}],"rect":Rect2(0.76,0.50,0.19,0.23)},
		{"id":"door","name":"Proving Door","description":"Challenge today’s deterministic training rival or pass the device for a local match.","actions":[{"label":"Start Training","target":"proving"},{"label":"Start Local Versus","target":"local_vs"}],"rect":Rect2(0.41,0.25,0.19,0.33)},
		{"id":"yard","name":"Print Yard","description":"Visit companions for one daily XP filament lesson.","actions":[{"label":"Visit Print Yard","target":"yard"}],"rect":Rect2(0.05,0.77,0.18,0.13)},
		{"id":"settings","name":"Settings","description":"Adjust text, contrast, motion, and AI training difficulty.","actions":[{"label":"Open Settings","target":"settings"}],"rect":Rect2(0.84,0.08,0.12,0.11)}]

func _workshop_station(id: String) -> Dictionary:
	for station in _workshop_stations():
		if str(station.id) == id: return station
	return _workshop_stations()[0]

func _workshop_hotspot(station: Dictionary) -> Button:
	var rect: Rect2 = station.rect
	var button := Button.new(); button.text = str(station.name); button.tooltip_text = str(station.description)
	button.anchor_left = rect.position.x; button.anchor_top = rect.position.y; button.anchor_right = rect.end.x; button.anchor_bottom = rect.end.y
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0; button.custom_minimum_size = Vector2(44, 44)
	button.add_theme_font_size_override("font_size", scaled_font(13))
	var chosen := str(station.id) == workshop_selected
	button.add_theme_stylebox_override("normal", panel_style(Color("a86b2ed0") if chosen else Color("142840d8"), Color("fff0a1") if chosen else Color("8deaff")))
	button.add_theme_stylebox_override("hover", panel_style(Color("2f93a8ed"), Color("ffffff")))
	button.pressed.connect(func(): workshop_selected = str(station.id); render())
	return button

func _run_workshop_station(id: String) -> void:
	match id:
		"printer": open_printer_picker()
		"collection", "shop", "codex", "team", "deck", "armor", "settings": navigate_to(id)
		"proving": start_battle()
		"local_vs": start_local_vs()
		"trade": local_trade = null; trade_creator_choice = ""; trade_partner_choice = ""; navigate_to("trade")
		"yard", "calibration": navigate_to(id)

func start_local_vs() -> void:
	var team := GameManager.current_team_loadout()
	if team.is_empty(): _toast("Choose a starter before starting local versus."); return
	local_authority = LocalBattleAuthority.create(team, ["mossmunk", "voltwig"], GameManager.active_deck_cards(), 20260814)
	local_ready_seat = -1
	local_concede_armed = false
	if screen == "workshop": workshop_return_view = workshop_view
	screen = "local_vs"
	render()

func render_local_vs() -> void:
	var panel := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(panel.get_parent())
	panel.add_child(label("Local Versus - Proving Grounds", 25, Color("ffd36c")))
	if local_authority == null:
		panel.add_child(label("Start a private hot-seat match from the Workshop.", 16, Color("dce8f4")))
		panel.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d"))); return
	var state := local_authority.state
	panel.add_child(label("Authority revision %d  |  Match seed %d  |  No rewards in local versus" % [local_authority.revision, state.seed], 15, Color("9beaff")))
	var seat := state.active_player
	if not state.finished and local_ready_seat != seat:
		local_concede_armed = false
		panel.add_child(label("Private handoff", 20, Color("fff0a1")))
		panel.add_child(label("Pass the device. The next hand remains hidden until the ready button is pressed.", 16, Color("dce8f4")))
		panel.add_child(make_button("Ready Player %d" % (seat + 1), func(): local_ready_seat = seat; render(), Color("a86b2e")))
		panel.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d"))); return
	var stage := BattleSpriteStage.new(); stage.configure(state.active_unit(0), state.active_unit(1), battle_last_event, battle_last_actor, bool(settings().get("reduced_motion", false))); panel.add_child(stage); stage.custom_minimum_size = Vector2(0, 110 if is_portrait_layout() else 120)
	for player in [0, 1]:
		var unit := state.active_unit(player)
		panel.add_child(label("Player %d: %s  %d/%d HP - %s" % [player + 1, str(unit.name), int(unit.hp), int(unit.max_hp), str(unit.element)], 17, Color("a9ecff") if player == 0 else Color("ffaaa1")))
	if state.finished:
		panel.add_child(label("Local match complete. No Forge Coins or rewards are granted.", 18, Color("fff0a1")))
		panel.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d"))); return
	panel.add_child(label("Player %d hand: %s" % [seat + 1, ", ".join(state.players[seat].hand)], 15, Color("dce8f4")))
	var actions := GridContainer.new(); actions.name = "LocalBattleActionGrid"; actions.columns = 2 if is_portrait_layout() else 4; actions.add_theme_constant_override("h_separation", 8); actions.add_theme_constant_override("v_separation", 8); panel.add_child(actions)
	for action in [{"type":"attack","name":"Basic Attack"},{"type":"ability","name":"Signature Ability"},{"type":"defend","name":"Defend"},{"type":"end_turn","name":"End Turn"}]:
		actions.add_child(make_button(str(action.name), func(): submit_local_intent({"type":action.type}), Color("2f93a8")))
	var card_counts := {}
	for card_id in state.players[seat].hand: card_counts[str(card_id)] = int(card_counts.get(str(card_id), 0)) + 1
	for card_id in card_counts:
		body.add_child(make_button("Play %s x%d" % [str(card_id).replace("_", " ").capitalize(), int(card_counts[card_id])], func(): submit_local_intent({"type":"card","card_id":card_id}), Color("526e93")))
	var navigation := GridContainer.new(); navigation.name = "LocalBattleNavigationGrid"; navigation.columns = 2 if is_portrait_layout() else 3; navigation.add_theme_constant_override("h_separation", 8); navigation.add_theme_constant_override("v_separation", 8); body.add_child(navigation)
	for index in state.players[seat].team.size():
		if index != int(state.players[seat].active) and int(state.players[seat].team[index].hp) > 0:
			navigation.add_child(make_button("Switch to %s" % str(state.players[seat].team[index].name), func(): submit_local_intent({"type":"switch","index":index}), Color("4d7898")))
	if local_concede_armed:
		navigation.add_child(make_button("Confirm Concede", toggle_local_concede, Color("9a5b6f")))
		navigation.add_child(make_button("Cancel Concede", cancel_local_concede, Color("536c8d")))
	else:
		navigation.add_child(make_button("Concede", toggle_local_concede, Color("9a5b6f")))
	navigation.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func submit_local_intent(intent: Dictionary) -> void:
	if local_authority == null: return
	if str(intent.get("type", "")) != "concede": local_concede_armed = false
	var seat := local_authority.state.active_player
	var result := local_authority.submit({"seat":seat,"expected_revision":local_authority.revision,"intent":intent})
	if not bool(result.ok): _toast(str(result.error)); return
	battle_last_event = str(intent.type); battle_last_actor = seat; local_ready_seat = -1; render()

func toggle_local_concede() -> void:
	if local_authority == null or local_authority.state.finished: return
	if not local_concede_armed:
		local_concede_armed = true
		_toast("Press Confirm Concede to end this local match.")
		render()
		return
	local_concede_armed = false
	submit_local_intent({"type":"concede"})

func cancel_local_concede() -> void:
	if not local_concede_armed: return
	local_concede_armed = false
	_toast("Concede cancelled.")
	render()

func _guildmate_profile() -> Dictionary:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "aquafin").profile
	profile.coins = 0
	profile.blueprints.append("voltwig")
	var printed := ProgressionRules.print_creature({"coins":99,"blueprints":["voltwig"],"creatures":[],"armor":[],"discovered":[],"team":[],"next_instance_nonce":7,"onboarding":profile.onboarding,"support_cards":{},"decks":[],"active_deck_id":"","armor_blueprints":[],"shop":[]}, "voltwig")
	profile.creatures.append(printed.profile.creatures[0]); profile.creatures[-1].bound = false; profile.creatures[-1].tradable = true
	return profile

func render_local_trade() -> void:
	var panel := make_panel(Color("19334de8"), Color("a8edff")); body.add_child(panel.get_parent())
	panel.add_child(label("Guild Trade Table", 25, Color("a8edff")))
	if local_trade == null: local_trade = LocalTradeAuthority.create(GameManager.profile, _guildmate_profile())
	panel.add_child(label("Local demo pairing code: %s" % local_trade.code, 17, Color("fff0a1")))
	panel.add_child(label("Two revision locks, two confirmations, one atomic settlement. The guildmate remains session-only.", 15, Color("dce8f4")))
	if local_trade.settled:
		panel.add_child(label("Settlement receipt", 19, Color("a8e3a5")))
		panel.add_child(label("You received %s for %s. Audit %s. Your profile was updated; the guildmate was not saved." % [_trade_name(GameManager.profile, local_trade.requested_id), _trade_name(local_trade.partner, local_trade.offered_id), str(local_trade.audit.back().code)], 15, Color("dce8f4")))
		body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))
		return
	var yours := local_trade.eligible(local_trade.creator); var theirs := local_trade.eligible(local_trade.partner)
	panel.add_child(label("Your eligible prints", 18, Color("ffd36c")))
	if yours.is_empty(): panel.add_child(label("Print an extra unbound, unequipped copy before local trade.", 15, Color("ffaaa1")))
	for id in yours: panel.add_child(make_button("Offer %s" % _trade_name(local_trade.creator, id), func(): select_trade_choice(0, id), Color("4d7898")))
	panel.add_child(label("Guildmate eligible prints", 18, Color("a8edff")))
	for id in theirs: panel.add_child(make_button("Request %s" % _trade_name(local_trade.partner, id), func(): select_trade_choice(1, id), Color("4d7898")))
	if not local_trade.offered_id.is_empty() and not local_trade.requested_id.is_empty() and not local_trade.settled:
		panel.add_child(label("Escrow draft: %s for %s" % [_trade_name(local_trade.creator, local_trade.offered_id), _trade_name(local_trade.partner, local_trade.requested_id)], 16, Color("fff0a1")))
		panel.add_child(label("Creator: %s  |  Guildmate: %s" % ["Confirmed" if local_trade.creator_confirmed else "Awaiting confirmation", "Confirmed" if local_trade.partner_confirmed else "Awaiting confirmation"], 15, Color("a8e3a5") if local_trade.creator_confirmed and local_trade.partner_confirmed else Color("dce8f4")))
		panel.add_child(make_button("Creator Confirm" if not local_trade.creator_confirmed else "Creator Confirmed", func(): confirm_local_trade(0), Color("a86b2e")))
		panel.add_child(make_button("Guildmate Confirm" if not local_trade.partner_confirmed else "Guildmate Confirmed", func(): confirm_local_trade(1), Color("588d73")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func confirm_local_trade(seat: int) -> void:
	var result := local_trade.confirm(seat, local_trade.creator_revision, local_trade.partner_revision)
	if not bool(result.ok): _toast(str(result.error)); return
	if bool(result.get("settled", false)): GameManager.settle_local_trade(result.creator, result.audit)
	else: render()

func select_trade_choice(seat: int, instance_id: String) -> void:
	if local_trade == null or local_trade.settled: return
	if seat == 0: trade_creator_choice = instance_id
	else: trade_partner_choice = instance_id
	if not trade_creator_choice.is_empty() and not trade_partner_choice.is_empty():
		var draft := local_trade.choose(trade_creator_choice, trade_partner_choice)
		if not bool(draft.ok): _toast(str(draft.error))
	render()

func _trade_name(profile: Dictionary, instance_id: String) -> String:
	for creature in profile.get("creatures", []):
		if str(creature.get("instance_id", "")) == instance_id: return str(Catalog.creature(str(creature.get("creature_id", ""))).get("name", "Printed companion"))
	return "Printed companion"

func render_shop() -> void:
	var intro := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(intro.get_parent())
	intro.add_child(label("Extruder Forge", 25, Color("ffd36c")))
	intro.add_child(label("Offline rotation for %s. Prices are listed by the Forge and repeat deterministically for this day." % shop_day_key, 15, Color("dce8f4")))
	var grid := GridContainer.new(); grid.columns = 3 if size.x >= 900 else 1; body.add_child(grid)
	for offer in GameManager.daily_shop(shop_day_key):
		var card := make_panel(Color("152842e8"), Color("7dd7ef")); grid.add_child(card.get_parent())
		card.add_child(label(str(offer.name), 19, Color("8deaff")))
		card.add_child(label(str(offer.kind).replace("_", " ").capitalize() + " • " + str(offer.price) + " FC", 14, Color("dce8f4")))
		card.add_child(make_button("Acquire", func(): GameManager.buy_shop_offer(shop_day_key, str(offer.offer_id))))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_print_yard() -> void:
	var panel := make_panel(Color("19334de8"), Color("7bcf89")); body.add_child(panel.get_parent())
	panel.add_child(label("Print Yard", 25, Color("a8e3a5")))
	panel.add_child(label("Your printed companions practice one calm filament lesson together each day. This activity is local, deterministic, and cannot be repeated today.", 16, Color("dce8f4")))
	panel.add_child(label("Companions present: %d | Current XP: %d | Spool threshold: %d XP" % [GameManager.profile.creatures.size(), int(GameManager.profile.xp), GameManager.filament_cap() * 100], 15, Color("9beaff")))
	var already := str(GameManager.profile.get("last_yard_day", "")) == shop_day_key
	panel.add_child(make_button("Lesson already shared today" if already else "Share Filament Lesson (+XP)", func():
		var xp := GameManager.visit_print_yard(shop_day_key)
		if xp > 0: _toast("Print Yard lesson complete: +%d XP." % xp), Color("588d73") if not already else Color("536c8d")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_calibration_bench() -> void:
	var panel := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(panel.get_parent())
	var used: int = int(GameManager.profile.daily_job_count) if str(GameManager.profile.last_job_day) == shop_day_key else 0
	panel.add_child(label("Calibration Bench", 25, Color("ffd36c")))
	panel.add_child(label("Tune a fixed 72% pattern for a reliable Forge Coin reward. A fresh day resets the three-pattern limit.", 16, Color("dce8f4")))
	panel.add_child(label("Today: %d / %d patterns complete | Reward at 72%%: 22 Forge Coins" % [used, ProgressionRules.DAILY_CALIBRATION_LIMIT], 15, Color("9beaff")))
	panel.add_child(make_button("Calibration complete for today" if used >= ProgressionRules.DAILY_CALIBRATION_LIMIT else "Run Calibration Pattern", func():
		var reward := GameManager.complete_workshop_job(72, shop_day_key)
		if reward > 0: _toast("Calibration pattern complete: +%d Forge Coins." % reward), Color("a86b2e") if used < ProgressionRules.DAILY_CALIBRATION_LIMIT else Color("536c8d")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_settings() -> void:
	var panel := make_panel(Color("19334de8"), Color("ffd36c")); body.add_child(panel.get_parent())
	var current := settings()
	panel.add_child(label("Workshop Settings", 25, Color("ffd36c")))
	panel.add_child(label("Settings are saved to this profile. Text, contrast, and motion controls never change battle rules.", 15, Color("dce8f4")))
	for scale in AccessibilityRules.TEXT_SCALES:
		panel.add_child(make_button("Text size %d%%" % (int(scale) / 100), func(): GameManager.save_settings({"text_scale_bps":scale}), Color("588d73") if int(current.text_scale_bps) == int(scale) else Color("2f93a8")))
	panel.add_child(make_button("High contrast: %s" % ("On" if bool(current.high_contrast) else "Off"), func(): GameManager.save_settings({"high_contrast":not bool(current.high_contrast)})))
	panel.add_child(make_button("Reduced motion: %s" % ("On" if bool(current.reduced_motion) else "Off"), func(): GameManager.save_settings({"reduced_motion":not bool(current.reduced_motion)})))
	for difficulty in AccessibilityRules.DIFFICULTIES:
		panel.add_child(make_button("Training AI: %s" % difficulty, func(): GameManager.save_settings({"ai_difficulty":difficulty}), Color("588d73") if str(current.ai_difficulty) == difficulty else Color("2f93a8")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func open_printer(creature_id: String) -> void:
	var definition := Catalog.creature(creature_id)
	if definition.is_empty() or creature_id not in GameManager.profile.get("blueprints", []):
		_toast("That blueprint is not learned yet.")
		return
	printer_creature_id = creature_id
	printer_price = int(Catalog.rarity(str(definition.rarity)).print)
	printer_sequence = ArcaneForgeSequence.create(bool(settings().get("reduced_motion", false)))
	printer_tick_accumulator = 0.0
	printer_presentation_seconds = 0.0
	printer_failure = ""
	printer_return_screen = screen
	if screen == "workshop": workshop_return_view = workshop_view
	screen = "printer"
	render()

func render_printer() -> void:
	var definition := Catalog.creature(printer_creature_id)
	if definition.is_empty() or printer_sequence == null:
		screen = "collection"
		render()
		return
	var panel := make_panel(Color("152d49ec"), Color("f1be69"))
	body.add_child(panel.get_parent())
	panel.add_child(label("Arcane Forge", 27, Color("ffd36c")))
	panel.add_child(label("%s blueprint - %s - %d Forge Coins" % [str(definition.name), str(definition.element), printer_price], 16, Color("9beaff")))
	panel.add_child(label("Available Forge Coins: %d. The profile changes only when the raw print completes." % int(GameManager.profile.coins), 15, Color("dce8f4")))
	var stage := ArcaneForgeStage.new()
	stage.configure(printer_creature_id, bool(settings().get("reduced_motion", false)), bool(settings().get("high_contrast", false)))
	stage.set_preview_phase(printer_sequence.phase, printer_sequence.progress_bps, printer_sequence.phase_progress_bps())
	stage.set_presentation_time(printer_presentation_seconds)
	stage.custom_minimum_size = Vector2(0, 540 if size.y > size.x else 330)
	panel.add_child(stage)
	match printer_sequence.phase:
		ArcaneForgeSequence.IDLE:
			panel.add_child(label("Preview the dormant print on the build plate. Begin only when ready.", 16, Color("fff0a1")))
			panel.add_child(make_button("Begin Print (%d FC)" % printer_price, begin_printer, Color("a86b2e")))
			panel.add_child(make_button("Cancel Preview", cancel_printer_preview, Color("536c8d")))
		ArcaneForgeSequence.PRINTING:
			panel.add_child(label("Printing layers: %d%%. The nozzle and reveal are presentation only." % (printer_sequence.layer_reveal_bps() / 100), 16, Color("9beaff")))
			panel.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.RAW_COMPLETE:
			panel.add_child(label("Raw print complete. Securing the Forge transaction...", 16, Color("fff0a1")))
		ArcaneForgeSequence.RAW_HOLD:
			panel.add_child(label("Raw print complete. The Forge record is secure; the dormant form rests for a moment before awakening.", 16, Color("fff0a1")))
			panel.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.AWAKENING:
			panel.add_child(label("Filament awakening in progress. The new print is already safely recorded.", 16, Color("9beaff")))
			panel.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.DEPARTING:
			panel.add_child(label("%s takes its first steps away from the build plate." % str(definition.name), 16, Color("a8e3a5")))
			panel.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.AWAKENED:
			panel.add_child(label("Welcome, %s! Your living print is ready for the Collection." % str(definition.name), 20, Color("a8e3a5")))
			panel.add_child(make_button("Print Another", return_to_printer_picker, Color("a86b2e")))
			panel.add_child(make_button("Return to Printer Bench", return_to_printer_station, Color("536c8d")))
		ArcaneForgeSequence.FAILED:
			panel.add_child(label("The Forge could not complete this print: %s" % printer_failure, 17, Color("ffaaa1")))
			panel.add_child(make_button("Return to Collection", navigate_to.bind("collection"), Color("536c8d")))
		_:
			panel.add_child(label("Preview closed without changing your profile.", 16, Color("dce8f4")))

func begin_printer() -> void:
	if printer_sequence == null or not printer_sequence.begin(): return
	printer_tick_accumulator = 0.0
	printer_presentation_seconds = 0.0
	render()

func advance_printer_for_test(step_bps: int) -> void:
	if printer_sequence == null: return
	printer_sequence.advance(step_bps)
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE: _commit_printer_once()
	render()

func _commit_printer_once() -> void:
	if printer_sequence == null or not printer_sequence.request_commit(): return
	var success := GameManager.print_creature(printer_creature_id)
	if not success: printer_failure = "The blueprint, coins, or inventory no longer passed validation."
	printer_sequence.resolve_commit(success)

func skip_printer() -> void:
	if printer_sequence == null or not printer_sequence.skip(): return
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE: _commit_printer_once()
	render()

func cancel_printer_preview() -> void:
	if printer_sequence != null: printer_sequence.cancel()
	printer_creature_id = ""
	screen = printer_return_screen
	if screen == "workshop": workshop_view = workshop_return_view
	render()

func return_to_printer_station() -> void:
	if printer_return_screen == "workshop":
		screen = "workshop"
		workshop_view = "printer"
		workshop_selected = "printer"
		workshop_drawer_object = ""
		render()
		return
	navigate_to("collection")

func return_to_printer_picker() -> void:
	if printer_return_screen == "workshop":
		printer_picker_open = true
		return_to_printer_station()
		return
	navigate_to("collection")

func render_collection() -> void:
	var intro := make_panel(Color("19334de8"), Color("8deaff")); body.add_child(intro.get_parent())
	intro.add_child(label("Collection & Print Yard", 25, Color("8deaff")))
	intro.add_child(label("%d printed creature instances are safely stored in your workshop. Every learned blueprint can be printed here." % GameManager.profile.creatures.size(), 15, Color("dce8f4")))
	for blueprint_id in GameManager.profile.blueprints:
		var blueprint := Catalog.creature(str(blueprint_id))
		if not blueprint.is_empty():
			var price: int = int(Catalog.rarity(str(blueprint.rarity)).print)
			intro.add_child(make_button("Print %s (%d FC)" % [str(blueprint.name), price], func(): open_printer(str(blueprint.id)), Color("a86b2e")))
	for creature in GameManager.profile.creatures:
		var row := make_panel(Color("152842e8"), Color("5e99b4")); body.add_child(row.get_parent())
		row.add_child(label("%s  •  %s%s" % [str(Catalog.creature(str(creature.creature_id)).name), "Bound" if bool(creature.get("bound", false)) else "Printed", "  • Armor: %s" % str(creature.armor_id) if not str(creature.get("armor_id", "")).is_empty() else ""], 16, Color("dce8f4")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_team() -> void:
	var intro := make_panel(Color("19334de8"), Color("8deaff")); body.add_child(intro.get_parent())
	intro.add_child(label("Three-Slot Team Builder", 25, Color("8deaff")))
	if team_draft.is_empty(): team_draft = Array(GameManager.profile.team)
	intro.add_child(label("Draft training team: %d / 3. Every selected print is unique; a team needs one to three companions." % team_draft.size(), 15, Color("dce8f4")))
	for creature in GameManager.profile.creatures:
		var instance_id := str(creature.instance_id)
		var selected: bool = instance_id in team_draft
		intro.add_child(make_button(("Remove " if selected else "Add ") + str(Catalog.creature(str(creature.creature_id)).name), func():
			if selected:
				if team_draft.size() > 1: team_draft.erase(instance_id)
				else: _toast("A training team needs at least one companion.")
			elif team_draft.size() < 3:
				team_draft.append(instance_id)
			else: _toast("A team can hold only three companions.")
			render(), Color("588d73") if selected else Color("2f93a8")))
	intro.add_child(make_button("Save Team", func(): GameManager.save_team(team_draft), Color("a86b2e")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_armor_legacy() -> void:
	var intro := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(intro.get_parent())
	intro.add_child(label("Armor Workbench", 25, Color("ffd36c")))
	for armor in Catalog.ARMOR:
		var known: bool = armor.id in GameManager.profile.armor_blueprints
		intro.add_child(make_button(("Print " if known else "Learn ") + str(armor.name) + " (%d FC)" % int(armor.print if known else armor.blueprint), func():
			if known: GameManager.print_armor(str(armor.id))
			else: GameManager.learn_armor_blueprint(str(armor.id))))
	for armor_instance in GameManager.profile.armor:
		if str(armor_instance.equipped_to).is_empty():
			for creature in GameManager.profile.creatures:
				var target_id := str(creature.instance_id)
				var armor_instance_id := str(armor_instance.armor_instance_id)
				intro.add_child(make_button("Equip %s to %s" % [str(armor_instance.armor_id), str(Catalog.creature(str(creature.creature_id)).name)], func(): GameManager.equip_armor(target_id, armor_instance_id), Color("588d73")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_armor() -> void:
	var panel := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(panel.get_parent())
	panel.add_child(label("Armor Workbench", 25, Color("ffd36c")))
	panel.add_child(label("Each print wears at most one armor piece. Move or remove an equipped piece without losing either item.", 15, Color("dce8f4")))
	for definition in Catalog.ARMOR:
		var known: bool = definition.id in GameManager.profile.armor_blueprints
		panel.add_child(make_button(("Print " if known else "Learn ") + str(definition.name) + " (%d FC)" % int(definition.print if known else definition.blueprint), func():
			if known: GameManager.print_armor(str(definition.id))
			else: GameManager.learn_armor_blueprint(str(definition.id))))
	for creature in GameManager.profile.creatures:
		var creature_id := str(creature.instance_id); var creature_name := str(Catalog.creature(str(creature.creature_id)).name); var equipped := str(creature.get("armor_id", ""))
		panel.add_child(label("%s: %s" % [creature_name, "Unarmored" if equipped.is_empty() else equipped.replace("_", " ").capitalize()], 15, Color("a8e3a5") if not equipped.is_empty() else Color("dce8f4")))
		if not equipped.is_empty(): panel.add_child(make_button("Unequip from %s" % creature_name, func(): GameManager.unequip_armor(creature_id), Color("536c8d")))
	for armor_instance in GameManager.profile.armor:
		var armor_id := str(armor_instance.armor_instance_id); var armor_name := str(armor_instance.armor_id).replace("_", " ").capitalize()
		for creature in GameManager.profile.creatures:
			var target_id := str(creature.instance_id); var target_name := str(Catalog.creature(str(creature.creature_id)).name)
			var moving := not str(armor_instance.get("equipped_to", "")).is_empty()
			panel.add_child(make_button(("Move " if moving else "Equip ") + armor_name + " to " + target_name, func():
				if moving: GameManager.reassign_armor(target_id, armor_id)
				else: GameManager.equip_armor(target_id, armor_id), Color("588d73")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_deck_legacy() -> void:
	var intro := make_panel(Color("19334de8"), Color("b88bff")); body.add_child(intro.get_parent())
	if deck_draft.is_empty(): deck_draft = GameManager.active_deck_cards()
	var active := GameManager.active_deck_cards()
	intro.add_child(label("15-Card Deck Builder", 25, Color("d3a7ff")))
	intro.add_child(label("Draft deck: %d / 15 cards. Owned counts are checked before the Forge saves it." % deck_draft.size(), 15, Color("dce8f4")))
	for card in Catalog.SUPPORT_CARDS:
		var owned: int = int(GameManager.profile.support_cards.get(str(card.id), 0))
		if owned > 0: intro.add_child(label("%s — owned %d, active %d" % [str(card.name), owned, active.count(card.id)], 14, Color("dce8f4")))
	if active.size() == 15: intro.add_child(make_button("Save Active Deck", func(): GameManager.save_deck(active), Color("588d73")))
	for card in Catalog.SUPPORT_CARDS:
		var owned_draft: int = int(GameManager.profile.support_cards.get(str(card.id), 0))
		if owned_draft > 0:
			var card_id := str(card.id)
			var copies: int = deck_draft.count(card_id)
			var row := HBoxContainer.new(); intro.add_child(row)
			var details := label("%s: owned %d, draft %d" % [str(card.name), owned_draft, copies], 14, Color("dce8f4")); details.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(details)
			var remove := Button.new(); remove.text = "-"; remove.disabled = copies == 0; row.add_child(remove)
			remove.pressed.connect(func(): deck_draft.erase(card_id); render())
			var add := Button.new(); add.text = "+"; add.disabled = copies >= owned_draft or deck_draft.size() >= 15; row.add_child(add)
			add.pressed.connect(func(): deck_draft.append(card_id); render())
	if deck_draft.size() == 15:
		intro.add_child(make_button("Save Draft as Active Deck", func(): GameManager.save_deck(deck_draft), Color("588d73")))
	else:
		intro.add_child(label("Add %d more cards to make a legal 15-card deck." % [15 - deck_draft.size()], 14, Color("fff0a1")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_deck() -> void:
	var panel := make_panel(Color("19334de8"), Color("b88bff")); body.add_child(panel.get_parent())
	if deck_slot_id.is_empty(): deck_slot_id = str(GameManager.profile.get("active_deck_id", ProgressionRules.STARTER_DECK_ID))
	if deck_draft.is_empty(): deck_draft = GameManager.active_deck_cards()
	panel.add_child(label("15-Card Deck Builder", 25, Color("d3a7ff")))
	panel.add_child(label("Selected slot: %s | Draft: %d / 15. Only owned support cards can be saved." % [str(ProgressionRules.DECK_SLOT_NAMES.get(deck_slot_id, "Forge Deck")), deck_draft.size()], 15, Color("dce8f4")))
	for slot_id in ProgressionRules.DECK_SLOT_IDS:
		var saved_cards: Array = []
		for saved in GameManager.profile.get("decks", []):
			if str(saved.get("id", "")) == slot_id: saved_cards = saved.get("cards", []).duplicate()
		var action := "Active" if str(GameManager.profile.active_deck_id) == slot_id else "Select"
		panel.add_child(make_button("%s: %d cards - %s" % [str(ProgressionRules.DECK_SLOT_NAMES[slot_id]), saved_cards.size(), action], func():
			deck_slot_id = slot_id
			deck_draft = saved_cards.duplicate() if not saved_cards.is_empty() else GameManager.active_deck_cards()
			if not saved_cards.is_empty(): GameManager.select_deck(slot_id)
			render(), Color("588d73") if str(GameManager.profile.active_deck_id) == slot_id else Color("526e93")))
	for card in Catalog.SUPPORT_CARDS:
		var card_id := str(card.id); var owned: int = int(GameManager.profile.support_cards.get(card_id, 0)); var copies: int = deck_draft.count(card_id)
		if owned <= 0: continue
		var row := HBoxContainer.new(); panel.add_child(row)
		var info := label("%s | owned %d | slot %d" % [str(card.name), owned, copies], 14, Color("dce8f4")); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(info)
		row.add_child(make_button("-", func(): deck_draft.erase(card_id); render(), Color("536c8d")))
		row.add_child(make_button("+", func(): if deck_draft.size() < 15 and deck_draft.count(card_id) < owned: deck_draft.append(card_id); render(), Color("2f93a8")))
	panel.add_child(make_button("Save %s as active (%d / 15)" % [str(ProgressionRules.DECK_SLOT_NAMES.get(deck_slot_id, "Forge Deck")), deck_draft.size()], func(): GameManager.save_deck_slot(deck_draft, deck_slot_id), Color("a86b2e")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_codex() -> void:
	var intro := make_panel(Color("19334de8"), Color("b88bff")); body.add_child(intro.get_parent())
	intro.add_child(label("Forgedex", 25, Color("d3a7ff")))
	intro.add_child(label("%d blueprints have been discovered." % GameManager.profile.discovered.size(), 15, Color("dce8f4")))
	var grid := GridContainer.new(); grid.columns = 4 if size.x >= 1100 else 2; body.add_child(grid)
	for creature in Catalog.CREATURES:
		var known: bool = creature.id in GameManager.profile.discovered
		var card := make_panel(Color("152842e8"), Color(Catalog.rarity(creature.rarity).color if known else "4b5d72")); grid.add_child(card.get_parent())
		card.add_child(label(str(creature.name) if known else "???", 17, Color(Catalog.rarity(creature.rarity).color if known else "8492a1")))
		card.add_child(label("%s • %d bends" % [creature.element, int(creature.bend)] if known else "Undiscovered", 13, Color("dce8f4")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func start_battle() -> void:
	var player_team := GameManager.current_team_loadout()
	if player_team.is_empty():
		_toast("Choose a starter before entering the Proving Grounds.")
		return
	# Training begins with the currently selected/available team; one print is valid.
	var rival_team := GameManager.training_opponent(shop_day_key)
	battle = BattleState.create(player_team, rival_team, GameManager.filament_cap(), 3, _training_seed(shop_day_key), GameManager.active_deck_cards())
	battle_last_event = ""
	battle_last_actor = 0
	battle_concede_armed = false
	battle_secondary_open = false
	battle_secondary_tab = "bench"
	if screen == "workshop": workshop_return_view = workshop_view
	screen = "battle"
	render()

func _training_seed(day_key: String) -> int:
	var seed := 0
	for byte in day_key.to_utf8_buffer(): seed = (seed * 31 + int(byte)) % 2147483647
	return seed

func render_battle() -> void:
	# Kept as the screen entry point for callers/tests; render() installs the
	# explicit full-height battle composition above the generic scroll shell.
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	render_battle_fullscreen(root)

func render_battle_fullscreen(host: Container) -> void:
	var frame := PanelContainer.new()
	frame.name = "BattleFullscreenPanel"
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.custom_minimum_size = Vector2(0, 420)
	frame.add_theme_stylebox_override("panel", panel_style(Color("19334de8"), Color("f1be69")))
	host.add_child(frame)
	var intro := VBoxContainer.new()
	intro.name = "BattleFullscreenContent"
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intro.add_theme_constant_override("separation", 8)
	frame.add_child(intro)
	status = label("", 14, Color("fff0a1"))
	status.name = "BattleStatus"
	intro.add_child(status)
	intro.add_child(label("Proving Grounds - %s" % ("Your turn" if battle.active_player == 0 else "Rival is thinking"), 22, Color("ffd36c")))
	var stage := BattleSpriteStage.new()
	stage.name = "BattleStage"
	stage.configure(battle.active_unit(0), battle.active_unit(1), battle_last_event, battle_last_actor, bool(settings().get("reduced_motion", false)))
	var compact_secondary := battle_secondary_open and not is_portrait_layout()
	stage.custom_minimum_size = Vector2(0, 188 if is_portrait_layout() else (96 if compact_secondary else 172))
	stage.size_flags_vertical = Control.SIZE_FILL if compact_secondary else Control.SIZE_EXPAND_FILL
	intro.add_child(stage)
	if battle.active_player == 0 and not battle.finished:
		render_battle_action_dock(intro)
		render_battle_secondary(intro)
	if battle.finished:
		intro.add_child(label("%s - Core Printer status resolved." % ("Victory!" if battle.winner == 0 else "Defeat."), 22, Color("ffd36c")))
		intro.add_child(make_button("Return to Workshop", func(): GameManager.claim_battle_reward(battle); screen="workshop"; render()))
		return
	# Portrait has room for the always-visible status summary. On compact
	# landscape, let the presentation use that room so the first fold remains
	# entirely actionable; Details retains the full verbose readout.
	if not battle_secondary_open and is_portrait_layout():
		render_battle_summary(intro)
	if battle.active_player == 1 and not battle.finished and not ai_pending:
		ai_pending = true
		call_deferred("run_ai" if bool(settings().get("reduced_motion", false)) else "run_ai_after_presentation")

func render_battle_summary(host: Container) -> void:
	var summary := make_panel(Color("10273ad8"), Color("517b9a"))
	summary.name = "BattleSummary"
	var panel := summary.get_parent() as PanelContainer
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 142)
	host.add_child(panel)
	for player in [1, 0]:
		var unit := battle.active_unit(player)
		var armor_id := str(unit.get("armor_id", ""))
		var base_hp: int = int(Catalog.creature(str(unit.id)).get("hp", unit.max_hp))
		summary.add_child(label(("Rival" if player == 1 else "You") + ": " + str(unit.name) + "  %d/%d HP - %s" % [int(unit.hp), int(unit.max_hp), str(unit.element)], 16, Color("ffaaa1") if player == 1 else Color("a9ecff")))
		summary.add_child(label("Armor: None" if armor_id.is_empty() else "Armor: %s | +%d maximum HP | %d guard" % [str(unit.get("armor_name", "Unarmored")), int(unit.max_hp) - base_hp, int(unit.get("armor", 0))], 13, Color("f1be69")))
		summary.add_child(label("Filament %d/%d | Attack %d | %s (%d; cd %d)" % [int(battle.players[player].filament), int(battle.players[player].spool_cap), int(unit.attack), str(unit.ability), int(unit.ability_cost), int(unit.cooldown_remaining)], 13, Color("d9e7f3")))
	summary.add_child(label("Battle log: " + " | ".join(battle.log.slice(maxi(0, battle.log.size()-3))), 13, Color("d0dfeb")))

func render_battle_action_dock(host: Container) -> void:
	var dock := make_panel(Color("214969ee"), Color("6de4ff"))
	dock.name = "BattleActionDock"
	var dock_panel := dock.get_parent() as PanelContainer
	dock_panel.custom_minimum_size = Vector2(0, 182 if is_portrait_layout() else 116)
	dock_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(dock_panel)
	dock.add_child(label("Moves", 18, Color("d7f8ff")))
	var actions := GridContainer.new()
	actions.name = "BattleActionGrid"
	actions.columns = 2 if is_portrait_layout() else 4
	actions.custom_minimum_size = Vector2(0, 104 if is_portrait_layout() else 48)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	dock.add_child(actions)
	var unit: Dictionary = battle.active_unit(0)
	var basic := make_button("Basic Attack (%d)" % int(unit.attack), func(): intent({"type":"attack"}))
	basic.name = "BattleActionBasicAttack"
	basic.custom_minimum_size.y = 48
	actions.add_child(basic)
	var ability := make_button("%s (%d FC)" % [str(unit.ability), int(unit.ability_cost)], func(): intent({"type":"ability"}))
	ability.name = "BattleActionSignatureAbility"
	ability.custom_minimum_size.y = 48
	ability.disabled = int(unit.cooldown_remaining) > 0 or int(battle.players[0].filament) < int(unit.ability_cost)
	actions.add_child(ability)
	var defend := make_button("Defend", func(): intent({"type":"defend"}), Color("526e93"))
	defend.name = "BattleActionDefend"
	defend.custom_minimum_size.y = 48
	actions.add_child(defend)
	var end_turn := make_button("End Turn", func(): intent({"type":"end_turn"}), Color("536c8d"))
	end_turn.name = "BattleActionEndTurn"
	end_turn.custom_minimum_size.y = 48
	actions.add_child(end_turn)
	var secondary := make_button("Hide Bench, Hand & Details" if battle_secondary_open else "Bench, Hand & Details", toggle_battle_secondary, Color("536c8d"))
	secondary.name = "BattleSecondaryToggle"
	secondary.custom_minimum_size = Vector2(0, 48)
	dock.add_child(secondary)

func render_battle_secondary(host: Container) -> void:
	if not battle_secondary_open:
		return
	var panel := make_panel(Color("172e43ee"), Color("7bcbe5"))
	panel.name = "BattleSecondaryPanel"
	var secondary_panel := panel.get_parent() as PanelContainer
	secondary_panel.custom_minimum_size = Vector2(0, 160)
	secondary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(secondary_panel)
	panel.add_child(label("Tactics", 16, Color("9beaff")))
	var tabs := GridContainer.new()
	tabs.name = "BattleSecondaryTabs"
	tabs.columns = 2 if is_portrait_layout() else 4
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 8)
	panel.add_child(tabs)
	for tab_data in [["bench", "Bench", "BattleSecondaryBenchTab"], ["hand", "Hand", "BattleSecondaryHandTab"], ["details", "Details", "BattleSecondaryDetailsTab"], ["concede", "Concede", "BattleSecondaryConcedeTab"]]:
		var tab_id := str(tab_data[0])
		var tab_button := make_button(str(tab_data[1]), set_battle_secondary_tab.bind(tab_id), Color("2f93a8") if battle_secondary_tab == tab_id else Color("536c8d"))
		tab_button.name = str(tab_data[2])
		tabs.add_child(tab_button)
	if battle_secondary_tab == "bench":
		render_battle_bench_tab(panel)
	elif battle_secondary_tab == "hand":
		render_battle_hand_tab(panel)
	elif battle_secondary_tab == "details":
		render_battle_details_tab(panel)
	else:
		render_battle_concede_tab(panel)

func render_battle_bench_tab(panel: Container) -> void:
	panel.add_child(label("Bench", 16, Color("9beaff")))
	var switches := GridContainer.new()
	switches.name = "BattleBenchGrid"
	switches.columns = 2 if is_portrait_layout() else 3
	switches.add_theme_constant_override("h_separation", 8)
	switches.add_theme_constant_override("v_separation", 8)
	panel.add_child(switches)
	var switch_count := 0
	for bench_index in battle.players[0].team.size():
		if bench_index == int(battle.players[0].active):
			continue
		var bench_unit: Dictionary = battle.players[0].team[bench_index]
		if int(bench_unit.hp) > 0:
			var switch_button := make_button("Switch %s" % str(bench_unit.name), func(): intent({"type":"switch","index":bench_index}))
			switch_button.name = "BattleSwitch%s" % str(bench_unit.id)
			switches.add_child(switch_button)
			switch_count += 1
	if switch_count == 0:
		switches.add_child(label("No healthy bench prints.", 14, Color("b9cad7")))

func render_battle_hand_tab(panel: Container) -> void:
	panel.add_child(label("Hand", 16, Color("9beaff")))
	var cards := GridContainer.new()
	cards.name = "BattleHandGrid"
	cards.columns = 2 if is_portrait_layout() else 4
	cards.add_theme_constant_override("h_separation", 8)
	cards.add_theme_constant_override("v_separation", 8)
	panel.add_child(cards)
	for card_id in battle.players[0].hand:
		var card := make_button(str(card_id).replace("_", " ").capitalize(), func(): intent({"type":"card","card_id":card_id}), Color("526e93"))
		card.name = "BattleCard%s" % str(card_id).capitalize()
		cards.add_child(card)

func render_battle_details_tab(panel: Container) -> void:
	for player in [1, 0]:
		var unit := battle.active_unit(player)
		var armor_id := str(unit.get("armor_id", ""))
		var base_hp: int = int(Catalog.creature(str(unit.id)).get("hp", unit.max_hp))
		panel.add_child(label(("Rival" if player == 1 else "You") + ": " + str(unit.name) + "  %d/%d HP - %s" % [int(unit.hp), int(unit.max_hp), str(unit.element)], 15, Color("ffaaa1") if player == 1 else Color("a9ecff")))
		panel.add_child(label("Armor: None" if armor_id.is_empty() else "Armor: %s | +%d maximum HP | %d guard" % [str(unit.get("armor_name", "Unarmored")), int(unit.max_hp) - base_hp, int(unit.get("armor", 0))], 13, Color("f1be69")))
		panel.add_child(label("Filament %d/%d | Attack %d | %s (%d; cd %d)" % [int(battle.players[player].filament), int(battle.players[player].spool_cap), int(unit.attack), str(unit.ability), int(unit.ability_cost), int(unit.cooldown_remaining)], 13, Color("d9e7f3")))
	panel.add_child(label("Battle log\n" + "\n".join(battle.log.slice(maxi(0, battle.log.size()-4))), 13, Color("d0dfeb")))

func render_battle_concede_tab(panel: Container) -> void:
	var concede_row := HBoxContainer.new()
	concede_row.add_theme_constant_override("separation", 8)
	panel.add_child(concede_row)
	if battle_concede_armed:
		var confirm := make_button("Confirm Concede", toggle_battle_concede, Color("9a5b6f"))
		confirm.name = "BattleActionConfirmConcede"
		concede_row.add_child(confirm)
		var cancel := make_button("Cancel Concede", cancel_battle_concede, Color("536c8d"))
		cancel.name = "BattleActionCancelConcede"
		concede_row.add_child(cancel)
	else:
		var concede := make_button("Concede", toggle_battle_concede, Color("9a5b6f"))
		concede.name = "BattleActionConcede"
		concede_row.add_child(concede)

func toggle_battle_secondary() -> void:
	battle_secondary_open = not battle_secondary_open
	if battle_secondary_open:
		battle_secondary_tab = "bench"
	render()

func set_battle_secondary_tab(tab_id: String) -> void:
	battle_secondary_open = true
	battle_secondary_tab = tab_id
	render()

func intent(action: Dictionary) -> void:
	if str(action.get("type", "")) != "concede": battle_concede_armed = false
	var result := BattleRules.apply_intent(battle, 0, action)
	if not result.ok: _toast(str(result.error))
	else:
		battle_concede_armed = false
		battle_last_event = str(action.get("type", ""))
		battle_last_actor = 0
		render()

func toggle_battle_concede() -> void:
	if battle == null or battle.finished: return
	if not battle_concede_armed:
		battle_concede_armed = true
		_toast("Press Confirm Concede to end this training match.")
		render()
		return
	intent({"type":"concede"})

func cancel_battle_concede() -> void:
	if not battle_concede_armed: return
	battle_concede_armed = false
	_toast("Concede cancelled.")
	render()

func run_ai_after_presentation() -> void:
	await get_tree().create_timer(0.5).timeout
	ai_pending = false
	if battle and battle.active_player == 1 and not battle.finished: run_ai()

func run_ai() -> void:
	ai_pending = false
	if battle.active_player != 1 or battle.finished: return
	var applied := AIOpponent.choose_intent(battle, str(settings().get("ai_difficulty", "Craftsman")))
	var result := BattleRules.apply_intent(battle, 1, applied)
	if not result.ok and battle.active_player == 1 and not battle.finished:
		applied = {"type":"defend"}
		result = BattleRules.apply_intent(battle, 1, applied)
	if not result.ok and battle.active_player == 1 and not battle.finished:
		applied = {"type":"end_turn"}
		result = BattleRules.apply_intent(battle, 1, applied)
	if result.ok:
		battle_last_event = str(applied.type)
		battle_last_actor = 1
	render()

func _toast(message: String) -> void:
	if status: status.text = message
