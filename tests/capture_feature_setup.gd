class_name CaptureFeatureSetup
extends RefCounted
## Feature-local deterministic capture setup. The harness remains responsible
## only for process arguments, fixture profile, settle checks, and PNG output.

static func configure_battle(main, mode: String) -> bool:
	if mode in ["battle", "battle_review", "battle_secondary", "battle_hand", "battle_impact", "battle_voidmanta", "high_contrast_battle", "reduced_motion_battle", "trial_battle"]:
		main.screen = "battle"
		if mode == "trial_battle":
			var encounter := Catalog.workshop_trial_encounter("first_layers_1")
			main.battle = BattleState.create(GameManager.current_team_loadout(), encounter.get("team", []), GameManager.filament_cap(), int(encounter.get("spool", 3)), 2, GameManager.active_deck_cards())
			main.battle_mode = "trial"
			main.trial_encounter_id = "first_layers_1"
			main.battle_ai_difficulty = str(encounter.get("ai", "Apprentice"))
		else:
			var rival := "voidmanta" if mode == "battle_voidmanta" else "mossmunk"
			main.battle = BattleState.create(GameManager.current_team_loadout(), [rival], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
		main.battle_secondary_open = mode in ["battle_secondary", "battle_hand"]
		main.battle_secondary_tab = "hand" if mode == "battle_hand" else "bench"
		if mode == "battle_impact": main.battle_last_event = "attack"
		return true
	if mode == "local_vs":
		main.screen = "local_vs"
		main.local_authority = LocalBattleAuthority.create(GameManager.current_team_loadout(), ["mossmunk", "voltwig"], GameManager.active_deck_cards(), 20260814)
		return true
	if mode == "local_vs_ready":
		main.screen = "local_vs"
		main.local_authority = LocalBattleAuthority.create(GameManager.current_team_loadout(), ["mossmunk", "voltwig"], GameManager.active_deck_cards(), 20260814)
		main.local_ready_seat = main.local_authority.state.active_player
		return true
	return false

static func configure_forge(main, mode: String) -> bool:
	if mode not in ["printer_preview", "printer_printing", "printer_raw_complete", "printer_raw_hold", "printer_awakening", "printer_departing", "printer_awakened", "printer_reduced", "printer_mossmunk_raw_complete", "armor_preview", "armor_printing", "armor_raw_hold", "armor_awakened"]:
		return false
	main.screen = "printer"
	main.printer_is_armor = mode.begins_with("armor_")
	main.printer_armor_id = "helm" if main.printer_is_armor else ""
	main.printer_creature_id = "mossmunk" if mode == "printer_mossmunk_raw_complete" else "cinderpaw"
	main.printer_price = int(ProgressionRules.armor_def(main.printer_armor_id).get("print", 0)) if main.printer_is_armor else int(Catalog.rarity(str(Catalog.creature(main.printer_creature_id).rarity)).print)
	main.printer_sequence = ArcaneForgeSequence.create(mode == "printer_reduced", main.printer_is_armor)
	if mode in ["printer_preview", "armor_preview"]: return true
	main.printer_sequence.begin()
	if mode in ["printer_printing", "armor_printing"]:
		main.printer_sequence.advance(3600)
		return true
	main.printer_sequence.advance(7000)
	if mode not in ["printer_raw_hold", "printer_awakening", "printer_departing", "printer_awakened", "printer_reduced", "armor_raw_hold", "armor_awakened"]:
		return true
	main.printer_sequence.request_commit()
	main.printer_sequence.resolve_commit(true)
	if mode in ["printer_awakening", "printer_departing", "printer_awakened", "printer_reduced", "armor_awakened"]:
		main.printer_sequence.advance(ArcaneForgeSequence.RAW_HOLD_BPS)
		main.printer_sequence.advance(900 if mode == "printer_awakening" else ArcaneForgeSequence.AWAKEN_BPS)
	if mode in ["printer_departing", "printer_awakened", "printer_reduced", "armor_awakened"]:
		main.printer_sequence.advance(450 if mode == "printer_departing" else ArcaneForgeSequence.DEPART_BPS)
	return true

static func configure_workshop(main, mode: String) -> bool:
	if mode == "trials":
		main.screen = "trials"
		return true
	if mode in ["station_live_printer_start", "station_live_printer_mid", "station_live_printer_hold", "station_live_printer_awakening", "station_live_printer_departing", "station_live_maker_team", "station_live_reduced", "station_live_review"]:
		main.screen = "workshop"
		main.workshop_view = "maker" if mode == "station_live_maker_team" else "printer"
		main.workshop_station_live_capture_progress = {"station_live_printer_start":0, "station_live_printer_mid":4400, "station_live_printer_hold":11000, "station_live_printer_awakening":14000, "station_live_printer_departing":15500, "station_live_maker_team":11000, "station_live_reduced":11000, "station_live_review":11000}.get(mode, 0)
		return true
	if mode in ["workshop_printer_picker", "printer_picker_preview_mossmunk"]:
		if mode == "workshop_printer_picker":
			main.screen = "workshop"
			main.workshop_view = "printer"
			main.printer_picker_open = true
		else:
			main.screen = "printer"
			main.printer_creature_id = "mossmunk"
			main.printer_price = int(Catalog.rarity(str(Catalog.creature("mossmunk").rarity)).print)
			main.printer_sequence = ArcaneForgeSequence.create(false)
		return true
	if mode in ["workshop_printer", "workshop_maker", "workshop_terminal", "workshop_terminal_offers", "workshop_terminal_forgedex", "workshop_terminal_trade", "workshop_proving", "workshop_yard", "workshop_maker_drawer", "workshop_proving_drawer"]:
		main.screen = "workshop"
		main.workshop_view = "maker" if mode == "workshop_maker_drawer" else ("proving" if mode == "workshop_proving_drawer" else ("terminal" if mode.begins_with("workshop_terminal_") else str(mode).trim_prefix("workshop_")))
		main.workshop_drawer_object = "armor_tools" if mode == "workshop_maker_drawer" else ("training_door" if mode == "workshop_proving_drawer" else "")
		return true
	return false
