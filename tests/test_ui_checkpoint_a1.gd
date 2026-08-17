extends Node

const MAIN := preload("res://scenes/main.tscn")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func tree_has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment): return true
	for child in node.get_children():
		if tree_has_text(child, fragment): return true
	return false

func _assert_multi_turn_dock_stability(main: Node, dimensions: Vector2i) -> void:
	get_viewport().size = dimensions
	main.size = Vector2(dimensions)
	main.screen = "battle"
	main.battle_secondary_open = false
	main.ai_pending = true # This test explicitly applies the accepted rival turns.
	main.battle = BattleState.create(GameManager.current_team_loadout(), ["voidmanta"], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
	# Skip the opening restriction so all six player Basic Attacks exercise the
	# actual impact feedback and presentation re-render path. Voidmanta survives
	# the deterministic fixture while its Defends keep the rival turn legal.
	main.battle.turn = 2
	main.battle.opening_player = 1
	main.battle.active_player = 0
	main.render()
	await get_tree().process_frame
	await get_tree().process_frame
	var baseline := Rect2()
	for exchange in 6:
		var player_result := BattleRules.apply_intent(main.battle, 0, {"type": "attack"})
		require(bool(player_result.get("ok", false)), "multi-turn player Basic Attack %d is accepted at %s" % [exchange + 1, dimensions])
		main.battle_last_event = "attack"
		main.battle_last_actor = 0
		main.battle_presentation_serial += 1
		main.render()
		await get_tree().process_frame
		var rival_result := BattleRules.apply_intent(main.battle, 1, {"type": "defend"})
		require(bool(rival_result.get("ok", false)), "multi-turn rival Defend %d is accepted at %s" % [exchange + 1, dimensions])
		main.battle_last_event = "defend"
		main.battle_last_actor = 1
		main.battle_presentation_serial += 1
		main.render()
		await get_tree().process_frame
		await get_tree().process_frame
		var docks := main.find_children("BattleActionDock", "", true, false)
		var grids := main.find_children("BattleActionGrid", "", true, false)
		var dock := main.find_child("BattleActionDock", true, false) as Control
		var dock_rect := dock.get_global_rect() if dock != null else Rect2()
		require(docks.size() == 1 and grids.size() == 1, "multi-turn render %d keeps exactly one BattleActionDock/Grid at %s" % [exchange + 1, dimensions])
		require(dock != null and dock_rect.position.y >= 0.0 and dock_rect.end.y <= float(dimensions.y), "multi-turn dock %d remains in viewport at %s (rect %s)" % [exchange + 1, dimensions, dock_rect])
		if exchange == 0:
			baseline = dock_rect
		else:
			require(absf(dock_rect.position.y - baseline.position.y) <= 8.0 and absf(dock_rect.size.y - baseline.size.y) <= 4.0, "multi-turn dock %d has stable top/height at %s (baseline %s, current %s)" % [exchange + 1, dimensions, baseline, dock_rect])
		for control_name in ["BattleActionBasicAttack", "BattleActionSignatureAbility", "BattleActionDefend", "BattleActionEndTurn", "BattleSecondaryToggle"]:
			var control := main.find_child(control_name, true, false) as Control
			var rect := control.get_global_rect() if control != null else Rect2()
			require(control != null and rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= float(dimensions.x) and rect.end.y <= float(dimensions.y), "multi-turn %s %d remains reachable at %s (rect %s)" % [control_name, exchange + 1, dimensions, rect])

func _ready() -> void:
	require(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 720 and int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 720, "project uses a square 720 base viewport")
	require(str(ProjectSettings.get_setting("display/window/stretch/mode")) == "canvas_items" and str(ProjectSettings.get_setting("display/window/stretch/aspect")) == "expand", "project uses canvas_items expand stretching")
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 500
	var moss_blueprint: Dictionary = ProgressionRules.purchase_creature_blueprint(profile, "mossmunk")
	require(bool(moss_blueprint.get("ok", false)), "battle fixture learns a healthy bench blueprint")
	profile = moss_blueprint.get("profile", profile)
	var moss_print: Dictionary = ProgressionRules.print_creature(profile, "mossmunk")
	require(bool(moss_print.get("ok", false)), "battle fixture prints a healthy bench creature")
	profile = moss_print.get("profile", profile)
	profile.team = [str(profile.creatures[0].instance_id), str(profile.creatures[1].instance_id)]
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	for size in [Vector2i(1280, 720), Vector2i(576, 1024), Vector2i(720, 1280)]:
		get_viewport().size = size
		main.size = Vector2(size)
		main.screen = "battle"
		main.battle_secondary_open = false
		main.battle = BattleState.create(GameManager.current_team_loadout(), ["mossmunk"], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
		main.render()
		# The dock is constructed synchronously: even before container settling it
		# must advertise a nonzero, touch-safe action grid rather than becoming an
		# empty Android first frame.
		var initial_grid := main.find_child("BattleActionGrid", true, false) as GridContainer
		var persistent_stage := main.find_child("BattleStage", true, false) as BattleSpriteStage
		require(initial_grid != null and initial_grid.custom_minimum_size.y >= (104.0 if size.y > size.x else 48.0), "BattleActionGrid has an explicit pre-settle height at %s" % size)
		for control_name in ["BattleActionBasicAttack", "BattleActionSignatureAbility", "BattleActionDefend", "BattleActionEndTurn"]:
			var initial_control := main.find_child(control_name, true, false) as Button
			require(initial_control != null and not initial_control.text.is_empty() and initial_control.custom_minimum_size.y >= 48.0, "%s has a pre-settle readable 48px contract at %s" % [control_name, size])
		require(tree_has_text(main, "Signature effect: +5 base damage before element and armor; foe loses 1 Attack and is locked 1 turn"), "battle dock exposes the exact catalog-derived Cinderpaw signature effect at %s" % size)
		main.render()
		await get_tree().process_frame
		require(persistent_stage != null and main.find_child("BattleStage", true, false) == persistent_stage, "Battle screen component reattaches one persistent stage at %s" % size)
		await get_tree().process_frame
		await get_tree().process_frame
		var frame := main.find_child("BattleFullscreenPanel", true, false) as PanelContainer
		var content := main.find_child("BattleFullscreenContent", true, false) as VBoxContainer
		var grid := main.find_child("BattleActionGrid", true, false) as GridContainer
		require(main.find_child("BattleActionDock", true, false) != null, "BattleActionDock is present before detail rows at %s" % size)
		require(frame != null and content != null and frame.custom_minimum_size.y >= 420.0 and frame.get_global_rect().size.y > 0.0, "battle uses an explicit non-collapsing full-height frame at %s (frame %s)" % [size, frame.get_global_rect() if frame != null else Rect2()])
		require(frame != null and frame.get_global_rect().end.y >= float(size.y) * 0.85 and frame.get_global_rect().end.y <= float(size.y), "battle composition reaches the lower visible viewport at %s (frame %s)" % [size, frame.get_global_rect() if frame != null else Rect2()])
		require(grid != null and grid.columns == (2 if size.y > size.x else 4), "BattleActionGrid uses the responsive column count at %s" % size)
		require(grid != null and grid.custom_minimum_size.y >= (104.0 if size.y > size.x else 48.0) and grid.get_global_rect().size.y >= (104.0 if size.y > size.x else 48.0), "BattleActionGrid retains a real visible height at %s (rect %s)" % [size, grid.get_global_rect() if grid != null else Rect2()])
		for control_name in ["BattleActionBasicAttack", "BattleActionSignatureAbility", "BattleActionDefend", "BattleActionEndTurn"]:
			var control := main.find_child(control_name, true, false) as Button
			var rect := control.get_global_rect() if control != null else Rect2()
			require(control != null and not control.text.is_empty() and rect.size.x > 0.0 and rect.size.y >= 48.0 and rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= float(size.x) and rect.end.y <= float(size.y), "%s is visible with readable text and a 48px target on first render at %s (rect %s)" % [control_name, size, rect])
		var opening_basic := main.find_child("BattleActionBasicAttack", true, false) as Button
		var opening_ability := main.find_child("BattleActionSignatureAbility", true, false) as Button
		var opening_defend := main.find_child("BattleActionDefend", true, false) as Button
		var opening_end := main.find_child("BattleActionEndTurn", true, false) as Button
		require(opening_basic != null and opening_basic.disabled and opening_ability != null and opening_ability.disabled and opening_defend != null and not opening_defend.disabled and opening_end != null and not opening_end.disabled and main.find_child("BattleOpeningGuidance", true, false) != null, "opening winner HUD disables attacks and guides Defend or End Turn at %s" % size)
		var secondary := main.find_child("BattleSecondaryToggle", true, false) as Button
		require(secondary != null and secondary.custom_minimum_size.y >= 48.0 and secondary.get_global_rect().size.y >= 48.0 and secondary.get_global_rect().end.y <= float(size.y), "Bench and Hand expander is visible on first render at %s" % size)
		if secondary != null:
			secondary.emit_signal("pressed")
			await get_tree().process_frame
			var bench := main.find_child("BattleBenchGrid", true, false) as GridContainer
			require(bench != null and bench.get_child_count() > 0 and bench.get_global_rect().end.y <= float(size.y), "expanded Bench has a reachable switch at %s (rect %s)" % [size, bench.get_global_rect() if bench != null else Rect2()])
			var hand_tab := main.find_child("BattleSecondaryHandTab", true, false) as Button
			if hand_tab != null:
				hand_tab.emit_signal("pressed")
				await get_tree().process_frame
			var hand := main.find_child("BattleHandGrid", true, false) as GridContainer
			var hand_carousel := main.find_child("BattleHandCarousel", true, false) as ScrollContainer
			var hand_scroll := main.find_child("BattleSecondaryScroll", true, false) as ScrollContainer
			var hand_viewport := main.find_child("BattleSecondaryViewport", true, false) as Control
			var viewport_rect := hand_viewport.get_global_rect() if hand_viewport != null else Rect2()
			require(hand != null and hand.get_child_count() > 0 and hand_carousel != null and hand_scroll != null and hand_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and viewport_rect.size.y >= 48.0 and viewport_rect.end.y <= float(size.y) and hand_carousel.custom_minimum_size.y >= 225.0, "expanded Hand retains 2:3 cards in a bounded, reachable tactical scroll viewport at %s (rect %s)" % [size, viewport_rect])
			var concede_tab := main.find_child("BattleSecondaryConcedeTab", true, false) as Button
			if concede_tab != null:
				concede_tab.emit_signal("pressed")
				await get_tree().process_frame
			var concede := main.find_child("BattleActionConcede", true, false) as Button
			require(concede != null and concede.get_global_rect().end.y <= float(size.y), "expanded Concede control is reachable at %s (rect %s)" % [size, concede.get_global_rect() if concede != null else Rect2()])
			var before_log: int = main.battle.log.size()
			main.intent({"type":"defend"})
			await get_tree().process_frame
			require(main.battle.log.size() > before_log, "expanded battle submits a legal core action at %s" % size)
	# The two legal opening choices must be actionable through their visible UI,
	# not merely enabled decoration.
	for opening_control_name in ["BattleActionDefend", "BattleActionEndTurn"]:
		main.screen = "battle"
		main.battle_secondary_open = false
		main.battle = BattleState.create(GameManager.current_team_loadout(), ["mossmunk"], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
		main.battle_session_generation += 1
		main.ai_pending = false
		main.render()
		await get_tree().process_frame
		var opening_control := main.find_child(opening_control_name, true, false) as Button
		var opening_control_enabled := opening_control != null and not opening_control.disabled
		var opening_log: int = main.battle.log.size()
		if opening_control != null: opening_control.emit_signal("pressed")
		require(opening_control_enabled and main.battle.active_player == 1 and main.battle.turn == 2 and main.battle.log.size() > opening_log, "%s advances a legal opening turn through the action dock" % opening_control_name)
	for multi_turn_size in [Vector2i(576, 1024), Vector2i(1280, 720)]:
		await _assert_multi_turn_dock_stability(main, multi_turn_size)
	# A deferred callback captured for the previous match must not mutate this
	# replacement match after its presentation delay.
	var stale_state: BattleState = main.battle
	var stale_generation: int = main.battle_session_generation
	main.start_battle()
	var replacement_log_size: int = main.battle.log.size()
	var replacement_turn: int = main.battle.turn
	var replacement_active: int = main.battle.active_player
	main.run_ai(stale_state, stale_generation)
	require(main.battle.log.size() == replacement_log_size and main.battle.turn == replacement_turn and main.battle.active_player == replacement_active, "stale AI callback cannot mutate a replacement training match")
	# Reproduce a legacy Android snapshot that only kept an ID and current health.
	# The normalizer must restore catalog combat/presentation fields before the HUD
	# builds the four moves or the player summary.
	var legacy_size := Vector2i(576, 1024)
	get_viewport().size = legacy_size
	main.size = Vector2(legacy_size)
	main.screen = "battle"
	main.battle_secondary_open = false
	main.battle = BattleState.create(GameManager.current_team_loadout(), ["voidmanta"], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
	var legacy_snapshot: Dictionary = main.battle.serialize().duplicate(true)
	legacy_snapshot.players[0].team[0] = {"creature_id":"cinderpaw", "health":34}
	legacy_snapshot.turn = 2
	legacy_snapshot.active_player = 0
	legacy_snapshot.opening_player = 1
	main.battle = BattleState.from_snapshot(legacy_snapshot)
	main.render()
	await get_tree().process_frame
	await get_tree().process_frame
	var normalized: Dictionary = main.battle.active_unit(0)
	require(str(normalized.get("id", "")) == "cinderpaw" and str(normalized.get("name", "")) == "Cinderpaw" and int(normalized.get("hp", 0)) == 34 and int(normalized.get("attack", 0)) == 9, "legacy active unit inherits catalog identity and keeps runtime health")
	require(tree_has_text(main, "You: Cinderpaw") and tree_has_text(main, "34/34 HP - Fire"), "normalized legacy player summary renders after Voidmanta rival")
	for control_name in ["BattleActionBasicAttack", "BattleActionSignatureAbility", "BattleActionDefend", "BattleActionEndTurn", "BattleSecondaryToggle"]:
		require(main.find_child(control_name, true, false) != null, "legacy runtime renders %s" % control_name)
	var legacy_attack := main.find_child("BattleActionBasicAttack", true, false) as Button
	var void_hp: int = int(main.battle.active_unit(1).get("hp", 0))
	var legacy_log_size: int = main.battle.log.size()
	if legacy_attack != null: legacy_attack.emit_signal("pressed")
	await get_tree().process_frame
	require(main.battle.log.size() > legacy_log_size and int(main.battle.active_unit(1).get("hp", void_hp)) < void_hp, "legacy Basic Attack applies through the canonical normalized combat state")
	main.screen = "local_vs"
	main.local_authority = LocalBattleAuthority.create(GameManager.current_team_loadout(), ["mossmunk"], GameManager.active_deck_cards(), 20260815)
	main.local_ready_seat = int(main.local_authority.state.active_player)
	main.render()
	await get_tree().process_frame
	var local_grid := main.find_child("LocalBattleActionGrid", true, false) as GridContainer
	require(local_grid != null and local_grid.columns == 2, "local-versus actions use a portrait-safe grid")
	main.queue_free()
	if failures.is_empty(): print("PASS: checkpoint A1 responsive battle action layout")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
