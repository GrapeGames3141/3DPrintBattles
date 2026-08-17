extends Control

## Reference-driven workshop presentation; final character art remains approval-gated.
const REFERENCE_TEXTURE := preload("res://docs/art/reference/workshop-theme-reference.jpg")
const WORKSHOP_OVERVIEW_LANDSCAPE_TEXTURE := preload("res://assets/ui/workshop/workshop_overview_landscape_v3.png")
const WORKSHOP_OVERVIEW_PORTRAIT_TEXTURE := preload("res://assets/ui/workshop/workshop_overview_portrait_v3.png")
const WORKSHOP_AMBIENT_LAYER := preload("res://scripts/ui/workshop_ambient_layer.gd")
const WORKSHOP_HOTSPOT_OVERLAY := preload("res://scripts/ui/workshop_hotspot_overlay.gd")
const WORKSHOP_PAN_AFFORDANCE := preload("res://scripts/ui/workshop_pan_affordance.gd")
const SUPPORT_CARD_PRESENTER := preload("res://scripts/ui/support_card_presenter.gd")
const SUPPORT_CARD_VIEW := preload("res://scripts/ui/support_card_view.gd")
const BATTLE_FEEDBACK_PRESENTER := preload("res://scripts/ui/battle_feedback_presenter.gd")
const TOUCH_SCROLL_CONTAINER := preload("res://scripts/ui/touch_scroll_container.gd")
const EQUIPMENT_WORKBENCH_VIEW := preload("res://scripts/ui/equipment_workbench_view.gd")
const REVIEW_BUILD_LABEL := "0.5.25-alpha-landscape-card-art"
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
var deck_selected_card_id := ""
var deck_slot_id := ProgressionRules.STARTER_DECK_ID
var card_archive_owned_only := false
var card_archive_detail_id := ""
var battle: BattleState
var body: VBoxContainer
var status: Label
var battle_last_event := ""
var battle_last_actor := 0
var battle_presentation_serial := 0
var ai_pending := false
var battle_session_generation := 0
var battle_concede_armed := false
var battle_secondary_open := false
var battle_secondary_tab := "bench"
var battle_mode := "training"
var trial_encounter_id := ""
var battle_ai_difficulty := "Craftsman"
var battle_launch_notice := ""
var local_concede_armed := false
var local_authority: LocalBattleAuthority
var local_ready_seat := -1
var local_trade: LocalTradeAuthority
var trade_creator_choice := ""
var trade_partner_choice := ""
var printer_sequence: ArcaneForgeSequence
var printer_creature_id := ""
var printer_armor_id := ""
var printer_is_armor := false
var printer_is_core := false
var equipment_selected_creature_id := ""
var equipment_mode := "suits"
var equipment_selected_id := "standard"
var printer_price := 0
var printer_tick_accumulator := 0.0
var printer_presentation_seconds := 0.0
var printer_capture_freeze := false
var printer_failure := ""
var printer_return_screen := "collection"
var printer_progress_label: Label
var team_draft_dirty := false
var calibration_values: Array[int] = [50, 50, 50]
var calibration_step := 0
var _focus_after_render := true
var workshop_ambient_capture_freeze := false
var workshop_station_live_capture_progress := -1
var workshop_station_live_capture_seed := 17
var overview_layout_portrait := false
var _workshop_screen_component := WorkshopScreenComponent.new()
var _battle_screen_component := BattleScreenComponent.new()
var _forge_screen_component := ArcaneForgeScreenComponent.new()
var _audio_director := AudioDirector.new()

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
	add_child(_audio_director)
	_audio_director.configure(settings(), false)
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
	var phase_before := printer_sequence.phase
	printer_sequence.advance(ArcaneForgeSequence.presentation_step_bps(printer_sequence.reduced_motion, phase_before))
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE:
		_commit_printer_once()
		render()
	elif printer_sequence.phase != phase_before:
		# A phase change changes controls/status hierarchy, so rebuild the shell.
		render()
	else:
		# Same-phase progress is visual-only. Keep the surrounding shell and the
		# persistent compositor alive while updating their presentation in place.
		_refresh_printer_presentation()

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
	_focus_after_render = true
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
		if child == _audio_director: continue
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
	button.gui_input.connect(func(event: InputEvent):
		if (event is InputEventKey or event is InputEventJoypadButton) and event.pressed:
			_focus_after_render = true)
	button.pressed.connect(func():
		_audio_director.cue("press")
		callback.call())
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
	_audio_director.configure(settings(), printer_capture_freeze or workshop_ambient_capture_freeze)
	_audio_director.route("battle" if screen in ["battle", "local_vs"] else ("forge" if screen == "printer" else "workshop"))
	_detach_persistent_screen_components()
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
	if GameManager.is_save_read_only():
		render_save_recovery(root)
		return
	# Battle is a first-fold activity, not a list below a generic scrolling shell.
	# Give it the remaining safe content area directly so mobile layout cannot
	# collapse action rows to zero height before the scroll container settles.
	if screen == "battle":
		render_battle_fullscreen(root)
		if _focus_after_render:
			_focus_after_render = false
			call_deferred("focus_first_button")
		return
	var scroll := TOUCH_SCROLL_CONTAINER.new()
	scroll.name = "TouchFirstScroll"
	scroll.custom_minimum_size = Vector2(0, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	if bool(get_meta("capture_scroll_trials", false)) and screen == "trials":
		call_deferred("_capture_scroll_trials", scroll)
	status = label("", 15, Color("fff0a1"))
	body.add_child(status)
	match screen:
		"onboarding": render_onboarding()
		"shop": render_shop()
		"codex": render_codex()
		"collection": render_collection()
		"team": render_team()
		"armor": render_armor()
		"deck": render_deck()
		"archive": render_card_archive()
		"yard": render_print_yard()
		"calibration": render_calibration_bench()
		"printer": render_printer()
		"settings": render_settings()
		"proving": render_proving_door()
		"trials": render_trials()
		"local_vs": render_local_vs()
		"trade": render_local_trade()
		_: render_workshop()
	if _focus_after_render:
		_focus_after_render = false
		call_deferred("focus_first_button")

func _detach_persistent_screen_components() -> void:
	# Main's shell is intentionally rebuilt for responsive text/contrast. Detach
	# expensive presentation nodes first so their imported textures and animation
	# state survive the ancestor queue_free operation.
	_battle_screen_component.detach()
	_forge_screen_component.detach()
	_workshop_screen_component.detach()

func focus_first_button() -> void:
	for node in find_children("*", "Button", true, false):
		var button := node as Button
		if button and button.is_visible_in_tree() and button.disabled == false:
			button.grab_focus()
			return

func _capture_scroll_trials(scroll: ScrollContainer) -> void:
	if is_instance_valid(scroll): scroll.scroll_vertical = 260

func render_save_recovery(root: VBoxContainer) -> void:
	var panel := make_panel(Color("2f1f2be8"), Color("ffaaa1"))
	root.add_child(panel.get_parent())
	panel.add_child(label("Save opened read-only", 25, Color("ffcfbf")))
	panel.add_child(label(GameManager.save_recovery_message(), 17, Color("fff3df")))
	panel.add_child(label("Install the newer build that created this save, or copy the profile and backup files before trying an older build. This session has not changed your local save.", 15, Color("dce8f4")))
	panel.add_child(label("No workshop, battle, or purchase actions are available while compatibility is blocked.", 14, Color("b9d3e8")))

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
	if GameManager.is_save_read_only():
		var compatibility := label("READ-ONLY COMPATIBILITY MODE\nSave schema is newer than this build", 15, Color("ffcfbf"))
		compatibility.name = "ReadOnlyCompatibilityHeader"
		compatibility.custom_minimum_size = Vector2(0 if portrait else 250, 40 if portrait else 58)
		compatibility.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
		compatibility.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
		compatibility.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(compatibility)
	elif GameManager.has_selected_starter():
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
		card.add_child(label(Catalog.signature_description(str(creature.id)), 13, Color("b9d3e8")))
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
		{"id":"maker", "name":"Maker Bench", "callout":"Team, decks, equipment, calibration", "description":"Shape your active team and every field-ready loadout.", "rect":Rect2(0.03, 0.68, 0.31, 0.26), "objects":[{"id":"team_board", "name":"Team Board", "description":"Set one to three printed companions as your active team.", "target":"team", "rect":Rect2(0.02, 0.47, 0.27, 0.28)}, {"id":"deck_blueprints", "name":"Deck Blueprint Rack", "description":"Choose and name a legal fifteen-card support deck.", "target":"deck", "rect":Rect2(0.38, 0.26, 0.24, 0.40)}, {"id":"card_archive", "name":"Support Card Archive", "description":"Browse card art, rules, targets and owned copies.", "target":"archive", "rect":Rect2(0.26, 0.52, 0.28, 0.18)}, {"id":"armor_tools", "name":"Equipment Workbench", "description":"Learn, print, fit, socket, remove, and move full suits and Cores.", "target":"armor", "rect":Rect2(0.58, 0.15, 0.24, 0.55)}, {"id":"calibration_dial", "name":"Calibration Dial", "description":"Run today's finite calibration pattern for a measured reward.", "target":"calibration", "rect":Rect2(0.80, 0.40, 0.16, 0.32)}]},
		{"id":"terminal", "name":"Forge Terminal", "callout":"Offers, Forgedex, Guild Trade", "description":"Browse fixed daily offers, records, and a local kid-safe trade demo.", "rect":Rect2(0.65, 0.30, 0.23, 0.34), "objects":[{"id":"offer_screen", "name":"Forge Offers", "description":"Review today's deterministic blueprint, card, and armor offers.", "target":"shop", "rect":Rect2(0.57, 0.35, 0.10, 0.29)}, {"id":"forgedex_screen", "name":"Forgedex Terminal", "description":"Track every discovered creature blueprint.", "target":"codex", "rect":Rect2(0.67, 0.35, 0.11, 0.29)}, {"id":"trade_terminal", "name":"Guild Trade Table", "description":"Open a credential-free two-profile escrow demonstration.", "target":"trade", "rect":Rect2(0.78, 0.35, 0.12, 0.29)}]},
		{"id":"proving", "name":"Proving Door", "callout":"Daily Training, Trials, Local Versus", "description":"Step through the center door for daily training, ordered Workshop Trials, or a private hot-seat match.", "rect":Rect2(0.45, 0.18, 0.20, 0.50), "objects":[{"id":"training_door", "name":"Proving Door", "description":"Choose a repeatable daily rival or an ordered Workshop Trial with fixed first-clear rewards.", "target":"proving", "rect":Rect2(0.42, 0.39, 0.23, 0.27)}, {"id":"versus_marker", "name":"Local Versus", "description":"Pass the device between two private players. No rewards are granted.", "target":"local_vs", "rect":Rect2(0.48, 0.64, 0.16, 0.17)}]},
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
	_workshop_screen_component.refresh(GameManager.profile, workshop_view, is_portrait_layout(), bool(settings().get("reduced_motion", false)), bool(settings().get("high_contrast", false)), workshop_station_live_capture_seed, workshop_station_live_capture_progress >= 0 or workshop_ambient_capture_freeze, workshop_station_live_capture_progress)
	_workshop_screen_component.attach(art_plane)

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
	var names := {"printer":"Open Arcane Forge", "collection":"Open Collection", "team":"Edit Team", "deck":"Edit Deck Slots", "archive":"Open Support Card Archive", "armor":"Open Equipment Workbench", "calibration":"Run Calibration", "shop":"Open Forge Offers", "codex":"Open Forgedex", "trade":"Open Guild Trade", "proving":"Open Proving Door", "trials":"Open Workshop Trials", "local_vs":"Start Local Versus", "yard":"Visit Print Yard"}
	return str(names.get(target, "Open Station"))

func open_workshop_view(view_id: String) -> void:
	# This is intentional station navigation, unlike a touch-driven draft refresh.
	# Restore a deterministic keyboard/controller target for the new location.
	_focus_after_render = true
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
		{"id":"maker","name":"Maker Bench","description":"Shape the active team, named deck slots, full-suit/Core loadouts, and daily calibration patterns at one maker table.","actions":[{"label":"Edit Team","target":"team"},{"label":"Edit Deck Slots","target":"deck"},{"label":"Open Equipment Workbench","target":"armor"},{"label":"Run Calibration","target":"calibration"}],"rect":Rect2(0.27,0.68,0.25,0.17)},
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
		"collection", "shop", "codex", "team", "deck", "archive", "armor", "settings": navigate_to(id)
		"proving": navigate_to("proving")
		"trials": navigate_to("trials")
		"local_vs": start_local_vs()
		"trade": local_trade = null; trade_creator_choice = ""; trade_partner_choice = ""; navigate_to("trade")
		"yard", "calibration": navigate_to(id)

func start_local_vs() -> void:
	var team := GameManager.current_team_loadout()
	if team.is_empty(): _toast("Choose a starter before starting local versus."); return
	local_authority = LocalBattleAuthority.create(team, ["mossmunk", "voltwig"], GameManager.active_deck_cards(), 20260814)
	var setup_error := local_authority.state.validation_error(true)
	if not setup_error.is_empty():
		local_authority = null
		_toast(setup_error)
		return
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
	var setup_error := state.validation_error(false)
	if not setup_error.is_empty():
		panel.add_child(label("This local match cannot continue: " + setup_error, 16, Color("ffaaa1")))
		panel.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d"))); return
	panel.add_child(label("Authority revision %d  |  Match seed %d  |  No rewards in local versus" % [local_authority.revision, state.seed], 15, Color("9beaff")))
	var seat := state.active_player
	if not state.finished and local_ready_seat != seat:
		local_concede_armed = false
		panel.add_child(label("Private handoff", 20, Color("fff0a1")))
		panel.add_child(label("Pass the device. The next hand remains hidden until the ready button is pressed.", 16, Color("dce8f4")))
		var hidden := SUPPORT_CARD_VIEW.new(); hidden.configure({}, 0, "", true, false, false); hidden.name = "LocalHiddenCardBack"; panel.add_child(hidden)
		panel.add_child(make_button("Ready Player %d" % (seat + 1), func(): local_ready_seat = seat; render(), Color("a86b2e")))
		panel.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d"))); return
	var stage := BattleSpriteStage.new(); stage.configure(state.active_unit(0), state.active_unit(1), battle_last_event, battle_last_actor, bool(settings().get("reduced_motion", false))); panel.add_child(stage); stage.custom_minimum_size = Vector2(0, 110 if is_portrait_layout() else 120)
	for player in [0, 1]:
		var unit := state.active_unit(player)
		panel.add_child(label("Player %d: %s  %d/%d HP - %s" % [player + 1, str(unit.get("name", "Unknown")), int(unit.get("hp", 0)), int(unit.get("max_hp", 1)), str(unit.get("element", "Unknown"))], 17, Color("a9ecff") if player == 0 else Color("ffaaa1")))
	if state.finished:
		panel.add_child(label("Local match complete. No Forge Coins or rewards are granted.", 18, Color("fff0a1")))
		panel.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d"))); return
	panel.add_child(label("Player %d hand — Deck %d | Discard %d" % [seat + 1, state.players[seat].deck.size(), state.players[seat].get("discard", []).size()], 15, Color("dce8f4")))
	var actions := GridContainer.new(); actions.name = "LocalBattleActionGrid"; actions.columns = 2 if is_portrait_layout() else 4; actions.add_theme_constant_override("h_separation", 8); actions.add_theme_constant_override("v_separation", 8); panel.add_child(actions)
	for action in [{"type":"attack","name":"Basic Attack"},{"type":"ability","name":"Signature Ability"},{"type":"defend","name":"Defend"},{"type":"end_turn","name":"End Turn"}]:
		actions.add_child(make_button(str(action.name), func(): submit_local_intent({"type":action.type}), Color("2f93a8")))
	var card_counts := {}
	for card_id in state.players[seat].hand: card_counts[str(card_id)] = int(card_counts.get(str(card_id), 0)) + 1
	var local_carousel := ScrollContainer.new()
	local_carousel.name = "LocalRevealedCardCarousel"
	local_carousel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	local_carousel.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	local_carousel.custom_minimum_size = Vector2(0, 274)
	local_carousel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(local_carousel)
	var local_cards := GridContainer.new(); local_cards.name = "LocalRevealedCardGrid"; local_cards.columns = 4
	local_cards.add_theme_constant_override("h_separation", 8)
	local_carousel.add_child(local_cards)
	for card_id in card_counts:
		var definition := Catalog.support_card(str(card_id)); var reason := SupportCardRules.legality_reason(state, seat, definition)
		var view := SUPPORT_CARD_VIEW.new(); view.configure(definition, int(card_counts[card_id]), reason); view.name = "LocalCard%s" % str(card_id).capitalize(); view.pressed.connect(func(): submit_local_intent({"type":"card","card_id":card_id})); local_cards.add_child(view)
	local_cards.custom_minimum_size = Vector2(maxi(1, card_counts.size()) * 182, 261)
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
	if bool(result.get("settled", false)):
		# A terminal keyboard/controller action should regain a predictable target.
		# Ordinary touch-driven drafts deliberately leave focus untouched.
		_focus_after_render = true
		GameManager.settle_local_trade(result.creator, result.audit)
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
		if str(offer.get("kind", "")) == "support_card":
			var definition := Catalog.support_card(str(offer.get("item_id", "")))
			var preview := SUPPORT_CARD_VIEW.new(); preview.configure(definition, int(GameManager.profile.support_cards.get(str(offer.get("item_id", "")), 0)), "", false, false, false); preview.name = "ShopCard%s" % str(offer.get("item_id", "")).capitalize(); card.add_child(preview)
		card.add_child(label(str(offer.name), 19, Color("8deaff")))
		card.add_child(label(str(offer.kind).replace("_", " ").capitalize() + " • " + str(offer.price) + " FC", 14, Color("dce8f4")))
		card.add_child(make_button("Acquire", func(): GameManager.buy_shop_offer(shop_day_key, str(offer.offer_id))))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_print_yard() -> void:
	var panel := make_panel(Color("19334de8"), Color("7bcf89")); body.add_child(panel.get_parent())
	panel.add_child(label("Print Yard", 25, Color("a8e3a5")))
	panel.add_child(label("Choose one calm, deterministic drill for today. Each choice can be claimed only once.", 16, Color("dce8f4")))
	panel.add_child(label("Companions present: %d | Current XP: %d | Pending warmup: +%d starting filament" % [GameManager.profile.creatures.size(), int(GameManager.profile.xp), int(GameManager.profile.get("pending_spool_warmup", 0))], 15, Color("9beaff")))
	var already := str(GameManager.profile.get("last_yard_day", "")) == shop_day_key
	var chosen := str(GameManager.profile.get("yard_choice", ""))
	panel.add_child(label("Today's drill: %s" % (chosen.replace("_", " ").capitalize() if already else "Choose one below"), 15, Color("a8e3a5") if already else Color("fff0a1")))
	for drill_id in ["field_practice", "team_bond", "spool_warmup"]:
		var unavailable: bool = drill_id == "spool_warmup" and GameManager.filament_cap() <= 3
		var copy: String = str({"field_practice":"Field Practice - +12 account XP", "team_bond":"Team Bond - +5 mastery to each saved team print", "spool_warmup":"Spool Warmup - +1 starting filament for next solo match (Requires spool capacity 4+)" if unavailable else "Spool Warmup - +1 starting filament for next solo match"}[drill_id])
		var drill_button := make_button(copy, run_print_yard_drill.bind(drill_id), Color("588d73") if not already and not unavailable else Color("536c8d"))
		drill_button.disabled = already or unavailable
		panel.add_child(drill_button)
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func run_print_yard_drill(drill_id: String) -> void:
	var before := int(GameManager.profile.get("revision", 0))
	GameManager.visit_print_yard(shop_day_key, drill_id)
	if int(GameManager.profile.get("revision", 0)) > before: _toast("Print Yard drill complete.")

func render_calibration_bench() -> void:
	var panel := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(panel.get_parent())
	var used: int = int(GameManager.profile.daily_job_count) if str(GameManager.profile.last_job_day) == shop_day_key else 0
	panel.add_child(label("Calibration Bench", 25, Color("ffd36c")))
	var targets: Array = ProgressionRules.calibration_pattern(shop_day_key, used)
	if calibration_step >= 3 or used >= ProgressionRules.DAILY_CALIBRATION_LIMIT: calibration_step = 0; calibration_values = [50, 50, 50]
	panel.add_child(label("Today: %d / %d patterns complete. Confirm all three values to score this pattern." % [used, ProgressionRules.DAILY_CALIBRATION_LIMIT], 15, Color("9beaff")))
	if used < ProgressionRules.DAILY_CALIBRATION_LIMIT:
		var target: int = int(targets[calibration_step])
		var value: int = int(calibration_values[calibration_step])
		panel.add_child(label("Step %d / 3 - target band %d to %d | selected %d" % [calibration_step + 1, maxi(0, target - 5), mini(100, target + 5), value], 18, Color("fff0a1")))
		var adjust := HBoxContainer.new(); panel.add_child(adjust)
		adjust.add_child(make_button("-10", adjust_calibration.bind(-10), Color("536c8d")))
		adjust.add_child(make_button("+10", adjust_calibration.bind(10), Color("2f93a8")))
		panel.add_child(make_button("Confirm Step %d" % (calibration_step + 1), confirm_calibration_step, Color("a86b2e")))
	else: panel.add_child(label("All three calibration patterns are complete for today.", 16, Color("a8e3a5")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func adjust_calibration(delta: int) -> void:
	calibration_values[calibration_step] = clampi(int(calibration_values[calibration_step]) + delta, 0, 100)
	render()

func confirm_calibration_step() -> void:
	calibration_step += 1
	if calibration_step < 3:
		render()
		return
	var used: int = int(GameManager.profile.daily_job_count) if str(GameManager.profile.last_job_day) == shop_day_key else 0
	var performance := ProgressionRules.calibration_performance(ProgressionRules.calibration_pattern(shop_day_key, used), calibration_values)
	var reward := GameManager.complete_workshop_job(performance, shop_day_key)
	if reward > 0: _toast("Calibration result %d%%: +%d Forge Coins." % [performance, reward])
	calibration_step = 0; calibration_values = [50, 50, 50]

func render_settings() -> void:
	var panel := make_panel(Color("19334de8"), Color("ffd36c")); body.add_child(panel.get_parent())
	var current := settings()
	panel.add_child(label("Workshop Settings", 25, Color("ffd36c")))
	panel.add_child(label("Installed review build: " + REVIEW_BUILD_LABEL, 13, Color("9beaff")))
	panel.add_child(label("Settings are saved to this profile. Text, contrast, and motion controls never change battle rules.", 15, Color("dce8f4")))
	for scale in AccessibilityRules.TEXT_SCALES:
		panel.add_child(make_button("Text size %d%%" % (int(scale) / 100), func(): GameManager.save_settings({"text_scale_bps":scale}), Color("588d73") if int(current.text_scale_bps) == int(scale) else Color("2f93a8")))
	panel.add_child(make_button("High contrast: %s" % ("On" if bool(current.high_contrast) else "Off"), func(): GameManager.save_settings({"high_contrast":not bool(current.high_contrast)})))
	panel.add_child(make_button("Reduced motion: %s" % ("On" if bool(current.reduced_motion) else "Off"), func(): GameManager.save_settings({"reduced_motion":not bool(current.reduced_motion)})))
	panel.add_child(label("Audio mix - procedural workshop tones only. Captions remain visible for gameplay cues.", 15, Color("9beaff")))
	for audio_key in ["master_bps", "music_bps", "sfx_bps"]:
		var title: String = str({"master_bps":"Master", "music_bps":"Music", "sfx_bps":"SFX"}[audio_key])
		panel.add_child(label("%s: %s" % [title, AudioSettings.label_for(int(current.get(audio_key, 0)))], 15, Color("dce8f4")))
		var row := HBoxContainer.new(); panel.add_child(row)
		row.add_theme_constant_override("separation", 8)
		var lower := make_button("Lower", adjust_audio_setting.bind(audio_key, -1), Color("536c8d"))
		lower.name = "Audio%sLower" % title
		lower.custom_minimum_size = Vector2(120, 48)
		lower.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(lower)
		var raise := make_button("Raise", adjust_audio_setting.bind(audio_key, 1), Color("2f93a8"))
		raise.name = "Audio%sRaise" % title
		raise.custom_minimum_size = Vector2(120, 48)
		raise.size_flags_horizontal = Control.SIZE_SHRINK_END
		row.add_child(raise)
	for difficulty in AccessibilityRules.DIFFICULTIES:
		panel.add_child(make_button("Training AI: %s" % difficulty, func(): GameManager.save_settings({"ai_difficulty":difficulty}), Color("588d73") if str(current.ai_difficulty) == difficulty else Color("2f93a8")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func adjust_audio_setting(key: String, direction: int) -> void:
	var levels: Array[int] = AudioSettings.LEVELS
	var current: int = int(settings().get(key, 0))
	var index := levels.find(current)
	if index < 0: index = levels.find(5000)
	index = clampi(index + direction, 0, levels.size() - 1)
	GameManager.save_settings({key:levels[index]})
	_audio_director.configure(settings(), false)

func open_printer(creature_id: String) -> void:
	var definition := Catalog.creature(creature_id)
	if definition.is_empty() or creature_id not in GameManager.profile.get("blueprints", []):
		_toast("That blueprint is not learned yet.")
		return
	printer_creature_id = creature_id
	printer_armor_id = ""
	printer_is_armor = false
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
	if (definition.is_empty() and not printer_is_armor) or printer_sequence == null:
		screen = "collection"
		render()
		return
	printer_progress_label = null
	var panel := make_panel(Color("152d49ec"), Color("f1be69"))
	body.add_child(panel.get_parent())
	panel.add_child(label("Arcane Forge", 27, Color("ffd36c")))
	var print_name := (str(ArmorCoreDefinitions.core_blueprint_definition(printer_armor_id).get("name", "Core")) if printer_is_core else str(ProgressionRules.armor_def(printer_armor_id).get("name", "Full Suit"))) if printer_is_armor else str(definition.name)
	var print_type := ("Printed Core" if printer_is_core else "Complete suit") if printer_is_armor else str(definition.element)
	panel.add_child(label("%s - %s - %d Forge Coins" % [print_name, print_type, printer_price], 16, Color("9beaff")))
	panel.add_child(label("Available Forge Coins: %d. The profile changes only when the raw print completes." % int(GameManager.profile.coins), 15, Color("dce8f4")))
	_forge_screen_component.refresh(printer_creature_id, bool(settings().get("reduced_motion", false)), bool(settings().get("high_contrast", false)), printer_sequence.phase, printer_sequence.progress_bps, printer_sequence.phase_progress_bps(), printer_presentation_seconds, 540 if size.y > size.x else 330, printer_armor_id if printer_is_armor else "", printer_armor_id if printer_is_core else "")
	_forge_screen_component.attach(panel)
	match printer_sequence.phase:
		ArcaneForgeSequence.IDLE:
			panel.add_child(label("Preview the dormant print on the build plate. Begin only when ready.", 16, Color("fff0a1")))
			panel.add_child(make_button("Begin Print (%d FC)" % printer_price, begin_printer, Color("a86b2e")))
			panel.add_child(make_button("Cancel Preview", cancel_printer_preview, Color("536c8d")))
		ArcaneForgeSequence.PRINTING:
			printer_progress_label = label(_printer_progress_text(), 16, Color("9beaff"))
			printer_progress_label.name = "PrinterProgressStatus"
			panel.add_child(printer_progress_label)
			panel.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.RAW_COMPLETE:
			panel.add_child(label("Raw print complete. Securing the Forge transaction...", 16, Color("fff0a1")))
		ArcaneForgeSequence.RAW_HOLD:
			var hold_text := ("Completed Core rests for a moment before transfer to the Equipment Workbench." if printer_is_core else "Completed full suit rests for a moment before transfer to the Equipment Workbench.") if printer_is_armor else "Raw print complete. The Forge record is secure; the dormant form rests for a moment before awakening."
			panel.add_child(label(hold_text, 16, Color("fff0a1")))
			panel.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.AWAKENING:
			panel.add_child(label("Filament awakening in progress. The new print is already safely recorded.", 16, Color("9beaff")))
			panel.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.DEPARTING:
			var departing_name := print_name
			panel.add_child(label("%s leaves the build plate for the workbench." % departing_name, 16, Color("a8e3a5")))
			panel.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.AWAKENED:
			var completion_text := ("Core secured: %s is ready for the Equipment Workbench." if printer_is_core else "Full suit secured: %s is ready for the Equipment Workbench.") % print_name if printer_is_armor else "Welcome, %s! Your living print is ready for the Collection." % str(definition.name)
			panel.add_child(label(completion_text, 20, Color("a8e3a5")))
			panel.add_child(make_button("Print Another" if not printer_is_armor else "Print Another Equipment Item", return_to_printer_picker, Color("a86b2e")))
			panel.add_child(make_button("Return to Printer Bench" if not printer_is_armor else "Return to Equipment Workbench", return_to_printer_station, Color("536c8d")))
		ArcaneForgeSequence.FAILED:
			panel.add_child(label("The Forge could not complete this print: %s" % printer_failure, 17, Color("ffaaa1")))
			panel.add_child(make_button("Return to Collection", navigate_to.bind("collection"), Color("536c8d")))
		_:
			panel.add_child(label("Preview closed without changing your profile.", 16, Color("dce8f4")))

func _printer_progress_text() -> String:
	if printer_sequence == null: return ""
	return "Printing layers: %d%%. The nozzle and reveal are presentation only." % (printer_sequence.layer_reveal_bps() / 100)

func _refresh_printer_presentation() -> void:
	if screen != "printer" or printer_sequence == null: return
	_forge_screen_component.refresh(printer_creature_id, bool(settings().get("reduced_motion", false)), bool(settings().get("high_contrast", false)), printer_sequence.phase, printer_sequence.progress_bps, printer_sequence.phase_progress_bps(), printer_presentation_seconds, 540 if size.y > size.x else 330, printer_armor_id if printer_is_armor else "", printer_armor_id if printer_is_core else "")
	if is_instance_valid(printer_progress_label):
		printer_progress_label.text = _printer_progress_text()

func begin_printer() -> void:
	if printer_sequence == null or not printer_sequence.begin(): return
	printer_tick_accumulator = 0.0
	printer_presentation_seconds = 0.0
	render()

func advance_printer_for_test(step_bps: int) -> void:
	if printer_sequence == null: return
	var phase_before := printer_sequence.phase
	printer_sequence.advance(step_bps)
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE:
		_commit_printer_once()
		render()
	elif printer_sequence.phase != phase_before:
		render()
	else:
		_refresh_printer_presentation()

func _commit_printer_once() -> void:
	if printer_sequence == null or not printer_sequence.request_commit(): return
	var success := (GameManager.print_core(printer_armor_id) if printer_is_core else GameManager.print_suit(printer_armor_id)) if printer_is_armor else GameManager.print_creature(printer_creature_id)
	if not success: printer_failure = "The blueprint, coins, or inventory no longer passed validation."
	printer_sequence.resolve_commit(success)

func skip_printer() -> void:
	if printer_sequence == null or not printer_sequence.skip(): return
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE: _commit_printer_once()
	render()

func cancel_printer_preview() -> void:
	if printer_sequence != null: printer_sequence.cancel()
	printer_creature_id = ""
	printer_armor_id = ""
	printer_is_armor = false
	printer_is_core = false
	screen = printer_return_screen
	if screen == "workshop": workshop_view = workshop_return_view
	render()

func return_to_printer_station() -> void:
	if printer_return_screen == "armor":
		navigate_to("armor")
		return
	if printer_return_screen == "workshop":
		screen = "workshop"
		workshop_view = "printer"
		workshop_selected = "printer"
		workshop_drawer_object = ""
		render()
		return
	navigate_to("collection")

func return_to_printer_picker() -> void:
	if printer_return_screen == "armor":
		open_armor_printer(printer_armor_id)
		return
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
		var instance_id := str(creature.get("instance_id", ""))
		row.add_child(label("%s - %s%s - Mastery %d" % [str(Catalog.creature(str(creature.creature_id)).name), "Bound" if bool(creature.get("bound", false)) else "Printed", " - Full suit fitted" if not str(creature.get("suit_instance_id", "")).is_empty() else "", GameManager.creature_mastery(instance_id)], 16, Color("dce8f4")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_team() -> void:
	var intro := make_panel(Color("19334de8"), Color("8deaff")); body.add_child(intro.get_parent())
	intro.add_child(label("Three-Slot Team Builder", 25, Color("8deaff")))
	if not team_draft_dirty: team_draft = Array(GameManager.profile.get("team", [])).duplicate()
	intro.add_child(label("Draft training team: %d / 3. Every selected print is unique; a team needs one to three companions." % team_draft.size(), 15, Color("dce8f4")))
	for creature in GameManager.profile.creatures:
		var instance_id := str(creature.get("instance_id", ""))
		if instance_id.is_empty(): continue
		var selected: bool = instance_id in team_draft
		var creature_name := str(Catalog.creature(str(creature.get("creature_id", ""))).get("name", "Unknown"))
		if TieredArmorRoster.has_master(str(creature.get("creature_id", ""))) and not str(creature.get("suit_instance_id", "")).is_empty():
			var loadout := EquipmentRules.suit_loadout(GameManager.profile, instance_id)
			var portrait := TieredArmorPalettePreview.new(); portrait.custom_minimum_size = Vector2(160, 160); portrait.configure_creature(str(creature.get("creature_id", ""))); portrait.configure_tier(str(loadout.get("tier_id", "standard"))); portrait.configure_core(str(loadout.get("core_id", ""))); intro.add_child(portrait)
			intro.add_child(label("%s • %s" % [str(ArmorCoreDefinitions.suit_definition(str(loadout.get("tier_id", ""))).get("name", "Full Suit")), str(ArmorCoreDefinitions.definition(str(loadout.get("core_id", ""))).get("name", "No Core"))], 13, Color("f1be69")))
		intro.add_child(make_button(("Remove " if selected else "Add ") + "%s (Mastery %d)" % [creature_name, GameManager.creature_mastery(instance_id)], toggle_team_draft_member.bind(instance_id), Color("588d73") if selected else Color("2f93a8")))
	intro.add_child(make_button("Save Team", save_team_draft, Color("a86b2e")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func toggle_team_draft_member(instance_id: String) -> void:
	if instance_id in team_draft:
		if team_draft.size() > 1: team_draft.erase(instance_id)
		else: _toast("A training team needs at least one companion.")
	elif team_draft.size() < 3:
		team_draft.append(instance_id)
	else:
		_toast("A team can hold only three companions.")
	team_draft_dirty = true
	render()

func save_team_draft() -> void:
	var draft: Array = team_draft.duplicate()
	# Reset before the synchronous profile_changed signal so its render sees the
	# saved profile rather than a stale draft.
	team_draft_dirty = false
	if GameManager.save_team(draft):
		team_draft = Array(GameManager.profile.get("team", [])).duplicate()
		_toast("Team saved. Maker shelf and training bench are updated.")
	else:
		team_draft_dirty = true

func render_armor() -> void:
	var panel := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(panel.get_parent())
	if equipment_selected_creature_id.is_empty() and not GameManager.profile.get("creatures", []).is_empty(): equipment_selected_creature_id = str(GameManager.profile.creatures[0].get("instance_id", ""))
	panel.add_child(EQUIPMENT_WORKBENCH_VIEW.build(GameManager.profile, equipment_selected_creature_id, equipment_mode, equipment_selected_id, not is_portrait_layout(), {"select_creature":equipment_select_creature,"select_mode":equipment_select_mode,"select_item":equipment_select_item,"suit_action":equipment_suit_action,"core_action":equipment_core_action,"fit_suit":equipment_fit_suit,"remove_suit":equipment_remove_suit,"remove_core":equipment_remove_core,"socket_core":equipment_socket_core}))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func equipment_select_creature(instance_id: String) -> void: equipment_selected_creature_id = instance_id; render()
func equipment_select_mode(next_mode: String) -> void:
	equipment_mode = next_mode
	if next_mode == "cores": equipment_selected_id = str(EquipmentRules.suit_loadout(GameManager.profile, equipment_selected_creature_id).get("core_id", ""))
	else: equipment_selected_id = "standard"
	render()
func equipment_select_item(item_id: String) -> void: equipment_selected_id = item_id; render()
func equipment_suit_action(tier_id: String) -> void:
	if tier_id in GameManager.profile.get("suit_blueprints", []): open_armor_printer(tier_id)
	else: GameManager.learn_suit_blueprint(tier_id)
func equipment_core_action(core_id: String) -> void:
	if core_id in GameManager.profile.get("core_blueprints", []): open_core_printer(core_id)
	else: GameManager.learn_core_blueprint(core_id)
func equipment_fit_suit(creature_id: String, suit_id: String) -> void: GameManager.move_suit(creature_id, suit_id)
func equipment_remove_suit() -> void: GameManager.remove_suit(equipment_selected_creature_id)
func equipment_remove_core(suit_id: String) -> void: GameManager.remove_core(suit_id)
func equipment_socket_core(suit_id: String, core_id: String) -> void: GameManager.move_core(suit_id, core_id)

func open_armor_printer(armor_id: String) -> void:
	var definition := ProgressionRules.armor_def(armor_id)
	if definition.is_empty() or armor_id not in GameManager.profile.get("suit_blueprints", []):
		_toast("That full-suit blueprint is not learned yet.")
		return
	printer_is_armor = true
	printer_is_core = false
	printer_armor_id = armor_id
	printer_creature_id = _selected_equipment_creature_species()
	printer_price = int(definition.get("print", 0))
	printer_sequence = ArcaneForgeSequence.create(bool(settings().get("reduced_motion", false)), true)
	printer_tick_accumulator = 0.0; printer_presentation_seconds = 0.0; printer_failure = ""
	printer_return_screen = "armor"
	screen = "printer"
	render()

func open_core_printer(core_id: String) -> void:
	var definition := ArmorCoreDefinitions.core_blueprint_definition(core_id)
	if definition.is_empty() or core_id not in GameManager.profile.get("core_blueprints", []):
		_toast("That Core blueprint is not learned yet."); return
	printer_is_armor = true; printer_is_core = true; printer_armor_id = core_id; printer_creature_id = _selected_equipment_creature_species(); printer_price = int(definition.print)
	printer_sequence = ArcaneForgeSequence.create(bool(settings().get("reduced_motion", false)), true)
	printer_tick_accumulator = 0.0; printer_presentation_seconds = 0.0; printer_failure = ""; printer_return_screen = "armor"; screen = "printer"; render()

func _selected_equipment_creature_species() -> String:
	for creature in GameManager.profile.get("creatures", []):
		if str(creature.get("instance_id", "")) == equipment_selected_creature_id:
			var species_id := str(creature.get("creature_id", ""))
			if Catalog.creature(species_id).is_empty() == false:
				return species_id
	return "cinderpaw"

func render_deck() -> void:
	var panel := make_panel(Color("19334de8"), Color("b88bff")); body.add_child(panel.get_parent())
	if deck_slot_id.is_empty(): deck_slot_id = str(GameManager.profile.get("active_deck_id", ProgressionRules.STARTER_DECK_ID))
	if deck_draft.is_empty(): deck_draft = GameManager.active_deck_cards()
	panel.add_child(label("15-Card Deck Builder", 25, Color("d3a7ff")))
	panel.add_child(label("Selected slot: %s | Draft: %d / 15. Only owned support cards can be saved." % [_saved_deck_name(deck_slot_id), deck_draft.size()], 15, Color("dce8f4")))
	for slot_id in ProgressionRules.DECK_SLOT_IDS:
		var saved_cards: Array = _saved_deck_cards(slot_id)
		var exists := _saved_deck_exists(slot_id)
		var action := "Active" if str(GameManager.profile.active_deck_id) == slot_id else "Select"
		var slot_copy := "%d cards - %s" % [saved_cards.size(), action] if exists else "Available slot"
		var slot_button := make_button("%s: %s" % [_saved_deck_name(slot_id), slot_copy], select_deck_slot.bind(slot_id), Color("588d73") if str(GameManager.profile.active_deck_id) == slot_id else Color("526e93"))
		slot_button.name = "DeckSlot%s" % slot_id.capitalize()
		panel.add_child(slot_button)
	if Catalog.support_card(deck_selected_card_id).is_empty():
		for candidate in Catalog.SUPPORT_CARDS:
			if int(GameManager.profile.support_cards.get(str(candidate.id), 0)) > 0:
				deck_selected_card_id = str(candidate.id)
				break
	var selected := Catalog.support_card(deck_selected_card_id)
	if not selected.is_empty():
		var selected_tray := make_panel(Color("10273ad8"), Color("ffd36c")); panel.add_child(selected_tray.get_parent()); selected_tray.name = "DeckSelectedCardTray"
		var selected_owned: int = int(GameManager.profile.support_cards.get(deck_selected_card_id, 0)); var selected_copies: int = deck_draft.count(deck_selected_card_id)
		selected_tray.add_child(label("Selected: %s" % str(selected.name), 19, Color("fff0a1")))
		selected_tray.add_child(label("Owned: %d | Draft copies: %d / %d | %d Filament" % [selected_owned, selected_copies, selected_owned, int(selected.cost)], 14, Color("9beaff")))
		selected_tray.add_child(label(SUPPORT_CARD_PRESENTER.effect_text(selected) + "\nTarget: " + SUPPORT_CARD_PRESENTER.target_text(selected), 14, Color("dce8f4")))
		var selected_actions := HBoxContainer.new(); selected_tray.add_child(selected_actions)
		var selected_remove := make_button("Remove selected", change_deck_draft.bind(deck_selected_card_id, false), Color("536c8d")); selected_remove.name = "DeckSelectedRemove"; selected_remove.disabled = selected_copies <= 0; selected_actions.add_child(selected_remove)
		var selected_add := make_button("Add selected (%d/%d)" % [selected_copies, selected_owned], change_deck_draft.bind(deck_selected_card_id, true), Color("2f93a8")); selected_add.name = "DeckSelectedAdd"; selected_add.disabled = deck_draft.size() >= 15 or selected_copies >= selected_owned; selected_actions.add_child(selected_add)
	var cards := GridContainer.new(); cards.name = "DeckCardGallery"; cards.columns = 2 if is_portrait_layout() else 4; cards.add_theme_constant_override("h_separation", 8); cards.add_theme_constant_override("v_separation", 8); panel.add_child(cards)
	for card in Catalog.SUPPORT_CARDS:
		var card_id := str(card.id); var owned: int = int(GameManager.profile.support_cards.get(card_id, 0))
		if owned <= 0: continue
		var view := SUPPORT_CARD_VIEW.new(); view.configure(card, owned, ""); view.name = "DeckCard%s" % card_id.capitalize(); view.pressed.connect(select_deck_card.bind(card_id)); cards.add_child(view)
	panel.add_child(make_button("Save %s as active (%d / 15)" % [_saved_deck_name(deck_slot_id), deck_draft.size()], save_active_deck_draft, Color("a86b2e")))
	var missing_slot := ""
	for candidate in ProgressionRules.DECK_SLOT_IDS:
		if candidate == ProgressionRules.STARTER_DECK_ID: continue
		if not _saved_deck_exists(candidate): missing_slot = candidate; break
	if not missing_slot.is_empty(): panel.add_child(make_button("Create %s Slot" % str(ProgressionRules.DECK_SLOT_NAMES.get(missing_slot, "Forge Deck")), create_deck_slot.bind(missing_slot), Color("2f93a8")))
	if not missing_slot.is_empty() and _saved_deck_exists(deck_slot_id) and not _saved_deck_cards(deck_slot_id).is_empty():
		panel.add_child(make_button("Duplicate Selected into %s" % str(ProgressionRules.DECK_SLOT_NAMES.get(missing_slot, "Forge Deck")), duplicate_selected_deck.bind(missing_slot), Color("2f93a8")))
	if deck_slot_id != ProgressionRules.STARTER_DECK_ID:
		panel.add_child(make_button("Delete Selected Slot", delete_selected_deck, Color("9a5b6f")))
		for fixed_name in ProgressionRules.DECK_NAME_OPTIONS:
			panel.add_child(make_button("Rename as %s" % fixed_name, rename_selected_deck.bind(fixed_name), Color("526e93")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_card_archive() -> void:
	var panel := make_panel(Color("19334de8"), Color("78cfe5")); body.add_child(panel.get_parent())
	panel.add_child(label("Support Card Archive", 25, Color("9beaff")))
	panel.add_child(label("30 offline tactical cards. Non-turn-ending; no reshuffle.", 15, Color("dce8f4")))
	panel.add_child(label("Deck 15 / opening 4 / hand cap 4 / draw 1 per turn.", 15, Color("dce8f4")))
	var filters := HBoxContainer.new(); panel.add_child(filters)
	var all_filter := make_button("All cards", func(): card_archive_owned_only = false; render(), Color("2f93a8") if not card_archive_owned_only else Color("536c8d")); all_filter.name = "ArchiveFilterAll"; filters.add_child(all_filter)
	var owned_filter := make_button("Owned only", func(): card_archive_owned_only = true; render(), Color("2f93a8") if card_archive_owned_only else Color("536c8d")); owned_filter.name = "ArchiveFilterOwned"; filters.add_child(owned_filter)
	var cards := GridContainer.new(); cards.name = "CardArchiveGallery"; cards.columns = 2 if is_portrait_layout() else 4; cards.add_theme_constant_override("h_separation", 8); cards.add_theme_constant_override("v_separation", 8); panel.add_child(cards)
	for card in Catalog.SUPPORT_CARDS:
		var owned := int(GameManager.profile.support_cards.get(str(card.id), 0))
		if card_archive_owned_only and owned <= 0: continue
		var view := SUPPORT_CARD_VIEW.new(); view.configure(card, owned); view.name = "ArchiveCard%s" % str(card.id).capitalize(); view.pressed.connect(show_card_archive_detail.bind(card)); cards.add_child(view)
	if not card_archive_detail_id.is_empty(): _append_card_archive_detail(panel, Catalog.support_card(card_archive_detail_id))
	body.add_child(make_button("Back to Maker Bench", navigate_to.bind("workshop"), Color("536c8d")))

func show_card_archive_detail(card: Dictionary) -> void:
	card_archive_detail_id = str(card.get("id", ""))
	render()

func _append_card_archive_detail(host: Container, card: Dictionary) -> void:
	var panel := make_panel(Color("10273ad8"), Color("ffd36c")); host.add_child(panel.get_parent())
	panel.name = "CardArchiveDetail"
	panel.add_child(label(str(card.get("name", "Support Card")), 21, Color("fff0a1")))
	panel.add_child(label("%s • %s • %d Filament" % [str(card.get("role", "utility")).capitalize(), str(card.get("rarity", "common")).capitalize(), int(card.get("cost", 0))], 15, Color("9beaff")))
	panel.add_child(label(SUPPORT_CARD_PRESENTER.effect_text(card) + "\nTarget: " + SUPPORT_CARD_PRESENTER.target_text(card) + "\nOwned: %d" % int(GameManager.profile.support_cards.get(str(card.id), 0)), 15, Color("dce8f4")))

func _saved_deck_cards(deck_id: String) -> Array:
	for saved in GameManager.profile.get("decks", []):
		if saved is Dictionary and str(saved.get("id", "")) == deck_id:
			var cards = saved.get("cards", [])
			return cards.duplicate() if cards is Array else []
	return []

func _saved_deck_exists(deck_id: String) -> bool:
	for saved in GameManager.profile.get("decks", []):
		if saved is Dictionary and str(saved.get("id", "")) == deck_id: return true
	return false

func _saved_deck_name(deck_id: String) -> String:
	for saved in GameManager.profile.get("decks", []):
		if saved is Dictionary and str(saved.get("id", "")) == deck_id:
			return str(saved.get("name", ProgressionRules.DECK_SLOT_NAMES.get(deck_id, "Forge Deck")))
	return str(ProgressionRules.DECK_SLOT_NAMES.get(deck_id, "Forge Deck"))

func select_deck_slot(deck_id: String) -> void:
	deck_slot_id = deck_id
	var saved_cards := _saved_deck_cards(deck_id)
	deck_draft = saved_cards.duplicate() if not saved_cards.is_empty() else GameManager.active_deck_cards()
	if not saved_cards.is_empty():
		GameManager.select_deck(deck_id)
	else:
		render()

func select_deck_card(card_id: String) -> void:
	if Catalog.support_card(card_id).is_empty(): return
	deck_selected_card_id = card_id
	render()

func change_deck_draft(card_id: String, add: bool) -> void:
	var owned: int = int(GameManager.profile.get("support_cards", {}).get(card_id, 0))
	if add:
		if deck_draft.size() < 15 and deck_draft.count(card_id) < owned: deck_draft.append(card_id)
	else:
		deck_draft.erase(card_id)
	render()

func save_active_deck_draft() -> void:
	GameManager.save_deck_slot(deck_draft.duplicate(), deck_slot_id)

func create_deck_slot(deck_id: String) -> void:
	deck_slot_id = deck_id; deck_draft = []
	if not GameManager.create_deck(deck_id, str(ProgressionRules.DECK_SLOT_NAMES.get(deck_id, "Forge Deck"))): render()

func duplicate_selected_deck(target_id: String) -> void:
	if GameManager.duplicate_deck(deck_slot_id, target_id):
		deck_slot_id = target_id; deck_draft = _saved_deck_cards(target_id)
	else: render()

func delete_selected_deck() -> void:
	var deleted := deck_slot_id
	deck_slot_id = ProgressionRules.STARTER_DECK_ID; deck_draft = GameManager.active_deck_cards()
	if not GameManager.delete_deck(deleted): render()

func rename_selected_deck(name: String) -> void:
	if not GameManager.rename_deck(deck_slot_id, name): render()

func render_codex() -> void:
	var intro := make_panel(Color("19334de8"), Color("b88bff")); body.add_child(intro.get_parent())
	intro.add_child(label("Forgedex", 25, Color("d3a7ff")))
	intro.add_child(label("%d blueprints have been discovered." % GameManager.profile.discovered.size(), 15, Color("dce8f4")))
	var grid := GridContainer.new(); grid.columns = 4 if size.x >= 1100 else 2; body.add_child(grid)
	for creature in Catalog.CREATURES:
		var known: bool = creature.id in GameManager.profile.discovered
		var card := make_panel(Color("152842e8"), Color(Catalog.rarity(creature.rarity).color if known else "4b5d72")); grid.add_child(card.get_parent())
		card.add_child(label(str(creature.name) if known else "???", 17, Color(Catalog.rarity(creature.rarity).color if known else "8492a1")))
		var mastery_total := 0; var owned_count := 0
		for owned in GameManager.profile.get("creatures", []):
			if owned is Dictionary and str(owned.get("creature_id", "")) == str(creature.id): mastery_total += GameManager.creature_mastery(str(owned.get("instance_id", ""))); owned_count += 1
		var print_count := int(GameManager.profile.get("print_history", {}).get("creatures", {}).get(str(creature.id), 0))
		card.add_child(label("%s | HP %d | Attack %d | Speed %d\nOwned %d | Mastery %d | Printed %d" % [str(creature.element), int(creature.hp), int(creature.attack), int(creature.speed), owned_count, mastery_total, print_count] if known else "Undiscovered", 13, Color("dce8f4")))
		if known:
			card.add_child(label("%s: %s" % [str(creature.ability), Catalog.signature_description(str(creature.id))], 12, Color("b9d3e8")))
	intro.add_child(label("Full suits and Cores", 20, Color("ffd36c")))
	for suit in Catalog.SUITS:
		var tier_id := str(suit.id); var owned := 0
		for row in GameManager.profile.get("suits", []): if row is Dictionary and str(row.get("tier_id", "")) == tier_id: owned += 1
		var printed := int(GameManager.profile.get("print_history", {}).get("suits", {}).get(tier_id, 0))
		intro.add_child(label("%s - +%d HP | +%d speed | %d guard | owned %d | printed %d" % [str(suit.name), int(suit.hp), int(suit.speed), int(suit.armor), owned, printed], 14, Color("dce8f4")))
	for core in Catalog.CORE_BLUEPRINTS:
		var core_id := str(core.id); var core_owned := 0
		for row in GameManager.profile.get("cores", []): if row is Dictionary and str(row.get("core_id", "")) == core_id: core_owned += 1
		intro.add_child(label("%s — %s | owned %d" % [str(core.name), str(ArmorCoreDefinitions.definition(core_id).get("effect", "")), core_owned], 14, Color("dce8f4")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_proving_door() -> void:
	var panel := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(panel.get_parent())
	panel.add_child(label("Proving Door", 25, Color("ffd36c")))
	panel.add_child(label("Choose a repeatable daily sparring match, a fixed Workshop Trial ladder, or a private local match.", 15, Color("dce8f4")))
	panel.add_child(label("Daily Training", 20, Color("8deaff")))
	panel.add_child(label("Today\'s deterministic rival changes by date. Wins grant 20 Forge Coins and 30 XP; defeats grant 8 Forge Coins and 10 XP.", 14, Color("dce8f4")))
	panel.add_child(make_button("Start Daily Training", start_battle, Color("2f93a8")))
	panel.add_child(label("Workshop Trials", 20, Color("ffd36c")))
	var campaign: Dictionary = GameManager.profile.get("solo_campaign", {})
	panel.add_child(label("Five authored tiers, 20 fixed encounters. Tier %d is currently available; first clears grant one-time coins, XP, and team mastery." % int(campaign.get("unlocked_tier", 1)), 14, Color("dce8f4")))
	var trials := make_button("Browse Workshop Trials", navigate_to.bind("trials"), Color("a86b2e"))
	trials.name = "OpenWorkshopTrials"
	panel.add_child(trials)
	panel.add_child(make_button("Start Local Versus", start_local_vs, Color("526e93")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_trials() -> void:
	var intro := make_panel(Color("19334de8"), Color("ffd36c")); body.add_child(intro.get_parent())
	intro.add_child(label("Workshop Trials", 25, Color("ffd36c")))
	intro.add_child(label("Each tier unlocks in order. Clear three encounters, then the boss, to open the next workshop test. First-clear rewards are claimed only on victory.", 15, Color("dce8f4")))
	var lineup := _trial_lineup_preview()
	intro.add_child(label(str(lineup.get("text", "Trial lineup: choose a Team Builder lineup.")), 14, Color("a9ecff") if not bool(lineup.get("temporary", false)) else Color("fff0a1")))
	var edit_team := make_button("Edit Current Team", navigate_to.bind("team"), Color("526e93"))
	edit_team.name = "EditCurrentTrialTeam"
	intro.add_child(edit_team)
	for tier in Catalog.WORKSHOP_TRIAL_TIERS:
		var tier_number: int = int(tier.get("tier", 0))
		var card := make_panel(Color("142b42e8"), Color("f1be69") if tier_number <= int(GameManager.profile.get("solo_campaign", {}).get("unlocked_tier", 1)) else Color("536273"))
		body.add_child(card.get_parent())
		card.add_child(label("Tier %d - %s" % [tier_number, str(tier.get("name", "Workshop Trial"))], 20, Color("ffd36c")))
		for encounter in tier.get("encounters", []):
			var encounter_id := str(encounter.get("id", ""))
			var state := GameManager.campaign_encounter_state(encounter_id)
			var unlocked: bool = bool(state.get("unlocked", false))
			var completed: bool = bool(state.get("completed", false))
			var reward: Dictionary = state.get("reward", {})
			var rival_names: Array[String] = []
			for creature_id in encounter.get("team", []): rival_names.append(str(Catalog.creature(str(creature_id)).get("name", creature_id)))
			var best_turns: int = int(GameManager.profile.get("solo_campaign", {}).get("best_turn_counts", {}).get(encounter_id, 0))
			var status_text := ("Complete - best %d turns" % best_turns) if completed and best_turns > 0 else ("Complete" if completed else ("Ready" if unlocked else "Locked - clear the prior encounter"))
			card.add_child(label("%s%s - %s" % ["Boss: " if bool(encounter.get("boss", false)) else "", str(encounter.get("name", "Encounter")), status_text], 16, Color("a8e3a5") if completed else (Color("dce8f4") if unlocked else Color("8492a1"))))
			card.add_child(label("Rival: %s | %s AI | spool %d" % [", ".join(rival_names), str(encounter.get("ai", "Apprentice")), int(encounter.get("spool", 3))], 13, Color("b9d3e8")))
			card.add_child(label("First clear: %d Forge Coins, %d XP, +%d mastery for each saved team print." % [int(reward.get("coins", 0)), int(reward.get("xp", 0)), int(reward.get("mastery", 0))], 13, Color("fff0a1")))
			var start := make_button("Replay %s" % str(encounter.get("name", "Trial")) if completed else "Start %s" % str(encounter.get("name", "Trial")), start_trial.bind(encounter_id), Color("588d73") if completed else Color("a86b2e"))
			start.name = "TrialStart%s" % encounter_id
			start.disabled = not unlocked
			card.add_child(start)
	body.add_child(make_button("Back to Proving Door", navigate_to.bind("proving"), Color("536c8d")))

func _trial_lineup_preview() -> Dictionary:
	# Preview and launch intentionally use the same factory contract: no separate
	# UI-only normalization can advertise a lineup BattleState will not receive.
	var fallback := SoloBattleFactory.preview(GameManager.profile)
	var temporary: Array = fallback.get("team", [])
	if not temporary.is_empty():
		if bool(fallback.get("temporary_repair", false)):
			return {"text":"Trial lineup: Legacy owned prints will be used temporarily: %s. Save a Team Builder lineup after the match." % _trial_lineup_names(temporary), "temporary":true}
		return {"text":"Trial lineup: %s" % _trial_lineup_names(temporary), "temporary":false}
	return {"text":"Trial lineup: No catalog-valid owned print is ready. Use the Printer Bench, then Team Builder.", "temporary":true}

func _trial_lineup_names(lineup: Array) -> String:
	var names: Array[String] = []
	for entry in lineup:
		var creature_id := str(entry.get("creature_id", "")) if entry is Dictionary else str(entry)
		var definition := Catalog.creature(creature_id)
		if not definition.is_empty(): names.append(str(definition.get("name", creature_id)))
	return ", ".join(names)

func start_trial(encounter_id: String) -> void:
	var state := GameManager.campaign_encounter_state(encounter_id)
	if not bool(state.get("ok", false)) or not bool(state.get("unlocked", false)):
		_toast(str(state.get("error", "Clear the earlier Workshop Trial encounters first.")))
		return
	var encounter: Dictionary = state["encounter"]
	battle_session_generation += 1
	ai_pending = false
	var setup := GameManager.create_solo_battle(encounter.get("team", []), int(encounter.get("spool", 3)), _trial_seed(encounter_id))
	if not bool(setup.get("ok", false)):
		battle = null
		_toast(str(setup.get("error", "The Workshop Trial team is not ready.")))
		return
	battle = setup.get("battle", null) as BattleState
	battle_launch_notice = str(setup.get("repair_message", "")) if bool(setup.get("temporary_repair", false)) or bool(setup.get("equipment_free_retry", false)) else ""
	var warmup := GameManager.consume_solo_spool_warmup()
	if warmup > 0: battle.players[0].filament = mini(int(battle.players[0].spool_cap), 3 + warmup)
	battle_mode = "trial"
	trial_encounter_id = encounter_id
	battle_ai_difficulty = str(encounter.get("ai", "Apprentice"))
	battle_last_event = ""; battle_last_actor = 0; battle_presentation_serial = 0; battle_concede_armed = false; battle_secondary_open = false; battle_secondary_tab = "bench"
	if screen == "workshop": workshop_return_view = workshop_view
	screen = "battle"
	render()

func start_battle() -> void:
	# Training begins with the currently selected/available team; one print is valid.
	var rival_team := GameManager.training_opponent(shop_day_key)
	# A new match invalidates every deferred AI callback tied to an older stage.
	battle_session_generation += 1
	ai_pending = false
	var setup := GameManager.create_solo_battle(rival_team, 3, _training_seed(shop_day_key))
	if not bool(setup.get("ok", false)):
		battle = null
		_toast(str(setup.get("error", "The training team is not ready.")))
		return
	battle = setup.get("battle", null) as BattleState
	battle_launch_notice = str(setup.get("repair_message", "")) if bool(setup.get("temporary_repair", false)) or bool(setup.get("equipment_free_retry", false)) else ""
	var warmup := GameManager.consume_solo_spool_warmup()
	if warmup > 0: battle.players[0].filament = mini(int(battle.players[0].spool_cap), 3 + warmup)
	battle_last_event = ""
	battle_presentation_serial = 0
	battle_last_actor = 0
	battle_mode = "training"
	trial_encounter_id = ""
	battle_ai_difficulty = str(settings().get("ai_difficulty", "Craftsman"))
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

func _trial_seed(encounter_id: String) -> int:
	var seed := 97
	for byte in encounter_id.to_utf8_buffer(): seed = (seed * 31 + int(byte)) % 2147483647
	return seed

func render_battle_fullscreen(host: Container) -> void:
	if battle == null or not battle.validation_error().is_empty():
		var unavailable := make_panel(Color("19334de8"), Color("ffaaa1"))
		host.add_child(unavailable.get_parent())
		unavailable.add_child(label("Proving Grounds unavailable", 24, Color("ffaaa1")))
		unavailable.add_child(label("Your current team needs a catalog-valid ready print before a training match can begin.", 16, Color("dce8f4")))
		unavailable.add_child(make_button("Return to Workshop", navigate_to.bind("workshop"), Color("536c8d")))
		return
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
	# Do not reserve a blank status row on the first action fold. Errors opt in
	# through _toast(), keeping the visible move dock compact on small portrait.
	status.visible = false
	intro.add_child(status)
	var battle_title := "Proving Grounds"
	if battle_mode == "trial" and not trial_encounter_id.is_empty():
		battle_title += " - Trial: %s" % str(Catalog.workshop_trial_encounter(trial_encounter_id).get("name", "Workshop Trial"))
	intro.add_child(label("%s - %s" % [battle_title, "Your turn" if battle.active_player == 0 else "Rival is thinking"], 22, Color("ffd36c")))
	if not battle_launch_notice.is_empty():
		intro.add_child(label("Lineup notice: " + battle_launch_notice, 13, Color("fff0a1")))
	# An opened tactical panel owns the first fold. Keep the stage compact on both
	# phone and landscape so every visual card can remain fully reachable.
	var compact_secondary := battle_secondary_open
	var stage := _battle_screen_component.refresh(battle.active_unit(0), battle.active_unit(1), battle_last_event, battle_last_actor, bool(settings().get("reduced_motion", false)), 160 if is_portrait_layout() and compact_secondary else (160 if is_portrait_layout() else (64 if compact_secondary else 172)), bool(settings().get("high_contrast", false)), battle_presentation_serial)
	stage.size_flags_vertical = Control.SIZE_FILL if compact_secondary else Control.SIZE_EXPAND_FILL
	_battle_screen_component.attach(intro)
	# Keep the read-only portrait recap above the action dock.  The dock is the
	# last normal-flow child, so changing combat feedback or the battle log cannot
	# walk the primary controls below the visible phone fold on a later render.
	if not battle_secondary_open and is_portrait_layout():
		render_battle_summary(intro)
	if battle.active_player == 0 and not battle.finished:
		render_battle_action_dock(intro)
		render_battle_secondary(intro)
	if battle.finished:
		var outcome := "Victory!" if battle.winner == 0 else "Defeat."
		intro.add_child(label("%s - Core Printer status resolved." % outcome, 22, Color("ffd36c")))
		if battle_mode == "trial" and not trial_encounter_id.is_empty():
			var trial_state := GameManager.campaign_encounter_state(trial_encounter_id)
			var reward: Dictionary = trial_state.get("reward", {})
			intro.add_child(label("Workshop Trial: %s\n%s" % [str(trial_state.get("encounter", {}).get("name", "Encounter")), "Victory claims %d Forge Coins, %d XP, and +%d mastery for each saved team print." % [int(reward.get("coins", 0)), int(reward.get("xp", 0)), int(reward.get("mastery", 0))] if battle.winner == 0 else "Defeats do not grant a Workshop Trial first-clear reward."], 15, Color("a8e3a5") if battle.winner == 0 else Color("ffaaa1")))
		intro.add_child(make_button("Return to Workshop Trials" if battle_mode == "trial" else "Return to Proving Door", finish_battle, Color("536c8d")))
		return
	# Landscape gives that room to the presentation; Details retains the verbose
	# recap there. Portrait renders its compact recap before the terminal dock.
	if battle.active_player == 1 and not battle.finished and not ai_pending:
		ai_pending = true
		var scheduled_state := battle
		var scheduled_generation := battle_session_generation
		if bool(settings().get("reduced_motion", false)):
			call_deferred("run_ai", scheduled_state, scheduled_generation)
		else:
			call_deferred("run_ai_after_presentation", scheduled_state, scheduled_generation)

func render_battle_summary(host: Container) -> void:
	var summary := make_panel(Color("10273ad8"), Color("517b9a"))
	summary.name = "BattleSummary"
	var panel := summary.get_parent() as PanelContainer
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size = Vector2(0, 142)
	host.add_child(panel)
	for player in [1, 0]:
		var unit := battle.active_unit(player)
		var suit_id := str(unit.get("suit_id", ""))
		var max_hp: int = int(unit.get("max_hp", 1))
		var base_hp: int = int(Catalog.creature(str(unit.get("id", ""))).get("hp", max_hp))
		summary.add_child(label(("Rival" if player == 1 else "You") + ": " + str(unit.get("name", "Unknown")) + "  %d/%d HP - %s" % [int(unit.get("hp", 0)), max_hp, str(unit.get("element", "Unknown"))], 16, Color("ffaaa1") if player == 1 else Color("a9ecff")))
		summary.add_child(label("Suit: None" if suit_id.is_empty() else "Suit: %s | +%d maximum HP | %d guard | Core: %s" % [str(unit.get("suit_name", "Full suit")), max_hp - base_hp, int(unit.get("armor", 0)), str(unit.get("core_name", "None"))], 13, Color("f1be69")))
		summary.add_child(label("Filament %d/%d | Attack %d | %s (%d; cd %d)" % [int(battle.players[player].get("filament", 0)), int(battle.players[player].get("spool_cap", 0)), int(unit.get("attack", 0)), str(unit.get("ability", "Signature")), int(unit.get("ability_cost", 0)), int(unit.get("cooldown_remaining", 0))], 13, Color("d9e7f3")))
		summary.add_child(label("Effect: " + Catalog.signature_description(str(unit.get("id", ""))), 12, Color("b9d3e8")))
	# A capped, single-line recap keeps the portrait first fold deterministic as
	# a battle history grows. The full history remains available in Details.
	var log_line := label("Latest: " + str(battle.log.back() if not battle.log.is_empty() else "Battle ready"), 13, Color("d0dfeb"))
	log_line.name = "BattleSummaryLatestEvent"
	log_line.clip_text = true
	log_line.autowrap_mode = TextServer.AUTOWRAP_OFF
	summary.add_child(log_line)

func render_battle_action_dock(host: Container) -> void:
	var dock := make_panel(Color("214969ee"), Color("6de4ff"))
	dock.name = "BattleActionDock"
	var dock_panel := dock.get_parent() as PanelContainer
	dock_panel.custom_minimum_size = Vector2(0, 210 if is_portrait_layout() else 142)
	dock_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(dock_panel)
	var opening_locked := battle.turn == 1 and battle.active_player == 0 and battle.opening_player == 0
	var dock_title := label("Moves - Opening: Defend or End Turn" if opening_locked else "Moves", 16 if opening_locked else 18, Color("fff0a1") if opening_locked else Color("d7f8ff"))
	if opening_locked: dock_title.name = "BattleOpeningGuidance"
	dock.add_child(dock_title)
	var feedback := label(battle_feedback_text(), 14, Color("fff0a1") if not bool(settings().get("high_contrast", false)) else Color.WHITE)
	feedback.name = "BattleImpactBanner"
	# Keep transient impact copy to one predictable dock row. Long-form combat
	# history is preserved in Details instead of resizing touch controls.
	feedback.autowrap_mode = TextServer.AUTOWRAP_OFF
	feedback.clip_text = true
	feedback.custom_minimum_size.y = 20
	dock.add_child(feedback)
	var actions := GridContainer.new()
	actions.name = "BattleActionGrid"
	actions.columns = 2 if is_portrait_layout() else 4
	actions.custom_minimum_size = Vector2(0, 104 if is_portrait_layout() else 48)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	dock.add_child(actions)
	var unit: Dictionary = battle.active_unit(0)
	var attack_value: int = int(unit.get("attack", 0))
	var ability_name := str(unit.get("ability", "Signature"))
	if ability_name.is_empty(): ability_name = "Signature"
	var ability_cost: int = int(unit.get("ability_cost", 0))
	var basic := make_button("Basic Attack (%d)" % attack_value, submit_battle_action.bind("attack"))
	basic.name = "BattleActionBasicAttack"
	basic.custom_minimum_size.y = 48
	basic.disabled = opening_locked
	actions.add_child(basic)
	var ability := make_button("%s (%d FC)" % [ability_name, ability_cost], submit_battle_action.bind("ability"))
	ability.name = "BattleActionSignatureAbility"
	ability.custom_minimum_size.y = 48
	ability.disabled = opening_locked or int(unit.get("cooldown_remaining", 0)) > 0 or int(battle.players[0].get("filament", 0)) < ability_cost
	actions.add_child(ability)
	var defend := make_button("Defend", submit_battle_action.bind("defend"), Color("526e93"))
	defend.name = "BattleActionDefend"
	defend.custom_minimum_size.y = 48
	actions.add_child(defend)
	var end_turn := make_button("End Turn", submit_battle_action.bind("end_turn"), Color("536c8d"))
	end_turn.name = "BattleActionEndTurn"
	end_turn.custom_minimum_size.y = 48
	actions.add_child(end_turn)
	var signature_effect := label("Signature effect: " + Catalog.signature_description(str(unit.get("id", ""))), 12, Color("b9d3e8"))
	signature_effect.name = "BattleSignatureDescription"
	signature_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The card detail itself occupies this explanatory role while the tactical
	# drawer is open. Removing this duplicate line preserves a complete card
	# viewport on a short landscape screen without hiding any move control.
	signature_effect.visible = not battle_secondary_open
	dock.add_child(signature_effect)
	var secondary := make_button("Hide Bench, Hand & Details" if battle_secondary_open else "Bench, Hand & Details", toggle_battle_secondary, Color("536c8d"))
	secondary.name = "BattleSecondaryToggle"
	secondary.custom_minimum_size = Vector2(0, 48)
	dock.add_child(secondary)

func render_battle_secondary(host: Container) -> void:
	if not battle_secondary_open:
		return
	# The Hand keeps its portrait cards intact. Its own vertical touch scroll keeps
	# the large card carousel reachable without pushing the primary move dock off
	# the first fold on a phone or on a short landscape screen.
	var secondary_panel := PanelContainer.new()
	secondary_panel.name = "BattleSecondaryPanel"
	secondary_panel.add_theme_stylebox_override("panel", panel_style(Color("172e43ee"), Color("7bcbe5")))
	secondary_panel.custom_minimum_size = Vector2(0, (282 if is_portrait_layout() else 260) if battle_secondary_tab == "hand" else 160)
	secondary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(secondary_panel)
	# Keep the scroll viewport from advertising its whole card-content height to
	# the outer battle VBox. Otherwise Godot expands the tactical panel below a
	# short landscape frame before it has a chance to scroll it.
	var viewport := Control.new()
	viewport.name = "BattleSecondaryViewport"
	viewport.clip_contents = true
	viewport.custom_minimum_size = Vector2.ZERO
	secondary_panel.add_child(viewport)
	var scroll := TOUCH_SCROLL_CONTAINER.new()
	scroll.name = "BattleSecondaryScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
	scroll.custom_minimum_size = Vector2.ZERO
	viewport.add_child(scroll)
	var panel := VBoxContainer.new()
	panel.name = "BattleSecondaryContent"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)
	scroll.add_child(panel)
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
		if int(bench_unit.get("hp", 0)) > 0:
			var switch_button := make_button("Switch %s" % str(bench_unit.get("name", "Unknown")), submit_battle_switch.bind(bench_index))
			switch_button.name = "BattleSwitch%s" % str(bench_unit.get("id", "Unknown"))
			switches.add_child(switch_button)
			switch_count += 1
	if switch_count == 0:
		switches.add_child(label("No healthy bench prints.", 14, Color("b9cad7")))

func render_battle_hand_tab(panel: Container) -> void:
	panel.add_child(label("Hand — Deck %d | Discard %d" % [battle.players[0].deck.size(), battle.players[0].get("discard", []).size()], 16, Color("9beaff")))
	var cards := GridContainer.new()
	cards.name = "BattleHandGrid"
	cards.columns = 4
	cards.add_theme_constant_override("h_separation", 8)
	cards.add_theme_constant_override("v_separation", 8)
	# Portrait cards stay portrait at every device size. A bounded horizontal
	# carousel protects their readable rules/target copy instead of flattening
	# four cards into landscape info tiles.
	var carousel := ScrollContainer.new()
	carousel.name = "BattleHandCarousel"
	carousel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	carousel.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	carousel.custom_minimum_size = Vector2(0, 238)
	carousel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(carousel)
	carousel.add_child(cards)
	var counts := {}
	for raw_id in battle.players[0].hand: counts[str(raw_id)] = int(counts.get(str(raw_id), 0)) + 1
	for card_id in counts:
		var definition := Catalog.support_card(str(card_id))
		var reason := SupportCardRules.legality_reason(battle, 0, definition)
		var card := SUPPORT_CARD_VIEW.new(); card.configure(definition, int(counts[card_id]), reason, false, true); card.pressed.connect(submit_battle_card.bind(str(card_id)))
		card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		card.name = "BattleCard%s" % str(card_id).capitalize()
		cards.add_child(card)
	cards.custom_minimum_size = Vector2(maxi(1, counts.size()) * 158, 225)

func submit_battle_card(card_id: String) -> void:
	_audio_director.cue("card")
	intent({"type":"card","card_id":card_id})

func battle_feedback_text() -> String:
	return BATTLE_FEEDBACK_PRESENTER.format(battle, battle_last_event, _audio_director.last_caption)

func render_battle_details_tab(panel: Container) -> void:
	for player in [1, 0]:
		var unit := battle.active_unit(player)
		var suit_id := str(unit.get("suit_id", ""))
		var max_hp: int = int(unit.get("max_hp", 1))
		var base_hp: int = int(Catalog.creature(str(unit.get("id", ""))).get("hp", max_hp))
		panel.add_child(label(("Rival" if player == 1 else "You") + ": " + str(unit.get("name", "Unknown")) + "  %d/%d HP - %s" % [int(unit.get("hp", 0)), max_hp, str(unit.get("element", "Unknown"))], 15, Color("ffaaa1") if player == 1 else Color("a9ecff")))
		panel.add_child(label("Suit: None" if suit_id.is_empty() else "Suit: %s | +%d maximum HP | %d guard | Core: %s" % [str(unit.get("suit_name", "Full suit")), max_hp - base_hp, int(unit.get("armor", 0)), str(unit.get("core_name", "None"))], 13, Color("f1be69")))
		panel.add_child(label("Filament %d/%d | Attack %d | %s (%d; cd %d)" % [int(battle.players[player].get("filament", 0)), int(battle.players[player].get("spool_cap", 0)), int(unit.get("attack", 0)), str(unit.get("ability", "Signature")), int(unit.get("ability_cost", 0)), int(unit.get("cooldown_remaining", 0))], 13, Color("d9e7f3")))
		panel.add_child(label("Signature effect: " + Catalog.signature_description(str(unit.get("id", ""))), 12, Color("b9d3e8")))
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

func submit_battle_action(action_type: String) -> void:
	intent({"type":action_type})

func submit_battle_switch(bench_index: int) -> void:
	intent({"type":"switch", "index":bench_index})

func finish_battle() -> void:
	if battle == null or not battle.finished: return
	var finished_state: BattleState = battle
	var finished_mode := battle_mode
	var finished_trial := trial_encounter_id
	var won: bool = battle.winner == 0
	var turns: int = battle.turn
	battle_session_generation += 1
	ai_pending = false
	battle = null
	battle_mode = "training"
	trial_encounter_id = ""
	battle_ai_difficulty = str(settings().get("ai_difficulty", "Craftsman"))
	screen = "trials" if finished_mode == "trial" else "proving"
	if finished_mode == "trial" and won and not finished_trial.is_empty():
		if not GameManager.claim_campaign_victory(finished_trial, turns): render()
	elif finished_mode == "training":
		if not GameManager.claim_battle_reward(finished_state): render()
	else:
		render()

func intent(action: Dictionary) -> void:
	if str(action.get("type", "")) != "concede": battle_concede_armed = false
	var result := BattleRules.apply_intent(battle, 0, action)
	if not result.ok: _toast(str(result.error))
	else:
		if str(action.get("type", "")) == "card":
			var card_definition := Catalog.support_card(str(result.get("card_id", "")))
			_audio_director.cue_card(str(card_definition.get("name", "Support Card")), SUPPORT_CARD_PRESENTER.effect_text(card_definition))
			battle_last_event = "card:" + str(result.get("card_id", ""))
		else: _audio_director.cue("impact")
		battle_concede_armed = false
		if str(action.get("type", "")) != "card": battle_last_event = str(action.get("type", ""))
		battle_last_actor = 0
		battle_presentation_serial += 1
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

func run_ai_after_presentation(expected_state: BattleState, expected_generation: int) -> void:
	await get_tree().create_timer(0.5).timeout
	if expected_state != battle or expected_generation != battle_session_generation or screen != "battle":
		return
	ai_pending = false
	if battle.active_player == 1 and not battle.finished:
		run_ai(expected_state, expected_generation)

func run_ai(expected_state: BattleState = null, expected_generation := -1) -> void:
	if expected_state != null and (expected_state != battle or expected_generation != battle_session_generation or screen != "battle"):
		return
	ai_pending = false
	if battle == null or screen != "battle" or battle.active_player != 1 or battle.finished: return
	var applied := AIOpponent.choose_intent(battle, battle_ai_difficulty)
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
		battle_presentation_serial += 1
	render()

func _toast(message: String) -> void:
	if status:
		status.visible = not message.is_empty()
		status.text = message
