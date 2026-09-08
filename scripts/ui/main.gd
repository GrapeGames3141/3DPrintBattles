extends Control

## Runtime-safe workshop presentation; final character art remains approval-gated.
const REFERENCE_TEXTURE := preload("res://assets/ui/workshop/workshop-theme-reference-fallback.jpg")
const WORKSHOP_OVERVIEW_LANDSCAPE_TEXTURE := preload("res://assets/ui/workshop/workshop_overview_landscape_v4.png")
const WORKSHOP_OVERVIEW_PORTRAIT_TEXTURE := preload("res://assets/ui/workshop/workshop_overview_portrait_v4.png")
const WORKSHOP_AMBIENT_LAYER := preload("res://scripts/ui/workshop_ambient_layer.gd")
const WORKSHOP_HOTSPOT_OVERLAY := preload("res://scripts/ui/workshop_hotspot_overlay.gd")
const WORKSHOP_PAN_AFFORDANCE := preload("res://scripts/ui/workshop_pan_affordance.gd")
const BLUEPRINT_SCHEMATIC_OVERLAY := preload("res://scripts/ui/blueprint_schematic_overlay.gd")
const BLUEPRINT_SCHEMATIC_SHADER := preload("res://scripts/ui/blueprint_schematic.gdshader")
const TOUCH_SCROLL_CONTAINER := preload("res://scripts/ui/touch_scroll_container.gd")
const SUPPORT_CARD_PRESENTER_PATH := "res://scripts/ui/support_card_presenter.gd"
const SUPPORT_CARD_VIEW_PATH := "res://scripts/ui/support_card_view.gd"
const BATTLE_FEEDBACK_PRESENTER_PATH := "res://scripts/ui/battle_feedback_presenter.gd"
const EQUIPMENT_WORKBENCH_VIEW_PATH := "res://scripts/ui/equipment_workbench_view.gd"
# TieredArmorRoster remains species-neutral and is loaded only by the Equipment
# Workbench path, so the workshop's first frame never parses its preview graph.
const TIERED_ARMOR_ROSTER_PATH := "res://scripts/ui/tiered_armor_roster.gd"
const TIERED_ARMOR_PREVIEW_PATH := "res://scripts/ui/tiered_armor_palette_preview.gd"
const BLUEPRINT_TRAY_VIEW := preload("res://scripts/ui/blueprint_tray_view.gd")
const FORGE_SCREEN_COMPONENT_PATH := "res://scripts/ui/arcane_forge_screen_component.gd"
const PHYSICAL_FORGE_SCREEN_COMPONENT_PATH := "res://scripts/ui/physical_forge_screen_component.gd"
const BATTLE_SPRITE_STAGE_PATH := "res://scripts/ui/battle_sprite_stage.gd"
const UNIFIED_BATTLE_SCREEN_COMPONENT_PATH := "res://scripts/ui/unified_battle_screen_component.gd"
const ARCANE_FOUNDRY_THEME_KIT := preload("res://scripts/ui/arcane_foundry_theme_kit.gd")
const UNIFIED_BATTLE_COORDINATOR := preload("res://scripts/battle/unified_battle_cycle_coordinator.gd")
const UNIFIED_RULES := preload("res://scripts/core/unified_rules.gd")
const UNIFIED_CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
const PORTRAIT_PRESENTATION_BOUNDARY := preload("res://scripts/ui/portrait_presentation_boundary.gd")
const CREATURE_SPRITE_CACHE := preload("res://scripts/ui/creature_sprite_cache.gd")
const BATTLE_MOVE_VFX := preload("res://scripts/ui/battle_move_vfx.gd")
const PHYSICAL_PORTRAIT_PLATE := preload("res://scripts/ui/physical_portrait_plate_presenter.gd")
const M1_PHYSICAL_UI := preload("res://scripts/ui/m1_physical_ui_component.gd")
const M3_PHYSICAL_UI := preload("res://scripts/ui/m3_physical_ui_component.gd")
const PHYSICAL_NAVIGATION := preload("res://scripts/ui/physical_navigation_component.gd")
const PHYSICAL_CONTROL_FAMILY := preload("res://scripts/ui/physical_control_family.gd")
const PHYSICAL_CATALOG_IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const REVIEW_BUILD_LABEL := "0.8.9-ui-alignment"
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

var screen := "title"
var workshop_selected := "printer"
var workshop_view := "overview"
var workshop_drawer_object := ""
var printer_picker_open := false
var printer_blueprint_selected_id := ""
var workshop_return_view := "overview"
var settings_return_screen := "workshop"
var pending_starter_id := ""
var starter_inspector_id := ""
var starter_page := 0
var shop_day_key := ""
var team_draft: Array = []
var deck_draft: Array = []
var deck_selected_card_id := ""
var deck_slot_id := ProgressionRules.STARTER_DECK_ID
var card_archive_owned_only := false
var card_archive_detail_id := ""
# `battle` is deliberately untyped so the shell can recover an interrupted
# session, but every shipped launch now stores a canonical v3 snapshot here.
# The older active-unit renderer remains isolated for historical test fixtures
# and is no longer an entry point from Workshop, Daily Training, Trials, or
# local hot-seat play.
var battle
var unified_battle_coordinator: UnifiedBattleCycleCoordinator = UNIFIED_BATTLE_COORDINATOR.new()
var battle_settlement_context: Dictionary = {}
var battle_settlement_finished := false
var toast := ""
var unified_hand_page := 0
var unified_selected_card_id := ""
var unified_selected_slot := -2
var unified_selected_target := -2
var unified_attack_slot := -1
var unified_attack_target := -2
var unified_ai_pending := false
const UNIFIED_AI_STEP_BUDGET := 48
var unified_ai_steps := 0
var unified_local_handoff := false
var unified_arrival_presented: Dictionary = {}
# Visual receipts are deliberately separate from UnifiedBattleState.  They only
# exist after an accepted intent and contain stage-safe public creature IDs.
var unified_battle_presentation: Dictionary = {"kind":"", "actor":0, "token":0}
var unified_page := 0
var unified_deck_draft: Array = []
var unified_preprint_draft: Array = []
var feedback_deck_draft_initialized := false
var feedback_deck_loaded_slot := ""
var unified_printer_draft: Array = []
var unified_printer_page := 0
var unified_codex_page := 0
var unified_inspector_id := ""
var unified_inspector_tab := "card"
var unified_reveal_page := 0
var unified_market_tab := "blueprints"
var unified_archive_filter := "all"
var m3_archive_owned_only := false
var m3_archive_printable_only := false
var m3_deck_edit_slot_id := "starter-deck"
var m3_pending_deck_slot_id := ""
var m3_deck_loaded_slot_id := ""
var m3_market_snapshot: Dictionary = {}
var m3_market_revision := -1
var m3_market_day_key := ""
var m3_action_in_flight := false
var m3_market_confirmation: Dictionary = {}
var m3_settings_draft: Dictionary = {}
var m3_settings_draft_initialized := false
var m3_result_state := "idle"
var m3_result_receipt: Dictionary = {}
var m3_recovery_new_maker_confirm := false
var m3_saved_preprint_draft: Array = []
var m3_pack_inspector_id := ""
var m3_pack_return_screen := "workshop"
var m3_pack_return_context: Dictionary = {"caller":"workshop"}
var title_new_maker_confirmation := false
var title_new_maker_in_flight := false
var title_new_maker_error := ""
var title_exit_confirmation := false
var battle_back_confirmation := false
var _last_back_dispatch_frame := -1
var _system_back_pending := false
var body: VBoxContainer
var status: Label
var battle_mode := "training"
var training_contract_id := ""
var trial_encounter_id := ""
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
var printer_progress_bar: ProgressBar
var team_draft_dirty := false
var calibration_values: Array[int] = [50, 50, 50]
var calibration_step := 0
var _focus_after_render := true
var workshop_ambient_capture_freeze := false
var workshop_station_live_capture_progress := -1
var workshop_station_live_capture_seed := 17
var overview_layout_portrait := false
var _workshop_screen_component := WorkshopScreenComponent.new()
var _portrait_presentation_boundary := PORTRAIT_PRESENTATION_BOUNDARY.new()
var _blueprint_tray_view := BLUEPRINT_TRAY_VIEW.new()
# Battle, Forge, cards, and equipment are intentionally absent from the first
# workshop frame. Their resources now load only when their screen is requested.
var _unified_battle_screen_component = null
var _forge_screen_component = null
var _physical_forge_screen_component = null
var _audio_director := AudioDirector.new()
var _m3_physical_ui := M3_PHYSICAL_UI.new()

func settings() -> Dictionary:
	return GameManager.profile.get("settings", AccessibilityRules.defaults())

func scaled_font(base: int) -> int:
	return maxi(12, (base * int(settings().get("text_scale_bps", 10000))) / 10000)

func is_portrait_layout() -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return viewport_size.y > viewport_size.x

func _optional_script(path: String, feature_name: String):
	var script = ResourceLoader.load(path)
	if script == null:
		push_error("%s resource could not load: %s" % [feature_name, path])
		_toast("%s could not load. The Workshop remains available." % feature_name)
	return script

func _unified_battle_component():
	if _unified_battle_screen_component == null:
		var script = _optional_script(UNIFIED_BATTLE_SCREEN_COMPONENT_PATH, "Foundry battle screen")
		if script == null: return null
		_unified_battle_screen_component = script.new()
	return _unified_battle_screen_component

func _forge_component():
	if _forge_screen_component == null:
		var script = _optional_script(FORGE_SCREEN_COMPONENT_PATH, "Forge presentation")
		if script == null: return null
		_forge_screen_component = script.new()
	return _forge_screen_component

func _physical_forge_component():
	if _physical_forge_screen_component == null:
		var script = _optional_script(PHYSICAL_FORGE_SCREEN_COMPONENT_PATH, "Forge continuity station")
		if script == null: return null
		_physical_forge_screen_component = script.new()
	return _physical_forge_screen_component

func _new_support_card_view():
	var script = _optional_script(SUPPORT_CARD_VIEW_PATH, "Support card view")
	return null if script == null else script.new()

func _new_local_battle_stage():
	var script = _optional_script(BATTLE_SPRITE_STAGE_PATH, "Local battle presentation")
	return null if script == null else script.new()

func _present_unified_battle_event(event: Dictionary) -> void:
	if event.is_empty(): return
	var token := int(unified_battle_presentation.get("token", 0)) + 1
	# Keep the whole public receipt.  The physical stage needs the exact source
	# and target slots (and public pre-action units) to animate causally; reducing
	# it to a generic left/right pair made every attack appear static.
	unified_battle_presentation = event.duplicate(true)
	unified_battle_presentation["kind"] = str(event.get("kind", ""))
	unified_battle_presentation["actor"] = int(event.get("actor", 0))
	unified_battle_presentation["token"] = token
	unified_battle_presentation["generation"] = int(event.get("generation", unified_battle_coordinator.generation))
	_schedule_unified_presentation_settlement(token, str(event.get("kind", "")))

func _reset_unified_battle_presentation() -> void:
	# Advance the serial on reset as well: a timer from a prior battle can never
	# settle a newly launched battle that happens to have the same event count.
	unified_battle_presentation = {"kind":"", "actor":0, "token":int(unified_battle_presentation.get("token", 0)) + 1}

func _leave_unified_battle() -> void:
	unified_battle_coordinator.invalidate_generation()
	battle = null
	battle_settlement_context.clear()
	unified_ai_pending = false
	unified_ai_steps = 0
	_reset_unified_battle_presentation()
	screen = "workshop"
	render()

func _unified_presentation_wait_seconds(kind: String) -> float:
	if bool(settings().get("reduced_motion", false)): return 0.0
	return _unified_presentation_duration(kind) + 0.10

func _unified_presentation_duration(kind: String) -> float:
	if kind == "deploy": return BATTLE_MOVE_VFX.event_duration("deploy")
	match kind:
		"print": return 0.78
		"attack", "ability": return 0.62
		"defend": return 0.42
		"card": return 0.52
		"switch": return 0.48
	return 0.0

func _schedule_unified_presentation_settlement(token: int, kind: String) -> void:
	if kind.is_empty() or not is_inside_tree(): return
	var delay := _unified_presentation_duration(kind) + 0.02
	if bool(settings().get("reduced_motion", false)): delay = 0.0
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(_settle_unified_battle_presentation.bind(token))

func _settle_unified_battle_presentation(token: int) -> void:
	# Token matching prevents a delayed timer from clearing a newer player action,
	# a subsequent AI receipt, or a completely new battle after leaving the arena.
	if battle == null or token != int(unified_battle_presentation.get("token", -1)) or str(unified_battle_presentation.get("kind", "")).is_empty(): return
	if int(unified_battle_presentation.get("generation", -1)) != unified_battle_coordinator.generation: return
	# Ack only the receipt that is still visible; a late timer from a replaced
	# match or newer action cannot unlock a different coordinator request.
	unified_battle_coordinator.acknowledge_presentation(int(unified_battle_presentation.get("generation", -1)))
	unified_battle_presentation = {"kind":"", "actor":0, "token":token}
	if screen == "unified_battle": render()

func _ready() -> void:
	print("PRINTFORGE_STARTUP marker=ui_ready renderer=%s platform=%s" % [RenderingServer.get_current_rendering_method(), OS.get_name()])
	if shop_day_key.is_empty(): shop_day_key = Time.get_date_string_from_system()
	GameManager.profile_changed.connect(render)
	GameManager.toast_requested.connect(_toast)
	add_child(_audio_director)
	_audio_director.configure(settings(), false)
	# A capture harness may select a non-default destination before this node enters
	# the tree. Normal launches use the workshop default and route from profile state.
	if screen == "workshop": screen = OnboardingState.screen_for_profile(GameManager.profile)
	render()
	call_deferred("_emit_first_frame_marker")

func _emit_first_frame_marker() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	print("PRINTFORGE_STARTUP marker=first_frame screen=%s viewport=%dx%d" % [screen, int(viewport_size.x), int(viewport_size.y)])

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree():
		# Window notifications propagate while the scene tree is walking children.
		# Render only after that walk so a native Back cannot rebuild the tree from
		# inside notification propagation.
		if not _system_back_pending:
			_system_back_pending = true
			call_deferred("_dispatch_pending_system_back")
		return
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		# Containers handle ordinary resize. An orientation flip needs its matching
		# v3 overview plate and fresh normalized hotspot layout.
		if screen == "workshop" and workshop_view == "overview" and is_portrait_layout() != overview_layout_portrait:
			call_deferred("render")
		queue_redraw()

func _exit_tree() -> void:
	if _forge_screen_component != null:
		_forge_screen_component.dispose()
	if _unified_battle_screen_component != null:
		_unified_battle_screen_component.dispose()
	if _workshop_screen_component != null:
		_workshop_screen_component.dispose()

func _process(delta: float) -> void:
	if printer_capture_freeze: return
	if screen != "printer" or printer_sequence == null: return
	if _physical_forge_screen_component != null and _physical_forge_screen_component.blocks_presentation_advance(): return
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
	# Foundry hotspots now resolve to the unified card surfaces. Legacy routes
	# remain available to retained screens under their explicit legacy ids.
	var unified_targets := {"shop":"unified_market", "archive":"unified_library", "armor":"unified_library", "deck":"unified_deck", "team":"unified_deck", "calibration":"unified_upgrades", "codex":"unified_forgedex", "collection":"unified_forgedex", "yard":"unified_market"}
	if unified_targets.has(target): target = str(unified_targets[target])
	if target == "unified_deck" and screen != "unified_deck":
		feedback_deck_draft_initialized = false
		m3_deck_loaded_slot_id = ""
	if target == "unified_market" and screen != "unified_market":
		m3_market_snapshot.clear()
		m3_market_revision = -1
	if target == "settings" and screen != "settings":
		# Settings is inspection-only until an explicit setting action. Preserve the
		# exact presentation origin so Title never silently becomes Workshop.
		settings_return_screen = screen
	if screen == "workshop" and target != "workshop":
		workshop_return_view = workshop_view
	if target == "workshop":
		workshop_view = workshop_return_view
		workshop_drawer_object = ""
	screen = target
	# Daily snapshots are a launch/navigation transition, never a render side
	# effect. This avoids recursive profile_changed -> render rebuilds.
	if target == "proving": GameManager.prepare_daily_training(shop_day_key)
	render()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode in [KEY_ESCAPE, KEY_BACK]): return
	if _system_back_pending:
		get_viewport().set_input_as_handled()
		return
	request_back()
	get_viewport().set_input_as_handled()

func _dispatch_pending_system_back() -> void:
	_system_back_pending = false
	request_back()

func request_back() -> void:
	# Android may surface KEY_BACK and WM_GO_BACK_REQUEST for one gesture.  The
	# frame guard keeps both routes on one dispatcher without dropping a later key.
	# A package/catalog failure happens before any profile normalization or write.
	# Its recovery plate has one safe exit; routing to Title would only rebuild the
	# same blocking plate.
	if str(GameManager.save_compatibility.get("state", "")) == "catalog_unavailable":
		get_tree().quit()
		return
	var frame := Engine.get_process_frames()
	if _last_back_dispatch_frame == frame: return
	_last_back_dispatch_frame = frame
	dispatch_back()

func dispatch_back() -> void:
	# Visible controls, Escape, and Android system Back converge here. Foremost
	# local state resolves before route navigation so no draft/receipt/job is lost.
	_focus_after_render = true
	if screen == "title" and title_exit_confirmation:
		_title_cancel_exit()
		return
	if screen == "title" and title_new_maker_confirmation:
		_title_cancel_new_maker()
		return
	if screen == "title":
		_title_request_exit()
		return
	# Modal dismissal takes precedence over route navigation.  The image-led
	# routes are full-screen, so leaving their inspector first is especially
	# important for keyboard and controller players.
	if not starter_inspector_id.is_empty():
		starter_inspector_id = ""
		render()
		return
	if screen == "m3_pack":
		_m3_back_from_pack()
		return
	# Archive detail state can legitimately be retained as the Forge caller. It is
	# only foremost while the Archive surface owns it; otherwise it must not eat a
	# Back intended for Forge/Deck.
	if screen == "unified_library" and not unified_inspector_id.is_empty():
		unified_inspector_id = ""
		render()
		return
	if not m3_market_confirmation.is_empty():
		if m3_action_in_flight:
			_toast("Order is being recorded. Please wait for this receipt.")
			render()
			return
		_m3_cancel_market_purchase()
		return
	if screen == "workshop":
		if not workshop_drawer_object.is_empty():
			close_workshop_drawer()
		elif workshop_view != "overview":
			open_workshop_view("overview")
		else:
			navigate_to("title")
		return
	if screen == "printer":
		_dispatch_forge_back()
		return
	if screen == "unified_deck":
		# Android Back on the dirty-exit docket means Stay: dismiss the docket,
		# retain the exact local deck/Pre-Print draft, and do not turn a second
		# Back into an implicit exit or discard.
		if m3_pending_deck_slot_id == "__back__":
			_m3_resolve_dirty_deck("cancel")
			return
		_m3_request_deck_exit()
		return
	if screen == "settings":
		_m3_cancel_settings()
		return
	if screen == "proving":
		if bool(get_meta("battle_preflight", false)):
			set_meta("battle_preflight", false)
			render()
		else:
			navigate_to("workshop")
		return
	if screen == "unified_battle":
		# Local matches and authoritative finished fixtures without a settlement
		# context have no pending reward transaction. Their visible/system Return is
		# therefore safe to leave immediately. Non-local pending/error settlement
		# and every unfinished live battle remain deliberately consumed below.
		if battle != null and bool(battle.finished) and (battle_settlement_finished or battle_mode == "local" or battle_settlement_context.is_empty()):
			_leave_unified_battle()
			return
		if battle_back_confirmation:
			battle_back_confirmation = false
		else:
			battle_back_confirmation = true
		render()
		return
	if screen == "m3_result":
		if m3_result_state in ["committed", "duplicate"]:
			_m3_continue_result()
		else:
			_toast("Settlement is not complete. Retry or resolve this result first.")
			render()
		return
	if screen in ["unified_library", "unified_market"]:
		navigate_to("workshop")
		return
	if screen == "onboarding":
		navigate_to("title")
		return
	if screen != "workshop":
		screen = "workshop"
		workshop_view = workshop_return_view
		workshop_drawer_object = ""
		render()

func _dispatch_forge_back() -> void:
	if printer_sequence == null:
		_return_from_forge_idle()
		return
	if printer_sequence.phase == ArcaneForgeSequence.IDLE:
		_return_from_forge_idle()
		return
	if printer_sequence.phase in [ArcaneForgeSequence.AWAKENED, ArcaneForgeSequence.FAILED]:
		return_to_printer_station()
		return
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE:
		_toast("Forge record is securing. Back is temporarily unavailable until the commit resolves.")
		render()
		return
	# Accepted printing and its noninterruptible commit/presentation stages never
	# cancel through Back. Leave to the recorded caller while the exact sequence
	# remains intact; reopening the Forge resumes the same generation/progress.
	# Clear only the visual cadence accumulator: leaving at an almost-complete
	# interval must not consume a hidden layer the moment the caller reopens the
	# Forge. The accepted sequence/progress/commit state remain authoritative.
	printer_tick_accumulator = 0.0
	_toast("PRINT PAUSED · JOB SAFE. Return to the Forge to resume.")
	screen = printer_return_screen
	if screen == "workshop": workshop_view = workshop_return_view
	render()

func _return_from_forge_idle() -> void:
	if printer_sequence != null:
		printer_sequence.cancel()
	printer_creature_id = ""
	printer_armor_id = ""
	printer_is_armor = false
	printer_is_core = false
	screen = printer_return_screen
	if screen == "workshop": workshop_view = workshop_return_view
	render()

func _forge_back_label() -> String:
	if printer_return_screen == "title": return "BACK TO TITLE"
	if printer_return_screen == "workshop": return "BACK TO WORKSHOP"
	if printer_return_screen == "armor": return "BACK TO EQUIPMENT"
	if printer_return_screen == "onboarding": return "BACK TO ONBOARDING"
	return "BACK TO COLLECTION"

func _forge_back_compact_label() -> String:
	return _forge_back_label().replace(" TO ", " TO\n")

func _forge_back_accessibility() -> String:
	var destination := "Collection"
	match printer_return_screen:
		"title": destination = "Title"
		"workshop": destination = "Workshop"
		"armor": destination = "Equipment Workbench"
		"onboarding": destination = "Onboarding"
	return "Back to %s without starting or cancelling this print" % destination

func _m3_open_pending_pack(return_screen := "workshop") -> void:
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {}) if GameManager.profile.get("pending_pack_reveal", {}) is Dictionary else {}
	if pending.is_empty():
		_toast("There is no pack waiting to open.")
		render()
		return
	m3_pack_return_screen = str(pending.get("return_route", return_screen))
	if m3_pack_return_screen not in ["workshop", "unified_library", "unified_market", "settings"]:
		m3_pack_return_screen = "workshop"
	m3_pack_return_context = pending.get("return_context", {}) as Dictionary if pending.get("return_context", {}) is Dictionary else {}
	if str(m3_pack_return_context.get("caller", "")) not in ["workshop", "unified_library", "unified_market", "settings"]:
		m3_pack_return_context = {"caller":m3_pack_return_screen}
	var presentation := GameManager.pending_pack_presentation(str(pending.get("receipt", "")))
	m3_pack_inspector_id = str(presentation.get("inspector_id", ""))
	unified_reveal_page = maxi(0, int(presentation.get("page", 0)))
	# A Pack tile selection is inline, not a modal.  Give a newly opened receipt
	# useful facts immediately, then retain that exact selection in its receipt
	# sidecar for resume.  Existing valid selections remain untouched.
	if m3_pack_inspector_id.is_empty():
		var receipt_cards: Array = (pending.get("cards", []) as Array).duplicate()
		receipt_cards.append_array((pending.get("bonus_cards", []) as Array).duplicate())
		var first_index := unified_reveal_page * 5
		if first_index >= 0 and first_index < receipt_cards.size():
			m3_pack_inspector_id = str(receipt_cards[first_index])
			var saved := GameManager.save_pending_pack_presentation(str(pending.get("receipt", "")), unified_reveal_page, m3_pack_inspector_id)
			if not bool(saved.get("ok", false)):
				_toast(str(saved.get("error", "Pack position could not be saved.")))
	screen = "m3_pack"
	render()

func _m3_back_from_pack() -> void:
	# Receipt selection is inline and persisted.  Back always returns to its
	# caller in one action without clearing page or selected-card context.
	screen = str(m3_pack_return_context.get("caller", m3_pack_return_screen))
	if screen not in ["workshop", "unified_library", "unified_market", "settings"]: screen = "workshop"
	render()

func _m3_set_pack_presentation(page: int, inspector_id := "") -> void:
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {}) if GameManager.profile.get("pending_pack_reveal", {}) is Dictionary else {}
	var saved := GameManager.save_pending_pack_presentation(str(pending.get("receipt", "")), page, inspector_id)
	# A failed optional sidecar write must never trap the player inside an
	# inspector. Keep this local browsing state and report the persistence warning.
	unified_reveal_page = maxi(0, page)
	m3_pack_inspector_id = inspector_id
	if not bool(saved.get("ok", false)):
		_toast(str(saved.get("error", "Pack position could not be saved.")))
		render()
		return
	unified_reveal_page = int(saved.get("presentation", {}).get("page", unified_reveal_page))
	render()

func clear_children(node: Node) -> void:
	for child in node.get_children():
		if child == _audio_director: continue
		node.remove_child(child)
		child.queue_free()

func _foundry_surface(color: Color, strength := 0.11) -> Color:
	var steel := Color("171918")
	var semantic := Color(color.r, color.g, color.b, 1.0)
	var result := steel.lerp(semantic, strength)
	result.a = maxf(0.90, color.a)
	return result

func _foundry_text_color(color: Color) -> Color:
	if bool(settings().get("high_contrast", false)): return Color.WHITE
	# Recast the ubiquitous cool body copy as warm ivory without touching semantic
	# red/green/cyan/gold messaging supplied by individual screens.
	for legacy in [Color("dce8f4"), Color("e1eef9"), Color("dbe9f6"), Color("b9d3e8"), Color("d6f7ff"), Color("edf7ff"), Color("c6d7e8")]:
		if color.is_equal_approx(legacy): return Color("e6dfd0")
	return color

func panel_style(color: Color, border: Color = Color("6bd6ed")) -> StyleBox:
	var role := "surface"
	if border.is_equal_approx(Color("f1be69")) or border.is_equal_approx(Color("ffd36c")): role = "commit"
	elif border.is_equal_approx(Color("ffaaa1")): role = "danger"
	elif border.is_equal_approx(Color("7142a8")): role = "arcane"
	return ARCANE_FOUNDRY_THEME_KIT.panel(role, bool(settings().get("high_contrast", false)))

func inset_style(color: Color, border: Color = Color("6bd6ed")) -> StyleBox:
	var role := "surface"
	if border.is_equal_approx(Color("f1be69")) or border.is_equal_approx(Color("ffd36c")): role = "commit"
	elif border.is_equal_approx(Color("ffaaa1")): role = "danger"
	elif border.is_equal_approx(Color("7142a8")): role = "arcane"
	return ARCANE_FOUNDRY_THEME_KIT.inset(role, bool(settings().get("high_contrast", false)))

func make_panel(color := Color("172942cc"), border := Color("6bd6ed")) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(220, 0)
	panel.add_theme_stylebox_override("panel", panel_style(color, border))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	return content

func button_style(accent: Color, state: String) -> StyleBox:
	var role := "primary"
	if accent.is_equal_approx(Color("a86b2e")): role = "commit"
	elif accent.is_equal_approx(Color("536c8d")) or accent.is_equal_approx(Color("526e93")): role = "secondary"
	elif accent.is_equal_approx(Color("7142a8")): role = "arcane"
	elif accent.is_equal_approx(Color("588d73")): role = "success"
	return ARCANE_FOUNDRY_THEME_KIT.button(role, state, bool(settings().get("high_contrast", false)))

func make_button(text_value: String, callback: Callable, accent := Color("2f93a8")) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", scaled_font(15))
	button.add_theme_font_override("font", ARCANE_FOUNDRY_THEME_KIT.display_font())
	button.add_theme_color_override("font_color", Color.WHITE if bool(settings().get("high_contrast", false)) else Color("f0e8d8"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("fff2d2"))
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("aaa69c"))
	button.add_theme_stylebox_override("normal", button_style(accent, "normal"))
	button.add_theme_stylebox_override("hover", button_style(accent, "hover"))
	button.add_theme_stylebox_override("pressed", button_style(accent, "pressed"))
	button.add_theme_stylebox_override("focus", button_style(accent, "focus"))
	button.add_theme_stylebox_override("disabled", button_style(accent, "disabled"))
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
	if size >= 18: value.add_theme_font_override("font", ARCANE_FOUNDRY_THEME_KIT.display_font())
	value.add_theme_color_override("font_color", _foundry_text_color(color))
	if size >= 24:
		value.add_theme_color_override("font_outline_color", Color("080909"))
		value.add_theme_constant_override("outline_size", 1)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return value

func _visual_style(background: Color, border: Color, radius := 10, width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = radius; style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius; style.corner_radius_bottom_right = radius
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 7; style.content_margin_bottom = 7
	return style

func _visual_panel(name_value: String, background: Color, border: Color, radius := 10) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = name_value
	panel.add_theme_stylebox_override("panel", _visual_style(background, border, radius))
	return panel

func _visual_button(name_value: String, text_value: String, callback: Callable, accent: Color, strong := false) -> Button:
	var button := Button.new()
	button.name = name_value
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 56 if strong else 48)
	button.focus_mode = Control.FOCUS_ALL
	button.accessibility_name = text_value
	button.add_theme_font_size_override("font_size", scaled_font(17 if strong else 14))
	button.add_theme_color_override("font_color", Color("f5f5e9"))
	button.add_theme_stylebox_override("normal", _visual_style(Color(accent, 0.30 if strong else 0.20), accent, 8, 2 if strong else 1))
	button.add_theme_stylebox_override("hover", _visual_style(Color(accent, 0.48), Color("e9fbff"), 8, 2))
	button.add_theme_stylebox_override("focus", _visual_style(Color(accent, 0.42), Color("ffffff"), 8, 3))
	button.add_theme_stylebox_override("pressed", _visual_style(Color(accent, 0.64), Color("ffffff"), 8, 2))
	button.gui_input.connect(func(event: InputEvent):
		if (event is InputEventKey or event is InputEventJoypadButton) and event.pressed:
			_focus_after_render = true)
	button.pressed.connect(func(): _audio_director.cue("press"); callback.call())
	return button

func _finish_visual_route() -> void:
	if _focus_after_render:
		_focus_after_render = false
		call_deferred("focus_first_button")

func _deferred_focus_if_ready(instance_id: int) -> void:
	# Render rebuilds can free a modal in the same frame its initial focus is
	# deferred. Resolve it by id at execution time and do nothing when it no
	# longer belongs to the live, visible focus tree.
	var control := instance_from_id(instance_id) as Control
	if control == null or not is_instance_valid(control): return
	if not control.is_inside_tree() or not control.is_visible_in_tree() or control.focus_mode == Control.FOCUS_NONE: return
	if control is Button and (control as Button).disabled: return
	control.grab_focus()

func _visual_toast(surface: Control) -> void:
	if toast.is_empty(): return
	var notice := _visual_panel("VisualRouteToast", Color("17241ee8"), Color("f1be69"), 8)
	# Toasts are feedback, not a modal glass pane.  They must never consume a
	# centre tap intended for physical hardware below them.
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	notice.anchor_left = 0.18; notice.anchor_right = 0.82
	notice.offset_left = 0; notice.offset_right = 0; notice.offset_top = -64; notice.offset_bottom = -20
	surface.add_child(notice)
	var copy := label(toast, 13, Color("fff0c4")); copy.mouse_filter = Control.MOUSE_FILTER_IGNORE; copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; notice.add_child(copy)

func _feedback_backdrop(texture: Texture2D, dim := 0.38) -> void:
	var background := TextureRect.new()
	background.name = "FeedbackWorkshopBackground"
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade := ColorRect.new()
	shade.name = "FeedbackWorkshopDim"
	shade.color = Color(0.025, 0.055, 0.07, dim)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

func _apply_blueprint_ink(target: CanvasItem) -> void:
	# The raw-print art becomes drafting ink while the adjacent native grid and
	# corner overlay supplies the technical construction context.
	var material := ShaderMaterial.new()
	material.shader = BLUEPRINT_SCHEMATIC_SHADER
	target.material = material

func _feedback_progress_instrument(surface: Control, prefix := "Workshop") -> void:
	var level := int(GameManager.profile.get("spool_level", 1))
	var xp := int(GameManager.profile.get("spool_xp", 0))
	var threshold := level * 100
	var instrument := _visual_panel("%sProgressInstrument" % prefix, Color("101923dc"), Color("78dded"))
	instrument.set_anchors_preset(Control.PRESET_TOP_LEFT)
	# Reserve the left safe-top hardware for the persistent Back owner.
	instrument.position = Vector2(112, 18)
	instrument.size = Vector2(230, 80)
	surface.add_child(instrument)
	var instrument_body := VBoxContainer.new(); instrument_body.add_theme_constant_override("separation", 3); instrument.add_child(instrument_body)
	instrument_body.add_child(label("SPOOL LEVEL %d" % level, 18, Color("f6db9a")))
	var progress := ProgressBar.new(); progress.name = "%sHudProgress" % prefix; progress.max_value = threshold; progress.value = xp; progress.show_percentage = false; progress.custom_minimum_size = Vector2(0, 13); progress.tooltip_text = "Spool Level %d · XP %d / %d" % [level, xp, threshold]; progress.accessibility_name = progress.tooltip_text
	progress.add_theme_stylebox_override("background", _visual_style(Color("123640"), Color("75e8f2"), 6, 1))
	progress.add_theme_stylebox_override("fill", _visual_style(Color("20bfcf"), Color("c3fbff"), 6, 1))
	instrument_body.add_child(progress)
	instrument_body.add_child(label("XP %d / %d" % [xp, threshold], 12, Color("d5fbff")))
	var coins := _visual_panel("%sCoinBadge" % prefix, Color("15241bdc"), Color("f1be69"), 18)
	coins.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	coins.position = Vector2(-190, 18); coins.size = Vector2(172, 44)
	surface.add_child(coins)
	var coin_label := label("%d Forge Coins" % int(GameManager.profile.get("forge_coins", 0)), 14, Color("ffe0a1")); coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; coins.add_child(coin_label)

func _m1_r2_cropped_texture(source: Texture2D, crop: Rect2i) -> AtlasTexture:
	return M1_PHYSICAL_UI.atlas_texture(source, crop)

func _m1_r2_workshop_props() -> Array:
	return M1_PHYSICAL_UI.workshop_prop_specs({"battle":M1_PHYSICAL_UI.texture_for("battle"), "archive":M1_PHYSICAL_UI.texture_for("archive"), "deck":M1_PHYSICAL_UI.texture_for("deck"), "supplies":M1_PHYSICAL_UI.texture_for("supplies"), "settings":M1_PHYSICAL_UI.texture_for("settings")})

func _add_m1_r2_workshop_props(surface: Control) -> void:
	for prop in _m1_r2_workshop_props():
		var rect: Rect2 = prop.rect
		var art := TextureRect.new()
		art.name = "WorkshopR2Prop%s" % _workshop_overview_hotspot_node_suffix(str(prop.id))
		art.texture = _m1_r2_cropped_texture(prop.texture as Texture2D, prop.crop as Rect2i)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.anchor_left = rect.position.x; art.anchor_top = rect.position.y; art.anchor_right = rect.end.x; art.anchor_bottom = rect.end.y
		surface.add_child(art)
		var label_rect := M1_PHYSICAL_UI.workshop_label_rect(prop)
		var high_contrast := bool(settings().get("high_contrast", false))
		var is_dark_supply_apron := str(prop.get("id", "")) == "supplies"
		var native_ink: Color = prop.get("label_color", Color("071a25")) if (not high_contrast or is_dark_supply_apron) else Color("000000")
		var native_outline: Color = prop.get("label_outline", Color("fff1c8")) if (not high_contrast or is_dark_supply_apron) else Color("ffffff")
		var native_label := label(str(prop.label), int(prop.get("label_font_size", 10)), native_ink)
		native_label.name = "WorkshopStationLabel%s" % _workshop_overview_hotspot_node_suffix(str(prop.id))
		native_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		native_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		native_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		native_label.clip_text = true
		native_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		native_label.anchor_left = label_rect.position.x; native_label.anchor_right = label_rect.end.x
		native_label.anchor_top = label_rect.position.y; native_label.anchor_bottom = label_rect.end.y
		# Keep the native copy legible after the global high-contrast theme applies.
		# This local override intentionally comes last so white label faces never lose
		# their black station names.
		native_label.add_theme_color_override("font_color", native_ink)
		native_label.add_theme_color_override("font_outline_color", native_outline)
		native_label.add_theme_constant_override("outline_size", 1)
		surface.add_child(native_label)
func render_feedback_workshop() -> void:
	overview_layout_portrait = is_portrait_layout()
	var workshop_plate := PHYSICAL_PORTRAIT_PLATE.new()
	workshop_plate.name = "WorkshopPortraitPlate"
	workshop_plate.configure(M1_PHYSICAL_UI.texture_for("workshop"))
	workshop_plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(workshop_plate)
	_apply_synthetic_host_inset_stress(workshop_plate)
	var surface := Control.new()
	surface.name = "WorkshopFullBleed"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	workshop_plate.content_layer().add_child(surface)
	_feedback_progress_instrument(surface, "Workshop")
	_add_m1_r2_workshop_props(surface)
	var printer_label := label("PRINTER", 12, Color("9beaff") if not bool(settings().get("high_contrast", false)) else Color("ffffff"))
	printer_label.add_theme_color_override("font_color", Color("ffffff") if bool(settings().get("high_contrast", false)) else Color("9beaff"))
	printer_label.add_theme_color_override("font_outline_color", Color("ffffff") if bool(settings().get("high_contrast", false)) else Color("fff1c8"))
	printer_label.add_theme_constant_override("outline_size", 1)
	# The label is initialized before its late local contrast overrides.
	printer_label.name = "WorkshopStationLabelPrinter"
	surface.add_child(printer_label)
	printer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	printer_label.add_theme_color_override("font_color", Color("ffffff") if bool(settings().get("high_contrast", false)) else Color("9beaff"))
	printer_label.add_theme_color_override("font_outline_color", Color("ffffff") if bool(settings().get("high_contrast", false)) else Color("fff1c8"))
	printer_label.add_theme_constant_override("outline_size", 1)
	printer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	printer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The authored printer plaque supplies its own material face. Keep this native
	# label transparent so it cannot become a generic cream button overlay.
	printer_label.add_theme_stylebox_override("normal", workshop_hotspot_style())
	# The lower rim is hardware, not a caption face.  Keep the printer label in the
	# dark-glass band immediately above the bed where its light outline remains clear.
	printer_label.anchor_left = 0.36; printer_label.anchor_top = 0.430; printer_label.anchor_right = 0.64; printer_label.anchor_bottom = 0.475
	for hotspot in _physical_workshop_hotspots():
		var button := _workshop_overview_hotspot_button(hotspot)
		surface.add_child(button)
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {}) if GameManager.profile.get("pending_pack_reveal", {}) is Dictionary else {}
	if not pending.is_empty():
		var resume := _visual_button("WorkshopResumePendingPack", "RESUME\nPACK", _m3_open_pending_pack.bind("workshop"), Color("f1be69"), true)
		resume.custom_minimum_size = Vector2(56, 56)
		PHYSICAL_CONTROL_FAMILY.apply(resume, "wide")
		resume.tooltip_text = "Open the committed pack waiting in this Workshop"
		resume.accessibility_name = resume.tooltip_text
		# A small ticket in the unused lower-left alcove keeps this recovery action
		# distinct from the Supply Cabinet and clear of the Settings dial.
		resume.anchor_left = 0.04; resume.anchor_top = 0.805; resume.anchor_right = 0.28; resume.anchor_bottom = 0.905
		surface.add_child(resume)
	else:
		var rewards: Dictionary = GameManager.profile.get("starter_pack_rewards", {})
		if str(rewards.get("kind", "")) == UNIFIED_RULES.FOUNDER_VERSION and int(rewards.get("opened", 0)) < int(rewards.get("entitled", 0)) and int(rewards.get("opened", 0)) == int(rewards.get("kept", 0)):
			var founder_pack := _visual_button("WorkshopOpenFounderPack", "OPEN\nFOUNDER %d/3" % (int(rewards.get("opened", 0)) + 1), _open_next_starter_pack, Color("f1be69"), true)
			founder_pack.custom_minimum_size = Vector2(56, 56)
			PHYSICAL_CONTROL_FAMILY.apply(founder_pack, "wide")
			founder_pack.tooltip_text = "Open the next committed Founder pack"
			founder_pack.accessibility_name = founder_pack.tooltip_text
			founder_pack.anchor_left = 0.04; founder_pack.anchor_top = 0.805; founder_pack.anchor_right = 0.28; founder_pack.anchor_bottom = 0.905
			surface.add_child(founder_pack)
	var back := _visual_button("WorkshopBack", "BACK", request_back, Color("8a6945"), false)
	PHYSICAL_NAVIGATION.configure_back(back, "Title")
	back.anchor_left = 0.030; back.anchor_top = 0.020; back.anchor_right = 0.180; back.anchor_bottom = 0.080
	surface.add_child(back)
	_visual_toast(surface)

func _apply_synthetic_host_inset_stress(plate: Control) -> void:
	_apply_presentation_safe_area(plate)
	var enabled := bool(get_meta("synthetic_host_inset_stress", false))
	_portrait_presentation_boundary.set_synthetic_host_inset_stress(enabled)
	if not enabled:
		return
	var reserve := _portrait_presentation_boundary.effective_visual_stress_reserve(get_viewport().get_visible_rect().size.x)
	plate.offset_bottom = -reserve
	var band := ColorRect.new()
	band.name = "SyntheticHostInsetStress"
	band.color = Color("432019")
	band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -reserve; band.offset_bottom = 0
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fixture_label := label(_portrait_presentation_boundary.synthetic_fixture_label(), 14, Color("fff0bb"))
	fixture_label.name = "SyntheticHostInsetStressLabel"
	fixture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fixture_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fixture_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.add_child(fixture_label)
	add_child(band)

func _apply_presentation_safe_area(plate: Control) -> void:
	var top_inset := float(get_meta("presentation_safe_top_inset", 0.0))
	_portrait_presentation_boundary.set_top_safe_inset(top_inset)
	if top_inset <= 0.0:
		return
	plate.offset_top = top_inset
	var label_node := label(_portrait_presentation_boundary.tall_safe_top_fixture_label(), 12, Color("fff0bb"))
	label_node.name = "TallSafeTopFixtureLabel"
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_node.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label_node.offset_top = 2; label_node.offset_bottom = top_inset - 2
	add_child(label_node)

func _physical_workshop_hotspots() -> Array:
	return M1_PHYSICAL_UI.physical_workshop_hotspots()

func _blueprint_card_texture(definition: Dictionary) -> Texture2D:
	return PHYSICAL_CATALOG_IMPRINT.blueprint_texture(definition)

func _starter_schematic_card(starter_id: String) -> Control:
	var creature := Catalog.creature(starter_id)
	var element_color := Color(ELEMENT_COLORS.get(str(creature.get("element", "")), "76ddff"))
	var selected := pending_starter_id == starter_id
	var card := _visual_panel("StarterSchematic%s" % starter_id.capitalize(), Color("071a25e8"), element_color if selected else Color("4b8193"), 12)
	card.custom_minimum_size = Vector2(260 if is_portrait_layout() else 370, 390 if is_portrait_layout() else 330)
	var content := VBoxContainer.new(); content.add_theme_constant_override("separation", 4); card.add_child(content)
	var art_frame := Control.new(); art_frame.custom_minimum_size = Vector2(0, 172 if is_portrait_layout() else 190); art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL; content.add_child(art_frame)
	var art := TextureRect.new(); art.name = "StarterBlueprintCard"; art.texture = _blueprint_card_texture(creature); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); art.mouse_filter = Control.MOUSE_FILTER_IGNORE; art_frame.add_child(art)
	var drafting := BLUEPRINT_SCHEMATIC_OVERLAY.new(); drafting.name = "StarterSchematicDraftGrid"; drafting.configure(Color("72ecff"), 1.0); drafting.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); drafting.mouse_filter = Control.MOUSE_FILTER_IGNORE; art_frame.add_child(drafting)
	var inspect := _visual_button("StarterInspect%s" % starter_id.capitalize(), "INSPECT BLUEPRINT", show_starter_inspector.bind(starter_id), Color("64dff0"))
	inspect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); inspect.tooltip_text = "Inspect %s blueprint schematic" % str(creature.get("name", starter_id)); art_frame.add_child(inspect)
	var name_label := label(str(creature.get("name", starter_id)), 18, element_color); name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; content.add_child(name_label)
	var detail := label("%s blueprint · %d HP · BEND %d" % [str(creature.get("element", "")), int(creature.get("hp", 0)), int(creature.get("bend", 0))], 11, Color("d8edf4")); detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; content.add_child(detail)
	var button_text := "FORGE %s" % str(creature.get("name", starter_id)).to_upper() if selected else "SELECT"
	var action := _visual_button("StarterSelect%s" % starter_id.capitalize(), button_text, confirm_starter if selected else _select_starter_blueprint.bind(starter_id), element_color, true)
	action.tooltip_text = "Select %s blueprint" % str(creature.get("name", starter_id)); content.add_child(action)
	return card

func _select_starter_blueprint(starter_id: String) -> void:
	pending_starter_id = starter_id
	starter_inspector_id = ""
	render()

func render_feedback_printer() -> void:
	# Every production Forge caller, including starter, armor, and cores, enters
	# one approved enclosure. The component is presentation-only: Main retains
	# the existing sequence, Back dispatcher, and exactly-once commit boundary.
	var physical = _physical_forge_component()
	if physical == null:
		return
	physical.render(self)

func _feedback_archive_cards() -> Array:
	var owned: Array = []
	for definition in UNIFIED_RULES.all_cards():
		if int(GameManager.profile.get("owned_cards", {}).get(str(definition.get("id", "")), 0)) > 0:
			owned.append(definition)
	return _filter_archive_cards(owned)

func _feedback_book_pager(host: Container, card_count: int) -> void:
	var per_page := 9
	var pages := maxi(1, int(ceil(float(card_count) / float(per_page))))
	unified_page = clampi(unified_page, 0, pages - 1)
	var pager := HBoxContainer.new(); pager.name = "ArchiveBookPager"; pager.alignment = BoxContainer.ALIGNMENT_CENTER; pager.add_theme_constant_override("separation", 8); host.add_child(pager)
	var previous := _visual_button("ArchivePreviousPage", "‹", func(): unified_page = posmod(unified_page - 1, pages); render(), Color("7896a4")); previous.custom_minimum_size = Vector2(48, 44); pager.add_child(previous)
	pager.add_child(_compact_pager_label("%d / %d" % [unified_page + 1, pages]))
	var next := _visual_button("ArchiveNextPage", "›", func(): unified_page = posmod(unified_page + 1, pages); render(), Color("7896a4")); next.custom_minimum_size = Vector2(48, 44); pager.add_child(next)

func _archive_blueprint_card(definition: Dictionary) -> Button:
	var card_id := str(definition.get("id", ""))
	var is_creature := str(definition.get("type", "")) == "creature"
	var portrait := is_portrait_layout()
	var card := Button.new()
	card.name = "ArchiveBlueprintCard%s" % card_id.capitalize()
	card.text = ""
	card.custom_minimum_size = Vector2(0, 144 if portrait else 112)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.tooltip_text = "%s · %s · Owned x%d" % [str(definition.get("name", card_id)), "blueprint" if is_creature else str(definition.get("type", "card")), int(GameManager.profile.get("owned_cards", {}).get(card_id, 0))]
	card.accessibility_name = card.tooltip_text
	card.add_theme_stylebox_override("normal", _visual_style(Color("13252bdc") if is_creature else Color("293129e8"), Color("55bed0") if is_creature else Color("9a794d"), 7, 1))
	card.add_theme_stylebox_override("hover", _visual_style(Color("1b4250ef") if is_creature else Color("45412dec"), Color("dcfbff"), 7, 2))
	card.add_theme_stylebox_override("focus", _visual_style(Color("214e5bf2") if is_creature else Color("55472eee"), Color("ffffff"), 7, 2))
	var content := VBoxContainer.new(); content.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_theme_constant_override("separation", 2); content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5); card.add_child(content)
	var title := label(str(definition.get("name", card_id)), 12, Color("bdf7ff") if is_creature else Color("fff0ce")); title.autowrap_mode = TextServer.AUTOWRAP_OFF; title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; content.add_child(title)
	var art_shell := Control.new(); art_shell.custom_minimum_size = Vector2(0, 66 if portrait else 45); art_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL; art_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE; content.add_child(art_shell)
	var art := TextureRect.new(); art.name = "ArchiveBlueprintCardArt" if is_creature else "ArchiveSupportArt"; art.texture = _blueprint_card_texture(Catalog.creature(card_id)) if is_creature else UNIFIED_CARD_VIEW.art_for_definition(definition); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_shell.add_child(art)
	var real_line := "HP %d · BEND %d" % [int(definition.get("hp", 0)), int(definition.get("bend", 0))] if is_creature else "%s · %d F" % [str(definition.get("type", "support")).capitalize(), int(definition.get("cost", 0))]
	var detail := label(real_line, 11, Color("d9f8fa") if is_creature else Color("f3dfb5")); detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; detail.autowrap_mode = TextServer.AUTOWRAP_OFF; detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; content.add_child(detail)
	var count_text := "x%d deck · owned x%d" % [unified_deck_draft.count(card_id), int(GameManager.profile.get("owned_cards", {}).get(card_id, 0))] if screen == "unified_deck" else "Owned x%d" % int(GameManager.profile.get("owned_cards", {}).get(card_id, 0))
	var footer := label(count_text, 10, Color("a5dfe6") if is_creature else Color("d9c294")); footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; footer.autowrap_mode = TextServer.AUTOWRAP_OFF; footer.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; content.add_child(footer)
	card.gui_input.connect(func(event: InputEvent):
		if (event is InputEventKey or event is InputEventJoypadButton) and event.pressed:
			_focus_after_render = true)
	card.pressed.connect(func():
		if screen == "unified_deck":
			if card_id in unified_deck_draft: unified_deck_draft.erase(card_id)
			elif unified_deck_draft.count(card_id) < int(GameManager.profile.get("owned_cards", {}).get(card_id, 0)): unified_deck_draft.append(card_id)
		else:
			unified_inspector_id = card_id
			unified_inspector_tab = "card"
		render())
	return card

func _feedback_collection_clipboard(host: Container, cards: Array) -> void:
	host.add_child(label("COLLECTION", 15, Color("352516")))
	host.add_child(label("%d card types · %d copies" % [cards.size(), _owned_card_total()], 12, Color("483420")))
	host.add_child(label("OWNED BLUEPRINTS", 11, Color("6a4b2a")))
	var shown := 0
	for definition in cards:
		var card_def: Dictionary = definition
		if str(card_def.get("type", "")) != "creature": continue
		var card_id := str(card_def.get("id", ""))
		host.add_child(label("%s · x%d" % [str(card_def.get("name", card_id)), int(GameManager.profile.get("owned_cards", {}).get(card_id, 0))], 11, Color("513c25")))
		shown += 1
		if shown >= 7: break
	if shown == 0: host.add_child(label("Creature blueprints appear here as cards are collected.", 11, Color("513c25")))

func _ensure_feedback_deck_drafts(force_reload := false) -> void:
	var active_slot := str(GameManager.profile.get("active_deck_id", "starter-deck"))
	if force_reload or not feedback_deck_draft_initialized or feedback_deck_loaded_slot != active_slot:
		unified_deck_draft = GameManager.active_deck_cards().duplicate()
		# An empty saved pre-print is a valid deliberate loadout.  Initialization
		# state, rather than Array.is_empty(), distinguishes it from first entry.
		unified_preprint_draft = (GameManager.profile.get("preprints", []) as Array).duplicate()
		feedback_deck_loaded_slot = active_slot
		feedback_deck_draft_initialized = true

func _feedback_deck_clipboard(host: Container) -> void:
	_ensure_feedback_deck_drafts()
	host.add_child(label("ACTIVE DECK", 15, Color("352516")))
	var slots := HBoxContainer.new(); slots.name = "ArchiveDeckSlots"; slots.add_theme_constant_override("separation", 3); host.add_child(slots)
	var portrait := is_portrait_layout()
	for index in UNIFIED_RULES.DECK_SLOTS.size():
		var slot: Dictionary = UNIFIED_RULES.DECK_SLOTS[index]
		var slot_id := str(slot.get("id", "")); var selected := slot_id == str(GameManager.profile.get("active_deck_id", ""))
		var short_name: String = ["F", "Q", "A"][index]
		var slot_name: String = str(slot.get("name", slot_id))
		var slot_text: String = ("✓ " if selected else "") + (short_name if portrait else slot_name)
		var slot_button := _visual_button("ArchiveDeckSlot%s" % slot_id.capitalize(), slot_text, func():
			if GameManager.select_unified_deck(slot_id):
				_ensure_feedback_deck_drafts(true)
				_toast("%s selected." % slot_name)
			else: _toast("That fixed deck slot needs a legal 40-card deck.")
			render(), Color("478e72") if selected else Color("7a8f9a"))
		slot_button.custom_minimum_size = Vector2(34 if portrait else 82, 36); slot_button.tooltip_text = "Select %s" % slot_name; slot_button.accessibility_name = slot_button.tooltip_text; slots.add_child(slot_button)
	var active_slot_name := str(UNIFIED_RULES.DECK_SLOTS.filter(func(slot): return str(slot.get("id", "")) == str(GameManager.profile.get("active_deck_id", ""))).front().get("name", "Forge Deck"))
	host.add_child(label(active_slot_name, 11, Color("6a4b2a")))
	host.add_child(label("%d / 40 cards · %d creatures" % [unified_deck_draft.size(), _deck_creature_count()], 12, Color("483420")))
	host.add_child(label("DECK ENTRIES", 11, Color("6a4b2a")))
	var entries: Array = []
	for card_id in unified_deck_draft:
		if card_id not in entries: entries.append(card_id)
	for card_id in entries.slice(0, 6): host.add_child(label("%s ×%d" % [str(UNIFIED_RULES.card(str(card_id)).get("name", card_id)), unified_deck_draft.count(card_id)], 11, Color("513c25")))
	var preprint_slots := UNIFIED_RULES.preprint_slots(GameManager.profile)
	host.add_child(label("PRE-PRINT %d / %d" % [unified_preprint_draft.size(), preprint_slots], 11, Color("6a4b2a")))
	var preprint_ids: Array = []
	for card_id in entries:
		if str(UNIFIED_RULES.card(str(card_id)).get("type", "")) == "creature": preprint_ids.append(card_id)
	var preprint_scroll := ScrollContainer.new(); preprint_scroll.name = "ArchivePrePrintScroll"; preprint_scroll.custom_minimum_size = Vector2(0, 104); preprint_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; preprint_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; host.add_child(preprint_scroll)
	var preprint_list := VBoxContainer.new(); preprint_list.name = "ArchivePrePrintList"; preprint_list.add_theme_constant_override("separation", 3); preprint_scroll.add_child(preprint_list)
	for creature_id in preprint_ids:
		var chosen := unified_preprint_draft.count(creature_id)
		var available := unified_deck_draft.count(creature_id)
		var pick := _visual_button("ArchivePrePrint%s" % str(creature_id).capitalize(), ("✓ " if chosen > 0 else "○ ") + str(UNIFIED_RULES.card(str(creature_id)).get("name", creature_id)), func():
			if chosen > 0: unified_preprint_draft.erase(creature_id)
			elif unified_preprint_draft.size() < preprint_slots and chosen < available: unified_preprint_draft.append(creature_id)
			render(), Color("4a9aae") if chosen > 0 else Color("718797"))
		pick.custom_minimum_size = Vector2(0, 32); preprint_list.add_child(pick)
	var save := _visual_button("SaveActiveDeck", "Save deck", func():
		var saved := GameManager.save_unified_deck(unified_deck_draft, str(GameManager.profile.get("active_deck_id", "starter-deck")))
		_toast("Deck saved." if saved else "Deck must be a legal 40-card owned deck.")
		render(), Color("478e72"), true)
	save.custom_minimum_size = Vector2(0, 40)
	host.add_child(save)
	var preprint := _visual_button("SavePrePrintLoadout", "Save pre-print", func():
		var saved := GameManager.save_preprints_v3(unified_preprint_draft)
		_toast("Pre-Print loadout saved." if saved else "Pre-Print loadout is not legal.")
		render(), Color("558cad"))
	preprint.custom_minimum_size = Vector2(0, 36)
	host.add_child(preprint)

func render_feedback_archive_book() -> void:
	_feedback_backdrop(_workshop_overview_texture(), 0.52)
	var surface := Control.new(); surface.name = "FeedbackArchiveSurface"; surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(surface)
	_feedback_progress_instrument(surface, "Archive")
	var portrait := is_portrait_layout()
	var book := _visual_panel("ArchiveBookShell", Color("e3d4b6f5"), Color("8a6035"), 12)
	book.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Portrait retains a real gutter for the attached filter tabs instead of
	# allowing their accessible hit targets to intrude over the first card.
	book.anchor_left = 0.235 if portrait else 0.14; book.anchor_top = 0.13; book.anchor_right = 0.765 if portrait else 0.70; book.anchor_bottom = 0.87 if portrait else 0.91
	book.offset_left = 0; book.offset_top = 0; book.offset_right = 0; book.offset_bottom = 0; surface.add_child(book)
	var book_body := VBoxContainer.new(); book_body.name = "ArchiveBookBody"; book_body.add_theme_constant_override("separation", 6); book.add_child(book_body)
	book_body.add_theme_constant_override("margin_left", 5)
	var tabs := HBoxContainer.new(); tabs.name = "ArchiveBookTabs"; tabs.add_theme_constant_override("separation", 6); book_body.add_child(tabs)
	var back := _visual_button("UnifiedFoundryWorkshopReturn", "←", navigate_to.bind("workshop"), Color("78a6b2"))
	back.custom_minimum_size = Vector2(44, 44); back.tooltip_text = "Return to Workshop"; back.accessibility_name = back.tooltip_text; tabs.add_child(back)
	tabs.add_child(_visual_button("ArchiveCollectionTab", "Collection", navigate_to.bind("archive"), Color("3f94a8"), screen == "unified_library"))
	tabs.add_child(_visual_button("ArchiveDeckTab", "Deck Builder", navigate_to.bind("deck"), Color("3f94a8"), screen == "unified_deck"))
	var heading := label("BLUEPRINT ARCHIVE", 18, Color("372718")); heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; book_body.add_child(heading)
	var cards := _feedback_archive_cards()
	var grid := GridContainer.new(); grid.name = "ArchiveBookCardGrid"; grid.columns = 3; grid.size_flags_vertical = Control.SIZE_EXPAND_FILL; grid.add_theme_constant_override("h_separation", 6); grid.add_theme_constant_override("v_separation", 6); book_body.add_child(grid)
	var page_cards := cards.slice(unified_page * 9, mini(cards.size(), unified_page * 9 + 9))
	for definition in page_cards:
		var card_def: Dictionary = definition
		grid.add_child(_archive_blueprint_card(card_def))
	_feedback_book_pager(book_body, cards.size())
	var filters := VBoxContainer.new(); filters.name = "ArchiveBookFilters"; filters.add_theme_constant_override("separation", 8)
	filters.set_anchors_preset(Control.PRESET_LEFT_WIDE); filters.anchor_left = 0.012; filters.anchor_top = 0.28; filters.anchor_right = 0.145 if portrait else 0.125; filters.anchor_bottom = 0.69; filters.offset_left = 0; filters.offset_top = 0; filters.offset_right = 0; filters.offset_bottom = 0; surface.add_child(filters)
	for filter in [["all", "All", "ArchiveFilterAll"], ["creature", "Creatures", "ArchiveFilterCreatures"], ["support", "Support", "ArchiveFilterSupport"]]:
		var filter_id := str(filter[0]); var chip := _visual_button(str(filter[2]), str(filter[1]), set_archive_filter.bind(filter_id), Color("4a95a5"), unified_archive_filter == filter_id); chip.tooltip_text = "Show %s cards" % str(filter[1]).to_lower(); filters.add_child(chip)
	var clipboard := _visual_panel("ArchiveDeckClipboard", Color("e0c89ff0"), Color("9b6a38"), 10)
	clipboard.set_anchors_preset(Control.PRESET_FULL_RECT); clipboard.anchor_left = 0.785 if portrait else 0.73; clipboard.anchor_top = 0.24; clipboard.anchor_right = 0.985; clipboard.anchor_bottom = 0.78; clipboard.offset_left = 0; clipboard.offset_top = 0; clipboard.offset_right = 0; clipboard.offset_bottom = 0; surface.add_child(clipboard)
	var clip_body := VBoxContainer.new(); clip_body.add_theme_constant_override("separation", 8); clipboard.add_child(clip_body)
	if screen == "unified_library":
		_feedback_collection_clipboard(clip_body, cards)
	else:
		_feedback_deck_clipboard(clip_body)
	_visual_toast(surface)
	_render_unified_inspector()
	# Pack receipts can route straight to Collection.  The image-led Archive is
	# its own render path, so retain the same exactly-once reveal layer used by
	# the regular Foundry shell.
	_render_unified_pack_reveal()

func _owned_card_total() -> int:
	var total := 0
	for count in GameManager.profile.get("owned_cards", {}).values(): total += int(count)
	return total

func _title_action(name_value: String, text_value: String, action: Callable, rect: Rect2, minimum: Vector2, description: String, default_focus := false) -> Button:
	var button := _visual_button(name_value, text_value, action, Color("f1be69"), true)
	button.custom_minimum_size = minimum
	button.tooltip_text = description
	button.accessibility_name = description
	M1_PHYSICAL_UI.apply_cream_action(button)
	if name_value in ["TitleBack", "TitleStay", "TitleConfirmExit", "TitleCancelNewMaker"]:
		# Title actions sit on the dark tool wall, so their light parchment face is
		# the readable physical affordance; the brass binding remains Back hardware
		# everywhere a dark plate already frames it.
		PHYSICAL_CONTROL_FAMILY.apply(button, "wide")
	M1_PHYSICAL_UI.add_complete_focus_ring(button, name_value, bool(settings().get("high_contrast", false)), _visual_style)
	M1_PHYSICAL_UI.place_design(button, rect)
	if default_focus: button.set_meta("title_default_focus", true)
	return button

func _title_continue() -> void:
	if title_new_maker_confirmation or title_new_maker_in_flight: return
	var onboarding: Dictionary = GameManager.profile.get("onboarding", {})
	if str(onboarding.get("state", "choose_starter")) == "starter_selected":
		# Resume exactly at the saved free first-print setup, never through a
		# generic Workshop redirect that loses the selected artifact.
		open_printer(str(onboarding.get("starter_id", "")))
		return
	navigate_to(OnboardingState.screen_for_profile(GameManager.profile))

func _title_request_new_maker() -> void:
	if title_new_maker_in_flight: return
	title_new_maker_confirmation = true
	title_new_maker_error = ""
	render()

func _title_cancel_new_maker() -> void:
	if title_new_maker_in_flight: return
	title_new_maker_confirmation = false
	title_new_maker_error = ""
	render()

func _title_request_exit() -> void:
	if title_new_maker_in_flight: return
	title_exit_confirmation = true
	render()

func _title_cancel_exit() -> void:
	title_exit_confirmation = false
	render()

func _title_confirm_exit() -> void:
	get_tree().quit()

func _title_confirm_new_maker() -> void:
	if not title_new_maker_confirmation or title_new_maker_in_flight: return
	title_new_maker_in_flight = true
	title_new_maker_error = ""
	render()
	var result := GameManager.create_new_maker_profile()
	if not bool(result.get("ok", false)):
		title_new_maker_in_flight = false
		title_new_maker_error = str(result.get("error", "Could not create the new maker profile."))
		render()
		return
	title_new_maker_confirmation = false
	title_new_maker_in_flight = false
	title_new_maker_error = ""
	screen = "onboarding"
	render()

func _render_physical_title() -> void:
	var title_plate := PHYSICAL_PORTRAIT_PLATE.new()
	title_plate.name = "TitlePortraitPlate"
	title_plate.configure(M1_PHYSICAL_UI.texture_for("title"))
	title_plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(title_plate)
	_apply_synthetic_host_inset_stress(title_plate)
	var surface := Control.new()
	surface.name = "PrintForgeTitleScreen"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_plate.content_layer().add_child(surface)
	# The title parchment is a light material in every accessibility mode. Keep
	# native ink dark there; only the separate action focus ring turns white in
	# high contrast. At 150% the brand deliberately steps down one native size so
	# the complete word stays within the paper inset rather than touching brass.
	var brand_size := 24 if int(settings().get("text_scale_bps", 10000)) >= 15000 else 34
	var brand := label("PRINTFORGE", brand_size, Color("47331f"))
	brand.name = "TitleNativeBrand"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	brand.clip_text = true
	brand.add_theme_color_override("font_color", Color("47331f"))
	brand.add_theme_color_override("font_outline_color", Color("fff1c8"))
	M1_PHYSICAL_UI.place_design(brand, Rect2(195, 165, 551, 78))
	surface.add_child(brand)
	var status_copy := "Choose a blueprint and bring a living print to the workshop."
	# A rejected persistence transaction remains actionable: keep its exact native
	# failure/retry feedback visible above the still-present confirmation controls.
	if not title_new_maker_error.is_empty():
		status_copy = title_new_maker_error
	elif title_new_maker_confirmation:
		status_copy = "Starting a new maker replaces this device's saved progress after you confirm."
	var status_label := label(status_copy, 14, Color("47331f"))
	status_label.name = "TitleNativeStatus"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color("47331f"))
	M1_PHYSICAL_UI.place_design(status_label, Rect2(205, 242, 531, 92))
	surface.add_child(status_label)
	var hero := TextureRect.new(); hero.name = "TitleCinderpawHero"; hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hero_atlas := AtlasTexture.new(); hero_atlas.atlas = CREATURE_SPRITE_CACHE.texture_for_creature("cinderpaw"); hero_atlas.region = CREATURE_SPRITE_CACHE.safe_source_region(0)
	hero.texture = hero_atlas; hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.tooltip_text = "Cinderpaw, a living printed companion"
	M1_PHYSICAL_UI.place_design(hero, Rect2(215, 500, 515, 540))
	surface.add_child(hero)
	var version := label("PrintForge · %s" % REVIEW_BUILD_LABEL, 12, Color("fff0bb"))
	version.name = "TitleStatusVersion"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	version.autowrap_mode = TextServer.AUTOWRAP_OFF
	M1_PHYSICAL_UI.place_design(version, Rect2(165, 1518, 611, 47))
	surface.add_child(version)
	var onboarding: Dictionary = GameManager.profile.get("onboarding", {})
	var starter_selected := str(onboarding.get("state", "choose_starter")) == "starter_selected"
	var fresh := str(onboarding.get("state", "choose_starter")) == "choose_starter"
	if title_exit_confirmation:
		var exit_confirm := _title_action("TitleConfirmExit", "EXIT", _title_confirm_exit, Rect2(170, 1180, 600, 140), Vector2(56, 56), "Exit PrintForge")
		surface.add_child(exit_confirm)
		var exit_stay := _title_action("TitleStay", "BACK / STAY", _title_cancel_exit, Rect2(70, 1405, 375, 95), Vector2(56, 56), "Stay in PrintForge", true)
		surface.add_child(exit_stay)
		call_deferred("_deferred_focus_if_ready", exit_stay.get_instance_id())
		return
	if title_new_maker_confirmation:
		var confirm_text := "WRITING…" if title_new_maker_in_flight else "CONFIRM NEW MAKER"
		var confirm := _title_action("TitleConfirmNewMaker", confirm_text, _title_confirm_new_maker, Rect2(170, 1180, 600, 140), Vector2(56, 56), "Confirm replacing this saved maker profile")
		confirm.disabled = title_new_maker_in_flight
		surface.add_child(confirm)
		var cancel := _title_action("TitleCancelNewMaker", "CANCEL", _title_cancel_new_maker, Rect2(70, 1405, 375, 95), Vector2(56, 56), "Cancel New Maker confirmation", true)
		cancel.disabled = title_new_maker_in_flight
		surface.add_child(cancel)
		call_deferred("_deferred_focus_if_ready", cancel.get_instance_id())
		return
	var primary_text := "NEW MAKER" if fresh else "CONTINUE"
	var primary_description := "Start a new maker profile" if fresh else "Continue the current maker profile"
	var primary := _title_action("TitleContinue", primary_text, _title_continue, Rect2(170, 1180, 600, 140), Vector2(56, 56), primary_description, true)
	surface.add_child(primary)
	call_deferred("_deferred_focus_if_ready", primary.get_instance_id())
	if not fresh:
		var new_maker := _title_action("TitleNewMaker", "NEW MAKER", _title_request_new_maker, Rect2(70, 1405, 375, 95), Vector2(48, 48), "Start a different maker profile")
		surface.add_child(new_maker)
	var settings_action := _title_action("TitleSettings", "SETTINGS", navigate_to.bind("settings"), Rect2(495, 1405, 375, 95), Vector2(48, 48), "Open Title settings")
	surface.add_child(settings_action)
	var title_back := _title_action("TitleBack", "BACK / EXIT", request_back, Rect2(40, 330, 300, 112), Vector2(72, 56), "Exit PrintForge")
	surface.add_child(title_back)

func _deck_creature_count() -> int:
	var total := 0
	for card_id in unified_deck_draft:
		if str(UNIFIED_RULES.card(str(card_id)).get("type", "")) == "creature": total += 1
	return total

func render() -> void:
	_audio_director.configure(settings(), printer_capture_freeze or workshop_ambient_capture_freeze)
	_audio_director.route("battle" if screen == "unified_battle" else ("forge" if screen == "printer" else "workshop"))
	_detach_persistent_screen_components()
	clear_children(self)
	# Recovery is deliberately the only title surface while persistence is unsafe.
	# It prevents a reset/navigation action from bypassing the M3 ledger decisions.
	if GameManager.is_save_read_only():
		_m3_physical_ui.render(self)
		_finish_visual_route()
		return
	if screen == "title":
		_render_physical_title()
		_finish_visual_route()
		return
	# M3 owns the portrait management routes as physical plates. The generated
	# masters supply static material and sockets only; state and controls remain
	# native controls above them.
	if screen in ["unified_market", "unified_library", "unified_deck", "settings", "m3_result", "m3_pack"]:
		_m3_physical_ui.render(self)
		_finish_visual_route()
		return
	# These review routes are deliberately image-led compositions rather than
	# descendants of the legacy framed/scrolled shell. Main still owns every
	# state transition and action; the presentation simply has room to breathe.
	if not GameManager.is_save_read_only() and screen == "onboarding" and is_portrait_layout():
		render_m1_r2_starter_page()
		_finish_visual_route()
		return
	# The approved physical Workshop remains the overview for every legal maker
	# state.  In particular, a selected starter can Back out of its uncommitted
	# first print (or pause its accepted print) and return through this same
	# physical Printer hotspot without falling through to the retired room shell.
	if not GameManager.is_save_read_only() and screen == "workshop" and workshop_view == "overview":
		render_feedback_workshop()
		_finish_visual_route()
		return
	if not GameManager.is_save_read_only() and screen == "printer":
		render_feedback_printer()
		_finish_visual_route()
		return
	# M2 battle routes own the whole safe game surface.  They must be entered
	# before the legacy backdrop/VBox shell, otherwise the portrait chassis would
	# be reduced to a small stacked panel beneath generic controls.
	if not GameManager.is_save_read_only() and screen == "proving":
		var challenge_component = _unified_battle_component()
		if challenge_component != null:
			challenge_component.render_preflight(self)
		else:
			screen = "workshop"
		_finish_visual_route()
		return
	if not GameManager.is_save_read_only() and screen == "unified_battle":
		render_m2_physical_battle()
		_finish_visual_route()
		return
	var backdrop := TextureRect.new()
	backdrop.texture = REFERENCE_TEXTURE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.72, 0.63, 0.50, 0.48)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var steel_overlay := ColorRect.new()
	steel_overlay.color = Color("0d0e0de0")
	steel_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	steel_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(steel_overlay)
	var warm_glow := ColorRect.new()
	warm_glow.color = Color("8d4a2038")
	warm_glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	warm_glow.offset_bottom = 260
	warm_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warm_glow)
	var cyan_balance := ColorRect.new()
	cyan_balance.color = Color("0b495426")
	cyan_balance.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cyan_balance.offset_top = -120
	cyan_balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cyan_balance)

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
	# Unified battle is a first-fold control surface. Its compact landscape
	# rhythm preserves the explicit phase and return actions at 125% text.
	root.add_theme_constant_override("separation", 6 if screen == "unified_battle" and not portrait else 12)
	margin.add_child(root)
	if _shows_workshop_hud(): render_header(root)
	if GameManager.is_save_read_only():
		render_save_recovery(root)
		return
	# Unified matches are presented by the shipped Foundry shell, not by the
	# retired compact test harness. They are a first-fold, no-scroll surface.
	if screen == "unified_battle":
		render_unified_battle_fullscreen(root)
		if _focus_after_render:
			_focus_after_render = false
			call_deferred("focus_first_button")
		return
	if screen == "onboarding":
		render_onboarding_fullscreen(root)
		if _focus_after_render:
			_focus_after_render = false
			call_deferred("focus_first_button")
		return
	# `codex` is retained as a legacy navigation token for old callers, but its
	# player-facing presentation is now the bounded unified Forgedex.
	if screen == "codex":
		screen = "unified_forgedex"
	if screen in ["unified_market", "unified_library", "unified_deck", "unified_upgrades", "unified_forgedex"]:
		render_unified_foundry_surface(root)
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
		"trade": render_local_trade()
		_: render_workshop()
	if _focus_after_render:
		_focus_after_render = false
		call_deferred("focus_first_button")

func _detach_persistent_screen_components() -> void:
	# Main's shell is intentionally rebuilt for responsive text/contrast. Detach
	# expensive presentation nodes first so their imported textures and animation
	# state survive the ancestor queue_free operation.
	if _forge_screen_component != null: _forge_screen_component.detach()
	if _unified_battle_screen_component != null: _unified_battle_screen_component.detach()
	_workshop_screen_component.detach()

func focus_first_button() -> void:
	# A full-screen inspector must never hand keyboard/controller focus back to
	# obscured route controls while it is visible.  Its Close button is the first
	# deterministic target, then normal route traversal resumes.
	for modal_name in ["UnifiedPackReveal", "StarterCardInspector", "UnifiedCardInspector"]:
		var modal := find_child(modal_name, true, false) as Control
		if modal != null and modal.is_visible_in_tree():
			for node in modal.find_children("*", "Button", true, false):
				var modal_button := node as Button
				if modal_button != null and modal_button.is_visible_in_tree() and not modal_button.disabled:
					modal_button.grab_focus()
					return
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

func _shows_workshop_hud() -> bool:
	# The shared progression strip belongs to every finished/non-battle surface.
	# Keep the initial blueprint ceremony intentionally uncluttered; the selected
	# starter's Forge screen immediately regains this HUD after selection.
	# Compatibility recovery is deliberately explicit even for a future profile
	# that happens to resemble a fresh onboarding save.
	if GameManager.is_save_read_only(): return true
	return screen != "unified_battle" and screen != "onboarding" and str(GameManager.profile.get("onboarding", {}).get("state", "choose_starter")) != "choose_starter"

func render_header(root: VBoxContainer) -> void:
	var header_box := PanelContainer.new()
	header_box.name = "WorkshopHeader"
	var portrait := size.y > size.x
	header_box.custom_minimum_size = Vector2(0, 76 if portrait else 60)
	header_box.add_theme_stylebox_override("panel", panel_style(Color("25211be8"), Color("c39450")))
	root.add_child(header_box)
	var header := HBoxContainer.new()
	header.name = "WorkshopHud"
	header.custom_minimum_size = Vector2(0, 48)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 10)
	header_box.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.custom_minimum_size = Vector2(140 if portrait else 160, 48)
	header.add_child(titles)
	titles.add_child(label("PRINTFORGE", 21, Color("ffd36c")))
	titles.add_child(label("Workshop", 13, Color("9beaff")))
	if GameManager.is_save_read_only():
		var compatibility := label("READ-ONLY COMPATIBILITY MODE\nSave schema is newer than this build", 15, Color("ffcfbf"))
		compatibility.name = "ReadOnlyCompatibilityHeader"
		compatibility.custom_minimum_size = Vector2(0 if portrait else 250, 40 if portrait else 58)
		compatibility.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
		compatibility.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
		compatibility.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(compatibility)
	else:
		var level := int(GameManager.profile.get("spool_level", 1))
		var account := label("Spool Level %d · XP %d / %d · %d Forge Coins" % [level, int(GameManager.profile.get("spool_xp", 0)), level * 100, int(GameManager.profile.get("forge_coins", 0))], 14 if portrait else 15, Color("d6f7ff"))
		account.name = "WorkshopHudProgress"
		account.custom_minimum_size = Vector2(310 if portrait else 360, 52 if portrait else 48)
		account.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
		account.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		account.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(account)

func _compact_pager_label(text_value: String) -> Label:
	var value := label(text_value, 14, Color("e6dfd0"))
	value.custom_minimum_size = Vector2(72, 44)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return value

func render_onboarding_fullscreen(host: Container) -> void:
	if is_portrait_layout():
		_render_portrait_starter_carousel(host)
		return
	var ceremony := VBoxContainer.new(); ceremony.name = "StarterBlueprintCeremony"; ceremony.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ceremony.add_theme_constant_override("separation", 12); host.add_child(ceremony)
	var title := label("CHOOSE A STARTER BLUEPRINT", 25, Color("fff0bb")); title.name = "StarterBlueprintTitle"; title.custom_minimum_size = Vector2(0, 34); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ceremony.add_child(title)
	var subtitle := label("Three Forge patterns are ready. Select one to load its free first print.", 13, Color("d7f6ff")); subtitle.name = "StarterBlueprintSubtitle"; subtitle.custom_minimum_size = Vector2(0, 22); subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL; subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ceremony.add_child(subtitle)
	var cards := GridContainer.new(); cards.name = "StarterChoiceGrid"; cards.columns = 2 if is_portrait_layout() else 3; cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL; cards.add_theme_constant_override("h_separation", 12); cards.add_theme_constant_override("v_separation", 12)
	if is_portrait_layout(): ceremony.add_child(cards)
	else:
		var centered_row := CenterContainer.new(); centered_row.name = "StarterLandscapeCenterRow"; centered_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL; centered_row.custom_minimum_size = Vector2(0, 338); ceremony.add_child(centered_row)
		cards.custom_minimum_size = Vector2(1140, 0); centered_row.add_child(cards)
	var choices := UNIFIED_RULES.STARTER_IDS
	for index in choices.size():
		if is_portrait_layout() and index == 2:
			var centered := CenterContainer.new(); centered.name = "StarterThirdBlueprintCenter"; centered.size_flags_horizontal = Control.SIZE_EXPAND_FILL; centered.custom_minimum_size = Vector2(0, 250); ceremony.add_child(centered)
			var third := _starter_schematic_card(str(choices[index])); third.custom_minimum_size.x = maxf(250, size.x * 0.58); centered.add_child(third)
		else:
			cards.add_child(_starter_schematic_card(str(choices[index])))
	var hint := label("Blueprints are unassembled patterns. Your selected pattern loads directly into the Forge.", 12, Color("9edeea")); hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ceremony.add_child(hint)
	var back := _visual_button("StarterBack", "BACK TO TITLE", request_back, Color("7398ad"), false)
	PHYSICAL_NAVIGATION.configure_back(back, "Title")
	ceremony.add_child(back)
	if not starter_inspector_id.is_empty(): render_starter_inspector()

func render_m1_r2_starter_page() -> void:
	var choices := UNIFIED_RULES.STARTER_IDS
	starter_page = posmod(starter_page, choices.size())
	var starter_id := str(choices[starter_page])
	var creature := Catalog.creature(starter_id)
	var accent := Color(ELEMENT_COLORS.get(str(creature.get("element", "")), "76ddff"))
	var plate := PHYSICAL_PORTRAIT_PLATE.new()
	plate.name = "StarterR2PhysicalPlate"
	plate.configure(M1_PHYSICAL_UI.texture_for("starter_desk"))
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(plate)
	_apply_presentation_safe_area(plate)
	var surface := Control.new()
	surface.name = "StarterR2PhysicalSurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.content_layer().add_child(surface)
	var content := Control.new()
	content.name = "StarterCarouselCard"
	content.set_meta("starter_id", starter_id)
	M1_PHYSICAL_UI.place_design(content, Rect2(205, 150, 530, 710))
	surface.add_child(content)
	# This heading and its facts sit on the pale starter parchment, so retain the
	# approved dark ink rather than inheriting generic cream-on-dark UI colors.
	var heading := label("CHOOSE A\nSTARTER BLUEPRINT", 18, Color("10283a") if not bool(settings().get("high_contrast", false)) else Color("000000"))
	heading.name = "StarterBlueprintTitle"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.anchor_right = 1.0; heading.offset_bottom = 92
	content.add_child(heading)
	var art := TextureRect.new()
	art.name = "StarterBlueprintSchematic"
	art.texture = _blueprint_card_texture(creature)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.anchor_left = 0.10; art.anchor_top = 0.15; art.anchor_right = 0.90; art.anchor_bottom = 0.62
	content.add_child(art)
	var name_label := label(str(creature.get("name", starter_id)), 28, accent)
	name_label.name = "StarterNativeName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.anchor_left = 0.05; name_label.anchor_right = 0.95; name_label.anchor_top = 0.63; name_label.anchor_bottom = 0.71
	content.add_child(name_label)
	var stats := label("%s  ·  HP %d  ·  BEND %d" % [str(creature.get("element", "")), int(creature.get("hp", 0)), int(creature.get("bend", 0))], 15, Color("47331f") if not bool(settings().get("high_contrast", false)) else Color("000000"))
	stats.name = "StarterNativeStats"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.anchor_left = 0.04; stats.anchor_right = 0.96; stats.anchor_top = 0.72; stats.anchor_bottom = 0.78
	content.add_child(stats)
	var free_status := label("FIRST PRINT · FREE", 15, Color("6b431f") if not bool(settings().get("high_contrast", false)) else Color("000000"))
	free_status.name = "StarterNativeFreeStatus"
	free_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	free_status.anchor_left = 0.04; free_status.anchor_right = 0.96; free_status.anchor_top = 0.80; free_status.anchor_bottom = 0.86
	content.add_child(free_status)
	# The illustrated desk already owns the left/right chevrons. Native controls
	# preserve the larger accessible target without painting duplicate words on them.
	var previous := _visual_button("StarterPrevious", "", func(): starter_page = posmod(starter_page - 1, choices.size()); render(), Color("587f90"))
	previous.custom_minimum_size = Vector2(48, 48)
	M1_PHYSICAL_UI.place_design(previous, Rect2(22, 920, 185, 105))
	previous.accessibility_name = "Previous starter blueprint"
	M1_PHYSICAL_UI.apply_cream_action(previous)
	surface.add_child(previous)
	var next := _visual_button("StarterNext", "", func(): starter_page = posmod(starter_page + 1, choices.size()); render(), Color("587f90"))
	next.custom_minimum_size = Vector2(48, 48)
	M1_PHYSICAL_UI.place_design(next, Rect2(733, 920, 186, 105))
	surface.add_child(next)
	var medallion := label("%d / %d" % [starter_page + 1, choices.size()], 17, Color("10283a") if not bool(settings().get("high_contrast", false)) else Color("000000"))
	medallion.name = "StarterPageMedallion"
	medallion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medallion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next.accessibility_name = "Next starter blueprint"
	M1_PHYSICAL_UI.apply_cream_action(next)
	M1_PHYSICAL_UI.place_design(medallion, Rect2(374, 920, 190, 105))
	surface.add_child(medallion)
	var inspect := _visual_button("StarterInspectFocused", "INSPECT", show_starter_inspector.bind(starter_id), accent)
	inspect.custom_minimum_size = Vector2(48, 48)
	inspect.accessibility_name = "Inspect %s blueprint" % str(creature.get("name", starter_id))
	M1_PHYSICAL_UI.place_design(inspect, Rect2(72, 1100, 310, 120))
	M1_PHYSICAL_UI.apply_cream_action(inspect)
	surface.add_child(inspect)
	var confirm := _visual_button("StarterConfirmFocused", "CONFIRM", func(): pending_starter_id = starter_id; confirm_starter(), Color("f1be69"), true)
	confirm.custom_minimum_size = Vector2(0, 56)
	confirm.accessibility_name = "Confirm %s blueprint and open its free first print" % str(creature.get("name", starter_id))
	M1_PHYSICAL_UI.place_design(confirm, Rect2(558, 1100, 310, 120))
	M1_PHYSICAL_UI.apply_cream_action(confirm)
	surface.add_child(confirm)
	var helper := label("INSPECT TO PREVIEW\nCONFIRM TO FORGE", 11, Color("10283a") if not bool(settings().get("high_contrast", false)) else Color("000000"))
	helper.name = "StarterNativeHelper"
	helper.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	helper.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	helper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# This compact instruction sits on its own lower plaque, below the center
	# counter and the two authored action plates.
	M1_PHYSICAL_UI.place_design(helper, Rect2(175, 1360, 591, 95))
	surface.add_child(helper)
	var back := _visual_button("StarterBack", "BACK", request_back, Color("7398ad"), false)
	PHYSICAL_NAVIGATION.configure_back(back, "Title")
	M1_PHYSICAL_UI.place_design(back, Rect2(32, 55, 150, 92))
	surface.add_child(back)
	for index in 3:
		var socket := TextureRect.new()
		socket.name = "StarterInnerSocket%d" % index
		socket.texture = _blueprint_card_texture(Catalog.creature(str(choices[index])))
		socket.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		socket.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Keep the transparent blueprint ink inside each circular socket instead of
		# letting the source canvas reach across the brass rim.
		# These are the three measured inner-circle centers in the starter master.
		# Their 186px pitch is intentionally wider than the carousel's old 150px
		# spacing, which had pushed Voltwig out onto the left brass rim.
		M1_PHYSICAL_UI.place_design(socket, Rect2(250 + index * 186, 1516, 68, 68))
		surface.add_child(socket)
	if not starter_inspector_id.is_empty(): render_starter_inspector()

func _render_portrait_starter_carousel(host: Container) -> void:
	var choices := UNIFIED_RULES.STARTER_IDS
	starter_page = posmod(starter_page, choices.size()); var starter_id := str(choices[starter_page]); var creature := Catalog.creature(starter_id)
	var ceremony := VBoxContainer.new(); ceremony.name = "StarterBlueprintCarousel"; ceremony.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ceremony.add_theme_constant_override("separation", 10); host.add_child(ceremony)
	var title := label("CHOOSE A STARTER BLUEPRINT", 24, Color("fff0bb")); title.name = "StarterBlueprintTitle"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ceremony.add_child(title)
	var pager := HBoxContainer.new(); pager.alignment = BoxContainer.ALIGNMENT_CENTER; ceremony.add_child(pager)
	var previous := _visual_button("StarterPrevious", "‹", func(): starter_page = posmod(starter_page - 1, choices.size()); render(), Color("587f90")); previous.custom_minimum_size = Vector2(48,48); pager.add_child(previous)
	pager.add_child(_compact_pager_label("%d / %d" % [starter_page + 1, choices.size()]))
	var next := _visual_button("StarterNext", "›", func(): starter_page = posmod(starter_page + 1, choices.size()); render(), Color("587f90")); next.custom_minimum_size = Vector2(48,48); pager.add_child(next)
	var card := _visual_panel("StarterCarouselCard", Color("071a25e8"), Color(ELEMENT_COLORS.get(str(creature.get("element", "")), "76ddff")), 12); card.custom_minimum_size = Vector2(0, 420); ceremony.add_child(card)
	card.set_meta("starter_id", starter_id)
	var content := VBoxContainer.new(); content.add_theme_constant_override("separation", 6); card.add_child(content)
	var art := TextureRect.new(); art.name = "StarterBlueprintCard"; art.texture = _blueprint_card_texture(creature); art.custom_minimum_size = Vector2(0,240); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; content.add_child(art)
	var element_color := Color(ELEMENT_COLORS.get(str(creature.get("element", "")), "76ddff")); var name_label := label(str(creature.get("name", starter_id)), 24, element_color); name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; content.add_child(name_label)
	var stats := label("%s · HP %d · BEND %d · FIRST PRINT FREE" % [str(creature.get("element", "")), int(creature.get("hp", 0)), int(creature.get("bend", 0))], 14, Color("d8edf4")); stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; content.add_child(stats)
	var actions := HBoxContainer.new(); actions.add_theme_constant_override("separation", 8); ceremony.add_child(actions)
	var inspect := _visual_button("StarterInspectFocused", "INSPECT", show_starter_inspector.bind(starter_id), element_color); inspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL; actions.add_child(inspect)
	var confirm := _visual_button("StarterConfirmFocused", "CONFIRM BLUEPRINT", func(): pending_starter_id = starter_id; confirm_starter(), Color("f1be69"), true); confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL; actions.add_child(confirm)
	var hint := label("Inspect does not choose. Confirm grants one starter and opens its empty Forge bed.", 12, Color("9edeea")); hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ceremony.add_child(hint)
	var back := _visual_button("StarterBack", "BACK TO TITLE", request_back, Color("7398ad"), false)
	PHYSICAL_NAVIGATION.configure_back(back, "Title")
	ceremony.add_child(back)
	if not starter_inspector_id.is_empty(): render_starter_inspector()

func render_onboarding() -> void:
	var intro := make_panel(Color("182d49ed"), Color("f1be69"))
	body.add_child(intro.get_parent())
	intro.add_child(label("Choose your first blueprint", 25, Color("ffd36c")))
	intro.add_child(label("Inspect a schematic, then select one pattern for a free first print.", 15, Color("e1eef9")))
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
		var portrait := TextureRect.new()
		portrait.name = "StarterBlueprintSchematic"
		portrait.texture = _blueprint_card_texture(creature)
		portrait.custom_minimum_size = Vector2(190, 150)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		card.add_child(label("SCHEMATIC · PRINT UNASSEMBLED", 12, Color("9beaff")))
		card.add_child(label(str(creature.name), 24, element_color))
		card.add_child(label("%s · %d HP · BEND %d" % [creature.element, int(creature.hp), int(creature.bend)], 15, Color("dbe9f6")))
		card.add_child(make_button("Selected" if pending_starter_id == starter_id else "View card", show_starter_inspector.bind(starter_id), element_color.darkened(0.35)))
	var confirmation := make_panel(Color("352719ed"), Color("f1be69"))
	body.add_child(confirmation.get_parent())
	confirmation.add_child(label("Blueprint choice", 19, Color("fff0a1")))
	if pending_starter_id.is_empty():
		confirmation.add_child(label("Select one card above to enable confirmation.", 15, Color("c6d7e8")))
	else:
		confirmation.add_child(make_button("Forge %s blueprint" % Catalog.creature(pending_starter_id).name, confirm_starter, Color("a86b2e")))
	if not starter_inspector_id.is_empty(): render_starter_inspector()

func show_starter_inspector(starter_id: String) -> void:
	if Catalog.creature(starter_id).is_empty(): return
	starter_inspector_id = starter_id
	render()

func render_m1_r2_starter_inspector_folio(creature: Dictionary) -> void:
	var modal := ColorRect.new()
	modal.name = "StarterCardInspector"
	modal.color = Color("07111bf0")
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.focus_mode = Control.FOCUS_ALL
	modal.accessibility_name = "Starter blueprint inspector"
	add_child(modal)
	var plate := PHYSICAL_PORTRAIT_PLATE.new()
	plate.name = "StarterR2InspectionFolio"
	plate.configure(M1_PHYSICAL_UI.texture_for("starter_inspector"))
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(plate)
	_apply_presentation_safe_area(plate)
	var surface := Control.new()
	surface.name = "StarterR2InspectorSurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.content_layer().add_child(surface)
	var art := TextureRect.new()
	art.name = "StarterInspectorBlueprintSchematic"
	art.texture = _blueprint_card_texture(creature)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	M1_PHYSICAL_UI.place_design(art, Rect2(154, 270, 630, 540))
	surface.add_child(art)
	var title := label(str(creature.get("name", "")).to_upper(), 21, Color("10283a"))
	title.name = "StarterInspectorNativeTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	M1_PHYSICAL_UI.place_design(title, Rect2(285, 160, 370, 80))
	surface.add_child(title)
	var facts := label("%s · HP %d · BEND %d\n%s" % [str(creature.get("element", "")), int(creature.get("hp", 0)), int(creature.get("bend", 0)), str(creature.get("ability", ""))], 17, Color("10283a"))
	facts.name = "StarterInspectorNativeFacts"
	facts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	facts.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	M1_PHYSICAL_UI.place_design(facts, Rect2(100, 820, 741, 280))
	surface.add_child(facts)
	var select := _visual_button("StarterInspectorSelect", "SELECT", func(): pending_starter_id = starter_inspector_id; starter_inspector_id = ""; render(), Color("f1be69"), true)
	select.accessibility_name = "Select this blueprint"
	select.custom_minimum_size = Vector2(0, 56)
	M1_PHYSICAL_UI.place_design(select, Rect2(84, 1400, 360, 120))
	M1_PHYSICAL_UI.apply_cream_action(select)
	surface.add_child(select)
	var close := _visual_button("StarterInspectorClose", "CLOSE", func(): starter_inspector_id = ""; render(), Color("7398ad"))
	close.custom_minimum_size = Vector2(56, 56)
	M1_PHYSICAL_UI.place_design(close, Rect2(500, 1400, 360, 120))
	M1_PHYSICAL_UI.apply_cream_action(close)
	surface.add_child(close)
	call_deferred("_deferred_focus_if_ready", close.get_instance_id())
func render_starter_inspector() -> void:
	var creature := Catalog.creature(starter_inspector_id)
	if creature.is_empty(): return
	if is_portrait_layout():
		render_m1_r2_starter_inspector_folio(creature)
		return
	var modal := ColorRect.new()
	modal.name = "StarterCardInspector"
	modal.color = Color("07111bf0")
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.focus_mode = Control.FOCUS_ALL
	modal.accessibility_name = "Starter blueprint inspector"
	add_child(modal)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var shell := PanelContainer.new()
	shell.custom_minimum_size = Vector2(minf(760, size.x - 28), minf(640, size.y - 28))
	shell.focus_mode = Control.FOCUS_ALL
	shell.accessibility_name = "Starter blueprint inspector content"
	shell.add_theme_stylebox_override("panel", panel_style(Color("102940f8"), Color(ELEMENT_COLORS.get(str(creature.element), "9beaff"))))
	center.add_child(shell)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	shell.add_child(content)
	var art_frame := Control.new()
	art_frame.custom_minimum_size = Vector2(300, 300 if is_portrait_layout() else 260)
	content.add_child(art_frame)
	var art := TextureRect.new()
	art.name = "StarterInspectorBlueprintSchematic"
	art.texture = _blueprint_card_texture(creature)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_blueprint_ink(art)
	art_frame.add_child(art)
	var drafting := BLUEPRINT_SCHEMATIC_OVERLAY.new(); drafting.name = "StarterInspectorDraftGrid"; drafting.configure(Color("72ecff"), 0.9); drafting.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); drafting.mouse_filter = Control.MOUSE_FILTER_IGNORE; art_frame.add_child(drafting)
	content.add_child(label(str(creature.name), 27, Color(ELEMENT_COLORS.get(str(creature.element), "9beaff"))))
	content.add_child(label("Blueprint schematic · %s · %s" % [str(creature.element), str(Catalog.rarity(str(creature.rarity)).name)], 15, Color("dce8f4")))
	content.add_child(label("HP %d · Bend %d\n%s" % [int(creature.hp), int(creature.bend), str(creature.ability)], 17, Color("fff9df")))
	content.add_child(make_button("Select this blueprint", func(): pending_starter_id = starter_inspector_id; starter_inspector_id = ""; render(), Color("a86b2e")))
	var close := make_button("Close", func(): starter_inspector_id = ""; render(), Color("536c8d"))
	content.add_child(close)
	# A modal-owned, actionable first focus avoids trapping keyboard/controller
	# users on a button hidden behind this full-screen overlay.
	call_deferred("_deferred_focus_if_ready", close.get_instance_id())

func confirm_starter() -> void:
	if not OnboardingState.can_confirm(GameManager.profile, pending_starter_id):
		_toast("Choose one Forge Trio companion first.")
		return
	# The free print remains a separate, required completion seam. Choose before
	# changing screens: the journaled profile signal can render synchronously.
	if GameManager.choose_starter(pending_starter_id):
		printer_return_screen = "workshop"
		screen = "printer"
		open_printer(pending_starter_id)
		pending_starter_id = ""
		return
	screen = "onboarding"
	render()

func render_workshop() -> void:
	var used_today := 0
	if workshop_view == "overview":
		render_workshop_overview(used_today)
	else:
		render_workshop_closeup(used_today)
	if str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected":
		var starter_id := str(GameManager.profile.get("onboarding", {}).get("starter_id", ""))
		var starter_prompt := make_panel(Color("352719ed"), Color("f1be69"))
		body.add_child(starter_prompt.get_parent())
		starter_prompt.add_child(label("Blue blueprint ready", 20, Color("fff0a1")))
		starter_prompt.add_child(label("Your first %s print is free. Complete it at the Arcane Forge to enter the workshop." % str(Catalog.creature(starter_id).get("name", "starter")), 15, Color("fff9df")))
		starter_prompt.add_child(make_button("Continue free Forge print", open_printer.bind(starter_id), Color("a86b2e")))
	return

func _workshop_views() -> Array:
	return [
		{"id":"printer", "name":"Printer Bench", "callout":"Workshop Models and Collection", "description":"Review learned blueprints and print display models with Forge Coins.", "rect":Rect2(0.08, 0.32, 0.28, 0.44), "objects":[{"id":"forge_machine", "name":"Workshop Model Forge", "description":"Choose an owned blueprint and print a collection model.", "target":"unified_forgedex", "rect":Rect2(0.34, 0.27, 0.36, 0.56)}, {"id":"collection_case", "name":"Collection Case", "description":"Review owned blueprints and printed models.", "target":"unified_forgedex", "rect":Rect2(0.08, 0.06, 0.25, 0.66)}]},
		{"id":"maker", "name":"Maker Bench", "callout":"Pre-prints, decks, equipment cards", "description":"Set your active deck, Pre-Print loadout, and battle equipment cards.", "rect":Rect2(0.03, 0.68, 0.31, 0.26), "objects":[{"id":"team_board", "name":"Pre-Print Board", "description":"Choose creature copies from the active deck to start in Defense Mode.", "target":"unified_deck", "rect":Rect2(0.02, 0.47, 0.27, 0.28)}, {"id":"deck_blueprints", "name":"Deck Blueprint Rack", "description":"Edit one of three fixed legal 40-card deck slots.", "target":"deck", "rect":Rect2(0.38, 0.26, 0.24, 0.40)}, {"id":"card_archive", "name":"Card Archive", "description":"Browse battle cards, rules, and owned copies.", "target":"archive", "rect":Rect2(0.26, 0.52, 0.28, 0.18)}, {"id":"armor_tools", "name":"Equipment Cards", "description":"Browse full suits, combat gems, and the Filament Ring for battle decks.", "target":"unified_library", "rect":Rect2(0.58, 0.15, 0.24, 0.55)}, {"id":"calibration_dial", "name":"Upgrade Forge", "description":"Open Workshop upgrades and in-battle Upgrade Cards.", "target":"calibration", "rect":Rect2(0.80, 0.40, 0.16, 0.32)}]},
		{"id":"terminal", "name":"Forge Terminal", "callout":"Offers, Forgedex, Guild Trade", "description":"Browse fixed daily offers, records, and a local kid-safe trade demo.", "rect":Rect2(0.65, 0.30, 0.23, 0.34), "objects":[{"id":"offer_screen", "name":"Forge Offers", "description":"Review today's deterministic blueprint, card, and armor offers.", "target":"shop", "rect":Rect2(0.57, 0.35, 0.10, 0.29)}, {"id":"forgedex_screen", "name":"Forgedex Terminal", "description":"Track every discovered creature blueprint.", "target":"codex", "rect":Rect2(0.67, 0.35, 0.11, 0.29)}, {"id":"trade_terminal", "name":"Guild Trade Table", "description":"Open a credential-free two-profile escrow demonstration.", "target":"trade", "rect":Rect2(0.78, 0.35, 0.12, 0.29)}]},
		{"id":"proving", "name":"Battle Arena", "callout":"Daily Training, Trials, Local Versus", "description":"Enter the Battle Arena for daily training, ordered Workshop Trials, or a private hot-seat match.", "rect":Rect2(0.45, 0.18, 0.20, 0.50), "objects":[{"id":"training_door", "name":"Battle Arena", "description":"Choose a repeatable daily rival or an ordered Workshop Trial with fixed first-clear rewards.", "target":"proving", "rect":Rect2(0.42, 0.39, 0.23, 0.27)}, {"id":"versus_marker", "name":"Local Versus", "description":"Pass the device between two private players. No rewards are granted.", "target":"local_vs", "rect":Rect2(0.48, 0.64, 0.16, 0.17)}]},
		{"id":"yard", "name":"Print Yard", "callout":"Daily filament lesson", "description":"Visit printed companions for one calm, limited XP lesson each day.", "rect":Rect2(0.37, 0.63, 0.27, 0.29), "objects":[{"id":"yard_companions", "name":"Daily Print Yard", "description":"Share today's local filament lesson with your current collection.", "target":"yard", "rect":Rect2(0.31, 0.44, 0.34, 0.28)}]}
	]

func _workshop_view_data(view_id: String) -> Dictionary:
	for view in _workshop_views():
		if str(view.id) == view_id: return view
	return {}

func _workshop_overview_texture() -> Texture2D:
	return WORKSHOP_OVERVIEW_PORTRAIT_TEXTURE if is_portrait_layout() else WORKSHOP_OVERVIEW_LANDSCAPE_TEXTURE

func _workshop_overview_hotspots() -> Array:
	# The v6 plates are full-room compositions. Each transparent target follows a
	# pictured physical object, so the overview goes straight to its destination.
	if is_portrait_layout():
		return [
			{"id":"printer", "name":"Workshop Model Forge", "description":"Review owned blueprints and print collection models.", "target":"printer", "rect":Rect2(0.03, 0.45, 0.30, 0.15)},
			{"id":"collection", "name":"Printer Drawers", "description":"Review owned blueprints and printed models.", "target":"unified_forgedex", "rect":Rect2(0.06, 0.60, 0.28, 0.18)},
			{"id":"team", "name":"Pre-Print Board", "description":"Set a v3 deck and creature Pre-Print loadout.", "target":"unified_deck", "rect":Rect2(0.18, 0.10, 0.43, 0.13)},
			{"id":"armor", "name":"Equipment Cards", "description":"Browse battle full suits, combat gems, and the Filament Ring.", "target":"unified_library", "rect":Rect2(0.62, 0.10, 0.16, 0.20)},
			{"id":"battle_arena", "name":"Battle Arena", "description":"Choose daily training, Workshop Trials, or Local Versus.", "target":"proving", "rect":Rect2(0.24, 0.39, 0.54, 0.14)},
			{"id":"card_archive", "name":"Support Card Deck", "description":"Browse the Support Card Archive.", "target":"archive", "rect":Rect2(0.72, 0.69, 0.17, 0.13)},
			{"id":"shop", "name":"Forge Offers Panel", "description":"Review today's deterministic Forge Offers.", "target":"shop", "rect":Rect2(0.68, 0.50, 0.09, 0.13)},
			{"id":"codex", "name":"Forgedex Panel", "description":"Track discovered creature blueprints.", "target":"codex", "rect":Rect2(0.77, 0.50, 0.09, 0.13)},
			{"id":"trade", "name":"Guild Trade Panel", "description":"Open the credential-free local trade table.", "target":"trade", "rect":Rect2(0.86, 0.50, 0.10, 0.13)},
			{"id":"upgrade_forge", "name":"Upgrade Forge", "description":"Browse permanent Workshop upgrades and Upgrade Cards.", "target":"calibration", "rect":Rect2(0.29, 0.53, 0.07, 0.07)}
		]
	return [
		{"id":"printer", "name":"Workshop Model Forge", "description":"Review owned blueprints and print collection models.", "target":"printer", "rect":Rect2(0.07, 0.43, 0.20, 0.27)},
			{"id":"collection", "name":"Printer Drawers", "description":"Review owned blueprints and printed models.", "target":"unified_forgedex", "rect":Rect2(0.22, 0.66, 0.12, 0.24)},
			{"id":"team", "name":"Pre-Print Board", "description":"Set a v3 deck and creature Pre-Print loadout.", "target":"unified_deck", "rect":Rect2(0.32, 0.08, 0.25, 0.16)},
			{"id":"armor", "name":"Equipment Cards", "description":"Browse battle full suits, combat gems, and the Filament Ring.", "target":"unified_library", "rect":Rect2(0.58, 0.08, 0.13, 0.20)},
		{"id":"battle_arena", "name":"Battle Arena", "description":"Choose daily training, Workshop Trials, or Local Versus.", "target":"proving", "rect":Rect2(0.31, 0.47, 0.40, 0.22)},
		{"id":"card_archive", "name":"Support Card Deck", "description":"Browse the Support Card Archive.", "target":"archive", "rect":Rect2(0.78, 0.76, 0.11, 0.13)},
		{"id":"shop", "name":"Forge Offers Panel", "description":"Review today's deterministic Forge Offers.", "target":"shop", "rect":Rect2(0.73, 0.47, 0.07, 0.16)},
		{"id":"codex", "name":"Forgedex Panel", "description":"Track discovered creature blueprints.", "target":"codex", "rect":Rect2(0.80, 0.47, 0.07, 0.16)},
		{"id":"trade", "name":"Guild Trade Panel", "description":"Open the credential-free local trade table.", "target":"trade", "rect":Rect2(0.87, 0.47, 0.07, 0.16)},
		{"id":"upgrade_forge", "name":"Upgrade Forge", "description":"Browse permanent Workshop upgrades and Upgrade Cards.", "target":"calibration", "rect":Rect2(0.25, 0.63, 0.05, 0.07)}
	]

func _workshop_texture(view_id: String) -> Texture2D:
	var path: String = str(WORKSHOP_CLOSEUP_PATHS.get(view_id, "res://assets/ui/workshop/workshop-theme-reference-fallback.jpg"))
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

func _workshop_overview_hotspot_node_suffix(hotspot_id: String) -> String:
	var suffixes := {"battle_arena":"BattleArena", "card_archive":"CardArchive"}
	if suffixes.has(hotspot_id): return str(suffixes[hotspot_id])
	return hotspot_id.replace("_", " ").capitalize().replace(" ", "")

func _workshop_overview_hotspot_button(hotspot: Dictionary) -> Button:
	var rect: Rect2 = hotspot.rect
	var button := Button.new()
	button.name = "WorkshopHotspot%s" % _workshop_overview_hotspot_node_suffix(str(hotspot.id))
	button.text = ""
	button.tooltip_text = "%s: %s" % [str(hotspot.name), str(hotspot.description)]
	button.accessibility_name = str(hotspot.name)
	button.anchor_left = rect.position.x; button.anchor_top = rect.position.y; button.anchor_right = rect.end.x; button.anchor_bottom = rect.end.y
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.custom_minimum_size = Vector2(48, 48)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("workshop_target", str(hotspot.target))
	button.add_theme_stylebox_override("normal", workshop_hotspot_style())
	button.add_theme_stylebox_override("hover", workshop_hotspot_style())
	# All direct hit states stay transparent over the authored prop. The child
	# four-edge ring below is the only focus chrome, inset to the actual silhouette.
	button.add_theme_stylebox_override("focus", workshop_hotspot_style())
	button.add_theme_stylebox_override("pressed", workshop_hotspot_style())
	# The ring follows the exact approved-prop zone, rather than covering the
	# Workshop with a generic cyan action plaque.
	_add_workshop_tight_focus_ring(button, str(hotspot.id))
	button.gui_input.connect(func(event: InputEvent):
		if (event is InputEventKey or event is InputEventJoypadButton) and event.pressed:
			_focus_after_render = true)
	if bool(hotspot.get("m1_physical", false)):
		button.pressed.connect(_run_workshop_station.bind(str(hotspot.target)))
	else:
		button.pressed.connect(activate_workshop_overview_hotspot.bind(str(hotspot.id)))
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

func _add_workshop_tight_focus_ring(button: Button, hotspot_id: String) -> void:
	var high_contrast := bool(settings().get("high_contrast", false))
	M1_PHYSICAL_UI.add_complete_focus_ring(button, hotspot_id, high_contrast, _visual_style)

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
	var button := make_button("Open Arcane Forge", open_printer_picker, Color("a86b2e"))
	button.name = "PrinterBlueprintTrayButton"
	button.tooltip_text = "Open the Arcane Forge and choose a learned creature blueprint"
	button.accessibility_name = "Open Arcane Forge"
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
	# Reserve enough portrait space for the bottom-row direct-object targets; the
	# prior 215px allowance clipped the Support Card Deck target on 576x1024.
	var viewport_height := get_viewport().get_visible_rect().size.y
	var overview_height := maxf(620.0, viewport_height - 235.0) if overview_layout_portrait else (maxf(360.0, viewport_height - 210.0) if viewport_height <= 600.0 else maxf(500.0, viewport_height - 150.0))
	# v6 overview plates are aspect-specific, static full-room shots. They never
	# host mutable-looking printer/team overlays or motion; those belong in stations.
	# Landscape keeps the complete orientation-matched foreground plane for its
	# normalized hotspot map, with a dim covered backdrop and modest zoom to
	# reduce empty side pillars without losing any pictured direct-object target.
	var landscape := not overview_layout_portrait
	var map := _workshop_surface("WorkshopMap", _workshop_overview_texture(), overview_height, null, false, "overview", landscape, false, Vector2(0.5, 0.5), 1.12 if landscape else 1.0)
	map.add_child(_workshop_settings_button())
	for hotspot in _workshop_overview_hotspots(): map.add_child(_workshop_overview_hotspot_button(hotspot))
	_add_workshop_overview_status(map, used_today)

func render_workshop_closeup(used_today: int) -> void:
	var view := _workshop_view_data(workshop_view)
	if view.is_empty():
		open_workshop_view("overview")
		return
	# `printer_picker_open` is retained as a serialized/caller compatibility bit,
	# never as a visible intermediate route. Creature selection lives in Forge.
	var picker_open := false
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
		if workshop_view == "printer" and not picker_open:
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
	if workshop_view == "printer" and not picker_open:
		chrome.add_child(_printer_picker_button())
	for object in view.objects: map.add_child(_workshop_object_button(object))
	# The Blueprint Tray owns the nearby explanatory space. Leaving the station
	# status strip underneath it creates a narrow, unreadable duplicate band.
	if not picker_open:
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
		strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = 0; strip.offset_bottom = 72
	elif workshop_view in ["printer", "maker"]:
		# Live v3 station scenes reserve their lower landmarks for the printer bed or
		# three plinths. A compact top strip leaves both controls and prop bases clear.
		strip.anchor_left = 0.14; strip.anchor_right = 0.84
		strip.anchor_top = 0.025; strip.anchor_bottom = 0.025
		strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = 0; strip.offset_bottom = 72
	else:
		strip.anchor_top = 1.0; strip.anchor_bottom = 1.0
		strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = -94; strip.offset_bottom = -14
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_theme_stylebox_override("panel", inset_style(Color("102940e8"), Color("f1be69")))
	scene_map.add_child(strip)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	strip.add_child(content)
	content.add_child(label("%s - %s" % [str(view.name), str(view.callout)], 16, Color("ffd36c")))
	var detail := "Focus a highlighted tool to open its Blueprint Tray."
	if workshop_view == "maker": detail = "Choose a fixed deck, Pre-Print loadout, equipment cards, or Workshop upgrade."
	elif workshop_view == "yard": detail = "%d Workshop models are on display." % GameManager.profile.get("printed_models", {}).size()
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
	content.add_child(label("Choose a station", 16, Color("9beaff")))
	content.add_child(label("Forge · Archive · Battle", 13, Color("dce8f4")))

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
	# Retained facade for callers outside the integrated selector.
	return _blueprint_tray_view.blueprint_ids(GameManager.profile)

func select_printer_blueprint(creature_id: String) -> void:
	# Main owns the selected ID and dormant Forge preview; this remains
	# authority-neutral until the existing commit seam reaches raw completion.
	if printer_is_armor or printer_sequence == null or printer_sequence.phase != ArcaneForgeSequence.IDLE:
		return
	if creature_id not in printer_blueprint_ids():
		return
	printer_blueprint_selected_id = creature_id
	printer_creature_id = creature_id
	var definition := Catalog.creature(creature_id)
	printer_price = int(UNIFIED_RULES.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), 20))
	render()

func render_printer_blueprint_tray(host: Control = null) -> void:
	# Compatibility name: the former separate tray is now cards embedded directly
	# in the Arcane Forge. It deliberately owns no preview or close action.
	printer_blueprint_selected_id = _blueprint_tray_view.render(host if host != null else body, printer_blueprint_selected_id, {
		"profile": GameManager.profile,
		"portrait": is_portrait_layout(),
		"schematic_only": str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected",
		"reduced_motion": bool(settings().get("reduced_motion", false)),
		"label": label,
		"make_button": make_button,
		"make_panel": make_panel,
		"inset_style": inset_style,
		"cartridge_style": func(selected: bool) -> StyleBox: return ARCANE_FOUNDRY_THEME_KIT.cartridge(selected, bool(settings().get("high_contrast", false))),
		"select_blueprint": select_printer_blueprint,
		"open_offers": navigate_to.bind("shop")
	})

func _workshop_action_label(target: String) -> String:
	var names := {"printer":"Open Model Forge", "collection":"Open Model Collection", "unified_forgedex":"Open Model Collection", "team":"Open Pre-Print Loadout", "unified_deck":"Open Pre-Print & Decks", "deck":"Edit Fixed Deck Slots", "archive":"Open Card Library", "unified_library":"Open Equipment Cards", "armor":"Open Equipment Cards", "calibration":"Open Upgrade Forge", "unified_upgrades":"Open Upgrade Forge", "shop":"Open Filament Market", "codex":"Open Forgedex", "trade":"Open Guild Trade", "proving":"Open Battle Arena", "trials":"Open Workshop Trials", "local_vs":"Start Local Versus", "yard":"Open Daily Quests"}
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
	# Legacy facade: route straight into the unified creature Forge. There is no
	# visible intermediate close-up or Blueprint Tray state.
	var ids := printer_blueprint_ids()
	if printer_blueprint_selected_id not in ids:
		printer_blueprint_selected_id = str(ids[0]) if not ids.is_empty() else ""
	open_printer(printer_blueprint_selected_id)

func _focus_printer_picker_origin() -> void:
	if screen != "printer" or printer_is_armor or printer_sequence == null or printer_sequence.phase != ArcaneForgeSequence.IDLE: return
	# The outer vertical scroller can retain focus-driven offset from the previous
	# shell. Reset it even in landscape, which has no nested cartridge strip.
	var outer_scroll := find_child("TouchFirstScroll", true, false) as ScrollContainer
	if outer_scroll != null:
		outer_scroll.follow_focus = false
		outer_scroll.scroll_vertical = 0
	var cartridge_scroll := find_child("PrinterBlueprintCartridgeStrip", true, false) as ScrollContainer
	if cartridge_scroll != null:
		cartridge_scroll.follow_focus = false
		cartridge_scroll.scroll_horizontal = 0
	# Keep this synchronous. A one-frame coroutine on Main can resume after its
	# final teardown, while the initial focus and scroll reset already share this
	# freshly-built printer tree.
	var first := find_child("PrinterSelectCinderpaw", true, false) as Button
	if first != null and first.is_visible_in_tree(): first.grab_focus()

func close_printer_picker() -> void:
	# Deprecated facade retained for old callers. The integrated screen uses its
	# normal idle Back action rather than exposing a tray close action.
	printer_picker_open = false
	if screen == "printer" and printer_sequence != null and printer_sequence.phase == ArcaneForgeSequence.IDLE:
		cancel_printer_preview()

func _workshop_stations() -> Array:
	return [
		{"id":"forge","name":"Printer Bench","description":"Review owned blueprints and print Workshop display models with Forge Coins.","actions":[{"label":"Open Model Collection","target":"unified_forgedex"}],"rect":Rect2(0.05,0.48,0.17,0.23)},
		{"id":"maker","name":"Maker Bench","description":"Set a fixed legal deck, choose Pre-Print creatures, browse Equipment Cards, and install Workshop upgrades.","actions":[{"label":"Open Pre-Print & Decks","target":"unified_deck"},{"label":"Open Equipment Cards","target":"unified_library"},{"label":"Open Upgrade Forge","target":"unified_upgrades"}],"rect":Rect2(0.27,0.68,0.25,0.17)},
		{"id":"terminal","name":"Forge Terminal","description":"Browse deterministic offers, track creature records, or open the kid-safe local trade table.","actions":[{"label":"Open Forge Offers","target":"shop"},{"label":"Open Forgedex","target":"codex"},{"label":"Open Trade Table","target":"trade"}],"rect":Rect2(0.76,0.50,0.19,0.23)},
		{"id":"door","name":"Battle Arena","description":"Challenge today’s deterministic training rival or pass the device for a local match.","actions":[{"label":"Start Training","target":"proving"},{"label":"Start Local Versus","target":"local_vs"}],"rect":Rect2(0.41,0.25,0.19,0.33)},
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

func activate_workshop_overview_hotspot(hotspot_id: String) -> void:
	# Kept as a callable seam for keyboard/UI tests. The overview is a direct
	# object map; it never opens legacy station close-ups before routing.
	for hotspot in _workshop_overview_hotspots():
		if str(hotspot.id) != hotspot_id:
			continue
		_run_workshop_station(str(hotspot.target))
		return
	push_error("Unknown workshop overview hotspot: %s" % hotspot_id)

func claim_overview_calibration() -> void:
	# Compatibility entry point for older UI tests. The active v3 dial is the
	# Upgrade Forge; it never grants retired calibration coins.
	navigate_to("calibration")

func _run_workshop_station(id: String) -> void:
	match id:
		"printer": open_printer_picker()
		"collection", "shop", "codex", "team", "deck", "archive", "armor", "settings", "unified_forgedex", "unified_deck", "unified_library", "unified_market", "unified_upgrades": navigate_to(id)
		"proving": navigate_to("proving")
		"trials": navigate_to("trials")
		"local_vs": start_local_vs()
		"trade": local_trade = null; trade_creator_choice = ""; trade_partner_choice = ""; navigate_to("trade")
		"yard", "calibration": navigate_to(id)
		_:
			_toast("%s is unavailable. Your Workshop state is unchanged." % id.replace("_", " ").capitalize())
			screen = "workshop"
			render()

func start_local_vs() -> void:
	# Hot-seat uses the same public v3 snapshot and seat-redacted hands as solo.
	# The rival deck defaults to the active legal deck, making both seats play the
	# same owned-card composition until second-deck selection is authored.
	_launch_unified_mode("local", {}, 20260814)

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
			var preview = _new_support_card_view()
			if preview != null:
				preview.configure(definition, int(GameManager.profile.support_cards.get(str(offer.get("item_id", "")), 0)), "", false, false, false); preview.name = "ShopCard%s" % str(offer.get("item_id", "")).capitalize(); card.add_child(preview)
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
	panel.add_child(label("Daily contract difficulty is fixed by the Guild: Apprentice, Craftsman, and Master. The legacy Training AI setting remains saved for compatibility but is no longer selectable.", 14, Color("9beaff")))
	var return_label := "Back to Title" if settings_return_screen == "title" else "Back to Workshop"
	var return_button := make_button(return_label, _return_from_settings, Color("536c8d"))
	return_button.name = "SettingsReturn"
	return_button.accessibility_name = return_label
	body.add_child(return_button)
	# The shared keyboard-first focus pass targets the first text-scale button.
	# On a short landscape viewport Godot can then retain that button's old scroll
	# offset and hide the Settings heading. Reset only the initial route origin;
	# later keyboard/touch focus still uses the normal ScrollContainer behavior.
	call_deferred("_restore_settings_scroll_origin")

func _return_from_settings() -> void:
	var destination := settings_return_screen if settings_return_screen in ["title", "workshop"] else "workshop"
	screen = destination
	if destination == "workshop":
		workshop_view = workshop_return_view
	render()

func _m3_ensure_deck_draft() -> void:
	if m3_deck_edit_slot_id.is_empty(): m3_deck_edit_slot_id = str(GameManager.profile.get("active_deck_id", "starter-deck"))
	if m3_deck_loaded_slot_id == m3_deck_edit_slot_id: return
	for deck in GameManager.profile.get("decks", []):
		if deck is Dictionary and str(deck.get("id", "")) == m3_deck_edit_slot_id:
			unified_deck_draft = (deck.get("cards", []) as Array).duplicate()
			break
	unified_preprint_draft = (GameManager.profile.get("preprints", []) as Array).duplicate()
	m3_saved_preprint_draft = unified_preprint_draft.duplicate()
	m3_deck_loaded_slot_id = m3_deck_edit_slot_id

func _m3_deck_is_dirty() -> bool:
	var saved: Array = []
	for deck in GameManager.profile.get("decks", []):
		if deck is Dictionary and str(deck.get("id", "")) == m3_deck_edit_slot_id:
			saved = (deck.get("cards", []) as Array).duplicate(); break
	return unified_deck_draft != saved or unified_preprint_draft != m3_saved_preprint_draft

func _m3_change_deck_occurrence(card_id: String, add: bool) -> void:
	if add:
		if unified_deck_draft.count(card_id) < int(GameManager.profile.get("owned_cards", {}).get(card_id, 0)): unified_deck_draft.append(card_id)
	else:
		unified_deck_draft.erase(card_id)
	render()

func _m3_request_deck_slot(slot_id: String) -> void:
	if slot_id == m3_deck_edit_slot_id: return
	if _m3_deck_is_dirty():
		m3_pending_deck_slot_id = slot_id
		render()
		return
	m3_deck_edit_slot_id = slot_id; m3_deck_loaded_slot_id = ""; render()

func _m3_resolve_dirty_deck(choice: String) -> void:
	if choice == "cancel": m3_pending_deck_slot_id = ""; render(); return
	if choice == "save":
		if not GameManager.save_unified_deck_and_preprints(unified_deck_draft, unified_preprint_draft, m3_deck_edit_slot_id):
			_toast("Deck and Pre-Print rack must both be legal before either can be saved.")
			render()
			return
		m3_deck_loaded_slot_id = m3_deck_edit_slot_id
		m3_saved_preprint_draft = unified_preprint_draft.duplicate()
		_toast("Deck and Pre-Print rack saved together.")
	if choice == "discard":
		m3_deck_loaded_slot_id = ""
		m3_saved_preprint_draft = []
	if m3_pending_deck_slot_id == "__back__":
		m3_pending_deck_slot_id = ""
		m3_deck_loaded_slot_id = ""
		navigate_to("workshop")
		return
	m3_deck_edit_slot_id = m3_pending_deck_slot_id
	m3_pending_deck_slot_id = ""
	m3_deck_loaded_slot_id = ""
	render()

func _m3_request_deck_exit() -> void:
	if _m3_deck_is_dirty():
		m3_pending_deck_slot_id = "__back__"
		render()
		return
	navigate_to("workshop")

func _m3_save_deck(should_render := true) -> bool:
	var result := GameManager.save_unified_deck(unified_deck_draft, m3_deck_edit_slot_id)
	if result:
		m3_deck_loaded_slot_id = m3_deck_edit_slot_id
		_toast("%s saved and active." % m3_deck_edit_slot_id.replace("-", " ").capitalize())
	else: _toast(UNIFIED_RULES.deck_reason(GameManager.profile, unified_deck_draft))
	if should_render: render()
	return result

func _m3_add_preprint(card_id: String) -> void:
	var slots := UNIFIED_RULES.preprint_slots(GameManager.profile)
	var card: Dictionary = UNIFIED_RULES.card(card_id)
	if str(card.get("type", "")) != "creature":
		_toast("Select a creature already in this deck for Pre-Print.")
		render()
		return
	if unified_preprint_draft.size() < slots and unified_preprint_draft.count(card_id) < unified_deck_draft.count(card_id):
		unified_preprint_draft.append(card_id)
		_toast("%s placed in the next Pre-Print clamp." % str(card.get("name", card_id)))
	else:
		_toast("That creature has no remaining eligible Pre-Print copy.")
	render()

func _m3_remove_preprint(index: int) -> void:
	if index >= 0 and index < unified_preprint_draft.size(): unified_preprint_draft.remove_at(index)
	render()

func _m3_save_preprints(should_render := true) -> bool:
	var saved := GameManager.save_preprints_v3(unified_preprint_draft)
	_toast("Pre-Print rack saved." if saved else "Pre-Prints must be creature copies in the active legal deck.")
	if saved: m3_saved_preprint_draft = unified_preprint_draft.duplicate()
	if should_render: render()
	return saved

func _m3_prepare_market_once() -> void:
	# Deterministic visual fixtures seed a fully authoritative copied snapshot.  A
	# render must never replace it from wall-clock preparation (which would also
	# turn a browse-only capture into a persistence mutation).
	if bool(get_meta("m3_capture_frozen_market", false)) and not m3_market_snapshot.is_empty(): return
	var key := Time.get_date_string_from_system()
	if not m3_market_snapshot.is_empty() and m3_market_day_key == key: return
	var prepared := GameManager.prepare_market_v3(0, key)
	if not bool(prepared.get("ok", false)):
		_toast(str(prepared.get("error", "Market preparation is unavailable.")))
		return
	m3_market_snapshot = (prepared.get("snapshot", {}) as Dictionary).duplicate(true)
	m3_market_revision = int(prepared.get("revision", GameManager.profile.get("revision", 0)))
	m3_market_day_key = key

func _m3_with_latch(action: Callable) -> void:
	if m3_action_in_flight: return
	m3_action_in_flight = true
	action.call()
	m3_action_in_flight = false

func _m3_request_market_purchase(category: String, id: String, price: int, consequence: String) -> void:
	if m3_action_in_flight: return
	m3_market_confirmation = {"category":category, "id":id, "price":price, "consequence":consequence}
	render()

func _m3_cancel_market_purchase() -> void:
	m3_market_confirmation.clear(); render()

func _m3_confirm_market_purchase() -> void:
	if m3_action_in_flight or m3_market_confirmation.is_empty(): return
	var request := m3_market_confirmation.duplicate(true)
	m3_action_in_flight = true
	render()
	call_deferred("_m3_execute_market_purchase", request)

func _m3_execute_market_purchase(request: Dictionary) -> void:
	var category := str(request.get("category", "")); var id := str(request.get("id", ""))
	var result: Dictionary = {}
	match category:
		"packs": result = GameManager.buy_card_pack(id, "unified_market", {"market_tab":unified_market_tab}, int(request.get("price", -1)))
		"blueprints": result = GameManager.buy_blueprint_v3(id)
		"cards": result = GameManager.buy_market_card_v3(id)
		"upgrades": result = GameManager.buy_workshop_upgrade_v3(id)
		"cosmetics": result = GameManager.buy_cosmetic_v3(id)
		_: result = {"ok":false, "error":"That cabinet drawer is unavailable."}
	if bool(result.get("ok", false)) or bool(result.get("price_changed", false)):
		m3_market_snapshot.clear()
		_toast("Purchase recorded." if bool(result.get("ok", false)) else "Pack price changed. Review the refreshed offer before buying.")
	else: _toast(str(result.get("error", "Purchase could not be recorded.")))
	m3_market_confirmation.clear(); m3_action_in_flight = false
	if bool(result.get("ok", false)) and category == "packs":
		_m3_open_pending_pack("unified_market")
		return
	render()

func _m3_ensure_settings_draft() -> void:
	if m3_settings_draft_initialized: return
	m3_settings_draft = settings().duplicate(true)
	m3_settings_draft_initialized = true

func _m3_set_setting(key: String, value) -> void:
	_m3_ensure_settings_draft(); m3_settings_draft[key] = value; render()

func _m3_adjust_setting(key: String, direction: int) -> void:
	_m3_ensure_settings_draft()
	var levels: Array[int] = AudioSettings.LEVELS
	var index := levels.find(int(m3_settings_draft.get(key, 5000)))
	if index < 0: index = levels.find(5000)
	m3_settings_draft[key] = levels[clampi(index + direction, 0, levels.size() - 1)]
	render()

func _m3_apply_settings() -> void:
	var saved := GameManager.save_settings(m3_settings_draft)
	if saved:
		m3_settings_draft_initialized = false
		_audio_director.configure(settings(), false)
		_toast("Settings applied.")
	else: _toast("Settings could not be saved.")
	render()

func _m3_cancel_settings() -> void:
	m3_settings_draft.clear(); m3_settings_draft_initialized = false; _return_from_settings()

func _m3_request_new_maker_recovery() -> void:
	m3_recovery_new_maker_confirm = true; render()

func _m3_confirm_new_maker_recovery() -> void:
	var result := GameManager.confirm_new_maker_after_recovery()
	if bool(result.get("ok", false)):
		m3_recovery_new_maker_confirm = false; navigate_to("title")
	else: _toast(str(result.get("error", "New Maker could not be created."))); render()

func _m3_acknowledge_backup_recovery() -> void:
	var result := GameManager.acknowledge_backup_recovery()
	if bool(result.get("ok", false)): navigate_to("title")
	else: _toast(str(result.get("error", "Recovered backup could not be promoted."))); render()

func _m3_retry_result() -> void:
	m3_result_state = "idle"; _settle_finished_unified_battle()

func _m3_continue_result() -> void:
	if m3_result_state not in ["committed", "duplicate"] or battle_mode == "local": return
	_leave_unified_battle()

func _restore_settings_scroll_origin() -> void:
	await get_tree().process_frame
	if screen != "settings": return
	var scroll := find_child("TouchFirstScroll", true, false) as ScrollContainer
	if is_instance_valid(scroll): scroll.scroll_vertical = 0

func adjust_audio_setting(key: String, direction: int) -> void:
	var levels: Array[int] = AudioSettings.LEVELS
	var current: int = int(settings().get(key, 0))
	var index := levels.find(current)
	if index < 0: index = levels.find(5000)
	index = clampi(index + direction, 0, levels.size() - 1)
	GameManager.save_settings({key:levels[index]})
	_audio_director.configure(settings(), false)

func open_printer(creature_id: String) -> void:
	var free_starter := str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected" and creature_id == str(GameManager.profile.get("onboarding", {}).get("starter_id", ""))
	if not creature_id.is_empty() and (Catalog.creature(creature_id).is_empty() or (not UNIFIED_RULES.has_printable_blueprint(GameManager.profile, creature_id) and not free_starter)):
		_toast("That blueprint is not learned yet.")
		return
	# Back may leave an accepted presentation for its recorded caller. Re-entering
	# must surface that exact visual job rather than allocating a second sequence.
	if printer_sequence != null and printer_sequence.phase in [ArcaneForgeSequence.PRINTING, ArcaneForgeSequence.RAW_COMPLETE, ArcaneForgeSequence.RAW_HOLD, ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.DEPARTING]:
		if creature_id != printer_creature_id:
			_toast("A Forge presentation is already active. Resume or finish it first.")
			return
		if toast.begins_with("PRINT PAUSED"):
			_toast("")
		screen = "printer"
		render()
		return
	printer_creature_id = creature_id
	printer_blueprint_selected_id = creature_id
	printer_armor_id = ""
	printer_is_armor = false
	printer_is_core = false
	var definition := Catalog.creature(creature_id)
	printer_price = 0 if free_starter else (int(UNIFIED_RULES.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), 20)) if not definition.is_empty() else 0)
	printer_sequence = ArcaneForgeSequence.create(bool(settings().get("reduced_motion", false)))
	printer_tick_accumulator = 0.0
	printer_presentation_seconds = 0.0
	printer_failure = ""
	# Re-selecting from an existing Forge (for tests or future keyboard routing)
	# must preserve its original caller instead of making Back a no-op.
	if screen != "printer":
		printer_return_screen = screen
	# The first-print review resolves back to the Workshop overview after a starter
	# has been selected. A Title resume remains explicitly title-owned.
	# Only the true starter-confirmation route is workshop-owned.  A free preview
	# opened from Archive/Collection remains caller-owned for Back parity.
	if free_starter and printer_return_screen == "onboarding":
		printer_return_screen = "workshop"
		workshop_return_view = "overview"
	# Creature Forge entry from any Workshop surface always returns to the direct
	# overview. The old printer close-up is no longer part of this route.
	if screen == "workshop": workshop_return_view = "overview"
	printer_picker_open = false
	screen = "printer"
	render()
	call_deferred("_focus_printer_picker_origin")

func render_printer() -> void:
	# Compatibility facade for direct callers/tests; every Forge entry delegates
	# to the cached physical station.
	render_feedback_printer()

func _refresh_printer_presentation() -> void:
	if screen != "printer" or printer_sequence == null: return
	var physical = _physical_forge_component()
	if physical != null:
		physical.refresh_presentation(self)

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
	var is_free_starter := not printer_is_armor and str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected" and printer_creature_id == str(GameManager.profile.get("onboarding", {}).get("starter_id", ""))
	var success := false
	if is_free_starter: success = GameManager.print_selected_starter()
	elif printer_is_armor: success = GameManager.print_core(printer_armor_id) if printer_is_core else GameManager.print_suit(printer_armor_id)
	else: success = bool(GameManager.print_workshop_model_v3(printer_creature_id, "forge-animation-%d" % Time.get_ticks_msec()).get("ok", false))
	if not success: printer_failure = "The blueprint, coins, or inventory no longer passed validation."
	printer_sequence.resolve_commit(success)

func skip_printer() -> void:
	if printer_sequence == null or not printer_sequence.skip(): return
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE: _commit_printer_once()
	render()

func cancel_printer_preview() -> void:
	if printer_sequence != null and printer_sequence.phase != ArcaneForgeSequence.IDLE:
		_dispatch_forge_back()
		return
	_return_from_forge_idle()

func return_to_printer_station() -> void:
	if printer_return_screen == "armor":
		navigate_to("armor")
		return
	if printer_return_screen == "workshop":
		screen = "workshop"
		workshop_view = "overview"
		workshop_selected = "printer"
		workshop_drawer_object = ""
		render()
		return
	if printer_return_screen == "title":
		screen = "title"
		render()
		return
	if printer_return_screen == "onboarding":
		screen = "onboarding"
		render()
		return
	navigate_to("collection")

func _open_next_starter_pack() -> void:
	var return_route := "workshop" if screen in ["workshop", "printer"] else "unified_library"
	var result := GameManager.claim_next_starter_pack(return_route, {"caller":return_route})
	if not bool(result.get("ok", false)):
		_toast(str(result.get("error", "No starter pack is waiting.")))
		render()
		return
	# The reward opens inside the new archive, not in the market. Pending cards
	# are committed before this presentation route, so reload resumes safely.
	printer_sequence = null
	# Each receipt has a receipt-keyed sidecar, so never inherit the previous
	# page or inspected card into the next Founder receipt.
	_m3_open_pending_pack(return_route)
	_toast("Starter pack %d / 3" % int(result.get("payload", {}).get("starter_opened", 0)))
	render()

func return_to_printer_picker() -> void:
	if printer_return_screen == "armor":
		open_armor_printer(printer_armor_id)
		return
	# Keep creature printing in the same integrated Forge. This is presentation
	# state only and deliberately does not touch profile, coins, or revision.
	var ids := printer_blueprint_ids()
	if printer_blueprint_selected_id not in ids:
		printer_blueprint_selected_id = str(ids[0]) if not ids.is_empty() else ""
	printer_creature_id = printer_blueprint_selected_id
	var definition := Catalog.creature(printer_creature_id)
	printer_price = int(UNIFIED_RULES.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), 20)) if not definition.is_empty() else 0
	printer_sequence = ArcaneForgeSequence.create(bool(settings().get("reduced_motion", false)))
	printer_tick_accumulator = 0.0
	printer_presentation_seconds = 0.0
	printer_failure = ""
	screen = "printer"
	render()
	call_deferred("_focus_printer_picker_origin")

func render_collection() -> void:
	# Legacy callers can still name this screen, but v3 profiles have no printed
	# creature-instance array. Route them to the model/blueprint collection.
	if not GameManager.profile.has("creatures"):
		screen = "unified_forgedex"
		render()
		return
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
		var roster = _optional_script(TIERED_ARMOR_ROSTER_PATH, "Armor preview")
		if roster != null and roster.has_master(str(creature.get("creature_id", ""))) and not str(creature.get("suit_instance_id", "")).is_empty():
			var loadout := EquipmentRules.suit_loadout(GameManager.profile, instance_id)
			var preview_script = _optional_script(TIERED_ARMOR_PREVIEW_PATH, "Armor preview")
			if preview_script != null:
				var portrait = preview_script.new(); portrait.custom_minimum_size = Vector2(160, 160); portrait.configure_creature(str(creature.get("creature_id", ""))); portrait.configure_tier(str(loadout.get("tier_id", "standard"))); portrait.configure_core(str(loadout.get("core_id", ""))); intro.add_child(portrait)
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
	var workbench = _optional_script(EQUIPMENT_WORKBENCH_VIEW_PATH, "Equipment Workbench")
	if workbench == null:
		panel.add_child(label("The Equipment Workbench could not load. Return to the Workshop and try again; your profile has not changed.", 15, Color("ffcfbf")))
	else:
		panel.add_child(workbench.build(GameManager.profile, equipment_selected_creature_id, equipment_mode, equipment_selected_id, not is_portrait_layout(), {"select_creature":equipment_select_creature,"select_mode":equipment_select_mode,"select_item":equipment_select_item,"suit_action":equipment_suit_action,"core_action":equipment_core_action,"fit_suit":equipment_fit_suit,"remove_suit":equipment_remove_suit,"remove_core":equipment_remove_core,"socket_core":equipment_socket_core}, bool(settings().get("high_contrast", false))))
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

func centered_card_gallery(host: Container, gallery_name: String, columns: int) -> GridContainer:
	# Card fronts deliberately retain their authored silhouette and native spacing.
	# Give a narrow portrait gallery a full-width host, then center the natural
	# two-column bounds inside it instead of stretching cards into dead space.
	var gallery_host := CenterContainer.new()
	gallery_host.name = gallery_name + "Host"
	gallery_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery_host.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	host.add_child(gallery_host)
	var cards := GridContainer.new()
	cards.name = gallery_name
	cards.columns = columns
	cards.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cards.add_theme_constant_override("h_separation", 8)
	cards.add_theme_constant_override("v_separation", 8)
	gallery_host.add_child(cards)
	return cards

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
		var selected_tray := make_panel(Color("10273ad8"), Color("ffd36c")); selected_tray.get_parent().add_theme_stylebox_override("panel", inset_style(Color("10273ad8"), Color("ffd36c"))); panel.add_child(selected_tray.get_parent()); selected_tray.name = "DeckSelectedCardTray"
		var selected_owned: int = int(GameManager.profile.support_cards.get(deck_selected_card_id, 0)); var selected_copies: int = deck_draft.count(deck_selected_card_id)
		selected_tray.add_child(label("Selected: %s" % str(selected.name), 19, Color("fff0a1")))
		selected_tray.add_child(label("Owned: %d | Draft copies: %d / %d | %d Filament" % [selected_owned, selected_copies, selected_owned, int(selected.cost)], 14, Color("9beaff")))
		var card_presenter = _optional_script(SUPPORT_CARD_PRESENTER_PATH, "Support card details")
		if card_presenter != null:
			selected_tray.add_child(label(card_presenter.effect_text(selected) + "\nTarget: " + card_presenter.target_text(selected), 14, Color("dce8f4")))
		var selected_actions := HBoxContainer.new(); selected_tray.add_child(selected_actions)
		var selected_remove := make_button("Remove selected", change_deck_draft.bind(deck_selected_card_id, false), Color("536c8d")); selected_remove.name = "DeckSelectedRemove"; selected_remove.disabled = selected_copies <= 0; selected_actions.add_child(selected_remove)
		var selected_add := make_button("Add selected (%d/%d)" % [selected_copies, selected_owned], change_deck_draft.bind(deck_selected_card_id, true), Color("2f93a8")); selected_add.name = "DeckSelectedAdd"; selected_add.disabled = deck_draft.size() >= 15 or selected_copies >= selected_owned; selected_actions.add_child(selected_add)
	var cards := centered_card_gallery(panel, "DeckCardGallery", 2 if is_portrait_layout() else 4)
	for card in Catalog.SUPPORT_CARDS:
		var card_id := str(card.id); var owned: int = int(GameManager.profile.support_cards.get(card_id, 0))
		if owned <= 0: continue
		var view = _new_support_card_view()
		if view != null:
			view.configure(card, owned, ""); view.name = "DeckCard%s" % card_id.capitalize(); view.pressed.connect(select_deck_card.bind(card_id)); cards.add_child(view)
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
	var edit_deck := make_button("Edit Deck", navigate_to.bind("deck"), Color("a86b2e"))
	edit_deck.name = "ArchiveEditDeck"
	panel.add_child(edit_deck)
	var filters := HBoxContainer.new(); panel.add_child(filters)
	var all_filter := make_button("All cards", func(): card_archive_owned_only = false; render(), Color("2f93a8") if not card_archive_owned_only else Color("536c8d")); all_filter.name = "ArchiveFilterAll"; filters.add_child(all_filter)
	var owned_filter := make_button("Owned only", func(): card_archive_owned_only = true; render(), Color("2f93a8") if card_archive_owned_only else Color("536c8d")); owned_filter.name = "ArchiveFilterOwned"; filters.add_child(owned_filter)
	var cards := centered_card_gallery(panel, "CardArchiveGallery", 2 if is_portrait_layout() else 4)
	for card in Catalog.SUPPORT_CARDS:
		var owned := int(GameManager.profile.support_cards.get(str(card.id), 0))
		if card_archive_owned_only and owned <= 0: continue
		var view = _new_support_card_view()
		if view != null:
			view.configure(card, owned); view.name = "ArchiveCard%s" % str(card.id).capitalize(); view.pressed.connect(show_card_archive_detail.bind(card)); cards.add_child(view)
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
	var card_presenter = _optional_script(SUPPORT_CARD_PRESENTER_PATH, "Support card details")
	if card_presenter != null:
		panel.add_child(label(card_presenter.effect_text(card) + "\nTarget: " + card_presenter.target_text(card) + "\nOwned: %d" % int(GameManager.profile.support_cards.get(str(card.id), 0)), 15, Color("dce8f4")))

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
		intro.add_child(label("%s - %s | owned %d" % [str(core.name), str(ArmorCoreDefinitions.definition(core_id).get("effect", "")), core_owned], 14, Color("dce8f4")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_proving_door() -> void:
	var panel := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(panel.get_parent())
	panel.add_child(label("Battle Arena Hub", 25, Color("ffd36c")))
	panel.add_child(label("Choose a frozen daily contract, a fixed Workshop Trial ladder, or a private local match.", 15, Color("dce8f4")))
	panel.add_child(label("Daily Training Contracts", 20, Color("8deaff")))
	var contracts := GameManager.daily_training_contracts()
	if contracts.is_empty():
		panel.add_child(label("Daily contracts are prepared when the Battle Arena opens. Return to the workshop and reopen the Battle Arena if needed.", 14, Color("fff0a1")))
	for contract in contracts:
		var claimed: bool = str(contract.get("id", "")) in GameManager.profile.get("daily_training", {}).get("claimed_ids", [])
		var contract_panel := make_panel(Color("12314be8"), Color("70dcea") if not claimed else Color("588d73")); panel.add_child(contract_panel.get_parent())
		var team_names: Array[String] = []
		for entry in contract.get("team", []):
			var unit := Catalog.creature(str(entry.get("creature_id", ""))); team_names.append(str(unit.get("name", "Print")))
		contract_panel.add_child(label("%s - %s%s" % [str(contract.get("name", "Contract")), str(contract.get("difficulty", "Apprentice")), " (Practice)" if claimed else ""], 18, Color("a9ecff") if not claimed else Color("a8e3a5")))
		contract_panel.add_child(_contract_portrait_strip(contract.get("team", [])))
		var tactics := str(contract.get("tactics", ""))
		var tactics_text := " | %s tactics" % tactics.capitalize() if not tactics.is_empty() else ""
		contract_panel.add_child(label("Rivals: %s | %s deck%s | prepared %d / 400 filament | rating %d vs %d" % [", ".join(team_names), str(contract.get("deck_role", "balanced")).capitalize(), tactics_text, int(contract.get("rival_starting_filament", 200)), int(contract.get("rating", 0)), int(contract.get("player_rating", 0))], 13, Color("dce8f4")))
		var target_note := "Rated target met" if bool(contract.get("within_target", false)) else "Closest legal rating"
		contract_panel.add_child(label("Field: %s | %s | %s" % [_contract_loadout_text(contract.get("team", [])), str(contract.get("tag", "Daily")), target_note], 12, Color("b9d3e8")))
		if str(contract.get("equipment_reason", "policy_primary")) != "policy_primary": contract_panel.add_child(label("Rival plan: %s." % str(contract.get("equipment_reason", "")).replace("_", " "), 11, Color("fff0a1")))
		var reward: Dictionary = contract.get("reward", {})
		contract_panel.add_child(label("Reward claimed; replays are practice only." if claimed else "First victory: %d Forge Coins, %d XP." % [int(reward.get("coins", 0)), int(reward.get("xp", 0))], 12, Color("fff0a1")))
		var launch := make_button("Practice %s" % str(contract.get("name", "Contract")) if claimed else "Accept %s" % str(contract.get("name", "Contract")), start_battle.bind(str(contract.get("id", ""))), Color("588d73") if claimed else Color("2f93a8")); launch.name = "DailyContract%s" % str(contract.get("id", "")); contract_panel.add_child(launch)
	panel.add_child(label("Workshop Trials", 20, Color("ffd36c")))
	var campaign: Dictionary = GameManager.profile.get("solo_campaign", {})
	panel.add_child(label("Five authored tiers, 20 fixed encounters. Tier %d is currently available; first clears grant one-time Forge Coins plus Spool and Season XP." % int(campaign.get("unlocked_tier", 1)), 14, Color("dce8f4")))
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
	var edit_team := make_button("Open Pre-Print & Decks", navigate_to.bind("unified_deck"), Color("526e93"))
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
			for entry in encounter.get("team", []):
				var creature_id := str(entry.get("creature_id", "")) if entry is Dictionary else str(entry)
				rival_names.append(str(Catalog.creature(creature_id).get("name", creature_id)))
			var best_turns: int = int(GameManager.profile.get("solo_campaign", {}).get("best_turn_counts", {}).get(encounter_id, 0))
			var status_text := ("Complete - best %d turns" % best_turns) if completed and best_turns > 0 else ("Complete" if completed else ("Ready" if unlocked else "Locked - clear the prior encounter"))
			card.add_child(label("%s%s - %s" % ["Boss: " if bool(encounter.get("boss", false)) else "", str(encounter.get("name", "Encounter")), status_text], 16, Color("a8e3a5") if completed else (Color("dce8f4") if unlocked else Color("8492a1"))))
			card.add_child(label("Rival: %s | %s AI | %s deck | 200 / 400 filament" % [", ".join(rival_names), str(encounter.get("ai", "Apprentice")), str(encounter.get("deck_role", "Balanced"))], 13, Color("b9d3e8")))
			card.add_child(label("First clear: %d Forge Coins and %d Spool/Season XP." % [int(reward.get("coins", 0)), int(reward.get("xp", 0))], 13, Color("fff0a1")))
			var start := make_button("Replay %s" % str(encounter.get("name", "Trial")) if completed else "Start %s" % str(encounter.get("name", "Trial")), start_trial.bind(encounter_id), Color("588d73") if completed else Color("a86b2e"))
			start.name = "TrialStart%s" % encounter_id
			start.disabled = not unlocked
			card.add_child(start)
	body.add_child(make_button("Back to Battle Arena", navigate_to.bind("proving"), Color("536c8d")))

func _trial_lineup_preview() -> Dictionary:
	# Preview and launch intentionally use the same factory contract: no separate
	# UI-only normalization can advertise a lineup BattleState will not receive.
	var fallback := SoloBattleFactory.preview(GameManager.profile)
	var temporary: Array = fallback.get("team", [])
	if not temporary.is_empty():
		if bool(fallback.get("temporary_repair", false)):
			return {"text":"Trial lineup: available catalog prints will be used temporarily: %s. Save a Pre-Print deck loadout after the match." % _trial_lineup_names(temporary), "temporary":true}
		return {"text":"Trial lineup: %s" % _trial_lineup_names(temporary), "temporary":false}
	return {"text":"Trial lineup: No catalog-valid owned print is ready. Add creature cards to a fixed deck, then choose Pre-Prints.", "temporary":true}

func _trial_lineup_names(lineup: Array) -> String:
	var names: Array[String] = []
	for entry in lineup:
		var creature_id := str(entry.get("creature_id", "")) if entry is Dictionary else str(entry)
		var definition := Catalog.creature(creature_id)
		if not definition.is_empty(): names.append(str(definition.get("name", creature_id)))
	return ", ".join(names)

func _contract_loadout_text(lineup: Array) -> String:
	var pieces: Array[String] = []
	for entry in lineup:
		if not entry is Dictionary: continue
		var creature_id := str(entry.get("creature_id", ""))
		var creature_name := str(Catalog.creature(creature_id).get("name", creature_id.capitalize()))
		pieces.append(creature_name)
	return ", ".join(pieces) if not pieces.is_empty() else "No field creatures"

func _daily_contract(contract_id: String) -> Dictionary:
	for raw in GameManager.daily_training_contracts():
		if str(raw.get("id", "")) == contract_id: return raw
	return {}

func _contract_portrait_strip(lineup: Array) -> Control:
	var strip := HBoxContainer.new(); strip.name = "DailyContractPortraits"; strip.add_theme_constant_override("separation", 8)
	for entry in lineup:
		if not entry is Dictionary: continue
		var creature_id := str(entry.get("creature_id", ""))
		var frame := TextureRect.new(); frame.custom_minimum_size = Vector2(64, 64)
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var portrait := AtlasTexture.new()
		portrait.atlas = CreatureSpriteCache.texture_for_creature(creature_id)
		portrait.region = CreatureSpriteCache.safe_source_region(0)
		frame.texture = portrait
		frame.tooltip_text = "%s - %s" % [str(Catalog.creature(creature_id).get("name", creature_id)), _contract_loadout_text([entry])]
		strip.add_child(frame)
	return strip

func start_trial(encounter_id: String) -> void:
	_launch_unified_mode("trial", {"encounter_id":encounter_id}, _trial_seed(encounter_id))

func start_battle(contract_id := "") -> void:
	_launch_unified_mode("daily", {"contract_id":contract_id,"day_key":shop_day_key}, _training_seed(shop_day_key + contract_id))

func _training_seed(day_key: String) -> int:
	var seed := 0
	for byte in day_key.to_utf8_buffer(): seed = (seed * 31 + int(byte)) % 2147483647
	return seed

func _trial_seed(encounter_id: String) -> int:
	var seed := 97
	for byte in encounter_id.to_utf8_buffer(): seed = (seed * 31 + int(byte)) % 2147483647
	return seed

## Public launch bridge for the deterministic card-battle modes.  This is kept
## beside the existing Trial/Daily entry points so workshop buttons, tests, and
## future Foundry-styled cards all share GameManager's launch snapshot rather
## than instantiating the retired prototype screen.
func start_mode(mode: String) -> void:
	_launch_unified_mode(mode, {}, 43 + mode.length())

func _launch_unified_mode(mode: String, opponent_setup: Dictionary, seed: int) -> void:
	battle = null
	battle_settlement_context.clear()
	battle_settlement_finished = false
	var setup: Dictionary = GameManager.create_unified_battle(mode, opponent_setup, seed)
	if not bool(setup.get("ok", false)):
		_toast(str(setup.get("error", "Unable to launch this battle.")))
		return
	battle = setup.get("battle", null)
	if battle == null:
		_toast("The battle snapshot could not be created.")
		return
	battle_mode = str(setup.get("mode", mode))
	unified_battle_coordinator.configure(battle, 0)
	battle_settlement_context = setup.get("settlement_context", {}).duplicate(true) if setup.get("settlement_context", {}) is Dictionary else {}
	unified_hand_page = 0
	unified_selected_card_id = ""
	unified_selected_slot = -2
	unified_selected_target = -2
	unified_attack_slot = -1
	unified_attack_target = -2
	unified_ai_pending = false
	unified_ai_steps = 0
	unified_local_handoff = battle_mode == "local"
	unified_arrival_presented.clear()
	_reset_unified_battle_presentation()
	if screen == "workshop": workshop_return_view = workshop_view
	screen = "unified_battle"
	# A seeded non-local battle can legitimately give the rival the first turn.
	# Compose the public board first, then let the AI resolve so its private hand is
	# never exposed or left waiting for player input.
	render()
	_queue_unified_ai_if_needed()

func _queue_unified_ai_if_needed() -> void:
	if battle_mode == "local" or battle == null or battle.finished or int(battle.active_seat) != 1:
		return
	unified_ai_pending = true
	unified_ai_steps = 0
	# Defer exactly one checked rival action. The generation is captured here so a
	# newly launched match or later Run Cycle can never receive this callback.
	call_deferred("_run_unified_ai", unified_battle_coordinator.generation)

func _complete_unified_cycle_handoff() -> void:
	if battle == null or battle.finished:
		unified_ai_pending = false
		unified_ai_steps = 0
		return
	if battle_mode == "local":
		unified_ai_pending = false
		unified_ai_steps = 0
		unified_local_handoff = true
		return
	if int(battle.active_seat) == 1:
		_queue_unified_ai_if_needed()
	else:
		unified_ai_pending = false
		unified_ai_steps = 0

func _unified_side_panel(title: String, state: Dictionary, color: Color) -> Control:
	var panel := make_panel(Color("132b3be8"), color)
	panel.name = "Unified%sField" % title.capitalize()
	# The battle surface has no global scroll. Keep the public board legible but
	# compact in both orientations so the hand's selected-card action stays in the
	# first interaction region on narrow screens.
	var compact := true
	panel.add_child(label(title + (" printer" if compact else ""), 14 if compact else 18, color))
	var printer: Dictionary = state.get("printer", {})
	panel.add_child(label(("%d/%d HP · %d/%d filament" if compact else "3D PRINTER  ·  %d / %d HP  ·  filament %d/%d") % [int(printer.get("hp", 0)), int(printer.get("max_hp", 2000)), int(state.get("filament", 0)), int(state.get("filament_max", 400))], 12 if compact else 14, Color("e6dfd0")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var narrow := is_portrait_layout()
	for slot in 3:
		var unit = state.get("slots", [])[slot]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(72 if narrow else 112, 42 if narrow else 50)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", inset_style(Color("102735"), color))
		var text := "Slot %d\nOpen" % (slot + 1)
		if unit != null:
			var equipment: Dictionary = unit.get("equipment", {}) if unit.get("equipment", {}) is Dictionary else {}
			var gear: Array[String] = []
			for key in ["armor", "gem"]:
				var attached: Dictionary = equipment.get(key, {}) if equipment.get(key, {}) is Dictionary else {}
				if not attached.is_empty(): gear.append(str(attached.get("name", key.capitalize())))
			text = "%s · %s\n%d HP%s%s" % [str(unit.get("name", "Print")), str(unit.get("mode", "defense")).capitalize(), int(unit.get("hp", 0)), " · ready" if bool(unit.get("ready", false)) else "", (" · " + "/".join(gear)) if not gear.is_empty() else ""]
		var caption := label(text, 10 if narrow else (11 if compact else 13), Color("e6dfd0"))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.add_child(caption)
		row.add_child(card)
		if unit != null and bool(unit.get("arriving", false)):
			card.name = "UnifiedArrival_%s_%d" % [title, slot]
			call_deferred("_present_unified_arrival", card, "%d:%s:%d:%s" % [int(battle.seed), title, slot, str(unit.get("card_id", "print"))])
	var queue: Array = state.get("queue", [])
	var queue_parts: Array[String] = []
	for job in queue: queue_parts.append("%s · %d turns" % [str(job.get("card_id", "print")), int(job.get("remaining", 0))])
	panel.add_child(label("Queue: " + ("empty" if queue_parts.is_empty() else " | ".join(queue_parts)), 13, Color("fff0a1")))
	if bool(state.get("filament_ring_active", false)):
		panel.add_child(label("Filament Ring active · +20 filament during Collect", 12, Color("ffd36c")))
	var trap: Dictionary = state.get("trap", {}) if state.get("trap", {}) is Dictionary else {}
	panel.add_child(label("Trap zone: " + ("set" if not trap.is_empty() else "empty"), 12, Color("e6dfd0")))
	if not state.get("staging", []).is_empty() or not state.get("holding", []).is_empty(): panel.add_child(label("Staging %d · Holding %d · Graveyard %d" % [(state.get("staging", []) as Array).size(), (state.get("holding", []) as Array).size(), (state.get("graveyard", []) as Array).size()], 12, Color("e6dfd0")))
	return panel.get_parent()

func _present_unified_arrival(card: Control, arrival_key: String) -> void:
	# Presentation-only event consumption: neither the authoritative state nor a
	# turn flag changes here. A rebuild therefore cannot replay the same walk-on.
	if unified_arrival_presented.has(arrival_key) or not is_instance_valid(card): return
	unified_arrival_presented[arrival_key] = true
	if bool(settings().get("reduced_motion", false)): return
	var destination := card.position
	card.position = destination + Vector2(-72.0, 12.0)
	card.modulate.a = 0.15
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", destination, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.32)

func _unified_cards_page(cards: Array, on_select: Callable) -> Control:
	var column := VBoxContainer.new()
	var per_page := 2 if is_portrait_layout() else 4
	var pages := maxi(1, int(ceil(float(cards.size()) / float(per_page))))
	unified_page = clampi(unified_page, 0, pages - 1)
	var grid := GridContainer.new()
	grid.name = "UnifiedFoundryCardGrid"
	grid.columns = 2 if is_portrait_layout() else 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	for definition in cards.slice(unified_page * per_page, mini(cards.size(), (unified_page + 1) * per_page)):
		var card: Dictionary = definition
		var id := str(card.get("id", ""))
		var copies := int(GameManager.profile.get("owned_cards", {}).get(id, 0))
		var market_price := int(card.get("market_price", -1))
		var status := "x%d in deck" % int(card.get("deck_count", 0)) if card.has("deck_count") else ""
		var view := UNIFIED_CARD_VIEW.new()
		view.name = "UnifiedCardView%s" % id.capitalize()
		view.configure(card, copies, market_price, status, true, true)
		view.pressed.connect(on_select.bind(id))
		grid.add_child(view)
	var pager := HBoxContainer.new()
	pager.name = "UnifiedFoundryPager"
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_child(pager)
	var previous := make_button("Previous", func(): unified_page = posmod(unified_page - 1, pages); render(), Color("536c8d"))
	previous.custom_minimum_size = Vector2(48, 44)
	previous.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	previous.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(previous)
	pager.add_child(_compact_pager_label("%d / %d" % [unified_page + 1, pages]))
	var next := make_button("Next", func(): unified_page = posmod(unified_page + 1, pages); render(), Color("536c8d"))
	next.custom_minimum_size = Vector2(48, 44)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(next)
	return column

func _unified_card_thumbnail(card: Dictionary) -> Texture2D:
	return UNIFIED_CARD_VIEW.art_for_definition(card)

func _unified_battle_background_path() -> String:
	var arena := "daily_arena"
	if battle_mode.begins_with("trial_"): arena = battle_mode.trim_prefix("trial_")
	elif battle_mode == "local": arena = "element_bench"
	return "res://assets/ui/battle_backgrounds/%s_%s_v1.png" % [arena, "portrait" if is_portrait_layout() else "landscape"]

func _creature_idle_atlas(creature_id: String) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = CreatureSpriteCache.texture_for_creature(creature_id)
	atlas.region = CreatureSpriteCache.safe_source_region(0)
	return atlas

func _render_unified_inspector() -> void:
	if unified_inspector_id.is_empty(): return
	var card := UNIFIED_RULES.card(unified_inspector_id)
	if card.is_empty(): return
	var modal := ColorRect.new(); modal.name = "UnifiedCardInspector"; modal.color = Color("07111bf0"); modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal.mouse_filter = Control.MOUSE_FILTER_STOP; modal.focus_mode = Control.FOCUS_ALL; modal.accessibility_name = "Card inspector"; add_child(modal)
	var center := CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal.add_child(center)
	var shell := PanelContainer.new(); shell.custom_minimum_size = Vector2(minf(760, size.x - 28), minf(620, size.y - 28)); shell.focus_mode = Control.FOCUS_ALL; shell.accessibility_name = "Card inspector content"; shell.add_theme_stylebox_override("panel", panel_style(Color("102940f8"), Color("8deaff"))); center.add_child(shell)
	var content := VBoxContainer.new(); content.add_theme_constant_override("separation", 10); shell.add_child(content)
	content.add_child(label(str(card.get("name", unified_inspector_id)), 26, Color("ffd36c")))
	var thumbnail := _unified_card_thumbnail(card)
	if thumbnail != null:
		var art := TextureRect.new(); art.texture = thumbnail; art.custom_minimum_size = Vector2(270, 250); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; content.add_child(art)
	var tabs := HBoxContainer.new(); content.add_child(tabs)
	for tab in ["card", "stats"]:
		tabs.add_child(make_button(tab.capitalize(), func(): unified_inspector_tab = tab; render(), Color("588d73") if tab == unified_inspector_tab else Color("536c8d")))
	if unified_inspector_tab == "card":
		content.add_child(label("Card · %s · %s · %d filament" % [str(card.get("type", "card")).capitalize(), str(card.get("rarity", "common")).capitalize(), int(card.get("cost", 0))], 16, Color("e6dfd0")))
	elif unified_inspector_tab == "stats":
		if str(card.get("type", "")) == "creature":
			content.add_child(label("HP %d · BEND %d · PRINT %d" % [int(card.get("hp", 0)), int(card.get("bend", 0)), int(card.get("print_ticks", 0))], 16, Color("fff0a1")))
		else:
			content.add_child(label("Cost %d filament · %s" % [int(card.get("cost", 0)), str(card.get("effect", card.get("type", "Support"))).replace("_", " ").capitalize()], 16, Color("fff0a1")))
	var close := make_button("Close", func(): unified_inspector_id = ""; render(), Color("536c8d"))
	content.add_child(close)
	call_deferred("_deferred_focus_if_ready", close.get_instance_id())

func _render_unified_forgedex_page(host: Container) -> void:
	var creatures: Array = []
	for definition in UNIFIED_RULES.all_cards():
		if str(definition.get("type", "")) == "creature": creatures.append(definition)
	var per_page := 2 if is_portrait_layout() else 4
	var pages := maxi(1, int(ceil(float(creatures.size()) / float(per_page))))
	unified_codex_page = clampi(unified_codex_page, 0, pages - 1)
	host.add_child(label("Creature blueprints · %d / %d owned" % [GameManager.profile.get("owned_blueprints", {}).size(), creatures.size()], 15, Color("dce8f4")))
	var grid := GridContainer.new()
	grid.name = "UnifiedForgedexGrid"
	grid.columns = 2 if is_portrait_layout() else 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	host.add_child(grid)
	for definition in creatures.slice(unified_codex_page * per_page, mini(creatures.size(), (unified_codex_page + 1) * per_page)):
		var creature_id := str(definition.get("id", ""))
		var known: bool = UNIFIED_RULES.has_printable_blueprint(GameManager.profile, creature_id)
		var printed := 0
		for model in GameManager.profile.get("printed_models", {}).values():
			if model is Dictionary and str(model.get("blueprint_id", "")) == creature_id: printed += 1
		var status := ("Blueprint" if known else "Not owned") + " · Printed %d" % printed
		var view := UNIFIED_CARD_VIEW.new()
		view.name = "UnifiedForgedexCard%s" % creature_id.capitalize()
		view.configure(definition, int(GameManager.profile.get("owned_cards", {}).get(creature_id, 0)), -1, status, true, known, not known)
		if known: view.pressed.connect(func(): unified_inspector_id = creature_id; unified_inspector_tab = "stats"; render())
		grid.add_child(view)
		if known:
			grid.add_child(make_button("Workshop print · %d FC" % int(UNIFIED_RULES.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), 20)), func(): var result = GameManager.print_workshop_model_v3(creature_id); _toast("Model printed." if bool(result.get("ok", false)) else str(result.get("error", "Print unavailable."))); render(), Color("a86b2e")))
	var pager := HBoxContainer.new()
	pager.name = "UnifiedForgedexPager"
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.add_child(pager)
	var previous := make_button("Previous", func(): unified_codex_page = posmod(unified_codex_page - 1, pages); render(), Color("536c8d"))
	previous.custom_minimum_size = Vector2(48, 44)
	previous.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	previous.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(previous)
	pager.add_child(_compact_pager_label("%d / %d" % [unified_codex_page + 1, pages]))
	var next := make_button("Next", func(): unified_codex_page = posmod(unified_codex_page + 1, pages); render(), Color("536c8d"))
	next.custom_minimum_size = Vector2(48, 44)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(next)
	host.add_child(label("Equipment Cards are stored with your battle card collection.", 14, Color("b9d3e8")))
	host.add_child(make_button("Open Equipment Cards", navigate_to.bind("archive"), Color("526e93")))

func render_unified_foundry_surface(host: Container) -> void:
	var title_map := {"unified_market":"Foundry Market", "unified_library":"Blueprint Archive · Collection", "unified_deck":"Blueprint Archive · Deck Builder", "unified_upgrades":"Printer Upgrade Grid", "unified_forgedex":"Forgedex"}
	host.add_child(label(str(title_map.get(screen, "Foundry")), 25, Color("ffd36c")))
	# Direct Foundry captures can intentionally mount this surface without the
	# shell; retain a data-complete fallback rather than hiding player progress.
	if find_child("WorkshopHud", true, false) == null:
		var foundry_level := int(GameManager.profile.get("spool_level", 1))
		var foundry_hud := label("Spool Level %d · XP %d / %d · %d Forge Coins" % [foundry_level, int(GameManager.profile.get("spool_xp", 0)), foundry_level * 100, int(GameManager.profile.get("forge_coins", 0))], 14, Color("9beaff"))
		foundry_hud.name = "FoundryHudProgress"
		host.add_child(foundry_hud)
	if screen in ["unified_library", "unified_deck"]:
		var archive_book := PanelContainer.new()
		archive_book.name = "ArchiveBookShell"
		archive_book.custom_minimum_size = Vector2(0, 52)
		archive_book.add_theme_stylebox_override("panel", panel_style(Color("17384ae8"), Color("6bd6ed")))
		host.add_child(archive_book)
		var archive_tabs := HBoxContainer.new(); archive_tabs.name = "ArchiveBookTabs"; archive_tabs.add_theme_constant_override("separation", 8); archive_book.add_child(archive_tabs)
		archive_tabs.add_child(make_button("Collection", navigate_to.bind("archive"), Color("588d73") if screen == "unified_library" else Color("526e93")))
		archive_tabs.add_child(make_button("Deck Builder", navigate_to.bind("deck"), Color("588d73") if screen == "unified_deck" else Color("526e93")))
		host.add_child(label("Bound blueprints · owned cards · saved deck leaves", 14, Color("9beaff")))
		var archive_filters := HBoxContainer.new(); archive_filters.name = "ArchiveBookFilters"; archive_filters.add_theme_constant_override("separation", 8); host.add_child(archive_filters)
		for filter in [["all", "All", "ArchiveFilterAll"], ["creature", "Creatures", "ArchiveFilterCreatures"], ["support", "Support", "ArchiveFilterSupport"]]:
			var filter_id := str(filter[0])
			var filter_button := make_button(str(filter[1]), set_archive_filter.bind(filter_id), Color("588d73") if unified_archive_filter == filter_id else Color("526e93"))
			filter_button.name = str(filter[2])
			filter_button.accessibility_name = "Show %s cards" % str(filter[1]).to_lower()
			archive_filters.add_child(filter_button)
	elif screen == "unified_market":
		host.add_child(label("Sparks %d" % int(GameManager.profile.get("sparks", 0)), 14, Color("9beaff")))
	# Every Foundry surface is intentionally bounded. Keep this shared return action
	# above all screen-specific content instead of relying on a clipped footer.
	var workshop_return := make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d"))
	workshop_return.name = "UnifiedFoundryWorkshopReturn"
	workshop_return.tooltip_text = "Return to the Workshop"
	workshop_return.accessibility_name = "Back to Workshop"
	workshop_return.focus_mode = Control.FOCUS_ALL
	host.add_child(workshop_return)
	if not toast.is_empty(): host.add_child(label(toast, 14, Color("fff0a1")))
	if screen == "unified_market":
		var tabs := GridContainer.new(); tabs.name = "V3MarketTabs"; tabs.columns = 2 if is_portrait_layout() else 5; tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tabs.add_theme_constant_override("h_separation", 8); tabs.add_theme_constant_override("v_separation", 8); host.add_child(tabs)
		for tab in [["blueprints","Blueprint Stall"],["cards","Card Shop"],["packs","Pack Emporium"],["upgrades","Upgrade Forge"],["cosmetics","Cosmetic Atelier"]]: tabs.add_child(make_button(str(tab[1]), func(): unified_market_tab = str(tab[0]); unified_page = 0; render(), Color("588d73") if unified_market_tab == str(tab[0]) else Color("526e93")))
		var market_scroll := TOUCH_SCROLL_CONTAINER.new(); market_scroll.name = "UnifiedMarketScroll"; market_scroll.custom_minimum_size = Vector2(0, 0); market_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; market_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; host.add_child(market_scroll)
		var market_body := VBoxContainer.new(); market_body.name = "UnifiedMarketScrollBody"; market_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; market_body.add_theme_constant_override("separation", 8); market_scroll.add_child(market_body)
		var market := GameManager.market_snapshot()
		var daily: Dictionary = market.get("daily_deal", {})
		market_body.add_child(label("Daily Deal: %s · 20%% off" % str(daily.get("id", "loading")), 14, Color("fff0a1")))
		var rewards := HBoxContainer.new(); rewards.name = "V3Rewards"; market_body.add_child(rewards)
		rewards.add_child(make_button("Daily quests", func(): var r = GameManager.daily_quests_v3(); _toast("Quests ready." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("526e93")))
		rewards.add_child(make_button("Season %d / 50" % UNIFIED_RULES.season_level(GameManager.profile), func(): var r = GameManager.claim_season_level_v3(UNIFIED_RULES.season_level(GameManager.profile), false); _toast("Season reward claimed." if bool(r.get("ok", false)) else str(r.get("error", "No reward ready."))); render(), Color("588d73")))
		var quest_day := Time.get_date_string_from_system(); var quest_result := GameManager.daily_quests_v3(quest_day)
		if bool(quest_result.get("ok", false)):
			var quest_state: Dictionary = GameManager.profile.get("quest_state", {})
			market_body.add_child(label("Daily Quests · %d free reroll" % int(quest_state.get("rerolls", 0)), 14, Color("9beaff")))
			for index in (quest_state.get("quests", []) as Array).size():
				var quest: Dictionary = quest_state.quests[index]; var quest_id := str(quest.get("id", ""))
				market_body.add_child(make_button("%s · %d/%d%s" % [str(quest.get("objective", "")).replace("_", " ").capitalize(), int(quest.get("progress", 0)), int(quest.get("target", 1)), " · claim" if bool(quest.get("completed", false)) else ""], func():
					var r = GameManager.claim_daily_quest_v3(quest_day, quest_id) if bool(quest.get("completed", false)) else GameManager.reroll_daily_quest_v3(quest_day, index)
					_toast("Quest reward claimed." if bool(r.get("ok", false)) else str(r.get("error", "Quest unavailable."))); render(), Color("588d73") if bool(quest.get("completed", false)) else Color("526e93")))
		var season: Dictionary = GameManager.profile.get("season", {})
		market_body.add_child(label("Season track · %d XP · level %d / 50%s" % [int(season.get("xp", 0)), UNIFIED_RULES.season_level(GameManager.profile), " · paid" if bool(season.get("paid", false)) else " · free"], 14, Color("fff0a1")))
		var level := UNIFIED_RULES.season_level(GameManager.profile)
		if level > 0:
			market_body.add_child(make_button("Claim free level %d" % level, func(): var r = GameManager.claim_season_level_v3(level, false); _toast("Free Season reward claimed." if bool(r.get("ok", false)) else str(r.get("error", "No reward ready."))); render(), Color("588d73")))
			if bool(season.get("paid", false)): market_body.add_child(make_button("Claim paid level %d" % level, func(): var r = GameManager.claim_season_level_v3(level, true); _toast("Paid Season reward claimed." if bool(r.get("ok", false)) else str(r.get("error", "No reward ready."))); render(), Color("7b5a9b")))
		if unified_market_tab == "blueprints":
			market_body.add_child(label("Blueprint Stall · 12 daily slots · rarity unlocked by Spool Level", 15, Color("e6dfd0")))
			var newcomer_items: Array = market.get("newcomer", {}).get("blueprints", []) if market.get("newcomer", {}) is Dictionary else []
			if not newcomer_items.is_empty():
				market_body.add_child(label("Newcomer Shelf · three half-price Common blueprints", 14, Color("fff0a1")))
				for offer in newcomer_items:
					var newcomer_id := str(offer.get("id", "")); market_body.add_child(make_button("Newcomer: %s · %d FC" % [newcomer_id, int(offer.get("price", 0))], func(): var r = GameManager.buy_blueprint_v3(newcomer_id); _toast("Blueprint purchased." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("a86b2e")))
			for offer in (market.get("blueprints", []) as Array):
				var blueprint_id := str(offer.get("id", ""))
				market_body.add_child(make_button("%s · %d FC" % [blueprint_id, int(offer.get("price", 0))], func(): var r = GameManager.buy_blueprint_v3(blueprint_id); _toast("Blueprint purchased." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("a86b2e")))
				market_body.add_child(make_button(("Remove wishlist: " if blueprint_id in GameManager.profile.get("wishlist", []) else "Wishlist: ") + blueprint_id, func(): var r = GameManager.set_wishlist_v3(blueprint_id, blueprint_id not in GameManager.profile.get("wishlist", [])); _toast("Wishlist updated." if bool(r.get("ok", false)) else str(r.get("error", "Wishlist full."))); render(), Color("526e93")))
		elif unified_market_tab == "cards":
			market_body.add_child(label("Card Shop · typed stock refreshes every 48 hours", 15, Color("e6dfd0")))
			for offer in (market.get("cards", []) as Array):
				var market_card_id := str(offer.get("id", ""))
				market_body.add_child(make_button("%s · %d FC" % [market_card_id, int(offer.get("price", 0))], func(): var r = GameManager.buy_market_card_v3(market_card_id); _toast("Card purchased." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("2f93a8")))
				market_body.add_child(make_button(("Remove wishlist: " if market_card_id in GameManager.profile.get("wishlist", []) else "Wishlist: ") + market_card_id, func(): var r = GameManager.set_wishlist_v3(market_card_id, market_card_id not in GameManager.profile.get("wishlist", [])); _toast("Wishlist updated." if bool(r.get("ok", false)) else str(r.get("error", "Wishlist full."))); render(), Color("526e93")))
		elif unified_market_tab == "packs":
			market_body.add_child(label("Pack Emporium · pity progress persists per pack type", 15, Color("e6dfd0")))
			for pack_id in UNIFIED_RULES.PACKS: market_body.add_child(make_button("%s · %d FC · pity %d/50" % [str(pack_id).capitalize(), int(UNIFIED_RULES.PACKS[pack_id].get("price", 0)), int(GameManager.profile.get("pack_pity", {}).get(pack_id, 0))], _buy_unified_pack.bind(str(pack_id)), Color("a86b2e")))
		elif unified_market_tab == "upgrades":
			market_body.add_child(label("Upgrade Forge · permanent Workshop upgrades and battle cards", 15, Color("e6dfd0")))
			for upgrade_id in UNIFIED_RULES.WORKSHOP_UPGRADES: market_body.add_child(make_button("Workshop: %s · %d FC" % [str(upgrade_id).replace("_", " "), int(UNIFIED_RULES.WORKSHOP_UPGRADES[upgrade_id].get("cost", 0))], func(): var r = GameManager.buy_workshop_upgrade_v3(str(upgrade_id)); _toast("Upgrade installed." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("588d73")))
			for upgrade_id in UNIFIED_RULES.UPGRADE_CARDS: market_body.add_child(make_button("Card: %s · %d FC" % [str(upgrade_id).replace("_", " "), int(UNIFIED_RULES.UPGRADE_CARDS[upgrade_id].get("cost", 0))], func(): var r = GameManager.buy_upgrade_card_v3(str(upgrade_id)); _toast("Upgrade Card added." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("526e93")))
		else:
			market_body.add_child(label("Cosmetic Atelier · visual items never change battle rules", 15, Color("e6dfd0")))
			for cosmetic_id in UNIFIED_RULES.COSMETICS:
				var cosmetic_name := str(UNIFIED_RULES.COSMETICS[cosmetic_id].get("name", cosmetic_id)); var cosmetic_price := int(UNIFIED_RULES.COSMETICS[cosmetic_id].get("coins", 0))
				market_body.add_child(make_button("%s · %d Forge Coins" % [cosmetic_name, cosmetic_price], func(): var r = GameManager.buy_cosmetic_v3(str(cosmetic_id), "forge_coins"); _toast("Cosmetic added." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("7b5a9b")))
				market_body.add_child(make_button("%s · %d Sparks" % [cosmetic_name, cosmetic_price], func(): var r = GameManager.buy_cosmetic_v3(str(cosmetic_id), "sparks"); _toast("Cosmetic added." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("526e93")))
			market_body.add_child(make_button("Local test purchase: Forge Boost (1,200 Sparks)", func(): var r = GameManager.fake_store_purchase_v3("ui-%d" % Time.get_ticks_msec(), "forge_boost"); _toast("Sparks added." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("a86b2e")))
			market_body.add_child(make_button("Unlock paid Season Track · 1,200 Sparks", func(): var r = GameManager.buy_paid_season_v3(); _toast("Season Track unlocked." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("588d73")))
	elif screen == "unified_library":
		var owned: Array = []
		for definition in UNIFIED_RULES.all_cards():
			if int(GameManager.profile.get("owned_cards", {}).get(str(definition.get("id", "")), 0)) > 0: owned.append(definition)
		var filtered_owned := _filter_archive_cards(owned)
		host.add_child(label("Collection pages · %d card types · creature cards unlock their printable blueprint." % filtered_owned.size(), 15, Color("e6dfd0")))
		host.add_child(_unified_cards_page(filtered_owned, func(id): unified_inspector_id = id; unified_inspector_tab = "card"; render()))
		var library_deck := make_button("Open Deck Blueprint Rack", navigate_to.bind("deck"), Color("a86b2e"))
		library_deck.name = "UnifiedLibraryDeck"
		host.add_child(library_deck)
	elif screen == "unified_deck":
		if unified_deck_draft.is_empty(): unified_deck_draft = GameManager.active_deck_cards()
		var deck_slots := HBoxContainer.new(); deck_slots.name = "V3DeckSlots"; host.add_child(deck_slots)
		for slot in UNIFIED_RULES.DECK_SLOTS:
			var slot_id := str(slot.get("id", "")); var is_active := slot_id == str(GameManager.profile.get("active_deck_id", ""))
			deck_slots.add_child(make_button(("✓ " if is_active else "") + str(slot.get("name", slot_id)), func():
				var selected = GameManager.select_unified_deck(slot_id)
				if selected: unified_deck_draft = GameManager.active_deck_cards(); unified_preprint_draft = GameManager.profile.get("preprints", []).duplicate()
				else: _toast("That fixed deck slot needs a legal 40-card deck.")
				render(), Color("588d73") if is_active else Color("526e93")))
		var creatures := 0
		for card_id in unified_deck_draft:
			if str(UNIFIED_RULES.card(str(card_id)).get("type", "")) == "creature": creatures += 1
		host.add_child(label("%d cards · minimum 40 · %d creatures · copies limited by ownership" % [unified_deck_draft.size(), creatures], 15, Color("fff0a1")))
		var owned_deck: Array = []
		for definition in UNIFIED_RULES.all_cards():
			if int(GameManager.profile.get("owned_cards", {}).get(str(definition.get("id", "")), 0)) > 0: owned_deck.append(definition)
		for definition in owned_deck: definition["name"] = "%s · x%d in deck" % [str(definition.get("name", "")), unified_deck_draft.count(str(definition.get("id", "")))]
		for definition in owned_deck:
			var definition_id := str(definition.get("id", ""))
			definition["name"] = str(UNIFIED_RULES.card(definition_id).get("name", definition_id))
			definition["deck_count"] = unified_deck_draft.count(definition_id)
		host.add_child(_unified_cards_page(_filter_archive_cards(owned_deck), func(id):
			if id in unified_deck_draft: unified_deck_draft.erase(id)
			elif unified_deck_draft.count(id) < int(GameManager.profile.get("owned_cards", {}).get(id, 0)): unified_deck_draft.append(id)
			render()))
		host.add_child(make_button("Save active fixed deck", func(): GameManager.save_unified_deck(unified_deck_draft, str(GameManager.profile.get("active_deck_id", "starter-deck"))); render(), Color("588d73")))
		if unified_preprint_draft.is_empty(): unified_preprint_draft = GameManager.profile.get("preprints", []).duplicate()
		var slots := UNIFIED_RULES.preprint_slots(GameManager.profile)
		host.add_child(label("Pre-Print loadout · %d / %d slots · consumes exact active deck creature copies" % [unified_preprint_draft.size(), slots], 15, Color("9beaff")))
		var preprint_options: Array = []
		for id in unified_deck_draft:
			if str(UNIFIED_RULES.card(str(id)).get("type", "")) == "creature" and id not in preprint_options: preprint_options.append(id)
		for creature_id in preprint_options:
			var chosen := unified_preprint_draft.count(creature_id)
			var available := unified_deck_draft.count(creature_id)
			host.add_child(make_button(("✓ " if chosen > 0 else "○ ") + "%s · %d/%d selected" % [str(UNIFIED_RULES.card(creature_id).get("name", creature_id)), chosen, available], func():
				if chosen > 0: unified_preprint_draft.erase(creature_id)
				elif unified_preprint_draft.size() < slots and unified_preprint_draft.count(creature_id) < available: unified_preprint_draft.append(creature_id)
				render(), Color("588d73") if chosen > 0 else Color("526e93")))
		host.add_child(make_button("Save Pre-Print loadout", func(): var saved = GameManager.save_preprints_v3(unified_preprint_draft); _toast("Pre-Print loadout saved." if saved else "Pre-Print loadout is not legal."); render(), Color("a86b2e")))
	elif screen == "unified_forgedex":
		_render_unified_forgedex_page(host)
	else:
		host.add_child(label("Printer skill nodes were retired. Workshop Upgrades and Upgrade Cards are available in the Filament Market.", 15, Color("fff0a1")))
		host.add_child(make_button("Open Upgrade Forge", func(): screen = "unified_market"; unified_market_tab = "upgrades"; render(), Color("588d73")))
	_render_unified_inspector()
	_render_unified_pack_reveal()

func _filter_archive_cards(definitions: Array) -> Array:
	if unified_archive_filter == "all": return definitions
	var filtered: Array = []
	for definition in definitions:
		var is_creature := str((definition as Dictionary).get("type", "")) == "creature"
		if (unified_archive_filter == "creature" and is_creature) or (unified_archive_filter == "support" and not is_creature): filtered.append(definition)
	return filtered

func set_archive_filter(filter_id: String) -> void:
	if filter_id not in ["all", "creature", "support"]: return
	unified_archive_filter = filter_id
	unified_page = 0
	render()

func _buy_unified_pack(pack_id: String) -> void:
	var result := GameManager.buy_card_pack(pack_id, "unified_market", {"caller":"unified_market"})
	if not bool(result.get("ok", false)):
		_toast(str(result.get("error", "Pack unavailable.")))
	else:
		_m3_open_pending_pack("unified_market")
		_toast("Pack opened. Review each card before keeping it.")
	render()

func _buy_unified_market_card(card_id: String) -> void:
	# Retained only for legacy buttons that still route here; all unified Market
	# purchases now use the canonical 48-hour typed Card Shop transition.
	var result := GameManager.buy_market_card_v3(card_id)
	if not bool(result.get("ok", false)):
		_toast(str(result.get("error", "Market offer unavailable.")))
	else:
		var card := UNIFIED_RULES.card(card_id)
		var message := "%s added to your Library." % str(card.get("name", card_id))
		_toast(message)
	render()

func _render_unified_pack_reveal() -> void:
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {})
	# Render from a copy: bonus-card presentation must never append into the
	# persisted exactly-once pending receipt when this surface redraws.
	var cards: Array = (pending.get("cards", []) as Array).duplicate() if pending is Dictionary else []
	var bonus_cards: Array = pending.get("bonus_cards", []) if pending is Dictionary else []
	if not bonus_cards.is_empty(): cards.append_array(bonus_cards)
	if cards.is_empty(): return
	var modal := ColorRect.new()
	modal.name = "UnifiedPackReveal"
	modal.color = Color("07111bf2")
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var shell := PanelContainer.new()
	var five_card_reveal := cards.size() == 5
	var reveal_height := 620.0 if five_card_reveal and is_portrait_layout() else (420.0 if five_card_reveal else (470.0 if is_portrait_layout() else 460.0))
	shell.custom_minimum_size = Vector2(minf(1040, size.x - 24), minf(reveal_height, size.y - 24))
	shell.add_theme_stylebox_override("panel", panel_style(Color("102940fa"), Color("f1be69")))
	center.add_child(shell)
	var content := VBoxContainer.new()
	content.name = "UnifiedPackRevealContent"
	content.add_theme_constant_override("separation", 8)
	shell.add_child(content)
	content.add_child(label("Foundry pack reveal", 24, Color("ffd36c")))
	var unlocks: Array = pending.get("blueprint_unlocks", []) if pending is Dictionary else []
	content.add_child(label("%d cards%s · duplicates are kept%s" % [cards.size(), " including %d Rare Reward bonus cards" % bonus_cards.size() if not bonus_cards.is_empty() else "", " · blueprint unlocked" if not unlocks.is_empty() else ""], 14, Color("dce8f4")))
	var per_page := 5 if five_card_reveal else (2 if is_portrait_layout() else 4)
	var pages := maxi(1, int(ceil(float(cards.size()) / float(per_page))))
	unified_reveal_page = clampi(unified_reveal_page, 0, pages - 1)
	# Keep a short reveal centered in its ceremonial panel instead of leaving a
	# large, accidental-looking empty rail on the right at desktop widths.
	var grid_center := CenterContainer.new()
	grid_center.name = "UnifiedPackRevealCardCenter"
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid_center)
	var grid := GridContainer.new()
	grid.name = "UnifiedPackRevealGrid"
	grid.columns = 3 if five_card_reveal and is_portrait_layout() else (5 if five_card_reveal else (2 if is_portrait_layout() else 4))
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid_center.add_child(grid)
	for card_id in cards.slice(unified_reveal_page * per_page, mini(cards.size(), (unified_reveal_page + 1) * per_page)):
		var id := str(card_id)
		var view := UNIFIED_CARD_VIEW.new()
		view.name = "UnifiedPackCardView%s" % id.capitalize()
		var note := "Blueprint unlocked" if id in unlocks else "Awarded now"
		view.configure(UNIFIED_RULES.card(id), int(GameManager.profile.get("owned_cards", {}).get(id, 0)), -1, note, true, false)
		grid.add_child(view)
	if pages > 1:
		var pager := HBoxContainer.new()
		pager.name = "UnifiedPackRevealPager"
		pager.alignment = BoxContainer.ALIGNMENT_CENTER
		pager.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		content.add_child(pager)
		var previous := make_button("Previous", func(): unified_reveal_page = posmod(unified_reveal_page - 1, pages); render(), Color("536c8d"))
		previous.custom_minimum_size = Vector2(48, 44)
		previous.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		previous.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pager.add_child(previous)
		pager.add_child(_compact_pager_label("%d / %d" % [unified_reveal_page + 1, pages]))
		var next := make_button("Next", func(): unified_reveal_page = posmod(unified_reveal_page + 1, pages); render(), Color("536c8d"))
		next.custom_minimum_size = Vector2(48, 44)
		next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pager.add_child(next)
	var keep_cards := make_button("Keep cards", _keep_unified_pack_cards, Color("588d73"))
	keep_cards.name = "UnifiedPackRevealKeepCards"
	content.add_child(keep_cards)

func _keep_unified_pack_cards() -> void:
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {})
	var starter_reward := bool(pending.get("starter_reward", false))
	var keep_result := GameManager.claim_pending_pack_reveal_result()
	var kept: Array = keep_result.get("cards", []) if keep_result.get("cards", []) is Array else []
	if not bool(keep_result.get("ok", false)):
		_toast(str(keep_result.get("error", "There are no pack cards waiting to keep.")))
	else:
		var rewards: Dictionary = GameManager.profile.get("starter_pack_rewards", {})
		if starter_reward and str(rewards.get("kind", "")) == UNIFIED_RULES.FOUNDER_VERSION and int(rewards.get("opened", 0)) < int(rewards.get("entitled", 0)):
			_toast("Founder receipt kept. Open Founder pack %d / 3 when ready." % (int(rewards.get("opened", 0)) + 1))
		else:
			_toast("Kept %d cards in your Library." % kept.size())
	if bool(keep_result.get("ok", false)):
		screen = str(m3_pack_return_context.get("caller", m3_pack_return_screen))
		if screen not in ["workshop", "unified_library", "unified_market", "settings"]: screen = "workshop"
	render()

func _submit_unified_intent(intent: Dictionary) -> void:
	if battle == null or battle.finished: return
	var previous_seat := int(battle.active_seat)
	var result := unified_battle_coordinator.submit_checked(unified_battle_coordinator.envelope(previous_seat, intent), unified_battle_coordinator.generation)
	if not bool(result.get("ok", false)):
		_toast(str(result.get("error", "That action is not legal.")))
		return
	_present_unified_battle_event(result.get("receipt", {}) as Dictionary)
	unified_selected_card_id = ""
	unified_selected_slot = -2
	unified_selected_target = -2
	unified_attack_slot = -1
	unified_attack_target = -2
	if battle_mode != "local" and int(battle.active_seat) == 1 and not battle.finished:
		_queue_unified_ai_if_needed()
	if battle_mode == "local" and int(battle.active_seat) != previous_seat:
		unified_local_handoff = true
		unified_ai_steps = 0
	render()

func _enter_unified_plan() -> void:
	if battle == null or str(battle.phase) != "draw": return
	var result := unified_battle_coordinator.enter_plan_if_needed(int(battle.active_seat))
	if not bool(result.get("ok", false)): _toast(str(result.get("error", "Could not prepare Plan.")))
	else: _present_unified_battle_event(result.get("receipt", {}) as Dictionary)
	render()

func _start_unified_run_cycle() -> void:
	if battle == null: return
	var result := unified_battle_coordinator.start_run_cycle(int(battle.active_seat))
	_handle_unified_cycle_result(result)

func _concede_unified_battle() -> void:
	if battle == null:
		return
	var conceding_seat := int(battle.active_seat) if battle_mode == "local" else 0
	if int(battle.active_seat) != conceding_seat or unified_battle_coordinator.in_flight or unified_battle_coordinator.presentation_active:
		_toast("The rival is resolving. Resume safely when it returns.")
		render()
		return
	var result := unified_battle_coordinator.submit_checked(unified_battle_coordinator.envelope(conceding_seat, {"type":"concede"}), unified_battle_coordinator.generation)
	if not bool(result.get("ok", false)):
		_toast(str(result.get("error", "Concede is unavailable right now.")))
		render()
		return
	battle_back_confirmation = false
	# Concede is terminal and has no presentation receipt. Render the finished
	# authority state so the existing settlement path owns the result exactly once.
	render()

func _submit_required_battle_decision(intent: Dictionary) -> void:
	if battle == null: return
	var result := unified_battle_coordinator.submit_required_decision(int(battle.active_seat), intent, unified_battle_coordinator.generation)
	_handle_unified_cycle_result(result)

func _submit_overflow_discard(card_ids: Array) -> void:
	_submit_required_battle_decision({"type":"discard_overflow", "card_ids":card_ids})

func _set_unified_focus(slot: int) -> void:
	if battle == null or str(battle.phase) != "main": return
	unified_battle_coordinator.set_transient_focus(slot)
	_toast("Focus this cycle: rival slot %d" % (slot + 1))
	render()

func _handle_unified_cycle_result(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		_toast(str(result.get("error", "Run Cycle stopped."))); render(); return
	if bool(result.get("complete", false)):
		_complete_unified_cycle_handoff()
		render()
		return
	_present_unified_battle_event(result.get("receipt", {}) as Dictionary)
	if not bool(result.get("paused", false)):
		call_deferred("_continue_unified_run_cycle", int(result.get("generation", unified_battle_coordinator.generation)))
	render()

func _continue_unified_run_cycle(token: int) -> void:
	if token != unified_battle_coordinator.generation: return
	if battle == null: return
	if unified_battle_coordinator.presentation_active:
		await get_tree().create_timer(_unified_presentation_wait_seconds(str(unified_battle_presentation.get("kind", "")))).timeout
		unified_battle_coordinator.acknowledge_presentation(token)
	if token != unified_battle_coordinator.generation: return
	var result := unified_battle_coordinator.advance_run_cycle(int(battle.active_seat), token)
	_handle_unified_cycle_result(result)

func _run_unified_ai(token := -1) -> void:
	if token >= 0 and token != unified_battle_coordinator.generation: return
	if not unified_ai_pending or battle == null or battle.finished: return
	if unified_ai_steps >= UNIFIED_AI_STEP_BUDGET:
		unified_ai_pending = false
		_toast("Rival turn paused safely after %d checked actions. Retry the battle flow." % UNIFIED_AI_STEP_BUDGET)
		render()
		return
	# Yield one composed frame so a player print arriving after Collect is visible
	# before the rival response. This is presentation scheduling only.
	var wait_seconds := 0.0 if bool(settings().get("reduced_motion", false)) else 0.52
	if wait_seconds > 0.0: await get_tree().create_timer(wait_seconds).timeout
	else: await get_tree().process_frame
	if token >= 0 and token != unified_battle_coordinator.generation: return
	if battle != null and not battle.finished and int(battle.active_seat) == 1:
		var intent := unified_battle_coordinator.next_ai_intent(1)
		if intent.is_empty(): unified_ai_pending = false; _toast("Rival has no legal continuation.")
		else:
			var result := unified_battle_coordinator.submit_checked(unified_battle_coordinator.envelope(1, intent), unified_battle_coordinator.generation)
			if not bool(result.get("ok", false)):
				unified_ai_pending = false; _toast(str(result.get("error", "Rival action rejected.")))
			else:
				# One increment maps to exactly one accepted checked envelope. Rejects
				# and stale deferred callbacks never consume the safety budget.
				unified_ai_steps += 1
				_present_unified_battle_event(result.get("receipt", {}) as Dictionary)
				if unified_battle_coordinator.presentation_active:
					await get_tree().create_timer(_unified_presentation_wait_seconds(str(unified_battle_presentation.get("kind", "")))).timeout
					unified_battle_coordinator.acknowledge_presentation(unified_battle_coordinator.generation)
				unified_ai_pending = not battle.finished and int(battle.active_seat) == 1
				if unified_ai_pending: call_deferred("_run_unified_ai", token)
				else: unified_ai_steps = 0
	else:
		unified_ai_pending = false
		unified_ai_steps = 0
	render()

func _settle_finished_unified_battle() -> void:
	if battle == null or battle_settlement_context.is_empty() or m3_result_state == "pending" or m3_result_state in ["committed", "duplicate"]: return
	m3_result_state = "pending"
	var settled: Dictionary = GameManager.settle_unified_mode_battle(battle_settlement_context, battle, int(battle.winner) == 0)
	m3_result_receipt = settled.get("payload", {}).duplicate(true) if settled.get("payload", {}) is Dictionary else {}
	if bool(settled.get("ok", false)):
		m3_result_state = "duplicate" if bool(m3_result_receipt.get("duplicate", false)) else "committed"
		battle_settlement_finished = true
		_toast("Result saved.")
		screen = "m3_result"
	else:
		m3_result_state = "error"
		_toast(str(settled.get("error", "Result could not be saved.")))
		screen = "m3_result"
	render()

func _unified_card_button(card_id: String) -> Button:
	var card := UNIFIED_RULES.card(card_id)
	var filament_cost := int(card.get("filament_cost", card.get("cost", 0)))
	# Selection is communicated by the physical focus/active treatment; a leading
	# tick made the first glyph sit under its cyan ring on the narrow hand rail.
	var button := make_button(str(card.get("name", card_id)) + " · %dF" % filament_cost, func(): unified_selected_card_id = card_id; unified_selected_slot = -2; unified_selected_target = -2; render(), Color("588d73") if card_id == unified_selected_card_id else Color("2f93a8"))
	button.custom_minimum_size = Vector2(0, 58)
	button.name = "UnifiedHand%s" % card_id.capitalize()
	var can_play := battle != null and str(battle.phase) == "main" and (battle_mode == "local" or int(battle.active_seat) == 0) and not unified_ai_pending
	if not can_play:
		button.disabled = true
		var disabled_reason := "Cards can be played only during your Main Phase." if battle == null or str(battle.phase) != "main" else "Rival cards are hidden while the rival resolves its turn."
		button.tooltip_text = disabled_reason
		button.accessibility_name = "%s. %s" % [str(card.get("name", card_id)), disabled_reason]
	else:
		button.tooltip_text = "Select %s for a legal Main Phase action" % str(card.get("name", card_id))
		button.accessibility_name = "Select %s, %d filament" % [str(card.get("name", card_id)), filament_cost]
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("focus", _unified_hand_focus_style())
	var art := _unified_card_thumbnail(card)
	if art != null:
		button.icon = art
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 42)
	return button

func _unified_hand_focus_style() -> StyleBoxFlat:
	# Keep the complete focus outline outside the hand label's content box.  The
	# rail has a real gap to Queue/Run; expanded margins use that gap rather than
	# painting across the first/last glyphs.
	var style := StyleBoxFlat.new()
	style.bg_color = Color("28404ae8")
	style.border_color = Color.WHITE if bool(settings().get("high_contrast", false)) else Color("75d8dd")
	style.set_border_width_all(3)
	style.expand_margin_left = 4
	style.expand_margin_right = 4
	style.expand_margin_top = 3
	style.expand_margin_bottom = 3
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.corner_radius_top_left = 7; style.corner_radius_top_right = 7; style.corner_radius_bottom_left = 7; style.corner_radius_bottom_right = 7
	return style

func _render_unified_play_picker(host: Container, active: Dictionary) -> void:
	if battle == null or str(battle.phase) != "main" or unified_selected_card_id.is_empty() or unified_selected_card_id not in active.get("hand", []): return
	var card := UNIFIED_RULES.card(unified_selected_card_id)
	var panel := make_panel(Color("17394ee8"), Color("8deaff"))
	panel.name = "UnifiedPlayTargetPicker"
	host.add_child(panel.get_parent())
	var selected_label := label("%s · choose its legal target" % str(card.get("name", unified_selected_card_id)), 15, Color("fff0a1"))
	selected_label.name = "UnifiedSelectedHandCard"
	panel.add_child(selected_label)
	var kind := str(card.get("type", ""))
	var picks := HBoxContainer.new()
	picks.add_theme_constant_override("separation", 7)
	panel.add_child(picks)
	if kind == "creature":
		panel.add_child(label("Creatures enter the public FIFO queue now; choose a slot and mode when printing completes.", 13, Color("e6dfd0")))
		var queue_creature := make_button("Queue creature", _submit_unified_intent.bind({"type":"play_card","card_id":unified_selected_card_id}), Color("a86b2e"))
		queue_creature.name = "UnifiedPlayQueueCreature"
		queue_creature.accessibility_name = "Queue selected creature"
		panel.add_child(queue_creature)
	elif kind == "equipment":
		if str(card.get("equipment_slot", "")) == "battle_effect":
			panel.add_child(label("This is worn by the player for this battle. It does not print or use a creature gear slot.", 13, Color("e6dfd0")))
			var activate_effect := make_button("Activate player effect", _submit_unified_intent.bind({"type":"play_card","card_id":unified_selected_card_id}), Color("a86b2e"))
			activate_effect.name = "UnifiedPlayActivateEffect"
			activate_effect.accessibility_name = "Activate selected player battle effect"
			panel.add_child(activate_effect)
		else:
			for slot in 3:
				if active.slots[slot] != null:
					picks.add_child(make_button(("✓ " if unified_selected_target == slot else "") + "Your slot %d" % (slot + 1), func(): unified_selected_target = slot; render(), Color("588d73") if unified_selected_target == slot else Color("526e93")))
			if unified_selected_target >= 0:
				var queue_equipment := make_button("Queue equipment", _submit_unified_intent.bind({"type":"play_card","card_id":unified_selected_card_id,"slot":-1,"target":unified_selected_target}), Color("a86b2e"))
				queue_equipment.name = "UnifiedPlayQueueEquipment"
				queue_equipment.accessibility_name = "Queue selected equipment"
				panel.add_child(queue_equipment)
	elif kind == "spell":
		# Targeted spells use slots; queue and filament spells resolve without one.
		for slot in 3:
			if battle.player(1 - int(battle.active_seat)).slots[slot] != null:
				picks.add_child(make_button(("✓ " if unified_selected_target == slot else "") + "Enemy %d" % (slot + 1), func(): unified_selected_target = slot; render(), Color("588d73") if unified_selected_target == slot else Color("526e93")))
		var cast_card := make_button("Cast card", _submit_unified_intent.bind({"type":"play_card","card_id":unified_selected_card_id,"target":unified_selected_target}), Color("a86b2e"))
		cast_card.name = "UnifiedPlayCastCard"
		cast_card.accessibility_name = "Cast selected card"
		panel.add_child(cast_card)
	else:
		var use_refill := make_button("Use refill", _submit_unified_intent.bind({"type":"play_card","card_id":unified_selected_card_id,"slot":-1,"target":-2}), Color("a86b2e"))
		use_refill.name = "UnifiedPlayUseRefill"
		use_refill.accessibility_name = "Use selected filament card"
		panel.add_child(use_refill)

func _render_unified_attack_picker(host: Container, active: Dictionary) -> void:
	if str(battle.phase) != "attack": return
	var panel := make_panel(Color("3a241ee8"), Color("f1be69"))
	panel.name = "UnifiedAttackTargetPicker"
	host.add_child(panel.get_parent())
	panel.add_child(label("Attack · choose a ready print, then a legal target", 15, Color("fff0a1")))
	var attackers := HBoxContainer.new(); panel.add_child(attackers)
	for slot in 3:
		if active.slots[slot] != null and bool(active.slots[slot].get("ready", false)):
			attackers.add_child(make_button(("✓ " if unified_attack_slot == slot else "") + str(active.slots[slot].get("name", "Print")), func(): unified_attack_slot = slot; unified_attack_target = -2; render(), Color("a86b2e") if unified_attack_slot == slot else Color("526e93")))
	if unified_attack_slot < 0: return
	var targets := HBoxContainer.new(); panel.add_child(targets)
	var foe: Dictionary = battle.player(1 - int(battle.active_seat)); var guarded := false
	for slot in 3:
		if foe.slots[slot] != null:
			guarded = true
			targets.add_child(make_button(("✓ " if unified_attack_target == slot else "") + "Enemy %d" % (slot + 1), func(): unified_attack_target = slot; render(), Color("588d73") if unified_attack_target == slot else Color("526e93")))
	if not guarded: targets.add_child(make_button(("✓ " if unified_attack_target == -1 else "") + "Rival printer", func(): unified_attack_target = -1; render(), Color("588d73") if unified_attack_target == -1 else Color("526e93")))
	if unified_attack_target >= -1: panel.add_child(make_button("Confirm attack", _submit_unified_intent.bind({"type":"attack","slot":unified_attack_slot,"target":unified_attack_target}), Color("a86b2e")))

func render_m2_physical_battle() -> void:
	if battle != null and unified_battle_coordinator.state != battle:
		# Tests/recovery fixtures may replace the public authority directly. Treat it
		# as a match replacement, cancelling stale callbacks before any render.
		unified_battle_coordinator.configure(battle, 0)
	var component = _unified_battle_component()
	if component == null:
		_toast("Battle presentation could not load. Return to Workshop and retry.")
		screen = "workshop"
		return
	component.render_fullscreen(self)

func render_unified_battle_fullscreen(host: Container) -> void:
	var component = _unified_battle_component()
	if component != null:
		# There is one maintained M2 composition.  Older callers delegate back to
		# the physical full-surface route instead of mounting a second UI shell.
		render_m2_physical_battle()
		return
	# Fallback keeps a damaged optional component from blanking the Workshop
	# shell. Normal shipped presentation is owned by UnifiedBattleScreenComponent.
	if battle == null:
		host.add_child(label("No unified battle is active.", 20, Color("fff0a1")))
		host.add_child(make_button("Return to Workshop", navigate_to.bind("workshop"), Color("536c8d")))
		return
	host.add_child(label("Battle presentation is unavailable. Return to the Workshop and retry.", 16, Color("fff0a1")))
	host.add_child(make_button("Return to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func _toast(message: String) -> void:
	toast = message
	if status:
		status.visible = not message.is_empty()
		status.text = message
