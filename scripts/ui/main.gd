extends Control
## Reference-driven workshop presentation; final character art remains approval-gated.
const REFERENCE_TEXTURE := preload("res://docs/art/reference/workshop-theme-reference.jpg")
const ELEMENT_COLORS := {"Fire":"f17e5b", "Water":"5fb9f5", "Lightning":"efd862", "Nature":"7bcf89", "Ice":"a5ecff", "Stone":"b7a48b", "Wind":"a6d7c8"}

var screen := "workshop"
var pending_starter_id := ""
var shop_day_key := ""
var team_draft: Array = []
var deck_draft: Array = []
var battle: BattleState
var body: VBoxContainer
var status: Label
var battle_last_event := ""
var battle_last_actor := 0
var ai_pending := false
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

func settings() -> Dictionary:
	return GameManager.profile.get("settings", AccessibilityRules.defaults())

func scaled_font(base: int) -> int:
	return maxi(12, (base * int(settings().get("text_scale_bps", 10000))) / 10000)

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
		# Containers perform the responsive layout; redraw only the decorative background.
		queue_redraw()

func _process(delta: float) -> void:
	if printer_capture_freeze: return
	if screen != "printer" or printer_sequence == null: return
	if printer_sequence.phase not in [ArcaneForgeSequence.PRINTING, ArcaneForgeSequence.AWAKENING]: return
	if not printer_sequence.reduced_motion: printer_presentation_seconds += delta
	printer_tick_accumulator += delta
	if printer_tick_accumulator < ArcaneForgeSequence.presentation_interval_seconds(printer_sequence.reduced_motion): return
	printer_tick_accumulator = 0.0
	printer_sequence.advance(ArcaneForgeSequence.presentation_step_bps(printer_sequence.reduced_motion))
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE: _commit_printer_once()
	render()

func navigate_to(target: String) -> void:
	screen = target
	render()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and screen == "printer":
		if printer_sequence != null and printer_sequence.phase == ArcaneForgeSequence.IDLE:
			printer_sequence.cancel()
			printer_creature_id = ""
			screen = "collection"
			render()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and screen != "onboarding" and screen != "workshop":
		screen = "workshop"
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
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	render_header(root)
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
	header_box.custom_minimum_size = Vector2(0, 90)
	header_box.add_theme_stylebox_override("panel", panel_style(Color("142840eb"), Color("f1be69")))
	root.add_child(header_box)
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 64)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 16)
	header_box.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.custom_minimum_size = Vector2(560, 58)
	header.add_child(titles)
	titles.add_child(label("PRINTFORGE LEGENDS", 29, Color("ffd36c")))
	titles.add_child(label("Makers Guild Workshop", 14, Color("9beaff")))
	if GameManager.has_selected_starter():
		var account := label("Forge Coins  %d\nSpool  %d / 10" % [int(GameManager.profile.coins), GameManager.filament_cap()], 16, Color("d6f7ff"))
		account.custom_minimum_size = Vector2(190, 58)
		account.autowrap_mode = TextServer.AUTOWRAP_OFF
		account.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		account.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(account)
	else:
		var ceremony := label("AWAKENING CEREMONY", 15, Color("fff0a1"))
		ceremony.custom_minimum_size = Vector2(220, 58)
		ceremony.autowrap_mode = TextServer.AUTOWRAP_OFF
		ceremony.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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

func render_workshop() -> void:
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

func start_local_vs() -> void:
	var team := GameManager.current_team_loadout()
	if team.is_empty(): _toast("Choose a starter before starting local versus."); return
	local_authority = LocalBattleAuthority.create(team, ["mossmunk", "voltwig"], GameManager.active_deck_cards(), 20260814)
	local_ready_seat = -1
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
		panel.add_child(label("Private handoff", 20, Color("fff0a1")))
		panel.add_child(label("Pass the device. The next hand remains hidden until the ready button is pressed.", 16, Color("dce8f4")))
		panel.add_child(make_button("Ready Player %d" % (seat + 1), func(): local_ready_seat = seat; render(), Color("a86b2e")))
		panel.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d"))); return
	var stage := BattleSpriteStage.new(); stage.configure(state.active_unit(0), state.active_unit(1), battle_last_event, battle_last_actor, bool(settings().get("reduced_motion", false))); panel.add_child(stage); stage.custom_minimum_size = Vector2(0, 120)
	for player in [0, 1]:
		var unit := state.active_unit(player)
		panel.add_child(label("Player %d: %s  %d/%d HP - %s" % [player + 1, str(unit.name), int(unit.hp), int(unit.max_hp), str(unit.element)], 17, Color("a9ecff") if player == 0 else Color("ffaaa1")))
	if state.finished:
		panel.add_child(label("Local match complete. No Forge Coins or rewards are granted.", 18, Color("fff0a1")))
		panel.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d"))); return
	panel.add_child(label("Player %d hand: %s" % [seat + 1, ", ".join(state.players[seat].hand)], 15, Color("dce8f4")))
	var actions := HBoxContainer.new(); actions.add_theme_constant_override("separation", 8); body.add_child(actions)
	for action in [{"type":"attack","name":"Basic Attack"},{"type":"ability","name":"Signature Ability"},{"type":"defend","name":"Defend"},{"type":"end_turn","name":"End Turn"}]:
		actions.add_child(make_button(str(action.name), func(): submit_local_intent({"type":action.type}), Color("2f93a8")))
	var card_counts := {}
	for card_id in state.players[seat].hand: card_counts[str(card_id)] = int(card_counts.get(str(card_id), 0)) + 1
	for card_id in card_counts:
		body.add_child(make_button("Play %s x%d" % [str(card_id).replace("_", " ").capitalize(), int(card_counts[card_id])], func(): submit_local_intent({"type":"card","card_id":card_id}), Color("526e93")))
	var navigation := HBoxContainer.new(); navigation.add_theme_constant_override("separation", 8); body.add_child(navigation)
	for index in state.players[seat].team.size():
		if index != int(state.players[seat].active) and int(state.players[seat].team[index].hp) > 0:
			navigation.add_child(make_button("Switch to %s" % str(state.players[seat].team[index].name), func(): submit_local_intent({"type":"switch","index":index}), Color("4d7898")))
	navigation.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func submit_local_intent(intent: Dictionary) -> void:
	if local_authority == null: return
	var seat := local_authority.state.active_player
	var result := local_authority.submit({"seat":seat,"expected_revision":local_authority.revision,"intent":intent})
	if not bool(result.ok): _toast(str(result.error)); return
	battle_last_event = str(intent.type); battle_last_actor = seat; local_ready_seat = -1; render()

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
	stage.set_preview_phase(printer_sequence.phase, printer_sequence.progress_bps)
	stage.set_presentation_time(printer_presentation_seconds)
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
		ArcaneForgeSequence.AWAKENING:
			panel.add_child(label("Filament awakening in progress. The new print is already safely recorded.", 16, Color("9beaff")))
			panel.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.AWAKENED:
			panel.add_child(label("Welcome, %s! Your living print is ready for the Collection." % str(definition.name), 20, Color("a8e3a5")))
			panel.add_child(make_button("Print Another", navigate_to.bind("collection"), Color("a86b2e")))
			panel.add_child(make_button("Return to Workshop", navigate_to.bind("workshop"), Color("536c8d")))
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
	screen = "collection"
	render()

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

func render_armor() -> void:
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

func render_deck() -> void:
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
	battle = BattleState.create(player_team, ["mossmunk"], GameManager.filament_cap(), 3, int(Time.get_ticks_msec()), GameManager.active_deck_cards())
	battle_last_event = ""
	battle_last_actor = 0
	screen = "battle"
	render()

func render_battle() -> void:
	var intro := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(intro.get_parent())
	intro.add_child(label("Proving Grounds — %s" % ("Your turn" if battle.active_player == 0 else "Rival is thinking"), 24, Color("ffd36c")))
	var stage := BattleSpriteStage.new()
	stage.configure(battle.active_unit(0), battle.active_unit(1), battle_last_event, battle_last_actor, bool(settings().get("reduced_motion", false)))
	intro.add_child(stage)
	for player in [1, 0]:
		var unit := battle.active_unit(player)
		var armor_id := str(unit.get("armor_id", ""))
		var base_hp: int = int(Catalog.creature(str(unit.id)).get("hp", unit.max_hp))
		intro.add_child(label(("Rival" if player == 1 else "You") + ": " + str(unit.name) + "  %d/%d HP  •  %s" % [int(unit.hp), int(unit.max_hp), str(unit.element)], 18, Color("ffaaa1") if player==1 else Color("a9ecff")))
		intro.add_child(label("Armor: None" if armor_id.is_empty() else "Armor: %s | +%d maximum HP | %d guard" % [str(unit.get("armor_name", "Unarmored")), int(unit.max_hp) - base_hp, int(unit.get("armor", 0))], 14, Color("f1be69")))
		intro.add_child(label("Filament %d/%d | Attack %d | %s (%d; cd %d)" % [int(battle.players[player].filament), int(battle.players[player].spool_cap), int(unit.attack), str(unit.ability), int(unit.ability_cost), int(unit.cooldown_remaining)], 14, Color("d9e7f3")))
	if battle.finished:
		intro.add_child(label("%s — Core Printer status resolved." % ("Victory!" if battle.winner == 0 else "Defeat."), 24, Color("ffd36c")))
		intro.add_child(make_button("Return to Workshop", func(): GameManager.claim_battle_reward(battle); screen="workshop"; render()))
		return
	if battle.active_player == 0:
		var actions := HBoxContainer.new(); actions.add_theme_constant_override("separation", 8); body.add_child(actions)
		actions.add_child(make_button("Basic Attack", func(): intent({"type":"attack"})))
		actions.add_child(make_button("Signature Ability", func(): intent({"type":"ability"})))
		actions.add_child(make_button("Defend", func(): intent({"type":"defend"})))
		actions.add_child(make_button("End Turn", func(): intent({"type":"end_turn"}), Color("536c8d")))
		var switches := HBoxContainer.new(); body.add_child(switches); switches.add_child(label("Bench:",15))
		for bench_index in battle.players[0].team.size():
			if bench_index == int(battle.players[0].active): continue
			var bench_unit: Dictionary = battle.players[0].team[bench_index]
			if int(bench_unit.hp) > 0: switches.add_child(make_button("Switch %s" % str(bench_unit.name), func(): intent({"type":"switch","index":bench_index})))
		var cards := HBoxContainer.new(); body.add_child(cards); cards.add_child(label("Hand:",15))
		for card_id in battle.players[0].hand: cards.add_child(make_button(str(card_id).replace("_", " ").capitalize(), func(): intent({"type":"card","card_id":card_id}), Color("526e93")))
	body.add_child(label("Battle log\n" + "\n".join(battle.log.slice(maxi(0, battle.log.size()-5))), 14, Color("d0dfeb")))
	if battle.active_player == 1 and not battle.finished and not ai_pending:
		ai_pending = true
		call_deferred("run_ai" if bool(settings().get("reduced_motion", false)) else "run_ai_after_presentation")

func intent(action: Dictionary) -> void:
	var result := BattleRules.apply_intent(battle, 0, action)
	if not result.ok: _toast(str(result.error))
	else:
		battle_last_event = str(action.get("type", ""))
		battle_last_actor = 0
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
