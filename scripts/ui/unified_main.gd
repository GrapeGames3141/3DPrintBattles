extends Control
## Deliberately compact, viewport-first playtest shell. It has no ScrollContainer:
## all collection surfaces page at a layout-derived capacity.
const RULES := preload("res://scripts/core/unified_rules.gd")
const BATTLE := preload("res://scripts/battle/unified_battle_state.gd")
const BATTLE_RULES := preload("res://scripts/battle/unified_battle_rules.gd")
const UNIFIED_AI := preload("res://scripts/battle/unified_ai_opponent.gd")
var screen := "onboarding"
var selected_starter := ""
var page := 0
var battle_hand_page := 0
var printer_upgrade_page := 0
var inspector_id := ""
var inspector_tab := "card"
var deck_draft: Array = []
var printer_upgrade_draft: Array = []
var battle: UnifiedBattleState
var battle_mode := "daily"
var battle_settlement_context: Dictionary = {}
var battle_settlement_finished := false
var ai_turn_pending := false
var toast := ""
var local_handoff_pending := false
var local_handoff_seat := 0
# A target is never inferred from a board position. -2 means unselected;
# -1 is the explicitly chosen printer target; 0..2 are board slots.
var selected_hand_card := ""
var selected_play_slot := -2
var selected_play_target := -2
var selected_attack_slot := -1
var selected_attack_target := -2
# The model's arriving flag can remain true until a later turn. These keys
# consume the visual event once, so rebuilding a responsive screen does not
# replay the same walk-on animation.
var arrival_presented: Dictionary = {}
var battle_printer_controls: Dictionary = {}
var battle_slot_controls: Dictionary = {}

func _ready() -> void:
	GameManager.profile_changed.connect(render); GameManager.toast_requested.connect(func(message): toast = message; render())
	screen = "onboarding" if str(GameManager.profile.get("onboarding", {}).get("state", "choose_starter")) == "choose_starter" else "workshop"
	render()
	print("PRINTFORGE_STARTUP marker=ui_ready screen=%s renderer=%s" % [screen, RenderingServer.get_current_rendering_method()])
	call_deferred("_emit_first_frame_marker")
func _emit_first_frame_marker() -> void:
	await get_tree().process_frame
	print("PRINTFORGE_STARTUP marker=first_frame screen=%s viewport=%dx%d" % [screen, int(size.x), int(size.y)])
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree(): render()
func portrait() -> bool: return size.y > size.x
func page_size() -> int: return 4 if portrait() else 8
func clear() -> VBoxContainer:
	for child in get_children(): child.queue_free()
	battle_printer_controls.clear()
	battle_slot_controls.clear()
	var root := VBoxContainer.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_theme_constant_override("separation", 8); add_child(root)
	return root
func render() -> void:
	var root := clear()
	match screen:
		"onboarding": render_onboarding(root)
		"workshop": render_workshop(root)
		"market": render_market(root)
		"library": render_library(root)
		"deck": render_deck(root)
		"upgrades": render_upgrades(root)
		"settings": render_settings(root)
		"battle": render_battle(root)
	if not toast.is_empty():
		var notice := Label.new(); notice.text = toast; notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; notice.add_theme_color_override("font_color", Color("fff0a1")); root.add_child(notice)
	if screen == "battle" and battle != null:
		call_deferred("_present_pending_arrivals")
func header(root: VBoxContainer, caption: String, back := "") -> void:
	var row := HBoxContainer.new(); root.add_child(row)
	if not back.is_empty(): row.add_child(button("‹", func(): screen = back; page = 0; render(), Color("536c8d")))
	var title := Label.new(); title.text = caption; title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.add_theme_font_size_override("font_size", 24); title.add_theme_color_override("font_color", Color("8deaff")); row.add_child(title)
	var coins := Label.new(); coins.text = "◈ %d  XP %d" % [int(GameManager.profile.get("coins", 0)), int(GameManager.profile.get("forge_xp", 0))]; coins.add_theme_color_override("font_color", Color("ffd36c")); row.add_child(coins)
func panel() -> VBoxContainer:
	var outer := PanelContainer.new(); outer.add_theme_stylebox_override("panel", style(Color("142b42e8"), Color("4d7898"))); var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 6); outer.add_child(box); return box
func style(bg: Color, border: Color) -> StyleBoxFlat:
	var out := StyleBoxFlat.new(); out.bg_color = bg; out.border_color = border; out.set_border_width_all(2); out.corner_radius_top_left = 10; out.corner_radius_top_right = 10; out.corner_radius_bottom_left = 10; out.corner_radius_bottom_right = 10; out.content_margin_left = 10; out.content_margin_right = 10; out.content_margin_top = 8; out.content_margin_bottom = 8; return out
func label(text_value: String, small := false) -> Label:
	var scale := float(GameManager.profile.get("settings", {}).get("text_scale_bps", 10000)) / 10000.0
	var out := Label.new(); out.text = text_value; out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; out.add_theme_font_size_override("font_size", int((14 if small else 17) * scale)); out.add_theme_color_override("font_color", Color("ffffff") if bool(GameManager.profile.get("settings", {}).get("high_contrast", false)) else Color("dce8f4")); return out
func button(text_value: String, action: Callable, tint := Color("2f93a8")) -> Button:
	var out := Button.new(); out.text = text_value; out.custom_minimum_size = Vector2(0, 38); out.add_theme_stylebox_override("normal", style(tint, Color("a8edff"))); out.pressed.connect(action); return out
func add_grid(root: VBoxContainer, cards: Array, callback: Callable) -> void:
	var grid := GridContainer.new(); grid.columns = 2 if portrait() else 4; grid.size_flags_vertical = Control.SIZE_EXPAND_FILL; root.add_child(grid)
	var start := page * page_size()
	for i in range(start, mini(start + page_size(), cards.size())): grid.add_child(card_button(cards[i], callback))
	var nav := HBoxContainer.new(); nav.alignment = BoxContainer.ALIGNMENT_CENTER; root.add_child(nav)
	var pages := maxi(1, int(ceil(float(cards.size()) / float(page_size())))); nav.add_child(button("‹", func(): page = posmod(page - 1, pages); render(), Color("536c8d"))); nav.add_child(label("%d / %d" % [page + 1, pages], true)); nav.add_child(button("›", func(): page = posmod(page + 1, pages); render(), Color("536c8d")))
func card_button(definition: Dictionary, callback: Callable) -> Button:
	var out := Button.new(); out.custom_minimum_size = Vector2(0, 122); out.tooltip_text = "Open card"; var owned := int(GameManager.profile.get("owned_cards", {}).get(str(definition.id), 0)); out.text = "%s\n%s  •  %s\n×%d" % [str(definition.name), str(definition.get("type", "card")).capitalize(), str(definition.get("rarity", "common")).capitalize(), owned]; out.add_theme_stylebox_override("normal", style(Color("17394e"), Color(Catalog.rarity(str(definition.get("rarity", "common"))).get("color", "69a7ff")))); out.pressed.connect(callback.bind(str(definition.id))); return out

func render_onboarding(root: VBoxContainer) -> void:
	header(root, "Choose a starter")
	root.add_child(label("Pick a print. Tap it for base stats."))
	var portraits := HBoxContainer.new(); root.add_child(portraits)
	for id in RULES.STARTER_IDS:
		var portrait := TextureRect.new(); portrait.texture = load(str(RULES.card(id).get("sprite_sheet", ""))); portrait.custom_minimum_size = Vector2(120, 120); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; portraits.add_child(portrait)
	var choices: Array = []
	for id in RULES.STARTER_IDS: choices.append(RULES.card(id))
	add_grid(root, choices, func(id): selected_starter = id; inspector_id = id; inspector_tab = "card"; render())
	if not selected_starter.is_empty(): root.add_child(button("Choose %s" % str(RULES.card(selected_starter).name), func(): GameManager.choose_starter(selected_starter); screen = "workshop"; render(), Color("3c76bf")))
	if not inspector_id.is_empty(): render_inspector(root)
func render_workshop(root: VBoxContainer) -> void:
	header(root, "Workshop")
	var state := str(GameManager.profile.get("onboarding", {}).get("state", "choose_starter"))
	if state == "starter_selected":
		var starter := str(GameManager.profile.onboarding.get("starter_id", "")); root.add_child(label("Blue blueprint ×3 ready. Print your first %s free." % str(RULES.card(starter).name))); root.add_child(button("Print starter", func(): GameManager.print_selected_starter(), Color("3c76bf"))); return
	root.add_child(label("Build cards, tune the printer, then take your deck to battle."))
	var actions := GridContainer.new(); actions.columns = 2; root.add_child(actions)
	for item in [["Market","market"],["My cards","library"],["Deck builder","deck"],["Printer grid","upgrades"],["Battle","battle"],["Settings","settings"]]: actions.add_child(button(str(item[0]), func(): screen = str(item[1]); page = 0; render()))

func render_settings(root: VBoxContainer) -> void:
	header(root, "Settings", "workshop")
	var values: Dictionary = GameManager.profile.get("settings", {})
	root.add_child(label("Text and motion controls apply immediately to the unified playtest."))
	root.add_child(button("Text scale: %d%%" % (int(values.get("text_scale_bps", 10000)) / 100), func(): GameManager.save_settings({"text_scale_bps": 12500 if int(values.get("text_scale_bps", 10000)) == 10000 else 10000}); render()))
	root.add_child(button("High contrast: %s" % ("On" if bool(values.get("high_contrast", false)) else "Off"), func(): GameManager.save_settings({"high_contrast": not bool(values.get("high_contrast", false))}); render()))
	root.add_child(button("Reduced motion: %s" % ("On" if bool(values.get("reduced_motion", false)) else "Off"), func(): GameManager.save_settings({"reduced_motion": not bool(values.get("reduced_motion", false))}); render()))
	var status := panel(); root.add_child(status.get_parent()); status.add_child(label("Spool %d  •  Collector %d  •  Workshop filament %d" % [_spool_cap(), _collector_cap(), int(GameManager.profile.get("workshop_filament", 0))], true))
func render_market(root: VBoxContainer) -> void:
	header(root, "Market", "workshop"); root.add_child(label("Packs only. Every slot rolls independently; duplicates are possible."))
	var products := [{"id":"pack_3","name":"3-card pack","price":60},{"id":"pack_5","name":"5-card pack","price":90},{"id":"pack_10","name":"10-card pack","price":160}]
	for product in products:
		root.add_child(button("%s  •  %d Forge Coins" % [product.name, product.price], buy_pack.bind(str(product.id)), Color("a86b2e")))
	root.add_child(label("Odds use catalog rarity weights. No pity or guaranteed rarity.", true))
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {}) if GameManager.profile.get("pending_pack_reveal", {}) is Dictionary else {}
	if not pending.is_empty(): root.add_child(button("Reveal %d cards" % (pending.get("cards", []) as Array).size(), func(): toast = "Found: " + ", ".join(GameManager.claim_pending_pack_reveal()); render(), Color("3c76bf")))
func render_library(root: VBoxContainer) -> void:
	header(root, "My cards", "workshop"); root.add_child(label("Owned cards only. Tap a card for a full-screen build view."))
	var owned: Array = []
	for definition in RULES.all_cards():
		if int(GameManager.profile.get("owned_cards", {}).get(str(definition.id), 0)) > 0: owned.append(definition)
	add_grid(root, owned, func(id): inspector_id = id; inspector_tab = "card"; render())
	if not inspector_id.is_empty(): render_inspector(root)
func render_deck(root: VBoxContainer) -> void:
	header(root, "Deck builder", "workshop")
	if deck_draft.is_empty():
		for deck in GameManager.profile.get("decks", []): if str(deck.get("id", "")) == str(GameManager.profile.get("active_deck_id", "starter-deck")): deck_draft = deck.get("cards", []).duplicate()
	root.add_child(label("%d / 15 cards • %d creatures • max three copies" % [deck_draft.size(), _creature_count(deck_draft)], true))
	var owned: Array = []
	for definition in RULES.all_cards():
		if int(GameManager.profile.get("owned_cards", {}).get(str(definition.id), 0)) > 0: owned.append(definition)
	add_grid(root, owned, func(id): _toggle_deck(id))
	root.add_child(button("Save battle deck", func(): GameManager.save_unified_deck(deck_draft); toast = "Deck saved."; render(), Color("588d73")))
func _toggle_deck(id: String) -> void:
	if id in deck_draft: deck_draft.erase(id)
	elif deck_draft.size() < 15 and deck_draft.count(id) < mini(3, int(GameManager.profile.owned_cards.get(id, 0))): deck_draft.append(id)
	render()
func _creature_count(cards: Array) -> int:
	var total := 0
	for id in cards:
		if str(RULES.card(str(id)).get("type", "")) == "creature": total += 1
	return total
func render_upgrades(root: VBoxContainer) -> void:
	header(root, "Printer grid", "workshop"); root.add_child(label("Select linked nodes, then apply once. Respec is free outside battle."))
	if printer_upgrade_draft.is_empty(): printer_upgrade_draft = GameManager.profile.get("printer_nodes", []).duplicate()
	var selected: Array = printer_upgrade_draft
	var new_cost := 0
	var refund := 0
	for node_id in selected:
		if node_id not in GameManager.profile.get("printer_nodes", []): new_cost += int(RULES.PRINTER_NODES.get(node_id, {}).get("cost", 0))
	for node_id in GameManager.profile.get("printer_nodes", []):
		if node_id not in selected: refund += int(RULES.PRINTER_NODES.get(node_id, {}).get("cost", 0))
	root.add_child(label("Draft %d nodes • Net %d XP (cost %d, refund %d)" % [selected.size(), new_cost - refund, new_cost, refund], true))
	var ids: Array = RULES.PRINTER_NODES.keys()
	var per_page := 4 if portrait() else 6
	var pages := maxi(1, int(ceil(float(ids.size()) / float(per_page))))
	printer_upgrade_page = clampi(printer_upgrade_page, 0, pages - 1)
	var grid := GridContainer.new(); grid.columns = 1 if portrait() else 2; root.add_child(grid)
	for id in ids.slice(printer_upgrade_page * per_page, mini((printer_upgrade_page + 1) * per_page, ids.size())):
		var node: Dictionary = RULES.PRINTER_NODES[id]
		var on := str(id) in selected
		grid.add_child(button(("✓ " if on else "○ ") + str(id).replace("_", " ") + "  %d XP" % int(node.cost), toggle_printer_node.bind(str(id)), Color("588d73") if on else Color("526e93")))
	var nav := HBoxContainer.new(); nav.alignment = BoxContainer.ALIGNMENT_CENTER; root.add_child(nav)
	nav.add_child(button("‹", func(): printer_upgrade_page = posmod(printer_upgrade_page - 1, pages); render(), Color("536c8d")))
	var page_indicator := label("%d / %d" % [printer_upgrade_page + 1, pages], true); page_indicator.autowrap_mode = TextServer.AUTOWRAP_OFF; nav.add_child(page_indicator)
	nav.add_child(button("›", func(): printer_upgrade_page = posmod(printer_upgrade_page + 1, pages); render(), Color("536c8d")))
	root.add_child(button("Apply upgrades", apply_printer_draft, Color("588d73")))
	root.add_child(button("Free respec (+refund)", func(): printer_upgrade_draft = []; GameManager.respec_printer_upgrades(), Color("536c8d")))
func render_battle(root: VBoxContainer) -> void:
	# The battlefield deliberately gets a tighter rhythm than collection pages so
	# all actionable controls remain in a phone viewport without a scroll surface.
	root.add_theme_constant_override("separation", 4)
	header(root, "Battle", "workshop")
	var background := TextureRect.new()
	background.texture = load(_battle_background_path())
	background.custom_minimum_size = Vector2(0, 64 if portrait() else 150)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(background)
	if battle == null:
		var deck := deck_draft
		if deck.is_empty():
			for saved in GameManager.profile.get("decks", []):
				if str(saved.get("id", "")) == str(GameManager.profile.get("active_deck_id", "starter-deck")): deck = saved.get("cards", []).duplicate()
		if RULES.deck_reason(GameManager.profile, deck).is_empty():
			root.add_child(label("Choose a battle. Trial tiers select their own arena."))
			var modes := GridContainer.new(); modes.columns = 2 if portrait() else 3; root.add_child(modes)
			for choice in [["Daily Training", "daily"], ["First Layers", "trial_first_layers"], ["Element Bench", "trial_element_bench"], ["Reinforced Run", "trial_reinforced_run"], ["Masterwork Circuit", "trial_masterwork_circuit"], ["Primordial Proof", "trial_primordial_proof"], ["Local Versus", "local"]]: modes.add_child(button(str(choice[0]), start_mode.bind(str(choice[1]))))
			return
		else:
			root.add_child(label("Build a legal 15-card deck first."))
			return
	var foe := battle.player(1)
	var mine := battle.player(0)
	root.add_child(label("TURN %d  •  %s" % [battle.turn, battle.phase.to_upper()]))
	root.add_child(_battle_side("RIVAL", foe, 1))
	root.add_child(_battle_side("YOU", mine, 0))
	if battle_mode == "local" and local_handoff_pending:
		root.add_child(label("Pass device to Player %d. Their hand is concealed." % (local_handoff_seat + 1)))
		root.add_child(button("Ready Player %d" % (local_handoff_seat + 1), func(): local_handoff_pending = false; render(), Color("3c76bf")))
	elif not battle.finished:
		var active := battle.player(battle.active_seat)
		if ai_turn_pending:
			root.add_child(label("Rival printer is acting...", true))
			return
		root.add_child(label("Player %d hand · choose a card, then its legal target." % (battle.active_seat + 1), true))
		var hand := GridContainer.new()
		hand.columns = 2 if portrait() else 4
		root.add_child(hand)
		var hand_pages := maxi(1, int(ceil(float(active.hand.size()) / float(page_size())))); battle_hand_page = clampi(battle_hand_page, 0, hand_pages - 1)
		for id in active.hand.slice(battle_hand_page * page_size(), mini((battle_hand_page + 1) * page_size(), active.hand.size())):
			var selected := str(id) == selected_hand_card
			hand.add_child(button(("✓ " if selected else "") + str(RULES.card(str(id)).get("name", id)), select_hand_card.bind(str(id)), Color("588d73") if selected else Color("3c76bf")))
		var hand_nav := HBoxContainer.new(); hand_nav.alignment = BoxContainer.ALIGNMENT_CENTER; root.add_child(hand_nav)
		hand_nav.add_child(button("‹", func(): battle_hand_page = posmod(battle_hand_page - 1, hand_pages); render(), Color("536c8d")))
		var hand_indicator := label("Hand %d / %d" % [battle_hand_page + 1, hand_pages], true); hand_indicator.autowrap_mode = TextServer.AUTOWRAP_OFF; hand_nav.add_child(hand_indicator)
		hand_nav.add_child(button("›", func(): battle_hand_page = posmod(battle_hand_page + 1, hand_pages); render(), Color("536c8d")))
		_render_play_target_picker(root, active)
		_render_attack_target_picker(root, active)
		var controls := HBoxContainer.new()
		root.add_child(controls)
		controls.add_child(button("Collect", func(): _battle_intent({"type":"collect","pile":0}, battle.active_seat), Color("588d73")))
		if battle.phase == "collect" and "clip_smelter" in active.nodes: controls.add_child(button("Smelt %d%s" % [int(active.collector), " to spool" if "spooler" in active.nodes else " reserve"], func(): _battle_intent({"type":"smelt"}, battle.active_seat), Color("a86b2e")))
		controls.add_child(button("Next phase", func(): _battle_intent({"type":"advance_phase"}, battle.active_seat), Color("536c8d")))
	if battle.finished:
		root.add_child(label("%s printer broke." % ("Rival" if battle.winner == 0 else "Your")))
		if not battle_settlement_context.is_empty() and not battle_settlement_finished:
			root.add_child(label("Settling %s result..." % str(battle_settlement_context.get("mode", "battle")), true))
			battle_settlement_finished = true
			call_deferred("_settle_finished_unified_battle")
		else:
			root.add_child(button("Return", func(): battle = null; battle_settlement_context = {}; screen = "workshop"; render()))
func _battle_side(name: String, p: Dictionary, seat: int) -> Control:
	var box := panel()
	box.add_child(label("%s • P %d • F %d/%d • C %d/%d" % [name, int(p.printer.durability), int(p.filament), int(p.spool_cap), int(p.collector), int(p.collector_cap)], true))
	var field := HBoxContainer.new()
	field.add_theme_constant_override("separation", 8)
	box.add_child(field)
	var printer := PanelContainer.new()
	printer.custom_minimum_size = Vector2(112, 58 if portrait() else 70)
	printer.add_theme_stylebox_override("panel", style(Color("23445a"), Color("8deaff")))
	var printer_label := label("3D PRINTER\n%d / 100" % int(p.printer.durability), true)
	printer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	printer.add_child(printer_label)
	field.add_child(printer)
	battle_printer_controls[seat] = printer
	for slot in 3:
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(105, 58 if portrait() else 70)
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var unit = p.slots[slot]
		var occupied := unit != null
		slot_panel.add_theme_stylebox_override("panel", style(Color("244451") if occupied else Color("142b42"), Color("72d2e9") if occupied else Color("4d7898")))
		var slot_text := "SLOT %d\n-" % (slot + 1) if not occupied else "%s\n%d HP" % [str(unit.name), int(unit.hp)]
		var slot_label := label(slot_text, true)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_panel.add_child(slot_label)
		field.add_child(slot_panel)
		battle_slot_controls[_arrival_key(battle.seed, seat, slot, "slot")] = slot_panel
	if not p.print_job.is_empty(): box.add_child(label("Printer: %s, %d ticks" % [str(p.print_job.card_id), int(p.print_job.ticks)], true))
	return box.get_parent() as Control

static func _arrival_key(seed_value: int, seat: int, slot: int, card_id: String) -> String:
	return "%d:%d:%d:%s" % [seed_value, seat, slot, card_id]

static func consume_arrival(presented: Dictionary, key: String) -> bool:
	if presented.has(key): return false
	presented[key] = true
	return true

static func arrival_duration(reduced_motion: bool) -> float:
	return 0.0 if reduced_motion else 0.52

func _present_pending_arrivals() -> void:
	# Container layout must settle before global rects describe the printer and
	# slot. This is presentation-only: it neither edits the battle state nor
	# affects readiness/turn timing.
	await get_tree().process_frame
	if battle == null or screen != "battle": return
	for seat in 2:
		var player := battle.player(seat)
		for slot in 3:
			var unit = player.slots[slot]
			if unit == null or not bool(unit.get("arriving", false)): continue
			var key := _arrival_key(battle.seed, seat, slot, str(unit.get("card_id", "print")))
			if not arrival_presented.has(key) and _animate_print_arrival(seat, slot, unit): consume_arrival(arrival_presented, key)

func _animate_print_arrival(seat: int, slot: int, unit: Dictionary) -> bool:
	var printer := battle_printer_controls.get(seat, null) as Control
	var slot_control := battle_slot_controls.get(_arrival_key(battle.seed, seat, slot, "slot"), null) as Control
	if printer == null or slot_control == null or not is_instance_valid(printer) or not is_instance_valid(slot_control): return false
	# Reduced motion uses the already-rendered destination card immediately.
	var duration := arrival_duration(bool(GameManager.profile.get("settings", {}).get("reduced_motion", false)))
	if duration <= 0.0: return true
	var flyer := PanelContainer.new()
	flyer.custom_minimum_size = Vector2(116, 64)
	flyer.size = flyer.custom_minimum_size
	flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flyer.z_index = 100
	flyer.add_theme_stylebox_override("panel", style(Color("2a7190eF"), Color("d4fbff")))
	var flyer_label := label("%s\nprinting complete" % str(unit.get("name", "Print")), true)
	flyer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flyer.add_child(flyer_label)
	add_child(flyer)
	var source := printer.get_global_rect().get_center() - global_position - flyer.size * 0.5
	var destination := slot_control.get_global_rect().get_center() - global_position - flyer.size * 0.5
	flyer.position = source
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flyer, "position", destination, duration)
	tween.parallel().tween_property(flyer, "modulate:a", 0.35, duration * 0.55).set_delay(duration * 0.45)
	tween.tween_callback(flyer.queue_free)
	return true

func _battle_intent(intent: Dictionary, seat := 0) -> void:
	var result := BATTLE_RULES.apply_intent(battle, seat, intent)
	toast = str(result.get("error", ""))
	if bool(result.get("ok", false)):
		selected_hand_card = ""
		selected_play_slot = -2
		selected_play_target = -2
		selected_attack_slot = -1
		selected_attack_target = -2
	if bool(result.get("ok", false)) and battle_mode != "local" and seat == 0 and battle.active_seat == 1 and not battle.finished: ai_turn_pending = true
	if bool(result.get("ok", false)) and battle_mode == "local" and battle.active_seat != seat: local_handoff_pending = true; local_handoff_seat = battle.active_seat
	render()
	if ai_turn_pending: call_deferred("_run_pending_ai")

func _run_pending_ai() -> void:
	# Let the rendered printer-to-slot event own one frame (or its motion tween)
	# before the AI can advance into the player's next start turn.
	if not ai_turn_pending or battle == null: return
	var delay := arrival_duration(bool(GameManager.profile.get("settings", {}).get("reduced_motion", false)))
	if delay > 0.0: await get_tree().create_timer(delay + 0.04).timeout
	else: await get_tree().process_frame
	if battle != null and battle.active_seat == 1 and not battle.finished: UNIFIED_AI.take_turn(battle, 1)
	ai_turn_pending = false
	render()

func _settle_finished_unified_battle() -> void:
	if battle == null or battle_settlement_context.is_empty(): return
	var result := GameManager.settle_unified_mode_battle(battle_settlement_context, battle, battle.winner == 0)
	toast = "Result saved." if bool(result.get("ok", false)) else str(result.get("error", "Result could not be saved."))
	render()

func start_mode(mode: String) -> void:
	var setup: Dictionary = GameManager.create_unified_battle(mode, {}, 43 + mode.length())
	if not bool(setup.get("ok", false)): toast = str(setup.get("error", "Unable to launch.")); render(); return
	battle_mode = mode
	battle = setup.get("battle", null) as UnifiedBattleState
	battle_settlement_context = setup.get("settlement_context", {}).duplicate(true) if setup.get("settlement_context", {}) is Dictionary else {}
	battle_settlement_finished = false
	ai_turn_pending = false
	battle_hand_page = 0
	arrival_presented.clear()
	local_handoff_pending = mode == "local"; local_handoff_seat = 0
	render()
func _first_open_slot(p: Dictionary) -> int:
	for i in 3:
		if p.slots[i] == null: return i
	return -1
func _first_friendly_slot(p: Dictionary) -> int:
	for i in 3:
		if p.slots[i] != null: return i
	return -1
func _spool_cap() -> int: return 10 if "spool_10" in GameManager.profile.get("printer_nodes", []) else (7 if "spool_7" in GameManager.profile.get("printer_nodes", []) else (5 if "spool_5" in GameManager.profile.get("printer_nodes", []) else 3))
func _collector_cap() -> int: return 8 if "collector_8" in GameManager.profile.get("printer_nodes", []) else (5 if "collector_5" in GameManager.profile.get("printer_nodes", []) else 3)
func render_inspector(root: VBoxContainer) -> void:
	var card := RULES.card(inspector_id)
	if card.is_empty(): return
	# Inspector is added above the page root and owns the viewport, not a row in it.
	var modal := ColorRect.new()
	modal.color = Color("081321f2")
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var shell := PanelContainer.new()
	shell.custom_minimum_size = Vector2(mini(900.0, size.x - 32.0), mini(620.0, size.y - 32.0))
	shell.add_theme_stylebox_override("panel", style(Color("142b42"), Color("8deaff")))
	center.add_child(shell)
	var overlay := VBoxContainer.new()
	overlay.add_theme_constant_override("separation", 12)
	shell.add_child(overlay)
	overlay.add_child(label(str(card.name)))
	var art_path := str(card.get("sprite_sheet", ""))
	if art_path.is_empty(): art_path = "res://assets/cards/creatures/%s_v1.png" % inspector_id
	if ResourceLoader.exists(art_path):
		var art := TextureRect.new(); art.texture = load(art_path); art.custom_minimum_size = Vector2(260, 260); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; overlay.add_child(art)
	var tabs := HBoxContainer.new(); overlay.add_child(tabs)
	for tab in ["card","stats","build"]: tabs.add_child(button(tab.capitalize(), func(): inspector_tab = tab; render(), Color("3c76bf") if tab == inspector_tab else Color("536c8d")))
	if inspector_tab == "card": overlay.add_child(label("%s • %s • %d filament" % [str(card.get("type", "")),str(card.get("rarity", "common")),int(card.get("cost", 0))]))
	elif inspector_tab == "stats": overlay.add_child(label("HP %d • Attack %d • Print %d" % [int(card.get("hp", 0)),int(card.get("attack", 0)),int(card.get("print_ticks", 0))]))
	else:
		overlay.add_child(label("Card XP %d • up to four active nodes" % int(GameManager.profile.get("card_xp", {}).get(inspector_id, 0)), true))
		for node in ["power_a","power_b","tempo_a","tempo_b","utility_a","utility_b"]: overlay.add_child(button("Build %s — %s" % [node.replace("_", " "), RULES.build_effect_label(inspector_id, node)], build_card.bind(inspector_id, node), Color("526e93")))
		overlay.add_child(button("Free respec", func(): GameManager.respec_card_build(inspector_id), Color("536c8d")))
	overlay.add_child(button("Close", func(): inspector_id = ""; render(), Color("536c8d")))

func buy_pack(pack_id: String) -> void:
	var result := GameManager.buy_card_pack(pack_id)
	if bool(result.get("ok", false)): render()
func build_card(card_id: String, node: String) -> void:
	GameManager.build_card_node(card_id, node)
func toggle_printer_node(id: String) -> void:
	if id in printer_upgrade_draft: printer_upgrade_draft.erase(id)
	else: printer_upgrade_draft.append(id)
	render()
func apply_printer_draft() -> void:
	if GameManager.apply_printer_upgrades(printer_upgrade_draft): printer_upgrade_draft = GameManager.profile.get("printer_nodes", []).duplicate()
func select_hand_card(card_id: String) -> void:
	# Selecting is deliberately inert: it does not pick the first open/friendly
	# target or spend filament. The next step must be an explicit legal choice.
	selected_hand_card = card_id
	selected_play_slot = -2
	selected_play_target = -2
	render()

func _render_play_target_picker(root: VBoxContainer, active: Dictionary) -> void:
	if selected_hand_card.is_empty() or selected_hand_card not in active.hand: return
	var card := RULES.card(selected_hand_card)
	if card.is_empty(): return
	var kind := str(card.get("type", ""))
	var picker := VBoxContainer.new()
	root.add_child(picker)
	picker.add_child(label("%s: choose a legal target" % str(card.get("name", selected_hand_card)), true))
	if kind == "creature":
		picker.add_child(label("Open battlefield slot", true))
		for slot in 3:
			if active.slots[slot] == null:
				picker.add_child(button(("✓ " if selected_play_slot == slot else "") + "Print to slot %d" % (slot + 1), func(): selected_play_slot = slot; render(), Color("588d73") if selected_play_slot == slot else Color("526e93")))
		if selected_play_slot >= 0:
			picker.add_child(button("Play %s" % str(card.name), func(): _battle_intent({"type":"play_card","card_id":selected_hand_card,"slot":selected_play_slot}, battle.active_seat), Color("3c76bf")))
	elif kind == "equipment":
		picker.add_child(label("Friendly completed print", true))
		for slot in 3:
			if active.slots[slot] != null:
				picker.add_child(button(("✓ " if selected_play_target == slot else "") + "Target %s (slot %d)" % [str(active.slots[slot].name), slot + 1], func(): selected_play_target = slot; render(), Color("588d73") if selected_play_target == slot else Color("526e93")))
		if selected_play_target >= 0:
			picker.add_child(button("Equip %s" % str(card.name), func(): _battle_intent({"type":"play_card","card_id":selected_hand_card,"target":selected_play_target}, battle.active_seat), Color("3c76bf")))
	elif kind == "spell":
		var rival := str(card.get("effect", "")) in ["slow_printer", "steal_filament"]
		var printer_name := "Rival printer" if rival else "Your printer"
		picker.add_child(button(("✓ " if selected_play_target == -1 else "") + "Target " + printer_name, func(): selected_play_target = -1; render(), Color("588d73") if selected_play_target == -1 else Color("526e93")))
		if selected_play_target == -1:
			picker.add_child(button("Cast %s" % str(card.name), func(): _battle_intent({"type":"play_card","card_id":selected_hand_card,"target":-1}, battle.active_seat), Color("3c76bf")))
	else:
		picker.add_child(button("Play %s" % str(card.name), func(): _battle_intent({"type":"play_card","card_id":selected_hand_card}, battle.active_seat), Color("3c76bf")))

func _render_attack_target_picker(root: VBoxContainer, active: Dictionary) -> void:
	if battle.phase != "attack": return
	var picker := VBoxContainer.new()
	root.add_child(picker)
	picker.add_child(label("Attack: choose your print, then an enemy target.", true))
	for slot in 3:
		if active.slots[slot] != null and bool(active.slots[slot].get("ready", false)):
			picker.add_child(button(("✓ " if selected_attack_slot == slot else "") + "Attack with %s (slot %d)" % [str(active.slots[slot].name), slot + 1], func(): selected_attack_slot = slot; selected_attack_target = -2; render(), Color("a86b2e") if selected_attack_slot == slot else Color("526e93")))
	if selected_attack_slot < 0: return
	var foe := battle.player(1 - battle.active_seat)
	for slot in 3:
		if foe.slots[slot] != null:
			picker.add_child(button(("✓ " if selected_attack_target == slot else "") + "Target %s (slot %d)" % [str(foe.slots[slot].name), slot + 1], func(): selected_attack_target = slot; render(), Color("588d73") if selected_attack_target == slot else Color("526e93")))
	if _first_friendly_slot(foe) < 0:
		picker.add_child(button(("✓ " if selected_attack_target == -1 else "") + "Target rival printer", func(): selected_attack_target = -1; render(), Color("588d73") if selected_attack_target == -1 else Color("526e93")))
	if selected_attack_target >= -1:
		picker.add_child(button("Confirm attack", func(): _battle_intent({"type":"attack","slot":selected_attack_slot,"target":selected_attack_target}, battle.active_seat), Color("a86b2e")))
func _battle_background_path() -> String:
	var id := "daily_arena"
	if battle_mode.begins_with("trial_"): id = battle_mode.trim_prefix("trial_")
	elif battle_mode == "local": id = "element_bench"
	return "res://assets/ui/battle_backgrounds/%s_%s_v1.png" % [id, "portrait" if portrait() else "landscape"]
