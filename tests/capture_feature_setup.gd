class_name CaptureFeatureSetup
extends RefCounted
## Feature-local deterministic capture setup. The harness remains responsible
## only for process arguments, fixture profile, settle checks, and PNG output.

static func configure_battle(main, mode: String) -> bool:
	if mode in ["battle_hand_cards", "high_contrast_cards"]:
		main.screen = "battle"
		main.battle = BattleState.create(GameManager.current_team_loadout(), ["mossmunk"], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
		main.battle.players[0].hand = ["coolant", "final_pass"]
		main.battle.players[0].filament = 1
		main.battle_secondary_open = true; main.battle_secondary_tab = "hand"
		if mode == "high_contrast_cards": GameManager.profile.settings.high_contrast = true
		return true
	var vfx_creatures := {"battle_vfx_fire":"cinderpaw", "battle_vfx_water":"aquafin", "battle_vfx_lightning":"voltwig", "battle_vfx_nature":"mossmunk", "battle_vfx_ice":"frostling", "battle_vfx_stone":"stoneback", "battle_vfx_wind":"galehopper", "battle_vfx_arcane":"runestag"}
	if mode in ["battle", "battle_review", "battle_secondary", "battle_hand", "battle_impact", "battle_voidmanta", "high_contrast_battle", "reduced_motion_battle", "trial_battle", "trial_battle_legacy", "trial_battle_teamlaunch", "battle_vfx_idle", "battle_vfx_basic"] or vfx_creatures.has(mode):
		main.screen = "battle"
		if mode in ["trial_battle", "trial_battle_legacy", "trial_battle_teamlaunch"]:
			var encounter := Catalog.workshop_trial_encounter("first_layers_1")
			var setup := GameManager.create_solo_battle(encounter.get("team", []), int(encounter.get("spool", 3)), 2)
			main.battle = setup.get("battle", null) as BattleState
			main.battle_launch_notice = str(setup.get("repair_message", "")) if bool(setup.get("temporary_repair", false)) or bool(setup.get("unarmored_retry", false)) else ""
			main.battle_mode = "trial"
			main.trial_encounter_id = "first_layers_1"
			main.battle_ai_difficulty = str(encounter.get("ai", "Apprentice"))
		elif vfx_creatures.has(mode):
			main.battle = BattleState.create([str(vfx_creatures[mode])], ["mossmunk"], 5, 3, 2, ["raw_filament", "quick_patch"])
			main.battle_last_event = "ability"
			main.battle_last_actor = 0
			main.battle_presentation_serial = 1
		elif mode == "battle_vfx_basic":
			main.battle = BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2, ["raw_filament", "quick_patch"])
			main.battle_last_event = "attack"
			main.battle_last_actor = 0
			main.battle_presentation_serial = 1
		else:
			var rival := "voidmanta" if mode == "battle_voidmanta" else "mossmunk"
			main.battle = BattleState.create(GameManager.current_team_loadout(), [rival], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
		main.battle_secondary_open = mode in ["battle_secondary", "battle_hand"]
		main.battle_secondary_tab = "hand" if mode == "battle_hand" else "bench"
		if mode == "battle_impact":
			main.battle_last_event = "attack"
			main.battle_presentation_serial = 1
		return true
	if mode in ["local_vs", "local_card_handoff"]:
		main.screen = "local_vs"
		main.local_authority = LocalBattleAuthority.create(GameManager.current_team_loadout(), ["mossmunk", "voltwig"], GameManager.active_deck_cards(), 20260814)
		return true
	if mode in ["local_vs_ready", "local_card_revealed"]:
		main.screen = "local_vs"
		main.local_authority = LocalBattleAuthority.create(GameManager.current_team_loadout(), ["mossmunk", "voltwig"], GameManager.active_deck_cards(), 20260814)
		main.local_ready_seat = main.local_authority.state.active_player
		return true
	return false

static func configure_forge(main, mode: String) -> bool:
	if mode not in ["printer_preview", "printer_printing", "printer_raw_complete", "printer_raw_hold", "printer_awakening", "printer_departing", "printer_awakened", "printer_reduced", "printer_mossmunk_raw_complete", "armor_preview", "armor_printing", "armor_raw_hold", "armor_awakened", "armor_shadow_raw_hold", "armor_full_suit_awakened"]:
		return false
	main.screen = "printer"
	main.printer_is_armor = mode.begins_with("armor_")
	main.printer_armor_id = "shadow_cloak" if mode == "armor_shadow_raw_hold" else ("full_suit" if mode == "armor_full_suit_awakened" else ("helm" if main.printer_is_armor else ""))
	main.printer_creature_id = "mossmunk" if mode == "printer_mossmunk_raw_complete" else "cinderpaw"
	main.printer_price = int(ProgressionRules.armor_def(main.printer_armor_id).get("print", 0)) if main.printer_is_armor else int(Catalog.rarity(str(Catalog.creature(main.printer_creature_id).rarity)).print)
	main.printer_sequence = ArcaneForgeSequence.create(mode == "printer_reduced", main.printer_is_armor)
	if mode in ["printer_preview", "armor_preview"]: return true
	main.printer_sequence.begin()
	if mode in ["printer_printing", "armor_printing"]:
		main.printer_sequence.advance(3600)
		return true
	main.printer_sequence.advance(7000)
	if mode not in ["printer_raw_hold", "printer_awakening", "printer_departing", "printer_awakened", "printer_reduced", "armor_raw_hold", "armor_awakened", "armor_shadow_raw_hold", "armor_full_suit_awakened"]:
		return true
	main.printer_sequence.request_commit()
	main.printer_sequence.resolve_commit(true)
	if mode in ["printer_awakening", "printer_departing", "printer_awakened", "printer_reduced", "armor_awakened", "armor_full_suit_awakened"]:
		main.printer_sequence.advance(ArcaneForgeSequence.RAW_HOLD_BPS)
		main.printer_sequence.advance(900 if mode == "printer_awakening" else ArcaneForgeSequence.AWAKEN_BPS)
	if mode in ["printer_departing", "printer_awakened", "printer_reduced", "armor_awakened", "armor_full_suit_awakened"]:
		main.printer_sequence.advance(450 if mode == "printer_departing" else ArcaneForgeSequence.DEPART_BPS)
	return true

static func configure_workshop(main, mode: String) -> bool:
	if mode in ["card_archive", "card_detail", "deck_cards", "shop_cards"]:
		main.screen = {"card_archive":"archive", "card_detail":"archive", "deck_cards":"deck", "shop_cards":"shop"}.get(mode, "archive")
		if mode == "card_detail": main.card_archive_detail_id = "coolant"
		return true
	if mode in ["trials", "trials_scrolled", "trials_legacy", "trials_teamlaunch"]:
		main.screen = "trials"
		if mode == "trials_scrolled": main.set_meta("capture_scroll_trials", true)
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
