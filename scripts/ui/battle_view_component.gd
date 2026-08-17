class_name BattleViewComponent
extends RefCounted
## Rebuildable battle shell. Main retains BattleState, rewards, AI, and callbacks.

func render_unavailable(host: Container, context: Dictionary) -> void:
	var unavailable: VBoxContainer = context.make_panel.call(Color("19334de8"), Color("ffaaa1"))
	host.add_child(unavailable.get_parent())
	unavailable.add_child(context.label.call("Proving Grounds unavailable", 24, Color("ffaaa1")))
	unavailable.add_child(context.label.call("Your current team needs a catalog-valid ready print before a training match can begin.", 16, Color("dce8f4")))
	unavailable.add_child(context.make_button.call("Return to Workshop", context.return_workshop, Color("536c8d")))

func build_shell(host: Container, context: Dictionary) -> Dictionary:
	var frame := PanelContainer.new()
	frame.name = "BattleFullscreenPanel"
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.custom_minimum_size = Vector2(0, 420)
	frame.add_theme_stylebox_override("panel", context.panel_style.call(Color("19334de8"), Color("f1be69")))
	host.add_child(frame)
	var intro := VBoxContainer.new()
	intro.name = "BattleFullscreenContent"
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intro.add_theme_constant_override("separation", 8)
	frame.add_child(intro)
	var status: Label = context.label.call("", 14, Color("fff0a1"))
	status.name = "BattleStatus"
	status.visible = false
	intro.add_child(status)
	intro.add_child(context.label.call("%s - %s" % [str(context.title), str(context.turn_caption)], 22, Color("ffd36c")))
	if not str(context.launch_notice).is_empty():
		intro.add_child(context.label.call("Lineup notice: " + str(context.launch_notice), 13, Color("fff0a1")))
	var stage: Control = context.stage
	stage.size_flags_vertical = Control.SIZE_FILL if bool(context.secondary_open) else Control.SIZE_EXPAND_FILL
	intro.add_child(stage)
	return {"content": intro, "status": status}

func render_active_content(host: Container, context: Dictionary) -> void:
	if not bool(context.secondary_open) and bool(context.portrait):
		render_summary(host, context)
	if int(context.active_player) == 0 and not bool(context.finished):
		render_action_dock(host, context)
		render_secondary(host, context)

func _add_unit_summary(host: Container, player: int, context: Dictionary, heading_size: int) -> void:
	var battle = context.battle
	var unit: Dictionary = battle.active_unit(player)
	var suit_id := str(unit.get("suit_id", ""))
	var max_hp: int = int(unit.get("max_hp", 1))
	var base_hp: int = int(Catalog.creature(str(unit.get("id", ""))).get("hp", max_hp))
	host.add_child(context.label.call(("Rival" if player == 1 else "You") + ": " + str(unit.get("name", "Unknown")) + "  %d/%d HP - %s" % [int(unit.get("hp", 0)), max_hp, str(unit.get("element", "Unknown"))], heading_size, Color("ffaaa1") if player == 1 else Color("a9ecff")))
	host.add_child(context.label.call("Suit: None" if suit_id.is_empty() else "Suit: %s | +%d maximum HP | %d guard | Core: %s" % [str(unit.get("suit_name", "Full suit")), max_hp - base_hp, int(unit.get("armor", 0)), str(unit.get("core_name", "None"))], 13, Color("f1be69")))
	host.add_child(context.label.call("Filament %d/%d | Attack %d | %s (%d; cd %d)" % [int(battle.players[player].get("filament", 0)), int(battle.players[player].get("spool_cap", 0)), int(unit.get("attack", 0)), str(unit.get("ability", "Signature")), int(unit.get("ability_cost", 0)), int(unit.get("cooldown_remaining", 0))], 13, Color("d9e7f3")))

func render_summary(host: Container, context: Dictionary) -> void:
	var summary: VBoxContainer = context.make_panel.call(Color("10273ad8"), Color("517b9a"))
	summary.get_parent().add_theme_stylebox_override("panel", context.inset_style.call(Color("10273ad8"), Color("517b9a")))
	summary.name = "BattleSummary"
	var panel := summary.get_parent() as PanelContainer
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size = Vector2(0, 142)
	host.add_child(panel)
	for player in [1, 0]:
		_add_unit_summary(summary, player, context, 16)
		var unit: Dictionary = context.battle.active_unit(player)
		summary.add_child(context.label.call("Effect: " + Catalog.signature_description(str(unit.get("id", ""))), 12, Color("b9d3e8")))
	var battle = context.battle
	var log_line: Label = context.label.call("Latest: " + str(battle.log.back() if not battle.log.is_empty() else "Battle ready"), 13, Color("d0dfeb"))
	log_line.name = "BattleSummaryLatestEvent"
	log_line.clip_text = true
	log_line.autowrap_mode = TextServer.AUTOWRAP_OFF
	summary.add_child(log_line)

func render_action_dock(host: Container, context: Dictionary) -> void:
	var battle = context.battle
	var portrait: bool = bool(context.portrait)
	var dock: VBoxContainer = context.make_panel.call(Color("214969ee"), Color("6de4ff"))
	dock.name = "BattleActionDock"
	var dock_panel := dock.get_parent() as PanelContainer
	dock_panel.custom_minimum_size = Vector2(0, 210 if portrait else 142)
	dock_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(dock_panel)
	var opening_locked: bool = int(battle.turn) <= 2
	var dock_title: Label = context.label.call("Moves - Setup: Defend, cards, or End Turn" if opening_locked else "Moves", 16 if opening_locked else 18, Color("fff0a1") if opening_locked else Color("d7f8ff"))
	if opening_locked: dock_title.name = "BattleOpeningGuidance"
	dock.add_child(dock_title)
	var feedback: Label = context.label.call(str(context.feedback), 14, Color.WHITE if bool(context.high_contrast) else Color("fff0a1"))
	feedback.name = "BattleImpactBanner"
	feedback.autowrap_mode = TextServer.AUTOWRAP_OFF
	feedback.clip_text = true
	feedback.custom_minimum_size.y = 20
	dock.add_child(feedback)
	var actions := GridContainer.new()
	actions.name = "BattleActionGrid"
	actions.columns = 2 if portrait else 4
	actions.custom_minimum_size = Vector2(0, 104 if portrait else 48)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	dock.add_child(actions)
	var unit: Dictionary = battle.active_unit(0)
	var attack_value: int = int(unit.get("attack", 0))
	var ability_name := str(unit.get("ability", "Signature"))
	if ability_name.is_empty(): ability_name = "Signature"
	var ability_cost: int = int(unit.get("ability_cost", 0))
	var basic: Button = context.make_button.call("Basic Attack (%d)" % attack_value, context.submit_action.bind("attack"))
	basic.name = "BattleActionBasicAttack"; basic.custom_minimum_size.y = 48; basic.disabled = opening_locked; actions.add_child(basic)
	var ability: Button = context.make_button.call("%s (%d FC)" % [ability_name, ability_cost], context.submit_action.bind("ability"))
	ability.name = "BattleActionSignatureAbility"; ability.custom_minimum_size.y = 48; ability.disabled = opening_locked or int(unit.get("cooldown_remaining", 0)) > 0 or int(battle.players[0].get("filament", 0)) < ability_cost; actions.add_child(ability)
	var defend: Button = context.make_button.call("Defend", context.submit_action.bind("defend"), Color("526e93"))
	defend.name = "BattleActionDefend"; defend.custom_minimum_size.y = 48; actions.add_child(defend)
	var end_turn: Button = context.make_button.call("End Turn", context.submit_action.bind("end_turn"), Color("536c8d"))
	end_turn.name = "BattleActionEndTurn"; end_turn.custom_minimum_size.y = 48; actions.add_child(end_turn)
	var signature_effect: Label = context.label.call("Signature effect: " + Catalog.signature_description(str(unit.get("id", ""))), 12, Color("b9d3e8"))
	signature_effect.name = "BattleSignatureDescription"
	signature_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	signature_effect.visible = not bool(context.secondary_open)
	dock.add_child(signature_effect)
	var secondary: Button = context.make_button.call("Hide Bench, Hand & Details" if bool(context.secondary_open) else "Bench, Hand & Details", context.toggle_secondary, Color("536c8d"))
	secondary.name = "BattleSecondaryToggle"; secondary.custom_minimum_size = Vector2(0, 48); dock.add_child(secondary)

func render_secondary(host: Container, context: Dictionary) -> void:
	if not bool(context.secondary_open): return
	var portrait: bool = bool(context.portrait)
	var tab := str(context.secondary_tab)
	var secondary_panel := PanelContainer.new()
	secondary_panel.name = "BattleSecondaryPanel"
	secondary_panel.add_theme_stylebox_override("panel", context.panel_style.call(Color("172e43ee"), Color("7bcbe5")))
	secondary_panel.custom_minimum_size = Vector2(0, (282 if portrait else 260) if tab == "hand" else 160)
	secondary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(secondary_panel)
	var viewport := Control.new()
	viewport.name = "BattleSecondaryViewport"; viewport.clip_contents = true; viewport.custom_minimum_size = Vector2.ZERO
	secondary_panel.add_child(viewport)
	var scroll: ScrollContainer = context.new_scroll.call()
	scroll.name = "BattleSecondaryScroll"; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE); scroll.custom_minimum_size = Vector2.ZERO
	viewport.add_child(scroll)
	var panel := VBoxContainer.new()
	panel.name = "BattleSecondaryContent"; panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; panel.add_theme_constant_override("separation", 8)
	scroll.add_child(panel)
	panel.add_child(context.label.call("Tactics", 16, Color("9beaff")))
	var tabs := GridContainer.new()
	tabs.name = "BattleSecondaryTabs"; tabs.columns = 2 if portrait else 4; tabs.add_theme_constant_override("h_separation", 8); tabs.add_theme_constant_override("v_separation", 8)
	panel.add_child(tabs)
	for tab_data in [["bench", "Bench", "BattleSecondaryBenchTab"], ["hand", "Hand", "BattleSecondaryHandTab"], ["details", "Details", "BattleSecondaryDetailsTab"], ["concede", "Concede", "BattleSecondaryConcedeTab"]]:
		var tab_id := str(tab_data[0])
		var tab_button: Button = context.make_button.call(str(tab_data[1]), context.select_tab.bind(tab_id), Color("2f93a8") if tab == tab_id else Color("536c8d"))
		tab_button.name = str(tab_data[2]); tabs.add_child(tab_button)
	match tab:
		"bench": _render_bench(panel, context)
		"hand": _render_hand(panel, context)
		"details": _render_details(panel, context)
		_: _render_concede(panel, context)

func _render_bench(panel: Container, context: Dictionary) -> void:
	panel.add_child(context.label.call("Bench", 16, Color("9beaff")))
	var switches := GridContainer.new()
	switches.name = "BattleBenchGrid"; switches.columns = 2 if bool(context.portrait) else 3; switches.add_theme_constant_override("h_separation", 8); switches.add_theme_constant_override("v_separation", 8)
	panel.add_child(switches)
	var count := 0
	var battle = context.battle
	for bench_index in battle.players[0].team.size():
		if bench_index == int(battle.players[0].active): continue
		var bench_unit: Dictionary = battle.players[0].team[bench_index]
		if int(bench_unit.get("hp", 0)) > 0:
			var switch_button: Button = context.make_button.call("Switch %s" % str(bench_unit.get("name", "Unknown")), context.submit_switch.bind(bench_index))
			switch_button.name = "BattleSwitch%s" % str(bench_unit.get("id", "Unknown")); switches.add_child(switch_button); count += 1
	if count == 0: switches.add_child(context.label.call("No healthy bench prints.", 14, Color("b9cad7")))

func _render_hand(panel: Container, context: Dictionary) -> void:
	var battle = context.battle
	panel.add_child(context.label.call("Hand - Deck %d | Discard %d" % [battle.players[0].deck.size(), battle.players[0].get("discard", []).size()], 16, Color("9beaff")))
	var cards := GridContainer.new()
	cards.name = "BattleHandGrid"; cards.columns = 4; cards.add_theme_constant_override("h_separation", 8); cards.add_theme_constant_override("v_separation", 8)
	var carousel := ScrollContainer.new()
	carousel.name = "BattleHandCarousel"; carousel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; carousel.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; carousel.custom_minimum_size = Vector2(0, 238); carousel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(carousel); carousel.add_child(cards)
	var counts := {}
	for raw_id in battle.players[0].hand: counts[str(raw_id)] = int(counts.get(str(raw_id), 0)) + 1
	for card_id in counts:
		var definition := Catalog.support_card(str(card_id))
		var reason := SupportCardRules.legality_reason(battle, 0, definition)
		var card = context.new_card_view.call()
		if card != null:
			card.configure(definition, int(counts[card_id]), reason, false, true); card.pressed.connect(context.submit_card.bind(str(card_id)))
			card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN; card.name = "BattleCard%s" % str(card_id).capitalize(); cards.add_child(card)
	cards.custom_minimum_size = Vector2(maxi(1, counts.size()) * 158, 225)

func _render_details(panel: Container, context: Dictionary) -> void:
	for player in [1, 0]:
		_add_unit_summary(panel, player, context, 15)
		var unit: Dictionary = context.battle.active_unit(player)
		panel.add_child(context.label.call("Signature effect: " + Catalog.signature_description(str(unit.get("id", ""))), 12, Color("b9d3e8")))
	var battle = context.battle
	panel.add_child(context.label.call("Battle log\n" + "\n".join(battle.log.slice(maxi(0, battle.log.size() - 4))), 13, Color("d0dfeb")))

func _render_concede(panel: Container, context: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8); panel.add_child(row)
	if bool(context.concede_armed):
		var confirm: Button = context.make_button.call("Confirm Concede", context.toggle_concede, Color("9a5b6f"))
		confirm.name = "BattleActionConfirmConcede"; row.add_child(confirm)
		var cancel: Button = context.make_button.call("Cancel Concede", context.cancel_concede, Color("536c8d"))
		cancel.name = "BattleActionCancelConcede"; row.add_child(cancel)
	else:
		var concede: Button = context.make_button.call("Concede", context.toggle_concede, Color("9a5b6f"))
		concede.name = "BattleActionConcede"; row.add_child(concede)
