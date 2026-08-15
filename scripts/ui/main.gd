extends Control
## Procedural workshop shell. Final illustration and 3D GLB creatures remain approval-gated assets.
var screen := "workshop"
var battle: BattleState
var title_label: Label
var body: VBoxContainer
var status: Label

func _ready() -> void:
	GameManager.profile_changed.connect(render)
	GameManager.toast_requested.connect(_toast)
	render()

func clear_children(node: Node) -> void:
	for child in node.get_children(): child.queue_free()

func make_button(text_value: String, callback: Callable) -> Button:
	var button := Button.new(); button.text = text_value; button.custom_minimum_size = Vector2(0, 42); button.pressed.connect(callback); return button

func label(text_value: String, size := 16, color := Color.WHITE) -> Label:
	var value := Label.new(); value.text = text_value; value.add_theme_font_size_override("font_size", size); value.add_theme_color_override("font_color", color); value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; return value

func render() -> void:
	clear_children(self)
	var bg := ColorRect.new(); bg.color = Color("172039") if screen == "workshop" else Color("141923"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left", 42); margin.add_theme_constant_override("margin_right", 42); margin.add_theme_constant_override("margin_top", 26); margin.add_theme_constant_override("margin_bottom", 24); add_child(margin)
	body = VBoxContainer.new(); body.add_theme_constant_override("separation", 12); margin.add_child(body)
	var header := HBoxContainer.new(); body.add_child(header)
	title_label = label("PRINTFORGE LEGENDS", 31, Color("ffd36c")); header.add_child(title_label)
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(spacer)
	header.add_child(label("Forge Coins: %d   Spool: %d/10" % [GameManager.profile.coins, GameManager.filament_cap()], 17, Color("8eeaff")))
	status = label("", 15, Color("d9e3f2")); body.add_child(status)
	if screen == "battle": render_battle()
	elif screen == "shop": render_shop()
	elif screen == "codex": render_codex()
	else: render_workshop()

func render_workshop() -> void:
	body.add_child(label("Makers Guild Workshop", 24, Color("ffb96b")))
	body.add_child(label("A warm timber workshop glows beneath hanging lamps. Snow-blue light spills past the door; filament spools, blueprints, and printed companions fill the benches.", 17, Color("d5dced")))
	var grid := GridContainer.new(); grid.columns = 3; grid.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_child(grid)
	for item in [["Main Printer","Print an owned blueprint"],["Extruder Forge","Daily rotating blueprints"],["Forgedex","Collection discoveries"],["Proving Grounds","Solo battle vs AI"],["Workbench","Calibration job rewards"],["Print Yard","Your printed creatures play"]]:
		var panel := VBoxContainer.new(); panel.custom_minimum_size = Vector2(240,105); grid.add_child(panel); panel.add_child(label(item[0],20,Color("7de9ff"))); panel.add_child(label(item[1],14,Color("b9c4d9")))
		match item[0]:
			"Extruder Forge": panel.add_child(make_button("Open Shop", func(): screen="shop"; render()))
			"Forgedex": panel.add_child(make_button("Open Forgedex", func(): screen="codex"; render()))
			"Proving Grounds": panel.add_child(make_button("Battle Apprentice AI", start_battle))
			"Workbench": panel.add_child(make_button("Run Calibration Job (+ coins)", func(): _toast("Calibration complete: +%d Forge Coins" % GameManager.complete_workshop_job(72))))
			"Main Printer": panel.add_child(make_button("Print Cinderpaw (20 FC)", func(): GameManager.print_creature("cinderpaw", 20)))
			"Print Yard": panel.add_child(label("%d companions are wandering." % GameManager.profile.creatures.size(),14,Color("9be59c")))

func render_shop() -> void:
	body.add_child(label("Extruder Forge — server-seeded daily rotation", 23, Color("ffb96b")))
	body.add_child(label("Offline slice uses a safe cached Common/Uncommon selection. Rare items are authority-generated in online service.", 14, Color("b9c4d9")))
	var grid := GridContainer.new(); grid.columns=4; body.add_child(grid)
	for creature in Catalog.CREATURES.slice(0, 8):
		var rarity := Catalog.rarity(creature.rarity); var panel := VBoxContainer.new(); grid.add_child(panel); panel.add_child(label(creature.name,18,Color(rarity.color))); panel.add_child(label("%s • %s\n%d bends" % [creature.element,rarity.name,creature.bend],13));
		var owned: bool = creature.id in GameManager.profile.blueprints
		panel.add_child(make_button("Print (%d FC)" % rarity.print if owned else "Learn (%d FC)" % rarity.blueprint, func():
			if owned: GameManager.print_creature(creature.id, rarity.print)
			else: GameManager.learn_blueprint(creature.id, rarity.blueprint)))
	body.add_child(make_button("Back to Workshop", func(): screen="workshop"; render()))

func render_codex() -> void:
	body.add_child(label("Forgedex — %d known blueprints" % GameManager.profile.discovered.size(), 23, Color("b88bff")))
	var grid := GridContainer.new(); grid.columns=4; body.add_child(grid)
	for creature in Catalog.CREATURES:
		var known: bool = creature.id in GameManager.profile.discovered
		var panel := VBoxContainer.new(); grid.add_child(panel)
		panel.add_child(label(creature.name if known else "???",17,Color(Catalog.rarity(creature.rarity).color if known else "6a7281")))
		panel.add_child(label("%s • %d bends" % [creature.element,creature.bend] if known else "Undiscovered",13))
	body.add_child(make_button("Back to Workshop", func(): screen="workshop"; render()))

func start_battle() -> void:
	battle = BattleState.create(["cinderpaw","aquafin","voltwig"],["mossmunk","stoneback","galehopper"],GameManager.filament_cap(),3,int(Time.get_ticks_msec()))
	screen="battle"; render()

func render_battle() -> void:
	body.add_child(label("Proving Grounds — %s" % ("Your turn" if battle.active_player == 0 else "Rival is thinking"),23,Color("ffb96b")))
	for player in [1,0]:
		var unit := battle.active_unit(player); var panel := VBoxContainer.new(); body.add_child(panel)
		panel.add_child(label(("Rival" if player == 1 else "You") + ": " + unit.name + "  %d/%d HP  •  %s" % [unit.hp,unit.max_hp,unit.element],20,Color("ff8d85") if player==1 else Color("8eeaff")))
		panel.add_child(label("Filament %d/%d | Attack %d | %s (%d; cd %d)" % [battle.players[player].filament,battle.players[player].spool_cap,unit.attack,unit.ability,unit.ability_cost,unit.cooldown_remaining],14))
	if battle.finished:
		body.add_child(label("%s — Core Printer status resolved." % ("Victory!" if battle.winner == 0 else "Defeat."),27,Color("ffd36c"))); body.add_child(make_button("Return to Workshop", func(): GameManager.award_battle(battle.winner==0); screen="workshop"; render())); return
	if battle.active_player == 0:
		var actions := HBoxContainer.new(); body.add_child(actions); actions.add_child(make_button("Basic Attack", func(): intent({"type":"attack"}))); actions.add_child(make_button("Signature Ability", func(): intent({"type":"ability"}))); actions.add_child(make_button("Defend (+4 shield)", func(): intent({"type":"defend"}))); actions.add_child(make_button("End Turn", func(): intent({"type":"end_turn"})))
		var switches := HBoxContainer.new()
		body.add_child(switches)
		switches.add_child(label("Bench:",15))
		for bench_index in battle.players[0].team.size():
			if bench_index == int(battle.players[0].active): continue
			var bench_unit: Dictionary = battle.players[0].team[bench_index]
			if int(bench_unit.hp) <= 0: continue
			var discount: int = int(battle.players[0].switch_discount)
			var switch_cost: int = maxi(0, int(bench_unit.cost) - discount)
			switches.add_child(make_button("Switch %s (%d)" % [bench_unit.name, switch_cost], func(): intent({"type":"switch","index":bench_index})))
		var cards := HBoxContainer.new()
		body.add_child(cards)
		cards.add_child(label("Hand:",15))
		for card in battle.players[0].hand:
			cards.add_child(make_button(str(card).replace("_"," ").capitalize(), func(): intent({"type":"card","card_id":card})))
	body.add_child(label("Battle log\n" + "\n".join(battle.log.slice(max(0,battle.log.size()-5))),14,Color("c8d1df")))
	if battle.active_player == 1 and not battle.finished:
		call_deferred("run_ai")

func intent(action: Dictionary) -> void:
	var result := BattleRules.apply_intent(battle,0,action)
	if not result.ok: _toast(result.error)
	render()

func run_ai() -> void:
	if battle.active_player != 1 or battle.finished: return
	var result := BattleRules.apply_intent(battle,1,AIOpponent.choose_intent(battle,"Craftsman"))
	if not result.ok and battle.active_player == 1 and not battle.finished:
		result = BattleRules.apply_intent(battle,1,{"type":"defend"})
	if not result.ok and battle.active_player == 1 and not battle.finished:
		BattleRules.apply_intent(battle,1,{"type":"end_turn"})
	render()

func _toast(message: String) -> void:
	if status: status.text = message
